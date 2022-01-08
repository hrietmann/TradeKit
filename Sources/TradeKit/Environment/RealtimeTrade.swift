//
//  Livetest.swift
//  TradeKit
//
//  Created by Hans Rietmann on 18/12/2021.
//

import Foundation
import Collections




public final actor RealtimeTrade<B: Broker>: TradeEnvironment {
    
    public let assets: Dictionary<AssetSymbol, Asset>
    public let broker: Broker
    public let start: Date
    public let end: Date!
    public let initialCash: Double
    public var cash: Double
    public var equity: Double
    public var buyingPower: Double
    public var openBracketOrders: Deque<OrderBracket>
    public var filledBracketOrders: Set<OrderBracket>
    public var orders: Dictionary<UUID, Order>
    public private(set) var listner: Listener
    public private(set) var strategy: Strategy
    
    public init(_ environment: Environment, on symbols: Set<AssetSymbol>, with strategy: Strategy) async throws {
        
        // Get the broker
        let broker = try B.init(environment)
        
        // Download most up to date data
        async let assetsRequest = symbols
            .concurrentCompactMap { try await broker.remoteAsset(from: $0) }
            .map { ($0.symbol, $0) }
        async let accountRequest = broker.remoteAccount
        async let positionsRequest = broker.remotePositions.map { OrderBracket(position: $0) }
        async let ordersRequest = broker.remoteOrders([.open], sorted: .ascending).map { ($0.id, $0) }
        let (assets, account, positions, orders) = try await (assetsRequest, accountRequest, positionsRequest, ordersRequest)
        
        // Initializing the environment
        self.assets = .init(uniqueKeysWithValues: assets)
        self.broker = broker
        start = Date()
        end = nil
        initialCash = account.totalCash
        cash = account.totalCash
        equity = account.totalEquity
        buyingPower = account.buyingPower
        openBracketOrders = .init(positions)
        filledBracketOrders = []
        self.orders = .init(uniqueKeysWithValues: orders)
        self.listner = RealtimeListner()
        self.strategy = strategy
        await listner.delegate = self
        self.strategy.delegate = self
    }
    
    public func place(order: OrderRequestParams, at date: Date) async throws -> Order
    { try await broker.remotelyOrder(order) }
    
}
