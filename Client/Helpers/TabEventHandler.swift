/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage

/**
 * A handler can be a plain old swift object. It does not need to extend any
 * other object, but can.
 *
 * Handlers should register for tab events with the `registerFor` method, and
 * cleanup with the `unregister` method.
 *
 * ```
 * class HandoffHandler {
 *     var tabObservers: TabObservers!
 *
 *     init() {
 *         tabObservers = registerFor(.didLoadFavicon, .didLoadPageMetadata)
 *     }
 *
 *     deinit {
 *         unregister(tabObservers)
 *     }
 * }
 * ```
 *
 * Handlers can implement any or all `TabEventHandler` methods. If you
 * implement a method, you should probably `registerFor` the event above.
 *
 * ```
 * extension HandoffHandler: TabEventHandler {
 *     func tab(_ tab: Tab, didLoadPageMetadata metadata: PageMetadata) {
 *         print("\(tab) has \(pageMetadata)")
 *     }
 *
 *     func tab(_ tab: Tab, didLoadFavicon favicon: Favicon) {
 *         print("\(tab) has \(favicon)")
 *     }
 * }
 * ```
 *
 * Tab events should probably be only posted from one place, to avoid cycles.
 *
 * ```
 * TabEvent.post(.didLoadPageMetadata(aPageMetadata), for: tab)
 * ```
 *
 * In this manner, we are able to use the notification center and have type safety.
 *
 */
// As we want more events we add more here.
// Each event needs:
// 1. a method in the TabEventHandler.
// 2. a default implementation of the method – so not everyone needs to implement it
// 3. a TabEventLabel, which is needed for registration
// 4. a TabEvent, with whatever parameters are needed.
//    i) a case to map the event to the event label (var label)
//   ii) a case to map the event to the event handler (func handle:with:)
protocol TabEventHandler {
    func tab(_ tab: Tab, didChangeURL url: URL)
    func tab(_ tab: Tab, didLoadPageMetadata metadata: PageMetadata)
    func tab(_ tab: Tab, didLoadFavicon favicon: Favicon?, with: Data?)
    func tabDidGainFocus(_ tab: Tab)
    func tabDidLoseFocus(_ tab: Tab)
    func tabDidClose(_ tab: Tab)
    func tabDidChangeContentBlockerStatus(_ tab: Tab)
}

// Provide default implmentations, because we don't want to litter the code with
// empty methods, and `@objc optional` doesn't really work very well.
extension TabEventHandler {
    func tab(_ tab: Tab, didChangeURL url: URL) {}
    func tab(_ tab: Tab, didLoadPageMetadata metadata: PageMetadata) {}
    func tab(_ tab: Tab, didLoadFavicon favicon: Favicon?, with: Data?) {}
    func tabDidGainFocus(_ tab: Tab) {}
    func tabDidLoseFocus(_ tab: Tab) {}
    func tabDidClose(_ tab: Tab) {}
    func tabDidChangeContentBlockerStatus(_ tab: Tab) {}
}

enum TabEventLabel: String {
    case didChangeURL
    case didLoadPageMetadata
    case didLoadFavicon
    case didGainFocus
    case didLoseFocus
    case didClose
    case didChangeContentBlocking
}

enum TabEvent {
    case didChangeURL(URL)
    case didLoadPageMetadata(PageMetadata)
    case didLoadFavicon(Favicon?, with: Data?)
    case didGainFocus
    case didLoseFocus
    case didClose
    case didChangeContentBlocking

    var label: TabEventLabel {
        switch self {
        case .didChangeURL:
            return .didChangeURL
        case .didLoadPageMetadata:
            return .didLoadPageMetadata
        case .didLoadFavicon:
            return .didLoadFavicon
        case .didGainFocus:
            return .didGainFocus
        case .didLoseFocus:
            return .didLoseFocus
        case .didClose:
            return .didClose
        case .didChangeContentBlocking:
            return .didChangeContentBlocking
        }
    }
    
    func handle(_ tab: Tab, with handler: TabEventHandler) {
        switch self {
        case .didChangeURL(let url):
            handler.tab(tab, didChangeURL: url)
        case .didLoadPageMetadata(let metadata):
            handler.tab(tab, didLoadPageMetadata: metadata)
        case .didLoadFavicon(let favicon, let data):
            handler.tab(tab, didLoadFavicon: favicon, with: data)
        case .didGainFocus:
            handler.tabDidGainFocus(tab)
        case .didLoseFocus:
            handler.tabDidLoseFocus(tab)
        case .didClose:
            handler.tabDidClose(tab)
        case .didChangeContentBlocking:
            handler.tabDidChangeContentBlockerStatus(tab)
        }
    }
}

// Hide some of the machinery away from the boiler plate above.
////////////////////////////////////////////////////////////////////////////////////////
extension TabEventLabel {
    var name: Notification.Name {
        return Notification.Name(self.rawValue)
    }
}

extension TabEvent {
    func notification(for tab: Any) -> Notification {
        return Notification(name: label.name, object: tab, userInfo: ["payload": self])
    }

    /// Use this method to post notifications to any concerned listeners.
    static func post(_ event: TabEvent, for tab: Any) {
        center.post(event.notification(for: tab))
    }
}

// These methods are used by TabEventHandler implementers.
// Their usage remains consistent, even as we add more event types and handler methods.
////////////////////////////////////////////////////////////////////////////////////////
private let center = NotificationCenter()

typealias TabObservers = [NSObjectProtocol]
extension TabEventHandler {
    /// Implementations of handles should use this method to register for events.
    /// `TabObservers` should be preserved for unregistering later.
    func registerFor(_ tabEvents: TabEventLabel..., queue: OperationQueue? = nil) -> TabObservers {
        return tabEvents.map { eventType in
            center.addObserver(forName: eventType.name, object: nil, queue: queue) { notification in
                guard let tab = notification.object as? Tab,
                    let event = notification.userInfo?["payload"] as? TabEvent else {
                        return
                }
                event.handle(tab, with: self)
            }
        }
    }
    
    func unregister(_ observers: TabObservers) {
        observers.forEach { observer in
            center.removeObserver(observer)
        }
    }
}
