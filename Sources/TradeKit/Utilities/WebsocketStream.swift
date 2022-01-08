//
//  Websocket.swift
//  TradeKit
//
//  Created by Hans Rietmann on 18/12/2021.
//

import Foundation
//import StreamKit
import CodableKit
import LogKit



public final class WebSocketStream: AsyncSequence/*, WebSocketDelegate*/ {
    
    
    public typealias Element = Data
    public typealias AsyncIterator = AsyncThrowingStream<Element, Error>.Iterator
    
    private let debug: Bool
//    private let socket: WebSocket
    private let onConnection: ((WebSocketStream) async throws -> ())?
    private var isConnected = false
    private var stream: AsyncThrowingStream<Element, Error>?
    private var continuation: AsyncThrowingStream<Element, Error>.Continuation?
    
    public init(url: String, debug: Bool = false, onConnection: ((WebSocketStream) async throws -> ())? = nil) {
        self.debug = debug
//        var request = URLRequest(url: URL(string: url)!)
//        request.timeoutInterval = 10
//        socket = .init(request: request)
        self.onConnection = onConnection
        stream = AsyncThrowingStream { continuation in
            self.continuation = continuation
//            self.continuation?.onTermination = { @Sendable [socket] _ in
//                socket.disconnect()
//            }
        }
    }
    
    deinit { continuation?.finish(throwing: nil) }
    
    public func makeAsyncIterator() -> AsyncIterator {
        guard let stream = stream else { fatalError("Stream not initialized before being utilized.") }
//        socket.delegate = self
//        socket.respondToPingWithPong = true
//        socket.connect()
        return stream.makeAsyncIterator()
    }
    
    private struct UnknownError: LocalizedError {
        var errorDescription: String? { "Unknown error" }
    }
    
//    public func didReceive(event: WebSocketEvent, client: WebSocketClient) {
//        switch event {
//        case .connected(let headers):
//            isConnected = true
//            sendPing()
//            if let onConnection = onConnection {
//                Task { [weak self] in
//                    guard let stream = self else { return }
//                    do { try await onConnection(stream) }
//                    catch { self?.continuation?.yield(with: .failure(error)) }
//                }
//            }
//            guard debug else { return }
//            logInfo("Websocket is connected:", headers)
//
//        case .disconnected(let reason, let code):
//            isConnected = false
//            continuation?.finish(throwing: nil)
//            guard debug else { return }
//            logInfo("Websocket is disconnected: \(reason) with code: \(code)")
//
//        case .text(let string):
//            guard let data = string.data(using: .utf8) else { return }
//            continuation?.yield(data)
//            guard debug else { return }
//            logInfo("Received text:", string)
//
//        case .binary(let data):
//            continuation?.yield(data)
//            guard debug else { return }
//            logInfo("Received data:", data.prettyJSON)
//
//        case .pong:
//            guard debug else { return }
//            logInfo("Received PONG")
//
//        case .ping:
//            guard debug else { return }
//            logInfo("Received PING")
//
//        case .error(let error):
//            isConnected = false
////            continuation?.yield(with: .failure(error ?? UnknownError()))
//            socket.connect()
//            guard debug else { return }
//            logInfo("Received error:", error?.localizedDescription ?? UnknownError().localizedDescription)
//
//        case .viabilityChanged(let viabilityChanged):
//            guard debug else { return }
//            logInfo("Viabilibility changed to \(viabilityChanged)")
//
//        case .reconnectSuggested(let needsToReconnect):
//            if needsToReconnect { socket.connect() }
//            guard debug else { return }
//            logInfo("Reconnection suggested \(needsToReconnect)")
//
//        case .cancelled:
//            isConnected = false
//            continuation?.finish(throwing: nil)
//            logInfo("Websocket is cancelled")
//        }
//    }
    
    public func send(_ message: Element) async {
//        guard let string = String(data: message, encoding: .utf8) else { return }//String(decoding: message, as: UTF8.self)
//        await withCheckedContinuation { continuation in
//            socket.write(string: string) { continuation.resume(returning: ()) }
//        }
    }
    
    private func sendPing() {
        guard isConnected else { return }
//        socket.write(ping: Data()) { [unowned self] in
//            Task { [weak self] in
//                do {
//                    try await Task.sleep(nanoseconds: 20 * 1_000_000_000)
//                    self?.sendPing()
//                } catch { self?.continuation?.finish(throwing: error) }
//            }
//        }
    }
    
}
