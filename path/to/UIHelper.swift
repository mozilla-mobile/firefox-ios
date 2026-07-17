// UIHelper.swift

import SwiftUI

/// Maximum number of lines to wrap to
let MAX_LINES = 3

/// Wraps text to multiple lines
func wrapText(_ text: String, to maxLines: Int = MAX_LINES) -> [String] {
    var lines = [String]()
    var currentLine = ""
    
    for word in text.components(separatedBy: " ") {
        if currentLine.count + word.count > 20 {
            lines.append(currentLine)
            currentLine = word
        } else {
            if currentLine != "" {
                currentLine += " "
            }
            currentLine += word
        }
    }
    
    if !currentLine.isEmpty {
        lines.append(currentLine)
    }
    
    return lines
}

/// Returns a multi-line text view
func multiLineTextView(_ text: String) -> some View {
    VStack(alignment: .leading) {
        ForEach(wrapText(text), id: \.self) { line in
            Text(line)
                .font(.body)
                .padding(.bottom, 4)
        }
    }
}