//
//  SortedArray.swift
//  AStar
//
//  Created by Damiaan Dufaux on 21/08/16.
//  Copyright © 2016 Damiaan Dufaux. All rights reserved.
//

import Foundation

extension Array {
    
    /// Finds such index N that predicate is true for all elements up to
    /// but not including the index N, and is false for all elements
    /// starting with index N.
    /// Behavior is undefined if there is no such N.
    func binarySearch(predicate: (Element) -> Bool) -> Int {
        var low = startIndex
        var high = endIndex
        while low != high {
            let mid = low.advanced(by: low.distance(to: high) / 2)
            if predicate(self[mid]) {
                low = mid.advanced(by: 1)
            } else {
                high = mid
            }
        }
        return low
    }
    
    mutating func sortedInsert(element: Element, predicate: (Element, Element) -> Bool) {
        insert(element, at: binarySearch{predicate($0, element)} )
    }
    
}

extension Array where Element: Comparable {
    /// Finds such index N that predicate is true for all elements up to
    /// but not including the index N, and is false for all elements
    /// starting with index N.
    /// Behavior is undefined if there is no such N.
    func binarySearch(element: Element) -> Int {
        var low = startIndex
        var high = endIndex
        while low != high {
            let mid = low.advanced(by: low.distance(to: high) / 2)
            if self[mid] < element {
                low = mid.advanced(by: 1)
            } else {
                high = mid
            }
        }
        return low
    }
    
    /// Inserts a new element in a sorted array.
    ///
    /// - Parameter newElement: The element to insert into the array.
    ///
    /// - Complexity: To find the index for the new element
    ///   it uses a binary search algorithm

    mutating func sortedInsert(newElement: Element) {
        insert(newElement, at: binarySearch(element: newElement) )
    }
}
