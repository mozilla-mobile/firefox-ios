//
// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "Common/GREYObjectFormatter.h"

#import "Additions/NSString+GREYAdditions.h"
#import "Common/GREYError.h"
#import "Common/GREYFatalAsserts.h"
#import "Common/GREYThrowDefines.h"
#import "Matcher/GREYStringDescription.h"

NSInteger const kGREYObjectFormatIndent = 2;

@implementation GREYObjectFormatter

+ (NSString *)formatArray:(NSArray *)array indent:(NSInteger)indent keyOrder:(NSArray *)keyOrder {
  return [self formatArray:array prefix:nil indent:indent keyOrder:keyOrder];
}

+ (NSString *)formatArray:(NSArray *)array
                   prefix:(NSString *)prefix
                   indent:(NSInteger)indent
                 keyOrder:(NSArray *)keyOrder {
  if (!array) {
    return @"";
  }

  if (!prefix) {
    prefix = @"";
  }

  NSMutableArray *formatted = [[NSMutableArray alloc] init];
  NSMutableString *indentString = [[NSMutableString alloc] init];

  // construct indent string
  for (NSInteger count = 0; count < indent; count++) {
    [indentString appendString:@" "];
  }

  for (id obj in array) {
    [formatted addObject:[GREYObjectFormatter grey_formatObject:obj
                                                   prefixString:YES
                                                         prefix:prefix
                                                         indent:indent
                                                       keyOrder:keyOrder]];
  }
  return [NSString stringWithFormat:@"%@[\n%@\n%@]",
                                    prefix,
                                    [formatted componentsJoinedByString:@",\n"],
                                    prefix];
}

+ (NSString *)formatDictionary:(NSDictionary *)dictionary
                        indent:(NSInteger)indent
                     hideEmpty:(BOOL)hideEmpty
                      keyOrder:(NSArray *)keyOrder {
  return [self formatDictionary:dictionary
                         prefix:nil
                         indent:indent
                      hideEmpty:hideEmpty
                       keyOrder:keyOrder];
}

+ (NSString *)formatDictionary:(NSDictionary *)dictionary
                        prefix:(NSString *)prefix
                        indent:(NSInteger)indent
                     hideEmpty:(BOOL)hideEmpty
                      keyOrder:(NSArray *)keyOrder {
  if (!dictionary) {
    return @"";
  }

  if (!prefix) {
    prefix = @"";
  }

  NSMutableArray *formatted = [[NSMutableArray alloc] init];
  NSMutableString *indentString = [[NSMutableString alloc] init];
  NSMutableDictionary *keySet = [[NSMutableDictionary alloc] init];

  // construct indent string
  for (NSInteger count = 0; count < indent; count++) {
    [indentString appendFormat:@" "];
  }

  // display dictionary key-values that are in the keyOrder
  for (NSString *key in keyOrder) {
    keySet[key] = @(YES);

    id value = dictionary[key];
    if (!value && hideEmpty) {
      continue;
    }

    NSString *formattedObject = [GREYObjectFormatter grey_formatObject:value
                                                          prefixString:NO
                                                                prefix:prefix
                                                                indent:indent
                                                              keyOrder:keyOrder];
    [formatted addObject:[NSString stringWithFormat:@"%@%@\"%@\":%@",
                                                    prefix,
                                                    indentString,
                                                    key,
                                                    formattedObject]];
  }

  // Display dictionary key-values that are not in the keyOrder
  for (NSString *key in [dictionary allKeys]) {
    if (keySet[key]) {
      continue;
    }

    NSString *formattedObject = [GREYObjectFormatter grey_formatObject:dictionary[key]
                                                          prefixString:NO
                                                                prefix:prefix
                                                                indent:indent
                                                              keyOrder:keyOrder];

    [formatted addObject:[NSString stringWithFormat:@"%@%@\"%@\":%@",
                                                    prefix,
                                                    indentString,
                                                    key,
                                                    formattedObject]];
  }

  return [NSString stringWithFormat:@"%@{\n%@\n%@}",
                                    prefix,
                                    [formatted componentsJoinedByString:@",\n"],
                                    prefix];
}

#pragma mark - Private

/**
 *  Serializes an object into JSON-like string.
 *  The supported objects are: NSString, NSNumber, NSArray, NSDictionary and GREYError.
 *
 *  @remark The serialized string is formatted as a JSON for presentation purposes but it doesn't
 *          have the right escaping applied for special character as it hinders readability.
 *
 *  @param object        The object to serialize.
 *  @param prefixString  Whether a prefix string should be applied to each newline
 *                       of the serialized dictionary.
 *  @param prefix        A string that will be applied to each newline
 *                       of the serialized dictionary.
 *  @param indent        Number of spaces that will be applied to each element
 *                       of the serialized dictionary.
 *
 *  @return Serialized string of the provided @c object.
 */

+ (NSString *)grey_formatObject:(id)object
                   prefixString:(BOOL)prefixString
                         prefix:(NSString *)prefix
                         indent:(NSInteger)indent
                       keyOrder:(NSArray *)keyOrder {
  NSMutableString *indentString = [[NSMutableString alloc] init];

  // construct indent string
  for (NSInteger count = 0; count < indent; count++) {
    [indentString appendString:@" "];
  }

  if ([object isKindOfClass:[NSString class]] ||
      [object isKindOfClass:[GREYStringDescription class]]) {
    NSString *objectString;
    if ([object isKindOfClass:[NSString class]]) {
      objectString = (NSString *)object;
    } else {
      objectString = [object description];
    }

    if (prefixString) {
      return [NSString stringWithFormat:@"%@%@\"%@\"",
                                        prefix,
                                        indentString,
                                        objectString];
    } else {
      return [NSString stringWithFormat:@"%@\"%@\"", indentString, objectString];
    }
  } else if ([object isKindOfClass:[NSNumber class]]) {
    return [object stringValue];
  } else if ([object isKindOfClass:[NSArray class]]) {
    NSString *prefixString = [NSString stringWithFormat:@"%@%@", prefix, indentString];
    return [GREYObjectFormatter formatArray:(NSArray *)object
                                     prefix:prefixString
                                     indent:indent
                                   keyOrder:keyOrder];
  } else if ([object isKindOfClass:[NSDictionary class]]) {
    NSString *prefixString = [NSString stringWithFormat:@"%@%@", prefix, indentString];
    return [GREYObjectFormatter formatDictionary:(NSDictionary *)object
                                          prefix:prefixString
                                          indent:indent
                                       hideEmpty:YES
                                        keyOrder:keyOrder];
  } else if ([object isKindOfClass:[GREYError class]]) {
    return [object description];
  } else {
    GREYThrow(@"Unhandled output type: %@", [object class]);
  }
  return nil;
}

@end
