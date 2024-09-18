//
//  NewPreferenceViewController.swift
//  ReerRouter
//
//  Created by YuYue on 2022/7/27.
//

import UIKit
import ReerRouter

@Routable("new_preference")
class NewPreferenceViewController: UIViewController {

    required init?(param: Route.Param) {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .brown
        view.addSubview(nameLabel)
        nameLabel.frame = view.bounds
    }
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.text = "This is NewPreferenceViewController"
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
