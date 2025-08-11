// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Generic Server‑Sent Events (SSE) parser that buffers partial fragments
/// and emits fully decoded objects as they arrive.
///
/// Example SSE stream:
/// ```
/// data: {"message":"First event"}
///
/// data: {"message":"Second event"}
///
/// data: [DONE]
/// ```
///
/// Notes:
/// 1. Each line is prefixed with `data:` (`Constants.dataPrefix`).
/// 2. Events are separated by two newlines (`Constants.eventDelimiter`).
/// 3. The stream ends when `[DONE]` is received (`Constants.doneSignal`).
final class SSEDataParser {
    enum Constants {
        static let eventDelimiter = "\n\n"
        static let dataPrefix = "data: "
        static let doneSignal = "[DONE]"
    }

    private let decoder: JSONDecoder
    /// Buffer to hold partial data fragments. This is used because the server might send
    /// incomplete chunks or cases where the incoming data is split across multiple chunks.
    private var buffer = ""

    init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }

    /// Processes incoming data chunks and returns parsed objects
    /// - Parameter data: Raw stream data chunk
    /// - Returns: Array of successfully decoded objects
    /// - Throws: `SSEParseError` when valid-looking data fails to decode into the expected type `T`
    func parse<T: Decodable & Sendable>(_ data: Data) throws -> [T] {
        // Convert data to string, skip if conversion fails
        guard let stringData = String(data: data, encoding: .utf8) else { throw SSEDataParserError.invalidDataEncoding }
        // Append new data to buffer
        buffer += stringData

        // Split into complete events (delimited by Constants.eventDelimiter)
        let parts = buffer.components(separatedBy: Constants.eventDelimiter)
        // Last part is either:
        // 1. Empty (if buffer ended with delimiter) -> clear buffer
        // 2. Incomplete event -> keep for next chunk
        // 3. Complete event (if delimiter appears at start of next chunk)
        buffer = parts.last ?? ""

        // Process all components except the last one (which is put into the buffer)
        return try parts.dropLast().compactMap { rawEvent in
            try processEvent(rawEvent)
        }
    }

    /// Flushes the buffer, clearing any partial data.
    /// This is useful when you want to reset the parser state, e.g., after processing a complete stream.
    /// - Note: This does not affect the already processed data.
    func flush() {
        buffer = ""
    }

    // MARK: - Helper Methods

    /// Processes a single raw event line, extracting the payload and decoding it.
    private func processEvent<T: Decodable>(_ rawEvent: String) throws -> T? {
        let trimmedEvent = rawEvent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEvent.isEmpty else { return nil }

        // Attempt to extract payload
        guard let payload = extractPayload(from: trimmedEvent),
              !isDoneSignal(payload) else { return nil }

        // If it's a valid SSE event and not a done signal, attempt to decode it
        // If decoding fails, throw a decoding error.
        do {
            return try decoder.decode(T.self, from: Data(payload.utf8))
        } catch {
            throw SSEDataParserError.invalidDataEncoding
        }
    }

    /// Checks if the payload is the stream termination signal `Constants.doneSignal`.
    /// A valid termination signal looks like: `data: [DONE]`
    private func isDoneSignal(_ payload: String) -> Bool {
        return payload == Constants.doneSignal
    }

    /// Extracts the payload from a valid event line by removing the data prefix.
    private func extractPayload(from line: String) -> String? {
        guard isValidEventLine(line) else { return nil }
        return String(line.dropFirst(Constants.dataPrefix.count))
    }

    /// Checks if a trimmed event line is valid by ensuring it starts with the `Constants.dataPrefix`.
    /// A valid event line looks like: `data: {"message":"event message"}`
    private func isValidEventLine(_ line: String) -> Bool {
        return line.hasPrefix(Constants.dataPrefix)
    }
}
