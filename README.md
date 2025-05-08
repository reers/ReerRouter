[中文文档](https://github.com/reers/ReerRouter/wiki/%E4%B8%AD%E6%96%87%E6%96%87%E6%A1%A3)

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/reers/ReerRouter)

# ReerRouter
App URL router for iOS (Swift only). Inspired by [URLNavigator](https://github.com/devxoul/URLNavigator).

Swift 5.10 and later support @_used and @_section, allowing data to be written into sections. Combined with Swift Macros, this enables capabilities similar to various decoupling and registration information methods from the Objective-C era. This framework also supports registering routes in this manner.

Registering UIViewController
```
extension Route.Key {
    // Note: The variable name 'chat' must exactly match the assigned string
    static let chat: Route.Key = "chat"
}

@Routable(.chat)
class ChatViewController: UIViewController {
    static func make(with param: Route.Param) -> ChatViewController? {
        return .init()
    }

    // ... other methods ...
}

@Routable("setting")
class SettingViewController: UIViewController {
    static func make(with param: Route.Param) -> SettingViewController? {
        return .init()
    }

    // ... other methods ...
}
```
Registering an action:
```
extension Route.Key {
    // Note: The variable name 'testKey' must exactly match the assigned string
    static let testKey: Self = "testKey"
}

struct Foo {
    #route(key: .testKey, action: { params in
        print("testKey triggered nested")
    })
}
```
🟡 Currently, the @_used and @_section capabilities are still an experimental feature in Swift and need to be enabled through configuration settings. Please refer to the integration documentation for details.

## Example App
To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
XCode 16.0 +

iOS 13 +

Swift 5.10

swift-syntax 600.0.0

## Installation

### CocoaPods
ReerRouter is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ReerRouter'
```
As CocoaPods does not directly support the use of Swift Macros, the macro implementation can be compiled into a binary for use. The integration method is as follows. It's necessary to set s.pod_target_xcconfig in the components dependent on the router to load the binary plugin of the macro implementation:
```
s.pod_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-enable-experimental-feature SymbolLinkageMarkers -Xfrontend -load-plugin-executable -Xfrontend ${PODS_ROOT}/ReerRouter/Sources/Resources/ReerRouterMacros#ReerRouterMacros'
  }
  
  s.user_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-enable-experimental-feature SymbolLinkageMarkers -Xfrontend -load-plugin-executable -Xfrontend ${PODS_ROOT}/ReerRouter/Sources/Resources/ReerRouterMacros#ReerRouterMacros'
  }
```
Alternatively, if s.pod_target_xcconfig is not used, you can add the following script to the Podfile for unified processing:
```
post_install do |installer|
  installer.pods_project.targets.each do |target|
    rhea_dependency = target.dependencies.find { |d| ['ReerRouter'].include?(d.name) }
    if rhea_dependency
      puts "Adding Rhea Swift flags to target: #{target.name}"
      target.build_configurations.each do |config|
        swift_flags = config.build_settings['OTHER_SWIFT_FLAGS'] ||= ['$(inherited)']
        
        plugin_flag = '-Xfrontend -load-plugin-executable -Xfrontend ${PODS_ROOT}/ReerRouter/Sources/Resources/ReerRouterMacros#ReerRouterMacros'
        
        unless swift_flags.join(' ').include?(plugin_flag)
          swift_flags.concat(plugin_flag.split)
        end

        # Add experimental feature flag for SymbolLinkageMarkers
        symbol_linkage_flag = '-enable-experimental-feature SymbolLinkageMarkers'

        unless swift_flags.join(' ').include?(symbol_linkage_flag)
          swift_flags.concat(symbol_linkage_flag.split)
        end

        config.build_settings['OTHER_SWIFT_FLAGS'] = swift_flags
      end
    end
  end
end

```
### Swift Package Manager
For packages that need to depend on ReerRouter, it's necessary to enable the Swift experimental feature:
```
// Package.swift
let package = Package(
    name: "APackageDependOnReerRouter",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "APackageDependOnReerRouter", targets: ["APackageDependOnReerRouter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/reers/ReerRouter.git", from: "2.2.5")
    ],
    targets: [
        .target(
            name: "APackageDependOnReerRouter",
            dependencies: [
                .product(name: "ReerRouter", package: "ReerRouter")
            ],
            // Add here to enable the experimental feature
            swiftSettings:[.enableExperimentalFeature("SymbolLinkageMarkers")]
        ),
    ]
)
```
In the main App Target's Build Settings, set to enable the experimental feature:
-enable-experimental-feature SymbolLinkageMarkers
![CleanShot 2024-10-12 at 20 39 59@2x](https://github.com/user-attachments/assets/6a15fd27-61cf-4d55-974e-8f6006577527)

## Getting Started
### 1. Understanding `Route.Key`

There are two modes of `Route.Key`.

Mode 1: `Route.Key` means URL `host` + `path`
```
/// myapp://example.com/over/there?name=phoenix#nose
/// \______/\_________/\_________/ \__________/ \__/
///    |         |          |           |        |
///  scheme     host       path      queries   fragment
///              \_________/
///                   |
///               route key
```

Mode 1: Set `host` for router instance and use `path` as the `Route.Key`.
```
/// myapp://example.com/over/there?name=phoenix#nose
/// \______/\_________/\_________/ \__________/ \__/
///    |         |          |           |        |
///  scheme     host       path      queries   fragment
///                         |
///                         |
///                    route key
```
You can configure to Mode 2 by implementing the RouterConfigable protocol:
```
extension Router: RouterConfigable {
    public static var host: String {
        return "example.com"
    }
}
```
### 2. Register Route
#### Mode 1
Now `Route.Key` means the combination of url `host` and `path`.

* Register an action.
```
Router.shared.registerAction(with: "abc_action") { _ in
    print("action executed.")
}
```

* Register a view controller by its type and a route key.
```
extension Route.Key {
    static let userPage: Self = "user"
}
Router.shared.register(UserViewController.self, forKey: .userPage)
Router.shared.register(UserViewController.self, forKey: "user")
```

* Register view controllers by their types and route keys.
```
Router.shared.registerPageClasses(with: ["preference": PreferenceViewController.self])
```

* Register view controllers by their type names and route keys.
```
Router.shared.registerPageClasses(with: ["preference": "ReerRouter_Example.PreferenceViewController"])
```

* Register view controllers and actions via Swift Macro
```
extension Route.Key {
    static let testKey: Self = "testKey"
}

struct Foo {
    #route(key: .testKey, action: { params in
        print("testKey triggered nested")
    })
}
```

```
extension Route.Key {
    static let chat: Route.Key = "chat"
}

@Routable(.chat)
class ChatViewController: UIViewController {
    static func make(with param: Route.Param) -> ChatViewController? {
        return .init()
    }

    // ... other methods ...
}

@Routable("setting")
class SettingViewController: UIViewController {
    static func make(with param: Route.Param) -> SettingViewController? {
        return .init()
    }

    // ... other methods ...
}
```

#### Mode 2
Firstly, you should set `host` for router instance.
```
Router.shared.host = "phoenix.com"
```
And now `Route.Key` means url path, then all the register methods are same as `Mode 1`.
("path", "/path" both are supported.)

* Implement `Routable` for view controller.
```
class UserViewController: UIViewController, Routable {
    var params: [String: Any]
    
    init(params: [String: Any]) {
        self.params = params
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func make(with param: Route.Param) -> UserViewController? {
        return .init(params: param.allParams)
    }
}   
```

### 3. Execute an route action.
```
Router.shared.executeAction(byKey: "abc_action")

// Mode 1.
Router.shared.open("myapp://abc_action")

// Mode 2.
Router.shared.open("myapp://phoenix.com/abc_action")
```

### 4. Open a view controller.
```
Router.shared.present(byKey: .userPage, embedIn: UINavigationController.self, userInfo: [
    "name": "apple",
    "id": "123123"
])

// Mode 1.
Router.shared.open("myapp://user?name=phoenix")
Router.shared.push("myapp://user?name=phoenix")
Router.shared.present("myapp://user?name=phoenix")

// Mode 2.
Router.shared.open("myapp://phoenix.com/user?name=phoenix")
Router.shared.push("myapp://phoenix.com/user?name=phoenix")
Router.shared.present("myapp://phoenix.com/user?name=phoenix")
```

### 5. Delegate for for the app about the route.
```
extension RouteManager: RouterDelegate {
    func router(_ router: Router, willOpenURL url: URL, userInfo: [String : Any]) -> URL? {
        print("will open \(url)")
        if let _ = url.absoluteString.range(of: "google") {
            return URL(string: url.absoluteString + "&extra1=234244&extra2=afsfafasd")
        } else if let _ = url.absoluteString.range(of: "bytedance"), !isUserLoggedIn() {
            print("intercepted by delegate")
            return nil
        }
        return url
    }

    func router(_ router: Router, didOpenURL url: URL, userInfo: [String : Any]) {
        print("did open \(url) success")
    }
    
    func router(_ router: Router, didFailToOpenURL url: URL, userInfo: [String : Any]) {
        print("did fail to open \(url)")
    }
    
    func router(_ router: Router, didFallbackToURL url: URL, userInfo: [String: Any]) {
        print("did fallback to \(url)")
    }
}
```

### 6. Fallback
* Use `route_fallback_url` key as a fallback url when some thing went wrong.
```
Router.shared.open("myapp://unregisteredKey?route_fallback_url=myapp%3A%2F%2Fuser%3Fname%3Di_am_fallback")
```

### 7. Redirect
* Implement `redirectURLWithRouteParam(_:)` method to redirect to a new url for the view controller.
```
class PreferenceViewController: UIViewController, Routable {
    static func make(with param: Route.Param) -> PreferenceViewController? {
        return .init()
    }
    
    class func redirectURLWithRouteParam(_ param: Route.Param) -> URL? {
        if let value = param.allParams["some_key"] as? String, value == "redirect" {
            return URL(string: "myapp://new_preference")
        }
        return nil
    }
}
```

### 8. Global instance for the router singleton.
```
public let AppRouter = Router.shared
AppRouter.open("myapp://user")
```

### 9. Notifications when will open and did open.
```
NotificationCenter.default.addObserver(
    forName: Notification.Name.routeWillOpenURL,
    object: nil,
    queue: .main
) { notification in
    if let param = notification.userInfo?[Route.notificationUserInfoKey] as? Route.Param {
        print("notification: route will open \(param.sourceURL)")
    }
}

NotificationCenter.default.addObserver(
    forName: Notification.Name.routeDidOpenURL,
    object: nil,
    queue: .main
) { notification in
    if let param = notification.userInfo?[Route.notificationUserInfoKey] as? Route.Param {
        print("notification: route did open \(param.sourceURL)")
    }
}
```

### 10. Custom controlling for transition.
```
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
    /// Transition will be handled by user who invoke the router `push` or `present` method.
    case delegate
}

let transition: Route.UserTransition = { fromNavigationController, fromViewController, toViewController in
    toViewController.transitioningDelegate = self.animator
    toViewController.modalPresentationStyle = .currentContext
    // Use the router found view controller directly, or just handle transition by yourself.
    // fromViewController?.present(toViewController, animated: true)
    self.present(toViewController, animated: true)
    return true
}
AppRouter.present(user.urlString, transitionExecutor: .user(transition))
```

### 11. Open style for UIViewController.
The priority levels on which the way router opens the controller depend are as follows:
```
`Router` instance property `preferredOpenStyle` <
  `Routable` property `preferredOpenStyle` that UIViewController implemented <
    The method you called. If you called `Router.push(...)`, the view controller will be pushed.
```

### 12. Forbidden transition animation.
* Use `route_no_animation` key to forbidden animation.
```
Router.shared.open("myapp://user?name=google&route_no_animation=1")
```

### 13. Intercept by external.
Intercept a route in some special scenarios, return false means to intercept the url.
```
Router.shared.addInterceptor(forKey: .userPage) { (_) -> Bool in
    print("intercepted user page")
    return true
}

Router.shared.addInterceptor(forKey: .userPage) { (params) -> Bool in
    print("intercepted user page")
    if let name = params.allParams["name"] as? String, name == "google" {
        print("intercepted user page success")
        return false
    }
    return true
}
```

### 14. Customize the timing to retrieve routes registered in the section
```
extension Router: RouterConfigable {
    // This configuration disables automatic retrieval
    public static var registrationMode: RegistrationMode { return .manual }
}
// Then call at an appropriate time
Router.shared.registerRoutes()
```

## Author

phoenix, x.rhythm@qq.com

## License

ReerRouter is available under the MIT license. See the LICENSE file for more info.
