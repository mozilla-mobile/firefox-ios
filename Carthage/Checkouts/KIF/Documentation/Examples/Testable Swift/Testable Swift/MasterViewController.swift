//
//  MasterViewController.swift
//  Testable Swift
//
//  Created by Jim Puls on 10/29/14.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

import UIKit

class MasterViewController: UITableViewController {
    
    let cellReuseIdentifier: String = "KIFCellReuseIdentifier"
    let numberOfSections = 1
    let numberOfRowsInSection1 = 3
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfSections
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRowsInSection1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Colors"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        

        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellReuseIdentifier)
        }
        
        cell?.isAccessibilityElement = true
        
        switch indexPath.row {
        case 0:
            cell?.textLabel?.text = "Red Color"
            cell?.textLabel?.textColor = UIColor.red
            cell?.accessibilityIdentifier = "Red Cell Identifier"
            cell?.accessibilityLabel = "Red Cell Label"
        case 1:
            cell?.textLabel?.text = "Green Color"
            cell?.textLabel?.textColor = UIColor.green
            cell?.accessibilityIdentifier = "Green Cell Identifier"
            cell?.accessibilityLabel = "Green Cell Label"
        case 2:
            cell?.textLabel?.text = "Blue Color"
            cell?.textLabel?.textColor = UIColor.blue
            cell?.accessibilityIdentifier = "Blue Cell Identifier"
            cell?.accessibilityLabel = "Blue Cell Label"
        default:
            print("Unknown Row \(indexPath.row)")
        }

        return cell!

    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let cell = tableView.cellForRow(at: indexPath) else {
            print("Cell at \(indexPath) not found")
            return
        }
        
        print("Tapped Cell \(cell.textLabel?.text) with AccessibilityLabel \(cell.accessibilityLabel) and AccessibilityIdentifier \(cell.accessibilityIdentifier)")

        if let text = cell.textLabel?.text {
            navigationItem.title = "Selected: " + text
        }
    }
    
    override func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}
