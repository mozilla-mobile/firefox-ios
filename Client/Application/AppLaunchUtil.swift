// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import SDWebImage

class AppLaunchUtil {

    func setUpAppLaunchDependencies() {
        // If the 'Save logs to Files app on next launch' toggle
        // is turned on in the Settings app, copy over old logs.
        if DebugSettingsBundleOptions.saveLogsToDocuments {
            Logger.copyPreviousLogsToDocuments()
        }

        // Need to get "settings.sendUsageData" this way so that Sentry can be initialized
        // before getting the Profile.
        let sendUsageData = NSUserDefaultsPrefs(prefix: "profile").boolForKey(AppConstants.PrefSendUsageData) ?? true
        SentryIntegration.shared.setup(sendUsageData: sendUsageData)

        setUserAgent()

        KeyboardHelper.defaultHelper.startObserving()
        DynamicFontHelper.defaultHelper.startObserving()
        MenuHelper.defaultHelper.setItems()

        let logDate = Date()
        // Create a new sync log file on cold app launch. Note that this doesn't roll old logs.
        Logger.syncLogger.newLogWithDate(logDate)
        Logger.browserLogger.newLogWithDate(logDate)
    }

    private func setUserAgent() {
        let firefoxUA = UserAgent.getUserAgent()

        // Set the UA for WKWebView (via defaults), the favicon fetcher, and the image loader.
        // This only needs to be done once per runtime. Note that we use defaults here that are
        // readable from extensions, so they can just use the cached identifier.

        SDWebImageDownloader.shared.setValue(firefoxUA, forHTTPHeaderField: "User-Agent")
        // SDWebImage is setting accept headers that report we support webp. We don't
        SDWebImageDownloader.shared.setValue("image/*;q=0.8", forHTTPHeaderField: "Accept")

        // Record the user agent for use by search suggestion clients.
        SearchViewController.userAgent = firefoxUA

        // Some sites will only serve HTML that points to .ico files.
        // The FaviconFetcher is explicitly for getting high-res icons, so use the desktop user agent.
        FaviconFetcher.userAgent = UserAgent.desktopUserAgent()
    }
}
