//
//  ADJTest.h
//  adjust
//
//  Created by Pedro Filipe on 15/05/15.
//  Copyright (c) 2015 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "ADJLoggerMock.h"

// assert level
#define aLevel(message, logLevel) \
    XCTAssert([self.loggerMock \
            deleteUntil:logLevel \
            beginsWith:message], \
          @"%@", self.loggerMock)

// assert test log
#define aTest(message) aLevel(message, ADJLogLevelTest)

// assert verbose log
#define aVerbose(message) aLevel(message, ADJLogLevelVerbose)

// assert debug log
#define aDebug(message) aLevel(message, ADJLogLevelDebug)

// assert info log
#define aInfo(message) aLevel(message, ADJLogLevelInfo)

// assert warn log
#define aWarn(message) aLevel(message, ADJLogLevelWarn)

// assert error log
#define aError(message) aLevel(message, ADJLogLevelError)

// assert assert log
#define aAssert(message) aLevel(message, ADJLogLevelAssert)

// assert not level
#define anLevel(message, logLevel) \
    XCTAssertFalse([self.loggerMock \
            deleteUntil:logLevel \
            beginsWith:message], \
        @"%@", self.loggerMock)

// assert not test log
#define anTest(message) anLevel(message, ADJLogLevelTest)

// assert not verbose log
#define anVerbose(message) anLevel(message, ADJLogLevelVerbose)

// assert not debug log
#define anDebug(message) anLevel(message, ADJLogLevelDebug)

// assert not info log
#define anInfo(message) anLevel(message, ADJLogLevelInfo)

// assert not warn log
#define anWarn(message) anLevel(message, ADJLogLevelWarn)

// assert not assert log
#define anAssert(message) anLevel(message, ADJLogLevelAssert)

// assert fail
#define aFail() \
    XCTFail(@"l:%@", self.loggerMock)

// assert false
#define aFalse(value) \
    XCTAssertFalse(value, @"v:%d, %@", value, self.loggerMock)

// assert log true
#define alTrue(value, log) \
    XCTAssert(value, @"v:%d, %@", value, log)

// assert true
#define aTrue(value) \
    alTrue(value, self.loggerMock)

// assert equals string log
#define aslEquals(field, value, log) \
    XCTAssert([field isEqualToString:value] || (field == nil && value == nil), @"f:%@, v:%@, l:%@", field, value, log)

// assert equals integer log
#define ailEquals(field, value, log) \
    XCTAssertEqual(field, value, @"f:%d, v:%d, l:%@", field, value, log)

// assert equals log
#define alEquals(field, value, log) \
    XCTAssertEqual(field, value, @"f:%@, v:%@, l:%@", field, value, log)

// assert not nil log
#define anlNil(field, log) \
    XCTAssertNotNil(field, @"f:%@, l:%@", field, log)

// assert nil log
#define alNil(field, log) \
    XCTAssertNil(field, @"f:%@, l:%@", field, log)

// assert equals integer
#define aiEquals(field, value) \
    ailEquals(field, value, self.loggerMock)

// assert not nill
#define anNil(field) \
    anlNil(field, self.loggerMock)

// assert nil
#define aNil(field) \
    alNil(field, self.loggerMock)

@interface ADJTest : XCTestCase

@property (atomic,strong) ADJLoggerMock *loggerMock;

@end
