//
//  PositionUtni.swift
//  TradeKit
//
//  Created by Hans Rietmann on 01/12/2021.
//

import Foundation





public enum PositionUnit {
    case quantity(quantity: Double)
    case percentage(percentage: Double)
    case all
    
    func quantity(for accountEquity: Double, price: Double) -> Double {
        switch self {
        case .quantity(let quantity): return quantity
        case .percentage(let percentage): return ((percentage / 100) * accountEquity) / price
        case .all: return accountEquity / price
        }
    }
}
