//
//  ExampleListViewController.swift
//  ReerRouter
//
//  Created by YuYue on 2022/7/25.
//

import UIKit
import ReerRouter

class ExampleListViewController: UIViewController {
    
    // MARK: Properties
    let animator = Animator()
    
    let users = [
        Example(name: "phoenix", urlString: "myapp://user?name=phoenix&id=121231&gender=male&age=18"),
        Example(name: "apple", urlString: "present .user"),
        Example(name: "google", urlString: "myapp://user?name=google"),
        Example(name: "intercept by delegate", urlString: "myapp://user?name=bytedance"),
        Example(name: "facebook", urlString: "myapp://user?name=facebook"),
        Example(name: "alert", urlString: "myapp://alert?title=Hello&message=World"),
        Example(name: "not allowed scheme", urlString: "notAllowedScheme://user"),
        Example(name: "fallback", urlString: "myapp://unregisteredKey?route_fallback_url=myapp%3A%2F%2Fuser%3Fname%3Di_am_fallback"),
        Example(name: "preference", urlString: "myapp://preference"),
        Example(name: "redirect", urlString: "myapp://preference?some_key=redirect"),
        Example(name: "custom transition by router", urlString: "myapp://transition_example?name=transition_by_router"),
        Example(name: "custom transition user", urlString: "myapp://transition_example?name=transition_by_user"),
        Example(name: "custom transition delegate", urlString: "myapp://transition_example?name=transition_by_delegate"),
    ]
    
    
    // MARK: UI Properties
    
    let tableView = UITableView()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        self.title = "Examples"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.tableView)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(ExampleCell.self, forCellReuseIdentifier: "user")
    }
    
    
    // MARK: Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.frame = self.view.bounds
    }
    
}


// MARK: - UITableViewDataSource

extension ExampleListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "user", for: indexPath) as! ExampleCell
        let user = self.users[indexPath.row]
        cell.textLabel?.text = user.name
        cell.detailTextLabel?.text = user.urlString
        cell.detailTextLabel?.textColor = .gray
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}


// MARK: - UITableViewDelegate

extension ExampleListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath : IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let user = self.users[indexPath.row]
        if indexPath.row == 0 {
            Router.shared.push(user.urlString, userInfo: [
                "userInfo1": "abcd",
                "userInfo2": "dkjk"
            ])
        }
        else if indexPath.row == 1 {
            Router.shared.present(byKey: .userPage, embedIn: UINavigationController.self, userInfo: [
                "name": "apple",
                "id": "123123"
            ])
        }
        else if indexPath.row == 2 {
            AppRouter.present(user.urlString, presentationStyle: .formSheet)
        }
        else if let _ = user.urlString.range(of: "transition_by_router") {
            if let targetViewController = AppRouter.viewController(for: user.urlString) {
                targetViewController.transitioningDelegate = animator
                targetViewController.modalPresentationStyle = .currentContext
                AppRouter.present(viewController: targetViewController)
            }
        }
        else if let _ = user.urlString.range(of: "transition_by_user") {
            let transition: Route.UserTransition = { fromNavigationController, fromViewController, toViewController in
                toViewController.transitioningDelegate = self.animator
                toViewController.modalPresentationStyle = .currentContext
                // Use the router found view controller directly, or just handle transition by yourself.
                // fromViewController?.present(toViewController, animated: true)
                self.present(toViewController, animated: true)
                return true
            }
            AppRouter.present(user.urlString, transitionExecutor: .user(transition))
        }
        else if let _ = user.urlString.range(of: "transition_by_delegate") {
            AppRouter.present(user.urlString, transitionExecutor: .delegate)
        }
        else {
            Router.shared.open(user.urlString)
        }
    }
}

