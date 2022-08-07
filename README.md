# ReerRouter
App URL router for iOS (Swift only). Inspired by [URLNavigator](https://github.com/devxoul/URLNavigator).


## Example App
To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
At least iOS 10.0
Xcode 13.2

## Installation

### CocoaPods
ReerRouter is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ReerRouter'
```
### Swift Package Manager
```
import PackageDescription

let package = Package(
    name: "YOUR_PROJECT_NAME",
    targets: [],
    dependencies: [
        .package(url: "https://github.com/reers/ReerRouter.git", from: "0.1.0")
    ]
)
```
```
.target(
    name: "YOUR_TARGET_NAME",
    dependencies: ["ReerRouter",]
),
```

## Getting Started
### 1. Understanding `Route.Key`
`Route.Key` means URL `host` + `path`
```
/// myapp://example.com/over/there?name=phoenix#nose
/// \______/\_________/\_________/ \__________/ \__/
///    |         |          |           |        |
///  scheme     host       path      queries   fragment
///              \_________/
///                   |
///               route key
```
### 2. Register Route

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

* Implement `Routable` for view controller.
```
class UserViewController: UIViewController, Routable {
    var params: [String: Any]
    
    required init?(param: Route.Param) {
        self.params = param.allParams
        super.init(nibName: nil, bundle: nil)
    }
}   
```

### 3. Execute an route action.
```
Router.shared.executeAction(byKey: "abc_action")
Router.shared.open("myapp://abc_action")
```

### 4. Open a view controller.
```
Router.shared.open("myapp://user?name=phoenix")
Router.shared.push("myapp://user?name=phoenix")
Router.shared.present("myapp://user?name=phoenix")
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
    
    required init?(param: Route.Param) {
        super.init(nibName: nil, bundle: nil)
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

## Author

phoenix, x.rhythm@qq.com

## License

ReerRouter is available under the MIT license. See the LICENSE file for more info.
