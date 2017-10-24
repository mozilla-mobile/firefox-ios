/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

public let NotificationDataLoginDidChange = Notification.Name("Data:Login:DidChange")

// add a property to allow the observation of firefox accounts
public let NotificationFirefoxAccountChanged = Notification.Name("FirefoxAccountChangedNotification")

public let NotificationFirefoxAccountProfileChanged = Notification.Name("NotificationFirefoxAccountProfileChanged")

public let NotificationFirefoxAccountDeviceRegistrationUpdated = Notification.Name("FirefoxAccountDeviceRegistrationUpdated")

public let NotificationPrivateDataClearedHistory = Notification.Name("PrivateDataClearedHistoryNotification")

// Fired when the user finishes navigating to a page and the location has changed
public let NotificationOnLocationChange = Notification.Name("OnLocationChange")

// Fired when a the page metadata extraction script has completed and is being passed back to the native client
public let NotificationOnPageMetadataFetched = Notification.Name("OnPageMetadataFetched")

// Fired when the login synchronizer has finished applying remote changes
public let NotificationDataRemoteLoginChangesWereApplied = Notification.Name("NotificationDataRemoteLoginChangesWereApplied")

// Fired when the FxA account has been verified. This should only be fired by the FxALoginStateMachine.
public let NotificationFirefoxAccountVerified = Notification.Name("FirefoxAccountVerifiedNotification")

// MARK: Notification UserInfo Keys
public let NotificationUserInfoKeyHasSyncableAccount = Notification.Name("NotificationUserInfoKeyHasSyncableAccount")

public let NotificationDidRestoreSession = Notification.Name("NotificationDidRestoreSession")
