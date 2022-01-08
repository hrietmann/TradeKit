//
//  DataStreamPage.swift
//  TradeKit
//
//  Created by Hans Rietmann on 30/11/2021.
//

import Foundation




public enum HistoricDataPage {
    
    case candles([Candle])
    case quotes([Quote])
    case trades([Trade])
    
    public var candles: [Candle]? {
        switch self {
        case .candles(let array): return array
        default: return nil
        }
    }
    
    public var quotes: [Quote]? {
        switch self {
        case .quotes(let array): return array
        default: return nil
        }
    }
    
    public var trades: [Trade]? {
        switch self {
        case .trades(let array): return array
        default: return nil
        }
    }
    
}
