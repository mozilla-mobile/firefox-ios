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
    public static let click = "click"
    public static let change = "change"
    public static let open = "open"
    public static let openAppStore = "open_app_store"
    public static let share = "share"
    public static let swipeToNavigateBack = "swipe_to_navigate_back"
    public static let swipeToNavigateForward = "swipe_to_navigate_forward"
}

class TelemetryEventObject {
    public static let app = "app"
    public static let searchBar = "search_bar"
    public static let eraseButton = "erase_button"
    public static let settingsButton = "settings_button"
    public static let setting = "setting"
    public static let menu = "menu"
    public static let pasteAndGo = "paste_and_go"
}
