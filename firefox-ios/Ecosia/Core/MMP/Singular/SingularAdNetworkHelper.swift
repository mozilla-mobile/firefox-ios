// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import StoreKit.SKAdNetwork

#if os(iOS)

protocol SingularAdNetworkHelperProtocol {
    var persistedValuesDictionary: [String: String] { get }
    var isRegistered: Bool { get }

    func registerAppForAdNetworkAttribution() async throws
    func fetchFromSingularServerAndUpdate(forEvent event: SingularEvent, sessionIdentifier: String, appDeviceInfo: AppDeviceInfo) async throws
}

struct SingularAdNetworkHelper: SingularAdNetworkHelperProtocol {

    enum PersistedObject: Hashable, CaseIterable {
        static var allCases: [SingularAdNetworkHelper.PersistedObject] {
            return [
                .firstSkanCallTimestamp, .lastSkanCallTimestamp, .conversionValue, .previousFineValue,
                .coarseValue(window: .first), .coarseValue(window: .second), .coarseValue(window: .third),
                .previousCoarseValue(window: .first), .previousCoarseValue(window: .second), .previousCoarseValue(window: .third),
                .windowLockTimestamp(window: .first), .windowLockTimestamp(window: .second), .windowLockTimestamp(window: .third),
                .errorCode
            ]
        }

        case firstSkanCallTimestamp
        case lastSkanCallTimestamp
        case conversionValue
        case coarseValue(window: SkanWindow)
        case previousFineValue // Only expected to exist for first window
        case previousCoarseValue(window: SkanWindow)
        case windowLockTimestamp(window: SkanWindow)
        case errorCode

        var key: String {
            switch self {
            case .firstSkanCallTimestamp: return "first_skan_call_timestamp"
            case .lastSkanCallTimestamp: return "last_skan_call_timestamp"
            case .conversionValue: return "current_conversion_value"
            case .coarseValue(let window): return "\(window.rawValue)_coarse_value"
            case .previousFineValue: return "prev_fine_value"
            case .previousCoarseValue(let window): return "\(window.rawValue)_prev_coarse_value"
            case .windowLockTimestamp(let window): return "\(window.rawValue)_window_lock_timestamp"
            case .errorCode: return "skan_error_code"
            }
        }

        var queryKey: String {
            switch self {
            case .firstSkanCallTimestamp: return "skan_first_call_to_skadnetwork_timestamp"
            case .lastSkanCallTimestamp: return "skan_last_call_to_skadnetwork_timestamp"
            case .conversionValue: return "skan_current_conversion_value"
            case .coarseValue(let window): return "\(window.rawValue)_coarse"
            case .previousFineValue: return "prev_fine_value"
            case .previousCoarseValue(let window): return "\(window.rawValue)_prev_coarse_value"
            case .windowLockTimestamp(let window): return "\(window.rawValue)_window_lock"
            case .errorCode: return "_skerror"
            }
        }
    }

    enum SkanWindow: String {
        case first = "p0"
        case second = "p1"
        case third = "p2"
        case over

        static let firstSkanWindowInSec = 3600 * 24 * 2
        static let secondSkanWindowInSec = 3600 * 24 * 7
        static let thirdSkanWindowInSec = 3600 * 24 * 35

        init(timeDiff: Int) {
            switch timeDiff {
            case 0...SkanWindow.firstSkanWindowInSec: self = .first
            case SkanWindow.firstSkanWindowInSec...SkanWindow.secondSkanWindowInSec: self = .second
            case SkanWindow.secondSkanWindowInSec...SkanWindow.thirdSkanWindowInSec: self = .third
            default: self = .over
            }
        }
    }

    enum Error: Swift.Error {
        case invalidConversionValues
    }

    private var currentTimestamp: Int {
        return Int(timestampProvider.currentTimestamp)
    }
    var persistedValuesDictionary: [String: String] {
        var dictionary = [String: String]()
        PersistedObject.allCases.forEach { obj in
            if let value = getUserDefaultsInteger(for: obj) {
                dictionary[obj.queryKey] = String(value)
            }
        }
        return dictionary
    }
    var isRegistered: Bool {
        return getUserDefaultsInteger(for: .firstSkanCallTimestamp) != nil
    }

    private let skan: SKAdNetworkProtocol.Type
    private let objectPersister: ObjectPersister
    private let timestampProvider: TimestampProvider
    private let singularService: SingularServiceProtocol

    init(skan: SKAdNetworkProtocol.Type = SKAdNetwork.self,
         objectPersister: ObjectPersister = UserDefaults.standard,
         timestampProvider: TimestampProvider = Date(),
         singularService: SingularServiceProtocol = SingularService()) {
        self.skan = skan
        self.objectPersister = objectPersister
        self.timestampProvider = timestampProvider
        self.singularService = singularService
    }

    func registerAppForAdNetworkAttribution() async throws {
        guard !isRegistered else { return }

        if #available(iOS 15.4, *) {
            do {
                try await skan.updatePostbackConversionValue(0)
            } catch {
                setUserDefaults(for: .errorCode, value: (error as NSError).code)
            }
        } else {
            skan.registerAppForAdNetworkAttribution()
        }
        setUserDefaults(for: .firstSkanCallTimestamp, value: currentTimestamp)
        setUserDefaults(for: .lastSkanCallTimestamp, value: currentTimestamp)
        persistUpdatedValues(fineValue: 0, coarseValue: nil)
    }

    func fetchFromSingularServerAndUpdate(forEvent event: SingularEvent = .session, sessionIdentifier: String, appDeviceInfo: AppDeviceInfo) async throws {
        let firstCallTimestamp = getUserDefaultsInteger(for: .firstSkanCallTimestamp) ?? 0
        guard SkanWindow(timeDiff: currentTimestamp - firstCallTimestamp) != .over else {
            return
        }

        let request = SingularConversionValueRequest(.init(identifier: sessionIdentifier, eventName: event.rawValue, appDeviceInfo: appDeviceInfo),
                                                     skanParameters: persistedValuesDictionary)
        let response = try await singularService.getConversionValue(request: request)
        if !response.isValid {
            throw Error.invalidConversionValues
        }

        let conversionValue = response.conversionValue
        let coarseValue = response.coarseValue
        let lockWindow = response.lockWindow ?? false
        if #available(iOS 16.1, *) {
            try? await skan.updatePostbackConversionValue(conversionValue, coarseValue: coarseValue, lockWindow: lockWindow)
        } else if #available(iOS 15.4, *) {
            try? await skan.updatePostbackConversionValue(conversionValue)
        } else if #available(iOS 14, *) {
            skan.updateConversionValue(conversionValue)
        }
        persistUpdatedValues(fineValue: conversionValue,
                             coarseValue: coarseValue,
                             lockWindow: lockWindow)
    }

    private func persistUpdatedValues(fineValue: Int, coarseValue: Int?, lockWindow: Bool = false) {
        let window = SkanWindow(timeDiff: currentTimestamp - (getUserDefaultsInteger(for: .firstSkanCallTimestamp) ?? 0))
        guard window != .over else { return }

        if window == .first {
            let persistedFineValue: Int? = getUserDefaultsInteger(for: .conversionValue)
            setUserDefaults(for: .conversionValue, value: fineValue)
            setUserDefaults(for: .previousFineValue, value: persistedFineValue)
        }

        let persistedCoarseValue: Int? = getUserDefaultsInteger(for: .coarseValue(window: window))
        setUserDefaults(for: .coarseValue(window: window), value: coarseValue)
        setUserDefaults(for: .previousCoarseValue(window: window), value: persistedCoarseValue)

        if lockWindow {
            setUserDefaults(for: .windowLockTimestamp(window: window), value: currentTimestamp)
        }

        setUserDefaults(for: .lastSkanCallTimestamp, value: currentTimestamp)
    }

    private func setUserDefaults(for object: PersistedObject, value: Int?) {
        objectPersister.set(value, forKey: object.key)
    }

    private func getUserDefaultsInteger(for object: PersistedObject) -> Int? {
        return objectPersister.object(forKey: object.key) as? Int
    }
}

#endif
