// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import ComponentLibrary

public final class MenuRedesignMainView: UIView,
                                 ThemeApplicable {
    private struct UX {
        static let headerTopMargin: CGFloat = 15
    }

    // MARK: - UI Elements
    private var collectionView: MenuCollectionView = .build()
    private var tableView: MenuRedesignTableView = .build()

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup
    private func setupView() {
        self.addSubview(collectionView)
        self.addSubview(tableView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: self.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: collectionView.bottomAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }

    public func setupAccessibilityIdentifiers(menuA11yId: String, menuA11yLabel: String) {
        collectionView.setupAccessibilityIdentifiers(menuA11yId: menuA11yId, menuA11yLabel: menuA11yLabel)
        tableView.setupAccessibilityIdentifiers(menuA11yId: menuA11yId, menuA11yLabel: menuA11yLabel)
    }

    // MARK: - Interface
    public func reloadDataView(with data: [MenuSection]) {
        collectionView.reloadCollectionView(with: data)
        tableView.reloadTableView(with: data)
    }

    // MARK: - ThemeApplicable
    public func applyTheme(theme: Theme) {
        backgroundColor = .clear
        collectionView.applyTheme(theme: theme)
        tableView.applyTheme(theme: theme)
    }
}
