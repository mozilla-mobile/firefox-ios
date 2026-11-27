// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

struct NativeErrorPageModel {
    enum Button {
        case tryAgain
        case goBack
    }

    struct Advanced {
        let summary: String
        let details: [String]
        let proceedTitle: String?
    }

    let imageName: String
    let title: String
    let description: String
    let errorCode: Int
    let primaryButton: Button
    let advanced: Advanced?
}

extension NativeErrorPageModel {
    init(errorPage: NativeErrorPageURL) {
        let appName = AppName.shortName.description
        let host = errorPage.originalURL.host ?? errorPage.originalURL.absoluteString

        switch errorPage.type {
        case .noInternet:
            self.init(
                imageName: ImageIdentifiers.NativeErrorPage.kitErrorExclamationMark,
                title: .NativeErrorPage.NoInternet.TitleLabel,
                description: .NativeErrorPage.NoInternet.Description,
                errorCode: errorPage.errorCode,
                primaryButton: .tryAgain,
                advanced: nil
            )

        case .noResponse:
            self.init(
                imageName: ImageIdentifiers.NativeErrorPage.kitErrorExclamationMark,
                title: .NativeErrorPage.NoResponse.TitleLabel,
                description: String(format: .NativeErrorPage.NoResponse.Description, host),
                errorCode: errorPage.errorCode,
                primaryButton: .tryAgain,
                advanced: nil
            )

        case .vpn:
            self.init(
                imageName: ImageIdentifiers.NativeErrorPage.kitErrorExclamationMark,
                title: .VPN.ErrorPage.Title,
                description: .VPN.ErrorPage.Body,
                errorCode: errorPage.errorCode,
                primaryButton: .tryAgain,
                advanced: nil
            )

        case .badCert:
            self = Self.badCert(errorPage: errorPage, appName: appName, host: host)

        // TODO: Wayback will get its own page once it's redesigned
        case .generic, .wayback:
            self.init(
                imageName: ImageIdentifiers.NativeErrorPage.kitErrorExclamationMark,
                title: .NativeErrorPage.Generic.TitleLabel,
                description: String(format: .NativeErrorPage.Generic.Description, appName, host),
                errorCode: errorPage.errorCode,
                primaryButton: .tryAgain,
                advanced: nil
            )
        }
    }

    private static func badCert(
        errorPage: NativeErrorPageURL,
        appName: String,
        host: String
    ) -> NativeErrorPageModel {
        let description: String
        let summary: String
        let details: [String]

        // TODO: Add cases for the other cert errors
        switch errorPage.errorCode {
        default:
            description = .NativeErrorPage.Security.BadCert.Description
            summary = .NativeErrorPage.Security.Advanced.Summary
            details = [
                String(format: .NativeErrorPage.Security.BadCert.NotValidForSite, appName, host),
                .NativeErrorPage.Security.BadCert.NetworkTip
            ]
        }

        return NativeErrorPageModel(
            imageName: ImageIdentifiers.NativeErrorPage.kitErrorExclamationMark,
            title: .NativeErrorPage.Security.TitleLabel,
            description: description,
            errorCode: errorPage.errorCode,
            primaryButton: .goBack,
            advanced: Advanced(
                summary: summary,
                details: details,
                proceedTitle: errorPage.certificateData == nil
                    ? nil
                    : String(format: .NativeErrorPage.Security.Advanced.ProceedButton, host)
            )
        )
    }
}
