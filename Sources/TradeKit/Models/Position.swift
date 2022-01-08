//
//  Position.swift
//  TradeKit
//
//  Created by Hans Rietmann on 30/11/2021.
//

import Foundation





public protocol Position {
    
    
    var side: PositionSide { get }
    var symbol: AssetSymbol { get }
    var quantity: Double { get }
    var entryPrice: Double { get }
    
    
}
