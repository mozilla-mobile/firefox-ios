// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

/// Owns the World Cup data lifecycle: consumes the `/matches` and `/live`
/// streams from `WorldCupAPIClientProtocol`, merges live IDs into the
/// matches view-model, and emits a fresh `Snapshot` to its listener every
/// time the displayable state changes. The middleware sits on top of this
/// and translates snapshots into Redux dispatches. The feed itself has no
/// Redux knowledge.
///
/// Live polling is opened lazily based on the latest `/matches` payload
/// (see `WorldCupPollingFetchStrategy.shouldPollLive`), so we don't hit
/// merino outside the tournament window.
@MainActor
final class WorldCupFeed {
    struct Snapshot: Equatable {
        let matches: [WorldCupMatches]
        let bestMatchIndex: Int
        let apiError: WorldCupLoadError?

        static let empty = Snapshot(matches: [], bestMatchIndex: 0, apiError: nil)
    }

    private let apiClient: WorldCupAPIClientProtocol
    /// When true, a parseable `response.now` overrides `Date()` for bucketing
    /// so QA can advance the mock server's timeline without touching device
    /// date. Prod stays on `Date()` even if a response carries `now`.
    private let usesDevServerTimeline: Bool
    /// Picks the selected team for the next stream restart. The feed asks
    /// the store on each start instead of being told, so a `selectTeam`
    /// action that updates the store before calling `start` is the only
    /// thing the middleware needs to coordinate.
    private let selectedTeamProvider: () -> String?
    private let store: WorldCupStoreProtocol

    private var matchesTask: Task<Void, Never>?
    private var liveTask: Task<Void, Never>?
    private var teamsTask: Task<Void, Never>?

    private var lastMatchesResponse: WorldCupMatchesResponse?
    private var cachedLiveIDs: Set<Int> = []
    private var cachedTeamsResponse: WorldCupTeamsResponse?
    private(set) var latestSnapshot: Snapshot = .empty

    var onUpdate: ((Snapshot) -> Void)?

    init(apiClient: WorldCupAPIClientProtocol,
         store: WorldCupStoreProtocol = WorldCupStore(),
         usesDevServerTimeline: Bool,
         selectedTeamProvider: @escaping () -> String?) {
        self.apiClient = apiClient
        self.usesDevServerTimeline = usesDevServerTimeline
        self.selectedTeamProvider = selectedTeamProvider
        self.store = store
    }

    deinit {
        matchesTask?.cancel()
        liveTask?.cancel()
        teamsTask?.cancel()
    }

    /// (Re)starts the `/matches` stream. The `/live` stream is opened
    /// lazily by `reconcileLivePolling` once we have a payload to decide
    /// from.
    func start() {
        stop()
        cachedLiveIDs = []
        lastMatchesResponse = nil
        cachedTeamsResponse = nil
        let stream = apiClient.matchesStream(team: nil)
        matchesTask = Task { @MainActor [weak self] in
            for await result in stream {
                guard let self else { break }
                self.handleMatchesResult(result)
            }
        }
        startTeams()
    }

    func stop() {
        matchesTask?.cancel(); matchesTask = nil
        teamsTask?.cancel(); teamsTask = nil
        stopLive()
    }

    private func stopLive() {
        liveTask?.cancel(); liveTask = nil
    }

    private func startLive() {
        let stream = apiClient.liveStream(team: nil)
        liveTask = Task { @MainActor [weak self] in
            for await result in stream {
                guard let self else { break }
                self.handleLiveResult(result)
            }
        }
    }

    /// One-shot `/teams` fetch. Elimination only flips after a knockout
    /// result, so we don't need to poll: `start()` is invoked again on
    /// foreground/retry, which refreshes the roster.
    private func startTeams() {
        teamsTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let result = await self.apiClient.loadTeams(team: nil)
            self.handleTeamsResult(result)
        }
    }

    /// `success(.some)` rebuilds the view-model. `success(.none)` (204)
    /// keeps the previous snapshot so the UI doesn't blink to empty while
    /// the strategy waits on the empty backoff. `failure` surfaces the
    /// error so the UI can show a retry state.
    private func handleMatchesResult(_ result: Result<WorldCupMatchesResponse?, WorldCupLoadError>) {
        switch result {
        case .success(let response):
            guard let response else { return }
            lastMatchesResponse = response
            // Reconcile first so the live stream is opened before the
            // matches snapshot is emitted. This keeps `liveFetchCount` and
            // dispatch ordering deterministic for tests.
            reconcileLivePolling(against: response)
            emit(buildSnapshot(from: response))
        case .failure(let error):
            emit(Snapshot(matches: latestSnapshot.matches,
                          bestMatchIndex: latestSnapshot.bestMatchIndex,
                          apiError: error))
        }
    }

    /// `/live` failure is intentionally swallowed: matches data is the
    /// primary view; we just don't refresh the live badge. On success we
    /// only re-emit when the live ID set actually changed.
    private func handleLiveResult(_ result: Result<WorldCupLiveResponse?, WorldCupLoadError>) {
        guard case .success(let response) = result else { return }
        // Merino keeps recently-final matches in `/live` for ~24h so the
        // result tile can show alongside live ones. Filter on
        // `statusType == "live"` so the badge only sticks for genuinely
        // in-progress matches.
        let newLiveIDs = Set(
            response?.matches?
                .filter { $0.statusType == "live" }
                .map(\.globalEventId) ?? []
        )
        guard newLiveIDs != cachedLiveIDs else { return }
        cachedLiveIDs = newLiveIDs
        guard let last = lastMatchesResponse else { return }
        emit(buildSnapshot(from: last))
    }

    private func handleTeamsResult(_ result: Result<WorldCupTeamsResponse?, WorldCupLoadError>) {
        guard case .success(let response) = result, let response else { return }
        let wasEliminated = isSelectedTeamEliminated(in: cachedTeamsResponse)
        cachedTeamsResponse = response
        let nowEliminated = isSelectedTeamEliminated(in: response)
        guard wasEliminated != nowEliminated, let last = lastMatchesResponse else { return }
        emit(buildSnapshot(from: last))
    }

    private func reconcileLivePolling(against response: WorldCupMatchesResponse) {
        let now = effectiveNow(from: response) ?? Date()
        if WorldCupPollingFetchStrategy.shouldPollLive(matches: response, now: now) {
            if liveTask == nil { startLive() }
        } else {
            stopLive()
            if !cachedLiveIDs.isEmpty {
                cachedLiveIDs = []
                emit(buildSnapshot(from: response))
            }
        }
    }

    private func buildSnapshot(from response: WorldCupMatchesResponse) -> Snapshot {
        let now = effectiveNow(from: response) ?? Date()
        if let team = selectedTeamProvider(),
           !isSelectedTeamEliminated(in: cachedTeamsResponse) {
            let perStage = WorldCupMatches.perStage(
                response: response.filtered(toTeam: team),
                liveIDs: cachedLiveIDs,
                now: now
            )
            return Snapshot(matches: perStage.cards,
                            bestMatchIndex: perStage.bestMatchIndex,
                            apiError: nil)
        }
        store.setSelectedTeam(countryId: nil)
        let flattened = WorldCupMatches.flattened(
            response: response,
            liveIDs: cachedLiveIDs,
            now: now
        )
        return Snapshot(matches: flattened.cards,
                        bestMatchIndex: flattened.bestMatchIndex,
                        apiError: nil)
    }

    /// True when a team is selected AND that team appears in the roster
    /// with `eliminated == true`.
    private func isSelectedTeamEliminated(in roster: WorldCupTeamsResponse?) -> Bool {
        guard let team = selectedTeamProvider(), let roster else { return false }
        return roster.teams.first(where: { $0.key == team })?.eliminated == true
    }

    /// Returns the response's `now` only when the dev pref is set and the
    /// field parses. Any other combination returns `nil`, leaving callers
    /// to fall back to `Date()` — which is what prod always does.
    private func effectiveNow(from response: WorldCupMatchesResponse) -> Date? {
        guard usesDevServerTimeline, let iso = response.now else { return nil }
        return WorldCupMatch.parseDate(iso)
    }

    private func emit(_ snapshot: Snapshot) {
        latestSnapshot = snapshot
        onUpdate?(snapshot)
    }
}
