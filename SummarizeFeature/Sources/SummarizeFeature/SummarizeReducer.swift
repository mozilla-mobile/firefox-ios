//
//  SummarizeReducer.swift
//

import Foundation
import Dependencies
import OpenAIClient
import OpenAIStreamingCompletions
import ComposableArchitecture

struct SummarizeReducer: ReducerProtocol {
    private enum OpenAICommandID {}
    
    struct State: Equatable {
        var url: URL
        var completion: StreamingCompletion? = nil
    }

    enum Action: Equatable {
        case onAppear
        case onDisappear
        
        case invokeCommand
    }
    
    @Dependency(\.openAIClient) var openAIClient
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .onAppear:
            return .task { .invokeCommand }
            
        case .onDisappear:
            return .cancel(id: OpenAICommandID.self)
            
        case .invokeCommand:
            state.completion = openAIClient.summaryForUrl(state.url)
            return .none
        }
    }
}

extension StreamingCompletion: Equatable {
    public static func == (lhs: OpenAIStreamingCompletions.StreamingCompletion, rhs: OpenAIStreamingCompletions.StreamingCompletion) -> Bool {
        lhs.text == rhs.text && lhs.status == rhs.status
    }
}
