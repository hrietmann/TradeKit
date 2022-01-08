//
//  Double.swift
//  TradeKit
//
//  Created by Hans Rietmann on 10/12/2021.
//

import Foundation




extension Double {
    
    
    public var currency: String { NumberFormatter.localizedString(from: .init(value: self), number: .currency) }
    public var percent: String {
        let formatter = NumberFormatter()
        formatter.allowsFloats = true
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.numberStyle = .percent
        formatter.locale = .current
        return formatter.string(from: .init(value: self))!
    }
    
    
}
