// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import WebCompatReporterKit

/// One property per Glean metric in `broken_site_report.yaml`, so the field names
/// live in one place. The struct is flat; each comment below is the Glean category
/// the fields under it belong to.
struct WebCompatReportPayload: Equatable {
    // broken_site_report
    var url: String?
    var breakageCategory: String?
    var description: String?
    // broken_site_report.tab_info
    var languages: [String]?
    var userAgentString: String?
    // broken_site_report.tab_info.antitracking
    var blockList: String?
    var blockedOrigins: [String]?
    var etpCategory: String?
    var isPrivateBrowsing: Bool?
    // broken_site_report.tab_info.frameworks
    var fastclick: Bool?
    var marfeel: Bool?
    var mobify: Bool?
    // broken_site_report.browser_info.app
    var defaultLocales: [String]?
    var defaultUserAgentString: String?
    // broken_site_report.browser_info.graphics
    var devicePixelRatio: String?
    var hasTouchScreen: Bool?
    // broken_site_report.browser_info.system
    var isTablet: Bool?
    var memory: Int?

    /// Only what the user typed or picked; send-time data stays nil. The sub-option
    /// wins over the category as the more specific answer.
    static func make(from state: WebCompatReporterState) -> WebCompatReportPayload {
        var payload = WebCompatReportPayload()
        payload.url = state.url.isEmpty ? nil : state.url
        payload.breakageCategory = state.selectedSubOptionID ?? state.selectedCategory?.rawValue
        let details = state.additionalDetails.trimmingCharacters(in: .whitespacesAndNewlines)
        payload.description = details.isEmpty ? nil : details
        return payload
    }

    struct PreviewField {
        enum Key: String {
            case description
            case reason
            case url
            case languages
            case useragentString
            case blockList
            case blockedOrigins
            case etpCategory
            case isPrivateBrowsing
            case fastclick
            case marfeel
            case mobify
            case defaultLocales
            case defaultUseragentString
            case isTablet
            case memory
            case devicePixelRatio
            case hasTouchScreen
        }

        let key: Key
        let value: WebCompatTechnicalDataViewModel.PreviewValue
    }

    struct PreviewGroup {
        enum Identifier: String {
            case basic
            case tabInfo
            case antiTracking
            case frameworks
            case app
            case system
            case graphics
        }

        let id: Identifier
        let fields: [PreviewField]
    }

    /// Projected from this struct, not from Redux state, so the preview can only show what gets sent.
    var previewGroups: [PreviewGroup] {
        return [
            PreviewGroup(id: .basic, fields: [
                PreviewField(key: .description, value: previewValue(description)),
                PreviewField(key: .reason, value: previewValue(breakageCategory)),
                PreviewField(key: .url, value: previewValue(url))
            ]),
            PreviewGroup(id: .tabInfo, fields: [
                PreviewField(key: .languages, value: previewValue(languages)),
                PreviewField(key: .useragentString, value: previewValue(userAgentString))
            ]),
            PreviewGroup(id: .antiTracking, fields: [
                PreviewField(key: .blockList, value: previewValue(blockList)),
                PreviewField(key: .blockedOrigins, value: previewValue(blockedOrigins)),
                PreviewField(key: .etpCategory, value: previewValue(etpCategory)),
                PreviewField(key: .isPrivateBrowsing, value: previewValue(isPrivateBrowsing))
            ]),
            PreviewGroup(id: .frameworks, fields: [
                PreviewField(key: .fastclick, value: previewValue(fastclick)),
                PreviewField(key: .marfeel, value: previewValue(marfeel)),
                PreviewField(key: .mobify, value: previewValue(mobify))
            ]),
            PreviewGroup(id: .app, fields: [
                PreviewField(key: .defaultLocales, value: previewValue(defaultLocales)),
                PreviewField(key: .defaultUseragentString, value: previewValue(defaultUserAgentString))
            ]),
            PreviewGroup(id: .system, fields: [
                PreviewField(key: .isTablet, value: previewValue(isTablet)),
                PreviewField(key: .memory, value: previewValue(memory))
            ]),
            PreviewGroup(id: .graphics, fields: [
                PreviewField(key: .devicePixelRatio, value: previewValue(devicePixelRatio)),
                PreviewField(key: .hasTouchScreen, value: previewValue(hasTouchScreen))
            ])
        ]
    }

    func makeReportPreviewViewModel() -> WebCompatReportPreviewViewModel {
        return WebCompatReportPreviewViewModel(
            title: .WebCompatReporter.Preview.Title,
            closeAccessibilityLabel: .WebCompatReporter.Sheet.CloseButtonAccessibilityLabel,
            closeA11yIdentifier: AccessibilityIdentifiers.WebCompatReporter.Preview.closeButton,
            bullets: summaryBullets,
            bulletsA11yIdentifier: AccessibilityIdentifiers.WebCompatReporter.Preview.summary,
            technicalDataTitle: .WebCompatReporter.Preview.TechnicalData,
            technicalDataA11yIdentifier: AccessibilityIdentifiers.WebCompatReporter.Preview.technicalDataRow
        )
    }

    private var summaryBullets: [String] {
        let collectedKeys = Set(
            previewGroups
                .flatMap { $0.fields }
                .filter { carriesData($0.value) }
                .map { $0.key }
        )
        let userAgent = String(
            format: .WebCompatReporter.Preview.Data.UserAgent,
            AppName.shortName.rawValue
        )
        let bullets: [(text: String, keys: [PreviewField.Key])] = [
            (pageURLBullet, [.url]),
            (.WebCompatReporter.Preview.Data.IssueAndDescription, [.reason, .description]),
            (.WebCompatReporter.Preview.Data.IsTablet, [.isTablet]),
            (userAgent, [.useragentString, .defaultUseragentString]),
            (.WebCompatReporter.Preview.Data.TrackingProtectionSetting, [.blockList, .etpCategory]),
            (.WebCompatReporter.Preview.Data.BlockedTrackers, [.blockedOrigins]),
            (.WebCompatReporter.Preview.Data.PrivateBrowsingStatus, [.isPrivateBrowsing]),
            (.WebCompatReporter.Preview.Data.AvailableMemory, [.memory]),
            (.WebCompatReporter.Preview.Data.PixelDensity, [.devicePixelRatio]),
            (.WebCompatReporter.Preview.Data.HasTouchscreen, [.hasTouchScreen]),
            (.WebCompatReporter.Preview.Data.PageLanguages, [.languages]),
            (.WebCompatReporter.Preview.Data.DeviceLocale, [.defaultLocales]),
            (.WebCompatReporter.Preview.Data.PageElements, [.fastclick, .marfeel, .mobify])
        ]
        return bullets
            .filter { bullet in bullet.keys.contains(where: collectedKeys.contains) }
            .map { $0.text }
    }

    /// An empty list is still sent, so it prints in Technical Data but earns no bullet here.
    private func carriesData(_ value: WebCompatTechnicalDataViewModel.PreviewValue) -> Bool {
        switch value {
        case .null:
            return false
        case .list(let values):
            return !values.isEmpty
        case .string, .bool, .quantity:
            return true
        }
    }

    /// A line separator, not a newline: same paragraph, so the address keeps the indent and no dot.
    private var pageURLBullet: String {
        let label: String = .WebCompatReporter.Preview.Data.PageURL
        guard let url else { return label }
        return "\(label)\u{2028}[\(url)]"
    }

    func makeTechnicalDataViewModel() -> WebCompatTechnicalDataViewModel {
        return WebCompatTechnicalDataViewModel(
            title: .WebCompatReporter.Preview.TechnicalData,
            closeAccessibilityLabel: .WebCompatReporter.Sheet.CloseButtonAccessibilityLabel,
            closeA11yIdentifier: AccessibilityIdentifiers.WebCompatReporter.Preview.closeButton,
            sections: previewGroups.map { group in
                let groupID = group.id.rawValue
                return WebCompatTechnicalDataViewModel.PreviewSection(
                    id: groupID,
                    title: groupID,
                    a11yIdentifier: "\(AccessibilityIdentifiers.WebCompatReporter.Preview.sectionHeader).\(groupID)",
                    contentA11yIdentifier:
                        "\(AccessibilityIdentifiers.WebCompatReporter.Preview.sectionContent).\(groupID)",
                    rows: group.fields.map { field in
                        WebCompatTechnicalDataViewModel.PreviewRow(
                            id: "\(groupID).\(field.key.rawValue)",
                            label: field.key.rawValue,
                            value: field.value
                        )
                    }
                )
            }
        )
    }

    private func previewValue(_ text: String?) -> WebCompatTechnicalDataViewModel.PreviewValue {
        guard let text, !text.isEmpty else { return .null }
        return .string(text)
    }

    private func previewValue(_ values: [String]?) -> WebCompatTechnicalDataViewModel.PreviewValue {
        guard let values else { return .null }
        return .list(values)
    }

    private func previewValue(_ flag: Bool?) -> WebCompatTechnicalDataViewModel.PreviewValue {
        guard let flag else { return .null }
        return .bool(flag)
    }

    private func previewValue(_ number: Int?) -> WebCompatTechnicalDataViewModel.PreviewValue {
        guard let number else { return .null }
        return .quantity(number)
    }
}
