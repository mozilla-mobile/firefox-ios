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
public class NodeSet: SequenceType {
  /// Empty node set
  public static let emptySet = XPathNodeSet(cXPath: nil, document: nil)
  
  /// XMLElement Generator for SequenceType Protocol
  public typealias Generator = AnyGenerator<XMLElement>
  
  /**
  generate method for SequenceType Protocol
  
  - returns: generator
  */
  public func generate() -> Generator {
    var index = 0
    return AnyGenerator {
      defer {
        index += 1
      }
      if index < self.count {
        return self[index]
      }
      return nil
    }
  }

  /// Number of nodes
  public private(set) lazy var count: Int = {
    return self.cNodeSet != nil ?Int(self.cNodeSet.memory.nodeNr) :0
  }()
  
  /// First Element
  public var first: XMLElement? {
    return self[startIndex]
  }

  /// if nodeset is empty
  public var isEmpty: Bool {
    return (cNodeSet == nil) || (cNodeSet.memory.nodeNr == 0) || (cNodeSet.memory.nodeTab == nil)
  }
  
  let cNodeSet: xmlNodeSetPtr
  let document: XMLDocument?
  
  init(cNodeSet: xmlNodeSetPtr, document: XMLDocument?) {
    self.cNodeSet = cNodeSet
    self.document = document
  }
}

extension NodeSet: Indexable {
  /// Use Int as Index type
  public typealias Index = Int
  
  /// Start index
  public var startIndex: Index {
    return 0
  }
  
  /// End index
  public var endIndex: Index {
    return count
  }
  
  /**
  Get the Nth node from set.
  
  - parameter idx: node index
  
  - returns: the idx'th node, nil if out of range
  */
  public subscript(idx: Index) -> XMLElement? {
    if idx >= count {
      return nil
    }
    return XMLElement(cNode: cNodeSet.memory.nodeTab[idx], document: document!)
  }
}

/// XPath selector result node set
public class XPathNodeSet: NodeSet {
  var cXPath: xmlXPathObjectPtr
  
  init(cXPath: xmlXPathObjectPtr, document: XMLDocument?) {
    self.cXPath = cXPath
    let nodeSet = cXPath != nil ? cXPath.memory.nodesetval : nil
    super.init(cNodeSet: nodeSet, document: document)
  }
  
  deinit {
    if cXPath != nil {
      xmlXPathFreeObject(cXPath)
    }
  }
}

