//
//  RouteDefine.swift
//  
//
//  Created by YuYue on 2022/7/24.
//

import UIKit

// MARK: - Definitions

/// Namespcace
public enum Route {}

extension Route {
    
    public enum OpenStyle {
        case push
        case present(UIModalPresentationStyle)
    }
    
    public typealias UserTransition = (
        _ fromNavigationController: UINavigationController?,
        _ fromViewController: UIViewController?,
        _ toViewController: UIViewController
    ) -> Bool
    
    public enum TransitionExecutor {
        /// Transition will be handled by router automatically.
        case router
        /// Transition will be handled by user who invoke the router `push` or `present` method.
        case user(UserTransition)
        /// Transition will be handled by delgate.
        case delegate
    }
    
    /// Internal default scheme.
    public static let defaultScheme = "reer"
    
    public static let fallbackURLKey = "route_fallback_url"
    
    public typealias Action = (_ params: Route.Param) -> Void
}

public typealias UIViewControllerClassName = String

/// Global instance of the Router.
public let AppRouter = Router.shared


// MARK: - Routable

/// Reresent a UIViewController that can be routed by ReerRouter.
public protocol Routable: UIViewController {
    
    /// Initializer for the view controller, param will take the source url, query params and user info params.
    init?(param: Route.Param)
    
    /// Implement this method if the view controller needs to redirect to another view controller under some conditions.
    static func redirectURLWithRouteParam(_ param: Route.Param) -> URL?
}

/// Make the protocol optional.
public extension Routable {
    static func redirectURLWithRouteParam(_ param: Route.Param) -> URL? { return nil }
}


// MARK: - Router Delegate

public protocol RouterDelegate {
    /// Callback when url will be opened.
    func router(_ router: Router, willOpenURL url: URL, userInfo: [String: Any]) -> URL?
    /// Callback when url has been opened.
    func router(_ router: Router, didOpenURL url: URL, userInfo: [String: Any])
    /// Callback when failed to open url.
    func router(_ router: Router, didFailToOpenURL url: URL, userInfo: [String: Any])
    /// Callback when fallback url has been opened.
    func router(_ router: Router, didFallbackToURL url: URL, userInfo: [String: Any])
    /// Callback when router ask the delegate to handle transition.
    func routeTransition(
        with router: Router,
        param: Route.Param,
        fromNavigationController: UINavigationController?,
        fromViewController: UIViewController?,
        toViewController: UIViewController
    ) -> Bool
}

/// Make the protocol optional.
public extension RouterDelegate {
    func router(_ router: Router, willOpenURL url: URL, userInfo: [String: Any]) -> URL? { return url }
    func router(_ router: Router, didOpenURL url: URL, userInfo: [String: Any]) {}
    func router(_ router: Router, didFailToOpenURL url: URL, userInfo: [String: Any]) {}
    func router(_ router: Router, didFallbackToURL url: URL, userInfo: [String: Any]) {}
    func routeTransition(
        with router: Router,
        param: Route.Param,
        fromNavigationController: UINavigationController?,
        fromViewController: UIViewController?,
        toViewController: UIViewController
    ) -> Bool { return false }
}


// MARK: - Router Notification

public extension Notification.Name {
    static let routeWillOpenURL = Notification.Name("ReerRouterWillOpenURLNotification")
    static let routeDidOpenURL = Notification.Name("ReerRouterDidOpenURLNotification")
}

extension Route {
    /// Get user info from notification instance.
    ///
    ///     if let param = notification.userInfo?[Route.notificationUserInfoKey] as? Route.Param {}
    public static let notificationUserInfoKey = "ReerRouterNotificationUserInfoKey"
}
