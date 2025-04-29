// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


public enum OnboardingActions: String, CaseIterable, Codable {
    
    /// Will end the onboarding on a set card
    ///
    case endOnboarding = "end-onboarding"
    
    /// Will take the user to the next card
    ///
    case forwardOneCard = "forward-one-card"
    
    /// Will take the user to the next card
    ///
    case forwardThreeCard = "forward-three-card"
    
    /// Will take the user to the next card
    ///
    case forwardTwoCard = "forward-two-card"
    
    /// Will open up a popup with instructions for something
    ///
    case openInstructionsPopup = "open-instructions-popup"
    
    /// Will take the user to the default browser settings in the iOS system
    /// settings
    ///
    case openIosFxSettings = "open-ios-fx-settings"
    
    /// Will open a webview where the user can read the privacy policy
    ///
    case readPrivacyPolicy = "read-privacy-policy"
    
    /// Will request to allow notifications from the user
    ///
    case requestNotifications = "request-notifications"
    
    /// Will send the user to settings to set Firefox as their default browser and
    /// advance to next card
    ///
    case setDefaultBrowser = "set-default-browser"
    
    /// Will take the user to the sync sign in flow
    ///
    case syncSignIn = "sync-sign-in"
}
