// Node.swift
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

/// Define a Swifty typealias for libxml's node type enum
public typealias XMLNodeType = xmlElementType

// MARK: - Give a Swifty name to each enum case of XMLNodeType
extension XMLNodeType {
  /// Element
  public static var Element: xmlElementType       { return XML_ELEMENT_NODE }
  /// Attribute
  public static var Attribute: xmlElementType     { return XML_ATTRIBUTE_NODE }
  /// Text
  public static var Text: xmlElementType          { return XML_TEXT_NODE }
  /// CData Section
  public static var CDataSection: xmlElementType  { return XML_CDATA_SECTION_NODE }
  /// Entity Reference
  public static var EntityRef: xmlElementType     { return XML_ENTITY_REF_NODE }
  /// Entity
  public static var Entity: xmlElementType        { return XML_ENTITY_NODE }
  /// Pi
  public static var Pi: xmlElementType            { return XML_PI_NODE }
  /// Comment
  public static var Comment: xmlElementType       { return XML_COMMENT_NODE }
  /// Document
  public static var Document: xmlElementType      { return XML_DOCUMENT_NODE }
  /// Document Type
  public static var DocumentType: xmlElementType  { return XML_DOCUMENT_TYPE_NODE }
  /// Document Fragment
  public static var DocumentFrag: xmlElementType  { return XML_DOCUMENT_FRAG_NODE }
  /// Notation
  public static var Notation: xmlElementType      { return XML_NOTATION_NODE }
  /// HTML Document
  public static var HtmlDocument: xmlElementType  { return XML_HTML_DOCUMENT_NODE }
  /// DTD
  public static var DTD: xmlElementType           { return XML_DTD_NODE }
  /// Element Declaration
  public static var ElementDecl: xmlElementType   { return XML_ELEMENT_DECL }
  /// Attribute Declaration
  public static var AttributeDecl: xmlElementType { return XML_ATTRIBUTE_DECL }
  /// Entity Declaration
  public static var EntityDecl: xmlElementType    { return XML_ENTITY_DECL }
  /// Namespace Declaration
  public static var NamespaceDecl: xmlElementType { return XML_NAMESPACE_DECL }
  /// XInclude Start
  public static var XIncludeStart: xmlElementType { return XML_XINCLUDE_START }
  /// XInclude End
  public static var XIncludeEnd: xmlElementType   { return XML_XINCLUDE_END }
  /// DocbDocument
  public static var DocbDocument: xmlElementType  { return XML_DOCB_DOCUMENT_NODE }
}

infix operator ~=
/**
 For supporting pattern matching of those enum case alias getters for XMLNodeType
 
 - parameter lhs: left hand side
 - parameter rhs: right hand side
 
 - returns: true if both sides equals
 */
public func ~=(lhs: XMLNodeType, rhs: XMLNodeType) -> Bool {
  return lhs.rawValue == rhs.rawValue
}

/// Base class for all XML nodes
open class XMLNode {
  /// The document containing the element.
  public unowned let document: XMLDocument
  
  /// The type of the XMLNode
  open var type: XMLNodeType {
    return cNode.pointee.type
  }
  
  /// The element's line number.
  open fileprivate(set) lazy var lineNumber: Int = {
    return xmlGetLineNo(self.cNode)
  }()
  
  // MARK: - Accessing Parent and Sibling Elements
  /// The element's parent element.
  open fileprivate(set) lazy var parent: XMLElement? = {
    return XMLElement(cNode: self.cNode.pointee.parent, document: self.document)
  }()
  
  /// The element's previous sibling.
  open fileprivate(set) lazy var previousSibling: XMLElement? = {
    return XMLElement(cNode: self.cNode.pointee.prev, document: self.document)
  }()

  /// The element's next sibling.
  open fileprivate(set) lazy var nextSibling: XMLElement? = {
    return XMLElement(cNode: self.cNode.pointee.next, document: self.document)
  }()
  
  // MARK: - Accessing Contents
  /// Whether this is a HTML node
  open var isHTML: Bool {
    return UInt32(self.cNode.pointee.doc.pointee.properties) & XML_DOC_HTML.rawValue == XML_DOC_HTML.rawValue
  }

  /// A string representation of the element's value.
  open fileprivate(set) lazy var stringValue : String = {
    let key = xmlNodeGetContent(self.cNode)
    let stringValue = ^-^key ?? ""
    xmlFree(key)
    return stringValue
  }()
  
  /// The raw XML string of the element.
  open fileprivate(set) lazy var rawXML: String = {
    let buffer = xmlBufferCreate()
    if self.isHTML {
      htmlNodeDump(buffer, self.cNode.pointee.doc, self.cNode)
    } else {
      xmlNodeDump(buffer, self.cNode.pointee.doc, self.cNode, 0, 0)
    }
    let dumped = ^-^xmlBufferContent(buffer) ?? ""
    xmlBufferFree(buffer)
    return dumped
  }()
  
 /// Convert this node to XMLElement if it is an element node
  open func toElement() -> XMLElement? {
    return self as? XMLElement
  }
  
  internal let cNode: xmlNodePtr
  
  internal init(cNode: xmlNodePtr, document: XMLDocument) {
    self.cNode = cNode
    self.document = document
  }

  internal convenience init?(cNode: xmlNodePtr?, document: XMLDocument) {
    guard let cNode = cNode else {
      return nil
    }
    self.init(cNode: cNode, document: document)
  }
}

extension XMLNode: Equatable {}

/**
 Determine whether two nodes are the same
 
 - parameter lhs: XMLNode on the left
 - parameter rhs: XMLNode on the right
 
 - returns: whether lhs and rhs are equal
 */
public func ==(lhs: XMLNode, rhs: XMLNode) -> Bool {
  return lhs.cNode == rhs.cNode
}
