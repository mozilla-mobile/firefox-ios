//
//  NBAsYouTypeFormatterTest.m
//  libPhoneNumber
//
//  Created by ishtar on 13. 3. 5..
//

#import <XCTest/XCTest.h>
#import "NBAsYouTypeFormatter.h"
#import "NBMetadataHelper.h"


@interface NBAsYouTypeFormatterTest : XCTestCase
@end


@implementation NBAsYouTypeFormatterTest

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    // ...
    
    [super tearDown];
}

- (void)formatter:(NBAsYouTypeFormatter *)formatter didInputString:(BOOL)withResult
{
    NSLog(@"formatter success : %@", withResult ? @"YES":@"NO");
}

- (void)testAsYouTypeFormatter
{
    //testInvalidRegion()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:NB_UNKNOWN_REGION];
        XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
        XCTAssertEqualObjects(@"+4", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"+48 ", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"+48 8", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"+48 88", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"+48 88 1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+48 88 12", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+48 88 123", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"+48 88 123 1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+48 88 123 12", [f inputDigit:@"2"]);
        
        [f clear];
        XCTAssertEqualObjects(@"6", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"65", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"650", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"6502", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"65025", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"650253", [f inputDigit:@"3"]);
    }
    
    //testInvalidPlusSign()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:NB_UNKNOWN_REGION];
        XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
        XCTAssertEqualObjects(@"+4", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"+48 ", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"+48 8", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"+48 88", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"+48 88 1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+48 88 12", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+48 88 123", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"+48 88 123 1", [f inputDigit:@"1"]);
        // A plus sign can only appear at the beginning of the number;
        // otherwise, no formatting is applied.
        XCTAssertEqualObjects(@"+48881231+", [f inputDigit:@"+"]);
        XCTAssertEqualObjects(@"+48881231+2", [f inputDigit:@"2"]);
        
        XCTAssertEqualObjects(@"+48881231+", [f removeLastDigit]);
        XCTAssertEqualObjects(@"+48 88 123 1", [f removeLastDigit]);
        XCTAssertEqualObjects(@"+48 88 123", [f removeLastDigit]);
        XCTAssertEqualObjects(@"+48 88 12", [f removeLastDigit]);
        XCTAssertEqualObjects(@"+48 88 1", [f removeLastDigit]);
        XCTAssertEqualObjects(@"+48 88", [f removeLastDigit]);
        XCTAssertEqualObjects(@"+48 8", [f removeLastDigit]);
        XCTAssertEqualObjects(@"+48 ", [f removeLastDigit]);
        XCTAssertEqualObjects(@"+4", [f removeLastDigit]);
        XCTAssertEqualObjects(@"+", [f removeLastDigit]);
        XCTAssertEqualObjects(@"", [f removeLastDigit]);
    }
    
    //testTooLongNumberMatchingMultipleLeadingDigits()
    {
        // See http://code.google.com/p/libphonenumber/issues/detail?id=36
        // The bug occurred last time for countries which have two formatting rules
        // with exactly the same leading digits pattern but differ in length.
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:NB_UNKNOWN_REGION];
        XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
        XCTAssertEqualObjects(@"+8", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"+81 ", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+81 9", [f inputDigit:@"9"]);
        XCTAssertEqualObjects(@"+81 90", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"+81 90 1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+81 90 12", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+81 90 123", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"+81 90 1234", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"+81 90 1234 5", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+81 90 1234 56", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"+81 90 1234 567", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"+81 90 1234 5678", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"+81 90 12 345 6789", [f inputDigit:@"9"]);
        XCTAssertEqualObjects(@"+81901234567890", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"+819012345678901", [f inputDigit:@"1"]);
    }
    
    // testCountryWithSpaceInNationalPrefixFormattingRule()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"BY"];
        XCTAssertEqualObjects(@"8", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"88", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"881", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"8 819", [f inputDigit:@"9"]);
        XCTAssertEqualObjects(@"8 8190", [f inputDigit:@"0"]);
        // The formatting rule for 5 digit numbers states that no space should be
        // present after the national prefix.
        XCTAssertEqualObjects(@"881 901", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"8 819 012", [f inputDigit:@"2"]);
        // Too long, no formatting rule applies.
        XCTAssertEqualObjects(@"88190123", [f inputDigit:@"3"]);
    }
    
    // testCountryWithSpaceInNationalPrefixFormattingRuleAndLongNdd()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"BY"];
        XCTAssertEqualObjects(@"9", [f inputDigit:@"9"]);
        XCTAssertEqualObjects(@"99", [f inputDigit:@"9"]);
        XCTAssertEqualObjects(@"999", [f inputDigit:@"9"]);
        XCTAssertEqualObjects(@"9999", [f inputDigit:@"9"]);
        XCTAssertEqualObjects(@"99999 ", [f inputDigit:@"9"]);
        XCTAssertEqualObjects(@"99999 1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"99999 12", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"99999 123", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"99999 1234", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"99999 12 345", [f inputDigit:@"5"]);
    }
    
    // testAYTFUS()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"US"];
        XCTAssertEqualObjects(@"6", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"65", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"650", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"650 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"650 25", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"650 253", [f inputDigit:@"3"]);
        // Note this is how a US local number (without area code) should be formatted.
        XCTAssertEqualObjects(@"650 2532", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"650 253 22", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"650 253 222", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"650 253 2222", [f inputDigit:@"2"]);
        
        [f clear];
        XCTAssertEqualObjects(@"1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"16", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"1 65", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"1 650", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"1 650 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"1 650 25", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"1 650 253", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"1 650 253 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"1 650 253 22", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"1 650 253 222", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"1 650 253 2222", [f inputDigit:@"2"]);
        
        [f clear];
        XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"01", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011 ", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011 4", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"011 44 ", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"011 44 6", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"011 44 61", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011 44 6 12", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"011 44 6 123", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"011 44 6 123 1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011 44 6 123 12", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"011 44 6 123 123", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"011 44 6 123 123 1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011 44 6 123 123 12", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"011 44 6 123 123 123", [f inputDigit:@"3"]);
        
        [f clear];
        XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"01", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011 ", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011 5", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"011 54 ", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"011 54 9", [f inputDigit:@"9"]);
        XCTAssertEqualObjects(@"011 54 91", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011 54 9 11", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011 54 9 11 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"011 54 9 11 23", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"011 54 9 11 231", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011 54 9 11 2312", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"011 54 9 11 2312 1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011 54 9 11 2312 12", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"011 54 9 11 2312 123", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"011 54 9 11 2312 1234", [f inputDigit:@"4"]);
        
        [f clear];
        XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"01", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011 ", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"011 24", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"011 244 ", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"011 244 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"011 244 28", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"011 244 280", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"011 244 280 0", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"011 244 280 00", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"011 244 280 000", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"011 244 280 000 0", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"011 244 280 000 00", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"011 244 280 000 000", [f inputDigit:@"0"]);
        
        [f clear];
        XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
        XCTAssertEqualObjects(@"+4", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"+48 ", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"+48 8", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"+48 88", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"+48 88 1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+48 88 12", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+48 88 123", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"+48 88 123 1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+48 88 123 12", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+48 88 123 12 1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+48 88 123 12 12", [f inputDigit:@"2"]);
    }
    
    //testAYTFUSFullWidthCharacters()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"US"];
        XCTAssertEqualObjects(@"\uFF16", [f inputDigit:@"\uFF16"]);
        XCTAssertEqualObjects(@"\uFF16\uFF15", [f inputDigit:@"\uFF15"]);
        XCTAssertEqualObjects(@"650", [f inputDigit:@"\uFF10"]);
        XCTAssertEqualObjects(@"650 2", [f inputDigit:@"\uFF12"]);
        XCTAssertEqualObjects(@"650 25", [f inputDigit:@"\uFF15"]);
        XCTAssertEqualObjects(@"650 253", [f inputDigit:@"\uFF13"]);
        XCTAssertEqualObjects(@"650 2532", [f inputDigit:@"\uFF12"]);
        XCTAssertEqualObjects(@"650 253 22", [f inputDigit:@"\uFF12"]);
        XCTAssertEqualObjects(@"650 253 222", [f inputDigit:@"\uFF12"]);
        XCTAssertEqualObjects(@"650 253 2222", [f inputDigit:@"\uFF12"]);
    }
    
    // testAYTFUSMobileShortCode()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"US"];
        XCTAssertEqualObjects(@"*", [f inputDigit:@"*"]);
        XCTAssertEqualObjects(@"*1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"*12", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"*121", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"*121#", [f inputDigit:@"#"]);
    }
    
    // testAYTFUSVanityNumber()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"US"];
        XCTAssertEqualObjects(@"8", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"80", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"800", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"800 ", [f inputDigit:@" "]);
        XCTAssertEqualObjects(@"800 M", [f inputDigit:@"M"]);
        XCTAssertEqualObjects(@"800 MY", [f inputDigit:@"Y"]);
        XCTAssertEqualObjects(@"800 MY ", [f inputDigit:@" "]);
        XCTAssertEqualObjects(@"800 MY A", [f inputDigit:@"A"]);
        XCTAssertEqualObjects(@"800 MY AP", [f inputDigit:@"P"]);
        XCTAssertEqualObjects(@"800 MY APP", [f inputDigit:@"P"]);
        XCTAssertEqualObjects(@"800 MY APPL", [f inputDigit:@"L"]);
        XCTAssertEqualObjects(@"800 MY APPLE", [f inputDigit:@"E"]);
    }
    
    // testAYTFAndRememberPositionUS()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"US"];
        XCTAssertEqualObjects(@"1", [f inputDigitAndRememberPosition:@"1"]);
        XCTAssertEqual(1, [f getRememberedPosition]);
        XCTAssertEqualObjects(@"16", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"1 65", [f inputDigit:@"5"]);
        XCTAssertEqual(1, [f getRememberedPosition]);
        XCTAssertEqualObjects(@"1 650", [f inputDigitAndRememberPosition:@"0"]);
        XCTAssertEqual(5, [f getRememberedPosition]);
        XCTAssertEqualObjects(@"1 650 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"1 650 25", [f inputDigit:@"5"]);
        // Note the remembered position for digit '0' changes from 4 to 5, because a
        // space is now inserted in the front.
        XCTAssertEqual(5, [f getRememberedPosition]);
        XCTAssertEqualObjects(@"1 650 253", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"1 650 253 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"1 650 253 22", [f inputDigit:@"2"]);
        XCTAssertEqual(5, [f getRememberedPosition]);
        XCTAssertEqualObjects(@"1 650 253 222", [f inputDigitAndRememberPosition:@"2"]);
        XCTAssertEqual(13, [f getRememberedPosition]);
        XCTAssertEqualObjects(@"1 650 253 2222", [f inputDigit:@"2"]);
        XCTAssertEqual(13, [f getRememberedPosition]);
        XCTAssertEqualObjects(@"165025322222", [f inputDigit:@"2"]);
        XCTAssertEqual(10, [f getRememberedPosition]);
        XCTAssertEqualObjects(@"1650253222222", [f inputDigit:@"2"]);
        XCTAssertEqual(10, [f getRememberedPosition]);
        
        [f clear];
        XCTAssertEqualObjects(@"1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"16", [f inputDigitAndRememberPosition:@"6"]);
        XCTAssertEqual(2, [f getRememberedPosition]);
        XCTAssertEqualObjects(@"1 65", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"1 650", [f inputDigit:@"0"]);
        XCTAssertEqual(3, [f getRememberedPosition]);
        XCTAssertEqualObjects(@"1 650 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"1 650 25", [f inputDigit:@"5"]);
        XCTAssertEqual(3, [f getRememberedPosition]);
        XCTAssertEqualObjects(@"1 650 253", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"1 650 253 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"1 650 253 22", [f inputDigit:@"2"]);
        XCTAssertEqual(3, [f getRememberedPosition]);
        XCTAssertEqualObjects(@"1 650 253 222", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"1 650 253 2222", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"165025322222", [f inputDigit:@"2"]);
        XCTAssertEqual(2, [f getRememberedPosition]);
        XCTAssertEqualObjects(@"1650253222222", [f inputDigit:@"2"]);
        XCTAssertEqual(2, [f getRememberedPosition]);
        
        [f clear];
        XCTAssertEqualObjects(@"6", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"65", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"650", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"650 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"650 25", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"650 253", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"650 2532", [f inputDigitAndRememberPosition:@"2"]);
        XCTAssertEqual(8, [f getRememberedPosition]);
        XCTAssertEqualObjects(@"650 253 22", [f inputDigit:@"2"]);
        XCTAssertEqual(9, [f getRememberedPosition]);
        XCTAssertEqualObjects(@"650 253 222", [f inputDigit:@"2"]);
        // No more formatting when semicolon is entered.
        XCTAssertEqualObjects(@"650253222;", [f inputDigit:@";"]);
        XCTAssertEqual(7, [f getRememberedPosition]);
        XCTAssertEqualObjects(@"650253222;2", [f inputDigit:@"2"]);
        
        [f clear];
        XCTAssertEqualObjects(@"6", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"65", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"650", [f inputDigit:@"0"]);
        // No more formatting when users choose to do their own formatting.
        XCTAssertEqualObjects(@"650-", [f inputDigit:@"-"]);
        XCTAssertEqualObjects(@"650-2", [f inputDigitAndRememberPosition:@"2"]);
        XCTAssertEqual(5, [f getRememberedPosition]);
        XCTAssertEqualObjects(@"650-25", [f inputDigit:@"5"]);
        XCTAssertEqual(5, [f getRememberedPosition]);
        XCTAssertEqualObjects(@"650-253", [f inputDigit:@"3"]);
        XCTAssertEqual(5, [f getRememberedPosition]);
        XCTAssertEqualObjects(@"650-253-", [f inputDigit:@"-"]);
        XCTAssertEqualObjects(@"650-253-2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"650-253-22", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"650-253-222", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"650-253-2222", [f inputDigit:@"2"]);
        
        [f clear];
        XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"01", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011 ", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011 4", [f inputDigitAndRememberPosition:@"4"]);
        XCTAssertEqualObjects(@"011 48 ", [f inputDigit:@"8"]);
        XCTAssertEqual(5, [f getRememberedPosition]);
        XCTAssertEqualObjects(@"011 48 8", [f inputDigit:@"8"]);
        XCTAssertEqual(5, [f getRememberedPosition]);
        XCTAssertEqualObjects(@"011 48 88", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"011 48 88 1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011 48 88 12", [f inputDigit:@"2"]);
        XCTAssertEqual(5, [f getRememberedPosition]);
        XCTAssertEqualObjects(@"011 48 88 123", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"011 48 88 123 1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011 48 88 123 12", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"011 48 88 123 12 1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011 48 88 123 12 12", [f inputDigit:@"2"]);
        
        [f clear];
        XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
        XCTAssertEqualObjects(@"+1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+1 6", [f inputDigitAndRememberPosition:@"6"]);
        XCTAssertEqualObjects(@"+1 65", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+1 650", [f inputDigit:@"0"]);
        XCTAssertEqual(4, [f getRememberedPosition]);
        XCTAssertEqualObjects(@"+1 650 2", [f inputDigit:@"2"]);
        XCTAssertEqual(4, [f getRememberedPosition]);
        XCTAssertEqualObjects(@"+1 650 25", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+1 650 253", [f inputDigitAndRememberPosition:@"3"]);
        XCTAssertEqualObjects(@"+1 650 253 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+1 650 253 22", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+1 650 253 222", [f inputDigit:@"2"]);
        XCTAssertEqual(10, [f getRememberedPosition]);
        
        [f clear];
        XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
        XCTAssertEqualObjects(@"+1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+1 6", [f inputDigitAndRememberPosition:@"6"]);
        XCTAssertEqualObjects(@"+1 65", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+1 650", [f inputDigit:@"0"]);
        XCTAssertEqual(4, [f getRememberedPosition]);
        XCTAssertEqualObjects(@"+1 650 2", [f inputDigit:@"2"]);
        XCTAssertEqual(4, [f getRememberedPosition]);
        XCTAssertEqualObjects(@"+1 650 25", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+1 650 253", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"+1 650 253 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+1 650 253 22", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+1 650 253 222", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+1650253222;", [f inputDigit:@";"]);
        XCTAssertEqual(3, [f getRememberedPosition]);
    }
    
    // testAYTFGBFixedLine()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"GB"];
        XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"02", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"020", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"020 7", [f inputDigitAndRememberPosition:@"7"]);
        XCTAssertEqual(5, [f getRememberedPosition]);
        XCTAssertEqualObjects(@"020 70", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"020 703", [f inputDigit:@"3"]);
        XCTAssertEqual(5, [f getRememberedPosition]);
        XCTAssertEqualObjects(@"020 7031", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"020 7031 3", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"020 7031 30", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"020 7031 300", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"020 7031 3000", [f inputDigit:@"0"]);
    }
    
    // testAYTFGBTollFree()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"GB"];
        XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"08", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"080", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"080 7", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"080 70", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"080 703", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"080 7031", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"080 7031 3", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"080 7031 30", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"080 7031 300", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"080 7031 3000", [f inputDigit:@"0"]);
    }
    
    // testAYTFGBPremiumRate()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"GB"];
        XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"09", [f inputDigit:@"9"]);
        XCTAssertEqualObjects(@"090", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"090 7", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"090 70", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"090 703", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"090 7031", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"090 7031 3", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"090 7031 30", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"090 7031 300", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"090 7031 3000", [f inputDigit:@"0"]);
    }
    
    // testAYTFNZMobile()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"NZ"];
        XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"02", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"021", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"02-11", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"02-112", [f inputDigit:@"2"]);
        // Note the unittest is using fake metadata which might produce non-ideal
        // results.
        XCTAssertEqualObjects(@"02-112 3", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"02-112 34", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"02-112 345", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"02-112 3456", [f inputDigit:@"6"]);
    }
    
    // testAYTFDE()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"DE"];
        XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"03", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"030", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"030/1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"030/12", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"030/123", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"030/1234", [f inputDigit:@"4"]);
        
        // 04134 1234
        [f clear];
        XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"04", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"041", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"041 3", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"041 34", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"04134 1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"04134 12", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"04134 123", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"04134 1234", [f inputDigit:@"4"]);
        
        // 08021 2345
        [f clear];
        XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"08", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"080", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"080 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"080 21", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"08021 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"08021 23", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"08021 234", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"08021 2345", [f inputDigit:@"5"]);
        
        // 00 1 650 253 2250
        [f clear];
        XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"00", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"00 1 ", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"00 1 6", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"00 1 65", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"00 1 650", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"00 1 650 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"00 1 650 25", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"00 1 650 253", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"00 1 650 253 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"00 1 650 253 22", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"00 1 650 253 222", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"00 1 650 253 2222", [f inputDigit:@"2"]);
    }
    
    // testAYTFAR()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"AR"];
        XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"01", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011 7", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"011 70", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"011 703", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"011 7031", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011 7031-3", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"011 7031-30", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"011 7031-300", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"011 7031-3000", [f inputDigit:@"0"]);
    }
    
    // testAYTFARMobile()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"AR"];
        XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
        XCTAssertEqualObjects(@"+5", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+54 ", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"+54 9", [f inputDigit:@"9"]);
        XCTAssertEqualObjects(@"+54 91", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+54 9 11", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+54 9 11 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+54 9 11 23", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"+54 9 11 231", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+54 9 11 2312", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+54 9 11 2312 1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+54 9 11 2312 12", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+54 9 11 2312 123", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"+54 9 11 2312 1234", [f inputDigit:@"4"]);
    }
}

@end
