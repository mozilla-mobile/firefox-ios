// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Common

// MARK: - ReaderModeStyleViewController

class ReaderModeStyleViewController: UIViewController, Themeable {
    // UI views
    private var fontTypeButtons: [ReaderModeFontTypeButton] = []
    private var fontSizeLabel: ReaderModeFontSizeLabel?
    private var fontSizeButtons: [ReaderModeFontSizeButton] = []
    private var themeButtons: [ReaderModeThemeButton] = []
    private var brightnessImageViews = [UIImageView]()
    private var separatorLines = [UIView.build(), UIView.build(), UIView.build()]

    private var fontTypeRow: UIView?
    private var fontSizeRow: UIView?
    private var brightnessRow: UIView?

    private lazy var slider: UISlider = .build { slider in
        slider.accessibilityLabel = .ReaderModeStyleBrightnessAccessibilityLabel
        slider.addTarget(self, action: #selector(self.changeBrightness), for: .valueChanged)
    }

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
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Our preferred content size has a fixed width and height based on the rows + padding
        preferredContentSize = CGSize(
            width: ReaderModeStyleViewModel.UX.Width,
            height: ReaderModeStyleViewModel.UX.Height
        )

        // Font type row

        let fontTypeRow: UIView = .build()
        view.addSubview(fontTypeRow)

        NSLayoutConstraint.activate([
            fontTypeRow.topAnchor.constraint(equalTo: view.topAnchor, constant: viewModel.fontTypeOffset),
            fontTypeRow.leftAnchor.constraint(equalTo: view.leftAnchor),
            fontTypeRow.rightAnchor.constraint(equalTo: view.rightAnchor),
            fontTypeRow.heightAnchor.constraint(equalToConstant: ReaderModeStyleViewModel.UX.RowHeight),
        ])
        self.fontTypeRow = fontTypeRow

        fontTypeButtons = [
            ReaderModeFontTypeButton(fontType: ReaderModeFontType.sansSerif),
            ReaderModeFontTypeButton(fontType: ReaderModeFontType.serif)
        ]

        setupButtons(fontTypeButtons, inRow: fontTypeRow, action: #selector(changeFontType))

        view.addSubview(separatorLines[0])
        makeSeparatorView(fromView: separatorLines[0], topConstraint: fontTypeRow)

        // Font size row

        let fontSizeRow: UIView = .build()
        view.addSubview(fontSizeRow)

        NSLayoutConstraint.activate([
            fontSizeRow.topAnchor.constraint(equalTo: separatorLines[0].bottomAnchor),
            fontSizeRow.leftAnchor.constraint(equalTo: view.leftAnchor),
            fontSizeRow.rightAnchor.constraint(equalTo: view.rightAnchor),
            fontSizeRow.heightAnchor.constraint(equalToConstant: ReaderModeStyleViewModel.UX.RowHeight),
        ])
        self.fontSizeRow = fontSizeRow

        let fontSizeLabel: ReaderModeFontSizeLabel = .build()
        fontSizeRow.addSubview(fontSizeLabel)

        NSLayoutConstraint.activate([
            fontSizeLabel.centerXAnchor.constraint(equalTo: fontSizeRow.centerXAnchor),
            fontSizeLabel.centerYAnchor.constraint(equalTo: fontSizeRow.centerYAnchor),
        ])
        self.fontSizeLabel = fontSizeLabel

        fontSizeButtons = [
            ReaderModeFontSizeButton(fontSizeAction: FontSizeAction.smaller),
            ReaderModeFontSizeButton(fontSizeAction: FontSizeAction.reset),
            ReaderModeFontSizeButton(fontSizeAction: FontSizeAction.bigger)
        ]

        setupButtons(fontSizeButtons, inRow: fontSizeRow, action: #selector(changeFontSize))

        view.addSubview(separatorLines[1])
        makeSeparatorView(fromView: separatorLines[1], topConstraint: fontSizeRow)

        // Theme row

        let themeRow: UIView = .build()
        view.addSubview(themeRow)

        NSLayoutConstraint.activate([
            themeRow.topAnchor.constraint(equalTo: separatorLines[1].bottomAnchor),
            themeRow.leftAnchor.constraint(equalTo: view.leftAnchor),
            themeRow.rightAnchor.constraint(equalTo: view.rightAnchor),
            themeRow.heightAnchor.constraint(equalToConstant: ReaderModeStyleViewModel.UX.RowHeight)
        ])

        // These UIButtons represent the ReaderModeTheme (Light/Sepia/Dark)
        // they don't follow the App Theme
        themeButtons = [
            ReaderModeThemeButton(readerModeTheme: ReaderModeTheme.light),
            ReaderModeThemeButton(readerModeTheme: ReaderModeTheme.sepia),
            ReaderModeThemeButton(readerModeTheme: ReaderModeTheme.dark)
        ]

        setupButtons(themeButtons, inRow: themeRow, action: #selector(changeTheme))

        view.addSubview(separatorLines[2])
        makeSeparatorView(fromView: separatorLines[2], topConstraint: themeRow)

        // Brightness row

        let brightnessRow: UIView = .build()
        view.addSubview(brightnessRow)
        NSLayoutConstraint.activate(
            [
                brightnessRow.topAnchor.constraint(equalTo: separatorLines[2].bottomAnchor),
                brightnessRow.leftAnchor.constraint(equalTo: view.leftAnchor),
                brightnessRow.rightAnchor.constraint(equalTo: view.rightAnchor),
                brightnessRow.heightAnchor.constraint(equalToConstant: ReaderModeStyleViewModel.UX.RowHeight),
                brightnessRow.bottomAnchor.constraint(
                    equalTo: view.bottomAnchor,
                    constant: viewModel.brightnessRowOffset
                ),
            ]
        )
        self.brightnessRow = brightnessRow

        brightnessRow.addSubview(slider)
        NSLayoutConstraint.activate(
            [
                slider.centerXAnchor.constraint(equalTo: brightnessRow.centerXAnchor),
                slider.centerYAnchor.constraint(equalTo: brightnessRow.centerYAnchor),
                slider.widthAnchor.constraint(
                    equalToConstant: CGFloat(ReaderModeStyleViewModel.UX.BrightnessSliderWidth)
                )
            ]
        )

        let brightnessMinImageView: UIImageView = .build { imageView in
            imageView.image = UIImage(named: StandardImageIdentifiers.Medium.sun)?.withRenderingMode(.alwaysTemplate)
        }
        brightnessImageViews.append(brightnessMinImageView)
        brightnessRow.addSubview(brightnessMinImageView)

        NSLayoutConstraint.activate(
            [
                brightnessMinImageView.centerYAnchor.constraint(equalTo: slider.centerYAnchor),
                brightnessMinImageView.rightAnchor.constraint(
                    equalTo: slider.leftAnchor,
                    constant: -CGFloat(ReaderModeStyleViewModel.UX.BrightnessIconOffset)
                )
            ]
        )

        let brightnessMaxImageView: UIImageView = .build { imageView in
            let image = UIImage(named: StandardImageIdentifiers.Medium.sunFill)
            imageView.image = image?.withRenderingMode(.alwaysTemplate)
        }
        brightnessImageViews.append(brightnessMaxImageView)
        brightnessRow.addSubview(brightnessMaxImageView)

        NSLayoutConstraint.activate(
            [
                brightnessMaxImageView.centerYAnchor.constraint(equalTo: slider.centerYAnchor),
                brightnessMaxImageView.leftAnchor.constraint(
                    equalTo: slider.rightAnchor,
                    constant: CGFloat(ReaderModeStyleViewModel.UX.BrightnessIconOffset)
                )
            ]
        )

        updateFontSizeButtons()
        updateFontTypeButtons()
        slider.value = Float(UIScreen.main.brightness)

        listenForThemeChange(view)
        applyTheme()
    }

    // MARK: - Applying Theme
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        popoverPresentationController?.backgroundColor = theme.colors.layer1

        slider.tintColor = theme.colors.actionPrimary

        // Set background color to container views
        [fontTypeRow, fontSizeRow, brightnessRow].forEach { view in
            view?.backgroundColor = theme.colors.layer1
        }

        fontSizeLabel?.textColor = theme.colors.textPrimary

        fontTypeButtons.forEach { button in
            button.setTitleColor(theme.colors.textPrimary,
                                 for: .selected)
            button.setTitleColor(theme.colors.textDisabled, for: [])
        }

        fontSizeButtons.forEach { button in
            button.setTitleColor(theme.colors.textPrimary, for: .normal)
            button.setTitleColor(theme.colors.textPrimary, for: .disabled)
        }

        separatorLines.forEach { line in
            line.backgroundColor = theme.colors.borderPrimary
        }

        brightnessImageViews.forEach { view in
            view.tintColor = theme.colors.iconSecondary
        }
    }

    func applyTheme(_ preferences: Prefs, contentScript: TabContentScript) {
        guard let readerPreferences = preferences.dictionaryForKey(ReaderModeProfileKeyStyle),
              let readerMode = contentScript as? ReaderMode,
              let style = ReaderModeStyle(windowUUID: windowUUID, dict: readerPreferences) else { return }

        readerMode.style = style
    }

    private func makeSeparatorView(fromView: UIView, topConstraint: UIView) {
        NSLayoutConstraint.activate(
            [
                fromView.topAnchor.constraint(equalTo: topConstraint.bottomAnchor),
                fromView.leftAnchor.constraint(equalTo: view.leftAnchor),
                fromView.rightAnchor.constraint(equalTo: view.rightAnchor),
                fromView.heightAnchor.constraint(
                    equalToConstant: CGFloat(ReaderModeStyleViewModel.UX.SeparatorLineThickness)
                )
            ]
        )
    }

    /// Setup constraints for a row of buttons. Left to right. They are all given the same width.
    private func setupButtons(_ buttons: [UIButton], inRow row: UIView, action: Selector) {
        for (idx, button) in buttons.enumerated() {
            row.addSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: action, for: .touchUpInside)
            NSLayoutConstraint.activate([
                button.topAnchor.constraint(equalTo: row.topAnchor),
                button.leftAnchor.constraint(equalTo: idx == 0 ? row.leftAnchor : buttons[idx - 1].rightAnchor),
                button.bottomAnchor.constraint(equalTo: row.bottomAnchor),
                button.widthAnchor.constraint(equalToConstant: self.preferredContentSize.width / CGFloat(buttons.count))
            ])
        }
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
        for button in themeButtons {
            button.fontType = fontType
        }
        fontSizeLabel?.fontType = fontType
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
}
