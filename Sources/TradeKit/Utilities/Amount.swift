//
//  Amount.swift
//  TradeKit
//
//  Created by Hans Rietmann on 13/12/2021.
//

import Foundation



public enum Amount {
    /// Value in percent (i.e. : 10.5 for 10,5 %)
    case percent(value: Double)
    case price(value: Double)
}
