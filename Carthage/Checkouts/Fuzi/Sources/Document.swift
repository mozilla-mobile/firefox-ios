// Document.swift
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

/// XML document which can be searched and queried.
open class XMLDocument {
  // MARK: - Document Attributes
  /// The XML version.
  open fileprivate(set) lazy var version: String? = {
    return ^-^self.cDocument.pointee.version
  }()
  
  /// The string encoding for the document. This is NSUTF8StringEncoding if no encoding is set, or it cannot be calculated.
  open fileprivate(set) lazy var encoding: String.Encoding = {
    if let encodingName = ^-^self.cDocument.pointee.encoding {
      let encoding = CFStringConvertIANACharSetNameToEncoding(encodingName as CFString?)
      if encoding != kCFStringEncodingInvalidId {
        return String.Encoding(rawValue: UInt(CFStringConvertEncodingToNSStringEncoding(encoding)))
      }
    }
    return String.Encoding.utf8
  }()

  // MARK: - Accessing the Root Element
  /// The root element of the document.
  open fileprivate(set) var root: XMLElement?
  
  // MARK: - Accessing & Setting Document Formatters
  /// The formatter used to determine `numberValue` for elements in the document. By default, this is an `NSNumberFormatter` instance with `NSNumberFormatterDecimalStyle`.
  open lazy var numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter
  }()
  
  /// The formatter used to determine `dateValue` for elements in the document. By default, this is an `NSDateFormatter` instance configured to accept ISO 8601 formatted timestamps.
  open lazy var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    return formatter
  }()
  
  // MARK: - Creating XML Documents
  fileprivate let cDocument: xmlDocPtr
  
  /**
  Creates and returns an instance of XMLDocument from an XML string, throwing XMLError if an error occured while parsing the XML.
  
  - parameter string:   The XML string.
  - parameter encoding: The string encoding.
  
  - throws: `XMLError` instance if an error occurred
  
  - returns: An `XMLDocument` with the contents of the specified XML string.
  */
  public convenience init(string: String, encoding: String.Encoding = String.Encoding.utf8) throws {
    guard let cChars = string.cString(using: encoding) else {
      throw XMLError.invalidData
    }
    try self.init(cChars: cChars)
  }
  
  /**
  Creates and returns an instance of XMLDocument from XML data, throwing XMLError if an error occured while parsing the XML.
  
  - parameter data: The XML data.
  
  - throws: `XMLError` instance if an error occurred
  
  - returns: An `XMLDocument` with the contents of the specified XML string.
  */
  public convenience init(data: Data) throws {
    let buffer = data.withUnsafeBytes { $0.bindMemory(to: Int8.self) }
    try self.init(buffer: buffer)
  }
  
  /**
  Creates and returns an instance of XMLDocument from C char array, throwing XMLError if an error occured while parsing the XML.
  
  - parameter cChars: cChars The XML data as C char array
  
  - throws: `XMLError` instance if an error occurred
  
  - returns: An `XMLDocument` with the contents of the specified XML string.
  */
  public convenience init(cChars: [CChar]) throws {
    try self.init(buffer: UnsafeBufferPointer(start: UnsafePointer(cChars), count: cChars.count))
  }

  /**
   Creates and returns an instance of XMLDocument from C char buffer, throwing XMLError if an error occured while parsing the XML.
   
   - parameter buffer: The XML data as C char buffer
   
   - throws: `XMLError` instance if an error occurred
   
   - returns: An `XMLDocument` with the contents of the specified XML string.
   */

  public convenience init(buffer: UnsafeBufferPointer<Int8>) throws {
    let options = Int32(XML_PARSE_NOWARNING.rawValue | XML_PARSE_NOERROR.rawValue | XML_PARSE_RECOVER.rawValue)
    try self.init(buffer: buffer, options: options)
  }

  fileprivate convenience init(buffer: UnsafeBufferPointer<Int8>, options: Int32) throws {
    guard let document = type(of: self).parse(buffer: buffer, options: options) else {
      throw XMLError.lastError(defaultError: .parserFailure)
    }
    xmlResetLastError()
    self.init(cDocument: document)
  }

  fileprivate class func parse(buffer: UnsafeBufferPointer<Int8>, options: Int32) -> xmlDocPtr? {
    return xmlReadMemory(buffer.baseAddress, Int32(buffer.count), "", nil, options)
  }
  
  fileprivate init(cDocument: xmlDocPtr) {
    self.cDocument = cDocument
    if let cRoot = xmlDocGetRootElement(cDocument) {
      root = XMLElement(cNode: cRoot, document: self)
    }
  }
  
  deinit {
    xmlFreeDoc(cDocument)
  }
  
  // MARK: - XML Namespaces
  var namespaces = [String: String]()  // prefix -> URI
  
  /**
  Defines a new prefix for the given namespace in XPath expressions.
  
  - parameter prefix: The prefix name
  - parameter ns:     The namespace URI declared in the XML Document
  */
  open func definePrefix(_ prefix: String, forNamespace ns: String) {
    namespaces[prefix] = ns
  }

  /**
   Define a prefix for a default namespace.
   
   - parameter prefix: The prefix name
   - parameter ns:     The default namespace URI that declared in XML Document
   */
  @available(*, deprecated, renamed: "definePrefix(_:forNamespace:)", message: "This API will be removed in version 4.")
  open func definePrefix(_ prefix: String, defaultNamespace ns: String) {
    definePrefix(prefix, forNamespace: ns)
  }
}

extension XMLDocument: Equatable {}

/**
Determine whether two documents are the same

- parameter lhs: XMLDocument on the left
- parameter rhs: XMLDocument on the right

- returns: whether lhs and rhs are equal
*/
public func ==(lhs: XMLDocument, rhs: XMLDocument) -> Bool {
  return lhs.cDocument == rhs.cDocument
}

/// HTML document which can be searched and queried.
open class HTMLDocument: XMLDocument {
  // MARK: - Convenience Accessors
  
  /// HTML title of current document
  open var title: String? {
    return root?.firstChild(tag: "head")?.firstChild(tag: "title")?.stringValue
  }
  
  /// HTML head element of current document
  open var head: XMLElement? {
    return root?.firstChild(tag: "head")
  }
  
  /// HTML body element of current document
  open var body: XMLElement? {
    return root?.firstChild(tag: "body")
  }

  fileprivate override class func parse(buffer: UnsafeBufferPointer<Int8>, options: Int32) -> xmlDocPtr? {
    return htmlReadMemory(buffer.baseAddress, Int32(buffer.count), "", nil, options)
  }
}
