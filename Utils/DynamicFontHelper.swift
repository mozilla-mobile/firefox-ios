/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

let NotificationDynamicFontChanged: String = "NotificationDynamicFontChanged"

private let iPadFactor: CGFloat = 1.06
private let iPhoneFactor: CGFloat = 0.88

public class DynamicFontHelper: NSObject {

    public class var defaultHelper: DynamicFontHelper {
        struct Singleton {
            static let instance = DynamicFontHelper()
        }
        return Singleton.instance
    }

    override init() {
        _defaultStandardFontSize = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleBody).pointSize // 14pt -> 17pt -> 23pt
        _deviceFontSize = _defaultStandardFontSize * (DeviceInfo.deviceModel().rangeOfString("iPad") != nil ? iPadFactor : iPhoneFactor)
        _defaultMediumFontSize = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleFootnote).pointSize // 12pt -> 13pt -> 19pt
        _defaultSmallFontSize = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleCaption2).pointSize // 11pt -> 11pt -> 17pt

        super.init()
    }

    /**
     * Starts monitoring the ContentSizeCategory chantes
     */
    func startObserving() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "SELcontentSizeCategoryDidChange:", name: UIContentSizeCategoryDidChangeNotification, object: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    /**
     * Device specific
     */
    private var _deviceFontSize: CGFloat
    var DeviceFontSize: CGFloat {
        return _deviceFontSize
    }
    var DeviceFont: UIFont {
        return UIFont.systemFontOfSize(_deviceFontSize, weight: UIFontWeightMedium)
    }
    var DeviceFontLight: UIFont {
        return UIFont.systemFontOfSize(_deviceFontSize, weight: UIFontWeightLight)
    }
    var DeviceFontSmall: UIFont {
        return UIFont.systemFontOfSize(_deviceFontSize - 1, weight: UIFontWeightMedium)
    }
    var DeviceFontSmallLight: UIFont {
        return UIFont.systemFontOfSize(_deviceFontSize - 1, weight: UIFontWeightLight)
    }
    var DeviceFontSmallBold: UIFont {
        return UIFont.systemFontOfSize(_deviceFontSize - 1, weight: UIFontWeightBold)
    }

    /**
     * Small
     */
    private var _defaultSmallFontSize: CGFloat
    var DefaultSmallFontSize: CGFloat {
        return _defaultSmallFontSize
    }
    var DefaultSmallFont: UIFont {
        return UIFont.systemFontOfSize(_defaultSmallFontSize, weight: UIFontWeightRegular)
    }
    var DefaultSmallFontBold: UIFont {
        return UIFont.boldSystemFontOfSize(_defaultSmallFontSize)
    }

    /**
     * Medium
     */
    private var _defaultMediumFontSize: CGFloat
    var DefaultMediumFontSize: CGFloat {
        return _defaultMediumFontSize
    }
    var DefaultMediumFont: UIFont {
        return UIFont.systemFontOfSize(_defaultMediumFontSize, weight: UIFontWeightRegular)
    }
    var DefaultMediumBoldFont: UIFont {
        return UIFont.boldSystemFontOfSize(_defaultMediumFontSize)
    }

    /**
     * Standard
     */
    private var _defaultStandardFontSize: CGFloat
    var DefaultStandardFontSize: CGFloat {
        return _defaultStandardFontSize
    }
    var DefaultStandardFont: UIFont {
        return UIFont.systemFontOfSize(_defaultStandardFontSize, weight: UIFontWeightRegular)
    }
    var DefaultStandardFontBold: UIFont {
        return UIFont.boldSystemFontOfSize(_defaultStandardFontSize)
    }

    /**
     * Reader mode
     */
    var ReaderStandardFontSize: CGFloat {
        return _defaultStandardFontSize - 2
    }
    var ReaderBigFontSize: CGFloat {
        return _defaultStandardFontSize + 5
    }

    func refreshFonts() {
        _defaultStandardFontSize = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleBody).pointSize
        _deviceFontSize = _defaultStandardFontSize * (DeviceInfo.deviceModel().rangeOfString("iPad") != nil ? iPadFactor : iPhoneFactor)
        _defaultMediumFontSize = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleFootnote).pointSize
        _defaultSmallFontSize = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleCaption2).pointSize
    }

    func SELcontentSizeCategoryDidChange(notification: NSNotification) {
        refreshFonts()
        let notification = NSNotification(name: NotificationDynamicFontChanged, object: nil)
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
}
