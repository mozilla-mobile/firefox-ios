//
//  JSONSchemaTests.swift
//  JSONSchemaTests
//
//  Created by Kyle Fuller on 23/02/2015.
//  Copyright (c) 2015 Cocode. All rights reserved.
//

import Foundation
import XCTest
import JSONSchema

class JSONSchemaTests: XCTestCase {
  var schema:Schema!

  override func setUp() {
    super.setUp()

    schema = Schema([
      "title": "Product",
      "description": "A product from Acme's catalog",
      "type": "object",
    ])
  }

  func testTitle() {
    XCTAssertEqual(schema.title!, "Product")
  }

  func testDescription() {
    XCTAssertEqual(schema.description!, "A product from Acme's catalog")
  }

  func testType() {
    XCTAssertEqual(schema.type!, [Type.Object])
  }

  func testSuccessfulValidation() {
    XCTAssertTrue(schema.validate([String:AnyObject]()).valid)
  }

  func testUnsuccessfulValidation() {
    XCTAssertFalse(schema.validate([String]()).valid)
  }

  func testReadme() {
    let schema = Schema([
      "type": "object",
      "properties": [
        "name": ["type": "string"],
        "price": ["type": "number"],
      ],
      "required": ["name"],
    ])

    XCTAssertTrue(schema.validate(["name": "Eggs", "price": 34.99]).valid)
    XCTAssertFalse(schema.validate(["price": 34.99]).valid)
  }
}
