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

#import <OCMock/OCMock.h>

#import "Additions/NSObject+GREYAdditions.h"
#import <EarlGrey/GREYElementHierarchy.h>
#import "GREYBaseTest.h"
#import "GREYExposedForTesting.h"
#import "GREYUTAccessibilityViewContainerView.h"
#import "GREYUTCustomAccessibilityView.h"

@interface GREYElementHierarchyTest : GREYBaseTest

@end

@implementation GREYElementHierarchyTest

- (void)testHierarchyStringWithNilView {
  UIView *view = nil;
  XCTAssertThrows([GREYElementHierarchy hierarchyStringForElement:view]);
}

- (void)testHierarchyStringWithValidHierarchy {
  UIView *viewB = [[UIView alloc] initWithFrame:kTestRect];
  UIView *viewC = [[UIView alloc] initWithFrame:kTestRect];
  UIView *viewD = [[UIView alloc] initWithFrame:kTestRect];
  UIView *viewE = [[UIView alloc] initWithFrame:kTestRect];
  UIView *viewF = [[UIView alloc] initWithFrame:kTestRect];
  UIView *viewG = [[UIView alloc] initWithFrame:kTestRect];
  GREYUTCustomAccessibilityView *viewA =
      [[GREYUTCustomAccessibilityView alloc] initWithObjects:@[ viewD, viewE ]];
  [viewA addSubview:viewB];
  [viewA addSubview:viewC];
  [viewB addSubview:viewF];
  [viewE addSubview:viewG];

  NSString *stringHierarchy = [GREYElementHierarchy hierarchyStringForElement:viewA];
  NSArray *stringTargetHierarchy = @[ @"<GREYUTCustomAccessibilityView:",
                                        @"  |--<UIView:",
                                        @"  |  |--<UIView:" ];
  [self grey_assertString:stringHierarchy containsStringsInArray:stringTargetHierarchy];
}

- (void)testHierarchyStringWithSingleView {
  UIView *viewA = [[UIView alloc] initWithFrame:kTestRect];
  NSString *stringHierarchy = [GREYElementHierarchy hierarchyStringForElement:viewA];
  NSArray *stringTargetHierarchy = @[ @"<UIView:" ];
  [self grey_assertString:stringHierarchy containsStringsInArray:stringTargetHierarchy];
}

- (void)testHierarchyStringWithSubviews {
  UIView *viewA = [[UIView alloc] initWithFrame:kTestRect];
  UIView *viewB = [[UIView alloc] initWithFrame:kTestRect];
  UIView *viewC = [[UIView alloc] initWithFrame:kTestRect];
  UIView *viewD = [[UIView alloc] initWithFrame:kTestRect];
  [viewA addSubview:viewB];
  [viewA addSubview:viewC];
  [viewA addSubview:viewD];
  NSString *stringHierarchy = [GREYElementHierarchy hierarchyStringForElement:viewA];
  NSArray *stringTargetHierarchy = @[ @"<UIView:",
                                        @"  |--<UIView:"];
  [self grey_assertString:stringHierarchy containsStringsInArray:stringTargetHierarchy];
}

- (void)testHierarchyStringWithAccessibilityViews {
  UIView *viewB = [[UIView alloc] initWithFrame:kTestRect];
  UIView *viewC = [[UIView alloc] initWithFrame:kTestRect];
  UIView *viewD = [[UIView alloc] initWithFrame:kTestRect];
  GREYUTCustomAccessibilityView *viewA = [[GREYUTCustomAccessibilityView alloc]
                                        initWithObjects:@[ viewB, viewC, viewD ]];
  NSString *stringHierarchy = [GREYElementHierarchy hierarchyStringForElement:viewA];
  NSArray *stringTargetHierarchy = @[ @"<GREYUTCustomAccessibilityView:",
                                        @"  |--<UIView:"];
  [self grey_assertString:stringHierarchy containsStringsInArray:stringTargetHierarchy];
}

- (void)testStringForCascadingHierarchyWithBothSubviewsandAXViews {
  UIView *viewB = [[UIView alloc] initWithFrame:kTestRect];
  UIView *viewD = [[UIView alloc] initWithFrame:kTestRect];
  GREYUTCustomAccessibilityView *viewC =
      [[GREYUTCustomAccessibilityView alloc] initWithObjects:@[ viewD ]];
  GREYUTCustomAccessibilityView *viewA =
      [[GREYUTCustomAccessibilityView alloc] initWithObjects:@[ viewB ]];
  [viewB addSubview:viewC];
  NSString *stringHierarchy = [GREYElementHierarchy hierarchyStringForElement:viewA];
  NSArray *stringTargetHierarchy = @[ @"<GREYUTCustomAccessibilityView:",
                                        @"  |--<UIView:",
                                        @"  |  |--<GREYUTCustomAccessibilityView:",
                                        @"  |  |  |--<UIView:" ];
  [self grey_assertString:stringHierarchy containsStringsInArray:stringTargetHierarchy];
}

- (void)testPrintingOfDescriptionAtLevelZero {
  UIView *viewA = [[UIView alloc] initWithFrame:kTestRect];
  NSString *targetString = @"<UIView:";
  NSString *printSubstring = [GREYElementHierarchy grey_printDescriptionForElement:viewA
                                                                           atLevel:0];
  XCTAssert([[printSubstring substringToIndex:[targetString length]] isEqualToString:targetString]);
}

- (void)testPrintingOfDescriptionAtLevelOne {
  UIView *viewA = [[UIView alloc] initWithFrame:kTestRect];
  NSString *targetString = @"  |--<UIView:";
  NSString *printSubstring = [GREYElementHierarchy grey_printDescriptionForElement:viewA
                                                                           atLevel:1];
  XCTAssert([[printSubstring substringToIndex:[targetString length]] isEqualToString:targetString]);
}

- (void)testPrintingOfDescriptionAtLevelTwo {
  UIView *viewA = [[UIView alloc] initWithFrame:kTestRect];
  NSString *targetString = @"  |  |--<UIView:";
  NSString *printSubstring = [GREYElementHierarchy grey_printDescriptionForElement:viewA
                                                                           atLevel:2];
  XCTAssert([[printSubstring substringToIndex:[targetString length]] isEqualToString:targetString]);
}

- (void)testAnnotationsForNilDictionary {
  UIView *viewA = [[UIView alloc] initWithFrame:kTestRect];
  NSString *stringHierarchy = [GREYElementHierarchy hierarchyStringForElement:viewA
                                                     withAnnotationDictionary:nil];
  XCTAssertNotNil(stringHierarchy);
}

- (void)testAnnotationsForSingleView {
  UIView *viewA = [[UIView alloc] initWithFrame:kTestRect];
  NSString *viewAAnnotation = @"This is a UIView";
  NSDictionary *annotations = @{[NSValue valueWithNonretainedObject:viewA] : viewAAnnotation};
  NSString *stringHierarchy = [GREYElementHierarchy hierarchyStringForElement:viewA
                                                     withAnnotationDictionary:annotations];
  XCTAssertTrue([stringHierarchy rangeOfString:viewAAnnotation].location != NSNotFound);
}

- (void)testAnnotationsForSingleAXView {
  GREYUTCustomAccessibilityView *viewA =
      [[GREYUTCustomAccessibilityView alloc] initWithObjects:@[]];
  NSString *viewAAnnotation = @"This is a Custom AX View";
  NSDictionary *annotations = @{[NSValue valueWithNonretainedObject:viewA] : viewAAnnotation};
  NSString *stringHierarchy = [GREYElementHierarchy hierarchyStringForElement:viewA
                                                     withAnnotationDictionary:annotations];
  XCTAssertTrue([stringHierarchy rangeOfString:viewAAnnotation].location != NSNotFound);
}

- (void)testAnnotationsForMultipleViews {
  UIView *viewB = [[UIView alloc] initWithFrame:kTestRect];
  UIView *viewC = [[UIView alloc] initWithFrame:kTestRect];
  UIView *viewD = [[UIView alloc] initWithFrame:kTestRect];
  GREYUTCustomAccessibilityView *viewA =
      [[GREYUTCustomAccessibilityView alloc] initWithObjects:@[ viewB, viewC ]];
  [viewC addSubview:viewD];
  NSString *viewAAnnotation = @"This is the root AX |view| A";
  NSString *viewBAnnotation = @"This is a child of A called B";
  NSString *viewCAnnotation = @"This is a child of A called C";
  NSString *viewDAnnotation = @"This is a child of C called D";

  NSDictionary *annotations = @{ [NSValue valueWithNonretainedObject:viewA] : viewAAnnotation,
                                 [NSValue valueWithNonretainedObject:viewB] : viewBAnnotation,
                                 [NSValue valueWithNonretainedObject:viewC] : viewCAnnotation,
                                 [NSValue valueWithNonretainedObject:viewD] : viewDAnnotation };
  NSString *stringHierarchy = [GREYElementHierarchy hierarchyStringForElement:viewA
                                                     withAnnotationDictionary:annotations];
  [self grey_assertString:stringHierarchy containsStringsInArray:[annotations allValues]];
}

- (void)testHierarchyStringForANilAnnotationDictionary {

  UIView *view = [[UIView alloc] initWithFrame:kTestRect];

  NSString *test =
  [GREYElementHierarchy grey_hierarchyString:view
                                outputString:[[NSMutableString alloc] init]
                     andAnnotationDictionary:nil];
  XCTAssertNotNil(test);
}

- (void)testHierarchyStringForSingleAccessibilityElement {
  UIView *viewA = [[UIView alloc] initWithFrame:kTestRect];
  UIAccessibilityElement *element =
      [[UIAccessibilityElement alloc] initWithAccessibilityContainer:viewA];
  NSString *accessibilityIdentifier = @"AxElement";
  element.accessibilityIdentifier = accessibilityIdentifier;
  NSString *stringHierarchy = [GREYElementHierarchy hierarchyStringForElement:element
                                                     withAnnotationDictionary:nil];
  XCTAssert([stringHierarchy rangeOfString:@"<UIAccessibilityElement:"].length != NSNotFound);
  NSString *targetString =
      [NSString stringWithFormat:@"<UIAccessibilityElement:%p; AX=Y; AX.id='AxElement'; "
                                 @"AX.frame={{0, 0}, {0, 0}}; AX.activationPoint={0, 0}; "
                                 @"AX.traits='UIAccessibilityTraitNone'; AX.focused='N'>",
                                 element];
  XCTAssertEqualObjects(targetString, stringHierarchy);
}

- (void)testHierarchyStringForViewWithAccessibilityElement {
  UIView *viewA = [[UIView alloc] initWithFrame:kTestRect];
  GREYUTCustomAccessibilityView *viewB =
      [[GREYUTCustomAccessibilityView alloc] initWithFrame:kTestRect];
  UIAccessibilityElement *element =
      [[UIAccessibilityElement alloc] initWithAccessibilityContainer:viewB];
  element.isAccessibilityElement = YES;

  [viewA addSubview:viewB];
  viewB.accessibleElements = @[ element ];

  NSString *stringHierarchy = [GREYElementHierarchy hierarchyStringForElement:viewA
                                                     withAnnotationDictionary:nil];

  NSArray *stringTargetHierarchy = @[ @"<UIView:",
                                        @"  |--<GREYUTCustomAccessibilityView:",
                                        @"  |--<UIAccessibilityElement:" ];
  [self grey_assertString:stringHierarchy containsStringsInArray:stringTargetHierarchy];
}

- (void)testHierarchyStringForViewWithAccessibilityElementsAndSubviews {
  UIView *viewForElementA = [[UIView alloc] initWithFrame:kTestRect];
  UIView *viewForElementB = [[UIView alloc] initWithFrame:kTestRect];
  UIAccessibilityElement *elementA =
      [[UIAccessibilityElement alloc] initWithAccessibilityContainer:viewForElementA];
  UIAccessibilityElement *elementB =
      [[UIAccessibilityElement alloc] initWithAccessibilityContainer:viewForElementB];
  UIView *viewA = [[UIView alloc] initWithFrame:kTestRect];
  GREYUTCustomAccessibilityView *viewB =
      [[GREYUTCustomAccessibilityView alloc] initWithObjects:@[ elementA ]];
  GREYUTCustomAccessibilityView *viewC =
      [[GREYUTCustomAccessibilityView alloc] initWithObjects:@[ elementB ]];
  UIView *viewD = [[UIView alloc] initWithFrame:kTestRect];
  [viewA addSubview:viewB];
  [viewA addSubview:viewC];
  [viewC addSubview:viewD];

  NSString *stringHierarchy = [GREYElementHierarchy hierarchyStringForElement:viewA
                                                     withAnnotationDictionary:nil];
  NSArray *stringTargetHierarchy = @[ @"<UIView:",
                                        @"  |--<UIView:",
                                        @"  |--<GREYUTCustomAccessibilityView:",
                                        @"  |  |--<UIAccessibilityElement:" ];
  [self grey_assertString:stringHierarchy containsStringsInArray:stringTargetHierarchy];
}

- (void)testHierarchyStringForViewWithCascadingAXElements {
  UIView *viewForElementA = [[UIView alloc] initWithFrame:kTestRect];
  UIView *viewForElementB = [[UIView alloc] initWithFrame:kTestRect];
  UIView *viewForElementC = [[UIView alloc] initWithFrame:kTestRect];
  UIAccessibilityElement *elementA =
      [[UIAccessibilityElement alloc] initWithAccessibilityContainer:viewForElementA];
  UIAccessibilityElement *elementB =
      [[UIAccessibilityElement alloc] initWithAccessibilityContainer:viewForElementB];
  UIAccessibilityElement *elementC =
      [[UIAccessibilityElement alloc] initWithAccessibilityContainer:viewForElementC];

  GREYUTCustomAccessibilityView *viewC =
      [[GREYUTCustomAccessibilityView alloc] initWithObjects:@[ elementC ]];
  GREYUTCustomAccessibilityView *viewB =
      [[GREYUTCustomAccessibilityView alloc] initWithObjects:@[ viewC, elementB ]];
  GREYUTCustomAccessibilityView *viewA =
      [[GREYUTCustomAccessibilityView alloc] initWithObjects:@[ viewB, elementA ]];

  NSString *stringHierarchy = [GREYElementHierarchy hierarchyStringForElement:viewA
                                                     withAnnotationDictionary:nil];
  NSArray *stringTargetHierarchy = @[ @"<GREYUTCustomAccessibilityView:",
                                        @"<UIAccessibilityElement:",
                                        @"  |--<GREYUTCustomAccessibilityView:",
                                        @"  |--<UIAccessibilityElement:",
                                        @"  |  |--<GREYUTCustomAccessibilityView:",
                                        @"  |  |--<UIAccessibilityElement:" ];
  [self grey_assertString:stringHierarchy containsStringsInArray:stringTargetHierarchy];
}

- (void)testHierarchyStringForAXViewWithAnnotations {
  UIView *viewForElementA = [[UIView alloc] initWithFrame:kTestRect];
  UIAccessibilityElement *elementA =
      [[UIAccessibilityElement alloc] initWithAccessibilityContainer:viewForElementA];
  NSString *elementAAnnotation = @"This is Accessibility Element A";
  NSDictionary *annotations =
      @{ [NSValue valueWithNonretainedObject:elementA]:elementAAnnotation };
  NSString *stringHierarchy = [GREYElementHierarchy hierarchyStringForElement:elementA
                                                     withAnnotationDictionary:annotations];
  NSString *targetString =
      [NSString stringWithFormat:@"<UIAccessibilityElement:%p; AX=Y; "
                                 @"AX.frame={{0, 0}, {0, 0}}; AX.activationPoint={0, 0}; "
                                 @"AX.traits='UIAccessibilityTraitNone'; AX.focused='N'> "
                                 @"This is Accessibility Element A", elementA];
  XCTAssertEqualObjects(targetString, stringHierarchy);

}

- (void)testDumpUIHierarchyForWindow {
  UIWindow *window = [[UIWindow alloc] init];
  UIView *view = [[UIView alloc] init];
  UIImageView *imageView = [[UIImageView alloc] init];
  [view addSubview:imageView];
  [window addSubview:view];
  NSString *uiHierarchy = [GREYElementHierarchy hierarchyStringForElement:window];
  NSString *uiViewCustomPrefix = [NSString stringWithFormat:@"<UIView:%p; AX=N;", view];
  NSString *imgViewCustomPrefix = [NSString stringWithFormat:@"<UIImageView:%p; AX=N;", imageView];

  XCTAssertNotEqual([uiHierarchy rangeOfString:uiViewCustomPrefix].location,
                    (NSUInteger)NSNotFound);
  XCTAssertNotEqual([uiHierarchy rangeOfString:imgViewCustomPrefix].location,
                    (NSUInteger)NSNotFound);
}

- (void)testHierarchyStringForNSObjectCategory {
  UIView *viewForElementA = [[UIView alloc] initWithFrame:kTestRect];
  UIView *viewForElementB = [[UIView alloc] initWithFrame:kTestRect];
  UIView *viewForElementC = [[UIView alloc] initWithFrame:kTestRect];
  UIAccessibilityElement *elementA =
      [[UIAccessibilityElement alloc] initWithAccessibilityContainer:viewForElementA];
  UIAccessibilityElement *elementB =
      [[UIAccessibilityElement alloc] initWithAccessibilityContainer:viewForElementB];
  UIAccessibilityElement *elementC =
      [[UIAccessibilityElement alloc] initWithAccessibilityContainer:viewForElementC];

  GREYUTCustomAccessibilityView *viewC =
      [[GREYUTCustomAccessibilityView alloc] initWithObjects:@[ elementC ]];
  GREYUTCustomAccessibilityView *viewB =
      [[GREYUTCustomAccessibilityView alloc] initWithObjects:@[ viewC, elementB ]];
  GREYUTCustomAccessibilityView *viewA =
      [[GREYUTCustomAccessibilityView alloc] initWithObjects:@[ viewB, elementA ]];

  NSString *hierarchyForViewA = [viewA grey_recursiveDescription];
  NSArray *stringTargetHierarchy = @[ @"<GREYUTCustomAccessibilityView:",
                                      @"<UIAccessibilityElement:",
                                      @"  |--<GREYUTCustomAccessibilityView:",
                                      @"  |--<UIAccessibilityElement:",
                                      @"  |  |--<GREYUTCustomAccessibilityView:",
                                      @"  |  |--<UIAccessibilityElement:" ];
  [self grey_assertString:hierarchyForViewA containsStringsInArray:stringTargetHierarchy];

  NSString *hierarchyForSingleAxElement = [elementC grey_recursiveDescription];
  stringTargetHierarchy = @[ @"<UIAccessibilityElement:" ];
  [self grey_assertString:hierarchyForSingleAxElement containsStringsInArray:stringTargetHierarchy];

  NSString *hierarchyForSingleView = [viewForElementA grey_recursiveDescription];
  stringTargetHierarchy = @[ @"<UIView:" ];
  [self grey_assertString:hierarchyForSingleView containsStringsInArray:stringTargetHierarchy];

  NSString *hierarchyForViewWithContainer = [viewC grey_recursiveDescription];
  stringTargetHierarchy = @[ @"<GREYUTCustomAccessibilityView:",
                             @"  |--<UIAccessibilityElement:" ];
  [self grey_assertString:hierarchyForViewWithContainer
      containsStringsInArray:stringTargetHierarchy];

  NSString *hierarchyForContainerWithView = [elementA grey_recursiveDescription];
  stringTargetHierarchy = @[ @"<UIAccessibilityElement:" ];
  for (NSString *targetString in stringTargetHierarchy) {
    XCTAssertNotEqual([hierarchyForContainerWithView rangeOfString:targetString].location,
                      (NSUInteger)NSNotFound);
  }
  [self grey_assertString:hierarchyForContainerWithView
      containsStringsInArray:stringTargetHierarchy];
}

- (void)testHierarchyForInstantiatedNSObject {
  NSObject *object = [[NSObject alloc] init];
  NSString *hierarchyForNSObject = [object grey_recursiveDescription];
  NSString *stringTargetHierarchy = @"<NSObject:";
  XCTAssertNotEqual([hierarchyForNSObject rangeOfString:stringTargetHierarchy].location,
                    (NSUInteger)NSNotFound);
}

- (void)testTraversalDoesNotVisitSameElementTwice {
  UIView *child = [[UIView alloc] init];
  GREYUTAccessibilityViewContainerView *view =
      [[GREYUTAccessibilityViewContainerView alloc] initWithElements:@[child]];
  // The same view @c child has been added as a subview and as an accessibility element.
  [view addSubview:child];

  NSArray *stringTargetHierarchy = @[ @"<GREYUTAccessibilityViewContainerView:",
                                      @"  |--<UIView:"];
  NSString *hierarchyForView = [view grey_recursiveDescription];
  NSUInteger count = ((NSArray *)[hierarchyForView componentsSeparatedByString:@"\n"]).count;

  // Make sure that two views were printed, instead of 3 views.
  XCTAssertEqual(count, stringTargetHierarchy.count);
}

# pragma mark - Private

- (void)grey_assertString:(NSString *)hierarchyString
   containsStringsInArray:(NSArray<NSString *> *)targetHierarchy {
  for (NSString *targetString in targetHierarchy) {
    XCTAssert([hierarchyString rangeOfString:targetString].location != NSNotFound);
  }
}

@end
