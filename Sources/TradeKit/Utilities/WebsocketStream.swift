//
//  Websocket.swift
//  TradeKit
//
//  Created by Hans Rietmann on 18/12/2021.
//

import Foundation
import WebSocketKit
import CodableKit
import LogKit





@available(macOS 12, *)
public final class WebsocketStream {
    
    private let url: String
    private let event: EventLoopGroup
    private let debug: Bool
    private var closeRequested = false
    private let connectionHandler: ((WebSocket) -> Void)?
    private var textHandler: ((String) -> Void)?
    private var errorHandler: ((Error) -> Void)?
    private var closeHandler: (() -> Void)?
    
    
    public var stream: AsyncThrowingStream<String, Error> {
         return AsyncThrowingStream { continuation in
             textHandler = { continuation.yield($0) }
             errorHandler = { continuation.yield(with: .failure($0)) }
             closeHandler = { continuation.finish(throwing: nil) }
             continuation.onTermination = { @Sendable _ in self.close() }
             connect()
         }
     }
    
    
    public init(url: String, on event: EventLoopGroup, debug: Bool = false, connectionHandler: ((WebSocket) -> Void)? = nil) {
        self.url = url
        self.event = event
        self.debug = debug
        self.connectionHandler = connectionHandler
    }
    

    func connect() {
        Task { [weak self] in
            do { try await self?.handleWebsocket() }
            catch { self?.errorHandler?(error) }
        }
    }
    
    private func handleWebsocket() async throws {
        try await WebSocket.connect(to: url, on: event) { [weak self] websocket async in
            self?.connectionHandler?(websocket)
            if self?.debug == true { logInfo("Websocket is connected!") }
            
            websocket.onText { websocket, text in
                do {
                    guard self?.closeRequested == false else { try await websocket.close() ; return }
                    self?.textHandler?(text)
                    guard self?.debug == true else { return }
                    logInfo("Received text from websocket:", text)
                } catch {
                    self?.errorHandler?(error)
                    guard self?.debug == true else { return }
                    logInfo("Received error from websocket:", error.localizedDescription)
                }
            }
            
            websocket.onBinary { websocket, data in
                do {
                    guard self?.closeRequested == false else { try await websocket.close() ; return }
                    let text = String(buffer: data)
                    self?.textHandler?(text)
                    guard self?.debug == true else { return }
                    logInfo("Received data from websocket:", text)
                } catch {
                    self?.errorHandler?(error)
                    guard self?.debug == true else { return }
                    logInfo("Received error from websocket:", error.localizedDescription)
                }
            }
            
            websocket.onPong { websocket async in
                if self?.debug == true { logInfo("PONG received from websocket.") }
                do {
                    try await Task.sleep(nanoseconds: 20 * 1_000_000_000)
                    guard self?.closeRequested == false else { try await websocket.close() ; return }
                    try await websocket.sendPing()
                    guard self?.debug == true else { return }
                    logInfo("PING sent from websocket.")
                } catch {
                    self?.errorHandler?(error)
                    guard self?.debug == true else { return }
                    logInfo("Received error from websocket:", error.localizedDescription)
                }
            }
            
            websocket.onPing { websocket async in
                guard self?.debug == true else { return }
                logInfo("PING received from websocket.")
            }
            websocket.onClose.whenComplete { result in
                switch result {
                case .success:
                    guard self?.closeRequested == false else {
                        self?.closeHandler?()
                        guard self?.debug == true else { return }
                        logInfo("Websocket closed!")
                        return
                    }
                    Task { [weak self] in
                        do {
                            try await self?.handleWebsocket()
                            guard self?.debug == true else { return }
                            logInfo("Reconnecting websocket...")
                        } catch {
                            self?.errorHandler?(error)
                            guard self?.debug == true else { return }
                            logInfo("Received error from websocket:", error.localizedDescription)
                        }
                    }
                case .failure(let error):
                    self?.errorHandler?(error)
                    guard self?.debug == true else { return }
                    logInfo("Received error from websocket:", error.localizedDescription)
                }
            }
            
            do { try await websocket.sendPing() }
            catch {
                self?.errorHandler?(error)
                guard self?.debug == true else { return }
                logInfo("Received error from websocket:", error.localizedDescription)
            }
        }
    }
    
    private func close() {
        closeRequested = true
        closeHandler?()
    }
    
}
