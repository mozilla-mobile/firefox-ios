// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension Analytics {
    enum Category: String {
        case
        activity,
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
        newsletterExperiment = "newsletter_experiment",
        ntp,
        pushNotificationConsent = "push_notification_consent",
        settings
    }

    enum Label: String {
        case
        analytics,
        market,
        toolbar

        enum Bookmarks: String {
            case
            importFunctionality = "import_functionality",
            learnMore = "learn_more",
            `import`
        }

        enum DefaultBrowser: String {
            case
            deeplink = "default_browser_deeplink",
            promo = "default_browser_promo",
            settings = "default_browser_settings"
        }

        enum Menu: String {
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

        enum MenuStatus: String {
            case
            bookmark,
            darkMode = "dark_mode",
            readingList = "reading_list",
            shortcut
        }

        enum Migration: String {
            case
            tabs
        }

        enum Navigation: String {
            case
            inapp,
            financialReports = "financial_reports",
            news,
            privacy,
            projects,
            sendFeedback = "send_feedback",
            terms
        }

        enum NewsletterCardExperiment: String {
            case
            ntpCard = "ntp_card"
        }

        enum NTP: String {
            case
            about,
            climateCounter = "climate_counter",
            customize,
            impact,
            news,
            onboardingCard = "onboarding_card",
            quickActions = "quick_actions",
            topSites = "top_sites"
        }

        enum Onboarding: String {
            case
            next,
            skip
        }

        enum Referral: String {
            case
            invite,
            inviteScreen = "invite_screen",
            learnMore = "learn_more",
            linkCopying = "link_copying",
            promo
        }
    }

    enum Action: String {
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

        enum Activity: String {
            case
            launch,
            resume
        }

        enum APNConsent: String {
            case
            allow,
            deny,
            error,
            view
        }

        enum Bookmarks: String {
            case
            `import`
        }

        enum BrazeIAM: String {
            case
            click,
            dismiss,
            view
        }

        enum NewsletterCardExperiment: String {
            case
            click,
            dismiss,
            view
        }

        enum NTPCustomization: String {
            case
            click,
            disable,
            enable
        }

        enum Promo: String {
            case
            click,
            close,
            view
        }

        enum Referral: String {
            case
            claim,
            click,
            open,
            send,
            view
        }

        enum SeedCounter: String {
            case
            level,
            collect,
            click
        }

        enum TopSite: String {
            case
            click,
            openNewTab = "open_new_tab",
            openPrivateTab = "open_private_tab",
            pin,
            remove,
            unpin
		}
    }

    enum Property: String {
        case
        enable,
        disable,
        home

        enum APNConsent: String {
            case
            home,
            onLaunchPrompt = "on_launch_prompt"
        }

        enum Bookmarks: String {
            case
            `import`,
            export,
            emptyState = "empty_state",
            success,
            error
        }

        enum Library: String {
            case
            bookmarks,
            downloads,
            history,
            readingList = "reading_list"
        }

        enum OnboardingPage: String, CaseIterable {
            case
            start,
            profits,
            action,
            greenSearch = "green_search",
            transparentFinances = "transparent_finances"
        }

        enum ShareContent: String {
            case
            ntp,
            web,
            file
        }

        enum TopSite: String {
            case
            `default`,
            mostVisited = "most_visited",
            pinned
        }
    }
}
