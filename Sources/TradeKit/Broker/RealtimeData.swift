//
//  RealtimeData.swift
//  TradeKit
//
//  Created by Hans Rietmann on 19/12/2021.
//

import Foundation



public enum RealtimeData {
    case candle(Candle, AssetSymbol)
    case trade(Trade, AssetSymbol)
    case quote(Quote, AssetSymbol)
    case order(Order)
}
