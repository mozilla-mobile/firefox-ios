//
//  KIFTestCase.m
//  KIF
//
//  Created by Brian Nickel on 12/14/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "KIFTestCase.h"
#import <UIKit/UIKit.h>
#import "UIApplication-KIFAdditions.h"
#import "KIFTestActor.h"

#define SIG(class, selector) [class instanceMethodSignatureForSelector:selector]

@implementation KIFTestCase
{
    NSException *_stoppingException;
}

NSComparisonResult selectorSort(NSInvocation *invocOne, NSInvocation *invocTwo, void *reverse);

+ (id)defaultTestSuite
{
    if (self == [KIFTestCase class]) {
        // Don't run KIFTestCase "tests"
        return nil;
    }
    
    return [super defaultTestSuite];
}

- (id)initWithInvocation:(NSInvocation *)anInvocation;
{
    self = [super initWithInvocation:anInvocation];
    if (!self) {
        return nil;
    }

    self.continueAfterFailure = NO;
    return self;
}

- (void)beforeEach { }
- (void)afterEach  { }
- (void)beforeAll  { }
- (void)afterAll   { }

NSComparisonResult selectorSort(NSInvocation *invocOne, NSInvocation *invocTwo, void *reverse) {
    
    NSString *selectorOne =  NSStringFromSelector([invocOne selector]);
    NSString *selectorTwo =  NSStringFromSelector([invocTwo selector]);
    return [selectorOne compare:selectorTwo options:NSCaseInsensitiveSearch];
}

+ (NSArray *)testInvocations
{
    NSArray *disorderedInvoc = [super testInvocations];
    NSArray *newArray = [disorderedInvoc sortedArrayUsingFunction:selectorSort context:NULL];
    return newArray;
}

+ (void)setUp
{
    [self performSetupTearDownWithSelector:@selector(beforeAll)];
}

+ (void)tearDown
{
    [self performSetupTearDownWithSelector:@selector(afterAll)];
}

+ (void)performSetupTearDownWithSelector:(SEL)selector
{
    KIFTestCase *testCase = [self testCaseWithSelector:selector];
    if ([testCase respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [testCase performSelector:selector];
#pragma clang diagnostic pop
    }

    if (testCase->_stoppingException) {
        [testCase->_stoppingException raise];
    }
}

- (void)setUp;
{
    [super setUp];
    
    if ([self isNotBeforeOrAfter]) {
        [self beforeEach];
    }
}

- (void)tearDown;
{
    if ([self isNotBeforeOrAfter]) {
        [self afterEach];
    }
    
    [super tearDown];
}

- (BOOL)isNotBeforeOrAfter;
{
    SEL selector = self.invocation.selector;
    return selector != @selector(beforeAll) && selector != @selector(afterAll);
}

- (void)failWithException:(NSException *)exception stopTest:(BOOL)stop
{
    if (stop) {
        _stoppingException = exception;
    }
    
    if (stop && self.stopTestsOnFirstBigFailure) {
        NSLog(@"Fatal failure encountered: %@", exception.description);
        NSLog(@"Stopping tests since stopTestsOnFirstBigFailure = YES");
        
        KIFTestActor *waiter = [[KIFTestActor alloc] init];
        [waiter waitForTimeInterval:[[NSDate distantFuture] timeIntervalSinceNow]];
        
        return;
    } else {
        [super failWithException:exception stopTest:stop];
    }
}

@end
