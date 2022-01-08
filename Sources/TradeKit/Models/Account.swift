//
//  Account.swift
//  TradeKit
//
//  Created by Hans Rietmann on 01/12/2021.
//

import Foundation





public protocol Account {
    
    
    
    var totalCash: Double { get }
    var buyingPower: Double { get }
    var totalEquity: Double { get }
    
    
    
    init(cash: Double)
    
    
    
}
