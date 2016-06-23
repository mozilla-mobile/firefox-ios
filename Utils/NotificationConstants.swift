/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

public let NotificationDataLoginDidChange = "Data:Login:DidChange"

// add a property to allow the observation of firefox accounts
public let NotificationFirefoxAccountChanged = "FirefoxAccountChangedNotification"

public let NotificationPrivateDataClearedHistory = "PrivateDataClearedHistoryNotification"

// Fired when the user finishes navigating to a page and the location has changed
public let NotificationOnLocationChange = "OnLocationChange"

// Fired when the login synchronizer has finished applying remote changes
public let NotificationDataRemoteLoginChangesWereApplied = "NotificationDataRemoteLoginChangesWereApplied"

// MARK: Notification UserInfo Keys
public let NotificationUserInfoKeyHasSyncableAccount = "NotificationUserInfoKeyHasSyncableAccount"