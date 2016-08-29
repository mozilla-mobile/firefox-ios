//
//  NBAsYouTypeFormatterTest2.m
//  libPhoneNumber
//
//  Created by tabby on 2015. 8. 4..
//  Copyright (c) 2015년 ohtalk.me. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "NBAsYouTypeFormatter.h"
#import "NBMetadataHelper.h"

@interface NBAsYouTypeFormatterTest2 : XCTestCase

@end


@implementation NBAsYouTypeFormatterTest2

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)formatter:(NBAsYouTypeFormatter *)formatter didInputString:(BOOL)withResult
{
    NSLog(@"formatter success : %@", withResult ? @"YES":@"NO");
}

- (void)testAsYouTypeFormatter
{
    // testAYTFKR()
    {
        // +82 51 234 5678
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"KR"];
        XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
        XCTAssertEqualObjects(@"+8", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"+82 ", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+82 5", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+82 51", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+82 51-2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+82 51-23", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"+82 51-234", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"+82 51-234-5", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+82 51-234-56", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"+82 51-234-567", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"+82 51-234-5678", [f inputDigit:@"8"]);
        
        // +82 2 531 5678
        [f clear];
        XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
        XCTAssertEqualObjects(@"+8", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"+82 ", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+82 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+82 25", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+82 2-53", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"+82 2-531", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+82 2-531-5", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+82 2-531-56", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"+82 2-531-567", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"+82 2-531-5678", [f inputDigit:@"8"]);
        
        // +82 2 3665 5678
        [f clear];
        XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
        XCTAssertEqualObjects(@"+8", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"+82 ", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+82 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+82 23", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"+82 2-36", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"+82 2-366", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"+82 2-3665", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+82 2-3665-5", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+82 2-3665-56", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"+82 2-3665-567", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"+82 2-3665-5678", [f inputDigit:@"8"]);
        
        // 02-114
        [f clear];
        XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"02", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"021", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"02-11", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"02-114", [f inputDigit:@"4"]);
        
        // 02-1300
        [f clear];
        XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"02", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"021", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"02-13", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"02-130", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"02-1300", [f inputDigit:@"0"]);
        
        // 011-456-7890
        [f clear];
        XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"01", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011-4", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"011-45", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"011-456", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"011-456-7", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"011-456-78", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"011-456-789", [f inputDigit:@"9"]);
        XCTAssertEqualObjects(@"011-456-7890", [f inputDigit:@"0"]);
        
        // 011-9876-7890
        [f clear];
        XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"01", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011-9", [f inputDigit:@"9"]);
        XCTAssertEqualObjects(@"011-98", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"011-987", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"011-9876", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"011-9876-7", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"011-9876-78", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"011-9876-789", [f inputDigit:@"9"]);
        XCTAssertEqualObjects(@"011-9876-7890", [f inputDigit:@"0"]);
    }
    
    // testAYTF_MX()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"MX"];
        
        // +52 800 123 4567
        XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
        XCTAssertEqualObjects(@"+5", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+52 ", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+52 8", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"+52 80", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"+52 800", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"+52 800 1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+52 800 12", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+52 800 123", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"+52 800 123 4", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"+52 800 123 45", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+52 800 123 456", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"+52 800 123 4567", [f inputDigit:@"7"]);
        
        // +52 55 1234 5678
        [f clear];
        XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
        XCTAssertEqualObjects(@"+5", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+52 ", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+52 5", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+52 55", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+52 55 1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+52 55 12", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+52 55 123", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"+52 55 1234", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"+52 55 1234 5", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+52 55 1234 56", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"+52 55 1234 567", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"+52 55 1234 5678", [f inputDigit:@"8"]);
        
        // +52 212 345 6789
        [f clear];
        XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
        XCTAssertEqualObjects(@"+5", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+52 ", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+52 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+52 21", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+52 212", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+52 212 3", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"+52 212 34", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"+52 212 345", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+52 212 345 6", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"+52 212 345 67", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"+52 212 345 678", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"+52 212 345 6789", [f inputDigit:@"9"]);
        
        // +52 1 55 1234 5678
        [f clear];
        XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
        XCTAssertEqualObjects(@"+5", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+52 ", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+52 1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+52 15", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+52 1 55", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+52 1 55 1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+52 1 55 12", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+52 1 55 123", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"+52 1 55 1234", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"+52 1 55 1234 5", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+52 1 55 1234 56", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"+52 1 55 1234 567", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"+52 1 55 1234 5678", [f inputDigit:@"8"]);
        
        // +52 1 541 234 5678
        [f clear];
        XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
        XCTAssertEqualObjects(@"+5", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+52 ", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+52 1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+52 15", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+52 1 54", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"+52 1 541", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+52 1 541 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+52 1 541 23", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"+52 1 541 234", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"+52 1 541 234 5", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+52 1 541 234 56", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"+52 1 541 234 567", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"+52 1 541 234 5678", [f inputDigit:@"8"]);
    }
    
    // testAYTF_International_Toll_Free()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"US"];
        // +800 1234 5678
        XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
        XCTAssertEqualObjects(@"+8", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"+80", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"+800 ", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"+800 1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+800 12", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+800 123", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"+800 1234", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"+800 1234 5", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+800 1234 56", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"+800 1234 567", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"+800 1234 5678", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"+800123456789", [f inputDigit:@"9"]);
    }
    
    // testAYTFMultipleLeadingDigitPatterns()
    {
        // +81 50 2345 6789
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"JP"];
        XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
        XCTAssertEqualObjects(@"+8", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"+81 ", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+81 5", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+81 50", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"+81 50 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+81 50 23", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"+81 50 234", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"+81 50 2345", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+81 50 2345 6", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"+81 50 2345 67", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"+81 50 2345 678", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"+81 50 2345 6789", [f inputDigit:@"9"]);
        
        // +81 222 12 5678
        [f clear];
        XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
        XCTAssertEqualObjects(@"+8", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"+81 ", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+81 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+81 22", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+81 22 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+81 22 21", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+81 2221 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+81 222 12 5", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+81 222 12 56", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"+81 222 12 567", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"+81 222 12 5678", [f inputDigit:@"8"]);
        
        // 011113
        [f clear];
        XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"01", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011 1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011 11", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"011113", [f inputDigit:@"3"]);
        
        // +81 3332 2 5678
        [f clear];
        XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
        XCTAssertEqualObjects(@"+8", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"+81 ", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+81 3", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"+81 33", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"+81 33 3", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"+81 3332", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+81 3332 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+81 3332 2 5", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+81 3332 2 56", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"+81 3332 2 567", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"+81 3332 2 5678", [f inputDigit:@"8"]);
    }
    
    // testAYTFLongIDD_AU()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"AU"];
        // 0011 1 650 253 2250
        XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"00", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"001", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"0011", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"0011 1 ", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"0011 1 6", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"0011 1 65", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"0011 1 650", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"0011 1 650 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"0011 1 650 25", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"0011 1 650 253", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"0011 1 650 253 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"0011 1 650 253 22", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"0011 1 650 253 222", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"0011 1 650 253 2222", [f inputDigit:@"2"]);
        
        // 0011 81 3332 2 5678
        [f clear];
        XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"00", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"001", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"0011", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"00118", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"0011 81 ", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"0011 81 3", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"0011 81 33", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"0011 81 33 3", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"0011 81 3332", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"0011 81 3332 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"0011 81 3332 2 5", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"0011 81 3332 2 56", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"0011 81 3332 2 567", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"0011 81 3332 2 5678", [f inputDigit:@"8"]);
        
        // 0011 244 250 253 222
        [f clear];
        XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"00", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"001", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"0011", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"00112", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"001124", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"0011 244 ", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"0011 244 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"0011 244 25", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"0011 244 250", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"0011 244 250 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"0011 244 250 25", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"0011 244 250 253", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"0011 244 250 253 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"0011 244 250 253 22", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"0011 244 250 253 222", [f inputDigit:@"2"]);
    }
    
    // testAYTFLongIDD_KR()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"KR"];
        // 00300 1 650 253 2222
        XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"00", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"003", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"0030", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"00300", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"00300 1 ", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"00300 1 6", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"00300 1 65", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"00300 1 650", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"00300 1 650 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"00300 1 650 25", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"00300 1 650 253", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"00300 1 650 253 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"00300 1 650 253 22", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"00300 1 650 253 222", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"00300 1 650 253 2222", [f inputDigit:@"2"]);
    }
    
    // testAYTFLongNDD_KR()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"KR"];
        // 08811-9876-7890
        XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"08", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"088", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"0881", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"08811", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"08811-9", [f inputDigit:@"9"]);
        XCTAssertEqualObjects(@"08811-98", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"08811-987", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"08811-9876", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"08811-9876-7", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"08811-9876-78", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"08811-9876-789", [f inputDigit:@"9"]);
        XCTAssertEqualObjects(@"08811-9876-7890", [f inputDigit:@"0"]);
        
        // 08500 11-9876-7890
        [f clear];
        XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"08", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"085", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"0850", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"08500 ", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"08500 1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"08500 11", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"08500 11-9", [f inputDigit:@"9"]);
        XCTAssertEqualObjects(@"08500 11-98", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"08500 11-987", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"08500 11-9876", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"08500 11-9876-7", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"08500 11-9876-78", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"08500 11-9876-789", [f inputDigit:@"9"]);
        XCTAssertEqualObjects(@"08500 11-9876-7890", [f inputDigit:@"0"]);
    }
    
    // testAYTFLongNDD_SG()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"SG"];
        // 777777 9876 7890
        XCTAssertEqualObjects(@"7", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"77", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"777", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"7777", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"77777", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"777777 ", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"777777 9", [f inputDigit:@"9"]);
        XCTAssertEqualObjects(@"777777 98", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"777777 987", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"777777 9876", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"777777 9876 7", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"777777 9876 78", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"777777 9876 789", [f inputDigit:@"9"]);
        XCTAssertEqualObjects(@"777777 9876 7890", [f inputDigit:@"0"]);
    }
    
    // testAYTFShortNumberFormattingFix_AU()
    {
        // For Australia, the national prefix is not optional when formatting.
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"AU"];
        
        // 1234567890 - For leading digit 1, the national prefix formatting rule has
        // first group only.
        XCTAssertEqualObjects(@"1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"12", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"123", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"1234", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"1234 5", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"1234 56", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"1234 567", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"1234 567 8", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"1234 567 89", [f inputDigit:@"9"]);
        XCTAssertEqualObjects(@"1234 567 890", [f inputDigit:@"0"]);
        
        // +61 1234 567 890 - Test the same number, but with the country code.
        [f clear];
        XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
        XCTAssertEqualObjects(@"+6", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"+61 ", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+61 1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+61 12", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+61 123", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"+61 1234", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"+61 1234 5", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+61 1234 56", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"+61 1234 567", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"+61 1234 567 8", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"+61 1234 567 89", [f inputDigit:@"9"]);
        XCTAssertEqualObjects(@"+61 1234 567 890", [f inputDigit:@"0"]);
        
        // 212345678 - For leading digit 2, the national prefix formatting rule puts
        // the national prefix before the first group.
        [f clear];
        XCTAssertEqualObjects(@"0", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"02", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"021", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"02 12", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"02 123", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"02 1234", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"02 1234 5", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"02 1234 56", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"02 1234 567", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"02 1234 5678", [f inputDigit:@"8"]);
        
        // 212345678 - Test the same number, but without the leading 0.
        [f clear];
        XCTAssertEqualObjects(@"2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"21", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"212", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"2123", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"21234", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"212345", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"2123456", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"21234567", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"212345678", [f inputDigit:@"8"]);
        
        // +61 2 1234 5678 - Test the same number, but with the country code.
        [f clear];
        XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
        XCTAssertEqualObjects(@"+6", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"+61 ", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+61 2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+61 21", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+61 2 12", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+61 2 123", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"+61 2 1234", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"+61 2 1234 5", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+61 2 1234 56", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"+61 2 1234 567", [f inputDigit:@"7"]);
        XCTAssertEqualObjects(@"+61 2 1234 5678", [f inputDigit:@"8"]);
    }
    
    // testAYTFShortNumberFormattingFix_KR()
    {
        // For Korea, the national prefix is not optional when formatting, and the
        // national prefix formatting rule doesn't consist of only the first group.
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"KR"];
        
        // 111
        XCTAssertEqualObjects(@"1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"11", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"111", [f inputDigit:@"1"]);
        
        // 114
        [f clear];
        XCTAssertEqualObjects(@"1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"11", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"114", [f inputDigit:@"4"]);
        
        // 13121234 - Test a mobile number without the national prefix. Even though it
        // is not an emergency number, it should be formatted as a block.
        [f clear];
        XCTAssertEqualObjects(@"1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"13", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"131", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"1312", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"13121", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"131212", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"1312123", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"13121234", [f inputDigit:@"4"]);
        
        // +82 131-2-1234 - Test the same number, but with the country code.
        [f clear];
        XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
        XCTAssertEqualObjects(@"+8", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"+82 ", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+82 1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+82 13", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"+82 131", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+82 131-2", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+82 131-2-1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+82 131-2-12", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+82 131-2-123", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"+82 131-2-1234", [f inputDigit:@"4"]);
    }
    
    // testAYTFShortNumberFormattingFix_MX()
    {
        // For Mexico, the national prefix is optional when formatting.
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"MX"];
        
        // 911
        XCTAssertEqualObjects(@"9", [f inputDigit:@"9"]);
        XCTAssertEqualObjects(@"91", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"911", [f inputDigit:@"1"]);
        
        // 800 123 4567 - Test a toll-free number, which should have a formatting rule
        // applied to it even though it doesn't begin with the national prefix.
        [f clear];
        XCTAssertEqualObjects(@"8", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"80", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"800", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"800 1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"800 12", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"800 123", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"800 123 4", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"800 123 45", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"800 123 456", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"800 123 4567", [f inputDigit:@"7"]);
        
        // +52 800 123 4567 - Test the same number, but with the country code.
        [f clear];
        XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
        XCTAssertEqualObjects(@"+5", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+52 ", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+52 8", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"+52 80", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"+52 800", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"+52 800 1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"+52 800 12", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+52 800 123", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"+52 800 123 4", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"+52 800 123 45", [f inputDigit:@"5"]);
        XCTAssertEqualObjects(@"+52 800 123 456", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"+52 800 123 4567", [f inputDigit:@"7"]);
    }
    
    // testAYTFNoNationalPrefix()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"IT"];
        XCTAssertEqualObjects(@"3", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"33", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"333", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"333 3", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"333 33", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"333 333", [f inputDigit:@"3"]);
    }
    
    // testAYTFShortNumberFormattingFix_US()
    {
        // For the US, an initial 1 is treated specially.
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"US"];
        
        // 101 - Test that the initial 1 is not treated as a national prefix.
        XCTAssertEqualObjects(@"1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"10", [f inputDigit:@"0"]);
        XCTAssertEqualObjects(@"101", [f inputDigit:@"1"]);
        
        // 112 - Test that the initial 1 is not treated as a national prefix.
        [f clear];
        XCTAssertEqualObjects(@"1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"11", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"112", [f inputDigit:@"2"]);
        
        // 122 - Test that the initial 1 is treated as a national prefix.
        [f clear];
        XCTAssertEqualObjects(@"1", [f inputDigit:@"1"]);
        XCTAssertEqualObjects(@"12", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"1 22", [f inputDigit:@"2"]);
    }
    
    // testAYTFDescription()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"US"];
        
        [f inputDigit:@"1"];
        [f inputDigit:@"6"];
        [f inputDigit:@"5"];
        [f inputDigit:@"0"];
        [f inputDigit:@"2"];
        [f inputDigit:@"5"];
        [f inputDigit:@"3"];
        [f inputDigit:@"2"];
        [f inputDigit:@"2"];
        [f inputDigit:@"2"];
        [f inputDigit:@"2"];
        XCTAssertEqualObjects(@"1 650 253 2222", [f description]);
        
        [f removeLastDigit];
        XCTAssertEqualObjects(@"1 650 253 222", [f description]);
        
        [f removeLastDigit];
        XCTAssertEqualObjects(@"1 650 253 22", [f description]);
        
        [f removeLastDigit];
        XCTAssertEqualObjects(@"1 650 253 2", [f description]);
        
        [f removeLastDigit];
        XCTAssertEqualObjects(@"1 650 253", [f description]);
        
        [f removeLastDigit];
        XCTAssertEqualObjects(@"1 650 25", [f description]);
        
        [f removeLastDigit];
        XCTAssertEqualObjects(@"1 650 2", [f description]);
        
        [f removeLastDigit];
        XCTAssertEqualObjects(@"1 650", [f description]);
        
        [f removeLastDigit];
        XCTAssertEqualObjects(@"1 65", [f description]);
        
        [f removeLastDigit];
        XCTAssertEqualObjects(@"16", [f description]);
        
        [f removeLastDigit];
        XCTAssertEqualObjects(@"1", [f description]);
        
        [f removeLastDigit];
        XCTAssertEqualObjects(@"", [f description]);
        
        [f inputString:@"16502532222"];
        XCTAssertEqualObjects(@"1 650 253 2222", [f description]);
    }
    
    // testAYTFNumberPatternsBecomingInvalidShouldNotResultInDigitLoss()
    {
        /** @type {i18n.phonenumbers.AsYouTypeFormatter} */
        NBAsYouTypeFormatter *f = [[NBAsYouTypeFormatter alloc] initWithRegionCodeForTest:@"CN"];
        
        XCTAssertEqualObjects(@"+", [f inputDigit:@"+"]);
        XCTAssertEqualObjects(@"+8", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"+86 ", [f inputDigit:@"6"]);
        XCTAssertEqualObjects(@"+86 9", [f inputDigit:@"9"]);
        XCTAssertEqualObjects(@"+86 98", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"+86 988", [f inputDigit:@"8"]);
        XCTAssertEqualObjects(@"+86 988 1", [f inputDigit:@"1"]);
        // Now the number pattern is no longer valid because there are multiple leading digit patterns;
        // when we try again to extract a country code we should ensure we use the last leading digit
        // pattern, rather than the first one such that it *thinks* it's found a valid formatting rule
        // again.
        // https://code.google.com/p/libphonenumber/issues/detail?id=437
        XCTAssertEqualObjects(@"+8698812", [f inputDigit:@"2"]);
        XCTAssertEqualObjects(@"+86988123", [f inputDigit:@"3"]);
        XCTAssertEqualObjects(@"+869881234", [f inputDigit:@"4"]);
        XCTAssertEqualObjects(@"+8698812345", [f inputDigit:@"5"]);
    }
}

@end
