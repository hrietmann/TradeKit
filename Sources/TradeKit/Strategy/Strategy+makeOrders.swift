//
//  Strategy+makeOrders.swift
//  TradeKit
//
//  Created by Hans Rietmann on 06/12/2021.
//

import Foundation
import LogKit





extension Strategy {
    
    
    
    func makeOrders(at tick: Tick) async throws {
        let indicator = try indicator(at: tick)
        let exits: [(OrderRequestParams, OrderBracket)] = try await delegate
            .openPositions(on: tick.asset)
            .compactMap {
                guard let exit = exit($0, by: indicator, at: tick) else { return nil }
                return (exit, $0)
            }
        for exit in exits {
            try await delegate.place(exit: exit.0, to: exit.1, at: tick)
        }
        
        guard let indicator = indicator else { return }
        guard let entry = entry(by: indicator) else { return }
        if entry.tradeSide == .sell, !tick.asset.shortable { return }
//        guard tick.buyingPower >= entry.price * entry.quantity else { return }
        do { try await delegate.place(entry: entry, at: tick) }
        catch { logError(error) }
    }
    
    
    
}
