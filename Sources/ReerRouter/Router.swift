//
//  Router.swift
//
//
//  Created by YuYue on 2022/7/24.
//

#if canImport(UIKit)
import UIKit
import MachO
import SectionReader

/// ReerRouter: Provides an elegant way to navigate through view controllers or actions by URLs.
/// There are two ways to use the route key:
///
/// Mode 1. Use the combination of url host and path as the route key.
///
/// myapp://example.com/over/there?name=phoenix#nose
/// \______/\_________/\_________/ \__________/ \__/
///    |         |          |           |        |
///  scheme     host       path      queries   fragment
///              \_________/
///                   |
///               route key
///
/// -------------------------------------------------------------
///
/// Mode 2. Set `host` for router instance and use path as the route key.
///
/// myapp://example.com/over/there?name=phoenix#nose
/// \______/\_________/\_________/ \__________/ \__/
///    |         |          |           |        |
///  scheme     host       path      queries   fragment
///                        |
///                        |
///                    route key
///
open class Router {
    /// Global singleton instance.
    public static let shared = Router()
    
    private init() {}
    
    public var delegate: RouterDelegate?
    
    // User can setup these properties as the default.
    open var preferredOpenStyle: Route.OpenStyle = .push
    open var preferredPresentationStyle: UIModalPresentationStyle = .fullScreen
    // Empty means any scheme is allowed.
    open var allowedSchemes: [String] = []
    
    open var host: String = ""
    
    private lazy var actionMap: [Route.ID: Route.Action] = {
        if lazyRegistration {
            Self.readActions()
        }
        return [:]
    }()
    
    private lazy var routableMap: [Route.ID: any Routable.Type] = {
        if lazyRegistration {
            Self.readViewControllers()
        }
        return [:]
    }()
    
    private var interceptors: [Route.ID: [Route.Interception]] = [:]
    
    private var lazyRegistration = false
}

// MARK: - Enable

extension Router {
    public func canOpenKey(_ key: Route.Key) -> Bool {
        guard let url = key.url(with: host) else { return false }
        return canOpenURL(url)
    }
    
    public func canOpenURL(_ url: URLConvertible) -> Bool {
        guard let url = url.urlValue else { return false }
        let param = Route.Param(url: url)
        guard isAllowedForScheme(param.scheme) else { return false }
        return actionMap[param.routeID] != nil || routableMap[param.routeID] != nil
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
        let id = key.id(with: host)
        assert(actionMap[id] == nil, "\(id) action has been registered.")
        assert(routableMap[id] == nil, "\(id) action conflict with a page.")
        actionMap[id] = action
    }
    
    public func unregisterAction(with key: Route.Key) {
        actionMap.removeValue(forKey: key.id(with: host))
    }
    
    /// Execute an action by a route key.
    ///
    ///     AppRouter.executeAction(byKey: "some_action")
    ///     // Also you can execute action by url
    ///     AppRouter.open("myapp://some_action")
    @discardableResult
    public func executeAction(byKey key: Route.Key, userInfo: [String: Any] = [:], completion: Route.Completion? = nil) -> Bool {
        let id = key.id(with: host)
        guard let action = actionMap[id] else {
            completion?(false)
            return false
        }
        guard let url = key.url(with: host) else {
            assert(false, "Generate url failed for \(id)")
            completion?(false)
            return false
        }
        let param = Route.Param(url: url, userInfo: userInfo)
        action(param)
        completion?(true)
        return true
    }
}


// MARK: - Register pages.

extension Router {
    
    /// Register a view controller by its type and a route key.
    public func register(_ pageClass: any Routable.Type, forKey key: Route.Key) {
        let id = key.id(with: host)
        assert(routableMap[id] == nil, "\(id) has been registered.")
        assert(actionMap[id] == nil, "\(id) page conflict with an action.")
        routableMap[id] = pageClass
    }
    
    /// Register view controllers by their types and route keys.
    public func registerPageClasses(with dict: [Route.Key: any Routable.Type]) {
        dict.forEach {
            let id = $0.id(with: host)
            assert(routableMap[id] == nil, "\(id) has been registered.")
            assert(actionMap[id] == nil, "\(id) page conflict with an action.")
            routableMap[id] = $1
        }
    }
    
    /// Register view controllers by their type names and route keys.
    /// Don't forget to add it's module name.
    ///
    ///     Router.shared.registerPageClasses(with: ["preference": "ReerRouter.PreferenceViewController"])
    public func registerPageClasses(with dict: [Route.Key: UIViewControllerClassName]) {
        dict.forEach {
            let id = $0.id(with: host)
            assert(routableMap[id] == nil, "\(id) has been registered.")
            assert(actionMap[id] == nil, "\(id) page conflict with an action.")
            guard let pageClass = NSClassFromString($1) else {
                assert(false, "\($1) class not found. Do NOT forget to add module name as a prefix when using Swift, such as `MuduleA.UserViewController")
                return
            }
            guard let routableClass = pageClass as? any Routable.Type else {
                assert(false, "\($1) class does not conform to Routable.")
                return
            }
            routableMap[id] = routableClass
        }
    }
    
    public func unregister(forKey key: Route.Key) {
        routableMap.removeValue(forKey: key.id(with: host))
    }
}


// MARK: - Interception

extension Router {
    
    /// Add a interception block for a certain route.
    /// Return false for the block means you want to stop routing for the url.
    public func addInterceptor(forKey key: Route.Key, interception: @escaping Route.Interception) {
        let id = key.id(with: host)
        var interceptions = interceptors[id] ?? []
        interceptions.append(interception)
        interceptors[id] = interceptions
    }
    
    public func removeInterceptor(forKey key: Route.Key) {
        interceptors.removeValue(forKey: key.id(with: host))
    }
}


// MARK: - Getter

extension Router {
    
    public func viewController(for url: URLConvertible, userInfo: [String: Any] = [:]) -> UIViewController? {
        guard let url = url.urlValue else { return nil }
        if !canOpenURL(url) { return nil }
        let param = Route.Param(url: url, userInfo: userInfo)
        guard let routable = routableMap[param.routeID],
              let routableViewController = routable.make(with: param)
        else { return nil }
        return routableViewController
    }
    
    public func viewController(for key: Route.Key, userInfo: [String: Any] = [:]) -> UIViewController? {
        guard let url = key.url(with: host) else { return nil }
        return viewController(for: url, userInfo: userInfo)
    }
    
    public func action(for url: URLConvertible) -> Route.Action? {
        guard let url = url.urlValue else { return nil }
        if !canOpenURL(url) { return nil }
        let param = Route.Param(url: url)
        return actionMap[param.routeID]
    }
    
    public func action(for key: Route.Key) -> Route.Action? {
        guard let url = key.url(with: host) else { return nil }
        return action(for: url)
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
    public func open(byKey key: Route.Key, userInfo: [String: Any] = [:], completion: Route.Completion? = nil) -> Bool {
        guard let url = key.url(with: host) else {
            assert(false, "Generate url failed for \(key)")
            return false
        }
        return open(url, userInfo: userInfo, completion: completion)
    }
    
    /// Open a page or execute an action by a url.
    /// URLString will be transformed to URL instance even though there are some special characters, such as Chinese.
    ///
    ///     Router.shared.open("myapp://user?name=apple")
    ///     Router.shared.open(URL(string: "myapp://user?name=apple")!)
    @discardableResult
    public func open(_ url: URLConvertible, userInfo: [String: Any] = [:], completion: Route.Completion? = nil) -> Bool {
        guard var url = url.urlValue else {
            completion?(false)
            return false
        }
        if !isAllowedForScheme(url.scheme) {
            defer { tellDelegateResult(false, forURL: url, userInfo: userInfo) }
            completion?(false)
            return false
        }
        if let delegate = delegate {
            if let modifiedURL = delegate.router(self, willOpenURL: url, userInfo: userInfo) {
                url = modifiedURL
            } else {
                defer { tellDelegateResult(false, forURL: url, userInfo: userInfo) }
                completion?(false)
                return false
            }
        }
        let param = Route.Param(url: url, userInfo: userInfo)
        if let interceptions = interceptors[param.routeID], !interceptions.reduce(true, { $0 && $1(param) }) {
            defer { tellDelegateResult(false, forURL: url, userInfo: userInfo) }
            completion?(false)
            return false
        }
        if let action = actionMap[param.routeID] {
            sendWillOpenNotification(with: param)
            action(param)
            defer {
                tellDelegateResult(true, forURL: url, userInfo: userInfo)
                sendDidOpenNotificationIfNeeded(true, with: param)
            }
            completion?(true)
            return true
        } else if let routable = routableMap[param.routeID] {
            if let redirectURL = routable.redirectURLWithRouteParam(param) {
                return open(redirectURL, userInfo: userInfo, completion: completion)
            }
            guard let viewController = routable.make(with: param),
                  let routableViewController = viewController as? (any Routable)
            else {
                assert(false, "Init \(routable) failed.")
                defer { tellDelegateResult(false, forURL: url, userInfo: userInfo) }
                completion?(false)
                return false
            }
            sendWillOpenNotification(with: param)
            let result = open(routable: routableViewController, animated: param.animated ?? true, completion: completion)
            tellDelegateResult(result, forURL: url, userInfo: userInfo)
            sendDidOpenNotificationIfNeeded(result, with: param)
            return result
        } else {
            if let fallbackURL = param.fallbackURL {
                let result = open(fallbackURL, userInfo: userInfo, completion: completion)
                if result { delegate?.router(self, didFallbackToURL: fallbackURL, userInfo: userInfo) }
                return result
            }
            assert(false, "\(param.routeID) can NOT be handled.")
            defer { tellDelegateResult(false, forURL: url, userInfo: userInfo) }
            completion?(false)
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
        transitionExecutor: Route.TransitionExecutor = .router,
        completion: Route.Completion? = nil
    ) -> Bool {
        guard let url = key.url(with: host) else {
            completion?(false)
            return false
        }
        return push(url, userInfo: userInfo, animated: animated, transitionExecutor: transitionExecutor, completion: completion)
    }
    
    /// Push a view controller by a url.
    ///
    ///     AppRouter.push("myapp://user?name=apple")
    @discardableResult
    public func push(
        _ url: URLConvertible,
        userInfo: [String: Any] = [:],
        animated: Bool = true,
        transitionExecutor: Route.TransitionExecutor = .router,
        completion: Route.Completion? = nil
    ) -> Bool {
        guard var url = url.urlValue else {
            completion?(false)
            return false
        }
        if !isAllowedForScheme(url.scheme) {
            defer { tellDelegateResult(false, forURL: url, userInfo: userInfo) }
            completion?(false)
            return false
        }
        if let delegate = delegate {
            if let modifiedURL = delegate.router(self, willOpenURL: url, userInfo: userInfo) {
                url = modifiedURL
            } else {
                defer { tellDelegateResult(false, forURL: url, userInfo: userInfo) }
                completion?(false)
                return false
            }
        }
        let param = Route.Param(url: url, userInfo: userInfo)
        if let interceptions = interceptors[param.routeID], !interceptions.reduce(true, { $0 && $1(param) }) {
            defer { tellDelegateResult(false, forURL: url, userInfo: userInfo) }
            completion?(false)
            return false
        }
        if let routable = routableMap[param.routeID] {
            if let redirectURL = routable.redirectURLWithRouteParam(param) {
                return push(redirectURL, userInfo: userInfo, animated: animated, transitionExecutor: transitionExecutor, completion: completion)
            }
            guard let routableViewController = routable.make(with: param) else {
                assert(false, "Init \(routable) failed.")
                defer { tellDelegateResult(false, forURL: url, userInfo: userInfo) }
                completion?(false)
                return false
            }
            sendWillOpenNotification(with: param)
            let result = _push(
                viewController: routableViewController,
                animated: param.animated ?? animated,
                param: param,
                transitionExecutor: transitionExecutor,
                completion: completion
            )
            tellDelegateResult(result, forURL: url, userInfo: userInfo)
            sendDidOpenNotificationIfNeeded(result, with: param)
            return result
        } else {
            if let fallbackURL = param.fallbackURL {
                let result = push(fallbackURL, userInfo: userInfo, animated: animated, transitionExecutor: transitionExecutor, completion: completion)
                if result { delegate?.router(self, didFallbackToURL: fallbackURL, userInfo: userInfo) }
                return result
            }
            assert(false, "\(param.routeID) can NOT be handled.")
            defer { tellDelegateResult(false, forURL: url, userInfo: userInfo) }
            completion?(false)
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
        transitionExecutor: Route.TransitionExecutor = .router,
        completion: Route.Completion? = nil
    ) -> Bool {
        guard let url = key.url(with: host) else {
            completion?(false)
            return false
        }
        return present(
            url,
            embedIn: navigationControllerClass,
            userInfo: userInfo,
            animated: animated,
            presentationStyle: presentationStyle,
            transitionExecutor: transitionExecutor,
            completion: completion
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
        transitionExecutor: Route.TransitionExecutor = .router,
        completion: Route.Completion? = nil
    ) -> Bool {
        guard var url = url.urlValue else {
            completion?(false)
            return false
        }
        if !isAllowedForScheme(url.scheme) {
            defer { tellDelegateResult(false, forURL: url, userInfo: userInfo) }
            completion?(false)
            return false
        }
        if let delegate = delegate {
            if let modifiedURL = delegate.router(self, willOpenURL: url, userInfo: userInfo) {
                url = modifiedURL
            } else {
                defer { tellDelegateResult(false, forURL: url, userInfo: userInfo) }
                completion?(false)
                return false
            }
        }
        let param = Route.Param(url: url, userInfo: userInfo)
        if let interceptions = interceptors[param.routeID], !interceptions.reduce(true, { $0 && $1(param) }) {
            defer { tellDelegateResult(false, forURL: url, userInfo: userInfo) }
            completion?(false)
            return false
        }
        if let routable = routableMap[param.routeID] {
            if let redirectURL = routable.redirectURLWithRouteParam(param) {
                return present(
                    redirectURL,
                    embedIn: navigationControllerClass,
                    userInfo: userInfo,
                    animated: animated,
                    transitionExecutor: transitionExecutor,
                    completion: completion
                )
            }
            guard let routableViewController = routable.make(with: param) else {
                assert(false, "Init \(routable) failed.")
                defer { tellDelegateResult(false, forURL: url, userInfo: userInfo) }
                completion?(false)
                return false
            }
            var toController = routableViewController
            if let navigationControllerClass = navigationControllerClass,
               !(toController is UINavigationController) {
                toController = navigationControllerClass.init(rootViewController: toController)
            }
            sendWillOpenNotification(with: param)
            let result = _present(
                viewController: toController,
                animated: param.animated ?? animated,
                param: param,
                presentationStyle: presentationStyle ?? preferredPresentationStyle,
                transitionExecutor: transitionExecutor,
                completion: completion
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
                    transitionExecutor: transitionExecutor,
                    completion: completion
                )
                if result { delegate?.router(self, didFallbackToURL: fallbackURL, userInfo: userInfo) }
                return result
            }
            assert(false, "\(param.routeID) can NOT be handled.")
            defer { tellDelegateResult(false, forURL: url, userInfo: userInfo) }
            completion?(false)
            return false
        }
    }
    
    /// Open a `Routable` view controller with the default open style.
    @discardableResult
    public func open(routable: any Routable, animated: Bool = true, completion: Route.Completion? = nil) -> Bool {
        let viewController = routable as UIViewController
        var result = false
        let openStyle = routable.preferredOpenStyle ?? self.preferredOpenStyle
        switch openStyle {
        case .push:
            result = push(viewController: viewController, animated: animated, completion: completion)
            if !result {
                result = present(viewController: viewController, animated: animated, completion: completion)
            }
        case .present(let modalPresentationStyle):
            result = present(viewController: viewController, animated: animated, presentationStyle: modalPresentationStyle, completion: completion)
            if !result {
                result = push(viewController: viewController, animated: animated, completion: completion)
            }
        }
        return result
    }
    
    /// Open a view controller with the default open style. Pass a navigationVC class if needed for presenting.
    @discardableResult
    public func open(
        viewController: UIViewController,
        animated: Bool = true,
        openStyle: Route.OpenStyle? = nil,
        embedIn navigationControllerClass: UINavigationController.Type? = nil,
        completion: Route.Completion? = nil
    ) -> Bool {
        var result = false
        let openStyle = openStyle ?? self.preferredOpenStyle
        switch openStyle {
        case .push:
            result = push(viewController: viewController, animated: animated, completion: completion)
            if !result {
                result = present(
                    viewController: viewController,
                    animated: animated,
                    embedIn: navigationControllerClass,
                    completion: completion
                )
            }
        case .present(let modalPresentationStyle):
            result = present(
                viewController: viewController,
                animated: animated,
                presentationStyle: modalPresentationStyle,
                embedIn: navigationControllerClass,
                completion: completion
            )
            if !result {
                result = push(viewController: viewController, animated: animated, completion: completion)
            }
        }
        return result
    }
    
    /// Push a view controller with the default open style.
    @discardableResult
    public func push(
        viewController: UIViewController,
        animated: Bool = true,
        completion: Route.Completion? = nil
    ) -> Bool {
        return _push(viewController: viewController, animated: animated, completion: completion)
    }
    
    /// Present a view controller with the default open style.
    @discardableResult
    public func present(
        viewController: UIViewController,
        animated: Bool = true,
        presentationStyle: UIModalPresentationStyle = .fullScreen,
        embedIn navigationControllerClass: UINavigationController.Type? = nil,
        completion: Route.Completion? = nil
    ) -> Bool {
        var viewController = viewController
        if let navigationControllerClass = navigationControllerClass,
           !(viewController is UINavigationController) {
            viewController = navigationControllerClass.init(rootViewController: viewController)
        }
        return _present(viewController: viewController, animated: animated, presentationStyle: presentationStyle, completion: completion)
    }
}


// MARK: - Private

extension Router {
    
    @discardableResult
    private func _push(
        viewController: UIViewController,
        animated: Bool = true,
        param: Route.Param = .default,
        transitionExecutor: Route.TransitionExecutor = .router,
        completion: Route.Completion? = nil
    ) -> Bool {
        guard !(viewController is UINavigationController) else {
            completion?(false)
            return false
        }
        guard let topNavigationController = UIApplication.shared.topMostNavigationController else {
            completion?(false)
            return false
        }
        switch transitionExecutor {
        case .router:
            topNavigationController.pushViewController(viewController, animated: animated) {
                completion?(true)
            }
            return true
        case .user(let execute):
            let result = execute(topNavigationController, nil, viewController)
            completion?(result)
            return result
        case .delegate:
            guard let delegate = delegate else { return false }
            let result = delegate.routeTransition(
                with: self,
                param: param,
                fromNavigationController: topNavigationController,
                fromViewController: nil,
                toViewController: viewController
            )
            completion?(result)
            return result
        }
    }
    
    @discardableResult
    private func _present(
        viewController: UIViewController,
        animated: Bool = true,
        param: Route.Param = .default,
        presentationStyle: UIModalPresentationStyle = .fullScreen,
        transitionExecutor: Route.TransitionExecutor = .router,
        completion: Route.Completion? = nil
    ) -> Bool {
        guard let topViewController = UIApplication.shared.topMostViewController else {
            completion?(false)
            return false
        }
        switch transitionExecutor {
        case .router:
            viewController.modalPresentationStyle = presentationStyle
            topViewController.present(viewController, animated: animated) {
                completion?(true)
            }
            return true
        case .user(let execute):
            let result = execute(nil, topViewController, viewController)
            completion?(result)
            return result
        case .delegate:
            guard let delegate = delegate else { return false }
            let result = delegate.routeTransition(
                with: self,
                param: param,
                fromNavigationController: nil,
                fromViewController: topViewController,
                toViewController: viewController
            )
            completion?(result)
            return result
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

// MARK: - Launch
extension Router {
    @objc
    public static func router_load() {
        if let configable = self as? RouterConfigable.Type {
            switch configable.registrationMode {
            case .auto:
                Router.shared.registerRoutes()
            case .lazy:
                Router.shared.lazyRegistration = true
            case .manual:
                break
            }
            Router.shared.host = configable.host
        } else {
            Router.shared.registerRoutes()
        }
    }
    
    private static let segmentName = "__DATA"
    private static let actionSectionName = "__rerouter_ac"
    private static let vcSectionName = "__rerouter_vc"
    
    /// Registers routes defined by macro.
    ///
    /// - Note: This method is automatically called if `registrationMode` is set to `.auto`.
    ///         Otherwise, you need to call this method manually to register routes.
    ///
    /// - Important: Ensure this method is called before using any routes, unless auto-registration is enabled.
    public func registerRoutes() {
        Router.readSectionDatas()
    }
    
    private static func readSectionDatas() {
        readViewControllers()
        readActions()
    }
    
    private static func readActions() {
        let actions = SectionReader.read(RouteActionInfo.self, segment: segmentName, section: actionSectionName)
        for info in actions {
            let string = info.0.description
            let function = info.1
            Router.shared.registerAction(with: string.routeKey, function)
        }
    }
    
    private static func readViewControllers() {
        let vcStrings = SectionReader.read(StaticString.self, segment: segmentName, section: vcSectionName)
        for info in vcStrings {
            let parts = info.description.components(separatedBy: ":")
            if parts.count == 2 {
                let key = parts[0]
                let vc = parts[1]
                if let routableClass = NSClassFromString(vc) as? any Routable.Type {
                    Router.shared.register(routableClass, forKey: key.routeKey)
                }
            } else {
                assert(false, "Register controller should have 2 parts")
            }
        }
    }
}
#endif
