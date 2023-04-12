//
//  CompletionView.swift
//

import SwiftUI
import ComposableArchitecture
import OpenAIStreamingCompletions

struct CompletionView: View {
    @ObservedObject private var completion: StreamingCompletion
    
    public init(completion: StreamingCompletion) {
        self.completion = completion
    }
    
    var body: some View {
        VStack {
            ScrollView {
                Text("\(completion.text)")
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
            }
            Divider()
            Text(completion.status.text)
        }
        .padding(.horizontal)
    }
}

extension StreamingCompletion.Status {
    var text: String {
        switch self {
        case .error: return "Error: something went wrong"
        case .complete: return "Completed"
        case .loading: return "Loading..."
        }
    }
}
