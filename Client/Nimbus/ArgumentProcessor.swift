// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

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
        var meantForUs = false

        func flag(_ v: String?) -> Bool {
            guard let v = v else {
                return true
            }
            return ["1", "true", "yes"].contains(v.lowercased())
        }

        queryItems.forEach { item in
            switch item.name {
            case "--nimbus-cli":
                meantForUs = flag(item.value)
            case "--experiments":
                experiments = item.value?.removingPercentEncoding
            case "--reset-db":
                resetDatabase = flag(item.value)
            case "--log-state":
                logState = flag(item.value)
            default:
                () // NOOP
            }
        }

        if !meantForUs {
            return nil
        }

        return check(args: CliArgs(resetDatabase: resetDatabase, experiments: experiments, logState: logState))
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

        args.forEach { arg in
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

        return check(args: CliArgs(resetDatabase: resetDatabase, experiments: experiments, logState: logState))
    }

    static func check(args: CliArgs) -> CliArgs? {
        if let string = args.experiments {
            guard let payload = try? Dictionary.parse(jsonString: string),
                    payload["data"] is [Any]
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

internal extension Dictionary where Key == String, Value == Any {
    func stringify() throws -> String {
        let data = try JSONSerialization.data(withJSONObject: self)
        guard let s = String(data: data, encoding: .utf8) else {
            throw NimbusError.JsonError(message: "Unable to encode")
        }
        return s
    }

    static func parse(jsonString string: String) throws -> [String: Any] {
        guard let data = string.data(using: .utf8) else {
            throw NimbusError.JsonError(message: "Unable to decode string into data")
        }
        let obj = try JSONSerialization.jsonObject(with: data)
        guard let obj = obj as? [String: Any] else {
            throw NimbusError.JsonError(message: "Unable to cast into JSONObject")
        }
        return obj
    }
}
