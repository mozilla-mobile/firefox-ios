// XMLTests.swift
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
import Fuzi

class XMLTests: XCTestCase {
  var document: Fuzi.XMLDocument!
  override func setUp() {
    super.setUp()
    let filePath = Bundle(for: XMLTests.self).url(forResource: "xml", withExtension: "xml")!
    do {
      document = try XMLDocument(data: Data(contentsOf: filePath))
    } catch {
      XCTAssertFalse(true, "Error should not be thrown")
    }
  }
  
  func testXMLVersion() {
    XCTAssertEqual(document.version, "1.0", "XML version should be 1.0")
  }
  
  func testXMLEncoding() {
    XCTAssertEqual(document.encoding, String.Encoding.utf8, "XML encoding should be UTF-8")
  }
  
  func testRoot() {
    XCTAssertEqual(document.root!.tag, "spec", "root tag should be spec")
    XCTAssertEqual(document.root!.attributes["w3c-doctype"], "rec", "w3c-doctype should be rec")
    XCTAssertEqual(document.root!.attributes["lang"], "en", "lang should be en")
  }
  
  func testTitle() {
    let titleElement = document.root!.firstChild(tag: "header")?.firstChild(tag: "title")
    XCTAssertNotNil(titleElement, "title element should not be nil")
    XCTAssertEqual(titleElement?.tag, "title", "tag should be `title`")
    XCTAssertEqual(titleElement?.stringValue, "Extensible Markup Language (XML)", "title string value should be 'Extensible Markup Language (XML)'")
  }
  
  func testXPath() {
    let path = "/spec/header/title"
    let elts = document.xpath(path)
    var counter = 0
    for elt in elts {
      XCTAssertEqual("title", elt.tag, "tag should be `title`")
      counter += 1
    }
    XCTAssertEqual(1, counter, "at least one element should have been found at element path '\(path)'")
  }
  
  func testTryXpathThrowsError() {
    do {
      _ = try document.tryXPath("////")
      XCTAssertFalse(true, "error should have been thrown")
    } catch XMLError.libXMLError(code: 1207, message: "Invalid expression") {
      
    } catch {
      XCTAssertFalse(true, "error type should be libXMLError \(error)")
    }
  }
  
  func testTryXpathFunctionThrowsError() {
    do {
      _ = try document.tryXPath("//*[unknown()]")
      XCTAssertFalse(true, "error should have been thrown")
    } catch XMLError.libXMLError(code: 1223, message: "Stack usage error") {
      
    } catch {
      XCTAssertFalse(true, "error type should be libXMLError \(error)")
    }
  }
  
  func testLineNumber() {
    let headerElement = document.root!.firstChild(tag: "header")
    XCTAssertNotNil(headerElement, "header element should not be nil")
    XCTAssertEqual(headerElement?.lineNumber, 123, "header line number should be correct")
  }
  
  func testThrowsError() {
    do {
      document = try XMLDocument(cChars: [CChar]())
      XCTAssertFalse(true, "error should have been thrown")
    } catch XMLError.parserFailure {
      
    } catch {
      XCTAssertFalse(true, "error type should be ParserFailure")
    }
  }

  func testAuthorsByStaticTag() {
    let authlistElement = document.root!.firstChild(staticTag: "header")?.firstChild(staticTag: "authlist")
    XCTAssertNotNil(authlistElement, "authorlist element should not be nil")
    let authorElements = authlistElement?.children(staticTag: "author")
    XCTAssertEqual(authorElements?.count, 5, "should have 5 elements")
  }
}
