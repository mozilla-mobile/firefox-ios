/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

protocol ReaderModeStyleViewControllerDelegate {
    func readerModeStyleViewController(readerModeStyleViewController: ReaderModeStyleViewController, didConfigureStyle style: ReaderModeStyle)
}

class ReaderModeStyleViewController: UIViewController {
    var delegate: ReaderModeStyleViewControllerDelegate?
    var readerModeStyle: ReaderModeStyle = DefaultReaderModeStyle

    private let rowHeights = [72, 44, 44, 52]
    private let width = 260

    private var rows: [UIView] = []
    private var fontTypeButtons: [FontTypeButton]!
    private var fontSizeButtons: [FontSizeButton]!
    private var themeButtons: [ThemeButton]!

    override func viewDidLoad() {
        view.backgroundColor = UIColor.grayColor()

        // Our preferred content size has a fixed width and height based on the rows + padding

        let height = rowHeights.reduce(0, combine: +) + (rowHeights.count - 1)
        preferredContentSize = CGSize(width: width, height: height)

        // Setup the rows. It is easier to setup a layout like this when we organize the buttons into rows.

        let fontTypeRow = UIView(), fontSizeRow = UIView(), themeRow = UIView(), sliderRow = UIView()
        rows = [fontTypeRow, fontSizeRow, themeRow, sliderRow]

        for (idx, row) in enumerate(rows) {
            view.addSubview(row)

            // The only row with a full white background is the one with the slider. The others are the default
            // clear color so that the gray dividers are visible between buttons in a row.
            if row == sliderRow {
                row.backgroundColor = UIColor.whiteColor()
            }

            row.snp_makeConstraints { make in
                make.left.equalTo(self.view.snp_left)
                make.right.equalTo(self.view.snp_right)
                if idx == 0 {
                    make.top.equalTo(self.view.snp_top)
                } else {
                    make.top.equalTo(self.rows[idx - 1].snp_bottom).offset(1)
                }
                make.height.equalTo(self.rowHeights[idx])
            }
        }

        // Setup the font type buttons

        fontTypeButtons = [
            FontTypeButton(fontType: ReaderModeFontType.SansSerif),
            FontTypeButton(fontType: ReaderModeFontType.Serif)
        ]
        
        setupButtons(fontTypeButtons, inRow: fontTypeRow, action: "SELchangeFontType:")

        // Setup the font size buttons

        fontSizeButtons = [
            FontSizeButton(fontSize: ReaderModeFontSize.Smallest),
            FontSizeButton(fontSize: ReaderModeFontSize.Small),
            FontSizeButton(fontSize: ReaderModeFontSize.Normal),
            FontSizeButton(fontSize: ReaderModeFontSize.Large),
            FontSizeButton(fontSize: ReaderModeFontSize.Largest),
        ]

        setupButtons(fontSizeButtons, inRow: fontSizeRow, action: "SELchangeFontSize:")

        // Setup the theme buttons

        themeButtons = [
            ThemeButton(theme: ReaderModeTheme.Light),
            ThemeButton(theme: ReaderModeTheme.Dark),
            ThemeButton(theme: ReaderModeTheme.Print)
        ]

        setupButtons(themeButtons, inRow: themeRow, action: "SELchangeTheme:")

        // Setup the brightness slider

        let slider = UISlider()
        slider.tintColor = UIColor.orangeColor()
        sliderRow.addSubview(slider)
        slider.addTarget(self, action: "SELchangeBrightness:", forControlEvents: UIControlEvents.ValueChanged)

        slider.snp_makeConstraints { make in
            make.center.equalTo(sliderRow.center)
            make.width.equalTo(180)
        }

        // Setup initial values

        selectFontType(readerModeStyle.fontType)
        selectFontSize(readerModeStyle.fontSize)
        selectTheme(readerModeStyle.theme)
        slider.value = Float(UIScreen.mainScreen().brightness)
    }

    /// Setup constraints for a row of buttons. Left to right. They are all given the same width.
    private func setupButtons(buttons: [UIButton], inRow row: UIView, action: Selector) {
        for (idx, button) in enumerate(buttons) {
            row.addSubview(button)
            button.addTarget(self, action: action, forControlEvents: UIControlEvents.TouchUpInside)
            button.snp_makeConstraints { make in
                make.top.equalTo(row.snp_top)
                if idx == 0 {
                    make.left.equalTo(row.snp_left)
                } else {
                    make.left.equalTo(buttons[idx - 1].snp_right).offset(1)
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
    }

    func SELchangeFontSize(button: FontSizeButton) {
        selectFontSize(button.fontSize)
        delegate?.readerModeStyleViewController(self, didConfigureStyle: readerModeStyle)
    }

    private func selectFontSize(fontSize: ReaderModeFontSize) {
        readerModeStyle.fontSize = fontSize
        for button in fontSizeButtons {
            button.selected = (button.fontSize == fontSize)
        }
    }

    func SELchangeTheme(button: ThemeButton) {
        selectTheme(button.theme)
        delegate?.readerModeStyleViewController(self, didConfigureStyle: readerModeStyle)
    }

    private func selectTheme(theme: ReaderModeTheme) {
        readerModeStyle.theme = theme
        for button in themeButtons {
            button.selected = (button.theme == theme)
        }
    }

    func SELchangeBrightness(slider: UISlider) {
        UIScreen.mainScreen().brightness = CGFloat(slider.value)
    }
}

/// Custom button that knows how to show the right image and selection style for a ReaderModeFontType
/// value. Very generic now, which will change when we have more final UX assets.
class FontTypeButton: UIButton {
    var fontType: ReaderModeFontType!

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience init(fontType: ReaderModeFontType) {
        self.init(frame: CGRectZero)
        self.fontType = fontType
        setTitle(fontType.rawValue, forState: UIControlState.Normal)
        setTitleColor(UIColor.blackColor(), forState: UIControlState.Selected)
        setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
        backgroundColor = UIColor.whiteColor()
    }
}

/// Custom button that knows how to show the right image and selection style for a ReaderModeFontSize
/// value. Very generic now, which will change when we have more final UX assets.
class FontSizeButton: UIButton {
    var fontSize: ReaderModeFontSize!

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience init(fontSize: ReaderModeFontSize) {
        self.init(frame: CGRectZero)
        self.fontSize = fontSize
        setTitle("\(fontSize.rawValue)", forState: UIControlState.Normal)
        setTitleColor(UIColor.blackColor(), forState: UIControlState.Selected)
        setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
        backgroundColor = UIColor.whiteColor()
    }
}

/// Custom button that knows how to show the right image and selection style for a ReaderModeTheme
/// value. Very generic now, which will change when we have more final UX assets.
class ThemeButton: UIButton {
    var theme: ReaderModeTheme!

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience init(theme: ReaderModeTheme) {
        self.init(frame: CGRectZero)
        self.theme = theme
        setTitle(theme.rawValue, forState: UIControlState.Normal)
        setTitleColor(UIColor.blackColor(), forState: UIControlState.Selected)
        setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
        backgroundColor = UIColor.whiteColor()
    }
}