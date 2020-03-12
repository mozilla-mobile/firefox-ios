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

#import "Common/GREYElementHierarchy.h"

#import "Additions/NSObject+GREYAdditions.h"
#import "Common/GREYConstants.h"
#import "Common/GREYFatalAsserts.h"
#import "Common/GREYThrowDefines.h"
#import "Provider/GREYUIWindowProvider.h"
#import "Traversal/GREYTraversalDFS.h"

@implementation GREYElementHierarchy

+ (NSString *)hierarchyStringForElement:(id)element {
  GREYThrowOnNilParameter(element);
  return [self grey_hierarchyString:element
                       outputString:[[NSMutableString alloc] init]
            andAnnotationDictionary:nil];
}

+ (NSString *)hierarchyStringForElement:(id)element
               withAnnotationDictionary:(NSDictionary *)annotationDictionary {
  GREYThrowOnNilParameter(element);
  return [self grey_hierarchyString:element
                       outputString:[[NSMutableString alloc] init]
            andAnnotationDictionary:annotationDictionary];
}

+ (NSString *)hierarchyStringForAllUIWindows {
  NSMutableString *log = [[NSMutableString alloc] init];
  long unsigned index = 0;
  for (UIWindow *window in [GREYUIWindowProvider allWindows]) {
    if (index != 0) {
      [log appendString:@"\n\n"];
    }
    index++;
    [log appendFormat:@"========== Window %lu ==========\n\n%@",
                      index,
                      [GREYElementHierarchy hierarchyStringForElement:window]];
  }
  return log;
}

#pragma mark - Private

/**
 *  Recursively prints the hierarchy from the given UI @c element along with any annotations in
 *  the @c annotationDictionary into the given @c outputString.
 *
 *  @param element The UI element to be printed.
 *  @param outputString A mutable string that receives the output.
 *  @param annotationDictionary The annotations to be applied.
 *
 *  @return A string containing the full view hierarchy from the given @c element.
 */
+ (NSString *)grey_hierarchyString:(id)element
                      outputString:(NSMutableString *)outputString
           andAnnotationDictionary:(NSDictionary *)annotationDictionary {
  GREYFatalAssert(element);
  GREYFatalAssert(outputString);

  // Traverse the hierarchy associated with the element.
  GREYTraversalDFS *traversal = [GREYTraversalDFS hierarchyForElementWithDFSTraversal:element];

  // Enumerate the hierarchy using block enumeration.
  [traversal enumerateUsingBlock:^(id _Nonnull element, NSUInteger level) {
    if ([outputString length] != 0) {
      [outputString appendString:@"\n"];
    }
    [outputString appendString:[self grey_printDescriptionForElement:element
                                                             atLevel:level]];
    NSString *annotation = annotationDictionary[[NSValue valueWithNonretainedObject:element]];
    if (annotation) {
      [outputString appendString:@" "]; // Space before annotation.
      [outputString appendString:annotation];
    }
  }];
  return outputString;
}

/**
 *  Creates and outputs the description in the correct format for the @c element at a particular @c
 *  level (depth of the element in the view hierarchy).
 *
 *  @param element The element whose description is to be printed.
 *  @param level The depth of the element in the view hierarchy.
 *
 *  @return A string with the description of the given @c element.
 */
+ (NSString *)grey_printDescriptionForElement:(id)element atLevel:(NSUInteger)level {
  GREYFatalAssert(element);
  NSMutableString *printOutput = [NSMutableString stringWithString:@""];

  if (level > 0) {
    [printOutput appendString:@"  "];
    for (NSUInteger space = 0; space < level; space++) {
      if (space != level - 1) {
        [printOutput appendString:@"|  "];
      } else {
        [printOutput appendString:@"|--"];
      }
    }
  }
  [printOutput appendString:[element grey_description]];
  return printOutput;
}

@end
