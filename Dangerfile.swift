// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Danger
import DangerSwiftCoverage
import Foundation

/// Reference at https://danger.systems/swift/reference.html
let danger = Danger()
let standardImageIdentifiersPath = "./BrowserKit/Sources/Common/Constants/StandardImageIdentifiers.swift"

checkForFunMetrics()
checkAlphabeticalOrder(inFile: standardImageIdentifiersPath)
checkCodeCoverage()
failOnNewFilesWithoutCoverage()
checkForWebEngineFileChange()
checkForCodeUsage()
checkStringsFile()
BrowserViewControllerChecker().failsOnAddedExtension()

// Add some fun comments in Danger to have positive feedback on PRs
func checkForFunMetrics() {
    let edited = danger.git.modifiedFiles + danger.git.createdFiles
    let testFiles = edited.filter { path in
        path.localizedCaseInsensitiveContains("Tests/")
    }
    if !testFiles.isEmpty {
        markdown("""
        ### 💪 **Quality guardian**
        **\(testFiles.count)** tests files modified. You're a champion of test coverage! 🚀
        """)
    }

    let additions = danger.github?.pullRequest.additions ?? 0
    let deletions = danger.github?.pullRequest.deletions ?? 0
    if deletions > additions && (additions - deletions) > 50 {
        markdown("""
        ### 🗑️ **Tossing out clutter**
        **\(deletions - additions)** line(s) removed. Fewer lines, fewer bugs 🐛!
        """)
    }

    // Either comment for the small number of files changed or small number of lines changed, otherwise it gets crowded.
    let filesChanged = danger.github?.pullRequest.changedFiles ?? 0
    let totalLines = deletions + additions
    if filesChanged > 0 && filesChanged <= 5 {
        markdown("""
        ### 🧹 **Tidy commit**
        Just **\(filesChanged)** file(s) touched. Thanks for keeping it clean and review-friendly!
        """)
    } else if totalLines > 0 && totalLines < 50 {
        markdown("""
        ### 🌱 **Tiny but mighty**
        Only **\(totalLines)** line(s) changed. Fast to review, faster to land! 🚀
        """)
    } else {
        checkBigPullRequest()
    }

    let weekday = Calendar(identifier: .gregorian).component(.weekday, from: Date()) // 6 = Friday
    if weekday == 6 {
        markdown("""
        ### 🙌 **Friday high-five**
        Thanks for pushing us across the finish line this week! 🙌
        """)
    }

    let docTouched = edited.contains { $0.contains(".md") }
    if docTouched {
        markdown("""
        ### 🌟 **Documentation star**
        Great documentation touches. Future you says thank you! 📚
        """)
    }

    checkDescriptionSection()
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

func failOnNewFilesWithoutCoverage() {
    let jsonPath = "coverage.json"

    guard let data = FileManager.default.contents(atPath: jsonPath),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let targets = json["targets"] as? [[String: Any]] else {
        fail("Could not parse coverage.json for per-file coverage")
        return
    }

    // Build an array with files with 0 coverage
    var filesWithoutCoverage = [String]()
    for target in targets {
        if let files = target["files"] as? [[String: Any]] {
            for file in files {
                if let path = file["name"] as? String,
                      let coverage = file["lineCoverage"] as? Double, coverage == 0 {
                    filesWithoutCoverage.append(path)
                }
            }
        }
    }

    // Get new files filtering Test and Generated
    let newSwiftFiles = danger.git.createdFiles.filter {
        $0.hasSuffix(".swift") &&
        !$0.contains("Tests") &&
        !$0.contains("/Generated/")
    }

    let contactMessage = "Please add unit tests. (cc: @cyndichin @yoanarios)."
    for file in newSwiftFiles {
        let cleanedFile = URL(fileURLWithPath: file).lastPathComponent

        // Try to find a file in coverage report that ends with this file
        let matchingFile = filesWithoutCoverage.first { coveragePath in
            coveragePath.hasSuffix(cleanedFile)
        }

        if let file = matchingFile {
            warn("New file `\(file)` has 0% test coverage. \(contactMessage)")
        }
    }
}

// MARK: - PR guidelines

// swiftlint:disable line_length
// Encourage smaller PRs
func checkBigPullRequest() {
    let mediumPRThreshold = 400
    let bigPRThreshold = 800
    let monsterPRThreshold = 2000
    guard let additions = danger.github.pullRequest.additions,
          let deletions = danger.github.pullRequest.deletions else { return }

    let additionsAndDeletions = additions + deletions
    if additionsAndDeletions > monsterPRThreshold {
        markdown("""
        ### 🧟‍♂️ **Monster PR**
        Wow, this PR is **huge** with \(additionsAndDeletions) lines changed!
        Thanks for powering through such a big task 🙌.
        Reviewers: feel free to ask for extra context, screenshots, or a breakdown to make reviewing smoother.
        """)
    } else if additionsAndDeletions > bigPRThreshold {
        markdown("""
        ### 🏔️ **Summit Climber**
        This PR is a **big climb** with \(additionsAndDeletions) lines changed!
        Thanks for taking on the heavy lifting 💪.
        Reviewers: a quick overview or walkthrough will make the ascent smoother.
        """)
    } else if additionsAndDeletions > mediumPRThreshold {
        markdown("""
        ### 🧩 **Neat Piece**
        This PR changes \(additionsAndDeletions) lines. It's a substantial update,
        but still review-friendly if there’s a clear description. Thanks for keeping things moving! 🚀
        """)
    } else {
        markdown("""
        ### 🥇 **Perfect PR size**
        Smaller PRs are easier to review. Thanks for making life easy for reviewers! ✨
        """)
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
    // Iterate through each added and modified file, running the checks on swift files only
    for file in editedFiles where file.contains(".swift") {
        // For modified, renamed hunks, or created new lines detect code usage to avoid in PR
        switch saferFileDiff(for: file) {
        case let .success(diff):
            if file == BrowserViewControllerChecker.bvcPath {
                BrowserViewControllerChecker().checkBrowserViewControllerSize(fileDiff: diff)
            }

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

private func saferFileDiff(for file: String) -> Result<FileDiff, Error> {
    let baseSHA = danger.github.pullRequest.base.sha
    let headSHA = danger.github.pullRequest.head.sha
    let baseRef = danger.github.pullRequest.base.ref // e.g. "main"

    // Try the SHA range first
    let range = "\(baseSHA)..\(headSHA)"
    switch danger.utils.diff(forFile: file, sourceBranch: range) {
    case .success(let result): return .success(result)
    case .failure:
        break
    }

    // Fallback 1: remote tracking branch
    switch danger.utils.diff(forFile: file, sourceBranch: "origin/\(baseRef)") {
    case .success(let result): return .success(result)
    case .failure:
        break
    }

    // Fallback 2: local branch name (if present)
    switch danger.utils.diff(forFile: file, sourceBranch: baseRef) {
    case .success(let result): return .success(result)
    case .failure(let error):
        return .failure(error)
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
                warn(message)
            }
        }
    } catch {
        warn("Failed to read or process file \(filePath): \(error)")
    }
}

// Check if there's String file changes, and if so ask the l10n reviewers
func checkStringsFile() {
    let edited = danger.git.modifiedFiles
    let touchedStrings = edited.filter { path in
        path.localizedCaseInsensitiveContains("/Strings.swift")
    }

    if !touchedStrings.isEmpty {
        markdown("""
        ### ✍️ **Strings Updated**
        Detected changes in `Shared/Strings.swift`.
        To keep strings up to standards, please tag a member of the [firefox-ios-l10n team](https://github.com/orgs/mozilla-mobile/teams/firefox-ios-l10n) for review. 🌍
        """)
    }
}

func checkDescriptionSection() {
    guard let body = danger.github.pullRequest.body else { return }

    // Regex to capture everything between "## :bulb: Description" and "## :movie_camera: Demos"
    guard let regexDescriptionDemo = try? NSRegularExpression(
        pattern: #"(?s)## :bulb: Description\s*(.*?)## :movie_camera: Demos"#,
        options: []
    ) else { return }

    // Regex to capture everything between "## :bulb: Description" and "## :pencil: Checklist"
    guard let regexDescriptionChecklist = try? NSRegularExpression(
        pattern: #"(?s)## :bulb: Description\s*(.*?)## :pencil: Checklist"#,
        options: []
    ) else { return }

    if let match = regexDescriptionDemo.firstMatch(in: body,
                                                   options: [],
                                                   range: NSRange(location: 0, length: body.utf16.count)),
       let range = Range(match.range(at: 1), in: body) {
        // Extract description content
        var desc = String(body[range])
        // Strip out HTML comments so `<!--- ... -->` placeholders don't count
        desc = desc.replacingOccurrences(of: #"<!--.*?-->"#, with: "", options: .regularExpression)

        commentDescriptionSection(desc: desc)
    } else if let match = regexDescriptionChecklist.firstMatch(in: body,
                                                               options: [],
                                                               range: NSRange(location: 0, length: body.utf16.count)),
              let range = Range(match.range(at: 1), in: body) {
        // Extract description content
        var desc = String(body[range])
        // Strip out HTML comments so `<!--- ... -->` placeholders don't count
        desc = desc.replacingOccurrences(of: #"<!--.*?-->"#, with: "", options: .regularExpression)
        commentDescriptionSection(desc: desc)
    }
}

func commentDescriptionSection(desc: String) {
    let count = desc.trimmingCharacters(in: .whitespacesAndNewlines).count
    if count == 0 {
        fail("""
            Details needed! Your description section is empty. Adding a bit more context will make reviews smoother.
            """)
    } else if count < 10 {
        warn("""
            Extra details help! Your description section is a bit short (\(count) characters). Adding a bit more context will make reviews smoother.
            """)
    } else if count >= 300 {
        markdown("""
            ### 💬 **Description craftsman**
            Great PR description! Reviewers salute you 🫡
            """)
    }
}

class BrowserViewControllerChecker {
    static let bvcPath = "firefox-ios/Client/Frontend/Browser/BrowserViewController/Views/BrowserViewController.swift"
    private lazy var bvcExtRegex: NSRegularExpression? = try? NSRegularExpression(
        pattern: #"firefox-ios/Client/Frontend/Browser/BrowserViewController/Views/BrowserViewController\+.+\.swift$"#,
        options: []
    )

    // Fail on new BrowserViewController extensions
    func failsOnAddedExtension() {
        guard let regex = bvcExtRegex else {
            warn("BVC extension regex failed to compile; skipping BVC extension check.")
            return
        }

        let created = danger.git.createdFiles
        let newBvcExtensions = created.filter { matches(regex, $0) }

        if newBvcExtensions.count == 1 {
            fail("""
            New `BrowserViewController+*.swift` file detected: \(newBvcExtensions)
            """)
        } else if !newBvcExtensions.isEmpty {
            let bullets = newBvcExtensions.map { "• `\($0)`" }.joined(separator: "\n")
            fail("""
            New `BrowserViewController+*.swift` files detected:
            \(bullets)
            """)
        }
    }

    // Apply soft size rule to BrowserViewController.swift using Danger's diff API
    func checkBrowserViewControllerSize(fileDiff: FileDiff) {
        let counts = addedRemoved(from: fileDiff.changes)
        let delta = counts.added - counts.removed
        if delta < 0 {
            let number = abs(delta)
            let plural = number == 1 ? "" : "s"
            markdown("""
            ### 🎉 **BrowserViewController got smaller**
            Nice! `BrowserViewController.swift` got smaller by \(number) line\(plural).
            """)
            return
        } else if delta > 0 {
            let plural = delta == 1 ? "" : "s"
            markdown("""
            ### 🦊 BrowserViewController Check
            We’re tracking the size of `BrowserViewController.swift` to keep it healthy.
            - ✨ Change in file size: **+\(delta) line\(plural)**
            """)
        }
    }

    private func matches(_ regex: NSRegularExpression, _ string: String) -> Bool {
        let range = NSRange(location: 0, length: (string as NSString).length)
        return regex.firstMatch(in: string, options: [], range: range) != nil
    }

    private func addedRemoved(from changes: FileDiff.Changes) -> (added: Int, removed: Int) {
        switch changes {
        case .created(let newLines):
            // All lines are additions in a created file
            return (added: newLines.count, removed: 0)

        case .deleted:
            // Entire file deleted; we can’t easily know how many lines existed here, treat as big shrink
            // Returning a negative value ensures we celebrate shrinkage.
            return (added: 0, removed: 1) // minimal negative delta

        case .modified(let hunks):
            return countInHunks(hunks)

        case .renamed(_, let hunks):
            return countInHunks(hunks)
        }
    }

    private func countInHunks(_ hunks: [FileDiff.Hunk]) -> (added: Int, removed: Int) {
        var added = 0
        var removed = 0
        for hunk in hunks {
            for line in hunk.lines {
                // Danger’s line type is printable; use its string form.
                let s = String(describing: line)
                // Count “real” content lines; skip file headers just in case.
                if s.hasPrefix("+") && !s.hasPrefix("+++") {
                    added += 1
                } else if s.hasPrefix("-") && !s.hasPrefix("---") {
                    removed += 1
                }
            }
        }
        return (added, removed)
    }
}
