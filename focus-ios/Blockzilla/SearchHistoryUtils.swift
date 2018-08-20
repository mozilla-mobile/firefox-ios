/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


import Foundation

struct textSearched{
    var text: String
    var isCurrentSearch: Bool
    
    init(text : String, isCurrentSearch: Bool) {
        self.text = text
        self.isCurrentSearch = isCurrentSearch
    }
    
    init?(dictionary: [String: Any]) {
        guard let text = dictionary["text"], let isCurrentSearch = dictionary["isCurrentSearch"] else { return nil }
        self.init(text: text as! String, isCurrentSearch: isCurrentSearch as! Bool)
    }
    
    var propertyListRepresentation : [String:Any] {
        return ["text" : text, "isCurrentSearch" : isCurrentSearch]
    }
    
}

class SearchHistoryUtils {
    
    static var isFromURLBar = false
    static var isNavigating = false
    
    static func pushSearchToStack(with searchedText: String) {
        var currentStack = [textSearched]()
        
        if let propertylistSearchesRead = UserDefaults.standard.object(forKey: "searchedHistory") as? [[String:Any]] {
            currentStack = propertylistSearchesRead.compactMap{ textSearched(dictionary: $0) }
            
            for index in 0..<currentStack.count {
                currentStack[index].isCurrentSearch = false
            }
        }
        
        currentStack.append(textSearched(text: searchedText, isCurrentSearch: true))
        
        let propertylistSearchesWrite = currentStack.map{ $0.propertyListRepresentation }
        UserDefaults.standard.set(propertylistSearchesWrite, forKey: "searchedHistory")
    }
    
    static func pullSearchFromStack() -> String? {
        var currentStack = [textSearched]()
        if let propertylistSearchesRead = UserDefaults.standard.object(forKey: "searchedHistory") as? [[String:Any]] {
            
            currentStack = propertylistSearchesRead.compactMap{ textSearched(dictionary: $0) }
            for search in currentStack {
                if search.isCurrentSearch {
                    return search.text
                }
            }
        }
        
        return nil
    }

    static func goForward() {
        isNavigating = true
        var currentStack = [textSearched]()
        if let propertylistSearchesRead = UserDefaults.standard.object(forKey: "searchedHistory") as? [[String:Any]] {
            
            currentStack = propertylistSearchesRead.compactMap{ textSearched(dictionary: $0) }
            
            for index in 0..<currentStack.count {
                if (currentStack[index].isCurrentSearch) {
                    
                    currentStack[index + 1].isCurrentSearch = true
                    currentStack[index].isCurrentSearch = false
                    break
                }
            }
            let propertylistSearchesWrite = currentStack.map{ $0.propertyListRepresentation }
            UserDefaults.standard.set(propertylistSearchesWrite, forKey: "searchedHistory")
        }
    }

    static func goBack() {
        isNavigating = true
        var currentStack = [textSearched]()
        if let propertylistSearchesRead = UserDefaults.standard.object(forKey: "searchedHistory") as? [[String:Any]] {
            
            currentStack = propertylistSearchesRead.compactMap{ textSearched(dictionary: $0) }
            
            for index in 0..<currentStack.count {
                if (currentStack[index].isCurrentSearch) {
                    
                    currentStack[index - 1].isCurrentSearch = true
                    currentStack[index].isCurrentSearch = false
                }
            }
            let propertylistSearchesWrite = currentStack.map{ $0.propertyListRepresentation }
            UserDefaults.standard.set(propertylistSearchesWrite, forKey: "searchedHistory")
        }
    }
}
