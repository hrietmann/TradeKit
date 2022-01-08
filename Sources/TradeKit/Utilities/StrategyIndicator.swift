//
//  StrategyIndicator.swift
//  TradeKit
//
//  Created by Hans Rietmann on 06/12/2021.
//

import Foundation





public struct StrategyIndicator {
    enum Trend { case bullish, bearish }
    let trend: Trend
    let areaOfValue: PositionSide
    let trigger: OrderSide
    let tick: Tick
}
