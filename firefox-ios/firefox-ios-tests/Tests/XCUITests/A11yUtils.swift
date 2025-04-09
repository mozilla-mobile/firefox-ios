// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class A11yUtils: XCTestCase {
    public struct MissingAccessibilityElement {
        public let elementType: String
        public let identifier: String
        public let screen: String

        public init(elementType: String, identifier: String, screen: String) {
            self.elementType = elementType
            self.identifier = identifier
            self.screen = screen
        }
    }

    public static func checkMissingLabels(in elements: [XCUIElement],
                                          screenName: String,
                                          missingLabels: inout [MissingAccessibilityElement],
                                          elementType: String) {
        for element in elements {
            let hasA11yLabel = !(element.accessibilityLabel?.isEmpty ?? true)
            let hasLabel = !(element.label.isEmpty) // Checks visible UI label

            guard element.exists else { continue }
            if !hasA11yLabel && !hasLabel && !element.identifier.isEmpty {
                missingLabels.append(A11yUtils.MissingAccessibilityElement(
                    elementType: elementType,
                    identifier: element.identifier,
                    screen: screenName
                ))
            }
        }
    }

    public static func checkButtonLabels(
        in element: XCUIElement,
        screenName: String,
        missingLabels: inout [MissingAccessibilityElement]
    ) {
        // If the element is a button, check its labels.
        if element.elementType == .button {
            let hasA11yLabel = !(element.accessibilityLabel?.isEmpty ?? true)
            let hasLabel = !(element.label.isEmpty)
            if !hasA11yLabel && !hasLabel && !element.identifier.isEmpty {
                missingLabels.append(MissingAccessibilityElement(
                    elementType: "Button",
                    identifier: element.identifier,
                    screen: screenName
                ))
            }
        }

        // Recursively check all children of the current element.
        let children = element.children(matching: .any).allElementsBoundByIndex
        for child in children where child.exists {
            checkButtonLabels(in: child, screenName: screenName, missingLabels: &missingLabels)
        }
    }

    // Generates a TXT report for missing accessibility labels.
    public static func generateTxtReport(missingLabels: [MissingAccessibilityElement]) -> String {
        var report = "⚠️ Missing Accessibility Labels or UI Labels:\n\n"
        for (index, element) in missingLabels.enumerated() {
            report += "\(index + 1). Type: \(element.elementType), " +
                    "Identifier: \(element.identifier), " +
                    "Screen: \(element.screen)\n"
        }
        return report
    }

    // Generates a CSV report for missing accessibility labels.
    public static func generateCSVReport(missingLabels: [MissingAccessibilityElement]) -> String {
        var csv = "ElementType,Identifier,Frame\n"
        for element in missingLabels {
            csv += "\"\(element.elementType)\",\"\(element.identifier)\",\"\(element.screen)\"\n"
        }
        return csv
    }

    // Saves the given report content to a file and returns the file path.
    public static func saveReportToFile(report: String, fileName: String) -> URL {
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)

        do {
            try report.write(to: fileURL, atomically: true, encoding: .utf8)
            print("📄 Report saved to: \(fileURL.path)")
        } catch {
            print("❌ Failed to save report: \(error)")
        }

        return fileURL
    }

    // Generates the report and attaches it to the XCUITest results.
    public static func generateAndAttachReport(missingLabels: [MissingAccessibilityElement]) {
        XCTContext.runActivity(named: "Accessibility Report") { activity in
            if missingLabels.isEmpty {
                activity.add(XCTAttachment(string: "✅ All elements have accessibility labels 🎉"))
            } else {
                let reportText = generateTxtReport(missingLabels: missingLabels)
                let reportCSV = generateCSVReport(missingLabels: missingLabels)

                // Save to files
                let txtFilePath = saveReportToFile(report: reportText, fileName: "AccessibilityReport.txt")
                // Attach reports to Xcode test results
                let txtAttachment = XCTAttachment(contentsOfFile: txtFilePath)
                txtAttachment.lifetime = .keepAlways
                activity.add(txtAttachment)

                let csvFilePath = saveReportToFile(report: reportCSV, fileName: "AccessibilityReport.csv")
                let csvAttachment = XCTAttachment(contentsOfFile: csvFilePath)
                csvAttachment.lifetime = .keepAlways
                activity.add(csvAttachment)
            }
        }
    }
}
