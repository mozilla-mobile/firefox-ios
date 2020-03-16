/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

open class MMTestUtils {
    public static func render<T>(graph: MMScreenGraph<T>, with renderer: GraphRepresentation = DotRepresentation()) {
        if let file = writeableURL(filename: "graph.\(renderer.fileExtension)") {
            print("Writing to \(file.absoluteString)")
            try? graph.stringRepresentation(renderer).write(to: file, atomically: true, encoding: .utf8)
        }
    }

    static func writeableURL(directory: String = "Library/Caches/tools.mappamundi", filename: String) -> URL? {
        let homeDir = try? UIDevice.current.homeDirectory()
        let dir = homeDir?.appendingPathComponent(directory)
        return URL(string: filename, relativeTo: dir)
    }
}

/// This is largely taken from SnapshotHelper, but duplicated here to be independent from Snapshot.

extension UIDevice {
    func homeDirectory() throws -> URL {
        let homeDir: URL
        // on OSX config is stored in /Users/<username>/Library
        // and on iOS/tvOS/WatchOS it's in simulator's home dir
        #if os(OSX)
            guard let user = ProcessInfo().environment["USER"] else {
                throw DeviceError.cannotDetectUser
            }

            guard let usersDir =  FileManager.default.urls(for: .userDirectory, in: .localDomainMask).first else {
                throw DeviceError.cannotFindHomeDirectory
            }

            homeDir = usersDir.appendingPathComponent(user)
        #else
            guard let simulatorHostHome = ProcessInfo().environment["SIMULATOR_HOST_HOME"] else {
                throw UIDeviceError.cannotFindSimulatorHomeDirectory
            }
            guard let homeDirUrl = URL(string: simulatorHostHome) else {
                throw UIDeviceError.cannotAccessSimulatorHomeDirectory(simulatorHostHome)
            }
            homeDir = URL(fileURLWithPath: homeDirUrl.path)
        #endif
        return homeDir
    }
}

enum UIDeviceError: Error, CustomDebugStringConvertible {
    case cannotDetectUser
    case cannotFindHomeDirectory
    case cannotFindSimulatorHomeDirectory
    case cannotAccessSimulatorHomeDirectory(String)

    var debugDescription: String {
        switch self {
        case .cannotDetectUser:
            return "Couldn't find MappaMundi configuration files - can't detect current user "
        case .cannotFindHomeDirectory:
            return "Couldn't find MappaMundi configuration files - can't detect `Users` dir"
        case .cannotFindSimulatorHomeDirectory:
            return "Couldn't find simulator home location. Please, check SIMULATOR_HOST_HOME env variable."
        case .cannotAccessSimulatorHomeDirectory(let simulatorHostHome):
            return "Can't prepare environment. Simulator home location is inaccessible. Does \(simulatorHostHome) exist?"
        }
    }
}

