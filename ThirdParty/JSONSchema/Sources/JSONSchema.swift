//
//  JSONSchema.swift
//  JSONSchema
//
//  Created by Kyle Fuller on 07/03/2015.
//  Copyright (c) 2015 Cocode. All rights reserved.
//

import Foundation

public enum Type: Swift.String {
  case Object = "object"
  case Array = "array"
  case String = "string"
  case Integer = "integer"
  case Number = "number"
  case Boolean = "boolean"
  case Null = "null"
}

extension String {
  func stringByRemovingPrefix(prefix:String) -> String? {
    if hasPrefix(prefix) {
      let index = startIndex.advancedBy(prefix.characters.count)
      return substringFromIndex(index)
    }

    return nil
  }
}

public struct Schema {
  public let title:String?
  public let description:String?

  public let type:[Type]?

  /// validation formats, currently private. If anyone wants to add custom please make a PR to make this public ;)
  let formats:[String:Validator]

  let schema:[String:AnyObject]

  public init(_ schema:[String:AnyObject]) {
    title = schema["title"] as? String
    description = schema["description"] as? String

    if let type = schema["type"] as? String {
      if let type = Type(rawValue: type) {
        self.type = [type]
      } else {
        self.type = []
      }
    } else if let types = schema["type"] as? [String] {
      self.type = types.map { Type(rawValue: $0) }.filter { $0 != nil }.map { $0! }
    } else {
      self.type = []
    }

    self.schema = schema

    formats = [
      "ipv4": validateIPv4,
      "ipv6": validateIPv6,
    ]
  }

  public func validate(data:AnyObject) -> ValidationResult {
    let validator = allOf(validators(self)(schema: schema))
    let result = validator(value: data)
    return result
  }

  func validatorForReference(reference:String) -> Validator {
    // TODO: Rewrite this whole block: https://github.com/kylef/JSONSchema.swift/issues/12

    if let reference = reference.stringByRemovingPrefix("#") {  // Document relative
      if let reference = reference.stringByRemovingPrefix("/")?.stringByRemovingPercentEncoding {
        var components = reference.componentsSeparatedByString("/")
        var schema = self.schema
        while let component = components.first {
          components.removeAtIndex(components.startIndex)

          if let subschema = schema[component] as? [String:AnyObject] {
            schema = subschema
            continue
          } else if let schemas = schema[component] as? [[String:AnyObject]] {
            if let component = components.first, index = Int(component) {
              components.removeAtIndex(components.startIndex)

              if schemas.count > index {
                schema = schemas[index]
                continue
              }
            }
          }

          return invalidValidation("Reference not found '\(component)' in '\(reference)'")
        }

        return allOf(JSONSchema.validators(self)(schema: schema))
      } else if reference == "" {
        return { value in
          let validators = JSONSchema.validators(self)(schema: self.schema)
          return allOf(validators)(value:value)
        }
      }
    }

    return invalidValidation("Remote $ref '\(reference)' is not yet supported")
  }
}

/// Returns a set of validators for a schema and document
func validators(root: Schema) -> (schema: [String:AnyObject]) -> [Validator] {
  return { schema in
    var validators = [Validator]()

    if let ref = schema["$ref"] as? String {
      validators.append(root.validatorForReference(ref))
    }

    if let type: AnyObject = schema["type"] {
      // Rewrite this and most of the validator to use the `type` property, see https://github.com/kylef/JSONSchema.swift/issues/12
      validators.append(validateType(type))
    }

    if let allOf = schema["allOf"] as? [[String:AnyObject]] {
      validators += allOf.map(JSONSchema.validators(root)).reduce([], combine: +)
    }

    if let anyOfSchemas = schema["anyOf"] as? [[String:AnyObject]] {
      let anyOfValidators = anyOfSchemas.map(JSONSchema.validators(root)).map(allOf) as [Validator]
      validators.append(anyOf(anyOfValidators))
    }

    if let oneOfSchemas = schema["oneOf"] as? [[String:AnyObject]] {
      let oneOfValidators = oneOfSchemas.map(JSONSchema.validators(root)).map(allOf) as [Validator]
      validators.append(oneOf(oneOfValidators))
    }

    if let notSchema = schema["not"] as? [String:AnyObject] {
      let notValidator = allOf(JSONSchema.validators(root)(schema:notSchema))
      validators.append(not(notValidator))
    }

    if let enumValues = schema["enum"] as? [AnyObject] {
      validators.append(validateEnum(enumValues))
    }

    // String

    if let maxLength = schema["maxLength"] as? Int {
      validators.append(validateLength(<=, length: maxLength, error: "Length of string is larger than max length \(maxLength)"))
    }

    if let minLength = schema["minLength"] as? Int {
      validators.append(validateLength(>=, length: minLength, error: "Length of string is smaller than minimum length \(minLength)"))
    }

    if let pattern = schema["pattern"] as? String {
      validators.append(validatePattern(pattern))
    }

    // Numerical

    if let multipleOf = schema["multipleOf"] as? Double {
      validators.append(validateMultipleOf(multipleOf))
    }

    if let minimum = schema["minimum"] as? Double {
      validators.append(validateNumericLength(minimum, comparitor: >=, exclusiveComparitor: >, exclusive: schema["exclusiveMinimum"] as? Bool, error: "Value is lower than minimum value of \(minimum)"))
    }

    if let maximum = schema["maximum"] as? Double {
      validators.append(validateNumericLength(maximum, comparitor: <=, exclusiveComparitor: <, exclusive: schema["exclusiveMaximum"] as? Bool, error: "Value exceeds maximum value of \(maximum)"))
    }

    // Array

    if let minItems = schema["minItems"] as? Int {
      validators.append(validateArrayLength(minItems, comparitor: >=, error: "Length of array is smaller than the minimum \(minItems)"))
    }

    if let maxItems = schema["maxItems"] as? Int {
      validators.append(validateArrayLength(maxItems, comparitor: <=, error: "Length of array is greater than maximum \(maxItems)"))
    }

    if let uniqueItems = schema["uniqueItems"] as? Bool {
      if uniqueItems {
        validators.append(validateUniqueItems)
      }
    }

    if let items = schema["items"] as? [String:AnyObject] {
      let itemsValidators = allOf(JSONSchema.validators(root)(schema:items))

      func validateItems(document:AnyObject) -> ValidationResult {
        if let document = document as? [AnyObject] {
          return flatten(document.map(itemsValidators))
        }

        return .Valid
      }

      validators.append(validateItems)
    } else if let items = schema["items"] as? [[String:AnyObject]] {
      func createAdditionalItemsValidator(additionalItems:AnyObject?) -> Validator {
        if let additionalItems = additionalItems as? [String:AnyObject] {
          return allOf(JSONSchema.validators(root)(schema:additionalItems))
        }

        let additionalItems = additionalItems as? Bool ?? true
        if additionalItems {
          return validValidation
        }

        return invalidValidation("Additional results are not permitted in this array.")
      }

      let additionalItemsValidator = createAdditionalItemsValidator(schema["additionalItems"])
      let itemValidators = items.map(JSONSchema.validators(root))

      func validateItems(value:AnyObject) -> ValidationResult {
        if let value = value as? [AnyObject] {
          var results = [ValidationResult]()

          for (index, element) in value.enumerate() {
            if index >= itemValidators.count {
              results.append(additionalItemsValidator(element))
            } else {
              let validators = allOf(itemValidators[index])
              results.append(validators(value:element))
            }
          }

          return flatten(results)
        }

        return .Valid
      }

      validators.append(validateItems)
    }

    if let maxProperties = schema["maxProperties"] as? Int {
      validators.append(validatePropertiesLength(maxProperties, comparitor: >=, error: "Amount of properties is greater than maximum permitted"))
    }

    if let minProperties = schema["minProperties"] as? Int {
      validators.append(validatePropertiesLength(minProperties, comparitor: <=, error: "Amount of properties is less than the required amount"))
    }

    if let required = schema["required"] as? [String] {
      validators.append(validateRequired(required))
    }

    if (schema["properties"] != nil) || (schema["patternProperties"] != nil) || (schema["additionalProperties"] != nil) {
      func createAdditionalPropertiesValidator(additionalProperties:AnyObject?) -> Validator {
        if let additionalProperties = additionalProperties as? [String:AnyObject] {
          return allOf(JSONSchema.validators(root)(schema:additionalProperties))
        }

        let additionalProperties = additionalProperties as? Bool ?? true
        if additionalProperties {
          return validValidation
        }

        return invalidValidation("Additional properties are not permitted in this object.")
      }

      func createPropertiesValidators(properties:[String:[String:AnyObject]]?) -> [String:Validator]? {
        if let properties = properties {
          return Dictionary(properties.keys.map {
            key in (key, allOf(JSONSchema.validators(root)(schema:properties[key]!)))
          })
        }

        return nil
      }

      let additionalPropertyValidator = createAdditionalPropertiesValidator(schema["additionalProperties"])
      let properties = createPropertiesValidators(schema["properties"] as? [String:[String:AnyObject]])
      let patternProperties = createPropertiesValidators(schema["patternProperties"] as? [String:[String:AnyObject]])
      validators.append(validateProperties(properties, patternProperties: patternProperties, additionalProperties: additionalPropertyValidator))
    }

    func validateDependency(key: String, validator: Validator) -> (value: AnyObject) -> ValidationResult {
      return { value in
        if let value = value as? [String:AnyObject] {
          if (value[key] != nil) {
            return validator(value)
          }
        }

        return .Valid
      }
    }

    func validateDependencies(key: String, dependencies: [String]) -> (value: AnyObject) -> ValidationResult {
      return { value in
        if let value = value as? [String:AnyObject] {
          if (value[key] != nil) {
            return flatten(dependencies.map { dependency in
              if value[dependency] == nil {
                return .Invalid(["'\(key)' is missing it's dependency of '\(dependency)'"])
              }
              return .Valid
            })
          }
        }

        return .Valid
      }
    }

    if let dependencies = schema["dependencies"] as? [String:AnyObject] {
      for (key, dependencies) in dependencies {
        if let dependencies = dependencies as? [String: AnyObject] {
          let schema = allOf(JSONSchema.validators(root)(schema:dependencies))
          validators.append(validateDependency(key, validator: schema))
        } else if let dependencies = dependencies as? [String] {
          validators.append(validateDependencies(key, dependencies: dependencies))
        }
      }
    }

    if let format = schema["format"] as? String {
      if let validator = root.formats[format] {
        validators.append(validator)
      } else {
        validators.append(invalidValidation("'format' validation of '\(format)' is not yet supported."))
      }
    }

    return validators
  }
}

public func validate(value:AnyObject, schema:[String:AnyObject]) -> ValidationResult {
  let root = Schema(schema)
  let validator = allOf(validators(root)(schema:schema))
  let result = validator(value: value)
  return result
}

/// Extension for dictionary providing initialization from array of elements
extension Dictionary {
  init(_ pairs: [Element]) {
    self.init()

    for (key, value) in pairs {
      self[key] = value
    }
  }
}
