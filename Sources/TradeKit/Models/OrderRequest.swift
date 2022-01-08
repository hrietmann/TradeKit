//
//  OrderRequest.swift
//  TradeKit
//
//  Created by Hans Rietmann on 01/12/2021.
//

import Foundation




public protocol OrderRequest {
    
    
    var quantity: Double { get }
    var tradeSide: OrderSide { get }
    var tradeType: OrderType { get }
    
    init(params: OrderRequestParams)
    
    
}


public enum OrderRequestParams {
    
    
    case buy(quantity: Double, asset: Asset, price: Double)
    case sell(quantity: Double, asset: Asset, price: Double)
    
    
    public var quantity: Double {
        switch self {
        case .buy(let quantity, _, _): return quantity
        case .sell(let quantity, _, _): return quantity
        }
    }
    
    public var asset: Asset {
        switch self {
        case .buy(_, let asset, _): return asset
        case .sell(_, let asset, _): return asset
        }
    }
    
    public var price: Double {
        switch self {
        case .buy(_, _, let price): return price
        case .sell(_, _, let price): return price
        }
    }
    
    public var tradeSide: OrderSide {
        switch self {
        case .buy: return .buy
        case .sell: return .sell
        }
    }
    
    
}
