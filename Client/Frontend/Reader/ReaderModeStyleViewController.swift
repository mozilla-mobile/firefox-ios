// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Shared

// MARK: - ReaderModeStyleViewControllerDelegate

protocol ReaderModeStyleViewControllerDelegate: AnyObject {
    // isUsingUserDefinedColor should be false by default unless we need to override the default color 
    func readerModeStyleViewController(_ readerModeStyleViewController: ReaderModeStyleViewController,
                                       didConfigureStyle style: ReaderModeStyle,
                                       isUsingUserDefinedColor: Bool)
}

// MARK: - ReaderModeStyleViewController

class ReaderModeStyleViewController: UIViewController, NotificationThemeable {
    var delegate: ReaderModeStyleViewControllerDelegate?

    fileprivate var fontTypeButtons: [FontTypeButton]!
    fileprivate var fontSizeLabel: FontSizeLabel!
    fileprivate var fontSizeButtons: [FontSizeButton]!
    fileprivate var themeButtons: [ThemeButton]!
    fileprivate var separatorLines = [UIView.build(), UIView.build(), UIView.build()]

    fileprivate var fontTypeRow: UIView!
    fileprivate var fontSizeRow: UIView!
    fileprivate var brightnessRow: UIView!

    // Keeps user-defined reader color until reader mode is closed or reloaded
    fileprivate var isUsingUserDefinedColor = false

    private var viewModel: ReaderModeStyleViewModel!

    static func initReaderModeViewController(viewModel: ReaderModeStyleViewModel) -> ReaderModeStyleViewController {
        let readerModeController = ReaderModeStyleViewController()
        readerModeController.viewModel = viewModel

        return readerModeController
    }

    override func viewDidLoad() {
        // Our preferred content size has a fixed width and height based on the rows + padding
        super.viewDidLoad()
        preferredContentSize = CGSize(width: ReaderModeStyleViewModel.Width, height: ReaderModeStyleViewModel.Height)
        popoverPresentationController?.backgroundColor = UIColor.theme.tableView.rowBackground

        // Font type row

        fontTypeRow = .build()
        view.addSubview(fontTypeRow)

        NSLayoutConstraint.activate([
            fontTypeRow.topAnchor.constraint(equalTo: view.topAnchor, constant: viewModel.fontTypeOffset),
            fontTypeRow.leftAnchor.constraint(equalTo: view.leftAnchor),
            fontTypeRow.rightAnchor.constraint(equalTo: view.rightAnchor),
            fontTypeRow.heightAnchor.constraint(equalToConstant: ReaderModeStyleViewModel.RowHeight),
        ])

        fontTypeButtons = [
            FontTypeButton(fontType: ReaderModeFontType.sansSerif),
            FontTypeButton(fontType: ReaderModeFontType.serif)
        ]

        setupButtons(fontTypeButtons, inRow: fontTypeRow, action: #selector(changeFontType))

        view.addSubview(separatorLines[0])
        makeSeparatorView(fromView: separatorLines[0], topConstraint: fontTypeRow)

        // Font size row

        fontSizeRow = .build()
        view.addSubview(fontSizeRow)

        NSLayoutConstraint.activate([
            fontSizeRow.topAnchor.constraint(equalTo: separatorLines[0].bottomAnchor),
            fontSizeRow.leftAnchor.constraint(equalTo: view.leftAnchor),
            fontSizeRow.rightAnchor.constraint(equalTo: view.rightAnchor),
            fontSizeRow.heightAnchor.constraint(equalToConstant: ReaderModeStyleViewModel.RowHeight),
        ])

        fontSizeLabel = .build()
        fontSizeRow.addSubview(fontSizeLabel)

        NSLayoutConstraint.activate([
            fontSizeLabel.centerXAnchor.constraint(equalTo: fontSizeRow.centerXAnchor),
            fontSizeLabel.centerYAnchor.constraint(equalTo: fontSizeRow.centerYAnchor),
        ])

        fontSizeButtons = [
            FontSizeButton(fontSizeAction: FontSizeAction.smaller),
            FontSizeButton(fontSizeAction: FontSizeAction.reset),
            FontSizeButton(fontSizeAction: FontSizeAction.bigger)
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
            themeRow.heightAnchor.constraint(equalToConstant: ReaderModeStyleViewModel.RowHeight)
        ])

        themeButtons = [
            ThemeButton(theme: ReaderModeTheme.light),
            ThemeButton(theme: ReaderModeTheme.sepia),
            ThemeButton(theme: ReaderModeTheme.dark)
        ]

        setupButtons(themeButtons, inRow: themeRow, action: #selector(changeTheme))

        view.addSubview(separatorLines[2])
        makeSeparatorView(fromView: separatorLines[2], topConstraint: themeRow)

        // Brightness row

        brightnessRow = .build()
        view.addSubview(brightnessRow)
        NSLayoutConstraint.activate([
            brightnessRow.topAnchor.constraint(equalTo: separatorLines[2].bottomAnchor),
            brightnessRow.leftAnchor.constraint(equalTo: view.leftAnchor),
            brightnessRow.rightAnchor.constraint(equalTo: view.rightAnchor),
            brightnessRow.heightAnchor.constraint(equalToConstant: ReaderModeStyleViewModel.RowHeight),
            brightnessRow.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: viewModel.brightnessRowOffset),
        ])

        let slider: UISlider = .build { slider in
            slider.accessibilityLabel = .ReaderModeStyleBrightnessAccessibilityLabel
            slider.tintColor = ReaderModeStyleViewModel.BrightnessSliderTintColor
            slider.addTarget(self, action: #selector(self.changeBrightness), for: .valueChanged)
        }

        brightnessRow.addSubview(slider)
        NSLayoutConstraint.activate([
            slider.centerXAnchor.constraint(equalTo: brightnessRow.centerXAnchor),
            slider.centerYAnchor.constraint(equalTo: brightnessRow.centerYAnchor),
            slider.widthAnchor.constraint(equalToConstant: CGFloat(ReaderModeStyleViewModel.BrightnessSliderWidth))
        ])

        let brightnessMinImageView: UIImageView = .build { imageView in
            imageView.image = UIImage(named: "brightnessMin")
        }

        brightnessRow.addSubview(brightnessMinImageView)

        NSLayoutConstraint.activate([
            brightnessMinImageView.centerYAnchor.constraint(equalTo: slider.centerYAnchor),
            brightnessMinImageView.rightAnchor.constraint(equalTo: slider.leftAnchor, constant: -CGFloat(ReaderModeStyleViewModel.BrightnessIconOffset))
        ])

        let brightnessMaxImageView: UIImageView = .build { imageView in
            imageView.image = UIImage(named: "brightnessMax")
        }

        brightnessRow.addSubview(brightnessMaxImageView)

        NSLayoutConstraint.activate([
            brightnessMaxImageView.centerYAnchor.constraint(equalTo: slider.centerYAnchor),
            brightnessMaxImageView.leftAnchor.constraint(equalTo: slider.rightAnchor, constant: CGFloat(ReaderModeStyleViewModel.BrightnessIconOffset))
        ])

        selectFontType(viewModel.readerModeStyle.fontType)
        updateFontSizeButtons()
        selectTheme(viewModel.readerModeStyle.theme)
        slider.value = Float(UIScreen.main.brightness)

        applyTheme()
    }

    // MARK: - Applying Theme
    func applyTheme() {
        fontTypeRow.backgroundColor = UIColor.theme.tableView.rowBackground
        fontSizeRow.backgroundColor = UIColor.theme.tableView.rowBackground
        brightnessRow.backgroundColor = UIColor.theme.tableView.rowBackground
        fontSizeLabel.textColor = UIColor.theme.tableView.rowText
        fontTypeButtons.forEach { button in
            button.setTitleColor(UIColor.theme.tableView.rowText, for: .selected)
            button.setTitleColor(UIColor.Photon.Grey40, for: [])
        }
        fontSizeButtons.forEach { button in
            button.setTitleColor(UIColor.theme.tableView.rowText, for: .normal)
            button.setTitleColor(UIColor.theme.tableView.disabledRowText, for: .disabled)
        }
        separatorLines.forEach { line in
            line.backgroundColor = UIColor.theme.tableView.separator
        }
    }

    func applyTheme(_ preferences: Prefs, contentScript: TabContentScript) {
        guard let readerPreferences = preferences.dictionaryForKey(ReaderModeProfileKeyStyle),
              let readerMode = contentScript as? ReaderMode,
              var style = ReaderModeStyle(dict: readerPreferences) else { return }

        style.ensurePreferredColorThemeIfNeeded()
        readerMode.style = style
    }

    fileprivate func makeSeparatorView(fromView: UIView, topConstraint: UIView) {
        NSLayoutConstraint.activate([
            fromView.topAnchor.constraint(equalTo: topConstraint.bottomAnchor),
            fromView.leftAnchor.constraint(equalTo: view.leftAnchor),
            fromView.rightAnchor.constraint(equalTo: view.rightAnchor),
            fromView.heightAnchor.constraint(equalToConstant: CGFloat(ReaderModeStyleViewModel.SeparatorLineThickness))
        ])
    }

    /// Setup constraints for a row of buttons. Left to right. They are all given the same width.
    fileprivate func setupButtons(_ buttons: [UIButton], inRow row: UIView, action: Selector) {
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

    @objc func changeFontType(_ button: FontTypeButton) {
        selectFontType(button.fontType)
        delegate?.readerModeStyleViewController(self,
                                                didConfigureStyle: viewModel.readerModeStyle,
                                                isUsingUserDefinedColor: isUsingUserDefinedColor)
    }

    fileprivate func selectFontType(_ fontType: ReaderModeFontType) {
        viewModel.readerModeStyle.fontType = fontType
        for button in fontTypeButtons {
            button.isSelected = button.fontType.isSameFamily(fontType)
        }
        for button in themeButtons {
            button.fontType = fontType
        }
        fontSizeLabel.fontType = fontType
    }

    @objc func changeFontSize(_ button: FontSizeButton) {
        switch button.fontSizeAction {
        case .smaller:
            viewModel.readerModeStyle.fontSize = viewModel.readerModeStyle.fontSize.smaller()
        case .bigger:
            viewModel.readerModeStyle.fontSize = viewModel.readerModeStyle.fontSize.bigger()
        case .reset:
            viewModel.readerModeStyle.fontSize = ReaderModeFontSize.defaultSize
        }
        updateFontSizeButtons()

        delegate?.readerModeStyleViewController(self,
                                                didConfigureStyle: viewModel.readerModeStyle,
                                                isUsingUserDefinedColor: isUsingUserDefinedColor)
    }

    fileprivate func updateFontSizeButtons() {
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

    @objc func changeTheme(_ button: ThemeButton) {
        selectTheme(button.theme)
        isUsingUserDefinedColor = true
        delegate?.readerModeStyleViewController(self,
                                                didConfigureStyle: viewModel.readerModeStyle,
                                                isUsingUserDefinedColor: true)
    }

    fileprivate func selectTheme(_ theme: ReaderModeTheme) {
        viewModel.readerModeStyle.theme = theme
    }

    @objc func changeBrightness(_ slider: UISlider) {
        UIScreen.main.brightness = CGFloat(slider.value)
    }
}

// MARK: - FontTypeButton

class FontTypeButton: UIButton {
    var fontType: ReaderModeFontType = .sansSerif

    convenience init(fontType: ReaderModeFontType) {
        self.init(frame: .zero)
        self.fontType = fontType
        accessibilityHint = .ReaderModeStyleFontTypeAccessibilityLabel
        switch fontType {
        case .sansSerif,
             .sansSerifBold:
            setTitle(.ReaderModeStyleSansSerifFontType, for: [])
            let f = UIFont(name: "FiraSans-Book", size: DynamicFontHelper.defaultHelper.ReaderStandardFontSize)
            titleLabel?.font = f
        case .serif,
             .serifBold:
            setTitle(.ReaderModeStyleSerifFontType, for: [])
            let f = UIFont(name: "NewYorkMedium-Regular", size: DynamicFontHelper.defaultHelper.ReaderStandardFontSize)
            titleLabel?.font = f
        }
    }
}

// MARK: - FontSizeAction

enum FontSizeAction {
    case smaller
    case reset
    case bigger
}

class FontSizeButton: UIButton {
    var fontSizeAction: FontSizeAction = .bigger

    convenience init(fontSizeAction: FontSizeAction) {
        self.init(frame: .zero)
        self.fontSizeAction = fontSizeAction

        switch fontSizeAction {
        case .smaller:
            setTitle(.ReaderModeStyleSmallerLabel, for: [])
            accessibilityLabel = .ReaderModeStyleSmallerAccessibilityLabel
        case .bigger:
            setTitle(.ReaderModeStyleLargerLabel, for: [])
            accessibilityLabel = .ReaderModeStyleLargerAccessibilityLabel
        case .reset:
            accessibilityLabel = .ReaderModeResetFontSizeAccessibilityLabel
        }

        // TODO Does this need to change with the selected font type? Not sure if makes sense for just +/-
        titleLabel?.font = UIFont(name: "FiraSans-Light", size: DynamicFontHelper.defaultHelper.ReaderBigFontSize)
    }
}

// MARK: - FontSizeLabel

class FontSizeLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        text = .ReaderModeStyleFontSize
        isAccessibilityElement = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var fontType: ReaderModeFontType = .sansSerif {
        didSet {
            switch fontType {
            case .sansSerif,
                 .sansSerifBold:
                font = UIFont(name: "FiraSans-Book", size: DynamicFontHelper.defaultHelper.ReaderBigFontSize)
            case .serif,
                 .serifBold:
                font = UIFont(name: "NewYorkMedium-Regular", size: DynamicFontHelper.defaultHelper.ReaderBigFontSize)
            }
        }
    }
}

// MARK: - ThemeButton

class ThemeButton: UIButton {
    var theme: ReaderModeTheme!

    convenience init(theme: ReaderModeTheme) {
        self.init(frame: .zero)
        self.theme = theme

        setTitle(theme.rawValue, for: [])

        accessibilityHint = .ReaderModeStyleChangeColorSchemeAccessibilityHint

        switch theme {
        case .light:
            setTitle(.ReaderModeStyleLightLabel, for: [])
            setTitleColor(ReaderModeStyleViewModel.ThemeTitleColorLight, for: .normal)
            backgroundColor = ReaderModeStyleViewModel.ThemeBackgroundColorLight
        case .dark:
            setTitle(.ReaderModeStyleDarkLabel, for: [])
            setTitleColor(ReaderModeStyleViewModel.ThemeTitleColorDark, for: [])
            backgroundColor = ReaderModeStyleViewModel.ThemeBackgroundColorDark
        case .sepia:
            setTitle(.ReaderModeStyleSepiaLabel, for: [])
            setTitleColor(ReaderModeStyleViewModel.ThemeTitleColorSepia, for: .normal)
            backgroundColor = ReaderModeStyleViewModel.ThemeBackgroundColorSepia
        }
    }

    var fontType: ReaderModeFontType = .sansSerif {
        didSet {
            switch fontType {
            case .sansSerif,
                 .sansSerifBold:
                titleLabel?.font = UIFont(name: "FiraSans-Book", size: DynamicFontHelper.defaultHelper.ReaderStandardFontSize)
            case .serif,
                 .serifBold:
                titleLabel?.font = UIFont(name: "NewYorkMedium-Regular", size: DynamicFontHelper.defaultHelper.ReaderStandardFontSize)
            }
        }
    }
}
