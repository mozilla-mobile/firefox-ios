// CSSTests.swift
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

import XCTest
@testable import Fuzi

class CSSTests: XCTestCase {
  func testCSSWildcardSelector() {
    XCTAssertEqual(XPathFromCSS("*"), ".//*")
  }
  
  func testCSSElementSelector() {
    XCTAssertEqual(XPathFromCSS("div"), ".//div")
  }
  
  func testCSSClassSelector() {
    XCTAssertEqual(XPathFromCSS(".highlighted"), ".//*[contains(concat(' ',normalize-space(@class),' '),' highlighted ')]")
  }
  
  func testCSSElementAndClassSelector() {
    XCTAssertEqual(XPathFromCSS("span.highlighted"), ".//span[contains(concat(' ',normalize-space(@class),' '),' highlighted ')]")
  }
  
  func testCSSElementAndIDSelector() {
    XCTAssertEqual(XPathFromCSS("h1#logo"), ".//h1[@id = 'logo']")
  }
  
  func testCSSIDSelector() {
    XCTAssertEqual(XPathFromCSS("#logo"), ".//*[@id = 'logo']")
  }
  
  func testCSSWildcardChildSelector() {
    XCTAssertEqual(XPathFromCSS("html *"), ".//html//*")
  }
  
  func testCSSDescendantCombinatorSelector() {
    XCTAssertEqual(XPathFromCSS("body p"), ".//body/descendant::p")
  }
  
  func testCSSChildCombinatorSelector() {
    XCTAssertEqual(XPathFromCSS("ul > li"), ".//ul/li")
  }
  
  func testCSSAdjacentSiblingCombinatorSelector() {
    XCTAssertEqual(XPathFromCSS("h1 + p"), ".//h1/following-sibling::*[1]/self::p")
  }
  
  func testCSSGeneralSiblingCombinatorSelector() {
    XCTAssertEqual(XPathFromCSS("p ~ p"), ".//p/following-sibling::p")
  }
  
  func testCSSMultipleExpressionSelector() {
    XCTAssertEqual(XPathFromCSS("img[alt]"), ".//img[@alt]")
  }
  
  func testCSSAttributeSelector() {
    XCTAssertEqual(XPathFromCSS("ul, ol"), ".//ul | .//ol")
  }
  
  func testCSSIDCombinatorSelector() {
    XCTAssertEqual(XPathFromCSS("div#test .note"), ".//div[@id = 'test']/descendant::*[contains(concat(' ',normalize-space(@class),' '),' note ')]")
  }
}
