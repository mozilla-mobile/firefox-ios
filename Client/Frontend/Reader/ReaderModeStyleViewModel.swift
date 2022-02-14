// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// MARK: - ReaderModeStyleViewModel

struct ReaderModeStyleViewModel {
    static let RowHeight = 50.0
    // For top or bottom presentation
    static let PresentationSpace = 13.0

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

    var isBottomPresented: Bool
    var readerModeStyle: ReaderModeStyle = DefaultReaderModeStyle

    var fontTypeOffset: CGFloat {
        return isBottomPresented ? 0 : ReaderModeStyleViewModel.PresentationSpace
    }

    var brightnessRowOffset: CGFloat {
        return isBottomPresented ? -ReaderModeStyleViewModel.PresentationSpace : 0
    }
}
