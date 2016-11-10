// AtomTests.swift
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

class AtomTests: XCTestCase {
  var document: XMLDocument!
  override func setUp() {
    super.setUp()
    let filePath = NSBundle(forClass: AtomTests.self).pathForResource("atom", ofType: "xml")!
    do {
      document = try XMLDocument(data: NSData(contentsOfFile: filePath)!)
    } catch {
      XCTAssertFalse(true, "Error should not be thrown")
    }
    document.definePrefix("atom", defaultNamespace: "http://www.w3.org/2005/Atom")
  }
  
  func testXMLVersion() {
    XCTAssertEqual(document.version, "1.0", "XML version should be 1.0")
  }
  
  func testXMLEncoding() {
    XCTAssertEqual(document.encoding, NSUTF8StringEncoding, "XML encoding should be UTF-8")
  }
  
  func testRoot() {
    XCTAssertEqual(document.root?.tag, "feed", "root tag should be feed")
  }
  
  func testTitle() {
    let titleElement = document.root!.firstChild(tag: "title")
    XCTAssertNotNil(titleElement, "title element should not be nil")
    XCTAssertEqual(titleElement?.tag, "title", "tag should be `title`")
    XCTAssertEqual(titleElement?.stringValue, "Example Feed", "title string value should be 'Example Feed'")
  }
  
  func testXPathTitle() {
    let titleElement = document.root!.firstChild(xpath: "/atom:feed/atom:title")
    XCTAssertNotNil(titleElement, "title element should not be nil")
    XCTAssertEqual(titleElement?.tag, "title", "tag should be `title`")
    XCTAssertEqual(titleElement?.stringValue, "Example Feed", "title string value should be 'Example Feed'")
  }
  
  func testLinks() {
    let linkElements = self.document.root!.children(tag: "link")
    XCTAssertEqual(linkElements.count, 2, "should have 2 link elements")
    XCTAssertEqual(linkElements[0].stringValue, "", "stringValue should be empty")
    XCTAssertNotEqual(linkElements[0]["href"], linkElements[1]["href"], "href values should not be equal")
  }
  
  func testUpdated() {
    let updatedElement = document.root!.firstChild(tag: "updated")
    XCTAssertNotNil(updatedElement?.dateValue, "dateValue should not be nil")
    let dateComponents = NSDateComponents()
    dateComponents.timeZone = NSTimeZone(abbreviation: "UTC")
    dateComponents.year = 2003
    dateComponents.month = 12
    dateComponents.day = 13
    dateComponents.hour = 18
    dateComponents.minute = 30
    dateComponents.second = 2
    XCTAssertEqual(updatedElement?.dateValue, NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)?.dateFromComponents(dateComponents), "dateValue should be equal to December 13, 2003 6:30:02 PM")
  }
  
  func testEntries() {
    let entryElements = document.root!.children(tag: "entry")
    XCTAssertEqual(entryElements.count, 1, "should be 1 entry element")
  }
  
  func testNamespace() {
    let entryElements = document.root!.children(tag: "entry")
    XCTAssertEqual(entryElements.count, 1, "should be 1 entry element")
    
    let namespacedElements = entryElements.first!.children(tag: "language", inNamespace: "dc")
    XCTAssertEqual(namespacedElements.count, 1, "should be 1 entry element")
    
    let namespacedElement = namespacedElements.first!
    XCTAssertNotNil(namespacedElement.namespace, "the namespace shouldn't be nil")
    XCTAssertEqual(namespacedElement.namespace!, "dc", "Namespaces should match")
  }
  
  func testXPathWithNamespaces() {
    var count = 0
    for (index, element) in document.xpath("//dc:language").enumerate() {
      XCTAssertNotNil(element.namespace, "the namespace shouldn't be nil")
      XCTAssertEqual(element.namespace!, "dc", "Namespaces should match")
      count = index + 1
    }
    XCTAssertEqual(count, 1, "should be 1 entry element")
  }
}
