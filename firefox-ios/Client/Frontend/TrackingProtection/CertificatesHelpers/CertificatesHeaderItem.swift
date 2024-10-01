// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class CertificatesHeaderItem: UIView {
    struct UX {
        static let headerItemIndicatorHeight = 4.0
        static let headerItemsSpacing = 10.0
    }

    private var itemSelectedCallback: (() -> Void)?
    private var theme: Theme?

    private let stackView: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.distribution = .fillProportionally
        stack.spacing = UX.headerItemsSpacing
    }

    private let button: UIButton = .build { button in
        button.configuration?.titleLineBreakMode = .byCharWrapping
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .center
    }

    private let indicator: UIView = .build { view in
        view.heightAnchor.constraint(equalToConstant: UX.headerItemIndicatorHeight).isActive = true
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        self.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: self.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        stackView.addArrangedSubview(button)
        stackView.addArrangedSubview(indicator)
    }

    func configure(theme: Theme, title: String?, isSelected: Bool, itemSelectedCallback: @escaping () -> Void) {
        self.theme = theme
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: #selector(certificateButtonTapped(_:)), for: .touchUpInside)
        indicator.backgroundColor = isSelected ? theme.colors.textAccent : .clear
        button.setTitleColor(isSelected ? theme.colors.textAccent : theme.colors.textPrimary, for: .normal)
        indicator.backgroundColor = isSelected ? theme.colors.textAccent : .clear
        self.itemSelectedCallback = itemSelectedCallback
    }

    @objc
    private func certificateButtonTapped(_ sender: UIButton) {
        button.setTitleColor(theme?.colors.textAccent, for: .normal)
        itemSelectedCallback?()
    }
}
