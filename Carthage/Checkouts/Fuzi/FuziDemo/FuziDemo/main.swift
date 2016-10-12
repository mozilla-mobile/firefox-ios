// main.swift
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

// This example does exactly the same thing as Ono's example
// https://github.com/mattt/Ono/blob/master/Example/main.m
// Comparing the two may help migrating your code from Ono

import Fuzi

let filePath = ((#file as NSString).stringByDeletingLastPathComponent as NSString).stringByAppendingPathComponent("nutrition.xml")
do {
  let data = NSData(contentsOfFile: filePath)!
  let document = try XMLDocument(data: data)
  
  if let root = document.root {
    print("Root Element: \(root.tag)")
    
    print("\nDaily values:")
    for element in root.firstChild(tag: "daily-values")?.children ?? [] {
      let nutrient = element.tag
      let amount = element.numberValue
      let unit = element["units"]
      print("- \(amount!)\(unit!) \(nutrient!)")
    }
    print("\n")
    var xpath = "//food/name"
    print("XPath Search: \(xpath)")
    for element in document.xpath(xpath) {
      print("\(element)")
    }
    
    print("\n")
    let css = "food > serving[units]"
    var blockElement:XMLElement? = nil
    print("CSS Search: \(css)")
    for (index, element) in document.css(css).enumerate() {
      if index == 1 {
        blockElement = element
        break
      }
    }
    print("Second element: \(blockElement!)\n")
    
    xpath = "//food/name"
    print("XPath Search: \(xpath)")
    let firstElement = document.firstChild(xpath: xpath)!
    print("First element: \(firstElement)")
  }
} catch let error as XMLError {
  switch error {
  case .NoError: print("wth this should not appear")
  case .ParserFailure, .InvalidData: print(error)
  case .LibXMLError(let code, let message):
    print("libxml error code: \(code), message: \(message)")
  }
}
