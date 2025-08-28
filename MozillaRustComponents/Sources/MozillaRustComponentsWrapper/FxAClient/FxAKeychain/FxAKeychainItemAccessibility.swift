/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public enum FxAKeychainItemAccessibility: String {
    /**
      The data in the keychain item cannot be accessed after a restart until the device has been unlocked once by
      the user.

      After the first unlock, the data remains accessible until the next restart. This is recommended for items that
      need to be accessed by background applications. Items with this attribute migrate to a new device when using
      encrypted backups.
     */
    case afterFirstUnlock = "kSecAttrAccessibleAfterFirstUnlock"

    /**
     The data in the keychain item cannot be accessed after a restart until the device has been unlocked once by the
     user.

     After the first unlock, the data remains accessible until the next restart. This is recommended for items that need
     to be accessed by background applications. Items with this attribute do not migrate to a new device. Thus, after
     restoring from a backup of a different device, these items will not be present.
     */
    case afterFirstUnlockThisDeviceOnly = "kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly"

    /**
     The data in the keychain can only be accessed when the device is unlocked. Only available if a passcode is set on
     the device.

     This is recommended for items that only need to be accessible while the application is in the foreground. Items
     with this attribute never migrate to a new device. After a backup is restored to a new device, these items are
     missing. No items can be stored in this class on devices without a passcode. Disabling the device passcode
     causes all items in this class to be deleted.
     */
    @available(iOS 8, *)
    case whenPasscodeSetThisDeviceOnly = "kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly"

    /**
     The data in the keychain item can be accessed only while the device is unlocked by the user.

     This is recommended for items that need to be accessible only while the application is in the foreground. Items
     with this attribute migrate to a new device when using encrypted backups.

     This is the default value for keychain items added without explicitly setting an accessibility constant.
     */
    case whenUnlocked = "kSecAttrAccessibleWhenUnlocked"

    /**
     The data in the keychain item can be accessed only while the device is unlocked by the user.

     This is recommended for items that need to be accessible only while the application is in the foreground. Items
     with this attribute do not migrate to a new device. Thus, after restoring from a backup of a different device,
     these items will not be present.
     */
    case whenUnlockedThisDeviceOnly = "kSecAttrAccessibleWhenUnlockedThisDeviceOnly"

    func secItemValue() -> CFString {
        switch self {
        case .afterFirstUnlock:
            return kSecAttrAccessibleAfterFirstUnlock
        case .afterFirstUnlockThisDeviceOnly:
            return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        case .whenPasscodeSetThisDeviceOnly:
            return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        case .whenUnlocked:
            return kSecAttrAccessibleWhenUnlocked
        case .whenUnlockedThisDeviceOnly:
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }
    }
}
