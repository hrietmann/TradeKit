//
//  OrderType.swift
//  TradeKit
//
//  Created by Hans Rietmann on 01/12/2021.
//

import Foundation





public enum OrderType {
    
    case market
    case limit(price: Double)
    case stop(price: Double)
    case stopLimit(stop: Double, limit: Double)
    
}
