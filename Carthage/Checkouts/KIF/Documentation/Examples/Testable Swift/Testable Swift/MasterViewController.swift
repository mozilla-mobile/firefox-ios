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
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        if let text = cell?.textLabel?.text {
            navigationItem.title = "Selected: " + text
        }
    }
}
