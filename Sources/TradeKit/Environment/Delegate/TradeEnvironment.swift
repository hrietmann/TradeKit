//
//  EnvironmentDelegate.swift
//  TradeKit
//
//  Created by Hans Rietmann on 07/12/2021.
//

import Foundation
import Collections



public protocol TradeEnvironment: StrategyDelegate, ListenerDelegate {
    
    
    // Key properties
    var listner: Listener { get }
    
    // Trade managment
    var openBracketOrders: Deque<OrderBracket> { get set }
    var filledBracketOrders: Set<OrderBracket> { get set }
    var orders: Dictionary<UUID, Order> { get set }
    
    // Trade managment
    #if compiler(>=5.5) && canImport(_Concurrency)
    func place(order: OrderRequestParams, at date: Date) async throws -> Order
    #endif
    
}
