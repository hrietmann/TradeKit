//
//  DataSource.swift
//  TradeKit
//
//  Created by Hans Rietmann on 30/11/2021.
//

import Foundation


#if compiler(>=5.5) && canImport(_Concurrency)
public protocol Broker {
    
    static func backtest(cash: Double) throws -> Self
    static var paper: Self { get throws }
    static var production: Self { get throws }
    
    var fees: Fees { get }
    
    var environment: Environment { get }
    init(_ environment: Environment) throws
    
    var remoteAccount: Account { get async throws }
    func sampleAccount(cash: Double) -> Account
    
    func remoteAsset(from symbol: String) async throws -> Asset?
    
    var remotePositions: [Position] { get async throws }
    func remotePosition(on asset: Asset) async throws -> Position?
    func remotelyClose(_ unit: PositionUnit, of position: Position) async throws -> Order
    func remotelyCloseAllPositions() async throws -> [Order]
    
    func remoteOrders(_ status: Set<OrderStatus>, sorted by: SortDirection) async throws -> [Order]
    func remotelyOrder(_ request: OrderRequestParams) async throws -> Order
    func sampleOrder(from request: OrderRequestParams, at date: Date) -> Order
    func remoteOrder(_ id: UUID) async throws -> Order?
    func remotelyCancel(_ order: Order) async throws
    func remotelyCancelAllOrders() async throws
    
    func remoteLatestTrade(of asset: Asset) async throws -> Trade
    
    func remoteLatestQuote(of asset: Asset) async throws -> Quote
    
    var maxHistoricDataPageItems: Int { get }
    func historicData(of params: HistoricDataParams) -> AsyncThrowingStream<HistoricDataPage, Error>
    
    func realtimeStream(for assets: [Asset]) -> AsyncThrowingStream<RealtimeData, Error>
    
}
#endif
