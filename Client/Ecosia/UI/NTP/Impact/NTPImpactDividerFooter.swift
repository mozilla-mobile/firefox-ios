// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

final class NTPImpactDividerFooter: UICollectionReusableView, ReusableCell, Themeable {
    struct UX {
        static let dividerHeight: CGFloat = 1
        static let dividerTop: CGFloat = 20
        static let dividerBottom: CGFloat = 32
        static let dividerInset: CGFloat = 16
        static let estimatedHeight = dividerHeight + dividerTop + dividerBottom
    }
    
    private lazy var dividerView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Themeable Properties
    
    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Init

    required init?(coder: NSCoder) { nil }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(dividerView)

        NSLayoutConstraint.activate([
            dividerView.heightAnchor.constraint(equalToConstant: 1),
            dividerView.topAnchor.constraint(equalTo: topAnchor, constant: UX.dividerTop),
            dividerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.dividerInset),
            dividerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.dividerInset),
            dividerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.dividerBottom)
        ])
        
        applyTheme()
        
        listenForThemeChange(self)
    }

    @objc func applyTheme() {
        dividerView.backgroundColor = .legacyTheme.ecosia.border
    }
}
