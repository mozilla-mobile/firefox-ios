// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

class ReaderPanelEmptyStateView: UIView {
    let windowUUID: WindowUUID
    let themeManager: Common.ThemeManager

    private lazy var welcomeLabel: UILabel = {
        return .build { label in
            label.text = .ReaderPanelWelcome
            label.textAlignment = .center
            label.font = FXFontStyles.Bold.body.scaledFont()
            label.adjustsFontSizeToFitWidth = true
            label.textColor = self.currentTheme().colors.textSecondary
        }
    }()

    private lazy var readerModeLabel: UILabel = {
        return .build { label in
            label.text = .ReaderPanelReadingModeDescription
            label.font = FXFontStyles.Regular.body.scaledFont()
            label.numberOfLines = 0
            label.textColor = self.currentTheme().colors.textSecondary
        }
    }()

    private lazy var readerModeImageView: UIImageView = {
        return .build { imageView in
            imageView.contentMode = .scaleAspectFit
            imageView.image = UIImage(named: StandardImageIdentifiers.Large.readerView)?
                .withRenderingMode(.alwaysTemplate)
            imageView.tintColor = self.currentTheme().colors.textSecondary
        }
    }()

    private lazy var readingListLabel: UILabel = {
        return .build { label in
            label.text = .ReaderPanelReadingListDescription
            label.font = FXFontStyles.Regular.body.scaledFont()
            label.numberOfLines = 0
            label.textColor = self.currentTheme().colors.textSecondary
        }
    }()

    private lazy var readingListImageView: UIImageView = {
        return .build { imageView in
            imageView.contentMode = .scaleAspectFit
            imageView.image = UIImage(named: StandardImageIdentifiers.Large.readingListAdd)?
                .withRenderingMode(.alwaysTemplate)
            imageView.tintColor = self.currentTheme().colors.textSecondary
        }
    }()

    private lazy var emptyStateViewWrapper: UIView = {
        return .build { view in
            view.addSubviews(self.welcomeLabel,
                             self.readerModeLabel,
                             self.readerModeImageView,
                             self.readingListLabel,
                             self.readingListImageView)
        }
    }()

    init(
        windowUUID: WindowUUID,
        frame: CGRect = .zero,
        themeManager: ThemeManager = AppContainer.shared.resolve()
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false

        setupLayout()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        addSubview(emptyStateViewWrapper)
    }

    private func setupConstraints() {
        
    }

    private func currentTheme() -> Theme {
        return themeManager.currentTheme(for: windowUUID)
    }
}
