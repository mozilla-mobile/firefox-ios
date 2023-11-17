/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core
import Common

final class NTPImpactCell: UICollectionViewCell, Themeable, ReusableCell {
    struct UX {
        static let cellsSpacing: CGFloat = 12
    }
    
    weak var delegate: NTPImpactCellDelegate? {
        didSet {
            impactRows.forEach { $0.delegate = delegate }
        }
    }
    
    private lazy var containerStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        return stack
    }()
    private var impactRows: [NTPImpactRowView] {
        containerStack.arrangedSubviews.compactMap { $0 as? NTPImpactRowView }
    }
    
    // MARK: - Themeable Properties
    
    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        applyTheme()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
        applyTheme()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupConstraints()
    }

    private func setup() {
        contentView.addSubview(containerStack)
        setupConstraints()
        listenForThemeChange(contentView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UX.cellsSpacing)
        ])
    }

    func applyTheme() {
        containerStack.arrangedSubviews.forEach { view in
            (view as? Themeable)?.applyTheme()
        }
    }
    
    func configure(items: [ClimateImpactInfo]) {
        containerStack.removeAllArrangedViews() // Remove existing view upon reuse
        
        for (index, info) in items.enumerated() {
            let row = NTPImpactRowView(info: info)
            row.position = (index, items.count)
            row.delegate = delegate
            containerStack.addArrangedSubview(row)
        }
    }
    
    func refresh(items: [ClimateImpactInfo]) {
        impactRows.forEach { row in
            let matchingInfo = items.first { $0.rawValue == row.info.rawValue }
            guard let info = matchingInfo else { return }
            row.info = info
        }
    }
}
