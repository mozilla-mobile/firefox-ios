// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


public enum OnboardingMultipleChoiceAction: String, CaseIterable, Codable {
    
    /// Will will set the theme to dark mode
    ///
    case themeDark = "theme-dark"
    
    /// Will set the theme to light mode
    ///
    case themeLight = "theme-light"
    
    /// Will set the theme to use the system theme
    ///
    case themeSystemDefault = "theme-system-default"
    
    /// Will set the toolbar on the bottom
    ///
    case toolbarBottom = "toolbar-bottom"
    
    /// Will set the toolbar on the top
    ///
    case toolbarTop = "toolbar-top"
}
