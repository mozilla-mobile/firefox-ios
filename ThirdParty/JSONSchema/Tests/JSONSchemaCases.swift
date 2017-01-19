//
//  JSONSchemaCases.swift
//  JSONSchema
//
//  Created by Kyle Fuller on 07/03/2015.
//  Copyright (c) 2015 Cocode. All rights reserved.
//

import Foundation
import XCTest
import JSONSchema

func fixture(named:String, forObject:AnyObject) -> NSData {
  let bundle = NSBundle(forClass:object_getClass(forObject))
  let path = bundle.URLForResource(named, withExtension: nil)!
  let data = NSData(contentsOfURL: path)!
  return data
}

func JSONFixture(named:String, forObject:AnyObject) -> [[String:AnyObject]] {
  let data = fixture(named, forObject: forObject)
  let object: AnyObject?
  do {
    object = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))
  } catch {
    fatalError()
  }
  return object as! [[String:AnyObject]]
}

class JSONSchemaCases: XCTestCase {
  func testEverything() {
    let bundle = NSBundle(forClass: JSONSchemaCases.self)
    let fileManager = NSFileManager.defaultManager()
    let files = fileManager.enumeratorAtPath(bundle.resourcePath!)!.allObjects as! [String]
    let suites = files.filter { (path) -> Bool in
      let blacklist = [
        "ref.json",
        "refRemote.json",
        "definitions.json",

        // Optionals
        "bignum.json",
        "format.json",
      ]
      return path.hasSuffix(".json") && !blacklist.contains(path)
    }

    let cases = suites.map { (file) -> [Case] in
      let suite = JSONFixture(file, forObject: self)
      return suite.map(makeCase(file))
    }

    let flatCases = cases.reduce([Case](), combine: +)
    for c in flatCases {
      for (name, assertion) in makeAssertions(c) {
        // TODO: Improve testing
        print(name)
        assertion()
      }
    }
  }
}

struct Test {
  let description:String
  let data:AnyObject
  let value:Bool

  init(description:String, data:AnyObject, value:Bool) {
    self.description = description
    self.data = data
    self.value = value
  }
}

func makeTest(object:[String:AnyObject]) -> Test {
  return Test(description: object["description"] as! String, data: object["data"] as AnyObject!, value: object["valid"] as! Bool)
}

struct Case {
  let description:String
  let schema:[String:AnyObject]
  let tests:[Test]

  init(description:String, schema:[String:AnyObject], tests:[Test]) {
    self.description = description
    self.schema = schema
    self.tests = tests
  }
}

func makeCase(filename: String) -> (object: [String:AnyObject]) -> Case {
  return { object in
    let description = object["description"] as! String
    let schema = object["schema"] as! [String:AnyObject]
    let tests = (object["tests"] as! [[String: AnyObject]]).map(makeTest)
    let caseName = (filename as NSString).stringByDeletingPathExtension
    return Case(description: "\(caseName) \(description)", schema: schema, tests: tests)
  }
}

typealias Assertion = (String, () -> ())

func makeAssertions(c:Case) -> ([Assertion]) {
  return c.tests.map { test -> Assertion in
    return ("\(c.description) \(test.description)", {
      let result = validate(test.data, schema: c.schema)
      switch result {
      case .Valid:
        XCTAssertEqual(result.valid, test.value, "Result is valid")
      case .Invalid(let errors):
        XCTAssertEqual(result.valid, test.value, "Failed validation: \(errors)")
      }
    })
  }
}
