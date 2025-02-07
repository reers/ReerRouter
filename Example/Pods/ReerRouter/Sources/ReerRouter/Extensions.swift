//
//  Extensions.swift
//  
//
//  Created by YuYue on 2022/7/25.
//

#if canImport(UIKit)
import UIKit

extension String {
    var routeKey: Route.Key {
        return Route.Key(rawValue: self)
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
        guard var string = urlString?.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
        
        if let directURL = URL(string: string, relativeTo: url) {
            return directURL
        }
        
        var scheme = "", host = "", path = "", query = "", fragment = ""
        
        if let schemeRange = string.range(of: "://") {
            scheme = String(string[..<schemeRange.lowerBound])
            string = String(string[schemeRange.upperBound...])
        }
        
        if let fragmentRange = string.range(of: "#") {
            fragment = String(string[fragmentRange.upperBound...])
            string = String(string[..<fragmentRange.lowerBound])
        }
        
        if let queryRange = string.range(of: "?") {
            query = String(string[queryRange.upperBound...])
            string = String(string[..<queryRange.lowerBound])
        }
        
        let components = string.split(separator: "/", maxSplits: 1)
        host = String(components.first ?? "")
        path = components.count > 1 ? "/" + components[1] : ""
        
        let encodedHost = host
        let encodedPath = encodePath(path)
        let encodedQuery = encodeQuery(query)
        let encodedFragment = encodeFragment(fragment)
        
        var urlString = ""
        if !scheme.isEmpty { urlString += "\(scheme)://" }
        urlString += encodedHost
        urlString += encodedPath
        if !encodedQuery.isEmpty { urlString += "?\(encodedQuery)" }
        if !encodedFragment.isEmpty { urlString += "#\(encodedFragment)" }
        
        return URL(string: urlString, relativeTo: url)
    }
    
    private static func encodePath(_ path: String) -> String {
        let allowedCharacters = CharacterSet.urlPathAllowed.subtracting(.init(charactersIn: "/"))
        return path
            .components(separatedBy: "/")
            .map { $0.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? $0 }
            .joined(separator: "/")
    }
    
    private static func encodeQuery(_ query: String) -> String {
        guard !query.isEmpty else { return "" }
        
        return query
            .components(separatedBy: "&")
            .compactMap { component -> String? in
                let parts = component.components(separatedBy: "=")
                guard let key = parts.first, !key.isEmpty else { return nil }
                
                let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
                
                if parts.count > 1 {
                    let value = parts[1]
                    let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                    return "\(encodedKey)=\(encodedValue)"
                } else {
                    return encodedKey
                }
            }
            .joined(separator: "&")
    }
    
    private static func encodeFragment(_ fragment: String) -> String {
        return fragment.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? fragment
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
                .sorted { $0.activationState.sortPriority < $1.activationState.sortPriority }
                .compactMap { $0 as? UIWindowScene }
                .compactMap { $0.windows.first { $0.isKeyWindow } }
                .first
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

public extension UINavigationController {

    /// Push ViewController with completion handler.
    ///
    /// - Parameters:
    ///   - viewController: viewController to push.
    ///   - completion: optional completion handler (default is nil).
    func pushViewController(_ viewController: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        pushViewController(viewController, animated: animated)
        guard animated, let coordinator = transitionCoordinator else {
            DispatchQueue.main.async { completion?() }
            return
        }
        coordinator.animate(alongsideTransition: nil) { _ in completion?() }
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

@available(iOS 13.0, *)
private extension UIScene.ActivationState {
    var sortPriority: Int {
        switch self {
        case .foregroundActive: return 1
        case .foregroundInactive: return 2
        case .background: return 3
        case .unattached: return 4
        @unknown default: return 5
        }
    }
}
#endif
