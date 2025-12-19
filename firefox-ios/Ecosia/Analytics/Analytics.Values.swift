// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension Analytics {
    public enum Category: String {
        case
        account,
        activity,
        autocomplete = "autocomplete_suggestion",
        bookmarks,
        brazeIAM = "braze_iam",
        browser,
        external,
        intro,
        invitations,
        menu,
        menuStatus = "menu_status",
        migration,
        navigation,
        ntp,
        pushNotificationConsent = "push_notification_consent",
        settings
    }

    public enum Label: String {
        case
        analytics,
        accountNudgeCard = "account_nudge_card",
        clear,
        close,
        market,
        profile,
        signIn = "sign_in",
        signUp = "sign_up",
        toolbar

        public enum Bookmarks: String {
            case
            importFunctionality = "import_functionality",
            learnMore = "learn_more",
            `import`
        }

        public enum DefaultBrowser: String {
            case
            deeplink = "default_browser_deeplink",
            promo = "default_browser_promo",
            settings = "default_browser_settings",
            settingsNudgeCard = "default_browser_settings_nudge_card"
        }

        public enum Menu: String {
            case
            bookmarks,
            copyLink = "copy_link",
            customizeHomepage = "customize_homepage",
            downloads,
            findInPage = "find_in_page",
            help,
            history,
            home,
            newTab = "new_tab",
            openInSafari = "open_in_safari",
            readingList = "reading_list",
            requestDesktopSite = "request_desktop_site",
            settings,
            share,
            zoom
        }

        public enum MenuStatus: String {
            case
            bookmark,
            darkMode = "dark_mode",
            readingList = "reading_list",
            shortcut
        }

        public enum Migration: String {
            case
            tabs
        }

        public enum Navigation: String {
            case
            help,
            inapp,
            market,
            news,
            privacy,
            projects,
            sendFeedback = "send_feedback",
            terms
        }

        public enum NTP: String {
            case
            climateCounter = "climate_counter",
            customize,
            impact,
            news,
            onboardingCard = "onboarding_card",
            quickActions = "quick_actions",
            topSites = "top_sites"
        }

        public enum Onboarding: String {
            case
            next,
            skip
        }

        public enum Referral: String {
            case
            invite,
            inviteScreen = "invite_screen",
            learnMore = "learn_more",
            linkCopying = "link_copying",
            promo
        }

        public enum Settings: String {
            case
            aiOverviews = "ai_overviews",
            analytics,
            clear,
            toolbar
        }

        public enum AISearch: String {
            case
            cta = "ai_search_cta"
        }
    }

    public enum Action: String {
        case
        change,
        click,
        disable,
        dismiss,
        display,
        enable,
        error,
        open,
        receive,
        success,
        view

        public enum Activity: String {
            case
            launch,
            resume
        }

        public enum APNConsent: String {
            case
            allow,
            deny,
            error,
            view
        }

        public enum Bookmarks: String {
            case
            `import`
        }

        public enum BrazeIAM: String {
            case
            click,
            dismiss,
            view
        }

        public enum NewsletterCardExperiment: String {
            case
            click,
            dismiss,
            view
        }

        public enum NTPCustomization: String {
            case
            click,
            disable,
            enable
        }

        public enum Promo: String {
            case
            click,
            close,
            view
        }

        public enum Referral: String {
            case
            claim,
            click,
            open,
            send,
            view
        }

        public enum SeedCounter: String {
            case
            level,
            collect,
            click
        }

        public enum TopSite: String {
            case
            click,
            openNewTab = "open_new_tab",
            openPrivateTab = "open_private_tab",
            pin,
            remove,
            unpin
		}
    }

    public enum Property: String {
        case
        account,
        cancel,
        enable,
        disable,
        header,
        home,
        detail,
        menu,
        nativeSettings = "native_settings",
        signOut = "sign_out"

        public enum APNConsent: String {
            case
            home,
            onLaunchPrompt = "on_launch_prompt"
        }

        public enum Bookmarks: String {
            case
            `import`,
            export,
            emptyState = "empty_state",
            success,
            error
        }

        public enum Library: String {
            case
            bookmarks,
            downloads,
            history,
            readingList = "reading_list"
        }

        public enum OnboardingPage: String, CaseIterable {
            case
            start,
            profits,
            action,
            greenSearch = "green_search",
            transparentFinances = "transparent_finances"
        }

        public enum ShareContent: String {
            case
            ntp,
            web,
            file
        }

        public enum TopSite: String {
            case
            `default`,
            mostVisited = "most_visited",
            pinned
        }

        public enum SettingsPrivateDataSection: String {
            case
            websites = "websites_data",
            main = "all_private_data"
        }
    }
}
