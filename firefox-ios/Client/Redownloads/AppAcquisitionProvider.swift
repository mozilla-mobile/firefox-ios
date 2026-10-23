// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import StoreKit

struct AppAcquisition: Equatable {
    let originalPurchaseDate: Date
    let originalAppVersion: String
}

enum AcquisitionFailure {
    case unsupportedOS
    case unverified
    case storeKitFailure
}

enum AcquisitionOutcome: Equatable {
    case available(AppAcquisition)
    case unavailable(AcquisitionFailure)
}

@MainActor
protocol AppAcquisitionProviding {
    func fetch() async -> AcquisitionOutcome
}

struct StoreKitAppAcquisitionProvider: AppAcquisitionProviding {
    func fetch() async -> AcquisitionOutcome {
        guard #available(iOS 16.0, *) else {
            return .unavailable(.unsupportedOS)
        }

        do {
            let transactionResult = try await AppTransaction.shared
            switch transactionResult {
            case .verified(let transaction):
                return .available(
                    AppAcquisition(
                        originalPurchaseDate: transaction.originalPurchaseDate,
                        originalAppVersion: transaction.originalAppVersion
                    )
                )
            case .unverified:
                return .unavailable(.unverified)
            }
        } catch {
            return .unavailable(.storeKitFailure)
        }
    }
}
