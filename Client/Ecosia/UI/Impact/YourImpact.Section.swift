/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import CoreGraphics
import Core

extension YourImpact {
    enum Section: Int, CaseIterable {
        case impact, multiply, explore

        var cell: AnyClass {
            switch self {
            case .impact: return MyImpactCell.self
            case .multiply: return MultiplyImpactCell.self
            case .explore: return EcosiaExploreCell.self
            }
        }

        var title: String? {
            switch self {
            case .multiply:
                return .localized(.groupYourImpact)
            case .explore:
                return .localized(.aboutEcosia)
            default:
                return nil
            }
        }
        
        var height: CGFloat {
            switch self {
            case .impact:
                return 290
            case .multiply:
                return 100
            case .explore:
                return 64
            }
        }
        
        enum Explore: Int, CaseIterable {
            case
            info,
            finance,
            shop,
            trees,
            privacy,
            faq
            
            var title: String {
                switch self {
                case .info:
                    return .localized(.howEcosiaWorks)
                case .finance:
                    return .localized(.financialReports)
                case .trees:
                    return .localized(.treesUpdate)
                case .faq:
                    return .localized(.faqs)
                case .shop:
                    return .localized(.shop)
                case .privacy:
                    return .localized(.privacy)
                }
            }
            
            var subtitle: String {
                switch self {
                case .info:
                    return .localized(.learnHowEcosia)
                case .finance:
                    return .localized(.seeHowMuchMoney)
                case .trees:
                    return .localized(.discoverWhereWe)
                case .faq:
                    return .localized(.findAnswersTo)
                case .shop:
                    return .localized(.buyTShirt)
                case .privacy:
                    return .localized(.learnHowWe)
                }
            }

            var image: String {
                switch self {
                case .info:
                    return "howEcosiaWorks"
                case .finance:
                    return "financialReports"
                case .trees:
                    return "treesUpdate"
                case .faq:
                    return "faqs"
                case .shop:
                    return "ecosiaShop"
                case .privacy:
                    return "privacy"
                }
            }

            var url: URL {
                switch self {
                case .info:
                    return Environment.current.howEcosiaWorks
                case .finance:
                    return Environment.current.financialReports
                case .trees:
                    return Environment.current.trees
                case .faq:
                    return Environment.current.faq
                case .shop:
                    return Environment.current.shop
                case .privacy:
                    return Environment.current.privacy
                }
            }

            var label: Analytics.Label.Navigation {
                switch self {
                case .info:
                    return .howEcosiaWorks
                case .finance:
                    return .financialReports
                case .trees:
                    return .projects
                case .faq:
                    return .faq
                case .shop:
                    return .shop
                case .privacy:
                    return .privacy
                }
            }
            
            var maskedCorners: CACornerMask {
                switch self {
                case .info:
                    return [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                case .faq:
                    return [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                default:
                    return []
                }
            }
        }
    }
}
