//
//  Validators.swift
//  JSONSchema
//
//  Created by Kyle Fuller on 07/03/2015.
//  Copyright (c) 2015 Cocode. All rights reserved.
//

import Foundation


public enum ValidationResult {
  case Valid
  case Invalid([String])

  public var valid: Bool {
    switch self {
    case .Valid:
      return true
    case .Invalid:
      return false
    }
  }

  public var errors:[String]? {
    switch self {
    case .Valid:
      return nil
    case .Invalid(let errors):
      return errors
    }
  }
}

typealias LegacyValidator = (AnyObject) -> (Bool)
typealias Validator = (AnyObject) -> (ValidationResult)

/// Flatten an array of results into a single result (combining all errors)
func flatten(results:[ValidationResult]) -> ValidationResult {
  let failures = results.filter { result in !result.valid }
  if failures.count > 0 {
    let errors = failures.reduce([String]()) { (accumulator, failure) in
      if let errors = failure.errors {
        return accumulator + errors
      }

      return accumulator
    }

    return .Invalid(errors)
  }

  return .Valid
}

/// Creates a Validator which always returns an valid result
func validValidation(value:AnyObject) -> ValidationResult {
  return .Valid
}

/// Creates a Validator which always returns an invalid result with the given error
func invalidValidation(error: String) -> (value: AnyObject) -> ValidationResult {
  return { value in
    return .Invalid([error])
  }
}

// MARK: Shared

/// Validate the given value is of the given type
func validateType(type: String) -> (value: AnyObject) -> ValidationResult {
  return { value in
    switch type {
    case "integer":
      if let number = value as? NSNumber {
        if !CFNumberIsFloatType(number) && CFGetTypeID(number) != CFBooleanGetTypeID() {
          return .Valid
        }
      }
    case "number":
      if let number = value as? NSNumber {
        if CFGetTypeID(number) != CFBooleanGetTypeID() {
          return .Valid
        }
      }
    case "string":
      if value is String {
        return .Valid
      }
    case "object":
      if value is NSDictionary {
        return .Valid
      }
    case "array":
      if value is NSArray {
        return .Valid
      }
    case "boolean":
      if let number = value as? NSNumber {
        if CFGetTypeID(number) == CFBooleanGetTypeID() {
          return .Valid
        }
      }
    case "null":
      if value is NSNull {
        return .Valid
      }
    default:
      break
    }

    return .Invalid(["'\(value)' is not of type '\(type)'"])
  }
}

/// Validate the given value is one of the given types
func validateType(type:[String]) -> Validator {
  let typeValidators = type.map(validateType) as [Validator]
  return anyOf(typeValidators)
}

func validateType(type:AnyObject) -> Validator {
  if let type = type as? String {
    return validateType(type)
  } else if let types = type as? [String] {
    return validateType(types)
  }

  return invalidValidation("'\(type)' is not a valid 'type'")
}


/// Validate that a value is valid for any of the given validation rules
func anyOf(validators:[Validator], error:String? = nil) -> (value: AnyObject) -> ValidationResult {
  return { value in
    for validator in validators {
      let result = validator(value)
      if result.valid {
        return .Valid
      }
    }

    if let error = error {
      return .Invalid([error])
    }

    return .Invalid(["\(value) does not meet anyOf validation rules."])
  }
}

func oneOf(validators: [Validator]) -> (value: AnyObject) -> ValidationResult {
  return { value in
    let results = validators.map { validator in validator(value) }
    let validValidators = results.filter { $0.valid }.count

    if validValidators == 1 {
      return .Valid
    }

    return .Invalid(["\(validValidators) validates instead `oneOf`."])
  }
}

/// Creates a validator that validates that the given validation rules are not met
func not(validator: Validator) -> (value: AnyObject) -> ValidationResult {
  return { value in
    if validator(value).valid {
      return .Invalid(["'\(value)' does not match 'not' validation."])
    }

    return .Valid
  }
}

func allOf(validators: [Validator]) -> (value: AnyObject) -> ValidationResult {
  return { value in
    return flatten(validators.map { validator in validator(value) })
  }
}

func validateEnum(values: [AnyObject]) -> (value: AnyObject) -> ValidationResult {
  return { value in
    if (values as! [NSObject]).contains(value as! NSObject) {
      return .Valid
    }

    return .Invalid(["'\(value)' is not a valid enumeration value of '\(values)'"])
  }
}

// MARK: String

func validateLength(comparitor: ((Int, Int) -> (Bool)), length: Int, error: String) -> (value: AnyObject) -> ValidationResult {
  return { value in
    if let value = value as? String {
      if !comparitor(value.characters.count, length) {
        return .Invalid([error])
      }
    }

    return .Valid
  }
}

func validatePattern(pattern: String) -> (value: AnyObject) -> ValidationResult {
  return { value in
    if let value = value as? String {
      let expression = try? NSRegularExpression(pattern: pattern, options: NSRegularExpressionOptions(rawValue: 0))
      if let expression = expression {
        let range = NSMakeRange(0, value.characters.count)
        if expression.matchesInString(value, options: NSMatchingOptions(rawValue: 0), range: range).count == 0 {
          return .Invalid(["'\(value)' does not match pattern: '\(pattern)'"])
        }
      } else {
        return .Invalid(["[Schema] Regex pattern '\(pattern)' is not valid"])
      }
    }

    return .Valid
  }
}

// MARK: Numerical

func validateMultipleOf(number: Double) -> (value: AnyObject) -> ValidationResult {
  return { value in
    if number > 0.0 {
      if let value = value as? Double {
        let result = value / number
        if result != floor(result) {
          return .Invalid(["\(value) is not a multiple of \(number)"])
        }
      }
    }

    return .Valid
  }
}

func validateNumericLength(length: Double, comparitor: ((Double, Double) -> (Bool)), exclusiveComparitor: ((Double, Double) -> (Bool)), exclusive: Bool?, error: String) -> (value: AnyObject) -> ValidationResult {
  return { value in
    if let value = value as? Double {
      if exclusive ?? false {
        if !exclusiveComparitor(value, length) {
          return .Invalid([error])
        }
      }

      if !comparitor(value, length) {
        return .Invalid([error])
      }
    }

    return .Valid
  }
}

// MARK: Array

func validateArrayLength(rhs: Int, comparitor: ((Int, Int) -> Bool), error: String) -> (value: AnyObject) -> ValidationResult {
  return { value in
    if let value = value as? [AnyObject] {
      if !comparitor(value.count, rhs) {
        return .Invalid([error])
      }
    }

    return .Valid
  }
}

func validateUniqueItems(value: AnyObject) -> ValidationResult {
  if let value = value as? [AnyObject] {
    // 1 and true, 0 and false are isEqual for NSNumber's, so logic to count for that below

    func isBoolean(number:NSNumber) -> Bool {
      return CFGetTypeID(number) != CFBooleanGetTypeID()
    }

    let numbers = value.filter { value in value is NSNumber } as! [NSNumber]
    let numerBooleans = numbers.filter(isBoolean)
    let booleans = numerBooleans as! [Bool]
    let nonBooleans = numbers.filter { number in !isBoolean(number) }
    let hasTrueAndOne = booleans.filter { v in v }.count > 0 && nonBooleans.filter { v in v == 1 }.count > 0
    let hasFalseAndZero = booleans.filter { v in !v }.count > 0 && nonBooleans.filter { v in v == 0 }.count > 0
    let delta = (hasTrueAndOne ? 1 : 0) + (hasFalseAndZero ? 1 : 0)

    if (NSSet(array: value).count + delta) == value.count {
      return .Valid
    }

    return .Invalid(["\(value) does not have unique items"])
  }

  return .Valid
}

// MARK: Object

func validatePropertiesLength(length: Int, comparitor: ((Int, Int) -> (Bool)), error: String) -> (value: AnyObject)  -> ValidationResult {
  return { value in
    if let value = value as? [String:AnyObject] {
      if !comparitor(length, value.count) {
        return .Invalid([error])
      }
    }

    return .Valid
  }
}

func validateRequired(required: [String]) -> (value: AnyObject)  -> ValidationResult {
  return { value in
    if let value = value as? [String:AnyObject] {
      if (required.filter { r in !value.keys.contains(r) }.count == 0) {
        return .Valid
      }

      return .Invalid(["Required properties are missing '\(required)'"])
    }

    return .Valid
  }
}

func validateProperties(properties: [String:Validator]?, patternProperties: [String:Validator]?, additionalProperties: Validator?) -> (value: AnyObject) -> ValidationResult {
  return { value in
    if let value = value as? [String:AnyObject] {
      let allKeys = NSMutableSet()
      var results = [ValidationResult]()

      if let properties = properties {
        for (key, validator) in properties {
          allKeys.addObject(key)

          if let value: AnyObject = value[key] {
            results.append(validator(value))
          }
        }
      }

      if let patternProperties = patternProperties {
        for (pattern, validator) in patternProperties {
          do {
            let expression = try NSRegularExpression(pattern: pattern, options: NSRegularExpressionOptions(rawValue: 0))
            let keys = value.keys.filter {
              (key: String) in expression.matchesInString(key, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, key.characters.count)).count > 0
            }

            allKeys.addObjectsFromArray(Array(keys))
            results += keys.map { key in validator(value[key]!) }
          } catch {
            return .Invalid(["[Schema] '\(pattern)' is not a valid regex pattern for patternProperties"])
          }
        }
      }

      if let additionalProperties = additionalProperties {
        let additionalKeys = value.keys.filter { !allKeys.containsObject($0) }
        results += additionalKeys.map { key in additionalProperties(value[key]!) }
      }

      return flatten(results)
    }

    return .Valid
  }
}

func validateDependency(key: String, validator: LegacyValidator) -> (value: AnyObject) -> Bool {
  return { value in
    if let value = value as? [String:AnyObject] {
      if (value[key] != nil) {
        return validator(value)
      }
    }

    return true
  }
}

func validateDependencies(key: String, dependencies: [String]) -> (value: AnyObject) -> Bool {
  return { value in
    if let value = value as? [String:AnyObject] {
      if (value[key] != nil) {
        for dependency in dependencies {
          if (value[dependency] == nil) {
            return false
          }
        }
      }
    }

    return true
  }
}

// MARK: Format

func validateIPv4(value:AnyObject) -> ValidationResult {
  if let ipv4 = value as? String {
    if let expression = try? NSRegularExpression(pattern: "^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", options: NSRegularExpressionOptions(rawValue: 0)) {
      if expression.matchesInString(ipv4, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, ipv4.characters.count)).count == 1 {
        return .Valid
      }
    }

    return .Invalid(["'\(ipv4)' is not valid IPv4 address."])
  }

  return .Valid
}

func validateIPv6(value:AnyObject) -> ValidationResult {
  if let ipv6 = value as? String {
    var buf = UnsafeMutablePointer<Void>.alloc(Int(INET6_ADDRSTRLEN))
    if inet_pton(AF_INET6, ipv6, &buf) == 1 {
      return .Valid
    }

    return .Invalid(["'\(ipv6)' is not valid IPv6 address."])
  }

  return .Valid
}
