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

#include <objc/runtime.h>

#import "Common/GREYSwizzler.h"
#import "GREYBaseTest.h"

#pragma mark - Class A (Superclass)

@interface GREYUTClassA : NSObject

- (NSString *)instanceMethod1;
- (NSString *)instanceMethod2;
- (NSString *)instanceMethod3;
+ (NSString *)classMethod1;
+ (NSString *)classMethod2;

@end

@implementation GREYUTClassA

- (NSString *)instanceMethod1 {
  return @"Class A Instance Method 1";
}

- (NSString *)instanceMethod2 {
  return @"Class A Instance Method 2";
}

- (NSString *)instanceMethod3 {
  return @"Class A Instance Method 3";
}

+ (NSString *)classMethod1 {
  return @"Class A Class Method 1";
}

+ (NSString *)classMethod2 {
  return @"Class A Class Method 2";
}

+ (NSString *)classMethod3 {
  return @"Class A Class Method 3";
}

+ (NSString *)classMethod4 {
  return @"Class A Class Method 4";
}

@end

#pragma mark - Class B

@interface GREYUTClassB : GREYUTClassA

@end

@implementation GREYUTClassB

@end

#pragma mark - Class C

@interface GREYUTClassC : GREYUTClassA

@end

@implementation GREYUTClassC

- (NSString *)instanceMethod1 {
  return @"Class C Instance Method 1";
}

@end

@interface GREYUTClassD : NSObject

+ (NSString *)classDClassMethod;
+ (NSString *)classDClassMethod1;
- (NSString *)classDInstanceMethod;
- (NSString *)classDInstanceMethod1;

@end

@implementation GREYUTClassD

+ (NSString *)classDClassMethod {
  return @"Class D Class Method";
}

+ (NSString *)classDClassMethod1 {
  return @"Class D Class Method 1";
}

- (NSString *)classDInstanceMethod {
  return @"Class D Instance Method";
}

- (NSString *)classDInstanceMethod1 {
  return @"Class D Instance Method 1";
}

@end

@interface GREYSwizzlerTest : GREYBaseTest
@end

@implementation GREYSwizzlerTest {
  GREYUTClassA *_objectA;
  GREYUTClassD *_objectD;
  GREYSwizzler *_swizzler;
}

- (void)setUp {
  [super setUp];
  _objectA = [[GREYUTClassA alloc] init];
  _objectD = [[GREYUTClassD alloc] init];
  _swizzler = [[GREYSwizzler alloc] init];
}

- (void)tearDown {
  [_swizzler resetAll];
  [super tearDown];
}

- (void)testSwizzleClassMethod {
  XCTAssertTrue([_swizzler swizzleClass:[GREYUTClassA class]
                     replaceClassMethod:@selector(classMethod1)
                             withMethod:@selector(classMethod2)],
                @"Swizzle should succeed");
  XCTAssertEqualObjects([GREYUTClassA classMethod1], @"Class A Class Method 2");
  XCTAssertEqualObjects([GREYUTClassA classMethod2], @"Class A Class Method 1");
  // Swizzle back
  XCTAssertTrue([_swizzler swizzleClass:[GREYUTClassA class]
                     replaceClassMethod:@selector(classMethod1)
                             withMethod:@selector(classMethod2)],
                @"Swizzle should succeed");
  XCTAssertEqualObjects([GREYUTClassA classMethod1], @"Class A Class Method 1");
  XCTAssertEqualObjects([GREYUTClassA classMethod2], @"Class A Class Method 2");
}

- (void)testSwizzleNotFoundMethod {
  // Swizzle class method
  XCTAssertFalse([_swizzler swizzleClass:[GREYUTClassA class]
                      replaceClassMethod:@selector(classMethod1)
                              withMethod:NSSelectorFromString(@"fakeClassMethod")]);
  XCTAssertEqualObjects([GREYUTClassA classMethod1], @"Class A Class Method 1");
  // Swizzle instance method
  XCTAssertFalse([_swizzler swizzleClass:[GREYUTClassA class]
                     replaceInstanceMethod:@selector(instanceMethod1)
                                withMethod:NSSelectorFromString(@"fakeMethod")]);
  XCTAssertEqualObjects([_objectA instanceMethod1], @"Class A Instance Method 1");
}

- (void)testSwizzleInstanceMethod {
  XCTAssertTrue([_swizzler swizzleClass:[GREYUTClassA class]
                    replaceInstanceMethod:@selector(instanceMethod1)
                               withMethod:@selector(instanceMethod2)],
                @"Swizzle should succeed");
  XCTAssertEqualObjects([_objectA instanceMethod1], @"Class A Instance Method 2");
  XCTAssertEqualObjects([_objectA instanceMethod2], @"Class A Instance Method 1");
  // Swizzle back

  XCTAssertTrue([_swizzler swizzleClass:[GREYUTClassA class]
                    replaceInstanceMethod:@selector(instanceMethod1)
                               withMethod:@selector(instanceMethod2)],
                @"Swizzle should succeed");
  XCTAssertEqualObjects([_objectA instanceMethod1], @"Class A Instance Method 1");
  XCTAssertEqualObjects([_objectA instanceMethod2], @"Class A Instance Method 2");
}

- (void)testResetClassMethods {
  XCTAssertFalse([_swizzler resetClassMethod:@selector(classMethod1) class:[GREYUTClassA class]],
                 @"Never swizzled. Should not reset.");

  XCTAssertTrue([_swizzler swizzleClass:[GREYUTClassA class]
                     replaceClassMethod:@selector(classMethod1)
                             withMethod:@selector(classMethod2)],
                @"Swizzle should succeed");

  XCTAssertTrue([_swizzler resetClassMethod:@selector(classMethod2) class:[GREYUTClassA class]]);
  XCTAssertEqualObjects([GREYUTClassA classMethod2], @"Class A Class Method 2");

  // Reset method 1, method 2 and method 3 remains the same.
  XCTAssertTrue([_swizzler resetClassMethod:@selector(classMethod1) class:[GREYUTClassA class]],
                @"Reset should succeed");
  XCTAssertEqualObjects([GREYUTClassA classMethod1], @"Class A Class Method 1");
  XCTAssertEqualObjects([GREYUTClassA classMethod2], @"Class A Class Method 2");
  XCTAssertEqualObjects([GREYUTClassA classMethod3], @"Class A Class Method 3");

  // Reset method 2, should have no effect.
  XCTAssertFalse([_swizzler resetClassMethod:@selector(classMethod2) class:[GREYUTClassA class]],
                 @"Should not reset");
  XCTAssertEqualObjects([GREYUTClassA classMethod2], @"Class A Class Method 2");
  XCTAssertEqualObjects([GREYUTClassA classMethod3], @"Class A Class Method 3");

  XCTAssertFalse([_swizzler resetClassMethod:@selector(classMethod3) class:[GREYUTClassA class]],
                 @"Reset should fail, never swizzled.");
  XCTAssertEqualObjects([GREYUTClassA classMethod3], @"Class A Class Method 3");

  XCTAssertFalse([_swizzler resetClassMethod:@selector(classMethod1) class:[GREYUTClassA class]],
                 @"Was reset before. Should not reset again.");
}

- (void)testResetInstanceMethods {
  XCTAssertFalse([_swizzler resetInstanceMethod:@selector(instanceMethod1)
                                          class:[GREYUTClassA class]],
                 @"Never swizzled. Should not reset.");

  XCTAssertTrue([_swizzler swizzleClass:[GREYUTClassA class]
                  replaceInstanceMethod:@selector(instanceMethod1)
                             withMethod:@selector(instanceMethod2)],
                @"Swizzle should succeed");

  // Reset method 1.
  XCTAssertTrue([_swizzler resetInstanceMethod:@selector(instanceMethod1)
                                         class:[GREYUTClassA class]],
                @"Reset should success");
  XCTAssertEqualObjects([_objectA instanceMethod1], @"Class A Instance Method 1");
  XCTAssertEqualObjects([_objectA instanceMethod2], @"Class A Instance Method 1");
  XCTAssertEqualObjects([_objectA instanceMethod3], @"Class A Instance Method 3");

  XCTAssertTrue([_swizzler resetInstanceMethod:@selector(instanceMethod2)
                                         class:[GREYUTClassA class]],
                @"Reset should succeed");
  XCTAssertEqualObjects([_objectA instanceMethod2], @"Class A Instance Method 2");
}

- (void)testNotSwizzleSuperClassMethod {
  XCTAssertTrue([_swizzler swizzleClass:[GREYUTClassB class]
                     replaceClassMethod:@selector(classMethod1)
                             withMethod:@selector(classMethod2)],
                @"Swizzle should succeed");
  XCTAssertEqualObjects([GREYUTClassB classMethod1], @"Class A Class Method 2");
  XCTAssertEqualObjects([GREYUTClassB classMethod2], @"Class A Class Method 1");
  XCTAssertEqualObjects([GREYUTClassA classMethod1], @"Class A Class Method 1");
  XCTAssertEqualObjects([GREYUTClassA classMethod2], @"Class A Class Method 2");
  XCTAssertEqualObjects([GREYUTClassC classMethod1], @"Class A Class Method 1");
  XCTAssertEqualObjects([GREYUTClassC classMethod2], @"Class A Class Method 2");
}

- (void)testNotSwizzleSuperInstanceMethod {
  XCTAssertTrue([_swizzler swizzleClass:[GREYUTClassB class]
                  replaceInstanceMethod:@selector(instanceMethod1)
                             withMethod:@selector(instanceMethod2)],
                @"Swizzle should succeed");
  GREYUTClassB *objectB = [[GREYUTClassB alloc] init];
  GREYUTClassC *objectC = [[GREYUTClassC alloc] init];
  XCTAssertEqualObjects([objectB instanceMethod1], @"Class A Instance Method 2");
  XCTAssertEqualObjects([objectB instanceMethod2], @"Class A Instance Method 1");
  XCTAssertEqualObjects([_objectA instanceMethod1], @"Class A Instance Method 1");
  XCTAssertEqualObjects([_objectA instanceMethod2], @"Class A Instance Method 2");
  XCTAssertEqualObjects([objectC instanceMethod1], @"Class C Instance Method 1");
  XCTAssertEqualObjects([objectC instanceMethod2], @"Class A Instance Method 2");
}

- (void)testSwizzleGREYUTClassAfterAddingMethod {
  SEL addSel = @selector(grey_customMethodToBeAddedAsClassAInstanceMethod);
  IMP addIMP = [self methodForSelector:addSel];
  XCTAssertTrue([_swizzler swizzleClass:[GREYUTClassA class]
                               addInstanceMethod:addSel
                              withImplementation:addIMP
                    andReplaceWithInstanceMethod:@selector(instanceMethod1)],
                @"Swizzling should succeed");
  XCTAssertEqualObjects([_objectA instanceMethod1],
                        @"Class A Added Instance Method called",
                        @"GREYUTClassA instance method should return swizzled value.");
  [_swizzler resetInstanceMethod:@selector(instanceMethod1) class:[GREYUTClassA class]];
}

- (void)testSwizzleSuccessOnAddingMethodFromAnotherClass {
  SEL addSel = @selector(instanceMethod2);
  IMP addIMP = [_objectA methodForSelector:addSel];
  BOOL swizzleSucceeded = [_swizzler swizzleClass:[GREYUTClassD class]
                                addInstanceMethod:addSel
                               withImplementation:addIMP
                     andReplaceWithInstanceMethod:@selector(classDInstanceMethod)];
  XCTAssertTrue(swizzleSucceeded, @"Swizzling should succeed");
  XCTAssertEqualObjects([_objectD classDInstanceMethod], @"Class A Instance Method 2");
  [_swizzler resetInstanceMethod:@selector(classDInstanceMethod) class:[GREYUTClassD class]];
  XCTAssertEqualObjects([_objectD classDInstanceMethod], @"Class D Instance Method");
  XCTAssertTrue([GREYUTClassD instancesRespondToSelector:addSel]);
}

- (void)testSwizzleFailure_ReplacementMethodFromAnotherClass {
  SEL addSel = @selector(instanceMethod3);
  IMP addIMP = [_objectD methodForSelector:addSel];
  BOOL swizzleSucceeded = [_swizzler swizzleClass:[GREYUTClassD class]
                                addInstanceMethod:addSel
                               withImplementation:addIMP
                     andReplaceWithInstanceMethod:@selector(instanceMethod1)];
  XCTAssertFalse(swizzleSucceeded,
                @"Swizzling failed because the replaced method is not in the swizzled class");
  XCTAssertFalse([_objectD respondsToSelector:@selector(instanceMethod3)]);
}

- (void)testSwizzleFailure_ClassMethodReplacement {
  SEL addSel = @selector(instanceMethod1);
  IMP addIMP = [_objectA methodForSelector:addSel];
  BOOL swizzleSucceeded = [_swizzler swizzleClass:[GREYUTClassD class]
                                addInstanceMethod:addSel
                               withImplementation:addIMP
                     andReplaceWithInstanceMethod:@selector(classDClassMethod)];
  XCTAssertFalse(swizzleSucceeded,
                 @"Swizzling failed because the method being replaced is a class method");
  XCTAssertEqualObjects([GREYUTClassD classDClassMethod], @"Class D Class Method");
  XCTAssertFalse([GREYUTClassD instancesRespondToSelector:addSel]);
}

- (void)testSwizzleFailure_ClassMethodAddition {
  SEL addSel = @selector(classMethod3);
  IMP addIMP = [GREYUTClassA methodForSelector:addSel];
  BOOL swizzleSucceeded = [_swizzler swizzleClass:[GREYUTClassD class]
                                addInstanceMethod:addSel
                               withImplementation:addIMP
                     andReplaceWithInstanceMethod:@selector(classDClassMethod)];
  XCTAssertFalse(swizzleSucceeded, @"Swizzling failed because the methods are class methods");
  XCTAssertEqualObjects([_objectD classDInstanceMethod1], @"Class D Instance Method 1");
  XCTAssertFalse([GREYUTClassD instancesRespondToSelector:addSel]);
}

- (void)testSwizzleFailure_AddingAnExistingSelector {
  SEL addSel = @selector(classDInstanceMethod1);
  IMP addIMP = [_objectD methodForSelector:addSel];
  BOOL swizzleSucceeded = [_swizzler swizzleClass:[GREYUTClassD class]
                                addInstanceMethod:addSel
                               withImplementation:addIMP
                     andReplaceWithInstanceMethod:@selector(classDInstanceMethod)];
  XCTAssertFalse(swizzleSucceeded, @"Selector Being Added already exists");
  XCTAssertTrue([GREYUTClassD instancesRespondToSelector:addSel]);
  XCTAssertEqualObjects([_objectD classDInstanceMethod], @"Class D Instance Method");
  XCTAssertEqualObjects([_objectD classDInstanceMethod1], @"Class D Instance Method 1");
}

- (void)testSwizzlingWithReplaceMethod_IncorrectClassMethods {
  SEL swizzledSelector = @selector(classMethod2);
  SEL fakeSelector = NSSelectorFromString(@"garbageSEL");

  BOOL swizzleSucceeded = [_swizzler swizzleClass:[GREYUTClassD class]
                               replaceClassMethod:fakeSelector
                                       withMethod:swizzledSelector];

  XCTAssertFalse(swizzleSucceeded,
                 @"Swizzle should Fail because the methods used are incorrect.");
  XCTAssertFalse([GREYUTClassD instancesRespondToSelector:swizzledSelector]);
  XCTAssertFalse([GREYUTClassD instancesRespondToSelector:fakeSelector]);
}

- (void)testSwizzlingWithReplaceMethod_IncorrectInstanceMethods {
  SEL swizzledSelector = @selector(instanceMethod1);
  SEL fakeSelector = NSSelectorFromString(@"garbageSEL");

  BOOL swizzleSucceeded = [_swizzler swizzleClass:[GREYUTClassD class]
                            replaceInstanceMethod:fakeSelector
                                       withMethod:swizzledSelector];

  XCTAssertFalse(swizzleSucceeded,
                 @"Swizzle should Fail because the methods used are incorrect.");
  XCTAssertFalse([GREYUTClassD instancesRespondToSelector:swizzledSelector]);
  XCTAssertFalse([GREYUTClassD instancesRespondToSelector:fakeSelector]);
}

-(void)testSwizzleWithImplementation_IncorrectImplementationForInstanceMethod {
  SEL addSel = @selector(instanceMethod3);
  IMP addIMP = [GREYUTClassA methodForSelector:addSel];
  BOOL swizzleSucceeded = [_swizzler swizzleClass:[GREYUTClassD class]
                                addInstanceMethod:addSel
                               withImplementation:addIMP
                     andReplaceWithInstanceMethod:@selector(classDInstanceMethod)];
  XCTAssertFalse(swizzleSucceeded,
                 @"Swizzling failed because the an instance method's implementation is being "
                 @"obtained using a class method's utility");
  XCTAssertFalse([GREYUTClassD instancesRespondToSelector:addSel]);
}

-(void)testSwizzleWithImplementation_IncorrectImplementationForClassMethod {
  SEL addSel = @selector(classMethod1);
  IMP addIMP = [GREYUTClassA instanceMethodForSelector:addSel];
  BOOL swizzleSucceeded = [_swizzler swizzleClass:[GREYUTClassD class]
                                addInstanceMethod:addSel
                               withImplementation:addIMP
                     andReplaceWithInstanceMethod:@selector(classDInstanceMethod)];
  XCTAssertFalse(swizzleSucceeded,
                 @"Swizzling failed because a class method's implementation is being obtained "
                 @"using an instance method's utility");
  XCTAssertFalse([GREYUTClassD instancesRespondToSelector:addSel]);
}

- (void)testSwizzleSameMethodTwiceAndReset {
  BOOL swizzleSucceeded = [_swizzler swizzleClass:[GREYUTClassA class]
                            replaceInstanceMethod:@selector(instanceMethod1)
                                       withMethod:@selector(instanceMethod2)];
  XCTAssertTrue(swizzleSucceeded);
  swizzleSucceeded = [_swizzler swizzleClass:[GREYUTClassA class]
                       replaceInstanceMethod:@selector(instanceMethod1)
                                  withMethod:@selector(instanceMethod3)];
  XCTAssertTrue(swizzleSucceeded);
  swizzleSucceeded = [_swizzler swizzleClass:[GREYUTClassA class]
                       replaceInstanceMethod:@selector(instanceMethod2)
                                  withMethod:@selector(instanceMethod3)];
  XCTAssertTrue(swizzleSucceeded);

  XCTAssertEqualObjects([_objectA instanceMethod1], @"Class A Instance Method 3");
  XCTAssertEqualObjects([_objectA instanceMethod2], @"Class A Instance Method 2");
  XCTAssertEqualObjects([_objectA instanceMethod3], @"Class A Instance Method 1");

  XCTAssertTrue([_swizzler resetInstanceMethod:@selector(instanceMethod2)
                                         class:[GREYUTClassA class]]);
  XCTAssertEqualObjects([_objectA instanceMethod2], @"Class A Instance Method 2");

  XCTAssertEqualObjects([_objectA instanceMethod1], @"Class A Instance Method 3");
  XCTAssertEqualObjects([_objectA instanceMethod3], @"Class A Instance Method 1");

  XCTAssertTrue([_swizzler resetInstanceMethod:@selector(instanceMethod3)
                                         class:[GREYUTClassA class]]);
  XCTAssertEqualObjects([_objectA instanceMethod3], @"Class A Instance Method 3");
  XCTAssertEqualObjects([_objectA instanceMethod1], @"Class A Instance Method 3");
}

- (void)testSwizzleResetSwizzleAgain {
  BOOL swizzleSucceeded = [_swizzler swizzleClass:[GREYUTClassA class]
                            replaceInstanceMethod:@selector(instanceMethod1)
                                       withMethod:@selector(instanceMethod2)];
  XCTAssertTrue(swizzleSucceeded);
  XCTAssertEqualObjects([_objectA instanceMethod1], @"Class A Instance Method 2");

  XCTAssertTrue([_swizzler resetInstanceMethod:@selector(instanceMethod2)
                                         class:[GREYUTClassA class]]);
  XCTAssertEqualObjects([_objectA instanceMethod1], @"Class A Instance Method 2");

  swizzleSucceeded = [_swizzler swizzleClass:[GREYUTClassA class]
                       replaceInstanceMethod:@selector(instanceMethod1)
                                  withMethod:@selector(instanceMethod2)];
  XCTAssertTrue(swizzleSucceeded);
  XCTAssertEqualObjects([_objectA instanceMethod1], @"Class A Instance Method 2");
  XCTAssertEqualObjects([_objectA instanceMethod2], @"Class A Instance Method 2");

  XCTAssertTrue([_swizzler resetInstanceMethod:@selector(instanceMethod1)
                                         class:[GREYUTClassA class]]);
  XCTAssertEqualObjects([_objectA instanceMethod1], @"Class A Instance Method 1");
  XCTAssertEqualObjects([_objectA instanceMethod2], @"Class A Instance Method 2");

  XCTAssertTrue([_swizzler resetInstanceMethod:@selector(instanceMethod2)
                                         class:[GREYUTClassA class]]);
  XCTAssertEqualObjects([_objectA instanceMethod2], @"Class A Instance Method 2");
}

- (void)testResetAll {
  BOOL swizzleSucceeded = [_swizzler swizzleClass:[GREYUTClassA class]
                            replaceInstanceMethod:@selector(instanceMethod1)
                                       withMethod:@selector(instanceMethod2)];
  XCTAssertTrue(swizzleSucceeded);
  swizzleSucceeded = [_swizzler swizzleClass:[GREYUTClassA class]
                       replaceInstanceMethod:@selector(instanceMethod1)
                                  withMethod:@selector(instanceMethod3)];
  XCTAssertTrue(swizzleSucceeded);
  swizzleSucceeded = [_swizzler swizzleClass:[GREYUTClassA class]
                       replaceInstanceMethod:@selector(instanceMethod2)
                                  withMethod:@selector(instanceMethod3)];
  XCTAssertTrue(swizzleSucceeded);

  [_swizzler resetAll];

  XCTAssertEqualObjects([_objectA instanceMethod1], @"Class A Instance Method 1");
  XCTAssertEqualObjects([_objectA instanceMethod2], @"Class A Instance Method 2");
  XCTAssertEqualObjects([_objectA instanceMethod3], @"Class A Instance Method 3");
}

#pragma mark - Custom Methods To Aid Testing

- (NSString *)grey_customMethodToBeAddedAsClassAInstanceMethod {
  return @"Class A Added Instance Method called";
}

@end
