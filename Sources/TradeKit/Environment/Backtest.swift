//
//  Backtest.swift
//  TradeKit
//
//  Created by Hans Rietmann on 30/11/2021.
//

import Foundation
import Collections
import CollectionConcurrencyKit




public final actor Backtest<B: Broker>: TradeEnvironment {
    
    
    public let broker: Broker
    public let start: Date
    public let end: Date!
    public let assets: Dictionary<AssetSymbol, Asset>
    public private(set) var strategy: Strategy
    public private(set) var listner: Listener
    public let initialCash: Double
    public var cash: Double
    public var equity: Double
    public var buyingPower: Double
    
    var account: Account
    public var openBracketOrders: Deque<OrderBracket>
    public var filledBracketOrders: Set<OrderBracket>
    public var orders = [UUID:Order]()
    
    
    public init(_ assets: Set<AssetSymbol>, on strategy: Strategy, start: DateComponents, end: DateComponents, cash: Double = 20_000, paper publicKey: String, _ privateKey: String) async throws {
        let broker = try B(.backtest(cash: cash, paperPublicKey: publicKey, paperSecretKey: privateKey))
        self.broker = broker
        self.initialCash = cash
        self.cash = cash
        self.equity = cash
        self.buyingPower = cash * 2
        
        var s = start
        s.second = nil
        s.nanosecond = nil
        s.calendar = .GMT0
        guard let starteDate = s.validDate else { throw InvalidDateComponents(propertyName: "start", components: s) }
        self.start = starteDate
        
        var e = end
        e.second = nil
        e.nanosecond = nil
        e.calendar = .GMT0
        guard let endDate = e.validDate else { throw InvalidDateComponents(propertyName: "end", components: e) }
        self.end = endDate
        
        let markets = try await assets.asyncCompactMap { symbol -> (AssetSymbol, Asset)? in
            guard let asset = try await broker.remoteAsset(from: symbol) else { return nil }
            return (asset.symbol, asset)
        }
        self.assets = .init(uniqueKeysWithValues: markets)
        self.strategy = strategy
        self.listner = BacktestListener(broker: broker, start: starteDate, end: endDate)
        self.account = broker.sampleAccount(cash: cash)
        openBracketOrders = .init()
        filledBracketOrders = .init()
        self.strategy.delegate = self
        await self.listner.delegate = self
    }
    
    deinit {
        print("Backtest deinit")
    }
    
    public func place(order: OrderRequestParams, at date: Date) async throws -> Order {
        broker.sampleOrder(from: order, at: date)
    }
    
    
}
