//
//  Key.swift
//  
//
//  Created by YuYue on 2022/7/24.
//

import Foundation

extension Route {
    /// Route key represent the unique identifier of the route(action or routable UIViewController).
    /// It is actually the combination of url `host` and `path`.
    public struct Key: ExpressibleByStringLiteral, Equatable, Hashable, RawRepresentable {
        public typealias StringLiteralType = String
        
        public private(set) var rawValue: String
        
        public init(stringLiteral value: String) {
            self.rawValue = value
        }
        
        public init?(rawValue: String) {
            self.rawValue = rawValue
        }
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue == rhs.rawValue
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(rawValue)
        }
    }
}

extension Route.Key {
    /// Use the router default scheme to generate a route url.
    func toURL() -> URL? {
        return "\(Route.defaultScheme)://\(self.rawValue)".toURL()
    }
}
