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

#import "Additions/NSString+GREYAdditions.h"

#import <CommonCrypto/CommonDigest.h>

@implementation NSString (GREYAdditions)

- (BOOL)grey_isNonEmptyAfterTrimming {
  NSString *trimmed =
      [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  return trimmed.length != 0;
}

- (NSString *)grey_md5String {
  // Get MD5 value of the given string.
  unsigned char md5Value[CC_MD5_DIGEST_LENGTH];
  const char *stringCPtr = [self UTF8String];
  CC_MD5(stringCPtr, (CC_LONG)strlen(stringCPtr), md5Value);

  // Parse MD5 value into individual hex values.
  NSMutableString *stringWithHexMd5Values = [[NSMutableString alloc] init];
  for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
    [stringWithHexMd5Values appendFormat:@"%02x", md5Value[i]];
  }

  return [stringWithHexMd5Values copy];
}

@end
