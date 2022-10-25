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
        menu
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
            terms
        }
        
        enum Browser: String {
            case
            favourites,
            history,
            tabs,
            settings,
            newTab = "new_tab",
            shareContent = "share_content",
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
            add,
            open,
            edit,
            delete,
            start,
            complete,
            enable,
            disable,
            delete_all = "delete_all",
            sendToFiles = "send_to_files"
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
}
