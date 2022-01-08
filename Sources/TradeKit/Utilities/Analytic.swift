//
//  Analytic.swift
//  TradeKit
//
//  Created by Hans Rietmann on 07/12/2021.
//

import Foundation





public struct Analytic {
    public var amount: Double
    public var percent: Double
    public var percentString: String { (percent / 100).percent }
    
    static func + (lhs: Analytic, rhs: Analytic) -> Analytic
    { .init(amount: lhs.amount + rhs.amount, percent: lhs.percent + rhs.percent) }
    
    static func - (lhs: Analytic, rhs: Analytic) -> Analytic
    { .init(amount: lhs.amount - rhs.amount, percent: lhs.percent - rhs.percent) }
    
    static func / (lhs: Analytic, rhs: Analytic) -> Analytic
    { .init(amount: lhs.amount / rhs.amount, percent: lhs.percent / rhs.percent) }
    
    static func / (lhs: Analytic, rhs: Double) -> Analytic
    { .init(amount: lhs.amount / rhs, percent: lhs.percent / rhs) }
    
    static func / (lhs: Analytic, rhs: Int) -> Analytic
    { .init(amount: lhs.amount / Double(rhs), percent: lhs.percent / Double(rhs)) }
}
