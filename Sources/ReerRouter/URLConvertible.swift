//
//  URLConvertible.swift
//  ReerRouter
//
//  Created by YuYue on 2022/7/26.
//

#if canImport(UIKit)
import Foundation

/// A type which can be converted to an URL string.
public protocol URLConvertible {
    var urlValue: URL? { get }
}

extension String: URLConvertible {
    public var urlValue: URL? {
        return self.toURL()
    }
}

extension URL: URLConvertible {
    public var urlValue: URL? {
        return self
    }
}
#endif
