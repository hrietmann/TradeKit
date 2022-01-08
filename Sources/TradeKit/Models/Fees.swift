//
//  Fees.swift
//  TradeKit
//
//  Created by Hans Rietmann on 13/12/2021.
//

import Foundation




public protocol Fees {
    
    var takerFee: Amount { get }
    var makerFee: Amount { get }
    
}
