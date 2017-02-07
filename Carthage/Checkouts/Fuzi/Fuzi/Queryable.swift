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
  func xpath(xpath: String) -> XPathNodeSet
  
  /**
  Returns the first elements matching an XPath selector, or `nil` if there are no results.
  
  - parameter xpath: The XPath selector.
  
  - returns: The child element.
  */
  func firstChild(xpath xpath: String) -> XMLElement?
  
  /**
  Returns the results for a CSS selector.
  
  - parameter css: The CSS selector string.
  
  - returns: An enumerable collection of results.
  */
  func css(css: String) -> XPathNodeSet
  
  /**
  Returns the first elements matching an CSS selector, or `nil` if there are no results.
  
  - parameter css: The CSS selector.
  
  - returns: The child element.
  */
  func firstChild(css css: String) -> XMLElement?
  
  /**
  Returns the result for evaluating an XPath selector that contains XPath function.
  
  - parameter xpath: The XPath query string.
  
  - returns: The eval function result.
  */
  func eval(xpath xpath: String) -> XPathFunctionResult?
}

/// Result for evaluating a XPath expression
public class XPathFunctionResult {
  /// Boolean value
  public private(set) lazy var boolValue: Bool = {
    return self.cXPath.memory.boolval != 0
  }()
  
  /// Double value
  public private(set) lazy var doubleValue: Double = {
    return self.cXPath.memory.floatval
  }()
  
  /// String value
  public private(set) lazy var stringValue: String = {
    return ^-^self.cXPath.memory.stringval ?? ""
  }()
  
  private let cXPath: xmlXPathObjectPtr
  internal init?(cXPath: xmlXPathObjectPtr) {
    self.cXPath = cXPath
    if cXPath == nil {
      return nil
    }
  }
  
  deinit {
    if cXPath != nil {
      xmlXPathFreeObject(cXPath)
    }
  }
}

extension XMLDocument: Queryable {
  /**
  Returns the results for an XPath selector.
  
  - parameter xpath: XPath selector string.
  
  - returns: An enumerable collection of results.
  */
  public func xpath(xpath: String) -> XPathNodeSet {
    return root == nil ?XPathNodeSet.emptySet :root!.xpath(xpath)
  }
  
  /**
  Returns the first elements matching an XPath selector, or `nil` if there are no results.
  
  - parameter xpath: The XPath selector.
  
  - returns: The child element.
  */
  public func firstChild(xpath xpath: String) -> XMLElement? {
    return root?.firstChild(xpath: xpath)
  }
  
  /**
  Returns the results for a CSS selector.
  
  - parameter css: The CSS selector string.
  
  - returns: An enumerable collection of results.
  */
  public func css(css: String) -> XPathNodeSet {
    return root == nil ?XPathNodeSet.emptySet :root!.css(css)
  }
  
  /**
  Returns the first elements matching an CSS selector, or `nil` if there are no results.
  
  - parameter css: The CSS selector.
  
  - returns: The child element.
  */
  public func firstChild(css css: String) -> XMLElement? {
    return root?.firstChild(css: css)
  }
  
  /**
  Returns the result for evaluating an XPath selector that contains XPath function.
  
  - parameter xpath: The XPath query string.
  
  - returns: The eval function result.
  */
  public func eval(xpath xpath: String) -> XPathFunctionResult? {
    return root?.eval(xpath: xpath)
  }
}

extension XMLElement: Queryable {
  /**
  Returns the results for an XPath selector.
  
  - parameter xpath: XPath selector string.
  
  - returns: An enumerable collection of results.
  */
  public func xpath(xpath: String) -> XPathNodeSet {
    let cXPath = cXPathWithXPathString(xpath)
    if cXPath != nil {
      return XPathNodeSet(cXPath: cXPath, document: document)
    }
    return XPathNodeSet.emptySet
  }
  
  /**
  Returns the first elements matching an XPath selector, or `nil` if there are no results.
  
  - parameter xpath: The XPath selector.
  
  - returns: The child element.
  */
  public func firstChild(xpath xpath: String) -> XMLElement? {
    return self.xpath(xpath).first
  }
  
  /**
  Returns the results for a CSS selector.
  
  - parameter css: The CSS selector string.
  
  - returns: An enumerable collection of results.
  */
  public func css(css: String) -> XPathNodeSet {
    return xpath(XPathFromCSS(css))
  }
  
  /**
  Returns the first elements matching an CSS selector, or `nil` if there are no results.
  
  - parameter css: The CSS selector.
  
  - returns: The child element.
  */
  public func firstChild(css css: String) -> XMLElement? {
    return self.css(css).first
  }
  
  /**
  Returns the result for evaluating an XPath selector that contains XPath function.
  
  - parameter xpath: The XPath query string.
  
  - returns: The eval function result.
  */
  public func eval(xpath xpath: String) -> XPathFunctionResult? {
    return XPathFunctionResult(cXPath: cXPathWithXPathString(xpath))
  }
  
  private func cXPathWithXPathString(xpath: String) -> xmlXPathObjectPtr {
    let context = xmlXPathNewContext(cNode.memory.doc)
    if context != nil {
      context.memory.node = cNode
      var node = cNode
      while node.memory.parent != nil {
        var ns = node.memory.nsDef
        while ns != nil {
          var prefix = ns.memory.prefix
          var prefixChars = [CChar]()
          if prefix == nil && !document.defaultNamespaces.isEmpty {
            let href = (^-^ns.memory.href)!
            
            if let defaultPrefix = document.defaultNamespaces[href] {
              prefixChars = defaultPrefix.cStringUsingEncoding(NSUTF8StringEncoding) ?? []
              prefix = UnsafePointer(prefixChars)
            }
          }
          if prefix != nil {
            xmlXPathRegisterNs(context, prefix, ns.memory.href)
          }
          ns = ns.memory.next
        }
        node = node.memory.parent
      }
      let xmlXPath = xmlXPathEvalExpression(xpath, context)
      
      xmlXPathFreeContext(context)
      return xmlXPath
    }
    return nil
  }
}

private class RegexConstants {
  static let idRegex = try! NSRegularExpression(pattern: "\\#([\\w-_]+)", options: [])
  
  static let classRegex = try! NSRegularExpression(pattern: "\\.([^\\.]+)", options: [])
  
  static let attributeRegex = try! NSRegularExpression(pattern: "\\[(\\w+)\\]", options: [])
}

internal func XPathFromCSS(css: String) -> String {
  var xpathExpressions = [String]()
  for expression in css.componentsSeparatedByString(",") where !expression.isEmpty {
    var xpathComponents = ["./"]
    var prefix: String? = nil
    let expressionComponents = expression.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    for (idx, var token) in expressionComponents.enumerate() {
      switch token {
      case "*" where idx != 0: xpathComponents.append("/*")
      case ">": prefix = ""
      case "+": prefix = "following-sibling::*[1]/self::"
      case "~": prefix = "following-sibling::"
      default:
        if prefix == nil && idx != 0 {
          prefix = "descendant::"
        }
        if let symbolRange = token.rangeOfCharacterFromSet(NSCharacterSet(charactersInString: "#.[]")) {
          let symbol = symbolRange.startIndex == token.startIndex ?"*" :""
          var xpathComponent = token.substringToIndex(symbolRange.startIndex)
          let nsrange = NSRange(location: 0, length: token.utf16.count)
          
          if let result = RegexConstants.idRegex.firstMatchInString(token, options: [], range: nsrange) where result.numberOfRanges > 1 {
            xpathComponent += "\(symbol)[@id = '\(token[result.rangeAtIndex(1)])']"
          }
          
          for result in RegexConstants.classRegex.matchesInString(token, options: [], range: nsrange) where result.numberOfRanges > 1 {
            xpathComponent += "\(symbol)[contains(concat(' ',normalize-space(@class),' '),' \(token[result.rangeAtIndex(1)]) ')]"
          }
          
          for result in RegexConstants.attributeRegex.matchesInString(token, options: [], range: nsrange) where result.numberOfRanges > 1 {
            xpathComponent += "[@\(token[result.rangeAtIndex(1)])]"
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
    xpathExpressions.append(xpathComponents.joinWithSeparator("/"))
  }
  return xpathExpressions.joinWithSeparator(" | ")
}
