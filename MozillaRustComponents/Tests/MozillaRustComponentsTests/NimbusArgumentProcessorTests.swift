/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import MozillaRustComponents
@testable import MozillaAppServices
import XCTest

final class NimbusArgumentProcessorTests: XCTestCase {
    let unenrollExperiments = """
        {"data": []}
    """

    let enrollExperiment = """
        {
            "data": [
                {"slug": "foo"}
            ]
        }
    """

    let withApos = """
        {
            "data": [
                {"slug": "&apos;"}
            ]
        }
    """

    let withoutApos = """
        {
            "data": [
                {"slug": "'"}
            ]
        }
    """

    func testCommandLineArgs() throws {
        // Both --nimbus-cli and --version 1 are required arguments.
        XCTAssertNil(ArgumentProcessor.createCommandLineArgs(args: []))
        XCTAssertNil(ArgumentProcessor.createCommandLineArgs(args: ["--reset-db"]))
        XCTAssertNil(ArgumentProcessor.createCommandLineArgs(args: ["--version", "1", "--reset-db"]))
        XCTAssertNil(ArgumentProcessor.createCommandLineArgs(args: ["--nimbus-cli", "--reset-db"]))

        XCTAssertEqual(
            ArgumentProcessor.createCommandLineArgs(args: ["--nimbus-cli", "--version", "1", "--experiments", unenrollExperiments]),
            CliArgs(experiments: unenrollExperiments)
        )

        XCTAssertEqual(
            ArgumentProcessor.createCommandLineArgs(args: ["--nimbus-cli", "--version", "1", "--reset-db"]),
            CliArgs(resetDatabase: true)
        )

        XCTAssertEqual(
            ArgumentProcessor.createCommandLineArgs(args: ["--nimbus-cli", "--version", "1", "--log-state"]),
            CliArgs(logState: true)
        )

        XCTAssertEqual(
            ArgumentProcessor.createCommandLineArgs(args: ["--nimbus-cli", "--version", "1", "--eval-jexl", "&apos;hello world&apos;"]),
            CliArgs(evalJexl: "'hello world'")
        )

        XCTAssertEqual(
            ArgumentProcessor.createCommandLineArgs(args: ["--nimbus-cli", "--version", "1", "--experiments", enrollExperiment]),
            CliArgs(experiments: enrollExperiment)
        )

        XCTAssertEqual(
            ArgumentProcessor.createCommandLineArgs(args: ["--nimbus-cli", "--version", "1", "--experiments", withApos]),
            CliArgs(experiments: withoutApos)
        )

        XCTAssertEqual(
            ArgumentProcessor.createCommandLineArgs(args: ["--nimbus-cli", "--version", "1", "--experiments", unenrollExperiments, "--reset-db"]),
            CliArgs(resetDatabase: true, experiments: unenrollExperiments)
        )
    }
}
