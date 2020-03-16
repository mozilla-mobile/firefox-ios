// Error.swift
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
*  XMLError enumeration.
*/
public enum XMLError: Error {
  /// No error
  case noError
  /// Contains a libxml2 error with error code and message
  case libXMLError(code: Int, message: String)
  /// Failed to convert String to bytes using given string encoding
  case invalidData
  /// XML Parser failed to parse the document
  case parserFailure
  /// XPath has either syntax error or some unknown/unsupported function
  case xpathError(code: Int)
  
  internal static func lastError(defaultError: XMLError = .noError) -> XMLError {
    guard let errorPtr = xmlGetLastError() else {
      return defaultError
    }
    let message = (^-^errorPtr.pointee.message)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    let code = Int(errorPtr.pointee.code)
    xmlResetError(errorPtr)
    return .libXMLError(code: code, message: message ?? "")
  }
}
