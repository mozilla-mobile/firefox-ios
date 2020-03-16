// Queryable.swift
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

/**
*  The `Queryable` protocol is adopted by `XMLDocument`, `HTMLDocument` and `XMLElement`, denoting that they can search for elements using XPath or CSS selectors.
*/
public protocol Queryable {
  /**
  Returns the results for an XPath selector.
  
  - parameter xpath: XPath selector string.
  
  - returns: An enumerable collection of results.
  */
  func xpath(_ xpath: String) -> NodeSet
  
  /**
   Returns the results for an XPath selector.
   
   - parameter xpath: XPath selector string.
   
   - returns: An enumerable collection of results.
   
   - Throws: last registered XMLError, most likely libXMLError with code and message.
   */
  func tryXPath(_ xpath: String) throws -> NodeSet
  
  /**
  Returns the first elements matching an XPath selector, or `nil` if there are no results.
  
  - parameter xpath: The XPath selector.
  
  - returns: The child element.
  */
  func firstChild(xpath: String) -> XMLElement?
  
  /**
  Returns the results for a CSS selector.
  
  - parameter css: The CSS selector string.
  
  - returns: An enumerable collection of results.
  */
  func css(_ css: String) -> NodeSet
  
  /**
  Returns the first elements matching an CSS selector, or `nil` if there are no results.
  
  - parameter css: The CSS selector.
  
  - returns: The child element.
  */
  func firstChild(css: String) -> XMLElement?
  
  /**
  Returns the result for evaluating an XPath selector that contains XPath function.
  
  - parameter xpath: The XPath query string.
  
  - returns: The eval function result.
  */
  func eval(xpath: String) -> XPathFunctionResult?
}

/// Result for evaluating a XPath expression
open class XPathFunctionResult {
  /// Boolean value
  open fileprivate(set) lazy var boolValue: Bool = {
    return self.cXPath.pointee.boolval != 0
  }()
  
  /// Double value
  open fileprivate(set) lazy var doubleValue: Double = {
    return self.cXPath.pointee.floatval
  }()
  
  /// String value
  open fileprivate(set) lazy var stringValue: String = {
    return ^-^self.cXPath.pointee.stringval ?? ""
  }()
  
  fileprivate let cXPath: xmlXPathObjectPtr
  internal init?(cXPath: xmlXPathObjectPtr?) {
    guard let cXPath = cXPath else {
      return nil
    }
    self.cXPath = cXPath
  }
  
  deinit {
    xmlXPathFreeObject(cXPath)
  }
}

extension XMLDocument: Queryable {
  /**
  Returns the results for an XPath selector.
  
  - parameter xpath: XPath selector string.
  
  - returns: An enumerable collection of results.
  */
  public func xpath(_ xpath: String) -> NodeSet {
    return root == nil ?XPathNodeSet.emptySet :root!.xpath(xpath)
  }
  
  /**
   - parameter xpath: XPath selector string.
   
   - returns: An enumerable collection of results.
   
   - Throws: last registered XMLError, most likely libXMLError with code and message.
   */
  public func tryXPath(_ xpath: String) throws -> NodeSet {
    guard let rootNode = root else {
      return XPathNodeSet.emptySet
    }
    
    return try rootNode.tryXPath(xpath)
  }
  /**
  Returns the first elements matching an XPath selector, or `nil` if there are no results.
  
  - parameter xpath: The XPath selector.
  
  - returns: The child element.
  */
  public func firstChild(xpath: String) -> XMLElement? {
    return root?.firstChild(xpath: xpath)
  }
  
  /**
  Returns the results for a CSS selector.
  
  - parameter css: The CSS selector string.
  
  - returns: An enumerable collection of results.
  */
  public func css(_ css: String) -> NodeSet {
    return root == nil ?XPathNodeSet.emptySet :root!.css(css)
  }
  
  /**
  Returns the first elements matching an CSS selector, or `nil` if there are no results.
  
  - parameter css: The CSS selector.
  
  - returns: The child element.
  */
  public func firstChild(css: String) -> XMLElement? {
    return root?.firstChild(css: css)
  }
  
  /**
  Returns the result for evaluating an XPath selector that contains XPath function.
  
  - parameter xpath: The XPath query string.
  
  - returns: The eval function result.
  */
  public func eval(xpath: String) -> XPathFunctionResult? {
    return root?.eval(xpath: xpath)
  }
}

extension XMLElement: Queryable {
  /**
  Returns the results for an XPath selector.
  
  - parameter xpath: XPath selector string.
  
  - returns: An enumerable collection of results.
  */
  public func xpath(_ xpath: String) -> NodeSet {
    guard let cXPath = try? self.cXPath(xpathString: xpath) else {
      return XPathNodeSet.emptySet
    }
    return XPathNodeSet(cXPath: cXPath, document: document)
  }
  
  /**
   - parameter xpath: XPath selector string.
   
   - returns: An enumerable collection of results.
   
   - Throws: last registered XMLError, most likely libXMLError with code and message.
   */
  public func tryXPath(_ xpath: String) throws -> NodeSet {
    return XPathNodeSet(cXPath: try self.cXPath(xpathString: xpath), document: document)
  }
  /**
  Returns the first elements matching an XPath selector, or `nil` if there are no results.
  
  - parameter xpath: The XPath selector.
  
  - returns: The child element.
  */
  public func firstChild(xpath: String) -> XMLElement? {
    return self.xpath(xpath).first
  }
  
  /**
  Returns the results for a CSS selector.
  
  - parameter css: The CSS selector string.
  
  - returns: An enumerable collection of results.
  */
  public func css(_ css: String) -> NodeSet {
    return xpath(XPath(fromCSS:css))
  }
  
  /**
  Returns the first elements matching an CSS selector, or `nil` if there are no results.
  
  - parameter css: The CSS selector.
  
  - returns: The child element.
  */
  public func firstChild(css: String) -> XMLElement? {
    return self.css(css).first
  }
  
  /**
  Returns the result for evaluating an XPath selector that contains XPath function.
  
  - parameter xpath: The XPath query string.
  
  - returns: The eval function result.
  */
  public func eval(xpath: String) -> XPathFunctionResult? {
    guard let cXPath = try? cXPath(xpathString: xpath) else {
      return nil
    }
    return XPathFunctionResult(cXPath: cXPath)
  }
  
  fileprivate func cXPath(xpathString: String) throws -> xmlXPathObjectPtr {
    guard let context = xmlXPathNewContext(cNode.pointee.doc) else {
      throw XMLError.lastError(defaultError: .xpathError(code: 1207))
    }
    
    func withXMLChar(_ string: String, _ handler: (UnsafePointer<xmlChar>) -> Void) {
      string.utf8CString
        .map { xmlChar(bitPattern: $0) }
        .withUnsafeBufferPointer {
          handler($0.baseAddress!)
        }
    }
    
    context.pointee.node = cNode
    
    // Registers namespace prefixes declared in the document.
    var node = cNode
    while node.pointee.parent != nil {
      var curNs = node.pointee.nsDef
      while let ns = curNs {
        var prefixChars = [CChar]()
        if let prefix = ns.pointee.prefix {
          xmlXPathRegisterNs(context, prefix, ns.pointee.href)
        }
        curNs = ns.pointee.next
      }
      node = node.pointee.parent
    }
    
    // Registers additional namespace prefixes.
    for (prefix, uri) in document.namespaces {
      withXMLChar(prefix) { prefix in
        withXMLChar(uri) { uri in
          xmlXPathRegisterNs(context, prefix, uri)
        }
      }
    }
    
    defer {
      xmlXPathFreeContext(context)
    }
    guard let xmlXPath = xmlXPathEvalExpression(xpathString, context) else {
      throw XMLError.lastError(defaultError: .xpathError(code: 1207))
    }
    return xmlXPath
  }
}

private class RegexConstants {
  static let idRegex = try! NSRegularExpression(pattern: "\\#([\\w-_]+)", options: [])
  
  static let classRegex = try! NSRegularExpression(pattern: "\\.([^\\.]+)", options: [])
  
  static let attributeRegex = try! NSRegularExpression(pattern: "\\[([^\\[\\]]+)\\]", options: [])
}

internal func XPath(fromCSS css: String) -> String {
  var xpathExpressions = [String]()
  for expression in css.components(separatedBy: ",") where !expression.isEmpty {
    var xpathComponents = ["./"]
    var prefix: String? = nil
    let expressionComponents = expression.trimmingCharacters(in: CharacterSet.whitespaces).components(separatedBy: CharacterSet.whitespaces)
    for (idx, var token) in expressionComponents.enumerated() {
      switch token {
      case "*" where idx != 0: xpathComponents.append("/*")
      case ">": prefix = ""
      case "+": prefix = "following-sibling::*[1]/self::"
      case "~": prefix = "following-sibling::"
      default:
        if prefix == nil && idx != 0 {
          prefix = "descendant::"
        }

        if let symbolRange = token.rangeOfCharacter(from: CharacterSet(charactersIn: "#.[]")) {
          let symbol = symbolRange.lowerBound == token.startIndex ?"*" :""
          var xpathComponent = String(token[..<symbolRange.lowerBound])
          let nsrange = NSRange(location: 0, length: token.utf16.count)
          
          if let result = RegexConstants.idRegex.firstMatch(in: token, options: [], range: nsrange), result.numberOfRanges > 1 {
            xpathComponent += "\(symbol)[@id = '\(token[result.range(at: 1)])']"
          }
          
          for result in RegexConstants.classRegex.matches(in: token, options: [], range: nsrange) where result.numberOfRanges > 1 {
            xpathComponent += "\(symbol)[contains(concat(' ',normalize-space(@class),' '),' \(token[result.range(at: 1)]) ')]"
          }
          
          for result in RegexConstants.attributeRegex.matches(in: token, options: [], range: nsrange) where result.numberOfRanges > 1 {
            xpathComponent += "[@\(token[result.range(at: 1)])]"
          }
          
          token = xpathComponent
        }
        
        if prefix != nil {
          token = prefix! + token
          prefix = nil
        }
        
        xpathComponents.append(token)
      }
    }
    xpathExpressions.append(xpathComponents.joined(separator: "/"))
  }
  return xpathExpressions.joined(separator: " | ")
}
