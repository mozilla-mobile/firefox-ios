/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

private struct ReaderModeStyleViewControllerUX {
    static let RowHeight = 50.0
    
    static let SeparatorLineThickness = 1.0

    static let Width = 270.0
    static let Height = 4.0 * RowHeight + 3.0 * SeparatorLineThickness
    
    static let ThemeRowBackgroundColor = UIColor.Photon.White100
    static let ThemeTitleColorLight = UIColor.Photon.Grey70
    static let ThemeTitleColorDark = UIColor.Photon.White100
    static let ThemeTitleColorSepia = UIColor.Photon.Grey70
    static let ThemeBackgroundColorLight = UIColor.Photon.White100
    static let ThemeBackgroundColorDark = UIColor.Photon.Grey80
    static let ThemeBackgroundColorSepia = UIColor.Defaults.LightBeige

    static let BrightnessSliderTintColor = UIColor.Photon.Orange60
    static let BrightnessSliderWidth = 140
    static let BrightnessIconOffset = 10
}

// MARK: -

protocol ReaderModeStyleViewControllerDelegate {    
    // isUsingUserDefinedColor should be false by default unless we need to override the default color 
    func readerModeStyleViewController(_ readerModeStyleViewController: ReaderModeStyleViewController, 
                                       didConfigureStyle style: ReaderModeStyle,
                                       isUsingUserDefinedColor: Bool)
}

// MARK: -

class ReaderModeStyleViewController: UIViewController, Themeable {
    var delegate: ReaderModeStyleViewControllerDelegate?
    var readerModeStyle: ReaderModeStyle = DefaultReaderModeStyle

    fileprivate var fontTypeButtons: [FontTypeButton]!
    fileprivate var fontSizeLabel: FontSizeLabel!
    fileprivate var fontSizeButtons: [FontSizeButton]!
    fileprivate var themeButtons: [ThemeButton]!
    fileprivate var separatorLines = [UIView(), UIView(), UIView()]
    
    fileprivate var fontTypeRow: UIView!
    fileprivate var fontSizeRow: UIView!
    fileprivate var brightnessRow: UIView!
    
    // Keeps user-defined reader color until reader mode is closed or reloaded
    fileprivate var isUsingUserDefinedColor = false
    
    override func viewDidLoad() {
        // Our preferred content size has a fixed width and height based on the rows + padding
        super.viewDidLoad()
        preferredContentSize = CGSize(width: ReaderModeStyleViewControllerUX.Width, height: ReaderModeStyleViewControllerUX.Height)
        popoverPresentationController?.backgroundColor = UIColor.theme.tableView.rowBackground

        // Font type row

        fontTypeRow = UIView()
        view.addSubview(fontTypeRow)

        fontTypeRow.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(13)
            make.left.right.equalTo(self.view)
            make.height.equalTo(ReaderModeStyleViewControllerUX.RowHeight)
        }

        fontTypeButtons = [
            FontTypeButton(fontType: ReaderModeFontType.sansSerif),
            FontTypeButton(fontType: ReaderModeFontType.serif)
        ]

        setupButtons(fontTypeButtons, inRow: fontTypeRow, action: #selector(changeFontType))

        view.addSubview(separatorLines[0])
        makeSeparatorView(fromView: separatorLines[0], topConstraint: fontTypeRow)
        
        // Font size row

        fontSizeRow = UIView()
        view.addSubview(fontSizeRow)

        fontSizeRow.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(separatorLines[0].snp.bottom)
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

        setupButtons(fontSizeButtons, inRow: fontSizeRow, action: #selector(changeFontSize))

        view.addSubview(separatorLines[1])
        makeSeparatorView(fromView: separatorLines[1], topConstraint: fontSizeRow)
        
        // Theme row

        let themeRow = UIView()
        view.addSubview(themeRow)

        themeRow.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(separatorLines[1].snp.bottom)
            make.left.right.equalTo(self.view)
            make.height.equalTo(ReaderModeStyleViewControllerUX.RowHeight)
        }

        themeButtons = [
            ThemeButton(theme: ReaderModeTheme.light),
            ThemeButton(theme: ReaderModeTheme.sepia),
            ThemeButton(theme: ReaderModeTheme.dark)
        ]

        setupButtons(themeButtons, inRow: themeRow, action: #selector(changeTheme))
        
        view.addSubview(separatorLines[2])
        makeSeparatorView(fromView: separatorLines[2], topConstraint: themeRow)
        
        // Brightness row

        brightnessRow = UIView()
        view.addSubview(brightnessRow)

        brightnessRow.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(separatorLines[2].snp.bottom)
            make.left.right.equalTo(self.view)
            make.height.equalTo(ReaderModeStyleViewControllerUX.RowHeight)
        }

        let slider = UISlider()
        brightnessRow.addSubview(slider)
        slider.accessibilityLabel = NSLocalizedString("Brightness", comment: "Accessibility label for brightness adjustment slider in Reader Mode display settings")
        slider.tintColor = ReaderModeStyleViewControllerUX.BrightnessSliderTintColor
        slider.addTarget(self, action: #selector(changeBrightness), for: .valueChanged)

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
        fromView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(topConstraint.snp.bottom)
            make.left.right.equalTo(self.view)
            make.height.equalTo(ReaderModeStyleViewControllerUX.SeparatorLineThickness)
        }
    }
    
    /// Setup constraints for a row of buttons. Left to right. They are all given the same width.
    fileprivate func setupButtons(_ buttons: [UIButton], inRow row: UIView, action: Selector) {
        for (idx, button) in buttons.enumerated() {
            row.addSubview(button)
            button.addTarget(self, action: action, for: .touchUpInside)
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

    @objc func changeFontType(_ button: FontTypeButton) {
        selectFontType(button.fontType)
        delegate?.readerModeStyleViewController(self, 
                                                didConfigureStyle: readerModeStyle, 
                                                isUsingUserDefinedColor: isUsingUserDefinedColor)
    }

    fileprivate func selectFontType(_ fontType: ReaderModeFontType) {
        readerModeStyle.fontType = fontType
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
            readerModeStyle.fontSize = readerModeStyle.fontSize.smaller()
        case .bigger:
            readerModeStyle.fontSize = readerModeStyle.fontSize.bigger()
        case .reset:
            readerModeStyle.fontSize = ReaderModeFontSize.defaultSize
        }
        updateFontSizeButtons()

        delegate?.readerModeStyleViewController(self, 
                                                didConfigureStyle: readerModeStyle, 
                                                isUsingUserDefinedColor: isUsingUserDefinedColor)
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

    @objc func changeTheme(_ button: ThemeButton) {
        selectTheme(button.theme)
        isUsingUserDefinedColor = true
        delegate?.readerModeStyleViewController(self, 
                                                didConfigureStyle: readerModeStyle, 
                                                isUsingUserDefinedColor: true)
    }

    fileprivate func selectTheme(_ theme: ReaderModeTheme) {
        readerModeStyle.theme = theme
    }

    @objc func changeBrightness(_ slider: UISlider) {
        UIScreen.main.brightness = CGFloat(slider.value)
    }
}

// MARK: -

class FontTypeButton: UIButton {
    var fontType: ReaderModeFontType = .sansSerif

    convenience init(fontType: ReaderModeFontType) {
        self.init(frame: .zero)
        self.fontType = fontType
        accessibilityHint = NSLocalizedString("Changes font type.", comment: "Accessibility hint for the font type buttons in reader mode display settings")
        switch fontType {
        case .sansSerif,
             .sansSerifBold:
            setTitle(NSLocalizedString("Sans-serif", comment: "Font type setting in the reading view settings"), for: [])
            let f = UIFont(name: "FiraSans-Book", size: DynamicFontHelper.defaultHelper.ReaderStandardFontSize)
            titleLabel?.font = f
        case .serif,
             .serifBold:
            setTitle(NSLocalizedString("Serif", comment: "Font type setting in the reading view settings"), for: [])
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
        self.init(frame: .zero)
        self.fontSizeAction = fontSizeAction

        switch fontSizeAction {
        case .smaller:
            let smallerFontLabel = NSLocalizedString("-", comment: "Button for smaller reader font size. Keep this extremely short! This is shown in the reader mode toolbar.")
            let smallerFontAccessibilityLabel = NSLocalizedString("Decrease text size", comment: "Accessibility label for button decreasing font size in display settings of reader mode")
            setTitle(smallerFontLabel, for: [])
            accessibilityLabel = smallerFontAccessibilityLabel
        case .bigger:
            let largerFontLabel = NSLocalizedString("+", comment: "Button for larger reader font size. Keep this extremely short! This is shown in the reader mode toolbar.")
            let largerFontAccessibilityLabel = NSLocalizedString("Increase text size", comment: "Accessibility label for button increasing font size in display settings of reader mode")
            setTitle(largerFontLabel, for: [])
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
            case .sansSerif,
                 .sansSerifBold:
                font = UIFont(name: "FiraSans-Book", size: DynamicFontHelper.defaultHelper.ReaderBigFontSize)
            case .serif,
                 .serifBold:
                font = UIFont(name: "Charis SIL", size: DynamicFontHelper.defaultHelper.ReaderBigFontSize)
            }
        }
    }
}

// MARK: -

class ThemeButton: UIButton {
    var theme: ReaderModeTheme!

    convenience init(theme: ReaderModeTheme) {
        self.init(frame: .zero)
        self.theme = theme

        setTitle(theme.rawValue, for: [])

        accessibilityHint = NSLocalizedString("Changes color theme.", comment: "Accessibility hint for the color theme setting buttons in reader mode display settings")

        switch theme {
        case .light:
            setTitle(NSLocalizedString("Light", comment: "Light theme setting in Reading View settings"), for: [])
            setTitleColor(ReaderModeStyleViewControllerUX.ThemeTitleColorLight, for: .normal)
            backgroundColor = ReaderModeStyleViewControllerUX.ThemeBackgroundColorLight
        case .dark:
            setTitle(NSLocalizedString("Dark", comment: "Dark theme setting in Reading View settings"), for: [])
            setTitleColor(ReaderModeStyleViewControllerUX.ThemeTitleColorDark, for: [])
            backgroundColor = ReaderModeStyleViewControllerUX.ThemeBackgroundColorDark
        case .sepia:
            setTitle(NSLocalizedString("Sepia", comment: "Sepia theme setting in Reading View settings"), for: [])
            setTitleColor(ReaderModeStyleViewControllerUX.ThemeTitleColorSepia, for: .normal)
            backgroundColor = ReaderModeStyleViewControllerUX.ThemeBackgroundColorSepia
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
                titleLabel?.font = UIFont(name: "Charis SIL", size: DynamicFontHelper.defaultHelper.ReaderStandardFontSize)
            }
        }
    }
}
