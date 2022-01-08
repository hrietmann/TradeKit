//
//  EnvironmentDelegate+didFillCancel.swift
//  TradeKit
//
//  Created by Hans Rietmann on 10/12/2021.
//

import Foundation



extension TradeEnvironment {
    
    
    
    public func received(order: Order) {
        guard let (positionIndex, isEntry) = position(for: order) else { return }
        switch order.currentStatus {
        case .canceled: didCancel(order: order, at: positionIndex, as: isEntry)
        case .closed: didFill(order: order, at: positionIndex, as: isEntry)
        default: return
        }
        orders.removeValue(forKey: order.id)
    }
    
    private func didFill(order: Order, at positionIndex: Int, as entry: Bool) {
        if entry { openBracketOrders[positionIndex].fillingEntry(order) }
        else {
            var position = openBracketOrders[positionIndex]
            position.fillingExit(order)
            if let profit = position.profit?.amount
            { equity += profit }
            filledBracketOrders.insert(position)
            openBracketOrders.remove(at: positionIndex)
        }
        let cost = order.cost!
        cash -= cost
//        if entry {
//            guard order.orderSide == .sell else { return }
//            buyingPower -= abs(cost)
//        } else {
//            guard order.orderSide == .buy else { return }
//            buyingPower += abs(cost)
//        }
    }
    
    private func didCancel(order: Order, at positionIndex: Int, as entry: Bool) {
        if entry { openBracketOrders.remove(at: positionIndex) }
        else { openBracketOrders[positionIndex].cancelExit() }
    }
    
    private func position(for order: Order) -> (index: Int, isEntry: Bool)? {
        let positionIndex: Int
        let isEntryOrder: Bool
        
        if let position = openBracketOrders.lazy.firstIndex(where: { $0.entryOrderID == order.id })
        { positionIndex = position ; isEntryOrder = true }
        else if let position = openBracketOrders.firstIndex(where: { $0.exitOrderID == order.id })
        { positionIndex = position ; isEntryOrder = false }
        else { return nil }
        return (index: positionIndex, isEntry: isEntryOrder)
    }
    
    
    
}
