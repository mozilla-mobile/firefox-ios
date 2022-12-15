import Foundation

extension Analytics {
    enum Category: String {
        case
        activity,
        browser,
        external,
        migration,
        navigation,
        onboarding,
        invitations,
        ntp,
        menu,
        menuStatus = "menu_status",
        settings
    }
    
    enum Label {
        enum Navigation: String {
            case
            home,
            projects,
            counter,
            howEcosiaWorks = "how_ecosia_works",
            financialReports = "financial_reports",
            shop,
            faq,
            news,
            privacy,
            sendFeedback = "send_feedback",
            terms,
            treecard,
            treestore
        }
        
        enum Browser: String {
            case
            favourites,
            history,
            tabs,
            settings,
            newTab = "new_tab",
            blockImages = "block_images",
            searchbar = "searchbar"
        }
    }
    
    enum Action: String {
        case
        view,
        open,
        receive,
        error,
        completed,
        success,
        retry,
        send,
        claim,
        click,
        change
        
        enum Activity: String {
            case
            launch,
            resume
        }
        
        enum Browser: String {
            case
            open,
            start,
            complete,
            enable,
            disable
        }

        enum Promo: String {
            case
            view,
            click,
            close
        }
    }
    
    enum Property: String {
        case
        home,
        menu,
        toolbar
        
        enum TopSite: String {
            case
            blog,
            privacy,
            financialReports = "financial_reports",
            howEcosiaWorks = "how_ecosia_works"
        }
    }

    enum Migration: String {
        case
        tabs,
        favourites,
        history,
        exception
    }

    enum ShareContent: String {
        case
        ntp,
        web,
        file
    }
}
