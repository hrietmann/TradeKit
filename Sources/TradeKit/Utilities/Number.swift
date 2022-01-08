//
//  File.swift
//  
//
//  Created by Hans Rietmann on 07/01/2022.
//

import Foundation





public struct Number: Codable {
    
    
    public var value: Double
    
    public init(_ val: Double) { value = val }
    public init(from decoder: Decoder) throws {
        if let val = try? decoder.singleValueContainer().decode(Double.self) {
            value = val
            return
        }
        if let string = try? decoder.singleValueContainer().decode(String.self) {
            if let double = Double(string) {
                value = double
                return
            } else if let int = Int(string) {
                value = .init(int)
                return
            }
        }
        if let int = try? decoder.singleValueContainer().decode(Int.self) {
            value = .init(int)
            return
        }
        throw NumberNotFound()
    }
    
    
}
