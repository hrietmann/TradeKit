//
//  DataStream+Params.swift
//  TradeKit
//
//  Created by Hans Rietmann on 30/11/2021.
//

import Foundation





public struct HistoricDataParams {
    
    public let asset: Asset
    public let start: Date
    public let end: Date
    
    public enum Class {
        case candles(Timeframe)
        case quotes, trades
    }
    public let `class`: Class
    
    init(_ `class`: Class, asset: Asset, start: Date, end: Date) {
        self.class = `class`
        self.asset = asset
        self.start = start
        self.end = end
    }
    
    public static func candles(of asset: Asset, from start: Date, to end: Date, each timeframe: Timeframe) -> Self
    { .init(.candles(timeframe), asset: asset, start: start, end: end) }
    
    public static func trades(of asset: Asset, from start: Date, to end: Date) -> Self
    { .init(.trades, asset: asset, start: start, end: end) }
    
    public static func quotes(of asset: Asset, from start: Date, to end: Date) -> Self
    { .init(.quotes, asset: asset, start: start, end: end) }
    
}
