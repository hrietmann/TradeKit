//
//  Asset.swift
//  TradeKit
//
//  Created by Hans Rietmann on 30/11/2021.
//

import Foundation




public typealias AssetSymbol = String

public protocol Asset {
    
    var symbol: AssetSymbol { get }
    var `class`: AssetClass { get }
    var shortable: Bool { get }
    var fractionable: Bool { get }
    
}


public enum AssetClass: String, Codable, CaseIterable {
    case market = "us_equity"
    case crypto
}
