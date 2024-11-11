// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common
import Shared

class BlockedTrackersTableView: UITableView,
                                UITableViewDelegate {
    private struct UX {
        static let estimatedRowHeight: CGFloat = 44
        static let headerPreferredHeight: CGFloat = 24
    }
    var diffableDataSource: UITableViewDiffableDataSource<Int, BlockedTrackerItem>?

    init() {
        super.init(frame: .zero, style: .insetGrouped)
        setupTableView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupTableView() {
        translatesAutoresizingMaskIntoConstraints = false
        showsHorizontalScrollIndicator = false
        backgroundColor = .clear
        layer.cornerRadius = TPMenuUX.UX.viewCornerRadius
        allowsSelection = false
        separatorColor = .clear
        separatorStyle = .singleLine
        isScrollEnabled = false
        showsVerticalScrollIndicator = false
        rowHeight = UITableView.automaticDimension
        accessibilityIdentifier = AccessibilityIdentifiers.EnhancedTrackingProtection.BlockedTrackers.containerView
        estimatedRowHeight = UX.estimatedRowHeight
        estimatedSectionHeaderHeight = UX.headerPreferredHeight
        register(BlockedTrackerCell.self,
                 forCellReuseIdentifier: BlockedTrackerCell.cellIdentifier)
        register(BlockedTrackersHeaderView.self,
                 forHeaderFooterViewReuseIdentifier: BlockedTrackersHeaderView.cellIdentifier)
    }

    func applySnapshot(with items: [BlockedTrackerItem]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, BlockedTrackerItem>()
        snapshot.appendSections([0])
        snapshot.appendItems(items, toSection: 0)
        diffableDataSource?.apply(snapshot, animatingDifferences: false)
    }

    // MARK: Themable
    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer1
        layer.borderColor = theme.colors.borderPrimary.cgColor
    }
}
