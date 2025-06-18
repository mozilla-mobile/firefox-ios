// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ToolbarKit

class SearchBarCell: UICollectionViewCell, ReusableCell, ThemeApplicable {
    private lazy var locationContainer: RegularBrowserAddressToolbar = .build()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHostingController()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureHostingController()
    }

    private func configureHostingController() {
        locationContainer.configure(
            config: setupSkelli(),
            toolbarPosition: .top,
            toolbarDelegate: nil,
            leadingSpace: 8,
            trailingSpace: 8,
            isUnifiedSearchEnabled: false,
            animated: false)

        contentView.addSubview(locationContainer)
        NSLayoutConstraint.activate([
            locationContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            locationContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            locationContainer.heightAnchor.constraint(equalToConstant: 54),
        ])
    }

    private func setupSkelli() -> AddressToolbarConfiguration {
        let uxConfiguration: AddressToolbarUXConfiguration = .experiment()

        let leadingPageElements = [ToolbarElement]()
        let trailingPageElements = [ToolbarElement]()

        let locationViewConfiguration = LocationViewConfiguration(
            searchEngineImageViewA11yId: "",
            searchEngineImageViewA11yLabel: "",
            lockIconButtonA11yId: "",
            lockIconButtonA11yLabel: "",
            urlTextFieldPlaceholder: .AddressToolbar.LocationPlaceholder,
            urlTextFieldA11yId: "",
            searchEngineImage: nil,
            lockIconImageName: "",
            lockIconNeedsTheming: false,
            safeListedURLImageName: nil,
            url: nil,
            droppableUrl: nil,
            searchTerm: nil,
            isEditing: false,
            isEnabled: false,
            didStartTyping: false,
            shouldShowKeyboard: false,
            shouldSelectSearchTerm: false,
            onTapLockIcon: { _ in },
            onLongPress: {})

        return AddressToolbarConfiguration(
            locationViewConfiguration: locationViewConfiguration,
            navigationActions: [],
            leadingPageActions: leadingPageElements,
            trailingPageActions: trailingPageElements,
            browserActions: [],
            borderPosition: .top,
            uxConfiguration: uxConfiguration,
            shouldAnimate: false
        )
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        locationContainer.applyTheme(theme: theme)
    }
}
