// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum URLProvider {

    case production
    case staging

    public var root: URL {
        switch self {
        case .production:
            return URL(string: "https://www.ecosia.org")!
        case .staging:
            return URL(string: "https://www.ecosia-staging.xyz")!
        }
    }

    public var domain: String? {
        if let urlComponents = URLComponents(string: root.absoluteString) {
            if let host = urlComponents.host {
                let domain = host.replacingOccurrences(of: "www.", with: "")
                return domain
            }
        }
        return nil
    }

    public var apiRoot: URL {
        switch self {
        case .production:
            return URL(string: "https://api.ecosia.org")!
        case .staging:
            return URL(string: "https://api.ecosia-staging.xyz")!
        }
    }

    public var snowplow: String {
        switch self {
        case .production:
            return "sp.ecosia.org"
        case .staging:
            return "org-ecosia-prod1.mini.snplow.net"
        }
    }

    var unleash: String {
        switch self {
        case .production:
            return "prod"
        case .staging:
            return "staging"
        }
    }

    public var brazeEndpoint: String {
        "sdk.fra-02.braze.eu"
    }

    public var statistics: URL {
        URL(string: "https://d2wfixp891z15b.cloudfront.net")!
    }

    public var financialReportsData: URL {
        URL(string: "https://s3.amazonaws.com/blog-en.ecosia.org/financial-reports/data.json")!
    }

    public var privacy: URL {
        URL(string: "https://www.ecosia.org/privacy")!
    }

    public var faq: URL {
        URL(string: "https://ecosia.helpscoutdocs.com/")!
    }

    public var terms: URL {
        URL(string: "https://docs.google.com/a/ecosia.org/document/d/1x31-MsVMcl17dK3k80IRPxIj5ZKQEHZPXRhU01H_Xfw/pub")!
    }

    public var aboutCounter: URL {
        URL(string: "https://ecosia.helpscoutdocs.com/article/369-impact-counter")!
    }

    public var bookmarksHelp: URL {
        URL(string: "https://ecosia.helpscoutdocs.com/article/458-import-export-bookmarks")!
    }

    public var referHelp: URL {
        URL(string: "https://ecosia.helpscoutdocs.com/article/358-refer-a-friend-ios-only")!
    }

    public var financialReports: URL {
        switch Language.current {
        case .de:
            return blog.appendingPathComponent("ecosia-finanzberichte-baumplanzbelege/")
        case .fr:
            return blog.appendingPathComponent("rapports-financiers-recus-de-plantations-arbres/")
        default:
            return blog.appendingPathComponent("ecosia-financial-reports-tree-planting-receipts/")
        }
    }

    public var blog: URL {
        switch Language.current {
        case .de:
            return URL(string: "https://de.blog.ecosia.org/")!
        case .fr:
            return URL(string: "https://fr.blog.ecosia.org/")!
        default:
            return URL(string: "https://blog.ecosia.org/")!
        }
    }

    public var trees: URL {
        switch Language.current {
        case .de:
            return blog.appendingPathComponent("tag/projekte/")
        case .fr:
            return blog.appendingPathComponent("tag/projets/")
        default:
            return blog.appendingPathComponent("tag/where-does-ecosia-plant-trees/")
        }
    }

    public var betaProgram: URL {
        switch Language.current {
        case .de:
            return URL(string: "https://ecosia.typeform.com/to/catmFLuA")!
        case .fr:
            return URL(string: "https://ecosia.typeform.com/to/oaFZzT0F")!
        default:
            return URL(string: "https://ecosia.typeform.com/to/EeMLqL3X")!
        }
    }

    public var betaFeedback: URL {
        switch Language.current {
        case .de:
            return URL(string: "https://ecosia.typeform.com/to/pIQ3uwp9")!
        case .fr:
            return URL(string: "https://ecosia.typeform.com/to/PRw7550n")!
        default:
            return URL(string: "https://ecosia.typeform.com/to/LlUGlFT9")!
        }
    }

    public var notifications: URL {
        var components = URLComponents(url: URL(string: "https://api.ecosia.org/v1/notifications")!, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            .init(name: "language", value: Language.current.rawValue),
            .init(name: "market", value: User.shared.marketCode.rawValue),
            .init(name: "limit", value: "50")
        ]
        return components.url!
    }
}
