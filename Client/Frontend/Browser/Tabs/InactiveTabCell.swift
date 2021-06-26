/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import UIKit

//class InactiveTabCell: UICollectionViewCell, UITableViewDataSource, UITableViewDelegate {
//    var inactiveTabsViewModel: InactiveViewModel?
//    static let Identifier = "InactiveTabCellIdentifier"
//    let InactiveTabsTableIdentifier = "InactiveTabsTableIdentifier"
//
//    var tableView = UITableView()
//    let cellIdentifier: String = "tableCell"
//    override init(frame: CGRect) {
////        super.init(frame: frame)
////        super.init(frame: .zero)
//        super.init(frame: CGRect(width: 150, height: 150))
//        tableView.frame = CGRect(width: 150, height: 150)
//        addSubviews(tableView)
//
//
//    }
//
//    init() {
//        super.init(frame: CGRect(width: 150, height: 150))
//        tableView.frame = CGRect(width: 150, height: 150)
//        addSubviews(tableView)
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        backgroundColor = .white
//        tableView.delegate = self
//        tableView.dataSource = self
//        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
//    }
//
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return 1
//    }
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return 4
//    }
//
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        return UIView()
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//
//        let cell: UITableViewCell = UITableViewCell(style: UITableViewCell.CellStyle.value1, reuseIdentifier: cellIdentifier)
//
//        cell.textLabel?.text = "1 CUP"
//        cell.detailTextLabel?.text = "Whole"
//
//        return cell
//    }
//
//    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 40
//    }
//}



class InactiveTabCell: UICollectionViewCell, Themeable, UITableViewDataSource, UITableViewDelegate {
    var inactiveTabsViewModel: InactiveViewModel?
    static let Identifier = "InactiveTabCellIdentifier"
    let InactiveTabsTableIdentifier = "InactiveTabsTableIdentifier"

    // Views
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.tableFooterView = UIView()
        tableView.register(OneLineTableViewCell.self, forCellReuseIdentifier: InactiveTabsTableIdentifier)
        tableView.allowsMultipleSelectionDuringEditing = true
        return tableView
    }()

    convenience init(viewModel: InactiveViewModel) {
        self.init()
        inactiveTabsViewModel = viewModel
//        addSubviews(tableView)
//        setupConstraints()
//        applyTheme()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        tableView.dataSource = self
        tableView.delegate = self
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
//        super.init(frame: .zero)
//        super.init(frame: CGRect(width: 150, height: 150))
//        tableView.frame = CGRect(width: 150, height: 150)
        addSubviews(tableView)
        addSubviews(tableView)
        setupConstraints()
        applyTheme()

    }
//    init() {
//        super.init(frame: .zero)
//        addSubviews(tableView)
//        setupConstraints()
//        applyTheme()
//    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
//        tableView.frame = self.frame
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
//        NSLayoutConstraint.activate([
//            tableView.topAnchor.constraint(equalTo: self.topAnchor),
//            tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
//            tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
//            tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
////            tableView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
//        ])
//
        self.bringSubviewToFront(tableView)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        inactiveTabsViewModel?.inactiveTabs.count ?? 0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: InactiveTabsTableIdentifier, for: indexPath) as! OneLineTableViewCell

        guard let tab = inactiveTabsViewModel?.inactiveTabs[indexPath.item] else {
            return cell
        }
        cell.backgroundColor = .clear

        cell.accessoryView = nil
        cell.titleLabel.text = tab.displayTitle
        cell.leftImageView.setImageAndBackground(forIcon: tab.displayFavicon, website: getTabDomainUrl(tab: tab)) {}
        cell.accessoryType = .none
        cell.editingAccessoryType = .disclosureIndicator
        return cell
    }

    func getTabDomainUrl(tab: Tab) -> URL? {
        guard tab.url != nil else {
            return tab.sessionData?.urls.last?.domainURL
        }
        return tab.url?.domainURL
    }

    func applyTheme() {
        self.backgroundColor = .clear
    }
}
