// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class EmptyReadingListView: UIView, Themeable {
    
    struct ReadingListPanelUX {
        static let WelcomeScreenPadding: CGFloat = 24
        static let WelcomeScreenHorizontalMinPadding: CGFloat = 40
        
        static let WelcomeScreenMaxWidth: CGFloat = 400
        static let WelcomeScreenItemImageWidth: CGFloat = 20
        
        static let WelcomeScreenTopPadding: CGFloat = 120
    }
    
    // MARK: - Themeable Properties
    
    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default
    
    // MARK: - Properties
    
    var welcomeLabel: UILabel = .build { label in
        label.text = .ReaderPanelWelcome
        label.textAlignment = .center
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body, size: 16, weight: .semibold)
        label.adjustsFontSizeToFitWidth = true
    }
    var readerModeLabel: UILabel = .build { label in
        label.text = .ReaderPanelReadingModeDescription
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body, size: 16, weight: .light)
        label.numberOfLines = 0
    }
    var readerModeImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "ReaderModeCircle")?.withRenderingMode(.alwaysTemplate)
    }
    var readingListLabel: UILabel = .build { label in
        label.text = .ReaderPanelReadingListDescription
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body, size: 16, weight: .light)
        label.numberOfLines = 0
    }
    var readingListImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "AddToReadingListCircle")?.withRenderingMode(.alwaysTemplate)
    }
    
    // MARK: - Init
    
    required init?(coder: NSCoder) {
        assertionFailure("This view is only supposed to be instantiated programmatically")
        return nil
    }
    
    init() {
        super.init(frame: .zero)
        setup()
        applyTheme()
    }
    
    // MARK: - Setup
    
    private func setup() {
                
        translatesAutoresizingMaskIntoConstraints = false
        
        let emptyStateViewWrapper: UIView = .build { view in
            view.addSubviews(self.welcomeLabel,
                             self.readerModeLabel,
                             self.readerModeImageView,
                             self.readingListLabel,
                             self.readingListImageView)
        }
        
        addSubview(emptyStateViewWrapper)
        
        NSLayoutConstraint.activate([
            // title
            welcomeLabel.topAnchor.constraint(equalTo: emptyStateViewWrapper.topAnchor),
            welcomeLabel.leadingAnchor.constraint(equalTo: emptyStateViewWrapper.leadingAnchor),
            welcomeLabel.trailingAnchor.constraint(equalTo: emptyStateViewWrapper.trailingAnchor),
            
            // first row
            readerModeLabel.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: ReadingListPanelUX.WelcomeScreenPadding),
            readerModeImageView.leadingAnchor.constraint(equalTo: welcomeLabel.leadingAnchor),
            readerModeImageView.trailingAnchor.constraint(equalTo: readerModeLabel.leadingAnchor, constant: -ReadingListPanelUX.WelcomeScreenPadding),
            
            readerModeImageView.centerYAnchor.constraint(equalTo: readerModeLabel.centerYAnchor),
            readerModeLabel.trailingAnchor.constraint(equalTo: welcomeLabel.trailingAnchor),
            readerModeImageView.widthAnchor.constraint(equalToConstant: ReadingListPanelUX.WelcomeScreenItemImageWidth),
            
            // second row
            readingListLabel.topAnchor.constraint(equalTo: readerModeLabel.bottomAnchor, constant: ReadingListPanelUX.WelcomeScreenPadding),
            readingListImageView.leadingAnchor.constraint(equalTo: welcomeLabel.leadingAnchor),
            readingListImageView.trailingAnchor.constraint(equalTo: readingListLabel.leadingAnchor, constant: -ReadingListPanelUX.WelcomeScreenPadding),
            
            readingListImageView.centerYAnchor.constraint(equalTo: readingListLabel.centerYAnchor),
            readingListLabel.trailingAnchor.constraint(equalTo: welcomeLabel.trailingAnchor),
            readingListImageView.widthAnchor.constraint(equalToConstant: ReadingListPanelUX.WelcomeScreenItemImageWidth),
            
            readingListLabel.bottomAnchor.constraint(equalTo: emptyStateViewWrapper.bottomAnchor).priority(.defaultLow),
            
            // overall positioning of emptyStateViewWrapper
            emptyStateViewWrapper.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: ReadingListPanelUX.WelcomeScreenHorizontalMinPadding),
            emptyStateViewWrapper.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -ReadingListPanelUX.WelcomeScreenHorizontalMinPadding),
            emptyStateViewWrapper.widthAnchor.constraint(lessThanOrEqualToConstant: ReadingListPanelUX.WelcomeScreenMaxWidth),
            
            emptyStateViewWrapper.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyStateViewWrapper.topAnchor.constraint(equalTo: topAnchor, constant: ReadingListPanelUX.WelcomeScreenTopPadding),
            emptyStateViewWrapper.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        welcomeLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        readerModeLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        readingListLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
        listenForThemeChange(self)
    }
    
    // MARK: - Themeable
    
    func applyTheme() {
        welcomeLabel.textColor = themeManager.currentTheme.colors.textPrimary
        readerModeLabel.textColor = themeManager.currentTheme.colors.textSecondary
        readerModeImageView.tintColor = themeManager.currentTheme.colors.textSecondary
        readingListLabel.textColor = themeManager.currentTheme.colors.textSecondary
        readingListImageView.tintColor = themeManager.currentTheme.colors.textSecondary
    }
}
