/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

let NotificationDynamicFontChanged: String = "NotificationDynamicFontChanged"

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
        defaultStandardFontSize = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleBody).pointSize // 14pt -> 17pt -> 23pt
        deviceFontSize = defaultStandardFontSize * (UIDevice.currentDevice().userInterfaceIdiom == .Pad ? iPadFactor : iPhoneFactor)
        defaultMediumFontSize = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleFootnote).pointSize // 12pt -> 13pt -> 19pt
        defaultSmallFontSize = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleCaption2).pointSize // 11pt -> 11pt -> 17pt

        super.init()
    }

    /**
     * Starts monitoring the ContentSizeCategory chantes
     */
    func startObserving() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DynamicFontHelper.SELcontentSizeCategoryDidChange(_:)), name: UIContentSizeCategoryDidChangeNotification, object: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    /**
     * Device specific
     */
    private var deviceFontSize: CGFloat
    var DeviceFontSize: CGFloat {
        return deviceFontSize
    }
    var DeviceFont: UIFont {
        return UIFont.systemFontOfSize(deviceFontSize, weight: UIFontWeightMedium)
    }
    var DeviceFontLight: UIFont {
        return UIFont.systemFontOfSize(deviceFontSize, weight: UIFontWeightLight)
    }
    var DeviceFontSmall: UIFont {
        return UIFont.systemFontOfSize(deviceFontSize - 1, weight: UIFontWeightMedium)
    }
    var DeviceFontSmallLight: UIFont {
        return UIFont.systemFontOfSize(deviceFontSize - 1, weight: UIFontWeightLight)
    }
    var DeviceFontSmallBold: UIFont {
        return UIFont.systemFontOfSize(deviceFontSize - 1, weight: UIFontWeightBold)
    }

    /**
     * Small
     */
    private var defaultSmallFontSize: CGFloat
    var DefaultSmallFontSize: CGFloat {
        return defaultSmallFontSize
    }
    var DefaultSmallFont: UIFont {
        return UIFont.systemFontOfSize(defaultSmallFontSize, weight: UIFontWeightRegular)
    }
    var DefaultSmallFontBold: UIFont {
        return UIFont.boldSystemFontOfSize(defaultSmallFontSize)
    }

    /**
     * Medium
     */
    private var defaultMediumFontSize: CGFloat
    var DefaultMediumFontSize: CGFloat {
        return defaultMediumFontSize
    }
    var DefaultMediumFont: UIFont {
        return UIFont.systemFontOfSize(defaultMediumFontSize, weight: UIFontWeightRegular)
    }
    var DefaultMediumBoldFont: UIFont {
        return UIFont.boldSystemFontOfSize(defaultMediumFontSize)
    }

    /**
     * Standard
     */
    private var defaultStandardFontSize: CGFloat
    var DefaultStandardFontSize: CGFloat {
        return defaultStandardFontSize
    }
    var DefaultStandardFont: UIFont {
        return UIFont.systemFontOfSize(defaultStandardFontSize, weight: UIFontWeightRegular)
    }
    var DefaultStandardFontBold: UIFont {
        return UIFont.boldSystemFontOfSize(defaultStandardFontSize)
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
        defaultStandardFontSize = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleBody).pointSize
        deviceFontSize = defaultStandardFontSize * (UIDevice.currentDevice().userInterfaceIdiom == .Pad ? iPadFactor : iPhoneFactor)
        defaultMediumFontSize = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleFootnote).pointSize
        defaultSmallFontSize = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleCaption2).pointSize
    }

    func SELcontentSizeCategoryDidChange(notification: NSNotification) {
        refreshFonts()
        let notification = NSNotification(name: NotificationDynamicFontChanged, object: nil)
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
}
