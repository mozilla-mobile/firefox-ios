//
//  TelemetryIntegration.swift
//  Blockzilla
//
//  Created by Justin D'Arcangelo on 5/11/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation

class TelemetryEventCategory {
    public static let action = "action"
}

class TelemetryEventMethod {
    public static let background = "background"
    public static let foreground = "foreground"
    public static let typeURL = "type_url"
    public static let typeQuery = "type_query"
    public static let selectQuery = "select_query"
    public static let click = "click"
    public static let change = "change"
    public static let open = "open"
    public static let show = "show"
    public static let coinFlip = "coin_flip"
    public static let close = "close"
    public static let cancel = "cancel"
    public static let openAppStore = "open_app_store"
    public static let openedFromExtension = "opened_from_extension"
    public static let share = "share"
    public static let customDomainRemoved = "removed"
    public static let customDomainReordered = "reordered"
    public static let drag = "drag"
    public static let drop = "drop"
    public static let siri = "siri"
}

class TelemetryEventObject {
    public static let app = "app"
    public static let searchBar = "search_bar"
    public static let eraseButton = "erase_button"
    public static let findInPageBar = "find_in_page_bar"
    public static let findNext = "find_next"
    public static let findPrev = "find_prev"
    public static let onboarding = "ios_onboarding_v1"
    public static let firstRun = "previous_first_run"
    public static let settingsButton = "settings_button"
    public static let setting = "setting"
    public static let menu = "menu"
    public static let customDomain = "custom_domain"
    public static let pasteAndGo = "paste_and_go"
    public static let requestHandler = "request_handler"
    public static let trackingProtectionDrawer = "tracking_protection_drawer"
    public static let trackingProtectionToggle = "tracking_protection_toggle"
    public static let websiteLink = "website_link"
    public static let autofill = "autofill"
    public static let trackerStatsShareButton = "tracker_stats_share_button"
    public static let quickAddCustomDomainButton = "quick_add_custom_domain_button"
    public static let requestDesktop = "request_desktop"
    public static let openFavoriteSite = "open_favorite_site"
    public static let eraseAndOpen = "erase_and_open"
    public static let eraseInBackground = "erase_in_background"
    public static let autocompleteTip = "autocomplete_tip"
    public static let sitesNotWorkingTip = "tracking_protection_tip"
    public static let biometricTip = "biometric_tip"
    public static let requestDesktopTip = "request_desktop_tip"
    public static let siriFavoriteTip = "siri_favorite_tip"
    public static let siriEraseTip = "siri_erase_tip"
}
