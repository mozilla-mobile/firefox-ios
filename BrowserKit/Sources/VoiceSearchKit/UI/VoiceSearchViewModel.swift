// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@MainActor
final class VoiceSearchViewModel {
    enum State: Equatable {
        case recordVoice(SpeechResult, SpeechError?)
        case loadingSearchResult
        case showSearchResult(SearchResult, SearchResultError?)
    }

    private let service: VoiceSearchService
    private var recordVoiceTask: Task<Void, Never>?
    private var searchResultTask: Task<Void, Never>?
    private var recentSpeechResult: SpeechResult?
    var onStateChange: ((State) -> Void)?

    init(service: VoiceSearchService) {
        self.service = service
    }

    func startRecordingVoice() {
        searchResultTask?.cancel()
        searchResultTask = nil
        recordVoiceTask = Task { [weak self] in
            await self?.recordVoiceTask()
        }
    }

    private func recordVoiceTask() async {
        let stream = service.recordVoice()
        do {
            for try await result in stream {
                try Task.checkCancellation()
                recentSpeechResult = result
                onStateChange?(.recordVoice(result, nil))
                guard result.isFinal else { continue }
                await searchVoiceResult(result)
                break
            }
        } catch {
            guard let error = error as? SpeechError else {
                return
            }
            onStateChange?(.recordVoice(.empty(), error))
        }
    }

    func stopRecordingVoice() {
        recordVoiceTask?.cancel()
        recordVoiceTask = nil
        service.stopRecordingVoice()
        guard let recentSpeechResult, searchResultTask == nil else { return }
        searchResultTask = Task { [weak self] in
            do {
                try Task.checkCancellation()
                await self?.searchVoiceResult(recentSpeechResult)
            } catch {
                return
            }
        }
    }

    private func searchVoiceResult(_ result: SpeechResult) async {
        onStateChange?(.loadingSearchResult)
        let searchResult = await service.search(text: result.text)
        switch searchResult {
        case .success(let result):
            onStateChange?(.showSearchResult(result, nil))
        case .failure(let error):
            onStateChange?(.showSearchResult(.empty(), error))
        }
    }
}
