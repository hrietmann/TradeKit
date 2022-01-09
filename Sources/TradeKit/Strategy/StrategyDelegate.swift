//
//  StrategyDelegate.swift
//  TradeKit
//
//  Created by Hans Rietmann on 06/12/2021.
//

import Foundation



#if compiler(>=5.5) && canImport(_Concurrency)
public protocol StrategyDelegate {
    
    
    
    var broker: Broker { get }
    
    func openPositions(on asset: Asset) async throws -> ArraySlice<OrderBracket>
    
    func place(entry newOrder: OrderRequestParams, at tick: Tick) async throws
    
    func place(exit newOrder: OrderRequestParams, to position: OrderBracket, at tick: Tick) async throws
    
    
    
}
#endif
