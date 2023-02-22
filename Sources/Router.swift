//
//  Router.swift
//
//
//  Created by YuYue on 2022/7/24.
//

import Foundation
import UIKit

/// ReerRouter: Provides an elegant way to navigate through view controllers or actions by URLs.
/// Use the combination of url host and path as the route key.
///
/// Format:
///
/// myapp://example.com/over/there?name=phoenix#nose
/// \______/\_________/\_________/ \__________/ \__/
///    |         |          |           |        |
///  scheme     host       path      queries   fragment
///              \_________/
///                   |
///               route key
///
open class Router {
    /// Global singleton instance.
    public static let shared = Router()
    
    public var delegate: RouterDelegate?
    
    // User can setup these properties as the default.
    open var preferredOpenStyle: Route.OpenStyle = .push
    open var preferredPresentationStyle: UIModalPresentationStyle = .fullScreen
    open var allowedSchemes: [String] = []
    
    private var actionMap: [Route.Key: Route.Action] = [:]
    private var routableMap: [Route.Key: Routable.Type] = [:]
}


// MARK: - Enable

extension Router {
    public func canOpenKey(_ key: Route.Key) -> Bool {
        guard let url = key.toURL() else { return false }
        return canOpenURL(url)
    }
    
    public func canOpenURL(_ url: URLConvertible) -> Bool {
        guard let url = url.urlValue else { return false }
        let param = Route.Param(url: url)
        guard isAllowedForScheme(param.scheme) else { return false }
        return actionMap[param.key.routeKey] != nil || routableMap[param.key.routeKey] != nil
    }
    
    private func isAllowedForScheme(_ scheme: String?) -> Bool {
        guard let scheme = scheme else { return false }
        if allowedSchemes.isEmpty { return true }
        else {
            return (allowedSchemes + [Route.defaultScheme]).contains(scheme)
        }
    }
}


// MARK: - Action methods

extension Router {
    
    /// Register an action by a route key.
    ///
    ///     AppRouter.registerAction(with: "some_action") { _ in
    ///         print("action executed.")
    ///     }
    public func registerAction(with key: Route.Key, _ action: @escaping Route.Action) {
        assert(actionMap[key] == nil, "\(key) action has been registered.")
        assert(routableMap[key] == nil, "\(key) action conflict with a page.")
        actionMap[key] = action
    }
    
    public func unregisterAction(with key: Route.Key) {
        actionMap.removeValue(forKey: key)
    }
    
    /// Execute an action by a route key.
    ///
    ///     AppRouter.executeAction(byKey: "some_action")
    ///     // Also you can execute action by url
    ///     AppRouter.open("myapp://some_action")
    @discardableResult
    public func executeAction(byKey key: Route.Key, userInfo: [String: Any] = [:]) -> Bool {
        guard let action = actionMap[key] else {
            return false
        }
        guard let url = key.toURL() else {
            assert(false, "Generate url failed for \(key)")
            return false
        }
        let param = Route.Param(url: url, userInfo: userInfo)
        action(param)
        return true
    }
}


// MARK: - Register pages.

extension Router {
    
    /// Register a view controller by its type and a route key.
    public func register(_ pageClass: Routable.Type, forKey key: Route.Key) {
        assert(routableMap[key] == nil, "\(key) has been registered.")
        assert(actionMap[key] == nil, "\(key) page conflict with an action.")
        routableMap[key] = pageClass
    }
    
    /// Register view controllers by their types and route keys.
    public func registerPageClasses(with dict: [Route.Key: Routable.Type]) {
        dict.forEach {
            assert(routableMap[$0] == nil, "\($0) has been registered.")
            assert(actionMap[$0] == nil, "\($0) page conflict with an action.")
            routableMap[$0] = $1
        }
    }
    
    /// Register view controllers by their type names and route keys.
    /// Don't forget to add it's module name.
    ///
    ///     Router.shared.registerPageClasses(with: ["preference": "ReerRouter.PreferenceViewController"])
    public func registerPageClasses(with dict: [Route.Key: UIViewControllerClassName]) {
        dict.forEach {
            assert(routableMap[$0] == nil, "\($0) has been registered.")
            assert(actionMap[$0] == nil, "\($0) page conflict with an action.")
            guard let pageClass = NSClassFromString($1) else {
                assert(false, "\($1) class not found. Do NOT forget to add module name as a prefix when using Swift, such as `MuduleA.UserViewController")
                return
            }
            guard let routableClass = pageClass as? Routable.Type else {
                assert(false, "\($1) class does not conform to Routable.")
                return
            }
            routableMap[$0] = routableClass
        }
    }
    
    public func unregister(forKey key: Route.Key) {
        routableMap.removeValue(forKey: key)
    }
}


// MARK: - Getter

extension Router {
    
    public func viewController(for url: URLConvertible, userInfo: [String: Any] = [:]) -> UIViewController? {
        guard let url = url.urlValue else { return nil }
        if !canOpenURL(url) { return nil }
        let param = Route.Param(url: url, userInfo: userInfo)
        guard let routable = routableMap[param.key.routeKey],
              let routableViewController = routable.init(param: param)
        else { return nil }
        return routableViewController as UIViewController
    }
    
    public func action(for url: URLConvertible) -> Route.Action? {
        guard let url = url.urlValue else { return nil }
        if !canOpenURL(url) { return nil }
        let param = Route.Param(url: url)
        return actionMap[param.key.routeKey]
    }
}


// MARK: - Open url.

extension Router {
    
    /// Open a page or execute an action by route key.
    ///
    ///     extension Route.Key {
    ///         static let userPage: Self = "user"
    ///     }
    ///     Router.shared.open(.userPage, userInfo: [
    ///         "name": "apple",
    ///         "id": "123123"
    ///     ])
    ///
    ///     // Route.Key can be expressed by string, so you can use a string as the key.
    ///     Router.shared.open(byKey: "user")
    @discardableResult
    public func open(byKey key: Route.Key, userInfo: [String: Any] = [:]) -> Bool {
        guard let url = key.toURL() else {
            assert(false, "Generate url failed for \(key)")
            return false
        }
        return open(url, userInfo: userInfo)
    }
    
    /// Open a page or execute an action by a url.
    /// URLString will be transformed to URL instance even though there are some special characters, such as Chinese.
    ///
    ///     Router.shared.open("myapp://user?name=apple")
    ///     Router.shared.open(URL(string: "myapp://user?name=apple")!)
    @discardableResult
    public func open(_ url: URLConvertible, userInfo: [String: Any] = [:]) -> Bool {
        guard let url = url.urlValue else { return false }
        if !isAllowedForScheme(url.scheme) {
            defer { tellDelegateResult(false, forURL: url, userInfo: userInfo) }
            return false
        }
        guard let url = delegate?.router(self, willOpenURL: url, userInfo: userInfo) else {
            defer { tellDelegateResult(false, forURL: url, userInfo: userInfo) }
            return false
        }
        let param = Route.Param(url: url, userInfo: userInfo)
        if let action = actionMap[param.key.routeKey] {
            sendWillOpenNotification(with: param)
            action(param)
            defer {
                tellDelegateResult(true, forURL: url, userInfo: userInfo)
                sendDidOpenNotificationIfNeeded(true, with: param)
            }
            return true
        } else if let routable = routableMap[param.key.routeKey] {
            if let redirectURL = routable.redirectURLWithRouteParam(param) {
                return open(redirectURL, userInfo: userInfo)
            }
            guard let routableViewController = routable.init(param: param) else {
                assert(false, "Init \(routable) failed.")
                defer { tellDelegateResult(false, forURL: url, userInfo: userInfo) }
                return false
            }
            let viewController = routableViewController as UIViewController
            sendWillOpenNotification(with: param)
            let result = open(viewController: viewController)
            tellDelegateResult(result, forURL: url, userInfo: userInfo)
            sendDidOpenNotificationIfNeeded(result, with: param)
            return result
        } else {
            if let fallbackURL = param.fallbackURL {
                let result = open(fallbackURL, userInfo: userInfo)
                if result { delegate?.router(self, didFallbackToURL: fallbackURL, userInfo: userInfo) }
                return result
            }
            assert(false, "\(param.key) can NOT be handled.")
            defer { tellDelegateResult(false, forURL: url, userInfo: userInfo) }
            return false
        }
    }
    
    /// Push a view controller by a route key.
    ///
    ///     AppRouter.push(byKey: "user")
    @discardableResult
    public func push(
        byKey key: Route.Key,
        userInfo: [String: Any] = [:],
        animated: Bool = true,
        transitionExecutor: Route.TransitionExecutor = .router
    ) -> Bool {
        guard let url = key.toURL() else { return false }
        return push(url, userInfo: userInfo, animated: animated, transitionExecutor: transitionExecutor)
    }
    
    /// Push a view controller by a url.
    ///
    ///     AppRouter.push("myapp://user?name=apple")
    @discardableResult
    public func push(
        _ url: URLConvertible,
        userInfo: [String: Any] = [:],
        animated: Bool = true,
        transitionExecutor: Route.TransitionExecutor = .router
    ) -> Bool {
        guard let url = url.urlValue else { return false }
        if !isAllowedForScheme(url.scheme) {
            defer { tellDelegateResult(false, forURL: url, userInfo: userInfo) }
            return false
        }
        guard let url = delegate?.router(self, willOpenURL: url, userInfo: userInfo) else {
            defer { tellDelegateResult(false, forURL: url, userInfo: userInfo) }
            return false
        }
        let param = Route.Param(url: url, userInfo: userInfo)
        if let routable = routableMap[param.key.routeKey] {
            if let redirectURL = routable.redirectURLWithRouteParam(param) {
                return push(redirectURL, userInfo: userInfo, animated: animated, transitionExecutor: transitionExecutor)
            }
            guard let routableViewController = routable.init(param: param) else {
                assert(false, "Init \(routable) failed.")
                defer { tellDelegateResult(false, forURL: url, userInfo: userInfo) }
                return false
            }
            let viewController = routableViewController as UIViewController
            sendWillOpenNotification(with: param)
            let result = _push(
                viewController: viewController,
                animated: animated,
                param: param,
                transitionExecutor: transitionExecutor
            )
            tellDelegateResult(result, forURL: url, userInfo: userInfo)
            sendDidOpenNotificationIfNeeded(result, with: param)
            return result
        } else {
            if let fallbackURL = param.fallbackURL {
                let result = push(fallbackURL, userInfo: userInfo, animated: animated, transitionExecutor: transitionExecutor)
                if result { delegate?.router(self, didFallbackToURL: fallbackURL, userInfo: userInfo) }
                return result
            }
            assert(false, "\(param.key) can NOT be handled.")
            defer { tellDelegateResult(false, forURL: url, userInfo: userInfo) }
            return false
        }
    }
    
    /// Present a view controller by a route key.
    ///
    ///     AppRouter.present(byKey: "user")
    @discardableResult
    public func present(
        byKey key: Route.Key,
        embedIn navigationControllerClass: UINavigationController.Type? = nil,
        userInfo: [String: Any] = [:],
        animated: Bool = true,
        presentationStyle: UIModalPresentationStyle? = nil,
        transitionExecutor: Route.TransitionExecutor = .router
    ) -> Bool {
        guard let url = key.toURL() else { return false }
        return present(
            url,
            embedIn: navigationControllerClass,
            userInfo: userInfo,
            animated: animated,
            presentationStyle: presentationStyle,
            transitionExecutor: transitionExecutor
        )
    }
    
    /// present a view controller by a url.
    ///
    ///     AppRouter.present("myapp://user?name=apple")
    @discardableResult
    public func present(
        _ url: URLConvertible,
        embedIn navigationControllerClass: UINavigationController.Type? = nil,
        userInfo: [String: Any] = [:],
        animated: Bool = true,
        presentationStyle: UIModalPresentationStyle? = nil,
        transitionExecutor: Route.TransitionExecutor = .router
    ) -> Bool {
        guard let url = url.urlValue else { return false }
        if !isAllowedForScheme(url.scheme) {
            defer { tellDelegateResult(false, forURL: url, userInfo: userInfo) }
            return false
        }
        guard let url = delegate?.router(self, willOpenURL: url, userInfo: userInfo) else {
            defer { tellDelegateResult(false, forURL: url, userInfo: userInfo) }
            return false
        }
        let param = Route.Param(url: url, userInfo: userInfo)
        if let routable = routableMap[param.key.routeKey] {
            if let redirectURL = routable.redirectURLWithRouteParam(param) {
                return present(
                    redirectURL,
                    embedIn: navigationControllerClass,
                    userInfo: userInfo,
                    animated: animated,
                    transitionExecutor: transitionExecutor
                )
            }
            guard let routableViewController = routable.init(param: param) else {
                assert(false, "Init \(routable) failed.")
                defer { tellDelegateResult(false, forURL: url, userInfo: userInfo) }
                return false
            }
            var toController = routableViewController as UIViewController
            if let navigationControllerClass = navigationControllerClass,
               !(toController is UINavigationController) {
                toController = navigationControllerClass.init(rootViewController: toController)
            }
            sendWillOpenNotification(with: param)
            let result = _present(
                viewController: toController,
                animated: animated,
                param: param,
                presentationStyle: presentationStyle ?? preferredPresentationStyle,
                transitionExecutor: transitionExecutor
            )
            tellDelegateResult(result, forURL: url, userInfo: userInfo)
            sendDidOpenNotificationIfNeeded(result, with: param)
            return result
        } else {
            if let fallbackURL = param.fallbackURL {
                let result = present(
                    fallbackURL,
                    embedIn: navigationControllerClass,
                    userInfo: userInfo,
                    animated: animated,
                    transitionExecutor: transitionExecutor
                )
                if result { delegate?.router(self, didFallbackToURL: fallbackURL, userInfo: userInfo) }
                return result
            }
            assert(false, "\(param.key) can NOT be handled.")
            defer { tellDelegateResult(false, forURL: url, userInfo: userInfo) }
            return false
        }
    }
    
    /// Open a view controller with the default open style.
    @discardableResult
    public func open(viewController: UIViewController, animated: Bool = true) -> Bool {
        var result = false
        switch preferredOpenStyle {
        case .push:
            result = push(viewController: viewController)
            if !result {
                result = present(viewController: viewController)
            }
        case .present(let modalPresentationStyle):
            result = present(viewController: viewController, presentationStyle: modalPresentationStyle)
            if !result {
                result = push(viewController: viewController)
            }
        }
        return result
    }
    
    /// Push a view controller with the default open style.
    @discardableResult
    public func push(
        viewController: UIViewController,
        animated: Bool = true
    ) -> Bool {
        return _push(viewController: viewController, animated: animated)
    }
    
    /// Present a view controller with the default open style.
    @discardableResult
    public func present(
        viewController: UIViewController,
        animated: Bool = true,
        presentationStyle: UIModalPresentationStyle = .fullScreen
    ) -> Bool {
        return _present(viewController: viewController, animated: animated, presentationStyle: presentationStyle)
    }
}


// MARK: - Private

extension Router {
    
    @discardableResult
    private func _push(
        viewController: UIViewController,
        animated: Bool = true,
        param: Route.Param = .default,
        transitionExecutor: Route.TransitionExecutor = .router
    ) -> Bool {
        guard !(viewController is UINavigationController) else { return false }
        guard let topNavigationController = UIApplication.shared.topMostNavigationController else { return false }
        switch transitionExecutor {
        case .router:
            topNavigationController.pushViewController(viewController, animated: animated)
            return true
        case .user(let execute):
            return execute(topNavigationController, nil, viewController)
        case .delegate:
            guard let delegate = delegate else { return false }
            return delegate.routeTransition(
                with: self,
                param: param,
                fromNavigationController: topNavigationController,
                fromViewController: nil,
                toViewController: viewController
            )
        }
    }
    
    @discardableResult
    private func _present(
        viewController: UIViewController,
        animated: Bool = true,
        param: Route.Param = .default,
        presentationStyle: UIModalPresentationStyle = .fullScreen,
        transitionExecutor: Route.TransitionExecutor = .router
    ) -> Bool {
        guard let topViewController = UIApplication.shared.topMostViewController else { return false }
        switch transitionExecutor {
        case .router:
            viewController.modalPresentationStyle = presentationStyle
            topViewController.present(viewController, animated: animated)
            return true
        case .user(let execute):
            return execute(nil, topViewController, viewController)
        case .delegate:
            guard let delegate = delegate else { return false }
            return delegate.routeTransition(
                with: self,
                param: param,
                fromNavigationController: nil,
                fromViewController: topViewController,
                toViewController: viewController
            )
        }
    }
    
    private func tellDelegateResult(_ isSuccess: Bool, forURL url: URL, userInfo: [String: Any]) {
        if isSuccess {
            delegate?.router(self, didOpenURL: url, userInfo: userInfo)
        } else {
            delegate?.router(self, didFailToOpenURL: url, userInfo: userInfo)
        }
    }
    
    private func sendWillOpenNotification(with param: Route.Param) {
        NotificationCenter.default.post(
            name: Notification.Name.routeWillOpenURL,
            object: self,
            userInfo: [Route.notificationUserInfoKey: param]
        )
    }
    
    private func sendDidOpenNotificationIfNeeded(_ openResult: Bool, with param: Route.Param) {
        if openResult {
            NotificationCenter.default.post(
                name: Notification.Name.routeDidOpenURL,
                object: self,
                userInfo: [Route.notificationUserInfoKey: param]
            )
        }
    }
}
