// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Danger
import DangerSwiftCoverage
import Foundation

/// Reference at https://danger.systems/swift/reference.html
let danger = Danger()

checkCodeCoverage()
checkBigPullRequest()
checkForPRDescription()
checkForCodeUsage()
changedFiles()

func changedFiles() {
    message("Edited \(danger.git.modifiedFiles.count) files")
    message("Created \(danger.git.createdFiles.count) files")
}

func checkCodeCoverage() {
    guard let xcresult = ProcessInfo.processInfo.environment["BITRISE_XCRESULT_PATH"]?.escapeString() else {
        fail("Could not get the BITRISE_XCRESULT_PATH to generate code coverage")
        return
    }

    Coverage.xcodeBuildCoverage(
        .xcresultBundle(xcresult),
        minimumCoverage: 50
    )
}

// MARK: - PR guidelines

// swiftlint:disable line_length
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
// swiftlint:enable line_length

enum CodeUsageToDetect: CaseIterable {
    static let commonLoggerSentence = " Please remove this usage from production code or use BrowserKit Logger."

    case print
    case nsLog
    case osLog
    case deferred

    var message: String {
        switch self {
        case .print:
            return "Print() function seems to be used in file %@ at line %d.\(CodeUsageToDetect.commonLoggerSentence)"
        case .nsLog:
            return "NSLog() function seems to be used in file %@ at line %d.\(CodeUsageToDetect.commonLoggerSentence)"
        case .osLog:
            return "os_log() function seems to be used in file %@ at line %d.\(CodeUsageToDetect.commonLoggerSentence)"
        case .deferred:
            return "Deferred class seems to be used in file %@ at line %d. Please consider replacing with completion handler instead."
        }
    }

    var keyword: String {
        switch self {
        case .print:
            return "print("
        case .nsLog:
            return "NSLog("
        case .osLog:
            return "os_log("
        case .deferred:
            return "Deferred<"
        }
    }
}

// Detects CodeUsageToDetect in PR so certain functions are not used in new code.
func checkForCodeUsage() {
    let editedFiles = danger.git.modifiedFiles + danger.git.createdFiles

    // We look at the diff between the source and destination branches
    let destinationSha = "\(danger.github.pullRequest.base.sha)"
    let sourceSha = "\(danger.github.pullRequest.head.sha)"
    let diffBranches = "\(destinationSha)..\(sourceSha)"

    // Iterate through each added and modified file, running the checks on swift files only
    for file in editedFiles {
        guard file.contains(".swift") else { return }
        let diff = danger.utils.diff(forFile: file, sourceBranch: diffBranches)
        // For modified, renamed hunks, or created new lines detect code usage to avoid in PR
        switch diff {
        case let .success(diff):
            switch diff.changes {
            case let .modified(hunks), let .renamed(_, hunks):
                detect(keywords: CodeUsageToDetect.allCases, inHunks: hunks, file: file)
            case let .created(newLines):
                detect(keywords: CodeUsageToDetect.allCases, inLines: newLines, file: file)
            case .deleted:
                break // do not warn on deleted lines
            }
        case .failure:
            break
        }
    }
}

// MARK: - Detect keyword helpers
func detect(keywords: [CodeUsageToDetect], inHunks hunks: [FileDiff.Hunk], file: String) {
    for keyword in keywords {
        detect(keyword: keyword.keyword, inHunks: hunks, file: file, message: keyword.message)
    }
}

func detect(keyword: String, inHunks hunks: [FileDiff.Hunk], file: String, message: String) {
    for hunk in hunks {
        var newLineCount = 0
        for line in hunk.lines {
            let isAddedLine = "\(line)".starts(with: "+")
            let isRemovedLine = "\(line)".starts(with: "-")
            // Make sure our newLineCount is proper to warn on correct line number
            guard isAddedLine || !isRemovedLine else { continue }
            newLineCount += 1

            // Warn only on added line having the particular keyword
            guard isAddedLine && String(describing: line).contains(keyword) else { continue }

            let lineNumber = hunk.newLineStart + newLineCount - 1
            warn(String(format: message, file, lineNumber))
        }
    }
}

func detect(keywords: [CodeUsageToDetect], inLines lines: [String], file: String) {
    for keyword in keywords {
        detect(keyword: keyword.keyword, inLines: lines, file: file, message: keyword.message)
    }
}

func detect(keyword: String, inLines lines: [String], file: String, message: String) {
    for (index, line) in lines.enumerated() where line.contains(keyword) {
        let lineNumber = index + 1
        warn(String(format: message, file, lineNumber))
    }
}

// MARK: - String Extension
extension String {
    // Helper function to escape (iOS) in our file name for xcov.
    func escapeString() -> String {
        var newString = self.replacingOccurrences(of: "(", with: "\\(")
        newString = newString.replacingOccurrences(of: ")", with: "\\)")
        newString = newString.replacingOccurrences(of: " ", with: "\\ ")
        return newString
    }
}
