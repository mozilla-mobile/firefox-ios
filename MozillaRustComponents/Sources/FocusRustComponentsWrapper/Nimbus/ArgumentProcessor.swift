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
                let resultJson = "{\"success\": true, \"result\": \(result)}"
                NSLog("JEXL_RESULT: \(resultJson)")
            } catch {
                let errorJson = "{\"success\": false, \"error\": \"\(error.localizedDescription)\"}"
                NSLog("JEXL_RESULT: \(errorJson)")
            }
        }
        // We have isLauncher here doing nothing; this is to match the Android implementation.
        // There is nothing to do at this point, because we're unable to affect the flow of the app.
        if args.isLauncher {
            () // NOOP.
        }
    }

    static func createCommandLineArgs(url: URL) -> CliArgs? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let scheme = components.scheme,
              let queryItems = components.queryItems,
              !["http", "https"].contains(scheme)
        else {
            return nil
        }

        var experiments: String?
        var resetDatabase = false
        var logState = false
        var isLauncher = false
        var evalJexl: String?
        var meantForUs = false

        func flag(_ v: String?) -> Bool {
            guard let v = v else {
                return true
            }
            return ["1", "true"].contains(v.lowercased())
        }

        for item in queryItems {
            switch item.name {
            case "--nimbus-cli":
                meantForUs = flag(item.value)
            case "--experiments":
                experiments = item.value?.removingPercentEncoding
            case "--reset-db":
                resetDatabase = flag(item.value)
            case "--log-state":
                logState = flag(item.value)
            case "--is-launcher":
                isLauncher = flag(item.value)
            case "--eval-jexl":
                evalJexl = item.value?.removingPercentEncoding
            default:
                () // NOOP
            }
        }

        if !meantForUs {
            return nil
        }

        return check(args: CliArgs(
            resetDatabase: resetDatabase,
            experiments: experiments,
            logState: logState,
            isLauncher: isLauncher,
            evalJexl: evalJexl
        ))
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
            var value: String?
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
                value = arg.replacingOccurrences(of: "&apos;", with: "'")
            }

            if let k = key, let v = value {
                argMap[k] = v
                key = nil
                value = nil
            }
        }

        if argMap["version"] != "1" {
            return nil
        }

        let experiments = argMap["experiments"]
        let evalJexl = argMap["eval-jexl"]

        return check(args: CliArgs(
            resetDatabase: resetDatabase,
            experiments: experiments,
            logState: logState,
            isLauncher: false,
            evalJexl: evalJexl
        ))
    }

    static func check(args: CliArgs) -> CliArgs? {
        if let string = args.experiments {
            guard let payload = try? Dictionary.parse(jsonString: string), payload["data"] is [Any]
            else {
                return nil
            }
        }
        return args
    }
}

struct CliArgs: Equatable {
    let resetDatabase: Bool
    let experiments: String?
    let logState: Bool
    let isLauncher: Bool
    let evalJexl: String?
}

public extension NimbusInterface {
    func initializeTooling(url: URL?) {
        guard let url = url,
              let args = ArgumentProcessor.createCommandLineArgs(url: url)
        else {
            return
        }
        ArgumentProcessor.initializeTooling(nimbus: self, args: args)
    }
}
