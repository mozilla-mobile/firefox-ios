// Element.swift
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

/// Represents an element in `XMLDocument` or `HTMLDocument`
open class XMLElement: XMLNode {
  
  /// The element's namespace.
  open fileprivate(set) lazy var namespace: String? = {
    return ^-^(self.cNode.pointee.ns != nil ?self.cNode.pointee.ns.pointee.prefix :nil)
  }()
  
  /// The element's tag.
  open fileprivate(set) lazy var tag: String? = {
    return ^-^self.cNode.pointee.name
  }()
  
  // MARK: - Accessing Attributes
  /// All attributes for the element.
  open fileprivate(set) lazy var attributes: [String : String] = {
    var attributes = [String: String]()
    var attribute = self.cNode.pointee.properties
    while attribute != nil {
      if let key = ^-^attribute?.pointee.name, let value = self.attr(key) {
        attributes[key] = value
      }
      attribute = attribute?.pointee.next
    }
    return attributes
  }()
  
  /**
   Returns the value for the attribute with the specified key.
   
   - parameter name: The attribute name.
   - parameter ns:   The namespace, or `nil` by default if not using a namespace
   
   - returns: The attribute value, or `nil` if the attribute is not defined.
   */
  open func attr(_ name: String, namespace ns: String? = nil) -> String? {
    var value: String? = nil
    
    let xmlValue: UnsafeMutablePointer<xmlChar>?
    if let ns = ns {
      xmlValue = xmlGetNsProp(cNode, name, ns)
    } else {
      xmlValue = xmlGetProp(cNode, name)
    }
    
    if let xmlValue = xmlValue {
      value = ^-^xmlValue
      xmlFree(xmlValue)
    }
    return value
  }
  
  // MARK: - Accessing Children
  
  /// The element's children elements.
  open var children: [XMLElement] {
    return LinkedCNodes(head: cNode.pointee.children).compactMap {
      XMLElement(cNode: $0, document: self.document)
    }
  }
  
  /**
  Get the element's child nodes of specified types
   
  - parameter types: type of nodes that should be fetched (e.g. .Element, .Text, .Comment)
   
  - returns: all children of specified types
  */
  open func childNodes(ofTypes types: [XMLNodeType]) -> [XMLNode] {
    return LinkedCNodes(head: cNode.pointee.children, types: types).compactMap { node in
      switch node.pointee.type {
      case XMLNodeType.Element:
        return XMLElement(cNode: node, document: self.document)
      default:
        return XMLNode(cNode: node, document: self.document)
      }
    }
  }
  
  /**
  Returns the first child element with a tag, or `nil` if no such element exists.
  
  - parameter tag: The tag name.
  - parameter ns:  The namespace, or `nil` by default if not using a namespace
  
  - returns: The child element.
  */
  open func firstChild(tag: XMLCharsComparable, inNamespace ns: XMLCharsComparable? = nil) -> XMLElement? {
    var nodePtr = cNode.pointee.children
    while let cNode = nodePtr {
      if cXMLNode(nodePtr, matchesTag: tag, inNamespace: ns) {
        return XMLElement(cNode: cNode, document: self.document)
      }
      nodePtr = cNode.pointee.next
    }
    return nil
  }

  /// faster version of firstChild with string literals (explicitly typed as StaticString)
  open func firstChild(staticTag tag: StaticString, inNamespace ns: StaticString? = nil) -> XMLElement? {
    return firstChild(tag: tag, inNamespace: ns)
  }

  /**
  Returns all children elements with the specified tag.

  - parameter tag: The tag name.
  - parameter ns:  The namepsace, or `nil` by default if not using a namespace

  - returns: The children elements.
  */
  open func children(tag: XMLCharsComparable, inNamespace ns: XMLCharsComparable? = nil) -> [XMLElement] {
    return LinkedCNodes(head: cNode.pointee.children).compactMap {
      cXMLNode($0, matchesTag: tag, inNamespace: ns)
        ? XMLElement(cNode: $0, document: self.document) : nil
    }
  }

  /// faster version of children with string literals (explicitly typed as StaticString)
  open func children(staticTag tag: StaticString, inNamespace ns: StaticString? = nil) -> [XMLElement] {
    return children(tag: tag, inNamespace: ns)
  }

  // MARK: - Accessing Content
  /// Whether the element has a value.
  open var isBlank: Bool {
    return stringValue.isEmpty
  }
  
  /// A number representation of the element's value, which is generated from the document's `numberFormatter` property.
  open fileprivate(set) lazy var numberValue: NSNumber? = {
    return self.document.numberFormatter.number(from: self.stringValue)
  }()
  
  /// A date representation of the element's value, which is generated from the document's `dateFormatter` property.
  open fileprivate(set) lazy var dateValue: Date? = {
    return self.document.dateFormatter.date(from: self.stringValue)
  }()
  
  /**
  Returns the child element at the specified index.
  
  - parameter idx: The index.
  
  - returns: The child element.
  */
  open subscript (idx: Int) -> XMLElement? {
    return children[idx]
  }
  
  /**
  Returns the value for the attribute with the specified key.
  
  - parameter name: The attribute name.
  
  - returns: The attribute value, or `nil` if the attribute is not defined.
  */
  open subscript (name: String) -> String? {
    return attr(name)
  }
}
