// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Common

class ReaderModeStyleViewController: UIViewController, Themeable, Notifiable {
    public struct UX {
        public static let stackViewSpacing: CGFloat = 8
        public static let brightnessSize: CGFloat = 20
        public static let brightnessMaxSize: CGFloat = 35
        public static let sliderVerticalSpacing: CGFloat = 16
        public static let brightnessHorizontalSpacing: CGFloat = 24
        public static let separatorLineThickness: CGFloat = 1.0
        public static let width: CGFloat = 270.0
        public static let brightnessIconOffset: CGFloat = 10
    }

    // UI views
    private var fontTypeButtons: [ReaderModeFontTypeButton] = []
    private var fontSizeButtons: [ReaderModeFontSizeButton] = []
    private var themeButtons: [ReaderModeThemeButton] = []
    private var brightnessImageViews = [UIImageView]()
    private var separatorLines = [UIView.build(), UIView.build(), UIView.build()]

    private lazy var fontTypeStackView: UIStackView = .build { view in
        view.axis = .horizontal
        view.distribution = .fill
        view.spacing = UX.stackViewSpacing
        view.alignment = .center
    }

    private lazy var fontSizeStackView: UIStackView = .build { view in
        view.axis = .horizontal
        view.distribution = .fillEqually
        view.spacing = UX.stackViewSpacing
        view.alignment = .center
    }

    private lazy var themeStackView: UIStackView = .build { view in
        view.axis = .horizontal
        view.distribution = .fillEqually
        view.spacing = 0
        view.alignment = .center
    }

    private lazy var brightnessRow: UIView = .build()

    private lazy var slider: UISlider = .build { slider in
        slider.accessibilityLabel = .ReaderModeStyleBrightnessAccessibilityLabel
        slider.addTarget(self, action: #selector(self.changeBrightness), for: .valueChanged)
    }

    // Constraints
    private var brightnessMinImageHeightConstraint: NSLayoutConstraint?
    private var brightnessMaxImageHeightConstraint: NSLayoutConstraint?

    private var viewModel: ReaderModeStyleViewModel
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    init(viewModel: ReaderModeStyleViewModel,
         windowUUID: WindowUUID,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.viewModel = viewModel
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        self.windowUUID = windowUUID

        super.init(nibName: nil, bundle: nil)

        setupNotifications(forObserver: self, observing: [UIContentSizeCategory.didChangeNotification])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()

        updateFontSizeButtons()
        updateFontTypeButtons()

        listenForThemeChange(view)
        applyTheme()
        adjustLayoutForA11ySizeCategory()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let targetSize = CGSize(width: UX.width, height: UIView.layoutFittingCompressedSize.height)
        preferredContentSize = view.systemLayoutSizeFitting(targetSize)
    }

    // MARK: - Applying Theme
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        popoverPresentationController?.backgroundColor = theme.colors.layer1

        slider.tintColor = theme.colors.actionPrimary

        // Set background color to container views
        [fontTypeStackView, fontSizeStackView, brightnessRow].forEach { view in
            view?.backgroundColor = theme.colors.layer1
        }

        fontSizeButtons.forEach { $0.applyTheme(theme: theme) }
        fontTypeButtons.forEach { $0.applyTheme(theme: theme) }
        themeButtons.forEach { $0.applyTheme(theme: theme) }

        separatorLines.forEach { line in
            line.backgroundColor = theme.colors.borderPrimary
        }

        brightnessImageViews.forEach { view in
            view.tintColor = theme.colors.iconSecondary
        }
    }

    func applyTheme(_ preferences: Prefs, contentScript: TabContentScript) {
        guard let readerPreferences = preferences.dictionaryForKey(PrefsKeys.ReaderModeProfileKeyStyle),
              let readerMode = contentScript as? ReaderMode,
              let style = ReaderModeStyle(windowUUID: windowUUID, dict: readerPreferences) else { return }

        readerMode.style = style
    }

    private func makeSeparatorView(fromView: UIView, topConstraint: UIView) {
        NSLayoutConstraint.activate(
            [
                fromView.topAnchor.constraint(equalTo: topConstraint.bottomAnchor),
                fromView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                fromView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                fromView.heightAnchor.constraint(equalToConstant: CGFloat(UX.separatorLineThickness))
            ]
        )
    }

    /// Setup a row of buttons.
    private func setupButtonsStack(_ buttons: [UIButton], inRow stackView: UIStackView, action: Selector) {
        buttons.forEach { button in
            stackView.addArrangedSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: action, for: .touchUpInside)
            button.setContentHuggingPriority(.required, for: .vertical)
        }
        stackView.setContentHuggingPriority(.required, for: .vertical)
    }

    @objc
    func changeFontType(_ button: ReaderModeFontTypeButton) {
        viewModel.fontTypeDidChange(button.fontType)
        updateFontTypeButtons()
    }

    private func updateFontTypeButtons() {
        let fontType = viewModel.readerModeStyle.fontType

        for button in fontTypeButtons {
            button.isSelected = button.fontType.isSameFamily(fontType)
        }

        for button in fontSizeButtons {
            button.configure(fontType: fontType)
        }

        for button in themeButtons {
            button.configure(fontType: fontType)
        }
    }

    @objc
    func changeFontSize(_ button: ReaderModeFontSizeButton) {
        viewModel.fontSizeDidChangeSizeAction(button.fontSizeAction)
        updateFontSizeButtons()
    }

    private func updateFontSizeButtons() {
        for button in fontSizeButtons {
            switch button.fontSizeAction {
            case .bigger:
                button.isEnabled = !viewModel.readerModeStyle.fontSize.isLargest()
                break
            case .smaller:
                button.isEnabled = !viewModel.readerModeStyle.fontSize.isSmallest()
                break
            case .reset:
                break
            }
        }
    }

    @objc
    func changeTheme(_ button: ReaderModeThemeButton) {
        guard let readerModeTheme = button.readerModeTheme else { return }
        viewModel.readerModeDidChangeTheme(readerModeTheme)
    }

    @objc
    func changeBrightness(_ slider: UISlider) {
        viewModel.sliderDidChange(value: CGFloat(slider.value))
    }

    // MARK: - Private
    private func setupLayout() {
        setupFontTypeRow()
        setupFontSizeRow()
        setupThemeRow()
        setupBrightnessRow()
    }

    private func setupFontTypeRow() {
        view.addSubview(fontTypeStackView)

        NSLayoutConstraint.activate([
            fontTypeStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: viewModel.fontTypeOffset),
            fontTypeStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            fontTypeStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        fontTypeButtons = [
            ReaderModeFontTypeButton(fontType: ReaderModeFontType.sansSerif),
            ReaderModeFontTypeButton(fontType: ReaderModeFontType.serif)
        ]

        setupButtonsStack(fontTypeButtons, inRow: fontTypeStackView, action: #selector(changeFontType))

        view.addSubview(separatorLines[0])
        makeSeparatorView(fromView: separatorLines[0], topConstraint: fontTypeStackView)
    }

    private func setupFontSizeRow() {
        view.addSubview(fontSizeStackView)

        NSLayoutConstraint.activate([
            fontSizeStackView.topAnchor.constraint(equalTo: separatorLines[0].bottomAnchor),
            fontSizeStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            fontSizeStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        fontSizeButtons = [
            ReaderModeFontSizeButton(fontSizeAction: FontSizeAction.smaller),
            ReaderModeFontSizeButton(fontSizeAction: FontSizeAction.reset),
            ReaderModeFontSizeButton(fontSizeAction: FontSizeAction.bigger)
        ]

        setupButtonsStack(fontSizeButtons, inRow: fontSizeStackView, action: #selector(changeFontSize))

        view.addSubview(separatorLines[1])
        makeSeparatorView(fromView: separatorLines[1], topConstraint: fontSizeStackView)
    }

    private func setupThemeRow() {
        view.addSubview(themeStackView)

        NSLayoutConstraint.activate([
            themeStackView.topAnchor.constraint(equalTo: separatorLines[1].bottomAnchor),
            themeStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            themeStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        // These UIButtons represent the ReaderModeTheme (Light/Sepia/Dark)
        // they don't follow the App Theme
        themeButtons = [
            ReaderModeThemeButton(readerModeTheme: ReaderModeTheme.light),
            ReaderModeThemeButton(readerModeTheme: ReaderModeTheme.sepia),
            ReaderModeThemeButton(readerModeTheme: ReaderModeTheme.dark)
        ]

        setupButtonsStack(themeButtons, inRow: themeStackView, action: #selector(changeTheme))

        view.addSubview(separatorLines[2])
        makeSeparatorView(fromView: separatorLines[2], topConstraint: themeStackView)
    }

    private func setupBrightnessRow() {
        view.addSubview(brightnessRow)

        // min image
        let brightnessMinImageView: UIImageView = .build { imageView in
            imageView.image = UIImage(named: StandardImageIdentifiers.Medium.sun)?.withRenderingMode(.alwaysTemplate)
        }
        brightnessMinImageView.accessibilityIdentifier = AccessibilityIdentifiers.ReaderMode.darkerBrightnessButton
        brightnessImageViews.append(brightnessMinImageView)
        brightnessRow.addSubview(brightnessMinImageView)

        brightnessMinImageHeightConstraint = brightnessMinImageView.heightAnchor.constraint(
            equalToConstant: UX.brightnessSize
        )
        brightnessMinImageHeightConstraint?.isActive = true

        // slider
        brightnessRow.addSubview(slider)
        slider.accessibilityIdentifier = AccessibilityIdentifiers.ReaderMode.brightnessSlider

        // max image
        let brightnessMaxImageView: UIImageView = .build { imageView in
            let image = UIImage(named: StandardImageIdentifiers.Medium.sunFill)
            imageView.image = image?.withRenderingMode(.alwaysTemplate)
        }
        brightnessMaxImageView.accessibilityIdentifier = AccessibilityIdentifiers.ReaderMode.lighterBrightnessButton
        brightnessImageViews.append(brightnessMaxImageView)
        brightnessRow.addSubview(brightnessMaxImageView)

        brightnessMaxImageHeightConstraint = brightnessMaxImageView.heightAnchor.constraint(
            equalToConstant: UX.brightnessSize
        )
        brightnessMaxImageHeightConstraint?.isActive = true

        NSLayoutConstraint.activate(
            [
                brightnessRow.topAnchor.constraint(equalTo: separatorLines[2].bottomAnchor),
                brightnessRow.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                brightnessRow.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                brightnessRow.bottomAnchor.constraint(
                    equalTo: view.bottomAnchor,
                    constant: viewModel.brightnessRowOffset
                ),

                brightnessMinImageView.centerYAnchor.constraint(equalTo: slider.centerYAnchor),
                brightnessMinImageView.leadingAnchor.constraint(equalTo: brightnessRow.leadingAnchor,
                                                                constant: UX.brightnessHorizontalSpacing),
                brightnessMinImageView.trailingAnchor.constraint(
                    equalTo: slider.leadingAnchor,
                    constant: -CGFloat(UX.brightnessIconOffset)
                ),
                brightnessMinImageView.widthAnchor.constraint(equalTo: brightnessMinImageView.heightAnchor),

                slider.topAnchor.constraint(equalTo: brightnessRow.topAnchor, constant: UX.sliderVerticalSpacing),
                slider.bottomAnchor.constraint(equalTo: brightnessRow.bottomAnchor,
                                               constant: -UX.sliderVerticalSpacing),

                brightnessMaxImageView.centerYAnchor.constraint(equalTo: slider.centerYAnchor),
                brightnessMaxImageView.leadingAnchor.constraint(
                    equalTo: slider.trailingAnchor,
                    constant: CGFloat(UX.brightnessIconOffset)
                ),
                brightnessMaxImageView.trailingAnchor.constraint(equalTo: brightnessRow.trailingAnchor,
                                                                 constant: -UX.brightnessHorizontalSpacing),
                brightnessMaxImageView.widthAnchor.constraint(equalTo: brightnessMaxImageView.heightAnchor)
            ]
        )

        slider.value = Float(UIScreen.main.brightness)
    }

    private func adjustLayoutForA11ySizeCategory() {
        let contentSizeCategory = UIApplication.shared.preferredContentSizeCategory
        if contentSizeCategory.isAccessibilityCategory {
            fontTypeStackView.axis = .vertical
            themeStackView.axis = .vertical
            themeStackView.alignment = .fill
        } else {
            fontTypeStackView.axis = .horizontal
            themeStackView.axis = .horizontal
            themeStackView.alignment = .center
        }

        var brightnessImageSize = max(UIFontMetrics.default.scaledValue(for: UX.brightnessSize), UX.brightnessSize)
        brightnessImageSize = min(brightnessImageSize, UX.brightnessMaxSize)
        brightnessMinImageHeightConstraint?.constant = brightnessImageSize
        brightnessMaxImageHeightConstraint?.constant = brightnessImageSize
    }

    // MARK: - Notifiable
    public func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIContentSizeCategory.didChangeNotification:
            adjustLayoutForA11ySizeCategory()
        default: break
        }
    }
}
