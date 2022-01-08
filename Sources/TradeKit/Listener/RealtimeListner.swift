//
//  RealtimeListner.swift
//  TradeKit
//
//  Created by Hans Rietmann on 19/12/2021.
//

import Foundation
import LogKit





actor RealtimeListner: Listener {
    
    var delegate: ListenerDelegate!
    private var latestQuote = [AssetSymbol:Quote?]()
    
    func listen() async throws {
        let stream = await delegate.broker.realtimeStream(for: delegate.assets.map { $0.value })
        for try await data in stream {
            switch data {
            case .candle(let candle, let symbol): try await received(candle: candle, of: symbol)
            case .trade(let trade, let symbol): await delegate.received(trade: trade, of: symbol)
            case .quote(let quote, let symbol):
                latestQuote[symbol] = quote
                await delegate.received(quote: quote, of: symbol)
            case .order(let order):
                await delegate.received(order: order)
                log(level: .level0, as: .custom("🏦"), "\(order.orderSide.rawValue.uppercased()) Order (id \(order.id)) updated to status \(String(describing: order.currentStatus).uppercased())")
            }
        }
    }
    
    private func latestQuote(of symbol: AssetSymbol) async throws -> Quote? {
        if let quote = latestQuote[symbol] { return quote }
        guard let asset = try await delegate.broker.remoteAsset(from: symbol) else { return nil }
        let quote = try await delegate.broker.remoteLatestQuote(of: asset)
        latestQuote[symbol] = quote
        return quote
    }
    
    private func received(candle: Candle, of assetSymbol: AssetSymbol) async throws {
        guard let asset = await delegate.assets[assetSymbol] else { return }
        let windowSize = await delegate.strategy.windowSize
        let end = candle.date
        guard let start = Calendar.GMT0.date(byAdding: .minute, value: -windowSize, to: end) else { return }
        let candles = try await delegate.broker
            .historicData(of: .candles(of: asset, from: start, to: end, each: .minute))
            .values.lazy.compactMap { $0.candles }.flatMap { $0 }.suffix(windowSize)
        guard candles.count == windowSize, let candle = candles.last else { return }
        guard let quote = try await latestQuote(of: assetSymbol) else { return }
        let tick = await Tick(asset: asset, candle: candle, candles: .init(candles), askPrice: quote.askPrice, bidPrice: quote.bidPrice, buyingPower: delegate.buyingPower, equity: delegate.equity)
        try await delegate.received(tick: tick)
    }
    
    
}






extension AsyncThrowingStream {
    
    public var values: [Element] {
        get async throws {
            var elements = [Element]()
            for try await element in self {
                elements.append(element)
            }
            return elements
        }
    }
    
}
