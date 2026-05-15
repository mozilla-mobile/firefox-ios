// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Danger
import DangerSwiftCoverage
import Foundation

/// Reference at https://danger.systems/swift/reference.html
let danger = Danger()
let standardImageIdentifiersPath = "./BrowserKit/Sources/Common/Constants/StandardImageIdentifiers.swift"

let releaseCheck = ReleaseBranchCheck()
if releaseCheck.isReleaseBranch {
    releaseCheck.postReleaseBranchComment()
} else {
    checkStringsFile()
    checkForFunMetrics()
    checkAlphabeticalOrder(inFile: standardImageIdentifiersPath)
    checkForSpecificFileChange()
    checkForGleanFileChange()
    CodeUsageDetector().checkForCodeUsage()
    let coverageGate = CodeCoverageGate()
    coverageGate.failOnFiles(type: .newFiles)
    coverageGate.failOnFiles(type: .modifiedFiles)
    BrowserViewControllerChecker().failsOnAddedExtension()
    checkCodeCoverage()
}

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

// MARK: Code coverage

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

class CodeCoverageGate {
    private let coverageBypassLabel = "ignore-code-coverage"
    private let jsonPath = "coverage.json"

    enum CoverageType {
        case newFiles
        case modifiedFiles

        var sourceFiles: [String] {
            switch self {
            case .newFiles: return danger.git.createdFiles
            case .modifiedFiles: return danger.git.modifiedFiles
            }
        }

        var minimumLines: Int {
            switch self {
            case .newFiles: return 5
            case .modifiedFiles: return 20
            }
        }

        var label: String {
            switch self {
            case .newFiles: return "New file"
            case .modifiedFiles: return "Existing file"
            }
        }

        var emptyMessage: String {
            switch self {
            case .newFiles: return "No new file detected so code coverage gate wasn't ran."
            case .modifiedFiles: return "No modified file detected so code coverage gate wasn't ran."
            }
        }

        var insufficientChangesMessage: String {
            switch self {
            case .newFiles: return "No new file had significant enough changes for the coverage gate to run."
            case .modifiedFiles: return "No modified file had significant enough changes for the coverage gate to run."
            }
        }

        var allPassMessage: String {
            switch self {
            case .newFiles: return "All new files meet their thresholds**."
            case .modifiedFiles: return "All modified files meet their thresholds."
            }
        }

        var thresholdRange: (min: Double, max: Double) {
            switch self {
            case .newFiles: return (min: 0.4, max: 0.7)
            case .modifiedFiles: return (min: 0.10, max: 0.25)
            }
        }
    }

    func failOnFiles(type: CoverageType) {
        guard let coverageFiles = parseCoverageFiles() else { return }

        let candidates = swiftSourceCandidates(from: type.sourceFiles)

        guard !candidates.isEmpty else {
            markdown("""
            ### ✅ \(type.label) code coverage
            \(type.emptyMessage)
            """)
            return
        }

        // Ignore tiny edits: only gate files with at least `type.minimumLines`
        let gated = candidates.filter { addedLines(in: $0) >= type.minimumLines }

        guard !gated.isEmpty else {
            markdown("""
            ### ✅ \(type.label) code coverage
            \(type.insufficientChangesMessage)
            """)
            return
        }

        // Collect failures
        var rows: [String] = []
        for file in gated {
            // Find matching coverage entry
            let entry = coverageMatch(repoPath: file, coverageFiles: coverageFiles)

            // Extract percentage (supports 0..1 or 0..100 in lineCoverage)
            let percent: Double = {
                guard let entry, let raw = entry["lineCoverage"] as? Double else { return 0 }
                return raw <= 1.000001 ? raw * 100.0 : raw
            }()

            // Calculate threshold based on file length
            let lineCount = countLines(in: file)
            let threshold = scaledPercentage(for: Double(lineCount), in: type.thresholdRange) * 100.0

            if percent + 0.0001 < threshold { // epsilon for float stability
                rows.append("| `\(file)` | \(formatPct(percent)) | \(formatPct(threshold)) |")
            }
        }

        guard !rows.isEmpty else {
            markdown("""
            ### ✅ \(type.label) code coverage
            \(type.allPassMessage)
            """)
            return
        }

        reportCoverageFailure(rows: rows, label: type.label)
    }

    private func swiftSourceCandidates(from files: [String]) -> [String] {
        files.filter {
            $0.hasSuffix(".swift") &&
            !$0.contains("Tests/") &&
            !$0.contains("/Generated/") &&
            !$0.contains("/Strings.swift") &&
            !$0.contains("/AccessibilityIdentifiers.swift") &&
            !$0.contains("ImageIdentifiers.swift") &&
            !$0.contains("Protocol.swift") &&
            !$0.contains("Dangerfile.swift")
        }
    }

    private func parseCoverageFiles() -> [[String: Any]]? {
        guard let data = FileManager.default.contents(atPath: jsonPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let targets = json["targets"] as? [[String: Any]] else {
            fail("Could not parse coverage.json for per-file coverage")
            return nil
        }
        return targets.flatMap { $0["files"] as? [[String: Any]] ?? [] }
    }

    private func addedLines(in file: String) -> Int {
        switch saferFileDiff(for: file) {
        case .success(let diff):
            switch diff.changes {
            case .created(let newLines):
                return newLines.count
            case .deleted:
                return 0
            case .modified(let hunks), .renamed(_, let hunks):
                return hunks.reduce(0) { acc, h in
                    acc + h.lines.filter {
                        let s = String(describing: $0)
                        return s.hasPrefix("+") && !s.hasPrefix("+++")
                    }.count
                }
            }
        case .failure:
            return 999 // if diff fails, be conservative and mention it
        }
    }

    private func reportCoverageFailure(rows: [String], label: String) {
        let header = """
        ### ❌ \(label) code coverage
        The following file(s) are below their scaled coverage:

        | File | Coverage | Required |
        |---|---:|---:|
        \(rows.joined(separator: "\n"))
        """
        if hasLabel(coverageBypassLabel) {
            warn("\(header)\n\n*Bypass label `\(coverageBypassLabel)` detected — reporting as warnings only for this PR.*")
        } else {
            let tip = "You can add the `\(coverageBypassLabel)` label with a short justification to bypass this check."
            let team = "[@fxios-unit-test-owners](https://github.com/orgs/mozilla-mobile/teams/fxios-unit-test-owners)"
            let owners = "Please also tag a member of the \(team) if the bypass is used."
            fail("\(header)\n\n\(tip) \(owners)")
        }
    }

    /// Maps an input value to a percentage using logarithmic scaling within the given range.
    /// - Parameter x: Input value (must be > 0)
    /// - Parameter range: The output min/max bounds for the scaling
    /// - Returns: A scaled value within `range` for inputs between 10 and 500
    private func scaledPercentage(for x: Double, in range: (min: Double, max: Double)) -> Double {
        precondition(x > 0, "Input must be greater than 0")

        let minX = 10.0
        let maxX = 500.0

        // Clamp to min/max bounds
        if x <= minX { return range.min }
        if x >= maxX { return range.max }

        let numerator = log(x / minX)
        let denominator = log(maxX / minX)

        return range.min + (range.max - range.min) * (numerator / denominator)
    }

    /// Counts the number of lines in a file
    /// - Parameter filePath: Path to the file
    /// - Returns: Number of lines in the file, or 0 if file cannot be read
    private func countLines(in filePath: String) -> Int {
        guard let content = try? String(contentsOfFile: filePath, encoding: .utf8) else {
            return 0
        }
        return content.components(separatedBy: .newlines).count
    }

    // Small helper to format percentages
    private func formatPct(_ value: Double) -> String {
        String(format: "%.1f%%", value)
    }

    // Match repo file to coverage entry by filename/suffix
    private func coverageMatch(repoPath: String, coverageFiles: [[String: Any]]) -> [String: Any]? {
        let repoFile = URL(fileURLWithPath: repoPath).lastPathComponent
        // Exact filename match first
        let sameName = coverageFiles.filter {
            URL(fileURLWithPath: ($0["name"] as? String) ?? "").lastPathComponent == repoFile
        }
        if sameName.count == 1 { return sameName.first }
        if sameName.count > 1 {
            // Disambiguate by longest common suffix with repoPath
            func commonSuffixLen(_ a: String, _ b: String) -> Int {
                let ar = Array(a.reversed()), br = Array(b.reversed())
                var i = 0; while i < ar.count && i < br.count && ar[i] == br[i] { i += 1 }; return i
            }
            return sameName.max { a, b in
                let sa = (a["name"] as? String) ?? "", sb = (b["name"] as? String) ?? ""
                return commonSuffixLen(sa, repoPath) < commonSuffixLen(sb, repoPath)
            }
        }
        // Fallback: raw suffix match
        return coverageFiles.first { entry in
            guard let name = entry["name"] as? String else { return false }
            return name.hasSuffix(repoPath) || repoPath.hasSuffix(name)
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

// Detect and tag specific people whenever specific files are modified
func checkForSpecificFileChange() {
    let modifiedFiles = danger.git.modifiedFiles

    struct FileCheck {
        let fileMatches: (String) -> Bool
        let message: String
        let contacts: String
        var foundMatches: [String] = []
    }

    var fileChecks = [
        FileCheck(
            fileMatches: { file in
                ["Tab.swift",
                 "TabManager.swift",
                 "TabManagerImplementation.swift",
                 "BrowserViewController+WebViewDelegates.swift"
                ].contains { file.hasSuffix($0) }
            },
            message: "Detected tab related changes in:",
            contacts: "(cc @lmarceau)"
        ),
        FileCheck(
            fileMatches: { $0.hasSuffix(".sh") },
            message: "Detected shell script changes in:",
            contacts: "(cc @adudenamedruby)"
        ),
        FileCheck(
            fileMatches: { file in
                file.contains("firefox-ios/Client/Glean/") && (file.hasSuffix(".yaml"))
            },
            message: "Detected telemetry changes in:",
            contacts: "(cc @ih-codes @adudenamedruby)"
        )
    ]

    for file in modifiedFiles {
        for fileIndex in fileChecks.indices where fileChecks[fileIndex].fileMatches(file) {
            fileChecks[fileIndex].foundMatches.append(file)
        }
    }

    // Issue warnings only for categories with matches
    for check in fileChecks where !check.foundMatches.isEmpty {
        let matches = check.foundMatches.joined(separator: ", ")
        warn("\(check.message) \(matches) \(check.contacts)")
    }
}

// Detect additions to Glean telemetry files and request data review
func checkForGleanFileChange() {
    let gleanPath = "firefox-ios/Client/Glean/"
    let createdFiles = danger.git.createdFiles.filter { $0.contains(gleanPath) }
    let modifiedFiles = danger.git.modifiedFiles.filter { $0.contains(gleanPath) }

    // For modified files, check if there are actual additions (not just deletions)
    let modifiedWithAdditions = modifiedFiles.filter { file in
        switch saferFileDiff(for: file) {
        case .success(let diff):
            switch diff.changes {
            case .modified(let hunks), .renamed(_, let hunks):
                // Check if any lines were added
                return hunks.contains { hunk in
                    hunk.lines.contains { line in
                        let s = String(describing: line)
                        return s.hasPrefix("+") && !s.hasPrefix("+++")
                    }
                }
            case .created:
                return true
            case .deleted:
                return false
            }
        case .failure:
            // If diff fails, be conservative and include the file
            return true
        }
    }

    let affectedFiles = createdFiles + modifiedWithAdditions
    if !affectedFiles.isEmpty {
        markdown("""
        ### 📊 **Telemetry changes detected**
        Changes with additions detected in Glean telemetry files:
        \(affectedFiles.map { "• `\($0)`" }.joined(separator: "\n"))

        Any additions to telemetry will require a data review. Please fill out a data review form \
        (found in the [data review repo](https://github.com/mozilla/data-review)) as necessary, \
        and tag @adudenamedruby for data review.
        """)
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

// MARK: - Detect code usage

// Detects Keywords in PR so certain functions are not used in new code.
class CodeUsageDetector {
    // In uniffi generated code, we might have print statements automatically generated.
    private let allowedPrintDirectories: [String] = [
        "MozillaRustComponents/Sources/FocusRustComponentsWrapper/Generated/",
        "MozillaRustComponents/Sources/MozillaRustComponentsWrapper/Generated/"
    ]

    private struct Detection {
        let keyword: Keywords
        let file: String
        let lineNumber: Int
        let isRemoval: Bool
    }

    private enum Keywords: CaseIterable {
        static let commonLoggerSentence = " Please remove this usage from production code or use BrowserKit Logger."

        case print
        case nsLog
        case osLog
        case deferred
        case swiftUIText
        case task
        case notifiable
        case unsafe
        case cspHeader
        case sha256

        var bundledHeader: String {
            switch self {
            case .print:
                return "### ⚠️ `print()` usage detected\nPrint() function seems to be used.\(Keywords.commonLoggerSentence)"
            case .nsLog:
                return "### ⚠️ `NSLog()` usage detected\nNSLog() function seems to be used.\(Keywords.commonLoggerSentence)"
            case .osLog:
                return "### ⚠️ `os_log()` usage detected\nos_log() function seems to be used.\(Keywords.commonLoggerSentence)"
            case .deferred:
                return "### ⚠️ `Deferred` usage detected\nDeferred class is used. Please replace with completion handler instead."
            case .swiftUIText:
                return "### ⚠️ SwiftUI `Text(\"\")` usage detected\nSwiftUI 'Text(\"\"' needs to be avoided, use Strings.swift localization instead."
            case .task:
                let contacts = "@Cramsden @ih-codes @lmarceau"
                return "### 🧑‍💻 New `Task {}` detected\nNew `Task {}` added. Please add a concurrency reviewer on your PR: \(contacts)"
            case .notifiable:
                return "### ⚠️ `NotificationCenter.default.addObserver` detected\nPlease prefer Notifiable over `NotificationCenter` unless specific circumstances."
            case .unsafe:
                return "### 🔒 Security: CSP `unsafe-` detected\nPlease request a security review."
            case .cspHeader:
                return "### 🔒 Security: `Content-Security-Policy` change detected\nPlease request a security review."
            case .sha256:
                return "### 🔒 Security: `sha256` hash changes detected\nPlease request a security review."
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
            case .swiftUIText:
                return " Text(\""
            case .task:
                return " Task {"
            case .notifiable:
                return "NotificationCenter.default.addObserver("
            case .unsafe:
                return "unsafe-"
            case .cspHeader:
                return "Content-Security-Policy"
            case .sha256:
                return "sha256"
            }
        }

        func applies(to file: String) -> Bool {
            switch self {
            case .unsafe, .cspHeader, .sha256:
                return file.hasSuffix(".swift") || file.hasSuffix(".js")
            default:
                return file.contains(".swift")
            }
        }

        // Comment with `markdown` instead of `warn` or `fail`. Has precedence over `shouldWarn`.
        var shouldComment: Bool {
            switch self {
            case .task:
                return true
            default:
                return false
            }
        }

        // Decide if we want to `warn` instead of `fail` on the pull request.
        var shouldWarn: Bool {
            switch self {
            case .deferred, .notifiable:
                return true
            default:
                return false
            }
        }

        // Default is true, expect for some additions that aren't worth flagging
        var detectsAdditions: Bool {
            switch self {
            case .sha256: return false
            default: return true
            }
        }

        // Most code removals we don't want to flag, expect for some
        var detectsRemovals: Bool {
            switch self {
            case .cspHeader, .sha256: return true
            default: return false
            }
        }
    }
    // swiftlint:enable line_length

    private func shouldSkip(_ keyword: Keywords, for file: String) -> Bool {
        // Only skip `print(` in whitelisted directories
        guard keyword == .print else { return false }
        return allowedPrintDirectories.contains { file.contains($0) }
    }

    func checkForCodeUsage() {
        var detections: [Detection] = []
        let editedFiles = danger.git.modifiedFiles + danger.git.createdFiles
        for file in editedFiles where !file.contains("Dangerfile") {
            let applicable = Keywords.allCases.filter { $0.applies(to: file) }
            guard !applicable.isEmpty else { continue }

            switch saferFileDiff(for: file) {
            case let .success(diff):
                if file == BrowserViewControllerChecker.bvcPath {
                    BrowserViewControllerChecker().checkBrowserViewControllerSize(fileDiff: diff)
                }
                switch diff.changes {
                case let .modified(hunks), let .renamed(_, hunks):
                    detections += collect(keywords: applicable, inHunks: hunks, file: file)
                case let .created(newLines):
                    detections += collect(keywords: applicable, inLines: newLines, file: file)
                case .deleted:
                    break // do not warn on deleted lines
                }
            case .failure:
                break
            }
        }

        // Group by keyword and emit one bundled message per keyword
        let grouped = Dictionary(grouping: detections, by: { $0.keyword })
        for keyword in Keywords.allCases {
            guard let items = grouped[keyword], !items.isEmpty else { continue }
            emitBundled(keyword: keyword, detections: items)
        }
    }

    private func emitBundled(keyword: Keywords, detections: [Detection]) {
        // You can add the `danger-bypass` label with a justification to bypass this check.
        let rows = detections.map { "| `\($0.file)` | \($0.lineNumber) | \($0.isRemoval ? "Removed" : "Added") |" }.joined(separator: "\n")
        let fullMessage = """
        \(keyword.bundledHeader)

        | File | Line | Change |
        |---|---|---|
        \(rows)
        \nYou can add the `danger-bypass` label with a justification to bypass those checks.\nPlease add a comment explaining why the checks are by-passed.
        """

        if keyword.shouldComment {
            markdown(fullMessage)
        } else if keyword.shouldWarn {
            warn(fullMessage)
        } else {
            failOrWarn(fullMessage)
        }
    }

    private func collect(keywords: [Keywords], inHunks hunks: [FileDiff.Hunk], file: String) -> [Detection] {
        keywords.flatMap { collect(keyword: $0, inHunks: hunks, file: file) }
    }

    private func collect(keyword: Keywords, inHunks hunks: [FileDiff.Hunk], file: String) -> [Detection] {
        guard !shouldSkip(keyword, for: file) else { return [] }
        var detections: [Detection] = []
        for hunk in hunks {
            var newLineCount = 0
            var oldLineCount = 0
            for line in hunk.lines {
                let lineStr = String(describing: line)
                let isAddedLine = lineStr.starts(with: "+")
                let isRemovedLine = lineStr.starts(with: "-")
                if isRemovedLine {
                    oldLineCount += 1
                    if keyword.detectsRemovals && lineStr.contains(keyword.keyword) {
                        let lineNumber = hunk.oldLineStart + oldLineCount - 1
                        detections.append(Detection(keyword: keyword, file: file, lineNumber: lineNumber, isRemoval: true))
                    }
                } else {
                    // Context or added line: exists in both old and new file
                    newLineCount += 1
                    oldLineCount += 1
                    if isAddedLine && keyword.detectsAdditions && lineStr.contains(keyword.keyword) {
                        let lineNumber = hunk.newLineStart + newLineCount - 1
                        detections.append(Detection(keyword: keyword, file: file, lineNumber: lineNumber, isRemoval: false))
                    }
                }
            }
        }
        return detections
    }

    private func collect(keywords: [Keywords], inLines lines: [String], file: String) -> [Detection] {
        keywords.flatMap { collect(keyword: $0, inLines: lines, file: file) }
    }

    private func collect(keyword: Keywords, inLines lines: [String], file: String) -> [Detection] {
        guard !shouldSkip(keyword, for: file) else { return [] }
        guard keyword.detectsAdditions else { return [] }
        return lines.enumerated().compactMap { index, line in
            guard line.contains(keyword.keyword) else { return nil }
            return Detection(keyword: keyword, file: file, lineNumber: index + 1, isRemoval: false)
        }
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

// MARK: - Label by-pass
// Used to by-pass a failure with the label `danger-bypass` on the pull request

private func hasLabel(_ bypassLabel: String) -> Bool {
    let labelNames = danger.github.issue.labels
    for label in labelNames where label.name == bypassLabel {
        return true
    }
    return false
}

/// Call this instead of `fail` when you want a "bypassable" failure.
/// If the PR has the bypass label, this becomes a `warn` instead.
private func failOrWarn(_ message: String) {
    let bypassLabel = "danger-bypass"
    if hasLabel(bypassLabel) {
        warn("""
        \(message)
        Since bypass label \(bypassLabel) detected we are reporting as warning only for this PR.
        """)
    } else {
        fail(message)
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
        To keep strings up to standards, please add a member of the [firefox-ios-l10n team](https://github.com/orgs/mozilla-mobile/teams/firefox-ios-l10n) as reviewer. 🌍
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
    if count == 0 { // swiftlint:disable:this empty_count
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

struct ReleaseBranchCheck {
    var isReleaseBranch: Bool {
        danger.github.pullRequest.base.ref.hasPrefix("release/")
    }

    func postReleaseBranchComment() {
        markdown("""
        # ‼️ ATTENTION ‼️
        ### 🎯 This PR targets a **release branch**.
        Please ensure you've followed the [uplift request process](https://github.com/mozilla-mobile/firefox-ios/wiki/Requesting-an-uplift-to-a-release-branch).
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
            failOrWarn("""
            New `BrowserViewController+*.swift` file detected: \(newBvcExtensions)
            """)
        } else if !newBvcExtensions.isEmpty {
            let bullets = newBvcExtensions.map { "• `\($0)`" }.joined(separator: "\n")
            failOrWarn("""
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
