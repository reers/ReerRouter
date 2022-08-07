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
}

extension Optional {
    var string: String? {
        if let string = self as? String {
            return string
        } else if let bool = self as? Bool {
            return bool ? "true" : "false"
        } else if let stringConvertible = self as? CustomStringConvertible {
            if let int = Int(stringConvertible.description) {
                return int.description
            } else if let double = Double(stringConvertible.description) {
                return double.description
            } else {
                return nil
            }
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

        if result == nil {
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

            if result == nil {
                if let encodedString = string.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
                    result = URL(string: encodedString)
                }
            }
            assert(result != nil, "Fail to create a URL.")
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
