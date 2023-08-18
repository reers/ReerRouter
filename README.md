[中文文档](https://github.com/reers/ReerRouter/wiki/%E4%B8%AD%E6%96%87%E6%96%87%E6%A1%A3)

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
        .package(url: "https://github.com/reers/ReerRouter.git", from: "0.2.2")
    ]
)
```
Next, add ReerRouter to your targets dependencies like so:
```
.target(
    name: "YOUR_TARGET_NAME",
    dependencies: ["ReerRouter",]
),
```

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
    
    required init?(param: Route.Param) {
        self.params = param.allParams
        super.init(nibName: nil, bundle: nil)
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

## Author

phoenix, x.rhythm@qq.com

## License

ReerRouter is available under the MIT license. See the LICENSE file for more info.
