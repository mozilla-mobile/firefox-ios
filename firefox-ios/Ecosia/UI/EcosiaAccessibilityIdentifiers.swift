// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Accessibility identifiers for Ecosia-specific UI elements
public struct EcosiaAccessibilityIdentifiers {
    public static let bannerLogo = "ecosia_logo"

    public struct Account {
        public static let navButton = "account_nav_button"
        public static let seedCountView = "seed_count_view"
        public static let userAvatar = "user_avatar"
        public static let defaultAvatar = "default_avatar"
    }

    public struct NTP {
        public static let rotatingTitle = "ntp_rotating_title"
        public static let headerLogo = "ntp_header_logo"
        public static let customizeButton = "ntp_customize_button"

        public struct ClimateImpact {
            public static let friendsAndTreesInvitesCounter = "friends_and_trees_invites_counter"
            public static let totalTreesCount = "total_trees_count"
            public static let totalInvestedCount = "total_invested_count"
            public static let referralImage = "referral_image"
            public static let totalTreesImage = "total_trees_image"
            public static let totalInvestedImage = "total_invested_image"
        }
    }

    public struct TabToolbar {
        public static let circleButton = "TabToolbar.circleButton"
    }

    public struct FindInPage {
        public static let searchField = "FindInPage.searchField"
        public static let matchCount = "FindInPage.matchCount"
        public static let findPrevious = "FindInPage.find_previous"
        public static let findNext = "FindInPage.find_next"
        public static let findClose = "FindInPage.close"
    }

    public struct Search {
        public static let suggestionCellPrefix = "searchSuggestion"
    }

    public struct AddressBar {
        public static let clearButton = "AddressBar.clearButton"
    }

    public struct OmniboxUpload {
        public static let signInSheetTitle = "omnibox_upload_sign_in_sheet_title"
        public static let signInSheetBody = "omnibox_upload_sign_in_sheet_body"
        public static let signInButton = "omnibox_upload_sign_in_button"
        public static let createAccountButton = "omnibox_upload_create_account_button"

        /// Attachment previews above the omnibox text field. Every id below except
        /// `attachmentsStrip` repeats once per attachment, so a query matches as many
        /// elements as there are tiles rather than exactly one.
        public static let attachmentsStrip = "omnibox_upload_attachments_strip"
        public static let attachmentTile = "omnibox_upload_attachment_tile"
        /// Present only while that tile is still uploading — absence means the upload settled.
        public static let attachmentSpinner = "omnibox_upload_attachment_spinner"
        public static let attachmentFileName = "omnibox_upload_attachment_file_name"
        public static let attachmentFileSize = "omnibox_upload_attachment_file_size"
        public static let attachmentImage = "omnibox_upload_attachment_image"
        public static let attachmentRemoveButton = "omnibox_upload_attachment_remove_button"
    }

    public struct ErrorView {
        public static let image = "error_view_image"
        public static let closeButton = "error_view_close_button"
    }

    /// Wallet-style stacked error toasts (`EcosiaErrorToastStack`). The collapsed and
    /// expanded layouts both exist in the view tree at all times; only the active one
    /// stays in the accessibility tree, so the presence of `expandedStack` is what
    /// distinguishes an expanded stack from a collapsed one.
    public struct ErrorToast {
        public static let container = "ecosia_error_toast_container"
        public static let collapsedStack = "ecosia_error_toast_collapsed_stack"
        public static let expandedStack = "ecosia_error_toast_expanded_stack"
        public static let card = "ecosia_error_toast_card"
    }
}
