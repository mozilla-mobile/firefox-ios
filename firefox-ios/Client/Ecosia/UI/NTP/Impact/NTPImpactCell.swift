// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class NTPImpactCell: UICollectionViewCell, ThemeApplicable, ReusableCell {
    struct UX {
        static let cellsSpacing: CGFloat = 12
    }

    private(set) weak var delegate: NTPImpactCellDelegate? {
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

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupConstraints()
    }

    private func setup() {
        contentView.addSubview(containerStack)
        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UX.cellsSpacing)
        ])
    }

    func applyTheme(theme: Theme) {
        containerStack.arrangedSubviews.forEach { view in
            (view as? Themeable)?.applyTheme()
            (view as? ThemeApplicable)?.applyTheme(theme: theme)
        }
    }

    func configure(items: [ClimateImpactInfo], delegate: NTPImpactCellDelegate?, theme: Theme) {
        self.delegate = delegate
        containerStack.removeAllArrangedViews() // Remove existing view upon reuse

        for (index, info) in items.enumerated() {
            let row = NTPImpactRowView(info: info)
            row.position = (index, items.count)
            row.delegate = delegate
            containerStack.addArrangedSubview(row)
        }
        applyTheme(theme: theme)
    }

    func refresh(items: [ClimateImpactInfo]) {
        impactRows.forEach { row in
            let matchingInfo = items.first { $0.rawValue == row.info.rawValue }
            guard let info = matchingInfo else { return }
            row.info = info
        }
    }
}
