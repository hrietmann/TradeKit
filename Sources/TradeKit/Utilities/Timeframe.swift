//
//  Timeframe.swift
//  TradeKit
//
//  Created by Hans Rietmann on 30/11/2021.
//

import Foundation





public enum Timeframe {
    case minute
    case minutes(minutes: Int)
    case hour
    case hours(hours: Int)
    case day
}
