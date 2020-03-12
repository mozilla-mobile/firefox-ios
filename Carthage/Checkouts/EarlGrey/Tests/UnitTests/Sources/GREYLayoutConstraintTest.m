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

#import <EarlGrey/GREYConstants.h>
#import <EarlGrey/GREYLayoutConstraint.h>
#import "GREYBaseTest.h"

@interface GREYLayoutConstraintTest : GREYBaseTest

@end

@implementation GREYLayoutConstraintTest

- (void)testExactlyEqualConstraint {
  GREYLayoutConstraint *constraint =
      [GREYLayoutConstraint layoutConstraintWithAttribute:kGREYLayoutAttributeRight
                                                relatedBy:kGREYLayoutRelationEqual
                                     toReferenceAttribute:kGREYLayoutAttributeLeft
                                               multiplier:1.0
                                                 constant:0];
  UIView *element = [[UIView alloc] init];
  UIView *reference = [[UIView alloc] init];
  element.accessibilityFrame = CGRectMake(0, 0, 10, 10);

  reference.accessibilityFrame = CGRectMake(10, 0, 10, 10);
  XCTAssertTrue([constraint satisfiedByElement:element andReferenceElement:reference]);

  reference.accessibilityFrame = CGRectMake(11, 0, 10, 10);
  XCTAssertFalse([constraint satisfiedByElement:element andReferenceElement:reference]);
}

- (void)testRelationalConstraint {
  GREYLayoutConstraint *constraint =
      [GREYLayoutConstraint layoutConstraintForDirection:kGREYLayoutDirectionLeft
                                    andMinimumSeparation:5];
  UIView *element = [[UIView alloc] init];
  UIView *reference = [[UIView alloc] init];
  reference.accessibilityFrame = CGRectMake(10, 0, 10, 10);

  // Separation between element and reference: -5 (overlap)
  element.accessibilityFrame = CGRectMake(5, 0, 10, 10);
  XCTAssertFalse([constraint satisfiedByElement:element andReferenceElement:reference]);

  // Separation between element and reference: 0
  element.accessibilityFrame = CGRectMake(0, 0, 10, 10);
  XCTAssertFalse([constraint satisfiedByElement:element andReferenceElement:reference]);

  // Separation between element and reference: 4
  element.accessibilityFrame = CGRectMake(-4, 0, 10, 10);
  XCTAssertFalse([constraint satisfiedByElement:element andReferenceElement:reference]);

  // Separation between element and reference: 5
  element.accessibilityFrame = CGRectMake(-5, 0, 10, 10);
  XCTAssertTrue([constraint satisfiedByElement:element andReferenceElement:reference]);

  // Separation between element and reference: 6
  element.accessibilityFrame = CGRectMake(-6, 0, 10, 10);
  XCTAssertTrue([constraint satisfiedByElement:element andReferenceElement:reference]);
}

@end
