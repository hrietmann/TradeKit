//
//  TradeManagment.swift
//  TradeKit
//
//  Created by Hans Rietmann on 06/12/2021.
//

import Foundation



public struct TradeManagment {
    
    let entryQuantity: PositionUnit
    
    public struct PositionPolicy {
        let maxLifeDuration: DateComponents
        let extremeDuration: DateComponents
        let canExitAtAnyCost: Bool
        let profit: Amount
        let loss: Amount
        
        public init(
            minProfitOf profit: Amount = .percent(value: 0.1),
            considerMaxLoss loss: Amount = .percent(value: 0.1),
            after maxLifeDuration: DateComponents = DateComponents().hours(1),
            exitAtAnyCost canExitAtAnyCost: Bool = true,
            after extremeDuration: DateComponents = DateComponents().hours(2)
        ) {
            self.maxLifeDuration = maxLifeDuration
            self.extremeDuration = extremeDuration
            self.canExitAtAnyCost = canExitAtAnyCost
            self.profit = profit
            self.loss = loss
        }
    }
    let longPositionPolicy: PositionPolicy
    let shortPositionPolicy: PositionPolicy
    
    
    public init(
        enterPositionWith entryQuantity: PositionUnit = .percentage(percentage: 0.5),
        exitLongPositionWith longPositionPolicy: PositionPolicy = .init(
            minProfitOf: .percent(value: 0.2),
            considerMaxLoss: .percent(value: 0.2), after: .hours(2),
            exitAtAnyCost: true, after: .hours(6)
        ),
        exitShortPositionWith shortPositionPolicy: PositionPolicy = .init(
            minProfitOf: .percent(value: 0.2),
            considerMaxLoss: .percent(value: 0.2), after: .hours(2),
            exitAtAnyCost: true, after: .hours(6)
        )
    ) {
        self.entryQuantity = entryQuantity
        self.longPositionPolicy = longPositionPolicy
        self.shortPositionPolicy = shortPositionPolicy
    }
}



extension TradeManagment {
    
    func exit(position: OrderBracket, at tick: Tick) -> OrderRequestParams? {
        guard let entryPrice = position.entryPrice,
              let entryFilledAt = position.entryFilledAt
        else { return nil }
        let positionLifeDuration = tick.candle.date.timeIntervalSince1970 - entryFilledAt.timeIntervalSince1970
        
        switch position.side {
        case .short:
            // BUY EXIT
            guard let maxLifeDuration = shortPositionPolicy.maxLifeDuration.duration,
                  let extremeDuration = shortPositionPolicy.extremeDuration.duration
            else { return nil }
            let maxPrice: Double
            switch positionLifeDuration {
            case ...maxLifeDuration:
                // Profit time period
                switch shortPositionPolicy.profit {
                case .percent(let percent): maxPrice = entryPrice * (1 - percent / 100)
                case .price(let price): maxPrice = entryPrice - price
                }
                
            case maxLifeDuration...extremeDuration:
                // Loss time period
                switch shortPositionPolicy.loss {
                case .percent(let percent): maxPrice = entryPrice * (1 + percent / 100)
                case .price(let price): maxPrice = entryPrice + price
                }
                
            case extremeDuration...:
                // Liquidation time period
                maxPrice = .infinity
            default: return nil
            }
            if positionLifeDuration >= maxLifeDuration {
            } else {
                
            }
            return .buy(quantity: position.quantity, asset: tick.asset, price: maxPrice)
            
        case .long:
            // SELL EXIT
            guard let maxLifeDuration = longPositionPolicy.maxLifeDuration.duration,
                  let extremeDuration = longPositionPolicy.extremeDuration.duration
            else { return nil }
            let minPrice: Double
            switch positionLifeDuration {
            case ..<maxLifeDuration:
                // Profit time period
                switch longPositionPolicy.profit {
                case .percent(let percent): minPrice = entryPrice * (1 + percent / 100)
                case .price(let price): minPrice = entryPrice + price
                }
                
            case maxLifeDuration..<extremeDuration:
                // Loss time period
                switch longPositionPolicy.loss {
                case .percent(let percent): minPrice = entryPrice * (1 - percent / 100)
                case .price(let price): minPrice = entryPrice - price
                }
                
            case extremeDuration...:
                // Liquidation time period
                minPrice = 0
            default: return nil
            }
            return .sell(quantity: position.quantity, asset: tick.asset, price: minPrice)
        }
    }
    
}



extension DateComponents {
    
    var duration: TimeInterval? {
        let from = Date(timeIntervalSince1970: 0)
        return Calendar.GMT0.date(byAdding: self, to: from)?.timeIntervalSince1970
    }
    
}


public extension DateComponents {
    
    static func valid(month: Int, day: Int, year: Int, hour: Int = 0, minute: Int = 0) -> DateComponents {
        var comps = DateComponents()
        comps.month = month
        comps.day = day
        comps.year = year
        comps.hour = hour
        comps.minute = minute
        comps.calendar = .GMT0
        comps.timeZone = Calendar.GMT0.timeZone
        comps.nanosecond = 0
        comps.second = 0
        comps.weekOfYear = nil
        comps.weekday = nil
        comps.weekdayOrdinal = nil
        comps.weekOfMonth = nil
        comps.era = nil
        comps.isLeapMonth = nil
        comps.quarter = nil
        comps.yearForWeekOfYear = nil
        return comps
    }
    
    func adding(_ value: Int, _ component: Calendar.Component) -> DateComponents {
        var comps = self
        let currentValue = comps.value(for: component) ?? 0
        let newValue = value + currentValue
        comps.setValue(newValue, for: component)
        return comps
    }
    
    func years(_ value: Int) -> DateComponents {
        var comps = self
        comps.year = value
        return comps
    }
    static func years(_ value: Int) -> DateComponents { .init().years(value) }
    
    func months(_ value: Int) -> DateComponents {
        var comps = self
        comps.month = value
        return comps
    }
    static func months(_ value: Int) -> DateComponents { .init().months(value) }
    
    func weeks(_ value: Int) -> DateComponents {
        var comps = self
        comps.weekOfYear = value
        return comps
    }
    static func weeks(_ value: Int) -> DateComponents { .init().weeks(value) }
    
    func days(_ value: Int) -> DateComponents {
        var comps = self
        comps.day = value
        return comps
    }
    static func days(_ value: Int) -> DateComponents { .init().days(value) }
    
    func hours(_ value: Int) -> DateComponents {
        var comps = self
        comps.hour = value
        return comps
    }
    static func hours(_ value: Int) -> DateComponents { .init().hours(value) }
    
    func minutes(_ value: Int) -> DateComponents {
        var comps = self
        comps.minute = value
        return comps
    }
    static func minutes(_ value: Int) -> DateComponents { .init().minutes(value) }
    
    func seconds(_ value: Int) -> DateComponents {
        var comps = self
        comps.second = value
        return comps
    }
    static func seconds(_ value: Int) -> DateComponents { .init().seconds(value) }
    
    var validDate: Date? {
        return Calendar.GMT0.date(from: self)
    }
    
}
