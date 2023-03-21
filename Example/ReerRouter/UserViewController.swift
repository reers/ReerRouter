//
//  UserViewController.swift
//  ReerRouter
//
//  Created by YuYue on 2022/7/25.
//

import UIKit
import ReerRouter

extension Route.Key {
    static let userPage: Self = "user"
}

final class UserViewController: UIViewController, Routable {
    
    var params: [String: Any]
    
    init?(param: Route.Param) {
        self.params = param.allParams
        super.init(nibName: nil, bundle: nil)
    }

    var preferredOpenStyle: Route.OpenStyle? {
        return .present(.pageSheet)
    }
    
    // MARK: UI
    
    let tableView = UITableView()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.tableView)
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        self.title = params["name"] as? String
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.navigationController?.viewControllers.count ?? 0 > 1 { // pushed
            self.navigationItem.leftBarButtonItem = nil
        } else if self.presentingViewController != nil { // presented
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: "Close",
                style: .done,
                target: self,
                action: #selector(doneButtonDidTap)
            )
        }
    }
    
    
    // MARK: Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.frame = self.view.bounds
    }
    
    
    // MARK: Actions
    
    @objc func doneButtonDidTap() {
        self.dismiss(animated: true, completion: nil)
    }
}


// MARK: - UITableViewDataSource

extension UserViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return params.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let dict = params[params.index(params.startIndex, offsetBy: indexPath.row)]

        cell.textLabel?.text = dict.key + ": " + (dict.value as? String ?? "")
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}


// MARK: - UITableViewDelegate

extension UserViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        Router.shared.present(byKey: .userPage, embedIn: UINavigationController.self, userInfo: [
            "name": "apple",
            "id": "123123"
        ])
    }
}
