/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Deferred
import Foundation
import Shared
import SwiftyJSON
import Sync
import XCGLogger

private let log = Logger.syncLogger
class FxAPushMessageHandler {

    let profile: Profile

    init(with profile: Profile) {
        self.profile = profile
    }

    func handle(message: JSON?) {

        guard let json = message else {
            return handleVerification()
        }

        // https://dxr.mozilla.org/mozilla-central/source/mobile/android/services/src/main/java/org/mozilla/gecko/fxa/FxAccountPushHandler.java#19


        // https://github.com/mozilla/fxa-auth-server/blob/master/docs/pushpayloads.schema.json#L26

        let command = json["command"].stringValue
        switch command {
            case "fxaccounts:device_connected":
                handleDeviceConnected(json["data"])
            case "fxaccounts:device_disconnected":
                handleDeviceDisconnected(json["data"])
            case "fxaccounts:profile_updated":
                handleProfileUpdated()
            case "fxaccounts:password_changed":
                handlePasswordChanged()
            case "fxaccounts:password_reset":
                handlePasswordReset()
            case "sync:collection_changed":
                handleCollectionChanged(json["data"])
            default:
                log.warning("Command \(command) received but not recognized")
                break
        }
    }

    func handleVerification() {

        guard let account = profile.getAccount(), account.actionNeeded == .needsVerification else {
            return log.info("Account verified by server either doesn't exist or doesn't need verifying")
        }

        account.advance()
    }

    func handleDeviceConnected(_ data: JSON?) {
        guard let deviceName = data?["deviceName"].string else {
            return log.warning("device_connected received but incomplete: \(data)")
        }
        log.debug("device_connected \(deviceName), unimplemented")
    }

    func handleDeviceDisconnected(_ data: JSON?) {
        guard let deviceID = data?["id"].string else {
            return log.warning("device_disconnected received but incomplete: \(data)")
        }
        log.debug("device_disconnected \(deviceID), unimplemented")
    }

    func handleProfileUpdated() {
        log.debug("profile_updated received but unimplemented")
    }

    func handlePasswordChanged() {
        log.debug("password_changed received but unimplemented")
        profile.getAccount()?.makeSeparated()
    }

    func handlePasswordReset() {
        log.debug("password_reset received but unimplemented")
    }

    func handleCollectionChanged(_ data: JSON?) {
        guard let collections = data?["collections"].arrayObject as? [String] else {
            return log.warning("collections_changed received but incomplete: \(data)")
        }
        let sm = profile.syncManager
        let deferreds = collections.flatMap { (id: String) -> SyncResult? in
            switch id {
            case "addons":
                return nil
            case "forms":
                return nil
            case "prefs":
                return nil
            case "bookmarks":
                return nil
            case "history":
                return sm.syncHistory()
            case "tabs":
                return sm.syncClientsThenTabs()
            case "passwords":
                return sm.syncLogins()
            case "clients":
                // if we get "tabs", "clients" then we'll do "tabs" first, 
                // then "client", but not "tabs" a second time.
                return sm.syncClients()
            default:
                return nil
            }
        }

        let _ = all(deferreds)
    }
/*
         {
            "version": x,
            "command": "fxaccounts:device_connected",
            "data": {
                "deviceName": "string",
            },
         },
         {
            "version": x,
            "command": "fxaccounts:device_disconnected",
            "data": {
                "id": "string"
                "deviceName": "string",
            },
         },
         {
            "version": x,
            "command": "fxaccounts:profile_updated",
         },
         {
            "version": x,
            "command": "fxaccounts:password_changed",
         },
         {
            "version": x,
            "command": "fxaccounts:password_reset",
         },
         
         {
            "version": x,
            "command": "sync:collection_changed",
            "data": {
                "collections": ["addons", "bookmarks", "history", "forms", "prefs",
                                "tabs", "passwords", "clients"],
            },
         },
*/
}
