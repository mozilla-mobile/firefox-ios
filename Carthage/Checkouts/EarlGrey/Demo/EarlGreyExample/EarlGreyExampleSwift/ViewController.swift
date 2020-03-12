//
// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

  var tableItems = (1...50).map { $0 }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Create the send message view to contain one of the two send buttons
    let sendMessageView = SendMessageView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
    sendMessageView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(sendMessageView)

    // Create buttons
    let clickMe = createButton("ClickMe")
    view.addSubview(clickMe)
    let send = createButton("Send")
    // Change label to identify this button more easily for the layout test
    send.accessibilityLabel = "SendForLayoutTest"
    view.addSubview(send)
    let send2 = createButton("Send")
    sendMessageView.addSubview(send2)

    // Create a UITableView to send some elements out of the screen
    let table = createTable()
    view.addSubview(table)

    // Create constraints
    let views = ["clickMe": clickMe, "send": send, "send2": send2, "table": table,
                 "sendMessageView": sendMessageView]
    let metrics = ["smallMargin": 10, "mediumMargin": 20, "largeMargin": 40, "buttonSize": 100,
                   "tableSize": 320]
    var allConstraints = [NSLayoutConstraint]()
    let verticalConstraints = NSLayoutConstraint.constraints(
      withVisualFormat: "V:|-largeMargin-[clickMe]-largeMargin-[send2]-largeMargin-[table]|",
      options: [],
      metrics: metrics,
      views: views)
    allConstraints += verticalConstraints
    let buttonsHorizontalConstraints = NSLayoutConstraint.constraints(
      withVisualFormat: "|-smallMargin-[clickMe(buttonSize)]-mediumMargin-[send(buttonSize)]",
      options:.alignAllTop,
      metrics: metrics,
      views: views)
    allConstraints += buttonsHorizontalConstraints
    let sendMessageViewConstraints = NSLayoutConstraint.constraints(
      withVisualFormat: "|-smallMargin-[send2(buttonSize)]",
      options:.alignAllTop,
      metrics: metrics,
      views: views)
    allConstraints += sendMessageViewConstraints
    let tableConstraints = NSLayoutConstraint.constraints(
      withVisualFormat: "|-smallMargin-[table(tableSize)]",
      options:.alignAllTop,
      metrics: metrics,
      views: views)
    allConstraints += tableConstraints
    NSLayoutConstraint.activate(allConstraints)
  }

  func createButton(_ title: String) -> UIButton {
    let button = UIButton(type: .system)
    button.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    button.backgroundColor = UIColor.green
    button.setTitle(title, for: UIControlState())
    button.addTarget(self, action: #selector(ViewController.buttonAction(_:)),
        for: .touchUpInside)
    button.accessibilityIdentifier = title
    button.accessibilityLabel = title
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }

  @objc func buttonAction(_ sender: UIButton!) {
    if let id = sender.accessibilityIdentifier {
      print("Button \(id) clicked")
    }
  }

  func createTable() -> UITableView {
    let tableView = UITableView()
    tableView.frame = CGRect(x: 0, y: 0, width: 320, height: 200)
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.estimatedRowHeight = 85.0
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.accessibilityIdentifier = "table"
    return tableView
  }

  func numberOfSections(in tableView:UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return tableItems.count
  }

  func tableView(_ tableView: UITableView,
      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell:UITableViewCell =
        tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
    // For cell 1 to 7, add a date
    var cellID : String
    if ((indexPath as NSIndexPath).row >= 1 && (indexPath as NSIndexPath).row <= 7) {
      cellID = getDateForIndex((indexPath as NSIndexPath).row)
    } else {
      cellID = "Cell\(tableItems[(indexPath as NSIndexPath).row])"
    }
    cell.textLabel?.text = cellID
    cell.accessibilityIdentifier = cellID
    return cell
  }

  func getDateForIndex(_ index: Int) -> String {
    var date = Date()
    var dateDeltaComponents = DateComponents()
    dateDeltaComponents.day = index
    date = (Calendar.current as NSCalendar).date(
        byAdding: dateDeltaComponents, to: date, options: NSCalendar.Options(rawValue: 0))!
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    return formatter.string(from: date)
  }
}

@objc class SendMessageView: UIView {
  // empty sub class of UIView to exercise inRoot
}
