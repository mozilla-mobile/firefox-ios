// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// Wrapper that uses a real `UIToolbar` in normal app runs and a plain `UIView` in UI tests.
///
/// Context:
/// - On iOS 26, `UIToolbar` no longer exposes its custom views (e.g. a `UISegmentedControl`)
///   through the accessibility tree / `XCUIApplication().debugDescription`.
/// - On iOS 18.2, `debugDescription` showed the segmented control and its buttons:
///
///     Toolbar, identifier: 'Toolbar'
///       ...
///       SegmentedControl, identifier: 'librarySegmentControl'
///         Button, label: 'readingListLarge'
///
///   But on iOS 26 the same toolbar appears only as:
///
///     Toolbar, identifier: 'Toolbar', label: 'Toolbar'
///       ...
///
/// This breaks XCUITest, because tests can no longer find buttons like
/// `readingListLarge` / `LibraryPanel_ReadingList` in the Library panel or tab tray.
///
/// For a detailed description of the issue, see:
///     https://github.com/mozilla-mobile/firefox-ios/issues/29114#issue-3377554646
///
/// Workaround:
/// - In UI tests we wrap a plain `UIView` (`contentView`) and manually host the
///   custom view (segmented control). This restores the visibility of those controls
///   in `debugDescription`, allowing XCUITests to interact with them.
/// - In a real app run, we still use a real `UIToolbar` to preserve
///   appearance and behavior.
///
/// References:
/// - Bug / tracking:
///   - Jira: FXIOS-13394
///   - GitHub: https://github.com/mozilla-mobile/firefox-ios/issues/29114
/// - Apple Developer Forums ticket:
///   - https://developer.apple.com/forums/thread/799300
///
/// When Apple fixes this regression and `UIToolbar` starts exposing its customViews
/// again in the accessibility tree on iOS 26+, this wrapper should be removed.
///
/// TODO(FXIOS-14318): add test that fails if `UIToolbar` starts exposing its customViews again.
final class TestableUIToolbar: UIView {
    private let realToolbar: UIToolbar?
    private let contentView: UIView
    private var storedItems: [UIBarButtonItem]?
    private let fallbackToolbarHeight: CGFloat = 44

    var delegate: UIToolbarDelegate? {
        get { realToolbar?.delegate }
        set { realToolbar?.delegate = newValue }
    }

    var items: [UIBarButtonItem]? {
        get { realToolbar?.items ?? storedItems }
        set { setItems(newValue, animated: false) }
    }

    func setItems(_ items: [UIBarButtonItem]?, animated: Bool) {
        storedItems = items

        if let realToolbar {
            realToolbar.setItems(items, animated: animated)
        } else {
            // UIView fallback: place the first customView in the middle (enough for UITests)
            contentView.subviews.forEach { $0.removeFromSuperview() }
            guard let customView = items?.first?.customView else { return }

            contentView.addSubview(customView)
            customView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                customView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                customView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
            ])
        }
    }

    // swiftlint:disable implicitly_unwrapped_optional
    /// NOTE: UIKit declares `tintColor` as an implicitly-unwrapped optional (`UIColor!`).
    /// To override it, we must use the exact same type signature.
    /// This is why the swiftlint rule is disabled for this block.
    override var tintColor: UIColor! {
        didSet {
            realToolbar?.tintColor = tintColor
            contentView.tintColor = tintColor
        }
    }
    // swiftlint:enable implicitly_unwrapped_optional

    var barTintColor: UIColor? {
        get { realToolbar?.barTintColor }
        set {
            realToolbar?.barTintColor = newValue
            contentView.backgroundColor = newValue
        }
    }

    var isTranslucent: Bool {
        get { realToolbar?.isTranslucent ?? false }
        set { realToolbar?.isTranslucent = newValue }
    }

    init() {
        if AppConstants.isRunningUITests {
            self.realToolbar = nil
            self.contentView = UIView()
        } else {
            // Real UIToolbar in production
            let toolbar = UIToolbar()
            toolbar.translatesAutoresizingMaskIntoConstraints = false
            self.realToolbar = toolbar
            self.contentView = toolbar
        }

        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        if AppConstants.isRunningUITests {
            let heightConstraint = heightAnchor.constraint(equalToConstant: fallbackToolbarHeight)
            heightConstraint.priority = UILayoutPriority(999)
            heightConstraint.isActive = true
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
