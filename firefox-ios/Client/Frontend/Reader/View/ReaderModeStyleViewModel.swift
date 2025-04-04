// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

// MARK: - ReaderModeStyleViewModelDelegate

protocol ReaderModeStyleViewModelDelegate: AnyObject {
    func readerModeStyleViewModel(_ readerModeStyleViewModel: ReaderModeStyleViewModel,
                                  didConfigureStyle style: ReaderModeStyle,
                                  isUsingUserDefinedColor: Bool)
}

// MARK: - ReaderModeStyleViewModel

class ReaderModeStyleViewModel {
    public init(windowUUID: WindowUUID,
                isBottomPresented: Bool,
                readerModeStyle: ReaderModeStyle? = nil) {
        let style: ReaderModeStyle = readerModeStyle ?? ReaderModeStyle.defaultStyle(for: windowUUID)
        self.readerModeStyle = style
        self.isBottomPresented = isBottomPresented
        self.readerModeStyle = style
    }

    struct UX {
        // For top or bottom presentation
        static let PresentationSpace = 13.0
    }

    var isBottomPresented: Bool
    var readerModeStyle: ReaderModeStyle

    // Keeps user-defined reader color until reader mode is closed or reloaded
    var isUsingUserDefinedColor = false

    weak var delegate: ReaderModeStyleViewModelDelegate?

    var fontTypeOffset: CGFloat {
        return isBottomPresented ? 0 : ReaderModeStyleViewModel.UX.PresentationSpace
    }

    var brightnessRowOffset: CGFloat {
        return isBottomPresented ? -ReaderModeStyleViewModel.UX.PresentationSpace : 0
    }

    func sliderDidChange(value: CGFloat) {
        UIScreen.main.brightness = value
    }

    func selectTheme(_ theme: ReaderModeTheme) {
        readerModeStyle.theme = theme
    }

    func selectFontType(_ fontType: ReaderModeFontType) {
        readerModeStyle.fontType = fontType
    }

    func readerModeDidChangeTheme(_ theme: ReaderModeTheme) {
        selectTheme(theme)
        isUsingUserDefinedColor = true
        delegate?.readerModeStyleViewModel(
            self,
            didConfigureStyle: readerModeStyle,
            isUsingUserDefinedColor: true
        )
    }

    func fontSizeDidChangeSizeAction(_ fontSizeAction: FontSizeAction) {
        switch fontSizeAction {
        case .smaller:
            readerModeStyle.fontSize = readerModeStyle.fontSize.smaller()
        case .bigger:
            readerModeStyle.fontSize = readerModeStyle.fontSize.bigger()
        case .reset:
            readerModeStyle.fontSize = ReaderModeFontSize.defaultSize
        }

        delegate?.readerModeStyleViewModel(
            self,
            didConfigureStyle: readerModeStyle,
            isUsingUserDefinedColor: isUsingUserDefinedColor
        )
    }

    func fontTypeDidChange(_ fontType: ReaderModeFontType) {
        selectFontType(fontType)
        delegate?.readerModeStyleViewModel(
            self,
            didConfigureStyle: readerModeStyle,
            isUsingUserDefinedColor: isUsingUserDefinedColor
        )
    }
}
