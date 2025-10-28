// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class WhatsNewCell: UITableViewCell {

    // MARK: - Properties

    private var item: WhatsNewItem!
    private var contentConfigurationToUpdate: Any?

    // MARK: - Configuration

    func configure(with item: WhatsNewItem) {
        selectionStyle = .none
        backgroundColor = .clear
        self.item = item
        configureBasedOnOSVersion()
    }

    private func configureBasedOnOSVersion() {
        if #available(iOS 14, *) {
            configureForiOS14(item: item)
        } else {
            configureForiOS13(item: item)
        }
    }

    @available(iOS 14, *)
    private func configureForiOS14(item: WhatsNewItem) {
        var newConfiguration = defaultContentConfiguration()
        newConfiguration.text = item.title
        newConfiguration.textProperties.font = .preferredFont(forTextStyle: .headline)
        newConfiguration.textProperties.lineBreakMode = .byTruncatingTail
        newConfiguration.textProperties.adjustsFontForContentSizeCategory = true
        newConfiguration.textProperties.adjustsFontSizeToFitWidth = true
        newConfiguration.secondaryText = item.subtitle
        newConfiguration.secondaryTextProperties.lineBreakMode = .byTruncatingTail
        newConfiguration.secondaryTextProperties.font = .preferredFont(forTextStyle: .subheadline)
        newConfiguration.secondaryTextProperties.adjustsFontForContentSizeCategory = true
        newConfiguration.secondaryTextProperties.adjustsFontSizeToFitWidth = true
        newConfiguration.imageProperties.maximumSize = CGSize(width: 24, height: 24)
        contentConfigurationToUpdate = newConfiguration
    }

    private func configureForiOS13(item: WhatsNewItem) {
        textLabel?.text = item.title
        textLabel?.lineBreakMode = .byTruncatingTail
        textLabel?.font = .preferredFont(forTextStyle: .headline)
        textLabel?.adjustsFontForContentSizeCategory = true
        textLabel?.adjustsFontSizeToFitWidth = true
        detailTextLabel?.text = item.subtitle
        detailTextLabel?.lineBreakMode = .byTruncatingTail
        detailTextLabel?.font = .preferredFont(forTextStyle: .subheadline)
        detailTextLabel?.adjustsFontForContentSizeCategory = true
        detailTextLabel?.adjustsFontSizeToFitWidth = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        if #available(iOS 14, *) {
            var newConfiguration = defaultContentConfiguration()
            newConfiguration.text = nil
            newConfiguration.image = nil
        } else {
            textLabel?.text = nil
            imageView?.image = nil
        }
    }
}

extension WhatsNewCell: ThemeApplicable {

    func applyTheme(theme: Theme) {
        if #available(iOS 14, *) {
            guard var updatedConfiguration = contentConfigurationToUpdate as? UIListContentConfiguration else { return }
            updatedConfiguration.image = item.image?.tinted(withColor: theme.colors.ecosia.iconDecorative)
            contentConfiguration = updatedConfiguration
        } else {
            imageView?.image = item.image?.tinted(withColor: theme.colors.ecosia.iconDecorative)
        }
    }
}

extension WhatsNewCell: ReusableCell {}
