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

#import <EarlGrey/GREYElementMatcherBlock.h>
#import "GREYBaseTest.h"

@interface GREYElementMatcherBlockTest : GREYBaseTest

// Always passing matchers.
@property(nonatomic, strong) GREYElementMatcherBlock *pass1;
@property(nonatomic, strong) GREYElementMatcherBlock *pass2;

// Always failing matchers.
@property(nonatomic, strong) GREYElementMatcherBlock *fail1;
@property(nonatomic, strong) GREYElementMatcherBlock *fail2;
@end

@implementation GREYElementMatcherBlockTest

- (void)setUp {
  [super setUp];
  BOOL (^yesMatcher)(id) = ^BOOL(id element) {
    return YES;
  };
  BOOL (^noMatcher)(id) = ^BOOL(id element) {
    return NO;
  };

  void (^pass1Description)(id<GREYDescription>) = ^(id<GREYDescription> description) {
    [description appendText:@"pass1"];
  };
  void (^pass2Description)(id<GREYDescription>) = ^(id<GREYDescription> description) {
    [description appendText:@"pass2"];
  };
  void (^fail1Description)(id<GREYDescription>) = ^(id<GREYDescription> description) {
    [description appendText:@"fail2"];
  };
  void (^fail2Description)(id<GREYDescription>) = ^(id<GREYDescription> description) {
    [description appendText:@"fail2"];
  };

  // Create matchers that always pass.
  self.pass1 = [GREYElementMatcherBlock matcherWithMatchesBlock:yesMatcher
                                               descriptionBlock:pass1Description];
  self.pass2 = [GREYElementMatcherBlock matcherWithMatchesBlock:yesMatcher
                                               descriptionBlock:pass2Description];

  // Create matchers that always fail.
  self.fail1 = [GREYElementMatcherBlock matcherWithMatchesBlock:noMatcher
                                               descriptionBlock:fail1Description];
  self.fail2 = [GREYElementMatcherBlock matcherWithMatchesBlock:noMatcher
                                               descriptionBlock:fail2Description];

}

- (void)testMatcherDescription {
  id<GREYMatcher> matcher = self.pass1;
  XCTAssertEqualObjects([matcher description], @"pass1", @"Descriptions do not match");
  [matcher matches:nil];
  XCTAssertEqualObjects([matcher description], @"pass1", @"Descriptions do not match");
}

- (void)testDescriptionOfAllOfMatcher {
  id<GREYMatcher> matcher = grey_allOf(self.pass1, self.pass2, nil);
  XCTAssertEqualObjects([matcher description], @"(pass1 && pass2)");
}

- (void)testDescriptionOfAnyOfMatcher {
  id<GREYMatcher> matcher = grey_anyOf(self.pass1, self.pass2, nil);
  XCTAssertEqualObjects([matcher description], @"(pass1 || pass2)");
}

- (void)testDescriptionOfCombinationMatcher {
  id<GREYMatcher> matcher = grey_allOf(self.pass1, grey_anyOf(self.pass1, self.pass2, nil), nil);
  XCTAssertEqualObjects([matcher description], @"(pass1 && (pass1 || pass2))");
}

@end
