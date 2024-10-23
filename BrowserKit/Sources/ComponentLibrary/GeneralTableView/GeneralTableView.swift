// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common

public protocol ElementData {
}

public protocol SectionData {
    associatedtype E: ElementData

    var elementData: [E] { get set }
}

public protocol GeneralTableViewDelegate: AnyObject {
    associatedtype S: SectionData

    func didSelectRowAt(indexPath: IndexPath, withModel: S.E)
    func scrollViewDidScroll(_ scrollView: UIScrollView, inScrollViewWithTopPadding topPadding: CGFloat)
}

public protocol ConfigurableTableViewCell: UITableViewCell {
    associatedtype E: ElementData

    func configureCellWith(model: E)
    func applyTheme(theme: Theme)
}

public class GeneralTableView<
    S: SectionData,
    Cell: ConfigurableTableViewCell,
    D: GeneralTableViewDelegate
>: UIView,
   UITableViewDelegate,
   UITableViewDataSource,
   ThemeApplicable
where S.E == Cell.E, D.S == S {
    // Static stored properties not supported in generic types :(
    private struct UXType {
        let topPadding: CGFloat = 10
    }
    private let UX = UXType()

    // MARK: - Properties
    public weak var delegate: D?
    private var sectionData: [S]
    private var configureCellWith: ((Cell, S.E) -> Void)?

    private var tableView: UITableView
    private let cellReuseIdentifier = String(describing: Cell.self)

    private var theme: Theme?

    // MARK: - Inits and UI Setup

    override init(frame: CGRect) {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        sectionData = []
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        setupTableView()
        setupUI()
    }

    private func setupUI() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: self.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(
            Cell.self,
            forCellReuseIdentifier: cellReuseIdentifier
        )
    }

    public func reloadTableView(with data: [S]) {
        sectionData = data
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource

    public func numberOfSections(in tableView: UITableView) -> Int {
        return sectionData.count
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? UX.topPadding : UITableView.automaticDimension
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionData[section].elementData.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as! Cell

        cell.configureCellWith(model: sectionData[indexPath.section].elementData[indexPath.row])
        if let theme { cell.applyTheme(theme: theme) }

        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        delegate?.didSelectRowAt(indexPath: indexPath, withModel: sectionData[indexPath.section].elementData[indexPath.row])
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let headerView = UIView()
            headerView.backgroundColor = .clear
            return headerView
        }
        return nil
    }

    // MARK: - UITableViewDelegate

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.scrollViewDidScroll(scrollView, inScrollViewWithTopPadding: UX.topPadding)
    }

    // MARK: - Theme Applicable
    public func applyTheme(theme: Theme) {
        self.theme = theme
        backgroundColor = .clear
        tableView.backgroundColor = .clear
    }
}
