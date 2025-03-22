// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Danger
import DangerSwiftCoverage
import Foundation

/// Reference at https://danger.systems/swift/reference.html
let danger = Danger()
let standardImageIdentifiersPath = "./BrowserKit/Sources/Common/Constants/StandardImageIdentifiers.swift"

checkAlphabeticalOrder(inFile: standardImageIdentifiersPath)
checkBigPullRequest()
checkCodeCoverage()
checkForPRDescription()
checkForWebEngineFileChange()
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
        warn("This Pull Request seems quite large. If it consists of multiple changes, try splitting them into separate PRs for a faster review process. Consider using epic branches for work impacting main.")
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

// Detect and warn about some changes related to WebView management to ensure we port changes to the WebEngine project
func checkForWebEngineFileChange() {
    let webEngineFiles = ["Tab.swift", "BrowserViewController+WebViewDelegates.swift"]
    let modifiedFiles = danger.git.modifiedFiles
    let affectedFiles = modifiedFiles.filter { file in
        webEngineFiles.contains { webFile in file.hasSuffix(webFile) }
    }

    if !affectedFiles.isEmpty {
        let message = "Ensure that necessary updates are also ported to the WebEngine project if required"
        let contact = "(cc @lmarceau)."
        warn("Changes detected in files: \(affectedFiles.joined(separator: ", ")). \(message) \(contact)")
    }
}

// MARK: Detect code usage
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
// swiftlint:enable line_length

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

// MARK: - Acorn Alphabetical order
func checkAlphabeticalOrder(inFile filePath: String) {
    do {
        let fileContent = try String(contentsOfFile: filePath, encoding: .utf8)

        // Regex to find public structs and their bodies
        let structRegex = try NSRegularExpression(pattern: "public struct (\\w+) \\{([^}]+)\\}", options: [])
        // Regex to find public static let variables
        let varRegex = try NSRegularExpression(pattern: "public static let (\\w+)", options: [])

        let nsrange = NSRange(fileContent.startIndex..<fileContent.endIndex, in: fileContent)
        structRegex.enumerateMatches(in: fileContent, options: [], range: nsrange) { match, _, _ in
            guard let structMatch = match,
                  let structRange = Range(structMatch.range(at: 1), in: fileContent),
                  let bodyRange = Range(structMatch.range(at: 2), in: fileContent) else {
                return
            }

            let structName = String(fileContent[structRange])
            let bodyContent = String(fileContent[bodyRange])

            let range = NSRange(bodyContent.startIndex..<bodyContent.endIndex, in: bodyContent)
            let varMatches = varRegex.matches(in: bodyContent, options: [], range: range)

            // Extract variable names from matches
            let varNames = varMatches.compactMap { match -> String? in
                guard let range = Range(match.range(at: 1), in: bodyContent) else { return nil }
                return String(bodyContent[range])
            }

            // Sort by lowercase for case-insensitive comparison and then by length
            let sortedVarNames = varNames.sorted {
                $0.lowercased() == $1.lowercased() ? $0.count < $1.count : $0.lowercased() < $1.lowercased()
            }

            // Iterate through the list and report all variables that are out of order
            for (index, varName) in varNames.enumerated() where varName.lowercased() != sortedVarNames[index].lowercased() {
                let message = "Variable '\(varName)' in \(structName) is out of alphabetical order."
                danger.warn(message)
            }
        }
    } catch {
        danger.warn("Failed to read or process file \(filePath): \(error)")
    }
}
