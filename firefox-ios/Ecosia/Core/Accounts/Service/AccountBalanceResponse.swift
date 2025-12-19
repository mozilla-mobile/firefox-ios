// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct AccountBalanceResponse: Codable {
    public let balance: Balance
    public let previousBalance: PreviousBalance?

    public init(balance: Balance, previousBalance: PreviousBalance?) {
        self.balance = balance
        self.previousBalance = previousBalance
    }

    public struct Balance: Codable {
        public let amount: Int
        public let isModified: Bool
        let updatedAt: String

        public init(amount: Int, updatedAt: String, isModified: Bool) {
            self.amount = amount
            self.updatedAt = updatedAt
            self.isModified = isModified
        }
    }

    public struct PreviousBalance: Codable {
        public let amount: Int

        public init(amount: Int) {
            self.amount = amount
        }
    }

    public var balanceIncrement: Int? {
        guard let previousBalance, balance.isModified else { return nil }
        return balance.amount - previousBalance.amount
    }
}
