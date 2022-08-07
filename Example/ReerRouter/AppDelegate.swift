//
//  AppDelegate.swift
//  ReerRouter
//
//  Created by YuYue on 2022/7/24.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.makeKeyAndVisible()
        let ExampleListViewController = ExampleListViewController()
        let nav = UINavigationController(rootViewController: ExampleListViewController)
        window.rootViewController = nav

        self.window = window
        
        RouteManager.default.rootNavigationController = nav
        RouteManager.default.config()
        return true
    }

}

