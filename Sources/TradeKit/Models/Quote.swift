//
//  Quote.swift
//  TradeKit
//
//  Created by Hans Rietmann on 30/11/2021.
//

import Foundation




public protocol Quote {
    
    
    var askPrice: Double { get }
    var askSize: Double { get }
    var bidPrice: Double { get }
    var bidSize: Double { get }
    
    
}
