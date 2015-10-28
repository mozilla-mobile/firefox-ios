//
//  json.swift
//  json
//
//  Created by Dan Kogai on 7/15/14.
//  Copyright (c) 2014 Dan Kogai. All rights reserved.
//
import Foundation
/// init
public class JSON {
    private let _value:AnyObject
    /// unwraps the JSON object
    public class func unwrap(obj:AnyObject) -> AnyObject {
        switch obj {
        case let json as JSON:
            return json._value
        case let ary as NSArray:
            var ret = [AnyObject]()
            for v in ary {
                ret.append(unwrap(v))
            }
            return ret
        case let dict as NSDictionary:
            var ret = [String:AnyObject]()
            for (ko, v) in dict {
                if let k = ko as? String {
                    ret[k] = unwrap(v)
                }
            }
            return ret
        default:
            return obj
        }
    }
    /// pass the object that was returned from
    /// NSJSONSerialization
    public init(_ obj:AnyObject) { self._value = JSON.unwrap(obj) }
    /// pass the JSON object for another instance
    public init(_ json:JSON){ self._value = json._value }
}
/// class properties
extension JSON {
    public typealias NSNull = Foundation.NSNull
    public typealias NSError = Foundation.NSError
    public class var null:NSNull { return NSNull() }
    /// constructs JSON object from data
    public convenience init(data:NSData) {
        do {
            // Try parsing some valid JSON
            let obj = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
            self.init(obj)
        }
        catch let error as NSError {
            // Catch fires here, with an NSErrro being thrown from the JSONObjectWithData method
            print("A JSON parsing error occurred, here are the details:\n \(error)")
            self.init(error)
        }
    }
    /// constructs JSON object from string
    public convenience init(string:String) {
        let enc:NSStringEncoding = NSUTF8StringEncoding
        self.init(data: string.dataUsingEncoding(enc)!)
    }
    /// parses string to the JSON object
    /// same as JSON(string:String)
    public class func parse(string:String)->JSON {
        return JSON(string:string)
    }
    /// constructs JSON object from the content of NSURL
    public convenience init(nsurl:NSURL) {
        var enc:NSStringEncoding = NSUTF8StringEncoding
        do {
            let str = try String(NSString(
                contentsOfURL:nsurl, usedEncoding:&enc))
            self.init(string:str)
        } catch let error as NSError {
            self.init(error)
        }
    }
    /// fetch the JSON string from NSURL and parse it
    /// same as JSON(nsurl:NSURL)
    public class func fromNSURL(nsurl:NSURL) -> JSON {
        return JSON(nsurl:nsurl)
    }
    /// constructs JSON object from the content of URL
    public convenience init(url:String) {
        if let nsurl = NSURL(string:url) as NSURL? {
            self.init(nsurl:nsurl)
        } else {
            self.init(NSError(
                domain:"JSONErrorDomain",
                code:400,
                userInfo:[NSLocalizedDescriptionKey: "malformed URL"]
                )
            )
        }
    }
    /// fetch the JSON string from URL in the string
    public class func fromURL(url:String) -> JSON {
        return JSON(url:url)
    }
    /// does what JSON.stringify in ES5 does.
    /// when the 2nd argument is set to true it pretty prints
    public class func stringify(obj:AnyObject, pretty:Bool=false) -> String! {
        if !NSJSONSerialization.isValidJSONObject(obj) {
            return JSON(NSError(
                domain:"JSONErrorDomain",
                code:422,
                userInfo:[NSLocalizedDescriptionKey: "not an JSON object"]
                )).toString(pretty)
        }
        return JSON(obj).toString(pretty)
    }
}
/// instance properties
extension JSON {
    /// access the element like array
    public subscript(idx:Int) -> JSON {
        switch _value {
        case _ as NSError:
            return self
        case let ary as NSArray:
            if 0 <= idx && idx < ary.count {
                return JSON(ary[idx])
            }
            return JSON(NSError(
                domain:"JSONErrorDomain", code:404, userInfo:[
                    NSLocalizedDescriptionKey:
                    "[\(idx)] is out of range"
                ]))
        default:
            return JSON(NSError(
                domain:"JSONErrorDomain", code:500, userInfo:[
                    NSLocalizedDescriptionKey: "not an array"
                ]))
            }
    }
    /// access the element like dictionary
    public subscript(key:String)->JSON {
        switch _value {
        case _ as NSError:
            return self
        case let dic as NSDictionary:
            if let val:AnyObject = dic[key] { return JSON(val) }
            return JSON(NSError(
                domain:"JSONErrorDomain", code:404, userInfo:[
                    NSLocalizedDescriptionKey:
                    "[\"\(key)\"] not found"
                ]))
        default:
            return JSON(NSError(
                domain:"JSONErrorDomain", code:500, userInfo:[
                    NSLocalizedDescriptionKey: "not an object"
                ]))
            }
    }
    /// access json data object
    public var data:AnyObject? {
        return self.isError ? nil : self._value
    }
    /// Gives the type name as string.
    /// e.g.  if it returns "Double"
    ///       .asDouble returns Double
    public var type:String {
    switch _value {
    case is NSError:        return "NSError"
    case is NSNull:         return "NSNull"
    case let o as NSNumber:
        switch String.fromCString(o.objCType)! {
        case "c", "C":              return "Bool"
        case "q", "l", "i", "s":    return "Int"
        case "Q", "L", "I", "S":    return "UInt"
        default:                    return "Double"
        }
    case is NSString:               return "String"
    case is NSArray:                return "Array"
    case is NSDictionary:           return "Dictionary"
    default:                        return "NSError"
        }
    }
    /// check if self is NSError
    public var isError:      Bool { return _value is NSError }
    /// check if self is NSNull
    public var isNull:       Bool { return _value is NSNull }
    /// check if self is Bool
    public var isBool:       Bool { return type == "Bool" }
    /// check if self is Int
    public var isInt:        Bool { return type == "Int" }
    /// check if self is UInt
    public var isUInt:       Bool { return type == "UInt" }
    /// check if self is Double
    public var isDouble:     Bool { return type == "Double" }
    /// check if self is any type of number
    public var isNumber:     Bool {
    if let o = _value as? NSNumber {
        let t = String.fromCString(o.objCType)!
        return  t != "c" && t != "C"
    }
    return false
    }
    /// check if self is String
    public var isString:     Bool { return _value is NSString }
    /// check if self is Array
    public var isArray:      Bool { return _value is NSArray }
    /// check if self is Dictionary
    public var isDictionary: Bool { return _value is NSDictionary }
    /// check if self is a valid leaf node.
    public var isLeaf:       Bool {
        return !(isArray || isDictionary || isError)
    }
    /// gives NSError if it holds the error. nil otherwise
    public var asError:NSError? {
    return _value as? NSError
    }
    /// gives NSNull if self holds it. nil otherwise
    public var asNull:NSNull? {
    return _value is NSNull ? JSON.null : nil
    }
    /// gives Bool if self holds it. nil otherwise
    public var asBool:Bool? {
    switch _value {
    case let o as NSNumber:
        switch String.fromCString(o.objCType)! {
        case "c", "C":  return Bool(o.boolValue)
        default:
            return nil
        }
    default: return nil
        }
    }
    /// gives Int if self holds it. nil otherwise
    public var asInt:Int? {
    switch _value {
    case let o as NSNumber:
        switch String.fromCString(o.objCType)! {
        case "c", "C":
            return nil
        default:
            return Int(o.longLongValue)
        }
    default: return nil
        }
    }
    /// gives Int32 if self holds it. nil otherwise
    public var asInt32:Int32? {
    switch _value {
    case let o as NSNumber:
        switch String.fromCString(o.objCType)! {
        case "c", "C":
            return nil
        default:
            return Int32(o.longLongValue)
        }
    default: return nil
        }
    }
    /// gives Int64 if self holds it. nil otherwise
    public var asInt64:Int64? {
    switch _value {
    case let o as NSNumber:
        switch String.fromCString(o.objCType)! {
        case "c", "C":
            return nil
        default:
            return Int64(o.longLongValue)
        }
    default: return nil
        }
    }
    /// gives Float if self holds it. nil otherwise
    public var asFloat:Float? {
    switch _value {
    case let o as NSNumber:
        switch String.fromCString(o.objCType)! {
        case "c", "C":
            return nil
        default:
            return Float(o.floatValue)
        }
    default: return nil
        }
    }
    /// gives Double if self holds it. nil otherwise
    public var asDouble:Double? {
    switch _value {
    case let o as NSNumber:
        switch String.fromCString(o.objCType)! {
        case "c", "C":
            return nil
        default:
            return Double(o.doubleValue)
        }
    default: return nil
        }
    }
    // an alias to asDouble
    public var asNumber:Double? { return asDouble }
    /// gives String if self holds it. nil otherwise
    public var asString:String? {
    switch _value {
    case let o as NSString:
        return o as String
    default: return nil
        }
    }
    /// if self holds NSArray, gives a [JSON]
    /// with elements therein. nil otherwise
    public var asArray:[JSON]? {
    switch _value {
    case let o as NSArray:
        var result = [JSON]()
        for v:AnyObject in o { result.append(JSON(v)) }
        return result
    default:
        return nil
        }
    }
    /// if self holds NSDictionary, gives a [String:JSON]
    /// with elements therein. nil otherwise
    public var asDictionary:[String:JSON]? {
    switch _value {
    case let o as NSDictionary:
        var result = [String:JSON]()
        for (ko, v) in o {
            if let k = ko as? String {
                result[k] = JSON(v)
            }
        }
        return result
    default: return nil
        }
    }
    /// Yields date from string
    public var asDate:NSDate? {
        if let dateString = _value as? String {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
            return dateFormatter.dateFromString(dateString)
        }
        return nil
    }
    /// gives the number of elements if an array or a dictionary.
    /// you can use this to check if you can iterate.
    public var length:Int {
    switch _value {
    case let o as NSArray:      return o.count
    case let o as NSDictionary: return o.count
    default: return 0
        }
    }
    // gives all values content in JSON object.
    public var allValues:JSON{
        if(self._value.allValues == nil) {
            return JSON([])
        }
        return JSON(self._value.allValues)
    }
    // gives all keys content in JSON object.
    public var allKeys:JSON{
        if(self._value.allKeys == nil) {
            return JSON([])
        }
        return JSON(self._value.allKeys)
    }
}

extension JSON : SequenceType {
    public func generate()->AnyGenerator<(AnyObject,JSON)?> {
        switch _value {
        case let o as NSArray:
            var i = -1
            return anyGenerator() {
                if ++i == o.count { return nil }
                return (i, JSON(o[i]))
            }
        case let o as NSDictionary:
            let ks = o.allKeys.reverse()
            return anyGenerator() {
                if ks.isEmpty { return nil }
                if let k = ks.last as? String {
                    return (k, JSON(o.valueForKey(k)!))
                } else {
                    return nil
                }
            }
        default:
            return anyGenerator() { nil }
        }
    }
    public func mutableCopyOfTheObject() -> AnyObject {
        return _value.mutableCopy()
    }
}
extension JSON : CustomStringConvertible {
    /// stringifies self.
    /// if pretty:true it pretty prints
    public func toString(pretty:Bool=false)->String {
        switch _value {
        case is NSError: return "\(_value)"
        case is NSNull: return "null"
        case let o as NSNumber:
            switch String.fromCString(o.objCType)! {
            case "c", "C":
                return o.boolValue.description
            case "q", "l", "i", "s":
                return o.longLongValue.description
            case "Q", "L", "I", "S":
                return o.unsignedLongLongValue.description
            default:
                switch o.doubleValue {
                case 0.0/0.0:   return "0.0/0.0"    // NaN
                case -1.0/0.0:  return "-1.0/0.0"   // -infinity
                case +1.0/0.0:  return "+1.0/0.0"   //  infinity
                default:
                    return o.doubleValue.description
                }
            }
        case let o as NSString:
            return o.debugDescription
        default:
            let opts: NSJSONWritingOptions = pretty
                ? NSJSONWritingOptions.PrettyPrinted : []
            if let data = try! NSJSONSerialization.dataWithJSONObject(
                _value, options:opts
                ) as NSData? {
                    if let result = NSString(
                        data:data, encoding:NSUTF8StringEncoding
                        ) as? String {
                            return result
                    }
            }
            return "YOU ARE NOT SUPPOSED TO SEE THIS!"
        }
    }
    public var description:String { return toString() }
}
