//
//  EnvironmentDelegate+StrategyDelegate.swift
//  TradeKit
//
//  Created by Hans Rietmann on 10/12/2021.
//

import Foundation




#if compiler(>=5.5) && canImport(_Concurrency)
extension TradeEnvironment {
    
    
    
    public func openPositions(on asset: Asset) async throws -> ArraySlice<OrderBracket> {
        let positions = self.openBracketOrders
            .lazy
            .filter { $0.assetSymbol == asset.symbol }
            .filter { $0.state == .filledEntry }
        return .init(positions)
    }
    
    public func place(entry newOrder: OrderRequestParams, at tick: Tick) async throws {
        let order = try await place(order: newOrder, at: tick.candle.date)
        orders[order.id] = order
        let position = OrderBracket(placedEntry: order)
        openBracketOrders.append(position)
    }
    
    public func place(exit newOrder: OrderRequestParams, to position: OrderBracket, at tick: Tick) async throws {
        guard let positionIndex = openBracketOrders.firstIndex(of: position) else { return }
        let order = try await place(order: newOrder, at: tick.candle.date)
        orders[order.id] = order
        openBracketOrders[positionIndex].placingExit(order)
    }
    
    
    
}
#endif
