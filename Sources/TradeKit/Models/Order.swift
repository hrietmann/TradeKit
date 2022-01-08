//
//  Order.swift
//  TradeKit
//
//  Created by Hans Rietmann on 30/11/2021.
//

import Foundation



public protocol Order: Codable {
    
    var id: UUID { get }
    var symbol: AssetSymbol { get }
    var createdAtDate: Date { get }
    var quantity: Double { get }
    var limitPrice: Double { get }
    var filledAtPrice: Double? { get set }
    var filledAtDate: Date? { get set }
    var orderSide: OrderSide { get }
    var currentStatus: OrderStatus { get set }
    
}



extension Order {
    
    var cost: Double? {
        guard let price = filledAtPrice else { return nil }
        switch orderSide {
        case .buy: return quantity * price
        case .sell: return -quantity * price
        }
    }
    
    func needsToBeExpired(at tick: Tick) -> Bool {
        if filledAtDate != nil { return false }
        guard let expiration = Calendar.GMT0.date(byAdding: .hour, value: 4, to: createdAtDate) else { return false }
        return tick.candle.date >= expiration
    }
    
}
