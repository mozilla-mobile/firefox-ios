// NodeSet.swift
// Copyright (c) 2015 Ce Zheng
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import libxml2

/// An enumerable set of XML nodes
open class NodeSet: Collection {
  // Index type for `Indexable` protocol
  public typealias Index = Int

  // IndexDistance type for `Indexable` protocol
  public typealias IndexDistance = Int
  
  fileprivate var cursor = 0
  open func next() -> XMLElement? {
    defer {
      cursor += 1
    }
    if cursor < self.count {
      return self[cursor]
    }
    return nil
  }

  /// Number of nodes
  open fileprivate(set) lazy var count: Int = {
    return Int(self.cNodeSet?.pointee.nodeNr ?? 0)
  }()
  
  /// First Element
  open var first: XMLElement? {
    return count > 0 ? self[startIndex] : nil
  }

  /// if nodeset is empty
  open var isEmpty: Bool {
    return (cNodeSet == nil) || (cNodeSet!.pointee.nodeNr == 0) || (cNodeSet!.pointee.nodeTab == nil)
  }

  /// Start index
  open var startIndex: Index {
    return 0
  }

  /// End index
  open var endIndex: Index {
    return count
  }

  /**
   Get the Nth node from set.

   - parameter idx: node index

   - returns: the idx'th node, nil if out of range
  */
  open subscript(_ idx: Index) -> XMLElement {
    precondition(idx >= startIndex && idx < endIndex, "Index of out bound")
    return XMLElement(cNode: (cNodeSet!.pointee.nodeTab[idx])!, document: document)
  }
  
  /**
   Get the index after `idx`

   - parameter idx: node index

   - returns: the index after `idx`
   */
  open func index(after idx: Index) -> Index {
    return idx + 1
  }
  
  internal let cNodeSet: xmlNodeSetPtr?
  internal let document: XMLDocument!
  
  internal init(cNodeSet: xmlNodeSetPtr?, document: XMLDocument?) {
    self.cNodeSet = cNodeSet
    self.document = document
  }
}

/// XPath selector result node set
open class XPathNodeSet: NodeSet {
  /// Empty node set
  public static let emptySet = XPathNodeSet(cXPath: nil, document: nil)

  fileprivate var cXPath: xmlXPathObjectPtr?
  
  internal init(cXPath: xmlXPathObjectPtr?, document: XMLDocument?) {
    self.cXPath = cXPath
    let nodeSet = cXPath?.pointee.nodesetval
    super.init(cNodeSet: nodeSet, document: document)
  }
  
  deinit {
    if cXPath != nil {
      xmlXPathFreeObject(cXPath)
    }
  }
}

