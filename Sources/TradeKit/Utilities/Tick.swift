//
//  Tick.swift
//  TradeKit
//
//  Created by Hans Rietmann on 06/12/2021.
//

import Foundation



public struct Tick {
    let asset: Asset
    let candle: Candle
    let candles: ArraySlice<Candle>
    let askPrice: Double
    let bidPrice: Double
    let buyingPower: Double
    let equity: Double
}
