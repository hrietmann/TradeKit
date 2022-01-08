//
//  Strategy.swift
//  TradeKit
//
//  Created by Hans Rietmann on 06/12/2021.
//

import Foundation




public protocol Strategy {
    
    
    var windowSize: Int { get }
    
    var delegate: StrategyDelegate! { get set }
    
    var tradeManagment: TradeManagment { get }
    
    func indicator(at tick: Tick) throws -> StrategyIndicator?
    
    
}



extension Strategy {
    
    
    func entry(by indicator: StrategyIndicator) -> OrderRequestParams? {
        let price: Double
        var quantity: Double {
            let q: Double
            switch tradeManagment.entryQuantity {
            case .quantity(let quantity): q = quantity
            case .percentage(let percentage): q = ((percentage / 100) * indicator.tick.equity) / price
            case .all: q = indicator.tick.equity / price
            }
            if indicator.tick.asset.fractionable, indicator.tick.asset.class == .crypto { return q }
            return q.rounded()
        }
        
        // BUY LONG
        if indicator.areaOfValue == .long, indicator.trigger == .buy {
            price = indicator.tick.askPrice
            if quantity == 0 { return nil }
            return .buy(quantity: quantity, asset: indicator.tick.asset, price: price)
        }
        
        // SELL SHORT
        if indicator.areaOfValue == .short, indicator.trigger == .sell {
            price = indicator.tick.bidPrice
            if quantity == 0 { return nil }
            return .sell(quantity: quantity, asset: indicator.tick.asset, price: price)
        }
        
        return nil
    }
    
    func exit(_ position: OrderBracket, by indicator: StrategyIndicator?, at tick: Tick) -> OrderRequestParams? {
        switch state(of: position, at: tick) {
        case let .lookingForProfit(buyPrice, sellPrice):
            
            // PROFIT EXITS
            guard let indicator = indicator else { return nil }
            
            // SELL LONG
            if position.side == .long, indicator.areaOfValue == .long, indicator.trigger == .sell, tick.bidPrice >= sellPrice
            { return .sell(quantity: position.quantity, asset: tick.asset, price: sellPrice) }
            
            // BUY SHORT
            if position.side == .short, indicator.areaOfValue == .short, indicator.trigger == .buy, tick.askPrice <= buyPrice
            { return .buy(quantity: position.quantity, asset: tick.asset, price: buyPrice) }
            
        case let .lookingForLoss(buyPrice, sellPrice):
            
            // LOSS EXITS
            
            // SELL LONG
            if position.side == .long, tick.bidPrice >= sellPrice
            { return .sell(quantity: position.quantity, asset: tick.asset, price: sellPrice) }
        
            // BUY SHORT
            if position.side == .short, tick.askPrice <= buyPrice
            { return .buy(quantity: position.quantity, asset: tick.asset, price: buyPrice) }
            
        case let .lookingForLiquidation(buyPrice, sellPrice):
            
            // LIQUIDATION EXITS
            switch position.side {
            case .long: return .sell(quantity: position.quantity, asset: tick.asset, price: sellPrice)
            case .short: return .buy(quantity: position.quantity, asset: tick.asset, price: buyPrice)
            }
        }
        return nil
    }
    
    private func state(of position: OrderBracket, at tick: Tick) -> ExitState {
        
        let entryFilledAt = position.entryFilledAt!
        let positionLifeDuration = tick.candle.date.timeIntervalSince1970 - entryFilledAt.timeIntervalSince1970
        let longPolicy = tradeManagment.longPositionPolicy
        let shortPolicy = tradeManagment.shortPositionPolicy
        let maxLifeDuration = position.side == .long ? longPolicy.maxLifeDuration.duration! : shortPolicy.maxLifeDuration.duration!
        let extremeDuration = position.side == .short ? longPolicy.extremeDuration.duration! : shortPolicy.extremeDuration.duration!
        
        let priceEvaluation: Amount
        var buyPrice: Double {
            switch priceEvaluation {
            case .percent(let percent): return position.entryPrice! * (1 - percent / 100)
            case .price(let price): return position.entryPrice! - price
            }
        }
        var sellPrice: Double {
            switch priceEvaluation {
            case .percent(let percent): return position.entryPrice! * (1 + percent / 100)
            case .price(let price): return position.entryPrice! + price
            }
        }
        
        var profitPriceEval: Amount { position.side == .long ? longPolicy.profit : shortPolicy.profit }
        var lossPriceEval: Amount { position.side == .short ? longPolicy.loss : shortPolicy.loss }
        
        switch positionLifeDuration {
        case ..<maxLifeDuration:
            priceEvaluation = profitPriceEval
            return .lookingForProfit(buyPrice: buyPrice, sellPrice: sellPrice)
            
        case maxLifeDuration..<extremeDuration:
            priceEvaluation = lossPriceEval
            return .lookingForLoss(buyPrice: sellPrice, sellPrice: buyPrice)
            
        default:
            var liquidation: ExitState { .lookingForLiquidation(buyPrice: tick.askPrice, sellPrice: tick.bidPrice) }
            if position.side == .long, longPolicy.canExitAtAnyCost { return liquidation }
            if position.side == .short, shortPolicy.canExitAtAnyCost { return liquidation }
            priceEvaluation = lossPriceEval
            return .lookingForLoss(buyPrice: sellPrice, sellPrice: buyPrice)
        }
    }
    
    
}


fileprivate enum ExitState {
    case lookingForProfit(buyPrice: Double, sellPrice: Double)
    case lookingForLoss(buyPrice: Double, sellPrice: Double)
    case lookingForLiquidation(buyPrice: Double, sellPrice: Double)
}
