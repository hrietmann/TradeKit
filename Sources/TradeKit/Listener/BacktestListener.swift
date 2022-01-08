//
//  ListenerSimulation.swift
//  TradeKit
//
//  Created by Hans Rietmann on 11/12/2021.
//

import Foundation
import Collections
import CollectionConcurrencyKit
import LogKit
import Algorithms




actor BacktestListener: Listener {
    
    public var ticks = 0
    public var delegate: ListenerDelegate!
    private let broker: Broker
    private let start, end: Date
    
    
    init(broker: Broker, start: Date, end: Date) {
        self.broker = broker
        self.start = start
        self.end = end
    }
    
    init(delegate: ListenerDelegate) async {
        self.delegate = delegate
        self.broker = await delegate.broker
        self.start = await delegate.start
        self.end = await delegate.end
    }
    
    
    private func generateTicks(forEach minutes: Range<Int>) async throws {
        var chunkBuffer = [AssetSymbol:Deque<Candle?>]()
        let minutesToDo = minutes.upperBound
        var minutesDone = 0
        let chunkSize = broker.maxHistoricDataPageItems
        let minutesChunks = minutes.chunks(ofCount: chunkSize)
        let windowSize = await delegate.strategy.windowSize
        let assets = await delegate.assets
        let assetsCount = assets.count
        
        for minutesChunck in minutesChunks {
            guard let first = minutesChunck.first, let last = minutesChunck.last else { continue }
            let range = first..<last + 1
            
            log(level: .level0, as: .downloading, "Downloading candles buffer of \(minutesChunck.count * assetsCount) items...")
            guard let candles = try await candles(in: range, associatedWith: chunkBuffer) else { continue }
            log(level: .level0, as: .majorTaskDone, "\(minutesChunck.count * assetsCount) candles downloaded successfully!")
            
            let bufferCount = chunkBuffer.isEmpty ? 0 : windowSize
            var loopStart = Date()
            for minuteIndex in (windowSize - 1)..<range.count + bufferCount {
                try await assets.concurrentForEach { (symbol, asset) in
                    guard let candle = candles[asset.symbol]![minuteIndex] else { return }
                    let window = candles[asset.symbol]!.lazy
                        .prefix(through: minuteIndex)
                        .suffix(windowSize)
                        .compactMap { $0 }
                    try await self.generateTick(for: asset, window: .init(window), at: candle)
                    self.ticks += 1
                }
                
                let totalMinutesDone = minuteIndex + minutesDone
                guard totalMinutesDone % 1000 == 0, totalMinutesDone != 0 else { continue }
                let percent = Double(totalMinutesDone) / Double(minutesToDo)
                let loopDuration = Calendar.GMT0.dateComponents([.hour, .minute, .second, .nanosecond], from: loopStart, to: Date())
                let duration = DateComponentsFormatter.localizedString(from: loopDuration, unitsStyle: .brief)!
                logInfo("Backtest \(percent.percent) done, \(totalMinutesDone) / \(minutesToDo) minutes. (took \(duration))")
                loopStart = Date()
            }
            minutesDone += range.count
            chunkBuffer = .init(uniqueKeysWithValues: candles.map { (key: $0.key, value: Deque<Candle?>.init($0.value.suffix(windowSize))) })
        }
    }
    
    private func iterate(through minutes: Range<Int>) async throws {
        let calendar = Calendar.GMT0
        let windowSize = await delegate.strategy.windowSize
        let assets = await delegate.assets
        let bufferSize = broker.maxHistoricDataPageItems
        
        let keys = minutes.map { calendar.date(byAdding: .minute, value: $0, to: start)! }
        let values = minutes.map { _ in [AssetSymbol:Candle]() }
        var buffer = OrderedDictionary<Date,Dictionary<AssetSymbol,Candle>>(uniqueKeys: keys, values: values)
        
        var bufferRange = Date(timeIntervalSince1970: 0)..<start
        
        var loopStart = Date()
        for minute in minutes {
            let windowEnd = calendar.date(byAdding: .minute, value: minute, to: start)!
//            let windowStart = calendar.date(byAdding: .minute, value: -windowSize + 1, to: windowEnd)!
//            let windowRange = windowStart...windowEnd
            
            if !bufferRange.contains(windowEnd) {
                // Update buffer
                // 1. Remove all candles not in the window range
//                buffer.removeAll(where: { !windowRange.contains($0.key) })
                
                // 2. Update buffer range
                let bufferEnd = calendar.date(byAdding: .minute, value: bufferSize, to: windowEnd)!
                bufferRange = windowEnd..<bufferEnd
                
                // 3. Download next batch of candles
                loopStart = Date()
                let start = DateFormatter.localizedString(from: bufferRange.lowerBound, dateStyle: .full, timeStyle: .full)
                let end = DateFormatter.localizedString(from: bufferRange.upperBound, dateStyle: .full, timeStyle: .full)
                log(level: .level0, as: .downloading, "Downloading \(bufferSize) candles for each \(assets.count) assets from \(start) to \(end)...")
                try await assets
                    .concurrentForEach { (symbol, asset) in
                        let batches = self.broker.historicData(of: .candles(of: asset, from: bufferRange.lowerBound, to: bufferRange.upperBound, each: .minute))
                        for try await batch in batches {
                            
                            // 4. Add the newly downloaded candles
                            batch.candles?.forEach { buffer[$0.date]?[symbol] = $0 }
                        }
                    }
                let loopDuration = Calendar.GMT0.dateComponents([.hour, .minute, .second, .nanosecond], from: loopStart, to: Date())
                let duration = DateComponentsFormatter.localizedString(from: loopDuration, unitsStyle: .brief)!
                log(level: .level0, as: .majorTaskDone, "Candles downloaded successfully! (took \(duration))")
                loopStart = Date()
            }
            
            // Create window
            guard minute >= windowSize - 1 else { continue }
            let windowBuffer = buffer.prefix(windowSize)
            try await assets.lazy
                .concurrentForEach { (symbol, asset) in
                    // 1. Get asset candles that are in the window range
                    let window = windowBuffer.compactMap { $0.value[symbol] }
                    // 2. Filter according to the window count == window size
                    guard window.count == windowSize, let candle = window.last else { return }
                    // 3. Call 'generateTick'
                    async let equityReq = self.delegate.equity
                    async let buyingPowerReq = self.delegate.buyingPower
                    let (equity, buyingPower) = await (equityReq, buyingPowerReq)
                    let tick = Tick(asset: asset, candle: candle, candles: .init(window), askPrice: candle.high.value, bidPrice: candle.low.value, buyingPower: buyingPower, equity: equity)
                    try await self.delegate.received(tick: tick)
                }
            buffer.removeFirst()
            
            
//            try await assets.lazy
//            // 1. Get asset candles that are in the window range
//                .compactMap { (symbol, asset) -> (AssetSymbol, Asset, ArraySlice<Candle>, Candle)? in
//                    let window = buffer.lazy.filter({ $0.assetSymbol == symbol && windowRange.contains($0.date) })
//
//                    // 2. Filter according to the window count == window size
//                    guard window.count == windowSize, let candle = window.last else { return nil }
//                    let candles = window
//                        .sorted(by: { $0.date < $1.date })
//                        .map { $0.candle }
//                    return (symbol, asset, .init(candles), candle.candle)
//                }
//
//            // 3. Call 'generateTick'
//                .concurrentForEach { (symbol, asset, window, candle) in
//                    async let equityReq = self.delegate.equity
//                    async let buyingPowerReq = self.delegate.buyingPower
//                    let (equity, buyingPower) = await (equityReq, buyingPowerReq)
//                    let tick = Tick(asset: asset, candle: candle, candles: window, askPrice: candle.high, bidPrice: candle.low, buyingPower: buyingPower, equity: equity)
//                    try await self.delegate.received(tick: tick)
//                }
            
            // Checkpoint
            guard (minute + 1) % 1000 == 0 else { continue }
            let percent = Double(minute + 1) / Double(minutes.count)
            let loopDuration = Calendar.GMT0.dateComponents([.hour, .minute, .second, .nanosecond], from: loopStart, to: Date())
            let duration = DateComponentsFormatter.localizedString(from: loopDuration, unitsStyle: .brief)!
            logInfo("Backtest \(percent.percent) done, \(minute + 1) / \(minutes.count) minutes. (took \(duration))")
            loopStart = Date()
        }
    }
    
    
    
    
    public func listen() async throws {
        let sessionStart = Date()
        let startDate = DateFormatter.localizedString(from: start, dateStyle: .full, timeStyle: .short)
        let endDate = DateFormatter.localizedString(from: end, dateStyle: .full, timeStyle: .short)
        let assets = await delegate.assets
        log(level: .level0, as: .computing, "Starting backtest from \(startDate) to \(endDate) for assets:", assets.map { $0.key })
        
        let minutes = 0..<(Calendar.GMT0.dateComponents([.minute], from: start, to: end).minute ?? 1)
        //        try await generateTicks(forEach: minutes)
        try await iterate(through: minutes)
        
        let sessionDuration = Calendar.GMT0.dateComponents([.hour, .minute, .second, .nanosecond], from: sessionStart, to: Date())
        let duration = DateComponentsFormatter.localizedString(from: sessionDuration, unitsStyle: .brief)!
        log(level: .level0, as: .majorTaskDone, "Backtest done in \(duration) !")
        
        
        //        var candlesBuffer = try await candles
        //        Terminal.print(level: .level0, as: .majorTaskDone, "Candles downloaded successfully!")
        //        let dateRange = start...end
        //        let candlesCount = candlesBuffer.lazy
        //            .filter { assetBuffer in
        //                guard let firstCandleDate = assetBuffer.value.lazy.first?.date,
        //                      dateRange.contains(firstCandleDate),
        //                      let lastCandleDate = assetBuffer.value.lazy.last?.date,
        //                      dateRange.contains(lastCandleDate)
        //                else { return false }
        //                return true
        //            }
        //            .map { $0.value.count }
        //            .reduce(0, +)
        //        guard candlesCount != 0 else {
        //            struct NoCandles: LocalizedError { var errorDescription: String? { "No candles found for any assets!" } }
        //            throw NoCandles()
        //        }
        //
        //        let windowSize = await max(delegate.strategy.windowSize, 1)
        //        Terminal.print(level: .level0, as: .loading, "Backtesting from \(startDate) to \(endDate)...")
        //
        //        var dateComponents = calendar.dateComponents(in: calendar.timeZone, from: start)
        //        var minute = dateComponents.minute ?? 0
        //        var tickDate = calendar.date(from: dateComponents)!
        //        var loopStart = Date()
        //        while tickDate <= end {
        //
        //            try await assets
        //                .lazy
        //                .compactMap { (symbol, asset) -> (Asset, Slice<Deque<Candle>>, Candle)? in
        //                    guard let candles = candlesBuffer[symbol]?.prefix(windowSize),
        //                          let candle = candles.last else { return nil }
        //                    return (asset, candles, candle)
        //                }
        //                .filter { $0.1.count == windowSize && $0.2.date == tickDate }
        //                .concurrentForEach { (asset, candles, candle) in
        //                    try await self.generateTick(for: asset, window: candles, at: candle)
        //                    candlesBuffer[asset.symbol]?.removeFirst()
        //                    self.ticks += 1
        //                }
        //
        ////                        for asset in assets {
        ////                            guard let candles = candlesBuffer[asset.key]?.prefix(windowSize), candles.count == windowSize,
        ////                                  let candle = candles.last, candle.date == tickDate
        ////                            else { continue }
        ////                            async let equityReq = delegate.equity
        ////                            async let buyingPowerReq = delegate.buyingPower
        ////                            let (equity, buyingPower) = await (equityReq, buyingPowerReq)
        ////                            let tick = Tick(asset: asset.value, candle: candle, candles: .init(candles), askPrice: candle.high, bidPrice: candle.low, buyingPower: buyingPower, equity: equity)
        ////                            try await delegate.received(tick: tick)
        ////                            candlesBuffer[asset.key]?.removeFirst()
        ////                            ticks += 1
        ////                        }
        //            minute += 1
        //            dateComponents.minute = minute
        //            tickDate = calendar.date(from: dateComponents)!
        //
        //            guard minute % 1000 == 0 else { continue }
        //            let percent = Double(minute) / Double(minutes)
        //            let loopDuration = calendar.dateComponents([.hour, .minute, .second, .nanosecond], from: loopStart, to: Date())
        //            let duration = DateComponentsFormatter.localizedString(from: loopDuration, unitsStyle: .brief)!
        //            Terminal.info("Backtest \(percent.percent) done, \(minute) / \(minutes) minutes. (took \(duration))")
        //            loopStart = Date()
        //        }
    }
    
    
    private func candles(in timeframe: Range<Int>, associatedWith buffer: [AssetSymbol:Deque<Candle?>]) async throws -> [AssetSymbol:Deque<Candle?>]? {
        let calendar = Calendar.GMT0
        guard let start = calendar.date(byAdding: .minute, value: timeframe.lowerBound, to: self.start),
              let end = calendar.date(byAdding: .minute, value: timeframe.upperBound, to: self.start)
        else { return nil }
        
        let minutesCount = timeframe.count
        let values = try await delegate
            .assets
            .concurrentMap { (symbol: AssetSymbol, asset: Asset) -> (AssetSymbol, Deque<Candle?>) in
                let rawCandles = try await self.broker
                    .historicData(of: .candles(of: asset, from: start, to: end, each: .minute))
                    .compactMap { $0.candles }
                    .reduce(into: Deque<Candle?>()) { $0.append(contentsOf: $1) }
                    .suffix(minutesCount)
                let bufferCandles = buffer[symbol] ?? []
                let missingCandles: Deque<Candle?> = .init(repeating: nil, count: max(minutesCount - rawCandles.count, 0))
                let candles = bufferCandles + missingCandles + rawCandles
                return (symbol, candles)
            }
        return .init(uniqueKeysWithValues: values)
    }
    
    private func generateTick(for asset: Asset, window candles: Slice<Deque<Candle>>, at candle: Candle) async throws {
        async let equityReq = delegate.equity
        async let buyingPowerReq = delegate.buyingPower
        let (equity, buyingPower) = await (equityReq, buyingPowerReq)
        let tick = Tick(
            asset: asset, candle: candle, candles: .init(candles),
            askPrice: candle.high.value, bidPrice: candle.low.value,
            buyingPower: buyingPower, equity: equity
        )
        try await self.delegate.received(tick: tick)
    }
    
}
