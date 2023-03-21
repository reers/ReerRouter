//
//  Extensions.swift
//  
//
//  Created by YuYue on 2022/7/25.
//

import Foundation
import UIKit

extension String {
    var routeKey: Route.Key {
        return Route.Key(rawValue: self)!
    }
    
    func toURL() -> URL? {
        return URL.with(urlString: self)
    }

    func removingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }
}

extension Optional {

    var isNil: Bool {
        return self == nil
    }

    var string: String? {
        if let string = self as? String {
            return string
        } else if let stringConvertible = self as? CustomStringConvertible {
            if let int = Int(stringConvertible.description) {
                return int.description
            } else if let double = Double(stringConvertible.description) {
                return double.description
            } else if let bool = self as? Bool {
                return bool ? "true" : "false"
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    var bool: Bool? {
        if let bool = self as? Bool {
            return bool
        } else if let stringConvertible = self as? CustomStringConvertible,
                  let double = Double(stringConvertible.description) {
            return double != .zero
        } else if let string = self as? String {
            let optional: String? = string
            if let int = optional.int {
                return int != 0
            } else if string.count <= 5 {
                switch string.lowercased() {
                case "true", "yes":
                    return true
                case "false", "no":
                    return false
                default:
                    return nil
                }
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    var int: Int? {
        if let stringConvertible = self as? CustomStringConvertible,
           let double = Double(stringConvertible.description) {
            return Int(double)
        } else if let bool = self as? Bool {
            return bool ? 1 : 0
        } else {
            return nil
        }
    }
}

extension URL {
    
    var queryParameters: [String: String] {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems
        else { return [:] }

        var items: [String: String] = [:]

        for queryItem in queryItems {
            items[queryItem.name] = queryItem.value
        }

        return items
    }
    
    static func with(urlString: String?, relativeTo url: URL? = nil) -> URL? {
        guard var string = urlString, !string.isEmpty else { return nil }
        string = string.trimmingCharacters(in: .whitespacesAndNewlines)
        var result: URL? = nil
        if url != nil {
            result = URL(string: string, relativeTo: url)
        } else {
            result = URL(string: string)
        }
        if result != nil { return result }

        var sourceString = string
        var fragment = ""
        if let fragmentRange = string.range(of: "#") {
            sourceString = String(string[..<fragmentRange.lowerBound])
            fragment = String(string[fragmentRange.lowerBound...])
        }
        let substrings = sourceString.components(separatedBy: "?")
        if substrings.count > 1 {
            let beforeQuery = substrings[0]
            let queryString = substrings[1]
            let params = queryString.components(separatedBy: "&")
            var encodedParams: [String: String] = [:]
            for param in params {
                let keyValue = param.components(separatedBy: "=")
                if keyValue.count > 1 {
                    let key = keyValue[0]
                    var value = keyValue[1]
                    value = decode(with: value)
                    let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .reerRouterAllowed)
                    encodedParams[key] = encodedValue
                }
            }
            let encodedURLString = "\(beforeQuery)?\(encodedParams.queryString)\(fragment))"
            if let url = url {
                result = URL(string: encodedURLString, relativeTo: url)
            } else {
                result = URL(string: encodedURLString)
            }
        }
        return result
    }

    private static func decode(with urlString: String) -> String {
        guard let _ = urlString.range(of: "%") else {
            return urlString
        }
        return urlString.removingPercentEncoding ?? urlString
    }
}

extension CharacterSet {
    static var reerRouterAllowed: CharacterSet {
        return CharacterSet(charactersIn: ":/?#@!$&'(){}*+=")
    }
}

extension Dictionary where Key == String, Value == String {
    var queryString: String {
        return self.map { "\($0)=\($1)" }.joined(separator: "&")
    }
}

extension Dictionary {
    static func + (lhs: [Key: Value], rhs: [Key: Value]) -> [Key: Value] {
        var result = lhs
        rhs.forEach { result[$0] = $1 }
        return result
    }
}

extension UIApplication {
    
    var appKeyWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .first(where: { $0 is UIWindowScene })
                .flatMap({ $0 as? UIWindowScene })?.windows
                .first(where: \.isKeyWindow)
        } else {
            return UIApplication.shared.keyWindow
        }
    }
    
    var topMostViewController: UIViewController? {
        guard let rootViewController = appKeyWindow?.rootViewController else { return nil }
        return topMost(of: rootViewController)
    }
    
    var topMostNavigationController: UINavigationController? {
        return topMostViewController?.navigationController
    }
    
    func topMost(of viewController: UIViewController?) -> UIViewController? {
        // presented view controller
        if let presentedViewController = viewController?.presentedViewController {
            return self.topMost(of: presentedViewController)
        }
        
        // UITabBarController
        if let tabBarController = viewController as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return self.topMost(of: selectedViewController)
        }
        
        // UINavigationController
        if let navigationController = viewController as? UINavigationController,
           let visibleViewController = navigationController.visibleViewController {
            return self.topMost(of: visibleViewController)
        }
        
        // UIPageController
        if let pageViewController = viewController as? UIPageViewController,
           pageViewController.viewControllers?.count == 1 {
            return self.topMost(of: pageViewController.viewControllers?.first)
        }
        
        // child view controller
        for subview in viewController?.view?.subviews ?? [] {
            if let childViewController = subview.next as? UIViewController {
                return self.topMost(of: childViewController)
            }
        }
        
        return viewController
    }
}

/// Make `Bool?` to a oppsite value if it is not nil.
prefix operator !
prefix func ! (value: Bool?) -> Bool? {
    guard let value = value else { return nil }
    if value {
        return false
    } else {
        return true
    }
}
