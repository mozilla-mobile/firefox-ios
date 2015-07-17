//
//  KIFTestCase.h
//  KIF
//
//  Created by Brian Nickel on 12/14/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

/*!
 * @abstract @c KIFTestCase subclasses @c SenTestCase or XCTestCase to add setup and teardown steps that can be used to execute KIF test steps.
 * @discussion This class provides four new methods: @c beforeAll and @c afterAll which run once before and after all tests and @c beforeEach and @c afterEach which run before and after every test. @c beforeEach and @c afterEach are guaranteed to run in the same instance as each test, but @c beforeAll and @c afterAll are not.  As such, @c beforeEach can be used to set up instance variables while @c beforeAll can only be used to set up static variables.
 */
#ifndef KIF_SENTEST

#import <XCTest/XCTest.h>
#import "XCTestCase-KIFAdditions.h"
@interface KIFTestCase : XCTestCase

#else

#import <SenTestingKit/SenTestingKit.h>
#import "SenTestCase-KIFAdditions.h"
@interface KIFTestCase : SenTestCase

#endif

/*!
 * @abstract This method runs once before executing the first test in the class.
 * @discussion This should be used for navigating to the starting point in the app where all tests will start from.  Because this method is not guaranteed to run in the same instance as tests, it should not be used for setting up instance variables but can be used for setting up static variables.
 */
- (void)beforeAll;

/*!
 * @abstract This method runs before each test.
 * @discussion This should be used for any common tasks required before each test.  Because this method is guaranteed to run in the same instance as tests, it can be used for setting up instance variables.
 */
- (void)beforeEach;

/*!
 * @abstract This method runs after each test.
 * @discussion This should be used for restoring the app to the state it was in before the test.  This could include conditional logic to recover from failed tests.
 */
- (void)afterEach;

/*!
 * @abstract This method runs once after executing the last test in the class.
 * @discussion This should be used for navigating back to the initial state of the app, where it was before @c beforeAll.  This should also be used for tearing down any static methods created by @c beforeAll.
 */
- (void)afterAll;

/*!
 * @discussion When @c YES, rather than failing the test and advancing on the first failure, KIF will stop executing tests and begin spinning the run loop.  This provides an opportunity for inspecting the state of the app when the failure occurred.
 */
@property (nonatomic, assign) BOOL stopTestsOnFirstBigFailure;

@end

