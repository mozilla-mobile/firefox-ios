/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Core
import MozillaAppServices
import Storage
import Shared

final class EcosiaImport {

    enum Status {
        case initial, succeeded, failed(Failure)
    }

    class Migration {
        var favorites: Status = .initial
        var history: Status = .initial
    }

    struct Failure: Error {
        let reasons: [MaybeErrorType]

        var description: String {
            // max 3 errors to be reported to save bandwidth and storage
            return reasons.prefix(3).map{$0.description}.joined(separator: " / ")
        }
    }

    struct Exception: Codable {
        let reason: String

        private static let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("migration.ecosia")

        static func load() -> Exception? {
            try? JSONDecoder().decode(Exception.self, from: .init(contentsOf: path))
        }

        func save() {
            try? JSONEncoder().encode(self).write(to: Self.path, options: .atomic)
        }

        static func clear() {
            try? FileManager.default.removeItem(at: path)
        }
    }

    let profile: Profile

    private var progress: ((Double) -> ())?

    init(profile: Profile) {
        self.profile = profile
    }

    private var favsProgress = 0.0 { didSet { progress?(totalProgress) } }
    private var historyProgress = 0.0 { didSet { progress?(totalProgress) } }

    private var totalProgress: Double {
        return (favsProgress + historyProgress) / 2.0
    }

    func migrate(progress: ((Double) -> ())? = nil, finished: @escaping (Migration) -> ()) {
        self.progress = progress

        // Migrate in order for performance reasons -> first history, then favorites
        let migration = Migration()
        EcosiaHistory.migrate(Core.History().items, to: profile, progress: { historyProgress in
            self.historyProgress = historyProgress
        }) { result in
            switch result {
            case .success:
                migration.history = .succeeded
            case .failure(let error):
                migration.history = .failed(error)
                Analytics.shared.migrationError(in: .history, message: error.description)
            }
            self.historyProgress = 1.0

            EcosiaFavourites.migrate(Core.Favourites().items, to: self.profile, progress: { favsProgress in
                self.favsProgress = favsProgress
            }) { result in
                switch result {
                case .success:
                    migration.favorites = .succeeded
                case .failure(let error):
                    migration.favorites = .failed(error)
                    Analytics.shared.migrationError(in: .favourites, message: error.description)
                }
                finished(migration)
                self.progress = nil
            }
        }
    }
}
