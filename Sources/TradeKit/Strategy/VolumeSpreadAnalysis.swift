//
//  MyStrategy.swift
//  TradeKit
//
//  Created by Hans Rietmann on 06/12/2021.
//

import Foundation
import Algorithms




extension Strategy where Self == VolumeSpreadAnalysis {
    public static func volumeSpreadAnalysis(
        managment: TradeManagment = .init(),
        buyLongOn longSOS: Array<Tick.SOS> = .trendSignals,
        sellLongOn longSOW: Array<Tick.SOW> = .all,
        sellShortOn shortSOS: Array<Tick.SOW> = .trendSignals,
        buyShortOn shortSOW: Array<Tick.SOS> = .all
    ) -> Self { .init(managment: managment, buyLongOn: longSOS, sellLongOn: longSOW, sellShortOn: shortSOS, buyShortOn: shortSOW) }
}

/// Based on VSA Youtube video : https://youtu.be/ncrqXFCQKOU
public class VolumeSpreadAnalysis: Strategy {
    
    
    public var windowSize: Int { Period._50.rawValue }
    public var delegate: StrategyDelegate!
    public let tradeManagment: TradeManagment
    
    let longEntries: Set<Tick.SOS>
    let longExits: Set<Tick.SOW>
    let shortEntries: Set<Tick.SOW>
    let shortExits: Set<Tick.SOS>
    
    init(
        managment: TradeManagment,
        buyLongOn longSOS: Array<Tick.SOS> = .trendSignals,
        sellLongOn longSOW: Array<Tick.SOW> = .all,
        sellShortOn shortSOS: Array<Tick.SOW> = .trendSignals,
        buyShortOn shortSOW: Array<Tick.SOS> = .all
    ) {
        self.tradeManagment = managment
        self.longEntries = .init(longSOS)
        self.longExits = .init(longSOW)
        self.shortEntries = .init(shortSOS)
        self.shortExits = .init(shortSOW)
    }
    
    public func indicator(at tick: Tick) throws -> StrategyIndicator? {
        let signOfStrength = tick.signOfStrength
        let signOfWeackness = tick.signOfWeackness
        
        
        let areaOfValue: PositionSide
        let trigger: OrderSide
        var indicator: StrategyIndicator
        { .init(trend: .bullish, areaOfValue: areaOfValue, trigger: trigger, tick: tick) }
        
        if let signOfStrength = signOfStrength {
            trigger = .buy
            // LONG ENTRY
            if longEntries.contains(signOfStrength) { areaOfValue = .long }
            // SHORT EXIT
            else if shortExits.contains(signOfStrength) { areaOfValue = .short }
            else { return nil }
        } else if let signOfWeackness = signOfWeackness {
            trigger = .sell
            // SHORT ENTRY
            if shortEntries.contains(signOfWeackness) { areaOfValue = .short }
            // LONG EXIT
            else if longExits.contains(signOfWeackness) { areaOfValue = .long }
            else { return nil }
        } else { return nil }
        return indicator
    }
    
}


extension Candle {
    
    var body: Double { close.value - open.value }
    var bodySpread: Double { abs(body) }
    var lowerWick: Double { min(close.value, open.value) - low.value }
    var upperWick: Double { high.value - max(close.value, open.value) }
    var wicksSpread: Double { lowerWick + upperWick }
    var spread: Double { bodySpread + wicksSpread }
    var trend: StrategyIndicator.Trend { body < 0 ? .bearish : .bullish }
    var dojiPatern: StrategyIndicator.Trend? {
        if lowerWick > bodySpread, lowerWick > upperWick { return .bullish }
        if upperWick > bodySpread, upperWick > lowerWick { return .bearish }
        return nil
    }
    
}


extension Tick {
    
    func movingAverage(_ property: KeyPath<Candle, Double> = \.close.value, in period: Period = ._20) -> Double? {
        let candles = self.candles.lazy
            .suffix(period.rawValue)
            .map { $0[keyPath: property] }
        guard candles.count == period.rawValue else { return nil }
        return candles.reduce(0, +) / Double(period.rawValue)
    }
    
    func ultraHigh(_ property: KeyPath<Candle, Double> = \.high.value, in period: Period = ._20) -> Bool? {
        let candles = self.candles.lazy
            .suffix(period.rawValue * 2)
            .map { $0[keyPath: property] }
        guard candles.count == period.rawValue * 2 else { return nil }
        guard let suffixMax = candles.suffix(period.rawValue).max() else { return nil }
        guard suffixMax == candle[keyPath: property] else { return false }
        guard let prefixMax = candles.prefix(period.rawValue).max() else { return nil }
        return suffixMax > prefixMax
    }
    
    func lower(_ property: KeyPath<Candle, Double> = \.low.value, in period: Period = ._20, offset: UInt? = nil) -> Double? {
        let candles = self.candles.lazy
            .dropLast(Int(offset ?? 0))
            .suffix(period.rawValue)
            .map { $0[keyPath: property] }
        guard candles.count == period.rawValue else { return nil }
        return candles.min()
    }
    
    func higher(_ property: KeyPath<Candle, Double> = \.low.value, in period: Period = ._20, offset: UInt? = nil) -> Double? {
        let candles = self.candles.lazy
            .dropLast(Int(offset ?? 0))
            .suffix(period.rawValue)
            .map { $0[keyPath: property] }
        guard candles.count == period.rawValue else { return nil }
        return candles.max()
    }
    
    func previous(_ position: Int) -> Candle? {
        let suffix = candles.suffix(position)
        guard suffix.count == position else { return nil }
        return suffix.first
    }
    
    public enum SOS: CaseIterable {
        case downThrust
        case sellingClimax
        case lowerBearishEffortThanResult
        case higherBearishEffortThanResult
        case noSupply
        case pseudoDownThrust
        case pseudoInverseDownThrust
        case inverseDownThrust
        case failedEffortSellingClimax
        
        public static var trendSignals: [Self] {
            [.downThrust, .sellingClimax, .lowerBearishEffortThanResult, .higherBearishEffortThanResult]
        }
        public static var continuationSignals: [Self] {
            [.noSupply, .pseudoDownThrust, .pseudoInverseDownThrust, .inverseDownThrust, .failedEffortSellingClimax]
        }
    }
    /// Sign that the market will rise
    var signOfStrength: SOS? {
        let ultraHighVolume = ultraHigh(\.volume.value, in: ._20)
        let averageVolume = movingAverage(\.volume.value, in: ._20)
        let averageSpread = movingAverage(\.bodySpread, in: ._20)
        
        if let doji = candle.dojiPatern, doji == .bullish {
            if let ultraHigh = ultraHighVolume, ultraHigh { return .downThrust }
            if let average = averageVolume, candle.volume.value > average { return .downThrust }
        }
        
        if candle.trend == .bearish,
           candle.bodySpread > candle.lowerWick, candle.bodySpread > candle.upperWick,
           candle.lowerWick > candle.upperWick, candle.lowerWick / candle.bodySpread >= 1 / 4,
           let averageSpread = averageSpread, candle.bodySpread > averageSpread,
           let previousLow = lower(\.low.value, in: ._20, offset: 1), candle.close.value < previousLow {
            if let ultraHigh = ultraHighVolume, ultraHigh { return .sellingClimax }
            if let average = averageVolume, candle.volume.value > average { return .sellingClimax }
        }
        
        if let prev = previous(1), candle.bodySpread > prev.bodySpread, candle.volume.value < prev.volume.value
        { return .lowerBearishEffortThanResult }
        
        if let prev = previous(1), candle.bodySpread < prev.bodySpread, candle.volume.value > prev.volume.value
        { return .higherBearishEffortThanResult }
        
        // Continuation signal in the continuation of trend
        if candle.bodySpread < candle.wicksSpread, candle.lowerWick > candle.bodySpread,
           let prev = previous(1), candle.bodySpread < prev.bodySpread,
           let prev2LowerVol = lower(\.volume.value, in: ._2, offset: 1), candle.volume.value < prev2LowerVol
        { return .noSupply }

        if let doji = candle.dojiPatern, doji == .bullish,
           let prev = previous(1), prev.bodySpread > candle.bodySpread,
           let prev2LowerVol = lower(\.volume.value, in: ._2, offset: 1), candle.volume.value < prev2LowerVol
        { return .pseudoDownThrust }

        if let doji = candle.dojiPatern, doji == .bearish,
           let prev = previous(1), prev.bodySpread > candle.bodySpread,
           let prev2LowerVol = lower(\.volume.value, in: ._2, offset: 1), candle.volume.value < prev2LowerVol
        { return .pseudoInverseDownThrust }

        if let doji = candle.dojiPatern, doji == .bearish,
           let averageSpread = averageSpread, candle.bodySpread < averageSpread,
           candle.bodySpread < candle.wicksSpread {
            if let ultraHigh = ultraHighVolume, ultraHigh { return .inverseDownThrust }
            if let average = averageVolume, candle.volume.value > average { return .inverseDownThrust }
        }

        if let prev1 = previous(1), let prev2 = previous(2),
           prev1.bodySpread > prev2.bodySpread, prev1.volume.value > prev2.volume.value,
           candle.trend == .bullish
        { return .failedEffortSellingClimax }
        
        return nil
    }
    
    public enum SOW: CaseIterable {
        case upThrust
        case buyingClimax
        case lowerBullishEffortThanResult
        case higherBullishEffortThanResult
        case noDemand
        case pseudoUpThrust
        case pseudoInverseUpThrust
        case inverseUpThrust
        case failedEffortBuyingClimax
        
        public static var trendSignals: [Self] {
            [.upThrust, .buyingClimax, .lowerBullishEffortThanResult, .higherBullishEffortThanResult]
        }
        public static var continuationSignals: [Self] {
            [.noDemand, .pseudoUpThrust, .pseudoInverseUpThrust, .inverseUpThrust, .failedEffortBuyingClimax]
        }
    }
    /// Sign that the market will fall
    var signOfWeackness: SOW? {
        let ultraHighVolume = ultraHigh(\.volume.value, in: ._20)
        let averageVolume = movingAverage(\.volume.value, in: ._20)
        let averageSpread = movingAverage(\.bodySpread, in: ._20)
        
        if let doji = candle.dojiPatern, doji == .bearish,
           let averageSpread = averageSpread, candle.bodySpread < averageSpread {
            if let ultraHigh = ultraHighVolume, ultraHigh { return .upThrust }
            if let average = averageVolume, candle.volume.value > average { return .upThrust }
        }
        
        if let doji = candle.dojiPatern,
           doji == .bearish || candle.upperWick / candle.bodySpread >= 1 / 4,
           let averageSpread = averageSpread, candle.bodySpread > averageSpread,
           let previousHigh = higher(\.high.value, in: ._20, offset: 1), candle.close.value > previousHigh {
            if let ultraHigh = ultraHighVolume, ultraHigh { return .buyingClimax }
            if let average = averageVolume, candle.volume.value > average { return .buyingClimax }
        }
        
        if let prev = previous(1), candle.bodySpread > prev.bodySpread, candle.volume.value < prev.volume.value
        { return .lowerBullishEffortThanResult }
        
        if let prev = previous(1), candle.bodySpread < prev.bodySpread, candle.volume.value > prev.volume.value
        { return .higherBullishEffortThanResult }
        
        // Continuation signal in the continuation of trend
        if let averageSpread = averageSpread, averageSpread > candle.bodySpread, candle.upperWick > candle.bodySpread,
           let prev2Low = lower(\.volume.value, in: ._2, offset: 1), prev2Low > candle.volume.value
        { return .noDemand }
        
        if candle.wicksSpread > candle.bodySpread,
           let prev = previous(1), prev.bodySpread > candle.bodySpread, prev.volume.value > candle.volume.value,
           let averageSpread = averageSpread, averageSpread > candle.bodySpread
        { return .pseudoUpThrust }
        
        if let doji = candle.dojiPatern, doji == .bullish,
           let prev = previous(1), prev.bodySpread > candle.bodySpread,
           let prev2LowerVol = lower(\.volume.value, in: ._2, offset: 1), prev2LowerVol > candle.volume.value
        { return .pseudoInverseUpThrust }
        
        if let doji = candle.dojiPatern, doji == .bullish,
           let averageSpread = averageSpread, candle.spread < averageSpread {
            if let ultraHigh = ultraHighVolume, ultraHigh { return .inverseUpThrust }
            if let average = averageVolume, candle.volume.value > average { return .inverseUpThrust }
        }
        
        if let prev2 = previous(2), let prev1 = previous(1), prev2.bodySpread < prev1.bodySpread, prev2.volume.value < prev1.volume.value,
           prev2.trend == .bullish, prev1.trend == .bullish, candle.trend == .bearish, candle.close.value < prev1.close.value
        { return .failedEffortBuyingClimax }
        
        return nil
    }
    
}



public extension Array where Element == Tick.SOW {
    static var all: [Element] { Element.allCases }
    static var trendSignals: [Element] { Element.trendSignals }
    static var continuationSignals: [Element] { Element.continuationSignals }
}



public extension Array where Element == Tick.SOS {
    static var all: [Element] { Element.allCases }
    static var trendSignals: [Element] { Element.trendSignals }
    static var continuationSignals: [Element] { Element.continuationSignals }
}
