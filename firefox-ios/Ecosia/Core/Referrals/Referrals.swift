// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The `Referrals` class is responsible for handling referral-related operations,
/// including refreshing referral codes, creating new codes, and claiming referrals.
public class Referrals: Publisher {

    /// Subscriptions to the referral model updates.
    public var subscriptions = [Subscription<Referrals.Model>]()

    /// Deeplink to enter the Referral's claim
    public static let deepLinkPath = "ecosia://invite/"

    /// Link shown in the Modal screen as well as the invite message
	public static let sharingLinkRoot = "https://ecosia.co/app?referrer="

    /// The HTTP client used for performing network requests.
    let client: HTTPClient

    /// Initializes a new instance of `Referrals` with the specified HTTP client.
    /// - Parameter client: The HTTP client to use. Defaults to `URLSessionHTTPClient`.
    public init(client: HTTPClient = URLSessionHTTPClient()) {
        self.client = client
    }

    /// Indicates whether the referral information needs to be updated.
    var needsUpdate: Bool {
        return Calendar.current.dateComponents([.hour], from: User.shared.referrals.updated, to: .init()).hour! >= 24
    }

    /// Indicates whether the referral information is currently being refreshed.
    var isRefreshing = false

    /// Refreshes the referral information.
    /// - Parameters:
    ///   - force: A Boolean value indicating whether to force a refresh. Defaults to `false`.
    ///   - createCode: A Boolean value indicating whether to create a new code if one does not exist. Defaults to `false`.
    /// - Throws: An error if the refresh operation fails.
    public func refresh(force: Bool = false, createCode: Bool = false) async throws {
        // Check if code is present
        guard let code = User.shared.referrals.code else {
            // only fetch new code if desired
            guard createCode else {
                return
            }

            let info = try await self.fetchCode()
            await self.update(info)
            return
        }

        // only refresh if forced or needed
        guard force || needsUpdate else {
            return
        }

        guard !isRefreshing else {
            return
        }
        isRefreshing = true
        defer {
            self.isRefreshing = false
        }

        // Refresh count for given code
        do {
            let info = try await self.refreshCode(code)
            await self.update(info)
        } catch {
            await self.updateErrorDate()
            throw error
        }
    }

    /// Creates a new referral code.
    /// - Returns: The created referral code information.
    /// - Throws: An error if the creation operation fails.
    func createCode() async throws -> CodeInfo {
        let request = ReferralCreateCodeRequest()
        let (data, response) = try await client.perform(request)
        guard response != nil else {
            throw Referrals.Error.noConnection
        }
        return try JSONDecoder().decode(CodeInfo.self, from: data)
    }

    /// Fetches the referral code information.
    /// - Returns: The fetched referral code information.
    /// - Throws: An error if the fetch operation fails.
    func fetchCode() async throws -> CodeInfo {
        // pretend success if we have a code already
        if let code = User.shared.referrals.code {
            return .init(code: code, claims: User.shared.referrals.claims)
        }
        return try await createCode()
    }

    /// Refreshes the referral code information.
    /// - Parameter code: The referral code to refresh.
    /// - Returns: The refreshed referral code information.
    /// - Throws: An error if the refresh operation fails.
    func refreshCode(_ code: String) async throws -> CodeInfo {
        let request = ReferralRefreshCodeRequest(code: code)
        let (data, response) = try await client.perform(request)
        guard let response = response else {
            throw Referrals.Error.noConnection
        }
        switch response.statusCode {
        case Referrals.Error.notFound.rawValue:
            return try await createCode()
        case 200:
            return try JSONDecoder().decode(CodeInfo.self, from: data)
        default:
            let error: Referrals.Error? = .init(rawValue: response.statusCode)
            throw error ?? .genericError
        }
    }

    /// Claims a referral using the specified referrer.
    /// - Parameter referrer: The referrer identifier.
    /// - Throws: An error if the claim operation fails.
    public func claim(referrer: String) async throws {
        var code: String
        if let storedCode = User.shared.referrals.code {
            code = storedCode
        } else {
            let info = try await self.fetchCode()
            await self.update(info)
            code = info.code
        }
        try await self.claim(referrer: referrer, claim: code)
        await self.storeClaim()
    }

    /// Claims a referral using the specified referrer and claim code.
    /// - Parameters:
    ///   - referrer: The referrer identifier.
    ///   - claim: The claim code.
    /// - Throws: An error if the claim operation fails.
    private func claim(referrer: String, claim: String) async throws {
        let request = ReferralClaimRequest(referrer: referrer, claim: claim)
        let (_, response) = try await client.perform(request)
        guard let response = response else {
            throw Referrals.Error.noConnection
        }
        guard response.statusCode == 201 else {
            let error: Referrals.Error? = .init(rawValue: response.statusCode)
            throw error ?? .genericError
        }
    }

    /// Updates the date on error to refresh the cooldown period.
    @MainActor
    private func updateErrorDate() {
        User.shared.referrals.updated = Date()
    }

    /// Updates the referral information.
    /// - Parameter info: The referral code information to update.
    @MainActor
    private func update(_ info: CodeInfo) {
        var referrals = User.shared.referrals
        referrals.code = info.code
        referrals.claims = info.claims
        referrals.updated = Date()
        User.shared.referrals = referrals
        send(referrals)
    }

    /// Stores the claim information and updates the referral state.
    @MainActor
    private func storeClaim() {
        var referrals = User.shared.referrals
        referrals.isClaimed = true
        referrals.isNewClaim = true
        User.shared.referrals = referrals
        send(referrals)
    }
}
