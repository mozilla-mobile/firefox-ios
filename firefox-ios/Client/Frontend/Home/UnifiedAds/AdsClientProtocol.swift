// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

protocol AdsClientProtocol: AnyObject, Sendable {
    func requestTileAds(mozAdRequests: [MozAdsPlacementRequest],
                        options: MozAdsRequestOptions?) throws -> [String: MozAdsTile]
    func requestImageAds(mozAdRequests: [MozAdsPlacementRequest],
                         options: MozAdsRequestOptions?) throws -> [String: MozAdsImage]
    func requestSpocAds(mozAdRequests: [MozAdsPlacementRequestWithCount],
                        options: MozAdsRequestOptions?) throws -> [String: [MozAdsSpoc]]
    func recordClick(clickUrl: String) throws
    func recordImpression(impressionUrl: String) throws
    func reportAd(reportUrl: String, reason: MozAdsReportReason) throws
}

extension MozAdsClient: AdsClientProtocol {
    func recordClick(clickUrl: String) throws {
        try recordClick(clickUrl: clickUrl, options: nil)
    }

    func recordImpression(impressionUrl: String) throws {
        try recordImpression(impressionUrl: impressionUrl, options: nil)
    }

    func reportAd(reportUrl: String, reason: MozAdsReportReason) throws {
        try reportAd(reportUrl: reportUrl, reason: reason, options: nil)
    }
}
