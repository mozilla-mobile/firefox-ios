// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

struct SummaryViewModel {
    let title: String?
    let titleA11yId: String
    let brandLabel: String
    let brandLabelA11yId: String
    let summary: NSAttributedString
    let summaryA11yId: String
    let scrollContentBottomInset: CGFloat
}

final class SummaryView: UIView, UITableViewDataSource, UITableViewDelegate, ThemeApplicable {
    private enum UX {
        static let titleVisibilityThreshold: CGFloat = 0.1
    }
    private enum Section: Int, CaseIterable {
        case title, answer
    }

    private let tableView: UITableView = .build {
        $0.backgroundColor = .clear
        $0.separatorStyle = .none
        $0.allowsSelection = false
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = false
        $0.clipsToBounds = false
    }
    private var theme: Theme?
    private var model: SummaryViewModel?

    var scrollView: UIScrollView { tableView }

    /// Called on every scroll with whether the title is still visible.
    var onTitleVisibilityChange: ((Bool) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupSubviews() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(cellType: SummaryTitleCell.self)
        tableView.register(cellType: SummaryAnswerCell.self)
        addSubview(tableView)
        tableView.pinToSuperview()
    }

    // MARK: - Configuration
    func configure(model: SummaryViewModel) {
        self.model = model
        if tableView.contentInset.bottom != model.scrollContentBottomInset {
            tableView.contentInset.bottom = model.scrollContentBottomInset
        }
        tableView.reloadData()
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
        case .answer:
            cell = tableView.dequeueReusableCell(withIdentifier: SummaryAnswerCell.cellIdentifier, for: indexPath)
            if let cell = cell as? SummaryAnswerCell {
                cell.configure(
                    header: model.brandLabel,
                    body: model.summary,
                    headerA11yId: model.brandLabelA11yId,
                    bodyA11yId: model.summaryA11yId
                )
            }
        }
        if let cell = cell as? ThemeApplicable, let theme {
            cell.applyTheme(theme: theme)
        }
        return cell
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    // MARK: - UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let titleCell = tableView.cellForRow(at: IndexPath(row: Section.title.rawValue, section: 0)),
              titleCell.frame.height > 0.0 else { return }
        let scrolledDistance = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        let coveredFraction = min(max((scrolledDistance - titleCell.frame.minY) / titleCell.frame.height, 0.0), 1.0)
        let visibleFraction = 1.0 - coveredFraction
        titleCell.alpha = visibleFraction
        onTitleVisibilityChange?(visibleFraction > UX.titleVisibilityThreshold)
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        self.theme = theme
    }
}
