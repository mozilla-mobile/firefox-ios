/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

extension Notification.Name {
    public static let DataLoginDidChange = Notification.Name("DataLoginDidChange")

    // add a property to allow the observation of firefox accounts
    public static let FirefoxAccountChanged = Notification.Name("FirefoxAccountChanged")

    public static let FirefoxAccountStateChange = Notification.Name("FirefoxAccountStateChange")

    public static let RegisterForPushNotifications = Notification.Name("RegisterForPushNotifications")

    public static let FirefoxAccountProfileChanged = Notification.Name("FirefoxAccountProfileChanged")

    public static let FirefoxAccountDeviceRegistrationUpdated = Notification.Name("FirefoxAccountDeviceRegistrationUpdated")

    public static let PrivateDataClearedHistory = Notification.Name("PrivateDataClearedHistory")
    public static let PrivateDataClearedDownloadedFiles = Notification.Name("PrivateDataClearedDownloadedFiles")

    // Fired when the user finishes navigating to a page and the location has changed
    public static let OnLocationChange = Notification.Name("OnLocationChange")
  
    // MARK: Notification UserInfo Keys
    public static let UserInfoKeyHasSyncableAccount = Notification.Name("UserInfoKeyHasSyncableAccount")

    // Fired when the login synchronizer has finished applying remote changes
    public static let DataRemoteLoginChangesWereApplied = Notification.Name("DataRemoteLoginChangesWereApplied")

    // Fired when a the page metadata extraction script has completed and is being passed back to the native client
    public static let OnPageMetadataFetched = Notification.Name("OnPageMetadataFetched")

    public static let ProfileDidStartSyncing = Notification.Name("ProfileDidStartSyncing")
    public static let ProfileDidFinishSyncing = Notification.Name("ProfileDidFinishSyncing")

    public static let DatabaseWasRecreated = Notification.Name("DatabaseWasRecreated")
    public static let DatabaseWasClosed = Notification.Name("DatabaseWasClosed")
    public static let DatabaseWasReopened = Notification.Name("DatabaseWasReopened")

    public static let PasscodeDidChange = Notification.Name("PasscodeDidChange")

    public static let PasscodeDidCreate = Notification.Name("PasscodeDidCreate")

    public static let PasscodeDidRemove = Notification.Name("PasscodeDidRemove")

    public static let DynamicFontChanged = Notification.Name("DynamicFontChanged")

    public static let UserInitiatedSyncManually = Notification.Name("UserInitiatedSyncManually")

    public static let FaviconDidLoad = Notification.Name("FaviconDidLoad")

    public static let ReachabilityStatusChanged = Notification.Name("ReachabilityStatusChanged")

    public static let HomePanelPrefsChanged = Notification.Name("HomePanelPrefsChanged")

    public static let FileDidDownload = Notification.Name("FileDidDownload")

    public static let DisplayThemeChanged = Notification.Name("DisplayThemeChanged")
}
