[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/reers/ReerRouter)

# ReerRouter
适用于iOS的应用程序URL路由器（仅限Swift）。受到[URLNavigator](https://github.com/devxoul/URLNavigator)的启发。

Swift 5.10 之后, 支持了@_used @_section 可以将数据写入 section, 再结合 Swift Macro, 就可以实现 OC 时代各种解耦和的, 用于注册信息的能力了. 本框架也支持了以这种方式注册路由

注册 UIViewController
```
extension Route.Key {
    // 注意 chat 变量名要和赋值的字符串完全一致
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

注册 action:
```
extension Route.Key {
    // 注意 testKey 变量名要和赋值的字符串完全一致
    static let testKey: Self = "testKey"
}

struct Foo {
    #route(key: .testKey, action: { params in
        print("testKey triggered nested")
    })
}
```
🟡 目前 @_used @_section 这个能力还是 Swift 的实验 Feature, 需要通过配置项开启, 详见接入文档.

## 示例应用程序
要运行该示例项目，请克隆 repo，并首先在 Example 目录中运行 `pod install`。

## 要求
XCode 16.0 +

iOS 13 +

Swift 5.10

swift-syntax 600.0.0

## 安装

### CocoaPods
ReerRouter 可以通过 [CocoaPods](https://cocoapods.org) 获得。要安装
它，只需在你的Podfile中添加以下一行。

```ruby
pod 'ReerRouter'
```
由于 CocoaPods 不支持直接使用 Swift Macro, 可以将宏实现编译为二进制提供使用, 接入方式如下, 需要在依赖路由的组件设置`s.pod_target_xcconfig`来加载宏实现的二进制插件:
```
s.pod_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-enable-experimental-feature SymbolLinkageMarkers -Xfrontend -load-plugin-executable -Xfrontend ${PODS_ROOT}/ReerRouter/MacroPlugin/ReerRouterMacros#ReerRouterMacros'
  }
  
  s.user_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-enable-experimental-feature SymbolLinkageMarkers -Xfrontend -load-plugin-executable -Xfrontend ${PODS_ROOT}/ReerRouter/MacroPlugin/ReerRouterMacros#ReerRouterMacros'
  }
```
或者, 如果不使用`s.pod_target_xcconfig`, 也可以在 podfile 中添加如下脚本统一处理:
```
post_install do |installer|
  installer.pods_project.targets.each do |target|
    rhea_dependency = target.dependencies.find { |d| ['ReerRouter'].include?(d.name) }
    if rhea_dependency
      puts "Adding Rhea Swift flags to target: #{target.name}"
      target.build_configurations.each do |config|
        swift_flags = config.build_settings['OTHER_SWIFT_FLAGS'] ||= ['$(inherited)']
        
        plugin_flag = '-Xfrontend -load-plugin-executable -Xfrontend ${PODS_ROOT}/ReerRouter/MacroPlugin/ReerRouterMacros#ReerRouterMacros'
        
        unless swift_flags.join(' ').include?(plugin_flag)
          swift_flags.concat(plugin_flag.split)
        end

        # 添加 SymbolLinkageMarkers 实验性特性标志
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
对于要依赖 ReerRouter 的 package, 需要开启 swift 实验 feature
```
// Package.swift
let package = Package(
    name: "APackageDependOnReerRouter",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "APackageDependOnReerRouter", targets: ["APackageDependOnReerRouter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/reers/ReerRouter.git", from: "2.2.7")
    ],
    targets: [
        .target(
            name: "APackageDependOnReerRouter",
            dependencies: [
                .product(name: "ReerRouter", package: "ReerRouter")
            ],
            // 此处添加开启实验 feature
            swiftSettings:[.enableExperimentalFeature("SymbolLinkageMarkers")]
        ),
    ]
)
```

在主App Target中 Build Settings设置开启实验feature:
-enable-experimental-feature SymbolLinkageMarkers
![CleanShot 2024-10-12 at 20 39 59@2x](https://github.com/user-attachments/assets/6a15fd27-61cf-4d55-974e-8f6006577527)


## 开始使用

### 1. 了解 `Route.Key`
`Route.Key`有两种 Mode.

#### Mode1: `Route.Key`意味着URL `host` + `path`。
```
/// myapp://example.com/over/there?name=phoenix#nose
/// \______/\_________/\_________/ \__________/ \__/
///    |         |          |           |        |
///  scheme     host       path      queries   fragment
///              \_________/
///                   |
///               route key
```

#### Mode 2: 设置路由器的 `host` 属性, 那么 `Route.Key` 则仅表示 `path`
```
/// myapp://example.com/over/there?name=phoenix#nose
/// \______/\_________/\_________/ \__________/ \__/
///    |         |          |           |        |
///  scheme     host       path      queries   fragment
///                         |
///                         |
///                    route key
```
可以通过实现 `RouterConfigable` 协议来配置为 Mode 2
```
extension Router: RouterConfigable {
    public static var host: String {
        return "example.com"
    }
}
```

### 2. 注册路由
#### 注册路由表
##### Mode 1: 现在 `Route.Key` 表示 url 的 `host` 和 `path` 拼接到一起.
* 注册一个 action
```
Router.shared.registerAction(with: "abc_action") { _ in
    print("action executed.")
}
```

* 通过 UIViewController 类型和 Route.Key 常量注册一个路由
```
extension Route.Key {
    static let userPage: Self = "user"
}
Router.shared.register(UserViewController.self, forKey: .userPage)
Router.shared.register(UserViewController.self, forKey: "user")
```

* 通过 UIViewController 类型和字符串 key 注册一个路由
```
Router.shared.registerPageClasses(with: ["preference": PreferenceViewController.self])
```

* 通过 UIViewController 字符串和字符串 key 注册一个路由
```
Router.shared.registerPageClasses(with: ["preference": "ReerRouter_Example.PreferenceViewController"])
```

* 使用 Swift Macro 来注册
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

##### Mode 2: 首先需要给路由器设置 `host` 属性
```
Router.shared.host = "phoenix.com"
```
现在 `Route.Key` 仅表示 `path`, 然后其他所有注册方法与 Mode1 相同. ("path", "/path" 两种表达方式都支持)

#### 为 UIViewController 实现`Routable'。
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

### 3. 执行一个路由 action。
```
Router.shared.executeAction(byKey: "abc_action")

// Mode 1
Router.shared.open("myapp://abc_action")

// Mode 2
Router.shared.open("myapp://phoenix.com/abc_action")
```

### 4. 打开一个 UIViewController.
```
Router.shared.present(byKey: .userPage, embedIn: UINavigationController.self, userInfo: [
    "name": "apple",
    "id": "123123"
])

// Mode 1
Router.shared.open("myapp://user?name=phoenix")
Router.shared.push("myapp://user?name=phoenix")
Router.shared.present("myapp://user?name=phoenix")

// Mode 2
Router.shared.open("myapp://phoenix.com/user?name=phoenix")
Router.shared.push("myapp://phoenix.com/user?name=phoenix")
Router.shared.present("myapp://phoenix.com/user?name=phoenix")
```

### 5. Router Delegate.
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

### 6. fallback 逻辑
* 使用`route_fallback_url` key 作为出错时的备用页面.
```
Router.shared.open("myapp://unregisteredKey?route_fallback_url=myapp%3A%2F%2Fuser%3Fname%3Di_am_fallback" )
```

### 7. 重定向
* 实现`redirectURLWithRouteParam(_:)`方法，为视图控制器重定向到一个新的URL。
```
class PreferenceViewController: UIViewController, Routable {
    static func make(with param: Route.Param) -> PreferenceViewController? {
        return .init()
    }
    static func redirectURLWithRouteParam(_ param: Route.Param) -> URL? {
        if let value = param.allParams["some_key"] as? String, value == "redirect" {
            return URL(string: "myapp://new_preference")
        }
        return nil
    }
}
```

### 8. Router 全局单例。
```
public let AppRouter = Router.shared
AppRouter.open("myapp://user")
```

### 9. 路由将要被打开和已经打开时的通知。
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

### 10. 自定义转场动画.
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

### 11. UIViewController 打开方式
路由器处理 UIViewController 打开方式的时候, 按照以下优先级顺序选取 style:
```
`Router` 的属性 `preferredOpenStyle` <
  控制器实现的 `Routable` 协议属性 `preferredOpenStyle` <
    使用者调用的方法, 比如, 如果你调用的是 `Router.push(...)`, 那控制器就以 push 的方式打开.
```

### 12. 禁用跳转动画
* 用 `route_no_animation` 字段来禁掉转场动画
```
Router.shared.open("myapp://user?name=google&route_no_animation=1")
```

### 13. 外部拦截
在一些特殊场景对路由进行拦截, 返回 false 表示对该 url 进行拦截.
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

### 14. 自定义时机来获取注册在 section 中的路由
```
extension Router: RouterConfigable {
    // 由该配置关闭自动获取
    public static var registrationMode: RegistrationMode { return .manual }
}
// 然后在合适的时机调用 
Router.shared.registerRoutes()
```

## Author

phoenix, x.rhythm@qq.com

## License

ReerRouter is available under the MIT license. See the LICENSE file for more info.
