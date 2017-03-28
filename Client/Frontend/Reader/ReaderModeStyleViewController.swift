/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Shared

private struct ReaderModeStyleViewControllerUX {
    static let RowHeight = 50

    static let Width = 270
    static let Height = 4 * RowHeight

    static let FontTypeRowBackground = UIColor(rgb: 0xfbfbfb)

    static let FontTypeTitleSelectedColor = UIColor(rgb: 0x333333)
    static let FontTypeTitleNormalColor = UIColor.lightGray // TODO THis needs to be 44% of 0x333333

    static let FontSizeRowBackground = UIColor(rgb: 0xf4f4f4)
    static let FontSizeLabelColor = UIColor(rgb: 0x333333)
    static let FontSizeButtonTextColorEnabled = UIColor(rgb: 0x333333)
    static let FontSizeButtonTextColorDisabled = UIColor.lightGray // TODO THis needs to be 44% of 0x333333

    static let ThemeRowBackgroundColor = UIColor.white
    static let ThemeTitleColorLight = UIColor(rgb: 0x333333)
    static let ThemeTitleColorDark = UIColor.white
    static let ThemeTitleColorSepia = UIColor(rgb: 0x333333)
    static let ThemeBackgroundColorLight = UIColor.white
    static let ThemeBackgroundColorDark = UIColor(rgb: 0x333333)
    static let ThemeBackgroundColorSepia = UIColor(rgb: 0xF0E6DC)

    static let BrightnessRowBackground = UIColor(rgb: 0xf4f4f4)
    static let BrightnessSliderTintColor = UIColor(rgb: 0xe66000)
    static let BrightnessSliderWidth = 140
    static let BrightnessIconOffset = 10
}

// MARK: -

protocol ReaderModeStyleViewControllerDelegate {
    func readerModeStyleViewController(_ readerModeStyleViewController: ReaderModeStyleViewController, didConfigureStyle style: ReaderModeStyle)
}

// MARK: -

class ReaderModeStyleViewController: UIViewController {
    var delegate: ReaderModeStyleViewControllerDelegate?
    var readerModeStyle: ReaderModeStyle = DefaultReaderModeStyle

    fileprivate var fontTypeButtons: [FontTypeButton]!
    fileprivate var fontSizeLabel: FontSizeLabel!
    fileprivate var fontSizeButtons: [FontSizeButton]!
    fileprivate var themeButtons: [ThemeButton]!

    override func viewDidLoad() {
        // Our preferred content size has a fixed width and height based on the rows + padding

        preferredContentSize = CGSize(width: ReaderModeStyleViewControllerUX.Width, height: ReaderModeStyleViewControllerUX.Height)

        popoverPresentationController?.backgroundColor = ReaderModeStyleViewControllerUX.FontTypeRowBackground

        // Font type row

        let fontTypeRow = UIView()
        view.addSubview(fontTypeRow)
        fontTypeRow.backgroundColor = ReaderModeStyleViewControllerUX.FontTypeRowBackground

        fontTypeRow.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view)
            make.left.right.equalTo(self.view)
            make.height.equalTo(ReaderModeStyleViewControllerUX.RowHeight)
        }

        fontTypeButtons = [
            FontTypeButton(fontType: ReaderModeFontType.sansSerif),
            FontTypeButton(fontType: ReaderModeFontType.serif)
        ]

        setupButtons(fontTypeButtons, inRow: fontTypeRow, action: #selector(ReaderModeStyleViewController.SELchangeFontType(_:)))

        // Font size row

        let fontSizeRow = UIView()
        view.addSubview(fontSizeRow)
        fontSizeRow.backgroundColor = ReaderModeStyleViewControllerUX.FontSizeRowBackground

        fontSizeRow.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(fontTypeRow.snp.bottom)
            make.left.right.equalTo(self.view)
            make.height.equalTo(ReaderModeStyleViewControllerUX.RowHeight)
        }

        fontSizeLabel = FontSizeLabel()
        fontSizeRow.addSubview(fontSizeLabel)

        fontSizeLabel.snp.makeConstraints { (make) -> Void in
            make.center.equalTo(fontSizeRow)
            return
        }

        fontSizeButtons = [
            FontSizeButton(fontSizeAction: FontSizeAction.smaller),
            FontSizeButton(fontSizeAction: FontSizeAction.reset),
            FontSizeButton(fontSizeAction: FontSizeAction.bigger)
        ]

        setupButtons(fontSizeButtons, inRow: fontSizeRow, action: #selector(ReaderModeStyleViewController.SELchangeFontSize(_:)))

        // Theme row

        let themeRow = UIView()
        view.addSubview(themeRow)

        themeRow.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(fontSizeRow.snp.bottom)
            make.left.right.equalTo(self.view)
            make.height.equalTo(ReaderModeStyleViewControllerUX.RowHeight)
        }

        themeButtons = [
            ThemeButton(theme: ReaderModeTheme.light),
            ThemeButton(theme: ReaderModeTheme.dark),
            ThemeButton(theme: ReaderModeTheme.sepia)
        ]

        setupButtons(themeButtons, inRow: themeRow, action: #selector(ReaderModeStyleViewController.SELchangeTheme(_:)))

        // Brightness row

        let brightnessRow = UIView()
        view.addSubview(brightnessRow)
        brightnessRow.backgroundColor = ReaderModeStyleViewControllerUX.BrightnessRowBackground

        brightnessRow.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(themeRow.snp.bottom)
            make.left.right.equalTo(self.view)
            make.height.equalTo(ReaderModeStyleViewControllerUX.RowHeight)
        }

        let slider = UISlider()
        brightnessRow.addSubview(slider)
        slider.accessibilityLabel = NSLocalizedString("Brightness", comment: "Accessibility label for brightness adjustment slider in Reader Mode display settings")
        slider.tintColor = ReaderModeStyleViewControllerUX.BrightnessSliderTintColor
        slider.addTarget(self, action: #selector(ReaderModeStyleViewController.SELchangeBrightness(_:)), for: UIControlEvents.valueChanged)

        slider.snp.makeConstraints { make in
            make.center.equalTo(brightnessRow)
            make.width.equalTo(ReaderModeStyleViewControllerUX.BrightnessSliderWidth)
        }

        let brightnessMinImageView = UIImageView(image: UIImage(named: "brightnessMin"))
        brightnessRow.addSubview(brightnessMinImageView)

        brightnessMinImageView.snp.makeConstraints { (make) -> Void in
            make.centerY.equalTo(slider)
            make.right.equalTo(slider.snp.left).offset(-ReaderModeStyleViewControllerUX.BrightnessIconOffset)
        }

        let brightnessMaxImageView = UIImageView(image: UIImage(named: "brightnessMax"))
        brightnessRow.addSubview(brightnessMaxImageView)

        brightnessMaxImageView.snp.makeConstraints { (make) -> Void in
            make.centerY.equalTo(slider)
            make.left.equalTo(slider.snp.right).offset(ReaderModeStyleViewControllerUX.BrightnessIconOffset)
        }

        selectFontType(readerModeStyle.fontType)
        updateFontSizeButtons()
        selectTheme(readerModeStyle.theme)
        slider.value = Float(UIScreen.main.brightness)
    }

    /// Setup constraints for a row of buttons. Left to right. They are all given the same width.
    fileprivate func setupButtons(_ buttons: [UIButton], inRow row: UIView, action: Selector) {
        for (idx, button) in buttons.enumerated() {
            row.addSubview(button)
            button.addTarget(self, action: action, for: UIControlEvents.touchUpInside)
            button.snp.makeConstraints { make in
                make.top.equalTo(row.snp.top)
                if idx == 0 {
                    make.left.equalTo(row.snp.left)
                } else {
                    make.left.equalTo(buttons[idx - 1].snp.right)
                }
                make.bottom.equalTo(row.snp.bottom)
                make.width.equalTo(self.preferredContentSize.width / CGFloat(buttons.count))
            }
        }
    }

    func SELchangeFontType(_ button: FontTypeButton) {
        selectFontType(button.fontType)
        delegate?.readerModeStyleViewController(self, didConfigureStyle: readerModeStyle)
    }

    fileprivate func selectFontType(_ fontType: ReaderModeFontType) {
        readerModeStyle.fontType = fontType
        for button in fontTypeButtons {
            button.isSelected = (button.fontType == fontType)
        }
        for button in themeButtons {
            button.fontType = fontType
        }
        fontSizeLabel.fontType = fontType
    }

    func SELchangeFontSize(_ button: FontSizeButton) {
        switch button.fontSizeAction {
        case .smaller:
            readerModeStyle.fontSize = readerModeStyle.fontSize.smaller()
        case .bigger:
            readerModeStyle.fontSize = readerModeStyle.fontSize.bigger()
        case .reset:
            readerModeStyle.fontSize = ReaderModeFontSize.defaultSize
        }
        updateFontSizeButtons()
        delegate?.readerModeStyleViewController(self, didConfigureStyle: readerModeStyle)
    }

    fileprivate func updateFontSizeButtons() {
        for button in fontSizeButtons {
            switch button.fontSizeAction {
            case .bigger:
                button.isEnabled = !readerModeStyle.fontSize.isLargest()
                break
            case .smaller:
                button.isEnabled = !readerModeStyle.fontSize.isSmallest()
                break
            case .reset:
                break
            }
        }
    }

    func SELchangeTheme(_ button: ThemeButton) {
        selectTheme(button.theme)
        delegate?.readerModeStyleViewController(self, didConfigureStyle: readerModeStyle)
    }

    fileprivate func selectTheme(_ theme: ReaderModeTheme) {
        readerModeStyle.theme = theme
    }

    func SELchangeBrightness(_ slider: UISlider) {
        UIScreen.main.brightness = CGFloat(slider.value)
    }
}

// MARK: -

class FontTypeButton: UIButton {
    var fontType: ReaderModeFontType = .sansSerif

    convenience init(fontType: ReaderModeFontType) {
        self.init(frame: CGRect.zero)
        self.fontType = fontType
        setTitleColor(ReaderModeStyleViewControllerUX.FontTypeTitleSelectedColor, for: UIControlState.selected)
        setTitleColor(ReaderModeStyleViewControllerUX.FontTypeTitleNormalColor, for: UIControlState())
        backgroundColor = ReaderModeStyleViewControllerUX.FontTypeRowBackground
        accessibilityHint = NSLocalizedString("Changes font type.", comment: "Accessibility hint for the font type buttons in reader mode display settings")
        switch fontType {
        case .sansSerif:
            setTitle(NSLocalizedString("Sans-serif", comment: "Font type setting in the reading view settings"), for: UIControlState())
            let f = UIFont(name: "FiraSans-Book", size: DynamicFontHelper.defaultHelper.ReaderStandardFontSize)
            titleLabel?.font = f
        case .serif:
            setTitle(NSLocalizedString("Serif", comment: "Font type setting in the reading view settings"), for: UIControlState())
            let f = UIFont(name: "Charis SIL", size: DynamicFontHelper.defaultHelper.ReaderStandardFontSize)
            titleLabel?.font = f
        }
    }
}

// MARK: -

enum FontSizeAction {
    case smaller
    case reset
    case bigger
}

class FontSizeButton: UIButton {
    var fontSizeAction: FontSizeAction = .bigger

    convenience init(fontSizeAction: FontSizeAction) {
        self.init(frame: CGRect.zero)
        self.fontSizeAction = fontSizeAction

        setTitleColor(ReaderModeStyleViewControllerUX.FontSizeButtonTextColorEnabled, for: UIControlState.normal)
        setTitleColor(ReaderModeStyleViewControllerUX.FontSizeButtonTextColorDisabled, for: UIControlState.disabled)

        switch fontSizeAction {
        case .smaller:
            let smallerFontLabel = NSLocalizedString("-", comment: "Button for smaller reader font size. Keep this extremely short! This is shown in the reader mode toolbar.")
            let smallerFontAccessibilityLabel = NSLocalizedString("Decrease text size", comment: "Accessibility label for button decreasing font size in display settings of reader mode")
            setTitle(smallerFontLabel, for: UIControlState())
            accessibilityLabel = smallerFontAccessibilityLabel
        case .bigger:
            let largerFontLabel = NSLocalizedString("+", comment: "Button for larger reader font size. Keep this extremely short! This is shown in the reader mode toolbar.")
            let largerFontAccessibilityLabel = NSLocalizedString("Increase text size", comment: "Accessibility label for button increasing font size in display settings of reader mode")
            setTitle(largerFontLabel, for: UIControlState())
            accessibilityLabel = largerFontAccessibilityLabel
        case .reset:
            accessibilityLabel = Strings.ReaderModeResetFontSizeAccessibilityLabel
        }

        // TODO Does this need to change with the selected font type? Not sure if makes sense for just +/-
        titleLabel?.font = UIFont(name: "FiraSans-Light", size: DynamicFontHelper.defaultHelper.ReaderBigFontSize)
    }
}

// MARK: -

class FontSizeLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        let fontSizeLabel = NSLocalizedString("Aa", comment: "Button for reader mode font size. Keep this extremely short! This is shown in the reader mode toolbar.")
        text = fontSizeLabel
        isAccessibilityElement = false
    }

    required init?(coder aDecoder: NSCoder) {
        // TODO
        fatalError("init(coder:) has not been implemented")
    }

    var fontType: ReaderModeFontType = .sansSerif {
        didSet {
            switch fontType {
            case .sansSerif:
                font = UIFont(name: "FiraSans-Book", size: DynamicFontHelper.defaultHelper.ReaderBigFontSize)
            case .serif:
                font = UIFont(name: "Charis SIL", size: DynamicFontHelper.defaultHelper.ReaderBigFontSize)
            }
        }
    }
}

// MARK: -

class ThemeButton: UIButton {
    var theme: ReaderModeTheme!

    convenience init(theme: ReaderModeTheme) {
        self.init(frame: CGRect.zero)
        self.theme = theme

        setTitle(theme.rawValue, for: UIControlState())

        accessibilityHint = NSLocalizedString("Changes color theme.", comment: "Accessibility hint for the color theme setting buttons in reader mode display settings")

        switch theme {
        case .light:
            setTitle(NSLocalizedString("Light", comment: "Light theme setting in Reading View settings"), for: UIControlState())
            setTitleColor(ReaderModeStyleViewControllerUX.ThemeTitleColorLight, for: UIControlState.normal)
            backgroundColor = ReaderModeStyleViewControllerUX.ThemeBackgroundColorLight
        case .dark:
            setTitle(NSLocalizedString("Dark", comment: "Dark theme setting in Reading View settings"), for: UIControlState())
            setTitleColor(ReaderModeStyleViewControllerUX.ThemeTitleColorDark, for: UIControlState())
            backgroundColor = ReaderModeStyleViewControllerUX.ThemeBackgroundColorDark
        case .sepia:
            setTitle(NSLocalizedString("Sepia", comment: "Sepia theme setting in Reading View settings"), for: UIControlState())
            setTitleColor(ReaderModeStyleViewControllerUX.ThemeTitleColorSepia, for: UIControlState.normal)
            backgroundColor = ReaderModeStyleViewControllerUX.ThemeBackgroundColorSepia
        }
    }

    var fontType: ReaderModeFontType = .sansSerif {
        didSet {
            switch fontType {
            case .sansSerif:
                titleLabel?.font = UIFont(name: "FiraSans-Book", size: DynamicFontHelper.defaultHelper.ReaderStandardFontSize)
            case .serif:
                titleLabel?.font = UIFont(name: "Charis SIL", size: DynamicFontHelper.defaultHelper.ReaderStandardFontSize)
            }
        }
    }
}
