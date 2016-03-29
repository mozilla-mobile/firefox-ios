/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

private struct ReaderModeStyleViewControllerUX {
    static let RowHeight = 50

    static let Width = 270
    static let Height = 4 * RowHeight

    static let FontTypeRowBackground = UIColor(rgb: 0xfbfbfb)

    static let FontTypeTitleSelectedColor = UIColor(rgb: 0x333333)
    static let FontTypeTitleNormalColor = UIColor.lightGrayColor() // TODO THis needs to be 44% of 0x333333

    static let FontSizeRowBackground = UIColor(rgb: 0xf4f4f4)
    static let FontSizeLabelColor = UIColor(rgb: 0x333333)
    static let FontSizeButtonTextColorEnabled = UIColor(rgb: 0x333333)
    static let FontSizeButtonTextColorDisabled = UIColor.lightGrayColor() // TODO THis needs to be 44% of 0x333333

    static let ThemeRowBackgroundColor = UIColor.whiteColor()
    static let ThemeTitleColorLight = UIColor(rgb: 0x333333)
    static let ThemeTitleColorDark = UIColor.whiteColor()
    static let ThemeTitleColorSepia = UIColor(rgb: 0x333333)
    static let ThemeBackgroundColorLight = UIColor.whiteColor()
    static let ThemeBackgroundColorDark = UIColor(rgb: 0x333333)
    static let ThemeBackgroundColorSepia = UIColor(rgb: 0xF0E6DC)

    static let BrightnessRowBackground = UIColor(rgb: 0xf4f4f4)
    static let BrightnessSliderTintColor = UIColor(rgb: 0xe66000)
    static let BrightnessSliderWidth = 140
    static let BrightnessIconOffset = 10
}

// MARK: -

protocol ReaderModeStyleViewControllerDelegate {
    func readerModeStyleViewController(readerModeStyleViewController: ReaderModeStyleViewController, didConfigureStyle style: ReaderModeStyle)
}

// MARK: -

class ReaderModeStyleViewController: UIViewController {
    var delegate: ReaderModeStyleViewControllerDelegate?
    var readerModeStyle: ReaderModeStyle = DefaultReaderModeStyle

    private var fontTypeButtons: [FontTypeButton]!
    private var fontSizeLabel: FontSizeLabel!
    private var fontSizeButtons: [FontSizeButton]!
    private var themeButtons: [ThemeButton]!

    override func viewDidLoad() {
        // Our preferred content size has a fixed width and height based on the rows + padding

        preferredContentSize = CGSize(width: ReaderModeStyleViewControllerUX.Width, height: ReaderModeStyleViewControllerUX.Height)

        popoverPresentationController?.backgroundColor = ReaderModeStyleViewControllerUX.FontTypeRowBackground

        // Font type row

        let fontTypeRow = UIView()
        view.addSubview(fontTypeRow)
        fontTypeRow.backgroundColor = ReaderModeStyleViewControllerUX.FontTypeRowBackground

        fontTypeRow.snp_makeConstraints { (make) -> () in
            make.top.equalTo(self.view)
            make.left.right.equalTo(self.view)
            make.height.equalTo(ReaderModeStyleViewControllerUX.RowHeight)
        }

        fontTypeButtons = [
            FontTypeButton(fontType: ReaderModeFontType.SansSerif),
            FontTypeButton(fontType: ReaderModeFontType.Serif)
        ]

        setupButtons(fontTypeButtons, inRow: fontTypeRow, action: "SELchangeFontType:")

        // Font size row

        let fontSizeRow = UIView()
        view.addSubview(fontSizeRow)
        fontSizeRow.backgroundColor = ReaderModeStyleViewControllerUX.FontSizeRowBackground

        fontSizeRow.snp_makeConstraints { (make) -> () in
            make.top.equalTo(fontTypeRow.snp_bottom)
            make.left.right.equalTo(self.view)
            make.height.equalTo(ReaderModeStyleViewControllerUX.RowHeight)
        }

        fontSizeLabel = FontSizeLabel()
        fontSizeRow.addSubview(fontSizeLabel)

        fontSizeLabel.snp_makeConstraints { (make) -> () in
            make.center.equalTo(fontSizeRow)
            return
        }

        fontSizeButtons = [
            FontSizeButton(fontSizeAction: FontSizeAction.Smaller),
            FontSizeButton(fontSizeAction: FontSizeAction.Bigger)
        ]

        setupButtons(fontSizeButtons, inRow: fontSizeRow, action: "SELchangeFontSize:")

        // Theme row

        let themeRow = UIView()
        view.addSubview(themeRow)

        themeRow.snp_makeConstraints { (make) -> () in
            make.top.equalTo(fontSizeRow.snp_bottom)
            make.left.right.equalTo(self.view)
            make.height.equalTo(ReaderModeStyleViewControllerUX.RowHeight)
        }

        themeButtons = [
            ThemeButton(theme: ReaderModeTheme.Light),
            ThemeButton(theme: ReaderModeTheme.Dark),
            ThemeButton(theme: ReaderModeTheme.Sepia)
        ]

        setupButtons(themeButtons, inRow: themeRow, action: "SELchangeTheme:")

        // Brightness row

        let brightnessRow = UIView()
        view.addSubview(brightnessRow)
        brightnessRow.backgroundColor = ReaderModeStyleViewControllerUX.BrightnessRowBackground

        brightnessRow.snp_makeConstraints { (make) -> () in
            make.top.equalTo(themeRow.snp_bottom)
            make.left.right.equalTo(self.view)
            make.height.equalTo(ReaderModeStyleViewControllerUX.RowHeight)
        }

        let slider = UISlider()
        brightnessRow.addSubview(slider)
        slider.accessibilityLabel = NSLocalizedString("Brightness", comment: "Accessibility label for brightness adjustment slider in Reader Mode display settings")
        slider.tintColor = ReaderModeStyleViewControllerUX.BrightnessSliderTintColor
        slider.addTarget(self, action: "SELchangeBrightness:", forControlEvents: UIControlEvents.ValueChanged)

        slider.snp_makeConstraints { make in
            make.center.equalTo(brightnessRow.center)
            make.width.equalTo(ReaderModeStyleViewControllerUX.BrightnessSliderWidth)
        }

        let brightnessMinImageView = UIImageView(image: UIImage(named: "brightnessMin"))
        brightnessRow.addSubview(brightnessMinImageView)

        brightnessMinImageView.snp_makeConstraints { (make) -> () in
            make.centerY.equalTo(slider)
            make.right.equalTo(slider.snp_left).offset(-ReaderModeStyleViewControllerUX.BrightnessIconOffset)
        }

        let brightnessMaxImageView = UIImageView(image: UIImage(named: "brightnessMax"))
        brightnessRow.addSubview(brightnessMaxImageView)

        brightnessMaxImageView.snp_makeConstraints { (make) -> () in
            make.centerY.equalTo(slider)
            make.left.equalTo(slider.snp_right).offset(ReaderModeStyleViewControllerUX.BrightnessIconOffset)
        }

        selectFontType(readerModeStyle.fontType)
        updateFontSizeButtons()
        selectTheme(readerModeStyle.theme)
        slider.value = Float(UIScreen.mainScreen().brightness)
    }

    /// Setup constraints for a row of buttons. Left to right. They are all given the same width.
    private func setupButtons(buttons: [UIButton], inRow row: UIView, action: Selector) {
        for (idx, button) in buttons.enumerate() {
            row.addSubview(button)
            button.addTarget(self, action: action, forControlEvents: UIControlEvents.TouchUpInside)
            button.snp_makeConstraints { make in
                make.top.equalTo(row.snp_top)
                if idx == 0 {
                    make.left.equalTo(row.snp_left)
                } else {
                    make.left.equalTo(buttons[idx - 1].snp_right)
                }
                make.bottom.equalTo(row.snp_bottom)
                make.width.equalTo(self.preferredContentSize.width / CGFloat(buttons.count))
            }
        }
    }

    func SELchangeFontType(button: FontTypeButton) {
        selectFontType(button.fontType)
        delegate?.readerModeStyleViewController(self, didConfigureStyle: readerModeStyle)
    }

    private func selectFontType(fontType: ReaderModeFontType) {
        readerModeStyle.fontType = fontType
        for button in fontTypeButtons {
            button.selected = (button.fontType == fontType)
        }
        for button in themeButtons {
            button.fontType = fontType
        }
        fontSizeLabel.fontType = fontType
    }

    func SELchangeFontSize(button: FontSizeButton) {
        switch button.fontSizeAction {
        case .Smaller:
            readerModeStyle.fontSize = readerModeStyle.fontSize.smaller()
        case .Bigger:
            readerModeStyle.fontSize = readerModeStyle.fontSize.bigger()
        }
        updateFontSizeButtons()
        delegate?.readerModeStyleViewController(self, didConfigureStyle: readerModeStyle)
    }

    private func updateFontSizeButtons() {
        for button in fontSizeButtons {
            switch button.fontSizeAction {
            case .Bigger:
                button.enabled = !readerModeStyle.fontSize.isLargest()
                break
            case .Smaller:
                button.enabled = !readerModeStyle.fontSize.isSmallest()
                break
            }
        }
    }

    func SELchangeTheme(button: ThemeButton) {
        selectTheme(button.theme)
        delegate?.readerModeStyleViewController(self, didConfigureStyle: readerModeStyle)
    }

    private func selectTheme(theme: ReaderModeTheme) {
        readerModeStyle.theme = theme
    }

    func SELchangeBrightness(slider: UISlider) {
        UIScreen.mainScreen().brightness = CGFloat(slider.value)
    }
}

// MARK: -

class FontTypeButton: UIButton {
    var fontType: ReaderModeFontType = .SansSerif

    convenience init(fontType: ReaderModeFontType) {
        self.init(frame: CGRectZero)
        self.fontType = fontType
        setTitleColor(ReaderModeStyleViewControllerUX.FontTypeTitleSelectedColor, forState: UIControlState.Selected)
        setTitleColor(ReaderModeStyleViewControllerUX.FontTypeTitleNormalColor, forState: UIControlState.Normal)
        backgroundColor = ReaderModeStyleViewControllerUX.FontTypeRowBackground
        accessibilityHint = NSLocalizedString("Changes font type.", comment: "Accessibility hint for the font type buttons in reader mode display settings")
        switch fontType {
        case .SansSerif:
            setTitle(NSLocalizedString("Sans-serif", comment: "Font type setting in the reading view settings"), forState: UIControlState.Normal)
            let f = UIFont(name: "FiraSans-Book", size: DynamicFontHelper.defaultHelper.ReaderStandardFontSize)
            titleLabel?.font = f
        case .Serif:
            setTitle(NSLocalizedString("Serif", comment: "Font type setting in the reading view settings"), forState: UIControlState.Normal)
            let f = UIFont(name: "Charis SIL", size: DynamicFontHelper.defaultHelper.ReaderStandardFontSize)
            titleLabel?.font = f
        }
    }
}

// MARK: -

enum FontSizeAction {
    case Smaller
    case Bigger
}

class FontSizeButton: UIButton {
    var fontSizeAction: FontSizeAction = .Bigger

    convenience init(fontSizeAction: FontSizeAction) {
        self.init(frame: CGRectZero)
        self.fontSizeAction = fontSizeAction

        setTitleColor(ReaderModeStyleViewControllerUX.FontSizeButtonTextColorEnabled, forState: UIControlState.Normal)
        setTitleColor(ReaderModeStyleViewControllerUX.FontSizeButtonTextColorDisabled, forState: UIControlState.Disabled)

        switch fontSizeAction {
        case .Smaller:
            let smallerFontLabel = NSLocalizedString("-", comment: "Button for smaller reader font size. Keep this extremely short! This is shown in the reader mode toolbar.")
            let smallerFontAccessibilityLabel = NSLocalizedString("Decrease text size", comment: "Accessibility label for button decreasing font size in display settings of reader mode")
            setTitle(smallerFontLabel, forState: .Normal)
            accessibilityLabel = smallerFontAccessibilityLabel
        case .Bigger:
            let largerFontLabel = NSLocalizedString("+", comment: "Button for larger reader font size. Keep this extremely short! This is shown in the reader mode toolbar.")
            let largerFontAccessibilityLabel = NSLocalizedString("Increase text size", comment: "Accessibility label for button increasing font size in display settings of reader mode")
            setTitle(largerFontLabel, forState: .Normal)
            accessibilityLabel = largerFontAccessibilityLabel
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

    var fontType: ReaderModeFontType = .SansSerif {
        didSet {
            switch fontType {
            case .SansSerif:
                font = UIFont(name: "FiraSans-Book", size: DynamicFontHelper.defaultHelper.ReaderBigFontSize)
            case .Serif:
                font = UIFont(name: "Charis SIL", size: DynamicFontHelper.defaultHelper.ReaderBigFontSize)
            }
        }
    }
}

// MARK: -

class ThemeButton: UIButton {
    var theme: ReaderModeTheme!

    convenience init(theme: ReaderModeTheme) {
        self.init(frame: CGRectZero)
        self.theme = theme

        setTitle(theme.rawValue, forState: UIControlState.Normal)

        accessibilityHint = NSLocalizedString("Changes color theme.", comment: "Accessibility hint for the color theme setting buttons in reader mode display settings")

        switch theme {
        case .Light:
            setTitle(NSLocalizedString("Light", comment: "Light theme setting in Reading View settings"), forState: .Normal)
            setTitleColor(ReaderModeStyleViewControllerUX.ThemeTitleColorLight, forState: UIControlState.Normal)
            backgroundColor = ReaderModeStyleViewControllerUX.ThemeBackgroundColorLight
        case .Dark:
            setTitle(NSLocalizedString("Dark", comment: "Dark theme setting in Reading View settings"), forState: .Normal)
            setTitleColor(ReaderModeStyleViewControllerUX.ThemeTitleColorDark, forState: UIControlState.Normal)
            backgroundColor = ReaderModeStyleViewControllerUX.ThemeBackgroundColorDark
        case .Sepia:
            setTitle(NSLocalizedString("Sepia", comment: "Sepia theme setting in Reading View settings"), forState: .Normal)
            setTitleColor(ReaderModeStyleViewControllerUX.ThemeTitleColorSepia, forState: UIControlState.Normal)
            backgroundColor = ReaderModeStyleViewControllerUX.ThemeBackgroundColorSepia
        }
    }

    var fontType: ReaderModeFontType = .SansSerif {
        didSet {
            switch fontType {
            case .SansSerif:
                titleLabel?.font = UIFont(name: "FiraSans-Book", size: DynamicFontHelper.defaultHelper.ReaderStandardFontSize)
            case .Serif:
                titleLabel?.font = UIFont(name: "Charis SIL", size: DynamicFontHelper.defaultHelper.ReaderStandardFontSize)
            }
        }
    }
}