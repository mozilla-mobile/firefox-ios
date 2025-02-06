// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public final class Images: Publisher {
    public var subscriptions = [Subscription<Item>]()
    var items = Set<Item>()
    private let session: URLSession

    public init(_ session: URLSession) {
        self.session = session
    }

    public func load(_ subscriber: AnyObject, url: URL, closure: @escaping (Input) -> Void) {
        subscribe(subscriber, closure: closure)
        guard let item = items.first(where: { $0.url == url })
        else {
            download(url)
            return
        }
        send(item)
    }

    public func cancellAll() {
        session.getAllTasks {
            $0.forEach { $0.cancel() }
        }
    }

    public func cancel(_ url: URL) {
        session.getAllTasks {
            $0.first { $0.originalRequest?.url == url }?.cancel()
        }
    }

    private func download(_ url: URL) {
        session.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async { [weak self] in
                data.map {
                    let item = Item(url, $0)
                    self?.send(item)
                    self?.items.insert(item)
                }
            }
        }.resume()
    }

    public struct Item: Hashable {
        public let url: URL
        public let data: Data

        init(_ url: URL, _ data: Data) {
            self.url = url
            self.data = data
        }

        public func hash(into: inout Hasher) {
            into.combine(url)
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.url == rhs.url
        }
    }
}
