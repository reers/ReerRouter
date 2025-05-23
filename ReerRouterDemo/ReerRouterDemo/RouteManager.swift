//
//  RouteManager.swift
//  ReerRouter
//
//  Created by YuYue on 2022/7/26.
//

import Foundation
import ReerRouter
import UIKit

/*
#route(key: "", action: {
    
})
 
@Routable(.chat)
@objc(AAChatViewController)
class ChatViewController: NSObject {
    func test() {
        
    }
}

@Routable("setting")
class SettingViewController: NSObject {
    func test() {
        
    }
}
 
#routeHost("example.com")
 
 or
 
extension Router: @retroactive RouterConfigable {
    public static var host: String {
        return "example.com"
    }
 
    public static var registrationMode: RegistrationMode {
        return .lazy
    }
}

*/

// 注册名为 abc_action 的 action
#route(key: "abc_action", action: { _ in
    print("macro action executed.")
})

final class RouteManager {
    static let `default` = RouteManager()
    private init() {}
    
    var rootNavigationController: UINavigationController?
    
    func config() {
        
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
        
        Router.shared.delegate = self
        Router.shared.preferredOpenStyle = .push
        // `AppRouter` means `Router.shared`
        AppRouter.allowedSchemes = ["myapp"]

//        AppRouter.host = "phoenix.com"
        
        // 注册页面
        
        // 1. 控制器名字注册
        Router.shared.registerPageClasses(with: ["preference": "ReerRouterDemo.PreferenceViewController"])
        
        // 2. 控制器类型注册
//        Router.shared.register(NewPreferenceViewController.self, forKey: "new_preference")
        Router.shared.register(TransitionExampleViewController.self, forKey: "transition_example")
        
        // 3. key 为 Route.Key 的静态常量
        Router.shared.register(UserViewController.self, forKey: .userPage)
        
        
        
        // 注册名为 abc_action 的 action
//        Router.shared.registerAction(with: "abc_action") { _ in
//            print("action executed.")
//        }
        
        // 注册与 page 同名的action, 将在debug下断言
//        Router.shared.registerAction(with: "preference") { params in
//
//        }
        
        // 执行action
        Router.shared.executeAction(byKey: "abc_action")
        Router.shared.open(URL(string: "myapp://abc_action?id=21312")!)
        Router.shared.open("myapp://abc_action?id=123123")
        
        
        // 注册名为 alert 的 action
        Router.shared.registerAction(with: "alert") { params in
            guard let title = params.queryParams["title"] else { return }
            let message = params.queryParams["message"]
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            Router.shared.present(viewController: alertController)
        }
    }
    
    func isUserLoggedIn() -> Bool {
        return false
    }
}

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
    
    func routeTransition(
        with router: Router,
        param: Route.Param,
        fromNavigationController: UINavigationController?,
        fromViewController: UIViewController?,
        toViewController: UIViewController
    ) -> Bool {
        print("route delegate transition of \(param.sourceURL)")
        toViewController.modalPresentationStyle = .fullScreen
        fromViewController?.present(toViewController, animated: false)
        return true
    }
}
