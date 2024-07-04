/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct textSearched {
    var text: String
    var isCurrentSearch: Bool

    init(text: String, isCurrentSearch: Bool) {
        self.text = text
        self.isCurrentSearch = isCurrentSearch
    }

    init?(dictionary: [String: Any]) {
        guard let text = dictionary["text"], let isCurrentSearch = dictionary["isCurrentSearch"] else { return nil }
        self.init(text: text as! String, isCurrentSearch: isCurrentSearch as! Bool)
    }
}

class SearchHistoryUtils {
    static var isFromURLBar = false
    static var isNavigating = false
    static var isReload = false
    private static var currentStack = [textSearched]()

    static func pushSearchToStack(with searchedText: String) {
        // Check whether the lastSearch is the current search. If not, remove subsequent searches
        if let lastSearch = currentStack.last, !lastSearch.isCurrentSearch {
            for index in 0..<currentStack.count where currentStack[index].isCurrentSearch {
                    currentStack.removeSubrange(index+1..<currentStack.count)
                    break
            }
        }

        for index in 0..<currentStack.count {
            currentStack[index].isCurrentSearch = false
        }

        currentStack.append(textSearched(text: searchedText, isCurrentSearch: true))
    }

    static func pullSearchFromStack() -> String? {
        for search in currentStack where search.isCurrentSearch {
            return search.text
        }

        return nil
    }

    static func goForward() {
        isNavigating = true
        for index in 0..<currentStack.count {
            if currentStack[index].isCurrentSearch && index + 1 < currentStack.count {
                currentStack[index + 1].isCurrentSearch = true
                currentStack[index].isCurrentSearch = false
                break
            }
        }
    }

    static func goBack() {
        isNavigating = true
        for index in 0..<currentStack.count {
            if currentStack[index].isCurrentSearch && index - 1 >= 0 {
                currentStack[index - 1].isCurrentSearch = true
                currentStack[index].isCurrentSearch = false
                break
            }
        }
    }
}
