// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit
import ComponentLibrary

struct SummaryViewModel {
    let title: String?
    let titleA11yId: String
    let compactTitleA11yId: String

    let brandViewModel: BrandViewConfiguration

    let summary: NSAttributedString?
    let summaryA11yId: String
    let scrollContentBottomInset: CGFloat
}

final class SummaryView: UIView, UITableViewDataSource, UITableViewDelegate, ThemeApplicable {
    private struct UX {
        static let tableViewHorizontalPadding: CGFloat = 16.0
        static let titleVisbilityThreshold: CGFloat = 30.0
        static let titleVisibilityAnimationDuration: CGFloat = 0.1
    }
    private enum Section: Int, CaseIterable {
        case title, brand, summary
    }
    private let tableView: UITableView = .build {
        $0.backgroundColor = .clear
        $0.separatorStyle = .none
        $0.allowsSelection = false
        $0.showsVerticalScrollIndicator = false
        $0.alpha = 0.0
    }
    private var theme: Theme?
    private var model: SummaryViewModel?
    /// A closure that is called in response to the tableView scroll.
    /// The paramater provided is true when the title cell is showed.
    var onDidChangeTitleCellVisibility: ((Bool) -> Void)?
    override var alpha: CGFloat {
        get {
            return tableView.alpha
        }
        set {
            tableView.alpha = newValue
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        tableView.dataSource = self
        tableView.delegate = self

        tableView.register(cellType: SummaryTitleCell.self)
        tableView.register(cellType: SummaryBrandCell.self)
        tableView.register(cellType: SummaryTextCell.self)

        addSubviews(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.tableViewHorizontalPadding),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.tableViewHorizontalPadding),
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.row), let model else {
            return UITableViewCell()
        }
        let cell: UITableViewCell
        switch section {
        case .title:
            cell = tableView.dequeueReusableCell(withIdentifier: SummaryTitleCell.cellIdentifier, for: indexPath)
            if let cell = cell as? SummaryTitleCell {
                cell.configure(text: model.title, a11yId: model.titleA11yId)
            }
        case .brand:
            cell = tableView.dequeueReusableCell(withIdentifier: SummaryBrandCell.cellIdentifier, for: indexPath)
            if let cell = cell as? SummaryBrandCell {
                cell.configure(
                    text: model.brandViewModel.brandLabel,
                    textA11yId: model.brandViewModel.brandLabelA11yId,
                    logo: model.brandViewModel.brandImage,
                    logoA11yId: model.brandViewModel.brandImageA11yId
                )
            }
        case .summary:
            cell = tableView.dequeueReusableCell(withIdentifier: SummaryTextCell.cellIdentifier, for: indexPath)
            if let cell = cell as? SummaryTextCell {
                cell.configure(text: model.summary, a11yId: model.summaryA11yId)
            }
        }
        if let cell = cell as? ThemeApplicable, let theme {
            cell.applyTheme(theme: theme)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func configure(model: SummaryViewModel) {
        self.model = model
        tableView.contentInset = UIEdgeInsets(
            top: 0.0,
            left: 0.0,
            bottom: model.scrollContentBottomInset,
            right: 0.0
        )
        tableView.reloadData()
    }

    // MARK: - UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let titleCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) else { return }
        // Determine the threshold for showing/hiding the compact title.
        // The threshold must include both the table view’s top contentInset
        // and its safe area inset, since the contentOffset.y does not start
        // at 0 but instead reflects these insets.
        let topInset = abs(tableView.contentInset.top) + abs(tableView.safeAreaInsets.top)
        let offset = scrollView.contentOffset.y + topInset - titleCell.frame.height
        // hide or show the title cell gradually as the table view scrolls.
        let titleCellAlpha = abs(offset / (titleCell.frame.height))

        let isShowingTitleCell = offset < -UX.titleVisbilityThreshold
        UIView.animate(withDuration: UX.titleVisibilityAnimationDuration) {
            titleCell.alpha = titleCellAlpha
            self.onDidChangeTitleCellVisibility?(isShowingTitleCell)
        }
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        self.theme = theme
    }
}
