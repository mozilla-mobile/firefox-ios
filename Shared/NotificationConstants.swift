/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

extension Notification.Name {

    public static let DataLoginDidChange = Notification.Name("DataLoginDidChange")

    // add a property to allow the observation of firefox accounts
    public static let FirefoxAccountChanged = Notification.Name("FirefoxAccountChanged")

    public static let FirefoxAccountProfileChanged = Notification.Name("FirefoxAccountProfileChanged")

    public static let FirefoxAccountDeviceRegistrationUpdated = Notification.Name("FirefoxAccountDeviceRegistrationUpdated")

    public static let PrivateDataClearedHistory = Notification.Name("PrivateDataClearedHistory")

    // Fired when the user finishes navigating to a page and the location has changed
    public static let OnLocationChange = Notification.Name("OnLocationChange")

    // Fired when a the page metadata extraction script has completed and is being passed back to the native client
    public static let OnPageMetadataFetched = Notification.Name("OnPageMetadataFetched")

    // Fired when the login synchronizer has finished applying remote changes
    public static let DataRemoteLoginChangesWereApplied = Notification.Name("DataRemoteLoginChangesWereApplied")

    // Fired when the FxA account has been verified. This should only be fired by the FxALoginStateMachine.
    public static let FirefoxAccountVerified = Notification.Name("FirefoxAccountVerified")

    // MARK: Notification UserInfo Keys
    public static let UserInfoKeyHasSyncableAccount = Notification.Name("UserInfoKeyHasSyncableAccount")

    public static let DidRestoreSession = Notification.Name("DidRestoreSession")

    public static let ContentBlockerUpdateNeeded = Notification.Name("ContentBlockerUpdateNeeded")

    public static let LocationChange = Notification.Name("OnLocationChange")

    public static let DynamicFontChanged = Notification.Name("DynamicFontChanged")
    public static let PasscodeDidChange = Notification.Name("PasscodeDidChange")
    public static let PasscodeDidCreate = Notification.Name("PasscodeDidCreate")
    public static let PasscodeDidRemove = Notification.Name("PasscodeDidRemove")

    public static let DatabaseWasRecreated = Notification.Name("DatabaseWasRecreated")

    public static let ReachabilityStatusChanged = Notification.Name("ReachabilityStatusChanged")

    public static let UserInitiatedSyncManually = Notification.Name("UserInitiatedSyncManually")

    public static let ProfileDidStartSyncing = Notification.Name("ProfileDidStartSyncing")
    public static let ProfileDidFinishSyncing = Notification.Name("ProfileDidFinishSyncing")

    public static let BookmarkBufferValidated = Notification.Name("BookmarkBufferValidated")

    public static let FaviconDidLoad = Notification.Name("FaviconManagerFaviconDidLoad")

    public static let BookmarkStatusChanged = Notification.Name("BookmarkStatusChanged")

}
