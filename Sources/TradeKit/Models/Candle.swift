//
//  Candle.swift
//  TradeKit
//
//  Created by Hans Rietmann on 30/11/2021.
//

import Foundation




public protocol Candle {
    
    
    var open: Number { get }
    var high: Number { get }
    var low: Number { get }
    var close: Number { get }
    var volume: Number { get }
    var date: Date { get }
    
    
}
