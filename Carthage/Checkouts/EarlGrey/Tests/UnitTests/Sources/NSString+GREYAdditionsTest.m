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
#import "GREYBaseTest.h"

@interface NSString_GREYAdditionsTest : GREYBaseTest
@end

@implementation NSString_GREYAdditionsTest

- (void)testNilString {
  NSString *nilString;
  XCTAssertFalse([nilString grey_isNonEmptyAfterTrimming]);
}

- (void)testStringOfZeroLength {
  NSString *zeroLengthString = @"";
  XCTAssertFalse([zeroLengthString grey_isNonEmptyAfterTrimming]);
}

- (void)testStringWithWhiteSpacesAndNewLine {
  NSString *whiteSpaceAndNewLineString = @"  \n  \n \n";
  XCTAssertFalse([whiteSpaceAndNewLineString grey_isNonEmptyAfterTrimming]);

  // new line only.
  NSString *newLineOnlyString = @"\n";
  XCTAssertFalse([newLineOnlyString grey_isNonEmptyAfterTrimming]);

  // white space only.
  NSString *whiteSpaceOnlyString = @" ";
  XCTAssertFalse([whiteSpaceOnlyString grey_isNonEmptyAfterTrimming]);
}

- (void)testNonEmptyStringWithCharacters {
  NSString *nonEmptyWithWhiteSpaces = @"a  ";
  XCTAssertTrue([nonEmptyWithWhiteSpaces grey_isNonEmptyAfterTrimming]);

  NSString *nonEmptyWithNewLine = @"a\n\n";
  XCTAssertTrue([nonEmptyWithNewLine grey_isNonEmptyAfterTrimming]);

  NSString *nonEmptyWithNewLineAndWhiteSpaces = @"a\n\n  \n";
  XCTAssertTrue([nonEmptyWithNewLineAndWhiteSpaces grey_isNonEmptyAfterTrimming]);
}

- (void)testNonEmtyWithoutWhiteSpaces {
  NSString *nonEmptyWithoutWhiteSpaces = @"a";
  XCTAssertTrue([nonEmptyWithoutWhiteSpaces grey_isNonEmptyAfterTrimming]);
}

- (void)testmd5WithStringProducesDifferentResultsForDifferentStrings {
  XCTAssertNotEqualObjects([@"foo" grey_md5String], [@"bar" grey_md5String]);
}
- (void)testmd5WithStringProducesSameResultsForSameStrings {
  XCTAssertEqualObjects([@"foo" grey_md5String], [@"foo" grey_md5String]);
}

- (void)testmd5WithStringIsCorrect {
  // Use this command to generate md5 from OSX command line and cross verify:
  // md5 -s "The quick brown fox jumps over the lazy dog"
  XCTAssertEqualObjects([@"The quick brown fox jumps over the lazy dog" grey_md5String],
                        @"9e107d9d372bb6826bd81d3542a419d6");
}

- (void)testmd5WithStringForEmptyString {
  XCTAssertGreaterThan([[@"" grey_md5String] length], (NSUInteger)0);
}

@end
