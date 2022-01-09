//
//  EnvironmentDelegate+fireTick.swift
//  TradeKit
//
//  Created by Hans Rietmann on 10/12/2021.
//

import Foundation



#if compiler(>=5.5) && canImport(_Concurrency)
extension TradeEnvironment {
    
    
    
    public func received(tick: Tick) async throws {
        fillPlacedOrders(at: tick)
        try await strategy.makeOrders(at: tick)
    }
    
    private func fillPlacedOrders(at tick: Tick) {
        switch broker.environment {
        case .backtest: break
        default: return
        }
        self.orders
            .lazy
            .filter { $0.value.symbol == tick.asset.symbol }
            .filter { $0.value.currentStatus == .open }
            .filter {
                if $0.value.needsToBeExpired(at: tick) { return true }
                switch $0.value.orderSide {
                case .buy: return tick.candle.close.value <= $0.value.limitPrice
                case .sell: return tick.candle.close.value >= $0.value.limitPrice
                }
            }
            .map { $0.key }
            .forEach { orderID in
                var order: Order {
                    get { orders[orderID]! }
                    set { orders[orderID] = newValue }
                }
                if order.needsToBeExpired(at: tick) {
                    order.currentStatus = .canceled
                } else {
                    let cost: Double
                    switch order.orderSide {
                    case .buy: cost = order.quantity * tick.candle.close.value
                    case .sell: cost = -order.quantity * tick.candle.close.value
                    }
                    if cash >= cost {
                        order.filledAtPrice = tick.candle.close.value
                        order.filledAtDate = tick.candle.date
                        order.currentStatus = .closed
                    } else {
                        order.currentStatus = .canceled
                    }
                }
                received(order: order)
            }
    }
    
    
    
}
#endif
