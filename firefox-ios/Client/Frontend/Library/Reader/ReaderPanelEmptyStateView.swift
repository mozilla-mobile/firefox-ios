// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

private struct ReadingListPanelUX {
    // Welcome Screen
    static let WelcomeScreenPadding: CGFloat = 15
    static let WelcomeScreenHorizontalMinPadding: CGFloat = 40

    static let WelcomeScreenMaxWidth: CGFloat = 400
    static let WelcomeScreenItemImageWidth: CGFloat = 20

    static let WelcomeScreenTopPadding: CGFloat = 120
}

final class ReaderPanelEmptyStateView: UIView {
    let windowUUID: WindowUUID
    let themeManager: Common.ThemeManager

    private lazy var welcomeLabel: UILabel = .build { label in
        label.text = .ReaderPanelWelcome
        label.textAlignment = .center
        label.font = FXFontStyles.Bold.body.scaledFont()
        label.numberOfLines = 0
        label.textColor = self.currentTheme().colors.textSecondary
    }

    private lazy var readerModeLabel: UILabel = .build { label in
        label.text = .ReaderPanelReadingModeDescription
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
        label.textColor = self.currentTheme().colors.textSecondary
    }

    private lazy var readerModeImageView: UIImageView = {
        return .build { imageView in
            imageView.contentMode = .scaleAspectFill
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
            imageView.contentMode = .scaleAspectFill
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
        let imageScaledWidth = UIFontMetrics.default.scaledValue(for: ReadingListPanelUX.WelcomeScreenItemImageWidth)
        NSLayoutConstraint.activate(
            [
                // title
                welcomeLabel.topAnchor.constraint(equalTo: emptyStateViewWrapper.topAnchor),
                welcomeLabel.leadingAnchor.constraint(equalTo: emptyStateViewWrapper.leadingAnchor),
                welcomeLabel.trailingAnchor.constraint(equalTo: emptyStateViewWrapper.trailingAnchor),

                // first row
                readerModeLabel.topAnchor.constraint(
                    equalTo: welcomeLabel.bottomAnchor,
                    constant: ReadingListPanelUX.WelcomeScreenPadding
                ),
                readerModeLabel.leadingAnchor.constraint(equalTo: welcomeLabel.leadingAnchor),
                readerModeLabel.trailingAnchor.constraint(
                    equalTo: readerModeImageView.leadingAnchor,
                    constant: -ReadingListPanelUX.WelcomeScreenPadding
                ),

                readerModeImageView.centerYAnchor.constraint(equalTo: readerModeLabel.centerYAnchor),
                readerModeImageView.trailingAnchor.constraint(equalTo: welcomeLabel.trailingAnchor),
                readerModeImageView.widthAnchor.constraint(
                    equalToConstant: imageScaledWidth
                ),

                // second row
                readingListLabel.topAnchor.constraint(
                    equalTo: readerModeLabel.bottomAnchor,
                    constant: ReadingListPanelUX.WelcomeScreenPadding
                ),
                readingListLabel.leadingAnchor.constraint(equalTo: welcomeLabel.leadingAnchor),
                readingListLabel.trailingAnchor.constraint(
                    equalTo: readingListImageView.leadingAnchor,
                    constant: -ReadingListPanelUX.WelcomeScreenPadding
                ),

                readingListImageView.centerYAnchor.constraint(equalTo: readingListLabel.centerYAnchor),
                readingListImageView.trailingAnchor.constraint(equalTo: welcomeLabel.trailingAnchor),
                readingListImageView.widthAnchor.constraint(
                    equalToConstant: imageScaledWidth
                ),

                readingListLabel.bottomAnchor.constraint(
                    equalTo: emptyStateViewWrapper.bottomAnchor
                ).priority(.defaultLow),

                // overall positioning of emptyStateViewWrapper
                emptyStateViewWrapper.leadingAnchor.constraint(
                    greaterThanOrEqualTo: leadingAnchor,
                    constant: ReadingListPanelUX.WelcomeScreenHorizontalMinPadding
                ),
                emptyStateViewWrapper.trailingAnchor.constraint(
                    lessThanOrEqualTo: trailingAnchor,
                    constant: -ReadingListPanelUX.WelcomeScreenHorizontalMinPadding
                ),
                emptyStateViewWrapper.widthAnchor.constraint(
                    lessThanOrEqualToConstant: ReadingListPanelUX.WelcomeScreenMaxWidth
                ),

                emptyStateViewWrapper.centerXAnchor.constraint(equalTo: centerXAnchor),
                emptyStateViewWrapper.topAnchor.constraint(
                    equalTo: topAnchor,
                    constant: ReadingListPanelUX.WelcomeScreenTopPadding
                ),
                emptyStateViewWrapper.bottomAnchor.constraint(equalTo: bottomAnchor)
            ]
        )

        welcomeLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        readerModeLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        readingListLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
    }

    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }
}
