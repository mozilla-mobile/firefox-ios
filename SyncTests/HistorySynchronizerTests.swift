/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Storage
@testable import Sync
import XCGLogger
import Deferred

import XCTest
import SwiftyJSON

private let log = Logger.syncLogger

class MockSyncDelegate: SyncDelegate {
    func displaySentTabForURL(_ URL: URL, title: String) {
    }
}

class DBPlace: Place {
    var isDeleted = false
    var shouldUpload = false
    var serverModified: Timestamp?
    var localModified: Timestamp?
}

class MockSyncableHistory {
    var wasReset: Bool = false
    var places = [GUID: DBPlace]()
    var remoteVisits = [GUID: Set<Visit>]()
    var localVisits = [GUID: Set<Visit>]()

    init() {
    }

    fileprivate func placeForURL(url: String) -> DBPlace? {
        return findOneValue(places) { $0.url == url }
    }
}

extension MockSyncableHistory: ResettableSyncStorage {
    func resetClient() -> Success {
        self.wasReset = true
        return succeed()
    }
}

extension MockSyncableHistory: SyncableHistory {
    // TODO: consider comparing the timestamp to local visits, perhaps opting to
    // not delete the local place (and instead to give it a new GUID) if the visits
    // are newer than the deletion.
    // Obviously this'll behave badly during reconciling on other devices:
    // they might apply our new record first, renaming their local copy of
    // the old record with that URL, and thus bring all the old visits back to life.
    // Desktop just finds by GUID then deletes by URL.
    func deleteByGUID(_ guid: GUID, deletedAt: Timestamp) -> Deferred<Maybe<()>> {
        self.remoteVisits.removeValue(forKey: guid)
        self.localVisits.removeValue(forKey: guid)
        self.places.removeValue(forKey: guid)

        return succeed()
    }

    func hasSyncedHistory() -> Deferred<Maybe<Bool>> {
        let has = self.places.values.contains(where: { $0.serverModified != nil })
        return deferMaybe(has)
    }

    /**
     * This assumes that the provided GUID doesn't already map to a different URL!
     */
    func ensurePlaceWithURL(_ url: String, hasGUID guid: GUID) -> Success {
        // Find by URL.
        if let existing = self.placeForURL(url: url) {
            let p = DBPlace(guid: guid, url: url, title: existing.title)
            p.isDeleted = existing.isDeleted
            p.serverModified = existing.serverModified
            p.localModified = existing.localModified
            self.places.removeValue(forKey: existing.guid)
            self.places[guid] = p
        }

        return succeed()
    }

    func storeRemoteVisits(_ visits: [Visit], forGUID guid: GUID) -> Success {
        // Strip out existing local visits.
        // We trust that an identical timestamp and type implies an identical visit.
        var remote = Set<Visit>(visits)
        if let local = self.localVisits[guid] {
            remote.subtract(local)
        }

        // Visits are only ever added.
        if var r = self.remoteVisits[guid] {
            r.formUnion(remote)
        } else {
            self.remoteVisits[guid] = remote
        }
        return succeed()
    }

    func insertOrUpdatePlace(_ place: Place, modified: Timestamp) -> Deferred<Maybe<GUID>> {
        // See if we've already applied this one.
        if let existingModified = self.places[place.guid]?.serverModified {
            if existingModified == modified {
                log.debug("Already seen unchanged record \(place.guid).")
                return deferMaybe(place.guid)
            }
        }

        // Make sure that we collide with any matching URLs -- whether locally
        // modified or not. Then overwrite the upstream and merge any local changes.
        return self.ensurePlaceWithURL(place.url, hasGUID: place.guid)
            >>> {
                if let existingLocal = self.places[place.guid] {
                    if existingLocal.shouldUpload {
                        log.debug("Record \(existingLocal.guid) modified locally and remotely.")
                        log.debug("Local modified: \(existingLocal.localModified ??? "nil"); remote: \(modified).")

                        // Should always be a value if marked as changed.
                        if existingLocal.localModified! > modified {
                            // Nothing to do: it's marked as changed.
                            log.debug("Discarding remote non-visit changes!")
                            self.places[place.guid]?.serverModified = modified
                            return deferMaybe(place.guid)
                        } else {
                            log.debug("Discarding local non-visit changes!")
                            self.places[place.guid]?.shouldUpload = false
                        }
                    } else {
                        log.debug("Remote record exists, but has no local changes.")
                    }
                } else {
                    log.debug("Remote record doesn't exist locally.")
                }

                // Apply the new remote record.
                let p = DBPlace(guid: place.guid, url: place.url, title: place.title)
                p.localModified = Date.now()
                p.serverModified = modified
                p.isDeleted = false
                self.places[place.guid] = p
                return deferMaybe(place.guid)
        }
    }

    func getModifiedHistoryToUpload() -> Deferred<Maybe<[(Place, [Visit])]>> {
        // TODO.
        return deferMaybe([])
    }

    func getDeletedHistoryToUpload() -> Deferred<Maybe<[GUID]>> {
        // TODO.
        return deferMaybe([])
    }

    func markAsSynchronized(_: [GUID], modified: Timestamp) -> Deferred<Maybe<Timestamp>> {
        // TODO
        return deferMaybe(0)
    }

    func markAsDeleted(_: [GUID]) -> Success {
        // TODO
        return succeed()
    }

    func onRemovedAccount() -> Success {
        // TODO
        return succeed()
    }

    func doneApplyingRecordsAfterDownload() -> Success {
        return succeed()
    }

    func doneUpdatingMetadataAfterUpload() -> Success {
        return succeed()
    }
}

class HistorySynchronizerTests: XCTestCase {
    private func applyRecords(records: [Record<HistoryPayload>], toStorage storage: SyncableHistory & ResettableSyncStorage) -> (synchronizer: HistorySynchronizer, prefs: Prefs, scratchpad: Scratchpad) {
        let delegate = MockSyncDelegate()

        // We can use these useless values because we're directly injecting decrypted
        // payloads; no need for real keys etc.
        let prefs = MockProfilePrefs()
        let scratchpad = Scratchpad(b: KeyBundle.random(), persistingTo: prefs)

        let synchronizer = HistorySynchronizer(scratchpad: scratchpad, delegate: delegate, basePrefs: prefs)

        let expectation = self.expectation(description: "Waiting for application.")
        var succeeded = false
        synchronizer.applyIncomingToStorage(storage, records: records)
                    .upon({ result in
            succeeded = result.isSuccess
            expectation.fulfill()
        })

        waitForExpectations(timeout: 10, handler: nil)
        XCTAssertTrue(succeeded, "Application succeeded.")
        return (synchronizer, prefs, scratchpad)
    }

    func testRecordSerialization() {
        let id = "abcdefghi"
        let modified: Timestamp = 0    // Ignored in upload serialization.
        let sortindex = 1
        let ttl = 12345
        let json: JSON = JSON([
            "id": id,
            "visits": [],
            "histUri": "http://www.slideshare.net/swadpasc/bpm-edu-netseminarscepwithreactionrulemlprova",
            "title": "Semantic Complex Event Processing with \(Character(UnicodeScalar(11)))Reaction RuleML 1.0 and Prova",
            ])
        let payload = HistoryPayload(json)
        let record = Record<HistoryPayload>(id: id, payload: payload, modified: modified, sortindex: sortindex, ttl: ttl)
        let k = KeyBundle.random()
        let s = k.serializer({ (x: HistoryPayload) -> JSON in x.json })
        let converter = { (x: JSON) -> HistoryPayload in HistoryPayload(x) }
        let f = k.factory(converter)
        let serialized = s(record)!
        let envelope = EnvelopeJSON(serialized)

        // With a badly serialized payload, we get null JSON!
        let p = f(envelope.payload)
        XCTAssertFalse(p!.json.isNull())

        // When we round-trip, the payload should be valid, and we'll get a record here.
        let roundtripped = Record<HistoryPayload>.fromEnvelope(envelope, payloadFactory: f)
        XCTAssertNotNil(roundtripped)
    }

    func testApplyRecords() {
        let earliest = Date.now()

        let empty = MockSyncableHistory()
        let noRecords = [Record<HistoryPayload>]()

        // Apply no records.
        let _ = self.applyRecords(records: noRecords, toStorage: empty)

        // Hey look! Nothing changed.
        XCTAssertTrue(empty.places.isEmpty)
        XCTAssertTrue(empty.remoteVisits.isEmpty)
        XCTAssertTrue(empty.localVisits.isEmpty)

        // Apply one remote record.
        let jA = "{\"id\":\"aaaaaa\",\"histUri\":\"http://foo.com/\",\"title\": \"ñ\",\"visits\":[{\"date\":1222222222222222,\"type\":1}]}"
        let pA = HistoryPayload.fromJSON(JSON(parseJSON: jA))!
        let rA = Record<HistoryPayload>(id: "aaaaaa", payload: pA, modified: earliest + 10000, sortindex: 123, ttl: 1000000)

        let (_, prefs, _) = self.applyRecords(records: [rA], toStorage: empty)

        // The record was stored. This is checking our mock implementation, but real storage should work, too!

        XCTAssertEqual(1, empty.places.count)
        XCTAssertEqual(1, empty.remoteVisits.count)
        XCTAssertEqual(1, empty.remoteVisits["aaaaaa"]!.count)
        XCTAssertTrue(empty.localVisits.isEmpty)

        // Test resetting now that we have a timestamp.
        XCTAssertFalse(empty.wasReset)
        XCTAssertTrue(HistorySynchronizer.resetSynchronizerWithStorage(empty, basePrefs: prefs, collection: "history").value.isSuccess)
        XCTAssertTrue(empty.wasReset)
    }
}
