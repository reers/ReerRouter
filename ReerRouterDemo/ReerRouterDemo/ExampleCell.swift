//
//  ExampleCell.swift
//  ReerRouter
//
//  Created by YuYue on 2022/7/25.
//

import UIKit

final class ExampleCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

