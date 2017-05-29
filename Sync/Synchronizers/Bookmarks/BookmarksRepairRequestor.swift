/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import Deferred
import SwiftyJSON
import Telemetry

private let log = Logger.syncLogger

// How long should we wait after sending a repair request before we give up?
private let ResponseIntervalTimeout = OneDayInMilliseconds * 3

// The maximum number of IDs we will request to be repaired. Beyond this
// number we assume that trying to repair may do more harm than good and may
// ask another client to wipe the server and reupload everything. Bug 1341972
// is tracking that work for Desktop.
private let MaxRequestedIDs = 1000

// If a repair is in progress, this is the generated GUID for the "flow ID".
private let PrefFlowID = "flowID"
// The IDs we are currently trying to obtain via the repair process.
private let PrefMissingIDs = "ids"
// The ID of the client we're currently trying to get the missing items from.
private let PrefCurrentClient = "currentClient"
// The IDs of the clients we've previously tried to get the missing items
// from.
private let PrefPreviousClients = "previousClients"
// The time, in seconds, when we initiated the most recent client request.
private let PrefLastRepair = "when"
// Our current state.
private let PrefCurrentState = "state"

private enum RepairState: String {
    // We have not started the repair process.
    case notRepairing = ""

    // We need to try to find another client to use.
    case needNewClient = "repair.need-new-client"

    // We've sent the first request to a client.
    case sentRequest = "repair.sent"

    // We've retried a request to a client.
    case sentSecondRequest = "repair.sent-again"

    // There were no problems, but we've gone as far as we can.
    case finished = "repair.finished"

    // We've found an error that forces us to abort this entire repair cycle.
    case aborted = "repair.aborted"
}

struct RepairResponse {
    let collection: String
    let request: String
    let flowID: String
    let clientID: String
    let ids: [String]

    static func fromJSON(args: JSON) -> RepairResponse {
        return RepairResponse(collection: args["collection"].stringValue, request: args["request"].stringValue,
                              flowID: args["flowID"].stringValue, clientID: args["clientID"].stringValue,
                              ids: args["ids"].arrayValue.map { $0.stringValue })
    }
}

struct RepairRequest {
    let collection: String
    let request: String
    let flowID: String
    let requestor: String
    let ids: [String]

    func toSyncCommand() -> SyncCommand {
        let jsonObj: [String: Any] = [
            "command": "repairRequest",
            "args": [
                [
                "collection": collection,
                "request": request,
                "flowID": flowID,
                "requestor": requestor,
                "ids": ids
                ]
            ]
        ]
        return SyncCommand(value: JSON(object: jsonObj).stringValue()!)
    }
}

private class AbortRepairError: MaybeErrorType {
    let description: String
    init(_ description: String) {
        self.description = description
    }
}

private class UnknownClientError: MaybeErrorType {
    let description: String
    init(_ description: String) {
        self.description = description
    }
}

private class InvalidStateError: MaybeErrorType {
    let description: String
    init(_ description: String) {
        self.description = description
    }
}

class BookmarksRepairRequestor {
    let prefs: Prefs
    let remoteClients: RemoteClientsAndTabs
    let scratchpad: Scratchpad

    init(scratchpad: Scratchpad, basePrefs: Prefs, remoteClients: RemoteClientsAndTabs) {
        self.scratchpad = scratchpad
        self.prefs = basePrefs.branch("repairs.bookmark")
        self.remoteClients = remoteClients
    }

    /**
     * See if the repairer is willing and able to begin a repair process given
     * the specified validation information.
     *
     * - returns: true if a repair was started and false otherwise.
     */
    func startRepairs(validationInfo: [BufferInconsistency: [GUID]], flowID: String = Bytes.generateGUID()) -> Deferred<Maybe<Bool>> {
        guard self.currentState == .notRepairing else {
            log.info("Can't start a repair - repair with ID \(self.flowID) is already in progress")
            return deferMaybe(false)
        }

        let ids = self.getProblemIDs(validationInfo)

        guard ids.count > 0 else {
            log.info("Not starting a repair as there are no problems")
            return deferMaybe(false)
        }

        guard ids.count <= MaxRequestedIDs else {
            log.info("Not starting a repair as there are over \(MaxRequestedIDs) problems")
            let extra = [
                "flowID": flowID,
                "reason": "too many problems: \(ids.count)"
            ]

            let event = Event(category: "sync", method: "repair", object: "aborted", extra: extra)
            recordTelemetry(event: event)

            return deferMaybe(false)
        }

        return self.anyClientsRepairing() >>== { clientsRepairing in
            guard !clientsRepairing else {
                log.info("Can't start repair, since other clients are already repairing bookmarks")
                let extra = [
                    "flowID": flowID,
                    "reason": "other clients repairing"
                ]
                let event = Event(category: "sync", method: "repair", object: "aborted", extra: extra)
                self.recordTelemetry(event: event)
                return deferMaybe(false)
            }

            log.info("Starting a repair, looking for \(ids.count) missing item(s)")
            // Setup our prefs to indicate we are on our way.
            self.flowID = flowID
            self.currentIDs = ids
            self.currentState = .needNewClient

            let extra = ["flowID": flowID, "numIDs": String(ids.count)]
            let event = Event(category: "sync", method: "repair", object: "started", extra: extra)
            self.recordTelemetry(event: event)

            return self.continueRepairs()
        }
    }

    /**
     * Work out what state our current repair request is in, and whether it can
     * proceed to a new state.
     *
     * - returns: true if we could continue the repair - even if the state didn't
     *            actually move. Returns false if we aren't actually repairing.
     */
    func continueRepairs(response: RepairResponse? = nil) -> Deferred<Maybe<Bool>> {
        // Note that "aborted" and "finished" should never be current when this
        // function returns - this function resets to notRepairing in those cases.
        guard self.currentState != .notRepairing else {
            return deferMaybe(false)
        }

        var abortReason: String?

        func runStateMachine(iteration: Int = 0) -> Deferred<Maybe<(state: RepairState, newState: RepairState)>> {
            let state = self.currentState
            log.info("continueRepairs starting with state \(state)")

            return self.advanceRepairState(state: state, response: response).bind { result in
                let newState: RepairState
                if result.isSuccess {
                    newState = result.successValue!
                    log.info("continueRepairs has next state \(newState)")
                } else {
                    let failure = result.failureValue!
                    if failure is AbortRepairError {
                        let reason = failure.description
                        log.info("Repair has been aborted: \(reason)")
                        newState = .aborted
                        abortReason = reason
                    } else {
                        return deferMaybe(failure)
                    }
                }
                let done = deferMaybe((state: state, newState: newState))

                if newState == .aborted {
                    return done
                }

                self.currentState = newState
                if state == newState {
                    return done
                }

                // we loop until the state doesn't change - but enforce a max of 10 times
                // to prevent errors causing infinite loops.
                return (iteration < 10) ? runStateMachine(iteration: iteration + 1) : done
            }
        }

        return runStateMachine() >>== { stateMachineResult in
            let state = stateMachineResult.state
            let newState = stateMachineResult.newState

            if state != newState {
                log.error("continueRepairs spun without getting a new state")
            }

            if newState == .finished || newState == .aborted {
                let method = newState == .finished ? "finished" : "aborted"
                var extra = [
                    "flowID": self.flowID,
                    "numIDs": String(self.currentIDs.count),
                ]
                if abortReason != nil {
                    extra["reason"] = abortReason
                }

                let event = Event(category: "sync", method: "repair", object: method, extra: extra)
                self.recordTelemetry(event: event)

                self.prefs.clearAll()
            }
            return deferMaybe(true)
        }
    }

    func recordTelemetry(event: Event) {
        var events = self.prefs.arrayForKey(PrefKeySyncEvents) as? [Data] ?? []

        let data = event.pickle()
        if event.validate() {
            events.append(data)
            self.prefs.setObject(events, forKey: PrefKeySyncEvents)
        } else {
            log.info("Event not recorded due to validation failure -- \(String(data: data, encoding: .utf8))")
        }
    }

    private func advanceRepairState(state: RepairState, response: RepairResponse?) -> Deferred<Maybe<RepairState>> {
        return self.anyClientsRepairing(flowID: self.flowID) >>== { anyClientsRepairing in
            guard !anyClientsRepairing else {
                return deferMaybe(AbortRepairError("other clients repairing"))
            }

            switch state {

            case .sentRequest, .sentSecondRequest:
                let flowID = self.flowID
                guard let clientID = self.currentRemoteClient else {
                    return deferMaybe(InvalidStateError("currentRemoteClient should be defined"))
                }
                if let response = response {
                    // We got an explicit response - let's see how we went.
                    return deferMaybe(self.handleResponse(state: state, response: response))
                }
                // So we've sent a request - and don't yet have a response. See if the
                // client we sent it to has removed it from its list (ie, whether it
                // has synced since we wrote the request.)
                return self.remoteClients.getClientWithId(clientID) >>== { client in
                    guard let client = client else {
                        // hrmph - the client has disappeared.
                        log.info("previously requested client \(clientID) has vanished - moving to next step")
                        let extra = [
                            "deviceID": "IMPLEMENT ME"/* TODO this.service.identity.hashedDeviceID(clientID) */,
                            "flowID": flowID
                        ]

                        let event = Event(category: "sync", method: "repair", object: "abandon", value: "missing", extra: extra)
                        self.recordTelemetry(event: event)

                        return deferMaybe(.needNewClient)
                    }
                    return self.isCommandPending(clientID: clientID, flowID: flowID) >>== { isCommandPending in
                        if isCommandPending {
                            // So the command we previously sent is still queued for the client
                            // (ie, that client is yet to have synced). Let's see if we should
                            // give up on that client.
                            if self.lastRepair + ResponseIntervalTimeout <= Date.now() {
                                log.info("previous request to client \(clientID) is pending, but has taken too long")
                                // XXX - should we remove the command?
                                let extra = [
                                    "deviceID": "IMPLEMENT ME"/* TODO this.service.identity.hashedDeviceID(clientID) */,
                                    "flowID": flowID
                                ]

                                let event = Event(category: "sync", method: "repair", object: "abandon", value: "silent", extra: extra)
                                self.recordTelemetry(event: event)

                                return deferMaybe(.needNewClient)
                            }
                            // Let's continue to wait for that client to respond.
                            // We are now sure that timeLeft > 0, so we can calculate it (Timestamp type is UInt64)
                            let timeLeft = self.lastRepair + ResponseIntervalTimeout - Date.now()
                            log.verbose("previous request to client \(clientID) has \(timeLeft) seconds before we give up on it")
                            return deferMaybe(state)
                        }
                        // The command isn't pending - if this was the first request, we give
                        // it another go (as that client may have cleared the command but is yet
                        // to complete the sync)
                        // XXX - note that this is no longer true - the responders don't remove
                        // their command until they have written a response. This might mean
                        // we could drop the entire STATE.SENT_SECOND_REQUEST concept???
                        if state == .sentRequest {
                            log.info("previous request to client \(clientID) was removed - trying a second time")
                            return self.writeRequest(client: client) >>== { success in
                                return deferMaybe(.sentSecondRequest)
                            }
                        } else {
                            // this was the second time around, so give up on this client
                            log.info("previous 2 requests to client \(clientID) were removed - need a new client")
                            return deferMaybe(.needNewClient)
                        }
                    }
                }

            case .needNewClient:
                // We need to find a new client to request.
                return self.findNextClient() >>== { client in
                    guard let nextClient = client else {
                        return deferMaybe(.finished)
                    }
                    if let currentRemoteClient = self.currentRemoteClient {
                        var previousRemoteClients = self.previousRemoteClients
                        previousRemoteClients.append(currentRemoteClient)
                        self.previousRemoteClients = previousRemoteClients
                    }
                    self.currentRemoteClient = nextClient.guid!
                    return self.writeRequest(client: nextClient) >>== { success in
                        return deferMaybe(.sentRequest)
                    }
                }

            case .aborted:
                break // our caller will take the abort action.

            case .finished:
                break

            case .notRepairing:
                // No repair is in progress. This is a common case, so only log trace.
                log.verbose("continue repairs called but no repair in progress.")
                break
            }
            return deferMaybe(state)
        }
    }

    /**
     * Handle being in the SENT_REQUEST or SENT_SECOND_REQUEST state with an
     * explicit response.
     */
    private func handleResponse(state: RepairState, response: RepairResponse) -> RepairState {
        guard let clientID = self.currentRemoteClient else {
            log.error("Cannot handle the response of an unknown client")
            return state
        }
        let flowID = self.flowID
        guard response.flowID == flowID && response.clientID == clientID &&
              response.request == "upload" else {
            log.info("got a response to a different repair request: \(response)")
            // hopefully just a stale request that finally came in (either from
            // an entirely different repair flow, or from a client we've since
            // given up on.) It doesn't mean we need to abort though...
            return state
        }
        // Pull apart the response and see if it provided everything we asked for.
        let remainingIDs = Array(Set(self.currentIDs).subtracting(Set(response.ids)))
        log.info("repair response from \(clientID) provided '\(response.ids)', remaining now '\(remainingIDs)'")
        self.currentIDs = remainingIDs
        let newState: RepairState
        if remainingIDs.count > 0 {
            // try a new client for the remaining ones.
            newState = .needNewClient
        } else {
            newState = .finished
        }
        // record telemetry about this
        let extra = [
            "deviceID": "IMPLEMENT ME"/* TODO this.service.identity.hashedDeviceID(clientID) */,
            "flowID": flowID,
            "numIDs": String(response.ids.count)
        ]
        let event = Event(category: "sync", method: "repair", object: "response", value: "upload", extra: extra)
        recordTelemetry(event: event)
        return newState
    }

    /**
     * Issue a repair request to a specific client.
     */
    private func writeRequest(client: RemoteClient) -> Success {
        log.verbose("writing repair request to client \(client.guid!)")
        let ids = self.currentIDs
        let flowID = self.flowID
        // Post a command to that client.
        let request = RepairRequest(collection: "bookmarks", request: "upload", flowID: flowID, requestor: self.scratchpad.clientGUID, ids: ids)

        return self.remoteClients.insertCommand(request.toSyncCommand(), forClients: [client]) >>== { (_: Int) -> Success in
            self.lastRepair = Date.now()
            // record telemetry about this
            let extra = [
                "deviceID": "IMPLEMENT ME"/* TODO this.service.identity.hashedDeviceID(clientID) */,
                "flowID": flowID,
                "numIDs": String(ids.count),
                ]

            let event = Event(category: "sync", method: "repair", object: "request", value: "upload", extra: extra)
            self.recordTelemetry(event: event)

            return succeed()
        }
    }

    private func findNextClient() -> Deferred<Maybe<RemoteClient?>> {
        var alreadyDone = self.previousRemoteClients
        if let currentRemoteClient = self.currentRemoteClient {
            alreadyDone.append(currentRemoteClient)
        }
        return self.remoteClients.getClients() >>== { remoteClients in
            // we want to consider the most-recently synced clients first.
            let sortedClients = remoteClients.sorted(by: { (a, b) -> Bool in
                return a.modified > b.modified
            })
            for client in sortedClients {
                log.verbose("findNextClient considering \(client)")
                guard let clientID = client.guid else {
                    continue
                }
                if !alreadyDone.contains(clientID) && self.isSuitableClient(client) {
                    return deferMaybe(client)
                }
            }
            log.verbose("findNextClient found no client")
            return deferMaybe(nil)
        }
    }

    private func isSuitableClient(_ client: RemoteClient) -> Bool {
        if let type = client.type,
           let version = client.version,
           let major = Int(version.components(separatedBy: ".")[0]) {
            return type == "desktop" && major > 53
        }
        return false
    }

    private func getProblemIDs(_ validations: [BufferInconsistency: [GUID]]) -> [GUID] {
        return validations.reduce([]) { acc, pair in acc + pair.value }
    }

    private func anyClientsRepairing(flowID: String? = nil) -> Deferred<Maybe<Bool>> {
        return self.remoteClients.getCommands() >>== { allCommands in
            return deferMaybe(allCommands.contains { (clientID: GUID, commands: [SyncCommand]) in
                return commands.contains { (command: SyncCommand) in
                    let json = JSON(parseJSON: command.value)
                    guard let cmdName = json["command"].string,
                          let argsArray = json["args"].array,
                          let argObj = argsArray[0].dictionary,
                          let argCol = argObj["collection"]?.string,
                          let argFlowID = argObj["flowID"]?.string
                    else {
                        return false
                    }
                    return !((cmdName != "repairResponse" && cmdName != "repairRequest") ||
                             argsArray.count != 1 ||
                             argCol != "bookmarks" ||
                             argFlowID == flowID
                            )
                }
            })
        }
    }

    private func isCommandPending(clientID: String, flowID: String) -> Deferred<Maybe<Bool>> {
        return self.remoteClients.getCommands() >>== { allCommands in
            guard let commands = allCommands[clientID] else {
                return deferMaybe(false)
            }
            return deferMaybe(commands.contains { (command: SyncCommand) in
                let json = JSON(parseJSON: command.value)
                guard let cmdName = json["command"].string,
                      let argsArray = json["args"].array,
                      let argObj = argsArray[0].dictionary,
                      let argCol = argObj["collection"]?.string,
                      let argFlowID = argObj["flowID"]?.string,
                      let argRequest = argObj["request"]?.string
                else {
                    return false
                }
                return cmdName == "repairRequest" && argsArray.count == 1 &&
                    argCol == "bookmarks" && argRequest == "upload" &&
                    argFlowID == flowID
            })
        }
    }

    private var flowID: String {
        get { return self.prefs.stringForKey(PrefFlowID)! }
        set { self.prefs.setString(newValue, forKey: PrefFlowID) }
    }

    private var currentIDs: [String] {
        get { return self.prefs.stringArrayForKey(PrefMissingIDs) ?? [String]() }
        set { self.prefs.setObject(newValue, forKey: PrefMissingIDs) }
    }

    private var currentRemoteClient: String? {
        get { return self.prefs.stringForKey(PrefCurrentClient) }
        set { self.prefs.setString(newValue!, forKey: PrefCurrentClient) }
    }

    private var previousRemoteClients: [String] {
        get { return self.prefs.stringArrayForKey(PrefPreviousClients) ?? [String]() }
        set { self.prefs.setObject(newValue, forKey: PrefPreviousClients) }
    }

    private var lastRepair: Timestamp {
        get { return self.prefs.timestampForKey(PrefLastRepair)! }
        set { self.prefs.setTimestamp(newValue, forKey: PrefLastRepair) }
    }

    private var currentState: RepairState {
        get {
            let Default = RepairState.notRepairing
            guard let raw = self.prefs.stringForKey(PrefCurrentState) else {
                return Default
            }
            return RepairState(rawValue: raw) ?? Default
        }
        set { self.prefs.setString(newValue.rawValue, forKey: PrefCurrentState) }
    }
}
