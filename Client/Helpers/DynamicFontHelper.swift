/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

let NotificationDynamicFontChanged = Notification.Name("NotificationDynamicFontChanged")

private let iPadFactor: CGFloat = 1.06
private let iPhoneFactor: CGFloat = 0.88

class DynamicFontHelper: NSObject {

    static var defaultHelper: DynamicFontHelper {
        struct Singleton {
            static let instance = DynamicFontHelper()
        }
        return Singleton.instance
    }

    override init() {
        defaultStandardFontSize = UIFontDescriptor.preferredFontDescriptor(withTextStyle: UIFontTextStyle.body).pointSize // 14pt -> 17pt -> 23pt
        deviceFontSize = defaultStandardFontSize * (UIDevice.current.userInterfaceIdiom == .pad ? iPadFactor : iPhoneFactor)
        defaultMediumFontSize = UIFontDescriptor.preferredFontDescriptor(withTextStyle: UIFontTextStyle.footnote).pointSize // 12pt -> 13pt -> 19pt
        defaultSmallFontSize = UIFontDescriptor.preferredFontDescriptor(withTextStyle: UIFontTextStyle.caption2).pointSize // 11pt -> 11pt -> 17pt

        super.init()
    }

    /**
     * Starts monitoring the ContentSizeCategory chantes
     */
    func startObserving() {
        NotificationCenter.default.addObserver(self, selector: #selector(DynamicFontHelper.SELcontentSizeCategoryDidChange(_:)), name: NSNotification.Name.UIContentSizeCategoryDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /**
     * Device specific
     */
    fileprivate var deviceFontSize: CGFloat
    var DeviceFontSize: CGFloat {
        return deviceFontSize
    }
    var DeviceFont: UIFont {
        return UIFont.systemFont(ofSize: deviceFontSize, weight: UIFontWeightMedium)
    }
    var DeviceFontLight: UIFont {
        return UIFont.systemFont(ofSize: deviceFontSize, weight: UIFontWeightLight)
    }
    var DeviceFontSmall: UIFont {
        return UIFont.systemFont(ofSize: deviceFontSize - 1, weight: UIFontWeightMedium)
    }
    var DeviceFontSmallLight: UIFont {
        return UIFont.systemFont(ofSize: deviceFontSize - 1, weight: UIFontWeightLight)
    }
    var DeviceFontSmallHistoryPanel: UIFont {
        return UIFont.systemFont(ofSize: deviceFontSize - 3, weight: UIFontWeightLight)
    }
    var DeviceFontHistoryPanel: UIFont {
        return UIFont.systemFont(ofSize: deviceFontSize)
    }
    var DeviceFontSmallBold: UIFont {
        return UIFont.boldSystemFont(ofSize: deviceFontSize - 1)
    }
    var DeviceFontMedium: UIFont {
        return UIFont.systemFont(ofSize: deviceFontSize + 1)
    }
    var DeviceFontMediumBold: UIFont {
        return UIFont.boldSystemFont(ofSize: deviceFontSize + 1)
    }
    var DeviceFontMediumBoldActivityStream: UIFont {
        return UIFont.systemFont(ofSize: deviceFontSize + 2, weight: UIFontWeightHeavy)
    }
    var DeviceFontSmallActivityStream: UIFont {
        return UIFont.systemFont(ofSize: deviceFontSize - 2, weight: UIFontWeightMedium)
    }
    var DeviceFontDescriptionActivityStream: UIFont {
        return UIFont.systemFont(ofSize: deviceFontSize - 2, weight: UIFontWeightRegular)
    }

    /**
     * Small
     */
    fileprivate var defaultSmallFontSize: CGFloat
    var DefaultSmallFontSize: CGFloat {
        return defaultSmallFontSize
    }
    var DefaultSmallFont: UIFont {
        return UIFont.systemFont(ofSize: defaultSmallFontSize, weight: UIFontWeightRegular)
    }
    var DefaultSmallFontBold: UIFont {
        return UIFont.boldSystemFont(ofSize: defaultSmallFontSize)
    }

    /**
     * Medium
     */
    fileprivate var defaultMediumFontSize: CGFloat
    var DefaultMediumFontSize: CGFloat {
        return defaultMediumFontSize
    }
    var DefaultMediumFont: UIFont {
        return UIFont.systemFont(ofSize: defaultMediumFontSize, weight: UIFontWeightRegular)
    }
    var DefaultMediumBoldFont: UIFont {
        return UIFont.boldSystemFont(ofSize: defaultMediumFontSize)
    }

    /**
     * Standard
     */
    fileprivate var defaultStandardFontSize: CGFloat
    var DefaultStandardFontSize: CGFloat {
        return defaultStandardFontSize
    }
    var DefaultStandardFont: UIFont {
        return UIFont.systemFont(ofSize: defaultStandardFontSize, weight: UIFontWeightRegular)
    }
    var DefaultStandardFontBold: UIFont {
        return UIFont.boldSystemFont(ofSize: defaultStandardFontSize)
    }

    /**
     * Reader mode
     */
    var ReaderStandardFontSize: CGFloat {
        return defaultStandardFontSize - 2
    }
    var ReaderBigFontSize: CGFloat {
        return defaultStandardFontSize + 5
    }

    /**
     * Intro mode
     */
    var IntroStandardFontSize: CGFloat {
        return defaultStandardFontSize - 1
    }
    var IntroBigFontSize: CGFloat {
        return defaultStandardFontSize + 1
    }

    func refreshFonts() {
        defaultStandardFontSize = UIFontDescriptor.preferredFontDescriptor(withTextStyle: UIFontTextStyle.body).pointSize
        deviceFontSize = defaultStandardFontSize * (UIDevice.current.userInterfaceIdiom == .pad ? iPadFactor : iPhoneFactor)
        defaultMediumFontSize = UIFontDescriptor.preferredFontDescriptor(withTextStyle: UIFontTextStyle.footnote).pointSize
        defaultSmallFontSize = UIFontDescriptor.preferredFontDescriptor(withTextStyle: UIFontTextStyle.caption2).pointSize
    }

    func SELcontentSizeCategoryDidChange(_ notification: Notification) {
        refreshFonts()
        let notification = Notification(name: NotificationDynamicFontChanged, object: nil)
        NotificationCenter.default.post(notification)
    }
}
