// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import PackagePlugin
import Foundation

@main
struct Plugin: BuildToolPlugin {
    func createBuildCommands(context: PackagePlugin.PluginContext,
                             target: any PackagePlugin.Target) async throws -> [PackagePlugin.Command] {
        let scriptPath = context.package.directory.appending("script.sh")

        return [
            .prebuildCommand(
                displayName: "Running custom bash script",
                executable: Path("/bin/bash"),
                arguments: [scriptPath.string],
                outputFilesDirectory: Path("../Sources/Storage")
            )
        ]
    }
}
