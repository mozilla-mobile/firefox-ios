import Foundation
import Regex
import SwiftShell

let fromVersionFile = "./Sentry.podspec"

let files = [
    "./Sentry.podspec",
    "./Sources/Sentry/SentryClient.m",
    "./Sources/Configuration/Sentry.xcconfig"
]

let args = CommandLine.arguments

let regex = Regex("[0-9]+\\.[0-9]+\\.[0-9]+")
if regex.firstMatch(in: args[1]) == nil {
    exit(errormessage: "version number must fit x.x.x format" )
}

let fromVersionFileHandler = try open(fromVersionFile)
let fromFileContent: String = fromVersionFileHandler.read()

for match in Regex("[0-9]+\\.[0-9]+\\.[0-9]+", options: [.dotMatchesLineSeparators]).allMatches(in: fromFileContent) {
    let fromVersion = match.matchedString
    let toVersion = args[1]

    for file in files {
        let readFile = try open(file)
        let contents: String = readFile.read()
        let newContents = contents.replacingOccurrences(of: fromVersion, with: toVersion)
        let overwriteFile = try! open(forWriting: file, overwrite: true)
        overwriteFile.write(newContents)
        overwriteFile.close()
    }
}
