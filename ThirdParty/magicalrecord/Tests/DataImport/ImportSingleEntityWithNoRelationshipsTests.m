//
//  DataImportTests.m
//  Magical Record
//
//  Created by Saul Mora on 7/15/11.
//  Copyright 2011 Magical Panda Software LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "FixtureHelpers.h"
#import "SingleEntityWithNoRelationships.h"

@interface ImportSingleEntityWithNoRelationshipsTests : XCTestCase

@property (nonatomic, strong) SingleEntityWithNoRelationships *testEntity;

@end

@implementation ImportSingleEntityWithNoRelationshipsTests

@synthesize testEntity;

- (void)setUp
{
    [super setUp];

    [MagicalRecord setDefaultModelFromClass:[self class]];
    [MagicalRecord setupCoreDataStackWithInMemoryStore];

    id singleEntity = [self dataFromJSONFixture];

    testEntity = [SingleEntityWithNoRelationships MR_importFromObject:singleEntity];
}

- (void)tearDown
{
    [super tearDown];

    [MagicalRecord cleanUp];
}

- (void)testImportASingleEntity
{
    XCTAssertNotNil(testEntity, @"testEntity should not be nil");
}

- (void)testImportStringAttributeToEntity
{
    XCTAssertEqualObjects(testEntity.stringTestAttribute, @"This is a test value", @"stringTestAttribute did not contain expected value, instead found '%@'", testEntity.stringTestAttribute);
}

- (void)testImportInt16AttributeToEntity
{
    XCTAssertEqualObjects(testEntity.int16TestAttribute, @256, @"int16TestAttribute did not contain expected value, instead found: %@", testEntity.int16TestAttribute);
}

- (void)testImportInt32AttributeToEntity
{
    XCTAssertEqualObjects(testEntity.int32TestAttribute, @32, @"int32TestAttribute did not contain expected value, instead found: %@", testEntity.int32TestAttribute);
}

- (void)testImportInt64AttributeToEntity
{
    XCTAssertEqualObjects(testEntity.int64TestAttribute, @42, @"int64TestAttribute did not contain expected value, instead found: %@", testEntity.int64TestAttribute);
}

- (void)testImportDecimalAttributeToEntity
{
    XCTAssertEqualObjects(testEntity.decimalTestAttribute, @1.2, @"decimalTestAttribute did not contain expected value, instead found: %@", testEntity.decimalTestAttribute);
}

- (void)testImportDoubleAttributeToEntity
{
    XCTAssertEqualObjects(testEntity.doubleTestAttribute, @124.3, @"doubleTestAttribute did not contain expected value, instead found: %@", testEntity.doubleTestAttribute);
}

- (void)testImportFloatAttributeToEntity
{
    XCTAssertEqualObjects(testEntity.floatTestAttribute, @10000000000, @"floatTestAttribute did not contain expected value, instead found: %@", testEntity.floatTestAttribute);
}

- (void)testImportBooleanAttributeToEntity
{
    XCTAssertFalse([testEntity.booleanTestAttribute boolValue], @"booleanTestAttribute did not contain expected value, instead found: %@", testEntity.booleanTestAttribute);
}

- (void)testImportMappedStringAttributeToEntity
{
    XCTAssertEqualObjects(testEntity.mappedStringAttribute, @"Mapped value", @"mappedStringAttribute did not contain expected value, instead found: %@", testEntity.mappedStringAttribute);
}

- (void)testImportStringAttributeWithNullValue
{
    XCTAssertNil(testEntity.nullTestAttribute, @"nullTestAttribute did not contain expected value, instead found: %@", testEntity.nullTestAttribute);
}

- (void)testImportNumberAsStringAttributeToEntity
{
    XCTAssertEqualObjects(testEntity.numberAsStringTestAttribute, @"10248909829", @"numberAsStringTestAttribute did not contain expected value, instead found: %@", testEntity.numberAsStringTestAttribute);
}

- (void)testImportBooleanAsStringAttributeToEntity
{
    XCTAssertTrue(testEntity.booleanAsStringTestAttribute, @"booleanFromStringTestAttribute did not contain expected value, instead found: %@", testEntity.booleanAsStringTestAttribute);
}

- (void)testImportAttributeNotInJsonData
{
    NSRange rangeOfString = [testEntity.notInJsonAttribute rangeOfString:@"Core Data Model"];

    XCTAssertNotEqual(@(rangeOfString.length), @0, @"notInJsonAttribute did not contain expected string, instead received: %@", testEntity.notInJsonAttribute);
}

#if TARGET_OS_IPHONE

#if defined(__IPHONE_5_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_5_0

- (void)testImportUIColorAttributeToEntity
{
    UIColor *actualColor = testEntity.colorTestAttribute;

    if ([actualColor respondsToSelector:@selector(getRed:green:blue:alpha:)]) {
        CGFloat red, blue, green, alpha;
        [actualColor getRed:&red green:&green blue:&blue alpha:&alpha];

        XCTAssertEqual(alpha, (CGFloat)1.0, @"Unexpected value returned: %f", alpha);
        XCTAssertEqual(red, (CGFloat)(64.0f / 255.0f), @"Unexpected value returned: %f", red);
        XCTAssertEqual(green, (CGFloat)(128.0f / 255.0f), @"Unexpected value returned: %f", green);
        XCTAssertEqual(blue, (CGFloat)(225.0f / 255.0f), @"Unexpected value returned: %f", blue);
    }
}
#endif

- (NSDate *)dateFromString:(NSString *)date
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];

    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss ZZZ";
    formatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    formatter.locale = [NSLocale currentLocale];

    NSDate *expectedDate = [formatter dateFromString:date];

    return expectedDate;
}

#else

- (void)testImportNSColorAttributeToEntity
{
    NSColor *actualColor = testEntity.colorTestAttribute;

    XCTAssertEqual([actualColor alphaComponent], (CGFloat)(255.0 / 255.0), @"Unexpected value returned");
    XCTAssertEqual([actualColor redComponent], (CGFloat)(64.0f / 255.0f), @"Unexpected value returned");
    XCTAssertEqual([actualColor greenComponent], (CGFloat)(128.0f / 255.0f), @"Unexpected value returned");
    XCTAssertEqual([actualColor blueComponent], (CGFloat)(225.0f / 255.0f), @"Unexpected value returned");
}

- (NSDate *)dateFromString:(NSString *)date
{
    NSDate *expectedDate = [NSDate dateWithString:date];

    return expectedDate;
}
#endif /* if TARGET_OS_IPHONE */

- (void)testImportDateAttributeToEntity
{
    NSDate *expectedDate = [self dateFromString:@"2011-07-23 22:30:40 +0000"];

    XCTAssertEqualObjects(testEntity.dateTestAttribute, expectedDate, @"Unexpected value returned");
}

- (void)testImportDateAttributeWithCustomFormat
{
    NSDate *expectedDate = [self dateFromString:@"2011-08-05 01:56:04 +0000"];

    XCTAssertEqualObjects(testEntity.dateWithCustomFormat, expectedDate, @"Unexpected value returned");
}

- (void)testImportEpochDate {
    XCTAssertEqualObjects(testEntity.unixTimeTestAttribute, [NSDate dateWithTimeIntervalSince1970:1388349428], @"unixTimeTestAttribute did not contain the expected value, instead found: %@", testEntity.unixTimeTestAttribute);
}

- (void)testImportEpochDate13 {
    XCTAssertEqualObjects(testEntity.unixTime13TestAttribute, [NSDate dateWithTimeIntervalSince1970:1388349427.543], @"unixTimeTest13Attribute did not contain the expected value, instead found: %@", testEntity.unixTime13TestAttribute);
}

@end
