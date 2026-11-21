/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

enum ArgumentProcessor {
    static func initializeTooling(nimbus: NimbusInterface, args: CliArgs) {
        if args.resetDatabase {
            nimbus.resetEnrollmentsDatabase().waitUntilFinished()
        }
        if let experiments = args.experiments {
            nimbus.setExperimentsLocally(experiments)
            nimbus.applyPendingExperiments().waitUntilFinished()
            // setExperimentsLocally and applyPendingExperiments run on the
            // same single threaded dispatch queue, so we can run them in series,
            // and wait for the apply.
            nimbus.setFetchEnabled(false)
        }
        if args.logState {
            nimbus.dumpStateToLog()
        }
        if let expression = args.evalJexl {
            // Evaluate JEXL and log the result
            do {
                let messagingHelper = try nimbus.createMessageHelper()
                let result = try messagingHelper.evalJexl(expression: expression)
                let resultJson = #"{"success": true, "result": \#(result)}"#
                // swiftlint:disable:next nslocalizedstring_key
                // NSLog is intentionally used here for nimbus-cli to capture structured JSON output from device logs
                NSLog("JEXL_RESULT: \(resultJson)")
            } catch {
                let errorJson = #"{"success": false, "error": "\#(error.localizedDescription)"}"#
                // swiftlint:disable:next nslocalizedstring_key
                // NSLog is intentionally used here for nimbus-cli to capture structured JSON output from device logs
                NSLog("JEXL_RESULT: \(errorJson)")
            }
        }
    }

    static func createCommandLineArgs(args: [String]?) -> CliArgs? {
        guard let args = args else {
            return nil
        }
        if !args.contains("--nimbus-cli") {
            return nil
        }

        var argMap = [String: String]()
        var key: String?
        var resetDatabase = false
        var logState = false

        for arg in args {
            switch arg {
            case "--version":
                key = "version"

            case "--experiments":
                key = "experiments"

            case "--reset-db":
                resetDatabase = true

            case "--log-state":
                logState = true

            case "--eval-jexl":
                key = "eval-jexl"

            default:
                if let k = key {
                    argMap[k] = arg
                    key = nil
                }
            }
        }

        if argMap["version"] != "1" {
            return nil
        }

        let experiments = argMap["experiments"]?.replacingOccurrences(of: "&apos;", with: "'")
        if !validateExperiments(experiments: experiments) {
            return nil
        }

        let evalJexl = argMap["eval-jexl"]?.replacingOccurrences(of: "&apos;", with: "'")

        return CliArgs(
            resetDatabase: resetDatabase,
            experiments: experiments,
            logState: logState,
            evalJexl: evalJexl
        )
    }

    static func validateExperiments(experiments: String?) -> Bool {
        if let json = experiments {
            guard let payload = try? Dictionary.parse(jsonString: json), payload["data"] is [Any]
            else {
                return false
            }
        }

        return true
    }
}

struct CliArgs: Equatable {
    let resetDatabase: Bool
    let experiments: String?
    let logState: Bool
    let evalJexl: String?

    init(
        resetDatabase: Bool = false,
        experiments: String? = nil,
        logState: Bool = false,
        evalJexl: String? = nil
    ) {
        self.resetDatabase = resetDatabase
        self.experiments = experiments
        self.logState = logState
        self.evalJexl = evalJexl
    }
}
