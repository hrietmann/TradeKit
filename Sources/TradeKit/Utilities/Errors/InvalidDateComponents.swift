//
//  InvalidDateComponents.swift
//  TradeKit
//
//  Created by Hans Rietmann on 15/12/2021.
//

import Foundation





struct InvalidDateComponents: LocalizedError {
    let propertyName: String
    let components: DateComponents
    var errorDescription: String? {
        "The given date component for '\(propertyName)' does not produce a valid date. \nDateComponent: \(components)"
    }
}



struct NumberNotFound: LocalizedError {
    var errorDescription: String? {
        "Number value not found when decoding object."
    }
}
