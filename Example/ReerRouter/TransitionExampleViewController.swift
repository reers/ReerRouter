//
//  TransitionExampleViewController.swift
//  ReerRouter
//
//  Created by YuYue on 2022/7/28.
//

import UIKit
import ReerRouter

class TransitionExampleViewController: UIViewController, Routable {
    
    let name: String
    
    init(name: String) {
        self.name = name
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func make(with param: Route.Param) -> TransitionExampleViewController? {
        guard let name = param.queryParams["name"] else { return nil }
        return .init(name: name)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Custom transition"
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        
        view.addSubview(nameLabel)
        nameLabel.frame = .init(x: 0, y: 100, width: view.bounds.size.width, height: 50)
        
        view.addSubview(closeButton)
        closeButton.frame = .init(x: 0, y: 0, width: 100, height: 100)
        closeButton.center = view.center
    }
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.text = name
        label.textAlignment = .center
        label.textColor = .red
        label.font = .boldSystemFont(ofSize: 30)
        return label
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .orange
        button.setTitle("close", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 25)
        button.layer.cornerRadius = 50
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(close), for: .touchUpInside)
        return button
    }()
    
    @objc
    func close() {
        self.dismiss(animated: true)
    }

}
