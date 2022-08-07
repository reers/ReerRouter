//
//  PreferenceViewController.swift
//  ReerRouter
//
//  Created by YuYue on 2022/7/27.
//

import UIKit
import ReerRouter

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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .lightGray
        view.addSubview(nameLabel)
        nameLabel.frame = view.bounds
    }
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.text = "This is PreferenceViewController"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 25)
        return label
    }()
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
