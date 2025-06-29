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

    func testCommandLineArgs() throws {
        XCTAssertNil(ArgumentProcessor.createCommandLineArgs(args: []))
        // No --nimbus-cli or --version 1
        XCTAssertNil(ArgumentProcessor.createCommandLineArgs(args: ["--experiments", "{\"data\": []}}"]))

        // No --version 1
        XCTAssertNil(ArgumentProcessor.createCommandLineArgs(args: ["--version", "1", "--experiments", "{\"data\": []}}"]))

        let argsUnenroll = ArgumentProcessor.createCommandLineArgs(args: ["--nimbus-cli", "--version", "1", "--experiments", unenrollExperiments])
        if let args = argsUnenroll {
            XCTAssertEqual(args.experiments, unenrollExperiments)
            XCTAssertFalse(args.resetDatabase)
        } else {
            XCTAssertNotNil(argsUnenroll)
        }

        XCTAssertEqual(
            ArgumentProcessor.createCommandLineArgs(args: ["--nimbus-cli", "--version", "1", "--experiments", unenrollExperiments]),
            CliArgs(resetDatabase: false, experiments: unenrollExperiments, logState: false, isLauncher: false)
        )

        XCTAssertEqual(
            ArgumentProcessor.createCommandLineArgs(args: ["--nimbus-cli", "--version", "1", "--experiments", unenrollExperiments, "--reset-db"]),
            CliArgs(resetDatabase: true, experiments: unenrollExperiments, logState: false, isLauncher: false)
        )

        XCTAssertEqual(
            ArgumentProcessor.createCommandLineArgs(args: ["--nimbus-cli", "--version", "1", "--reset-db"]),
            CliArgs(resetDatabase: true, experiments: nil, logState: false, isLauncher: false)
        )

        XCTAssertEqual(
            ArgumentProcessor.createCommandLineArgs(args: ["--nimbus-cli", "--version", "1", "--log-state"]),
            CliArgs(resetDatabase: false, experiments: nil, logState: true, isLauncher: false)
        )
    }

    func testUrl() throws {
        XCTAssertNil(ArgumentProcessor.createCommandLineArgs(url: URL(string: "https://example.com")!))
        XCTAssertNil(ArgumentProcessor.createCommandLineArgs(url: URL(string: "my-app://deeplink")!))

        let experiments = "{\"data\": []}"
        let percentEncoded = experiments.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics)!
        let arg0 = ArgumentProcessor.createCommandLineArgs(url: URL(string: "my-app://deeplink?--nimbus-cli&--experiments=\(percentEncoded)&--reset-db")!)
        XCTAssertNotNil(arg0)
        XCTAssertEqual(arg0, CliArgs(resetDatabase: true, experiments: experiments, logState: false, isLauncher: false))

        let arg1 = ArgumentProcessor.createCommandLineArgs(url: URL(string: "my-app://deeplink?--nimbus-cli=1&--experiments=\(percentEncoded)&--reset-db=1")!)
        XCTAssertNotNil(arg1)
        XCTAssertEqual(arg1, CliArgs(resetDatabase: true, experiments: experiments, logState: false, isLauncher: false))

        let arg2 = ArgumentProcessor.createCommandLineArgs(url: URL(string: "my-app://deeplink?--nimbus-cli=true&--experiments=\(percentEncoded)&--reset-db=true")!)
        XCTAssertNotNil(arg2)
        XCTAssertEqual(arg2, CliArgs(resetDatabase: true, experiments: experiments, logState: false, isLauncher: false))

        let arg3 = ArgumentProcessor.createCommandLineArgs(url: URL(string: "my-app://deeplink?--nimbus-cli&--is-launcher")!)
        XCTAssertNotNil(arg3)
        XCTAssertEqual(arg3, CliArgs(resetDatabase: false, experiments: nil, logState: false, isLauncher: true))

        let httpArgs = ArgumentProcessor.createCommandLineArgs(url: URL(string: "https://example.com?--nimbus-cli=true&--experiments=\(percentEncoded)&--reset-db=true")!)
        XCTAssertNil(httpArgs)
    }

    func testLongUrlFromRust() throws {
        // Long string encoded by Rust
        let string = "%7B%22data%22%3A[%7B%22appId%22%3A%22org.mozilla.ios.Firefox%22,%22appName%22%3A%22firefox_ios%22,%22application%22%3A%22org.mozilla.ios.Firefox%22,%22arguments%22%3A%7B%7D,%22branches%22%3A[%7B%22feature%22%3A%7B%22enabled%22%3Afalse,%22featureId%22%3A%22this-is-included-for-mobile-pre-96-support%22,%22value%22%3A%7B%7D%7D,%22features%22%3A[%7B%22enabled%22%3Atrue,%22featureId%22%3A%22onboarding-framework-feature%22,%22value%22%3A%7B%22cards%22%3A%7B%22welcome%22%3A%7B%22body%22%3A%22Onboarding%2FOnboarding.Welcome.Description.TreatementA.v114%22,%22buttons%22%3A%7B%22primary%22%3A%7B%22action%22%3A%22set-default-browser%22,%22title%22%3A%22Onboarding%2FOnboarding.Welcome.ActionTreatementA.v114%22%7D,%22secondary%22%3A%7B%22action%22%3A%22next-card%22,%22title%22%3A%22Onboarding%2FOnboarding.Welcome.Skip.v114%22%7D%7D,%22link%22%3A%7B%22url%22%3A%22https%3A%2F%2Fwww.mozilla.org%2Fde-de%2Fprivacy%2Ffirefox%2F%22%7D,%22title%22%3A%22Onboarding%2FOnboarding.Welcome.Title.TreatementA.v114%22%7D%7D%7D%7D],%22ratio%22%3A0,%22slug%22%3A%22control%22%7D,%7B%22feature%22%3A%7B%22enabled%22%3Afalse,%22featureId%22%3A%22this-is-included-for-mobile-pre-96-support%22,%22value%22%3A%7B%7D%7D,%22features%22%3A[%7B%22enabled%22%3Atrue,%22featureId%22%3A%22onboarding-framework-feature%22,%22value%22%3A%7B%22cards%22%3A%7B%22notification-permissions%22%3A%7B%22body%22%3A%22Benachrichtigungen%20helfen%20dabei,%20Tabs%20zwischen%20Ger%C3%A4ten%20zu%20senden%20und%20Tipps%20zu%20erhalten.%E2%80%A8%E2%80%A8%22,%22image%22%3A%22notifications-ctd%22,%22title%22%3A%22Du%20bestimmst,%20was%20Firefox%20kann%22%7D,%22sign-to-sync%22%3A%7B%22body%22%3A%22Wenn%20du%20willst,%20bringt%20Firefox%20deine%20Tabs%20und%20Passw%C3%B6rter%20auf%20all%20deine%20Ger%C3%A4te.%22,%22image%22%3A%22sync-devices-ctd%22,%22title%22%3A%22Alles%20ist%20dort,%20wo%20du%20es%20brauchst%22%7D,%22welcome%22%3A%7B%22body%22%3A%22Nimm%20nicht%20das%20Erstbeste,%20sondern%20das%20Beste%20f%C3%BCr%20dich%3A%20Firefox%20sch%C3%BCtzt%20deine%20Privatsph%C3%A4re.%22,%22buttons%22%3A%7B%22primary%22%3A%7B%22action%22%3A%22set-default-browser%22,%22title%22%3A%22Als%20Standardbrowser%20festlegen%22%7D,%22secondary%22%3A%7B%22action%22%3A%22next-card%22,%22title%22%3A%22Onboarding%2FOnboarding.Welcome.Skip.v114%22%7D%7D,%22image%22%3A%22welcome-ctd%22,%22title%22%3A%22Du%20entscheidest,%20was%20Standard%20ist%22%7D%7D%7D%7D],%22ratio%22%3A100,%22slug%22%3A%22treatment-a%22%7D,%7B%22feature%22%3A%7B%22enabled%22%3Afalse,%22featureId%22%3A%22this-is-included-for-mobile-pre-96-support%22,%22value%22%3A%7B%7D%7D,%22features%22%3A[%7B%22enabled%22%3Atrue,%22featureId%22%3A%22onboarding-framework-feature%22,%22value%22%3A%7B%22cards%22%3A%7B%22notification-permissions%22%3A%7B%22image%22%3A%22notifications-ctd%22%7D,%22sign-to-sync%22%3A%7B%22image%22%3A%22sync-devices-ctd%22%7D,%22welcome%22%3A%7B%22body%22%3A%22Onboarding%2FOnboarding.Welcome.Description.TreatementA.v114%22,%22buttons%22%3A%7B%22primary%22%3A%7B%22action%22%3A%22set-default-browser%22,%22title%22%3A%22Onboarding%2FOnboarding.Welcome.ActionTreatementA.v114%22%7D,%22secondary%22%3A%7B%22action%22%3A%22next-card%22,%22title%22%3A%22Onboarding%2FOnboarding.Welcome.Skip.v114%22%7D%7D,%22image%22%3A%22welcome-ctd%22,%22link%22%3A%7B%22title%22%3A%22Onboarding%2FOnboarding.Welcome.Link.Action.v114%22,%22url%22%3A%22https%3A%2F%2Fwww.mozilla.org%2Fde-de%2Fprivacy%2Ffirefox%2F%22%7D,%22title%22%3A%22Onboarding%2FOnboarding.Welcome.Title.TreatementA.v114%22%7D%7D%7D%7D],%22ratio%22%3A0,%22slug%22%3A%22treatment-b%22%7D,%7B%22feature%22%3A%7B%22enabled%22%3Afalse,%22featureId%22%3A%22this-is-included-for-mobile-pre-96-support%22,%22value%22%3A%7B%7D%7D,%22features%22%3A[%7B%22enabled%22%3Atrue,%22featureId%22%3A%22onboarding-framework-feature%22,%22value%22%3A%7B%22cards%22%3A%7B%22notification-permissions%22%3A%7B%22body%22%3A%22Benachrichtigungen%20helfen%20dabei,%20Tabs%20zwischen%20Ger%C3%A4ten%20zu%20senden%20und%20Tipps%20zu%20erhalten.%E2%80%A8%E2%80%A8%22,%22title%22%3A%22Du%20bestimmst,%20was%20Firefox%20kann%22%7D,%22sign-to-sync%22%3A%7B%22body%22%3A%22Wenn%20du%20willst,%20bringt%20Firefox%20deine%20Tabs%20und%20Passw%C3%B6rter%20auf%20all%20deine%20Ger%C3%A4te.%22,%22title%22%3A%22Alles%20ist%20dort,%20wo%20du%20es%20brauchst%22%7D,%22welcome%22%3A%7B%22body%22%3A%22Nimm%20nicht%20das%20Erstbeste,%20sondern%20das%20Beste%20f%C3%BCr%20dich%3A%20Firefox%20sch%C3%BCtzt%20deine%20Privatsph%C3%A4re.%22,%22buttons%22%3A%7B%22primary%22%3A%7B%22action%22%3A%22set-default-browser%22,%22title%22%3A%22Als%20Standardbrowser%20festlegen%22%7D,%22secondary%22%3A%7B%22action%22%3A%22next-card%22,%22title%22%3A%22Onboarding%2FOnboarding.Welcome.Skip.v114%22%7D%7D,%22title%22%3A%22Du%20entscheidest,%20was%20Standard%20ist%22%7D%7D%7D%7D],%22ratio%22%3A0,%22slug%22%3A%22treatment-c%22%7D],%22bucketConfig%22%3A%7B%22count%22%3A10000,%22namespace%22%3A%22ios-onboarding-framework-feature-release-5%22,%22randomizationUnit%22%3A%22nimbus_id%22,%22start%22%3A0,%22total%22%3A10000%7D,%22channel%22%3A%22developer%22,%22endDate%22%3Anull,%22enrollmentEndDate%22%3A%222023-08-03%22,%22featureIds%22%3A[%22onboarding-framework-feature%22],%22featureValidationOptOut%22%3Afalse,%22id%22%3A%22release-ios-on-boarding-challenge-the-default-copy%22,%22isEnrollmentPaused%22%3Afalse,%22isRollout%22%3Afalse,%22locales%22%3Anull,%22localizations%22%3Anull,%22outcomes%22%3A[%7B%22priority%22%3A%22primary%22,%22slug%22%3A%22onboarding%22%7D,%7B%22priority%22%3A%22secondary%22,%22slug%22%3A%22default_browser%22%7D],%22probeSets%22%3A[],%22proposedDuration%22%3A44,%22proposedEnrollment%22%3A30,%22referenceBranch%22%3A%22control%22,%22schemaVersion%22%3A%221.12.0%22,%22slug%22%3A%22release-ios-on-boarding-challenge-the-default-copy%22,%22startDate%22%3A%222023-06-26%22,%22targeting%22%3A%22true%22,%22userFacingDescription%22%3A%22Testing%20copy%20and%20images%20in%20the%20first%20run%20onboarding%20that%20is%20consistent%20with%20marketing%20messaging.%22,%22userFacingName%22%3A%22[release]%20iOS%20On-boarding%20Challenge%20the%20Default%20Copy%22%7D]%7D"

        let url = URL(string: "fennec://deeplink?--nimbus-cli&--experiments=\(string)")

        XCTAssertNotNil(url)

        let args = ArgumentProcessor.createCommandLineArgs(url: url!)
        XCTAssertNotNil(args)
        XCTAssertEqual(args?.experiments, string.removingPercentEncoding)
    }
}
