// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public final class News: StatePublisher {
    public var subscriptions = [Subscription<[NewsModel]>]()
    public var state: [NewsModel]? {
        items.sorted { $0.publishDate > $1.publishDate }
    }
    private let dispatch = DispatchQueue(label: "", qos: .utility)
    private let characters = ["&#39;": "'"]

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private(set) var items = Set<NewsModel>() {
        didSet {
            DispatchQueue.main.async { [weak self ] in
                self?.state.map { self?.send($0) }
            }
        }
    }

    public init() {
        dispatch.async { [weak self] in
            self?.restore()
        }
    }

    var needsUpdate: Bool {
        guard !items.isEmpty else { return true }
        return Calendar.current.dateComponents([.day], from: User.shared.news, to: .init()).day! >= 1
    }

    public func load(session: URLSession, force: Bool = false) {
        guard needsUpdate || force else { return }
        session.dataTask(with: EcosiaEnvironment.current.urlProvider.notifications) { [weak self] data, _, _ in
            self?.dispatch.async {
                guard
                    let data = data,
                    let new = try? self?.decoder.decode([NewsModel].self, from: data)
                else {
                    return
                }
                let cleaned = new.compactMap { self?.clean($0) }
                self?.items = .init(cleaned + (self?.items ?? []))
                self?.save()
            }
        }.resume()
    }

    private func restore() {
        dispatch.async { [weak self] in
            if let news = try? JSONDecoder().decode([NewsModel].self, from: .init(contentsOf: FileManager.news)) {
                self?.items = .init(news.filter { $0.language == Language.current })
            }
        }
    }

    private func save() {
        dispatch.async { [weak self] in
            guard let items = self?.items, !items.isEmpty else { return }
            do {
                try JSONEncoder().encode(items).write(to: FileManager.news, options: .atomic)
                User.shared.news = Date()
            } catch {}
        }
    }

    private func clean(_ item: NewsModel) -> NewsModel {
        var item = item
        item.text = item.text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        item.text = characters.reduce(item.text) { text, char in
            text.replacingOccurrences(of: char.0, with: char.1)
        }
        return item
    }
}
