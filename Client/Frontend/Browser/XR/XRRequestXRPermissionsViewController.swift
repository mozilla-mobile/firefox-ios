//
//  RequestXRPermissionsViewController.swift
//  XRViewer
//
//  Created by Anthony Morales on 4/16/19.
//  Copyright © 2019 Mozilla. All rights reserved.
//

import UIKit

class RequestXRPermissionsViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var stackViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        cancelButton.layer.borderWidth = 0.5
        cancelButton.layer.borderColor = UIColor.lightGray.cgColor
        confirmButton.layer.borderWidth = 0.5
        confirmButton.layer.borderColor = UIColor.lightGray.cgColor
    }
}
