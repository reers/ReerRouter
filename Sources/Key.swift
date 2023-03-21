//
//  Key.swift
//  
//
//  Created by YuYue on 2022/7/24.
//

import Foundation

extension Route {
    /// Represent a unique id for `Route.Key`, it is the combination of url host and path.
    typealias ID = String

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
    /// Transform route key to route id.
    func id(with host: String) -> Route.ID {
        return rawValue.hasPrefix(host) ? rawValue : "\(host)\(rawValue)"
    }

    /// Use the router default scheme to generate a route url.
    func url(with host: String) -> URL? {
        let id = id(with: host)
        return "\(Route.defaultScheme)://\(id)".toURL()
    }
}
