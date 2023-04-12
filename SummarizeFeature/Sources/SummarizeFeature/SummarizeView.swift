//
//  SummarizeView.swift
//

import SwiftUI
import OpenAIStreamingCompletions
import ComposableArchitecture

public struct SummarizeView: View {
    private let store: StoreOf<SummarizeReducer>
    @ObservedObject var viewStore: ViewStoreOf<SummarizeReducer>
    
    public init(url: URL) {
        store = Store(
            initialState: .init(url: url),
            reducer: SummarizeReducer()
        )
        viewStore = ViewStore(store)
    }
    
    public var body: some View {
        VStack {
            if let completion = viewStore.completion {
                CompletionView(completion: completion)
            }
        }
        .navigationTitle("Summary")
        .onAppear { viewStore.send(.onAppear) }
        .onDisappear { viewStore.send(.onDisappear) }
    }
}

struct SummarizeView_Previews: PreviewProvider {
    static var previews: some View {
        SummarizeView(url: URL(string: "https://www.pumabrowser.com")!)
    }
}
