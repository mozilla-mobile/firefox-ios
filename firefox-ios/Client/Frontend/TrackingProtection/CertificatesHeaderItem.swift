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

    var itemSelectedCallback: ((_ selectedCertificateIndex: Int) -> Void)?
    private var theme: Theme?

    private let stackView: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.distribution = .fillProportionally
        stack.spacing = UX.headerItemsSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
    }

    private let button: UIButton = .build { button in
        button.configuration?.titleLineBreakMode = .byCharWrapping
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .center
        button.translatesAutoresizingMaskIntoConstraints = false
    }

    private let indicator: UIView = .build { view in
        view.heightAnchor.constraint(equalToConstant: UX.headerItemIndicatorHeight).isActive = true
        view.translatesAutoresizingMaskIntoConstraints = false
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

    func configure(theme: Theme, tagIndex: Int, title: String?) {
        self.theme = theme
        self.tag = tagIndex
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: #selector(certificateButtonTapped(_:)), for: .touchUpInside)
        indicator.backgroundColor = tagIndex == 0 ? theme.colors.textAccent : .clear
        button.setTitleColor(tagIndex == 0 ? theme.colors.textAccent : theme.colors.textPrimary, for: .normal)
    }

    func hideIndicator() {
        indicator.backgroundColor = .clear
        button.setTitleColor(theme?.colors.textPrimary, for: .normal)
    }

    @objc
    private func certificateButtonTapped(_ sender: UIButton) {
        indicator.backgroundColor = theme?.colors.textAccent
        button.setTitleColor(theme?.colors.textAccent, for: .normal)
        itemSelectedCallback?(self.tag)
    }
}
