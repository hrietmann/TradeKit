//
//  ListenerDelegate.swift
//  TradeKit
//
//  Created by Hans Rietmann on 12/12/2021.
//

import Foundation





public protocol ListenerDelegate: Actor {
    
    
    var start: Date { get }
    
    var end: Date! { get }
    
    var broker: Broker { get }
    
    var strategy: Strategy { get }
    
    var initialCash: Double { get }
    
    var equity: Double { get set }
    
    var buyingPower: Double { get set }
    
    var cash: Double { get set }
    
    var assets: Dictionary<AssetSymbol, Asset> { get }
    
    func received(order: Order)
    
    func received(trade: Trade, of assetSymbol: AssetSymbol)
    
    func received(quote: Quote, of assetSymbol: AssetSymbol)
    
#if compiler(>=5.5) && canImport(_Concurrency)
    func received(tick: Tick) async throws
    #endif
    
    
}
