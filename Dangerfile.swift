// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Danger
import DangerSwiftCoverage
import Foundation

let danger = Danger()

coverage()
changedFiles()
checkBigPullRequest()
checkForPRDescription()

func changedFiles() {
    message("Edited \(danger.git.modifiedFiles.count) files")
    message("Created \(danger.git.createdFiles.count) files")
}

func coverage() {
    guard let xcresult = ProcessInfo.processInfo.environment["BITRISE_XCRESULT_PATH"]?.escapeString() else {
        fail("Could not get the BITRISE_XCRESULT_PATH to generate code coverage")
        return
    }

    Coverage.xcodeBuildCoverage(
        .xcresultBundle(xcresult),
        minimumCoverage: 50
    )
}

// Encourage smaller PRs
func checkBigPullRequest() {
    let bigPRThreshold = 800
    guard let additions = danger.github.pullRequest.additions,
          let deletions = danger.github.pullRequest.deletions else { return }

    let additionsAndDeletions = additions + deletions
    if additionsAndDeletions > bigPRThreshold {
        warn("Pull Request size seems relatively large. If this Pull Request contains multiple changes, please split each into separate PR will helps faster, easier review. Consider using epic branches for work that would affect main.")
    }
}

// Encourage writing up some reasoning about the PR, rather than just leaving a title.
func checkForPRDescription() {
    let body = danger.github.pullRequest.body?.count ?? 0
    let linesOfCode = danger.github.pullRequest.additions ?? 0
    if body < 3 && linesOfCode > 10 {
        warn("Please provide a summary of your changes in the Pull Request description. This helps reviewers to understand your code and technical decisions. Please also include the JIRA issue number and the GitHub ticket number (if available).")
    }
}

extension String {
    // Helper function to escape (iOS) in our file name for xcov.
    func escapeString() -> String {
        var newString = self.replacingOccurrences(of: "(", with: "\\(")
        newString = newString.replacingOccurrences(of: ")", with: "\\)")
        newString = newString.replacingOccurrences(of: " ", with: "\\ ")
        return newString
    }
}
