//
//  OpenAIClient.swift
//

import Foundation
import Dependencies
import XCTestDynamicOverlay
import OpenAIStreamingCompletions

public extension DependencyValues {
    var openAIClient: OpenAIClient {
        get { self[OpenAIClient.self] }
        set { self[OpenAIClient.self] = newValue }
    }
}

public struct OpenAIClient {
    public var summaryForUrl: @Sendable (_ url: URL) -> StreamingCompletion?
}

extension OpenAIClient: TestDependencyKey {
    public static var testValue = Self(
        summaryForUrl: unimplemented("\(Self.self).summaryForUrl")
    )
    
//    static let previewValue = Self(
//        createEdit: unimplemented("\(Self.self).createEdit"),
//        createCompletion: unimplemented("\(Self.self).createCompletion")
//    )
}
