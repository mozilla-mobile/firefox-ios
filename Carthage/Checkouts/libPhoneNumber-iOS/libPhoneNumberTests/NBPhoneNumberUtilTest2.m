//
//  NBPhoneNumberUtilTest2.m
//  libPhoneNumber
//
//  Created by tabby on 2015. 8. 4..
//  Copyright (c) 2015년 ohtalk.me. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "NBMetadataHelper.h"
#import "NBPhoneMetaData.h"

#import "NBPhoneNumber.h"
#import "NBPhoneNumberDesc.h"
#import "NBPhoneNumberUtil.h"
#import "NBNumberFormat.h"


@interface NBPhoneNumberUtil (FOR_UNIT_TEST)

- (BOOL)canBeInternationallyDialled:(NBPhoneNumber*)number;
- (BOOL)truncateTooLongNumber:(NBPhoneNumber*)number;
- (NBEValidationResult)isPossibleNumberWithReason:(NBPhoneNumber*)number;
- (BOOL)isPossibleNumber:(NBPhoneNumber*)number;
- (NBEMatchType)isNumberMatch:(id)firstNumberIn second:(id)secondNumberIn;
- (int)getLengthOfGeographicalAreaCode:(NBPhoneNumber*)phoneNumber;
- (int)getLengthOfNationalDestinationCode:(NBPhoneNumber*)phoneNumber;
- (BOOL)maybeStripNationalPrefixAndCarrierCode:(NSString**)numberStr metadata:(NBPhoneMetaData*)metadata carrierCode:(NSString**)carrierCode;
- (NBECountryCodeSource)maybeStripInternationalPrefixAndNormalize:(NSString**)numberStr possibleIddPrefix:(NSString*)possibleIddPrefix;
- (NSString*)format:(NBPhoneNumber*)phoneNumber numberFormat:(NBEPhoneNumberFormat)numberFormat;
- (NSString*)formatByPattern:(NBPhoneNumber*)number numberFormat:(NBEPhoneNumberFormat)numberFormat userDefinedFormats:(NSArray*)userDefinedFormats;
- (NSString*)formatNumberForMobileDialing:(NBPhoneNumber*)number regionCallingFrom:(NSString*)regionCallingFrom withFormatting:(BOOL)withFormatting;
- (NSString*)formatOutOfCountryCallingNumber:(NBPhoneNumber*)number regionCallingFrom:(NSString*)regionCallingFrom;
- (NSString*)formatOutOfCountryKeepingAlphaChars:(NBPhoneNumber*)number regionCallingFrom:(NSString*)regionCallingFrom;
- (NSString*)formatNationalNumberWithCarrierCode:(NBPhoneNumber*)number carrierCode:(NSString*)carrierCode;
- (NSString*)formatInOriginalFormat:(NBPhoneNumber*)number regionCallingFrom:(NSString*)regionCallingFrom;
- (NSString*)formatNationalNumberWithPreferredCarrierCode:(NBPhoneNumber*)number fallbackCarrierCode:(NSString*)fallbackCarrierCode;

@end


@interface NBPhoneNumberUtilTest2 : XCTestCase
@end

@interface NBPhoneNumberUtilTest2 ()

@property (nonatomic, strong) NBPhoneNumberUtil *aUtil;

@end


@implementation NBPhoneNumberUtilTest2

- (void)setUp
{
    [super setUp];
    _aUtil = [[NBPhoneNumberUtil alloc] init];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testWithTestData
{
    // NSError *anError = nil;
    
    // Set up some test numbers to re-use.
    // TODO: Rewrite this as static functions that return new numbers each time to
    // avoid any risk of accidental changes to mutable static state affecting many
    // tests.
    NBPhoneNumber *ALPHA_NUMERIC_NUMBER = [[NBPhoneNumber alloc] init];
    ALPHA_NUMERIC_NUMBER.countryCode = @1;
    ALPHA_NUMERIC_NUMBER.nationalNumber = @80074935247;
    
    NBPhoneNumber *AE_UAN = [[NBPhoneNumber alloc] init];
    AE_UAN.countryCode = @971;
    AE_UAN.nationalNumber = @600123456;
    
    NBPhoneNumber *AR_MOBILE = [[NBPhoneNumber alloc] init];
    AR_MOBILE.countryCode = @54;
    AR_MOBILE.nationalNumber = @91187654321;
    
    NBPhoneNumber *AR_NUMBER = [[NBPhoneNumber alloc] init];
    AR_NUMBER.countryCode = @54;
    AR_NUMBER.nationalNumber = @1187654321;
    
    NBPhoneNumber *AU_NUMBER = [[NBPhoneNumber alloc] init];
    AU_NUMBER.countryCode = @61;
    AU_NUMBER.nationalNumber = @236618300;
    
    NBPhoneNumber *BS_MOBILE = [[NBPhoneNumber alloc] init];
    BS_MOBILE.countryCode = @1;
    BS_MOBILE.nationalNumber = @2423570000;
    
    NBPhoneNumber *BS_NUMBER = [[NBPhoneNumber alloc] init];
    BS_NUMBER.countryCode = @1;
    BS_NUMBER.nationalNumber = @2423651234;
    
    // Note that this is the same as the example number for DE in the metadata.
    NBPhoneNumber *DE_NUMBER = [[NBPhoneNumber alloc] init];
    DE_NUMBER.countryCode = @49;
    DE_NUMBER.nationalNumber = @30123456;
    
    NBPhoneNumber *DE_SHORT_NUMBER = [[NBPhoneNumber alloc] init];
    DE_SHORT_NUMBER.countryCode = @49;
    DE_SHORT_NUMBER.nationalNumber = @1234;
    
    NBPhoneNumber *GB_MOBILE = [[NBPhoneNumber alloc] init];
    GB_MOBILE.countryCode = @44;
    GB_MOBILE.nationalNumber = @7912345678;
    
    NBPhoneNumber *GB_NUMBER = [[NBPhoneNumber alloc] init];
    GB_NUMBER.countryCode = @44;
    GB_NUMBER.nationalNumber = @2070313000;
    
    NBPhoneNumber *IT_MOBILE = [[NBPhoneNumber alloc] init];
    IT_MOBILE.countryCode = @39;
    IT_MOBILE.nationalNumber = @345678901;
    
    NBPhoneNumber *IT_NUMBER = [[NBPhoneNumber alloc] init];
    IT_NUMBER.countryCode = @39;
    IT_NUMBER.nationalNumber = @236618300;
    IT_NUMBER.italianLeadingZero = YES;
    
    NBPhoneNumber *JP_STAR_NUMBER = [[NBPhoneNumber alloc] init];
    JP_STAR_NUMBER.countryCode = @81;
    JP_STAR_NUMBER.nationalNumber = @2345;
    
    // Numbers to test the formatting rules from Mexico.
    NBPhoneNumber *MX_MOBILE1 = [[NBPhoneNumber alloc] init];
    MX_MOBILE1.countryCode = @52;
    MX_MOBILE1.nationalNumber = @12345678900;
    
    NBPhoneNumber *MX_MOBILE2 = [[NBPhoneNumber alloc] init];
    MX_MOBILE2.countryCode = @52;
    MX_MOBILE2.nationalNumber = @15512345678;
    
    NBPhoneNumber *MX_NUMBER1 = [[NBPhoneNumber alloc] init];
    MX_NUMBER1.countryCode = @52;
    MX_NUMBER1.nationalNumber = @3312345678;
    
    NBPhoneNumber *MX_NUMBER2 = [[NBPhoneNumber alloc] init];
    MX_NUMBER2.countryCode = @52;
    MX_NUMBER2.nationalNumber = @8211234567;
    
    NBPhoneNumber *NZ_NUMBER = [[NBPhoneNumber alloc] init];
    NZ_NUMBER.countryCode = @64;
    NZ_NUMBER.nationalNumber = @33316005;
    
    NBPhoneNumber *SG_NUMBER = [[NBPhoneNumber alloc] init];
    SG_NUMBER.countryCode = @65;
    SG_NUMBER.nationalNumber = @65218000;
    
    // A too-long and hence invalid US number.
    NBPhoneNumber *US_LONG_NUMBER = [[NBPhoneNumber alloc] init];
    US_LONG_NUMBER.countryCode = @1;
    US_LONG_NUMBER.nationalNumber = @65025300001;
    
    NBPhoneNumber *US_NUMBER = [[NBPhoneNumber alloc] init];
    US_NUMBER.countryCode = @1;
    US_NUMBER.nationalNumber = @6502530000;
    
    NBPhoneNumber *US_PREMIUM = [[NBPhoneNumber alloc] init];
    US_PREMIUM.countryCode = @1;
    US_PREMIUM.nationalNumber = @9002530000;
    
    // Too short, but still possible US numbers.
    NBPhoneNumber *US_LOCAL_NUMBER = [[NBPhoneNumber alloc] init];
    US_LOCAL_NUMBER.countryCode = @1;
    US_LOCAL_NUMBER.nationalNumber = @2530000;
    
    NBPhoneNumber *US_SHORT_BY_ONE_NUMBER = [[NBPhoneNumber alloc] init];
    US_SHORT_BY_ONE_NUMBER.countryCode = @1;
    US_SHORT_BY_ONE_NUMBER.nationalNumber = @650253000;
    
    NBPhoneNumber *US_TOLLFREE = [[NBPhoneNumber alloc] init];
    US_TOLLFREE.countryCode = @1;
    US_TOLLFREE.nationalNumber = @8002530000;
    
    NBPhoneNumber *US_SPOOF = [[NBPhoneNumber alloc] init];
    US_SPOOF.countryCode = @1;
    US_SPOOF.nationalNumber = @0;
    
    NBPhoneNumber *US_SPOOF_WITH_RAW_INPUT = [[NBPhoneNumber alloc] init];
    US_SPOOF_WITH_RAW_INPUT.countryCode = @1;
    US_SPOOF_WITH_RAW_INPUT.nationalNumber = @0;
    US_SPOOF_WITH_RAW_INPUT.rawInput = @"000-000-0000";
    
    NBPhoneNumber *INTERNATIONAL_TOLL_FREE = [[NBPhoneNumber alloc] init];
    INTERNATIONAL_TOLL_FREE.countryCode = @800;
    INTERNATIONAL_TOLL_FREE.nationalNumber = @12345678;
    
    // We set this to be the same length as numbers for the other non-geographical
    // country prefix that we have in our test metadata. However, this is not
    // considered valid because they differ in their country calling code.
    
    NBPhoneNumber *INTERNATIONAL_TOLL_FREE_TOO_LONG = [[NBPhoneNumber alloc] init];
    INTERNATIONAL_TOLL_FREE_TOO_LONG.countryCode = @800;
    INTERNATIONAL_TOLL_FREE_TOO_LONG.nationalNumber = @123456789;
    
    NBPhoneNumber *UNIVERSAL_PREMIUM_RATE = [[NBPhoneNumber alloc] init];
    UNIVERSAL_PREMIUM_RATE.countryCode = @979;
    UNIVERSAL_PREMIUM_RATE.nationalNumber = @123456789;
    
    NBPhoneNumber *UNKNOWN_COUNTRY_CODE_NO_RAW_INPUT = [[NBPhoneNumber alloc] init];
    UNKNOWN_COUNTRY_CODE_NO_RAW_INPUT.countryCode = @2;
    UNKNOWN_COUNTRY_CODE_NO_RAW_INPUT.nationalNumber = @12345;
    
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    
    #pragma mark - testMaybeExtractCountryCode
    {
        NSLog(@"-------------- testMaybeExtractCountryCode");
        NBPhoneNumber *number = [[NBPhoneNumber alloc] init];
        NBPhoneMetaData *metadata = [helper getMetadataForRegion:@"US"];
        
        // Note that for the US, the IDD is 011.
        NSString *phoneNumber = @"011112-3456789";
        NSString *strippedNumber = @"123456789";
        NSNumber *countryCallingCode = @1;
        
        NSString *numberToFill = @"";
        
        {
            NSError *anError = nil;
            XCTAssertEqualObjects(countryCallingCode, [_aUtil maybeExtractCountryCode:phoneNumber metadata:metadata
                                                                       nationalNumber:&numberToFill keepRawInput:YES phoneNumber:&number error:&anError]);
            XCTAssertEqual(NBECountryCodeSourceFROM_NUMBER_WITH_IDD, [number.countryCodeSource integerValue]);
            // Should strip and normalize national significant number.
            XCTAssertEqualObjects(strippedNumber, numberToFill);
            if (anError)
                XCTFail(@"Should not have thrown an exception: %@", anError.description);
        }
        XCTAssertEqual(NBECountryCodeSourceFROM_NUMBER_WITH_IDD, [number.countryCodeSource integerValue], @"Did not figure out CountryCodeSource correctly");
        // Should strip and normalize national significant number.
        XCTAssertEqualObjects(strippedNumber, numberToFill, @"Did not strip off the country calling code correctly.");
        
        number = [[NBPhoneNumber alloc] init];
        phoneNumber = @"+6423456789";
        countryCallingCode = @64;
        numberToFill = @"";
        XCTAssertEqualObjects(countryCallingCode, [_aUtil maybeExtractCountryCode:phoneNumber metadata:metadata
                                                                   nationalNumber:&numberToFill keepRawInput:YES phoneNumber:&number error:nil]);
        XCTAssertEqual(NBECountryCodeSourceFROM_NUMBER_WITH_PLUS_SIGN, [number.countryCodeSource integerValue], @"Did not figure out CountryCodeSource correctly");
        
        number = [[NBPhoneNumber alloc] init];
        phoneNumber = @"+80012345678";
        countryCallingCode = @800;
        numberToFill = @"";
        XCTAssertEqualObjects(countryCallingCode, [_aUtil maybeExtractCountryCode:phoneNumber metadata:metadata
                                                                   nationalNumber:&numberToFill keepRawInput:YES phoneNumber:&number error:nil]);
        XCTAssertEqual(NBECountryCodeSourceFROM_NUMBER_WITH_PLUS_SIGN, [number.countryCodeSource integerValue], @"Did not figure out CountryCodeSource correctly");
        
        number = [[NBPhoneNumber alloc] init];
        phoneNumber = @"2345-6789";
        numberToFill = @"";
        XCTAssertEqual(@0, [_aUtil maybeExtractCountryCode:phoneNumber metadata:metadata
                                            nationalNumber:&numberToFill keepRawInput:YES phoneNumber:&number error:nil]);
        XCTAssertEqual(NBECountryCodeSourceFROM_DEFAULT_COUNTRY, [number.countryCodeSource integerValue], @"Did not figure out CountryCodeSource correctly");
        
        
        number = [[NBPhoneNumber alloc] init];
        phoneNumber = @"0119991123456789";
        numberToFill = @"";
        {
            NSError *anError = nil;
            [_aUtil maybeExtractCountryCode:phoneNumber metadata:metadata
                             nationalNumber:&numberToFill keepRawInput:YES phoneNumber:&number error:&anError];
            if (anError == nil)
                XCTFail(@"Should have thrown an exception, no valid country calling code present.");
            else // Expected.
                XCTAssertEqualObjects(@"INVALID_COUNTRY_CODE", anError.domain);
        }
        
        number = [[NBPhoneNumber alloc] init];
        phoneNumber = @"(1 610) 619 4466";
        countryCallingCode = @1;
        numberToFill = @"";
        {
            NSError *anError = nil;
            XCTAssertEqualObjects(countryCallingCode, [_aUtil maybeExtractCountryCode:phoneNumber metadata:metadata
                                                                       nationalNumber:&numberToFill keepRawInput:YES phoneNumber:&number error:&anError],
                                  @"Should have extracted the country calling code of the region passed in");
            XCTAssertEqual(NBECountryCodeSourceFROM_NUMBER_WITHOUT_PLUS_SIGN, [number.countryCodeSource integerValue], @"Did not figure out CountryCodeSource correctly");
        }
        
        number = [[NBPhoneNumber alloc] init];
        phoneNumber = @"(1 610) 619 4466";
        countryCallingCode = @1;
        numberToFill = @"";
        {
            NSError *anError = nil;
            XCTAssertEqualObjects(countryCallingCode, [_aUtil maybeExtractCountryCode:phoneNumber metadata:metadata
                                                                       nationalNumber:&numberToFill keepRawInput:NO phoneNumber:&number error:&anError]);
        }
        
        number = [[NBPhoneNumber alloc] init];
        phoneNumber = @"(1 610) 619 446";
        numberToFill = @"";
        {
            NSError *anError = nil;
            XCTAssertEqualObjects(@0, [_aUtil maybeExtractCountryCode:phoneNumber metadata:metadata
                                                       nationalNumber:&numberToFill keepRawInput:NO phoneNumber:&number error:&anError]);
            XCTAssertFalse(number.countryCodeSource != nil, @"Should not contain CountryCodeSource.");
        }
        
        number = [[NBPhoneNumber alloc] init];
        phoneNumber = @"(1 610) 619";
        numberToFill = @"";
        {
            NSError *anError = nil;
            XCTAssertEqual(@0, [_aUtil maybeExtractCountryCode:phoneNumber metadata:metadata
                                                nationalNumber:&numberToFill keepRawInput:YES phoneNumber:&number error:&anError]);
            XCTAssertEqual(NBECountryCodeSourceFROM_DEFAULT_COUNTRY, [number.countryCodeSource integerValue]);
        }
    }


    #pragma mark - testParseNationalNumber
    {
        NSError *anError;
        NSLog(@"-------------- testParseNationalNumber");
        // National prefix attached.
        XCTAssertTrue([NZ_NUMBER isEqual:[_aUtil parse:@"033316005" defaultRegion:@"NZ" error:&anError]]);
        XCTAssertTrue([NZ_NUMBER isEqual:[_aUtil parse:@"33316005" defaultRegion:@"NZ" error:&anError]]);
        
        // National prefix attached and some formatting present.
        XCTAssertTrue([NZ_NUMBER isEqual:[_aUtil parse:@"03-331 6005" defaultRegion:@"NZ" error:&anError]]);
        XCTAssertTrue([NZ_NUMBER isEqual:[_aUtil parse:@"03 331 6005" defaultRegion:@"NZ" error:&anError]]);
        
        // Test parsing RFC3966 format with a phone context.
        XCTAssertTrue([NZ_NUMBER isEqual:[_aUtil parse:@"tel:03-331-6005;phone-context=+64" defaultRegion:@"NZ" error:&anError]]);
        XCTAssertTrue([NZ_NUMBER isEqual:[_aUtil parse:@"tel:331-6005;phone-context=+64-3" defaultRegion:@"NZ" error:&anError]]);
        XCTAssertTrue([NZ_NUMBER isEqual:[_aUtil parse:@"tel:331-6005;phone-context=+64-3" defaultRegion:@"US" error:&anError]]);
        
        // Test parsing RFC3966 format with optional user-defined parameters. The
        // parameters will appear after the context if present.
        XCTAssertTrue([NZ_NUMBER isEqual:[_aUtil parse:@"tel:03-331-6005;phone-context=+64;a=%A1" defaultRegion:@"NZ" error:&anError]]);
        
        // Test parsing RFC3966 with an ISDN subaddress.
        XCTAssertTrue([NZ_NUMBER isEqual:[_aUtil parse:@"tel:03-331-6005;isub=12345;phone-context=+64" defaultRegion:@"NZ" error:&anError]]);
        XCTAssertTrue([NZ_NUMBER isEqual:[_aUtil parse:@"tel:+64-3-331-6005;isub=12345" defaultRegion:@"NZ" error:&anError]]);
        
        // Testing international prefixes.
        // Should strip country calling code.
        XCTAssertTrue([NZ_NUMBER isEqual:[_aUtil parse:@"0064 3 331 6005" defaultRegion:@"NZ" error:&anError]]);
        
        // Try again, but this time we have an international number with Region Code
        // US. It should recognise the country calling code and parse accordingly.
        XCTAssertTrue([NZ_NUMBER isEqual:[_aUtil parse:@"01164 3 331 6005" defaultRegion:@"US" error:&anError]]);
        XCTAssertTrue([NZ_NUMBER isEqual:[_aUtil parse:@"+64 3 331 6005" defaultRegion:@"US" error:&anError]]);
        // We should ignore the leading plus here, since it is not followed by a valid
        // country code but instead is followed by the IDD for the US.
        XCTAssertTrue([NZ_NUMBER isEqual:[_aUtil parse:@"+01164 3 331 6005" defaultRegion:@"US" error:&anError]]);
        XCTAssertTrue([NZ_NUMBER isEqual:[_aUtil parse:@"+0064 3 331 6005" defaultRegion:@"NZ" error:&anError]]);
        XCTAssertTrue([NZ_NUMBER isEqual:[_aUtil parse:@"+ 00 64 3 331 6005" defaultRegion:@"NZ" error:&anError]]);
        
        XCTAssertTrue([US_LOCAL_NUMBER isEqual:[_aUtil parse:@"tel:253-0000;phone-context=www.google.com" defaultRegion:@"US" error:&anError]]);
        XCTAssertTrue([US_LOCAL_NUMBER isEqual:[_aUtil parse:@"tel:253-0000;isub=12345;phone-context=www.google.com" defaultRegion:@"US" error:&anError]]);
        // This is invalid because no "+" sign is present as part of phone-context.
        // The phone context is simply ignored in this case just as if it contains a
        // domain.
        XCTAssertTrue([US_LOCAL_NUMBER isEqual:[_aUtil parse:@"tel:2530000;isub=12345;phone-context=1-650" defaultRegion:@"US" error:&anError]]);
        XCTAssertTrue([US_LOCAL_NUMBER isEqual:[_aUtil parse:@"tel:2530000;isub=12345;phone-context=1234.com" defaultRegion:@"US" error:&anError]]);
        
        NBPhoneNumber *nzNumber = [[NBPhoneNumber alloc] init];
        [nzNumber setCountryCode:@64];
        [nzNumber setNationalNumber:@64123456];
        XCTAssertTrue([nzNumber isEqual:[_aUtil parse:@"64(0)64123456" defaultRegion:@"NZ" error:&anError]]);
        // Check that using a '/' is fine in a phone number.
        XCTAssertTrue([DE_NUMBER isEqual:[_aUtil parse:@"301/23456" defaultRegion:@"DE" error:&anError]]);
        
        NBPhoneNumber *usNumber = [[NBPhoneNumber alloc] init];
        // Check it doesn't use the '1' as a country calling code when parsing if the
        // phone number was already possible.
        [usNumber setCountryCode:@1];
        [usNumber setNationalNumber:@1234567890];
        XCTAssertTrue([usNumber isEqual:[_aUtil parse:@"123-456-7890" defaultRegion:@"US" error:&anError]]);
        
        // Test star numbers. Although this is not strictly valid, we would like to
        // make sure we can parse the output we produce when formatting the number.
        XCTAssertTrue([JP_STAR_NUMBER isEqual:[_aUtil parse:@"+81 *2345" defaultRegion:@"JP" error:&anError]]);
        
        NBPhoneNumber *shortNumber = [[NBPhoneNumber alloc] init];
        [shortNumber setCountryCode:@64];
        [shortNumber setNationalNumber:@12];
        XCTAssertTrue([shortNumber isEqual:[_aUtil parse:@"12" defaultRegion:@"NZ" error:&anError]]);
    }


    #pragma mark - testParseNumberWithAlphaCharacters
    {
        NSError *anError;
        NSLog(@"-------------- testParseNumberWithAlphaCharacters");
        // Test case with alpha characters.
        NBPhoneNumber *tollfreeNumber = [[NBPhoneNumber alloc] init];
        [tollfreeNumber setCountryCode:@64];
        [tollfreeNumber setNationalNumber:@800332005];
        XCTAssertTrue([tollfreeNumber isEqual:[_aUtil parse:@"0800 DDA 005" defaultRegion:@"NZ" error:&anError]]);
        
        NBPhoneNumber *premiumNumber = [[NBPhoneNumber alloc] init];
        [premiumNumber setCountryCode:@64];
        [premiumNumber setNationalNumber:@9003326005];
        XCTAssertTrue([premiumNumber isEqual:[_aUtil parse:@"0900 DDA 6005" defaultRegion:@"NZ" error:&anError]]);
        // Not enough alpha characters for them to be considered intentional, so they
        // are stripped.
        XCTAssertTrue([premiumNumber isEqual:[_aUtil parse:@"0900 332 6005a" defaultRegion:@"NZ" error:&anError]]);
        XCTAssertTrue([premiumNumber isEqual:[_aUtil parse:@"0900 332 600a5" defaultRegion:@"NZ" error:&anError]]);
        XCTAssertTrue([premiumNumber isEqual:[_aUtil parse:@"0900 332 600A5" defaultRegion:@"NZ" error:&anError]]);
        XCTAssertTrue([premiumNumber isEqual:[_aUtil parse:@"0900 a332 600A5" defaultRegion:@"NZ" error:&anError]]);
    }


    #pragma mark - testParseMaliciousInput
    {
        NSLog(@"-------------- testParseMaliciousInput");
        // Lots of leading + signs before the possible number.
        
        NSString *maliciousNumber = @"";
        for (int i=0; i<6000; i++)
        {
            maliciousNumber = [maliciousNumber stringByAppendingString:@"+"];
        }
        
        maliciousNumber = [maliciousNumber stringByAppendingString:@"12222-33-244 extensioB 343+"];
        {
            NSError *anError = nil;
            [_aUtil parse:maliciousNumber defaultRegion:@"US" error:&anError];
            if (anError == nil) {
                XCTFail(@"This should not parse without throwing an exception %@", maliciousNumber);
            } else {
                XCTAssertEqualObjects(@"TOO_LONG", anError.domain, @"Wrong error type stored in exception.");
            }
        }
        
        NSString *maliciousNumberWithAlmostExt = @"";
        for (int i=0; i<350; i++)
        {
            maliciousNumberWithAlmostExt = [maliciousNumberWithAlmostExt stringByAppendingString:@"200"];
        }
        
        [maliciousNumberWithAlmostExt stringByAppendingString:@" extensiOB 345"];
        
        {
            NSError *anError = nil;
            [_aUtil parse:maliciousNumberWithAlmostExt defaultRegion:@"US" error:&anError];
            if (anError == nil) {
                XCTFail(@"This should not parse without throwing an exception %@", maliciousNumberWithAlmostExt);
            } else {
                XCTAssertEqualObjects(@"TOO_LONG", anError.domain, @"Wrong error type stored in exception.");
            }
        }
    }


    #pragma mark - testParseWithInternationalPrefixes
    {
        NSError *anError = nil;
        NSLog(@"-------------- testParseWithInternationalPrefixes");
        XCTAssertTrue([US_NUMBER isEqual:[_aUtil parse:@"+1 (650) 253-0000" defaultRegion:@"NZ" error:&anError]]);
        XCTAssertTrue([INTERNATIONAL_TOLL_FREE isEqual:[_aUtil parse:@"011 800 1234 5678" defaultRegion:@"US" error:&anError]]);
        XCTAssertTrue([US_NUMBER isEqual:[_aUtil parse:@"1-650-253-0000" defaultRegion:@"US" error:&anError]]);
        // Calling the US number from Singapore by using different service providers
        // 1st test: calling using SingTel IDD service (IDD is 001)
        XCTAssertTrue([US_NUMBER isEqual:[_aUtil parse:@"0011-650-253-0000" defaultRegion:@"SG" error:&anError]]);
        // 2nd test: calling using StarHub IDD service (IDD is 008)
        XCTAssertTrue([US_NUMBER isEqual:[_aUtil parse:@"0081-650-253-0000" defaultRegion:@"SG" error:&anError]]);
        // 3rd test: calling using SingTel V019 service (IDD is 019)
        XCTAssertTrue([US_NUMBER isEqual:[_aUtil parse:@"0191-650-253-0000" defaultRegion:@"SG" error:&anError]]);
        // Calling the US number from Poland
        XCTAssertTrue([US_NUMBER isEqual:[_aUtil parse:@"0~01-650-253-0000" defaultRegion:@"PL" error:&anError]]);
        // Using '++' at the start.
        XCTAssertTrue([US_NUMBER isEqual:[_aUtil parse:@"++1 (650) 253-0000" defaultRegion:@"PL" error:&anError]]);
    }


    #pragma mark - testParseNonAscii
    {
        NSError *anError = nil;
        NSLog(@"-------------- testParseNonAscii");
        // Using a full-width plus sign.
        XCTAssertTrue([US_NUMBER isEqual:[_aUtil parse:@"\uFF0B1 (650) 253-0000" defaultRegion:@"SG" error:&anError]]);
        // Using a soft hyphen U+00AD.
        XCTAssertTrue([US_NUMBER isEqual:[_aUtil parse:@"1 (650) 253\u00AD-0000" defaultRegion:@"US" error:&anError]]);
        // The whole number, including punctuation, is here represented in full-width
        // form.
        XCTAssertTrue([US_NUMBER isEqual:[_aUtil parse:@"\uFF0B\uFF11\u3000\uFF08\uFF16\uFF15\uFF10\uFF09\u3000\uFF12\uFF15\uFF13\uFF0D\uFF10\uFF10\uFF10\uFF10" defaultRegion:@"SG" error:&anError]]);
        // Using U+30FC dash instead.
        XCTAssertTrue([US_NUMBER isEqual:[_aUtil parse:@"\uFF0B\uFF11\u3000\uFF08\uFF16\uFF15\uFF10\uFF09\u3000\uFF12\uFF15\uFF13\u30FC\uFF10\uFF10\uFF10\uFF10" defaultRegion:@"SG" error:&anError]]);
        
        // Using a very strange decimal digit range (Mongolian digits).
        // TODO(user): Support Mongolian digits
        // STAssertTrue(US_NUMBER isEqual:
        //     [_aUtil parse:@"\u1811 \u1816\u1815\u1810 " +
        //                     '\u1812\u1815\u1813 \u1810\u1810\u1810\u1810" defaultRegion:@"US"], nil);
    }


    #pragma mark - testParseWithLeadingZero
    {
        NSError *anError = nil;
        NSLog(@"-------------- testParseWithLeadingZero");
        XCTAssertTrue([IT_NUMBER isEqual:[_aUtil parse:@"+39 02-36618 300" defaultRegion:@"NZ" error:&anError]]);
        XCTAssertTrue([IT_NUMBER isEqual:[_aUtil parse:@"02-36618 300" defaultRegion:@"IT" error:&anError]]);
        XCTAssertTrue([IT_MOBILE isEqual:[_aUtil parse:@"345 678 901" defaultRegion:@"IT" error:&anError]]);
    }


    #pragma mark - testParseNationalNumberArgentina
    {
        NSError *anError = nil;
        NSLog(@"-------------- testParseNationalNumberArgentina");
        // Test parsing mobile numbers of Argentina.
        NBPhoneNumber *arNumber = [[NBPhoneNumber alloc] init];
        [arNumber setCountryCode:@54];
        [arNumber setNationalNumber:@93435551212];
        XCTAssertTrue([arNumber isEqual:[_aUtil parse:@"+54 9 343 555 1212" defaultRegion:@"AR" error:&anError]]);
        XCTAssertTrue([arNumber isEqual:[_aUtil parse:@"0343 15 555 1212" defaultRegion:@"AR" error:&anError]]);
        
        arNumber = [[NBPhoneNumber alloc] init];
        [arNumber setCountryCode:@54];
        [arNumber setNationalNumber:@93715654320];
        XCTAssertTrue([arNumber isEqual:[_aUtil parse:@"+54 9 3715 65 4320" defaultRegion:@"AR" error:&anError]]);
        XCTAssertTrue([arNumber isEqual:[_aUtil parse:@"03715 15 65 4320" defaultRegion:@"AR" error:&anError]]);
        XCTAssertTrue([AR_MOBILE isEqual:[_aUtil parse:@"911 876 54321" defaultRegion:@"AR" error:&anError]]);
        
        // Test parsing fixed-line numbers of Argentina.
        XCTAssertTrue([AR_NUMBER isEqual:[_aUtil parse:@"+54 11 8765 4321" defaultRegion:@"AR" error:&anError]]);
        XCTAssertTrue([AR_NUMBER isEqual:[_aUtil parse:@"011 8765 4321" defaultRegion:@"AR" error:&anError]]);
        
        arNumber = [[NBPhoneNumber alloc] init];
        [arNumber setCountryCode:@54];
        [arNumber setNationalNumber:@3715654321];
        XCTAssertTrue([arNumber isEqual:[_aUtil parse:@"+54 3715 65 4321" defaultRegion:@"AR" error:&anError]]);
        XCTAssertTrue([arNumber isEqual:[_aUtil parse:@"03715 65 4321" defaultRegion:@"AR" error:&anError]]);
        
        arNumber = [[NBPhoneNumber alloc] init];
        [arNumber setCountryCode:@54];
        [arNumber setNationalNumber:@2312340000];
        XCTAssertTrue([arNumber isEqual:[_aUtil parse:@"+54 23 1234 0000" defaultRegion:@"AR" error:&anError]]);
        XCTAssertTrue([arNumber isEqual:[_aUtil parse:@"023 1234 0000" defaultRegion:@"AR" error:&anError]]);
    }


    #pragma mark - testParseWithXInNumber
    {
        NSError *anError = nil;
        NSLog(@"-------------- testParseWithXInNumber");
        // Test that having an 'x' in the phone number at the start is ok and that it
        // just gets removed.
        XCTAssertTrue([AR_NUMBER isEqual:[_aUtil parse:@"01187654321" defaultRegion:@"AR" error:&anError]]);
        XCTAssertTrue([AR_NUMBER isEqual:[_aUtil parse:@"(0) 1187654321" defaultRegion:@"AR" error:&anError]]);
        XCTAssertTrue([AR_NUMBER isEqual:[_aUtil parse:@"0 1187654321" defaultRegion:@"AR" error:&anError]]);
        XCTAssertTrue([AR_NUMBER isEqual:[_aUtil parse:@"(0xx) 1187654321" defaultRegion:@"AR" error:&anError]]);
        
        id arFromUs = [[NBPhoneNumber alloc] init];
        [arFromUs setCountryCode:@54];
        [arFromUs setNationalNumber:@81429712];
        // This test is intentionally constructed such that the number of digit after
        // xx is larger than 7, so that the number won't be mistakenly treated as an
        // extension, as we allow extensions up to 7 digits. This assumption is okay
        // for now as all the countries where a carrier selection code is written in
        // the form of xx have a national significant number of length larger than 7.
        XCTAssertTrue([arFromUs isEqual:[_aUtil parse:@"011xx5481429712" defaultRegion:@"US" error:&anError]]);
    }


    #pragma mark - testParseNumbersMexico
    {
        NSError *anError = nil;
        NSLog(@"-------------- testParseNumbersMexico");
        // Test parsing fixed-line numbers of Mexico.
        
        id mxNumber = [[NBPhoneNumber alloc] init];
        [mxNumber setCountryCode:@52];
        [mxNumber setNationalNumber:@4499780001];
        XCTAssertTrue([mxNumber isEqual:[_aUtil parse:@"+52 (449)978-0001" defaultRegion:@"MX" error:&anError]]);
        XCTAssertTrue([mxNumber isEqual:[_aUtil parse:@"01 (449)978-0001" defaultRegion:@"MX" error:&anError]]);
        XCTAssertTrue([mxNumber isEqual:[_aUtil parse:@"(449)978-0001" defaultRegion:@"MX" error:&anError]]);
        
        // Test parsing mobile numbers of Mexico.
        mxNumber = [[NBPhoneNumber alloc] init];
        [mxNumber setCountryCode:@52];
        [mxNumber setNationalNumber:@13312345678];
        XCTAssertTrue([mxNumber isEqual:[_aUtil parse:@"+52 1 33 1234-5678" defaultRegion:@"MX" error:&anError]]);
        XCTAssertTrue([mxNumber isEqual:[_aUtil parse:@"044 (33) 1234-5678" defaultRegion:@"MX" error:&anError]]);
        XCTAssertTrue([mxNumber isEqual:[_aUtil parse:@"045 33 1234-5678" defaultRegion:@"MX" error:&anError]]);
    }


    #pragma mark - testFailedParseOnInvalidNumbers
    {
        NSLog(@"-------------- testFailedParseOnInvalidNumbers");
        {
            NSError *anError = nil;
            NSString *sentencePhoneNumber = @"This is not a phone number";
            [_aUtil parse:sentencePhoneNumber defaultRegion:@"NZ" error:&anError];
            
            if (anError == nil)
                XCTFail(@"This should not parse without throwing an exception %@", sentencePhoneNumber);
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"NOT_A_NUMBER", anError.domain ,@"Wrong error type stored in exception.");
        }
        {
            NSError *anError = nil;
            NSString *sentencePhoneNumber = @"1 Still not a number";
            [_aUtil parse:sentencePhoneNumber defaultRegion:@"NZ" error:&anError];
            
            if (anError == nil)
                XCTFail(@"This should not parse without throwing an exception %@", sentencePhoneNumber);
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"NOT_A_NUMBER", anError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *anError = nil;
            NSString *sentencePhoneNumber = @"1 MICROSOFT";
            [_aUtil parse:sentencePhoneNumber defaultRegion:@"NZ" error:&anError];
            
            if (anError == nil)
                XCTFail(@"This should not parse without throwing an exception %@", sentencePhoneNumber);
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"NOT_A_NUMBER", anError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *anError = nil;
            NSString *sentencePhoneNumber = @"12 MICROSOFT";
            [_aUtil parse:sentencePhoneNumber defaultRegion:@"NZ" error:&anError];
            
            if (anError == nil)
                XCTFail(@"This should not parse without throwing an exception %@", sentencePhoneNumber);
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"NOT_A_NUMBER", anError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *anError = nil;
            NSString *tooLongPhoneNumber = @"01495 72553301873 810104";
            [_aUtil parse:tooLongPhoneNumber defaultRegion:@"GB" error:&anError];
            
            if (anError == nil)
                XCTFail(@"This should not parse without throwing an exception %@", tooLongPhoneNumber);
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"TOO_LONG", anError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *anError = nil;
            NSString *plusMinusPhoneNumber = @"+---";
            [_aUtil parse:plusMinusPhoneNumber defaultRegion:@"DE" error:&anError];
            
            if (anError == nil)
                XCTFail(@"This should not parse without throwing an exception %@", plusMinusPhoneNumber);
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"NOT_A_NUMBER", anError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *anError = nil;
            NSString *plusStar = @"+***";
            [_aUtil parse:plusStar defaultRegion:@"DE" error:&anError];
            if (anError == nil)
                XCTFail(@"This should not parse without throwing an exception %@", plusStar);
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"NOT_A_NUMBER", anError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *anError = nil;
            NSString *plusStarPhoneNumber = @"+*******91";
            [_aUtil parse:plusStarPhoneNumber defaultRegion:@"DE" error:&anError];
            if (anError == nil)
                XCTFail(@"This should not parse without throwing an exception %@", plusStarPhoneNumber);
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"NOT_A_NUMBER", anError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *anError = nil;
            NSString *tooShortPhoneNumber = @"+49 0";
            [_aUtil parse:tooShortPhoneNumber defaultRegion:@"DE" error:&anError];
            if (anError == nil)
                XCTFail(@"This should not parse without throwing an exception %@", tooShortPhoneNumber);
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"TOO_SHORT_NSN", anError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *anError = nil;
            NSString *invalidcountryCode = @"+210 3456 56789";
            [_aUtil parse:invalidcountryCode defaultRegion:@"NZ" error:&anError];
            if (anError == nil)
                XCTFail(@"This is not a recognised region code: should fail: %@", invalidcountryCode);
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"INVALID_COUNTRY_CODE", anError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *anError = nil;
            NSString *plusAndIddAndInvalidcountryCode = @"+ 00 210 3 331 6005";
            [_aUtil parse:plusAndIddAndInvalidcountryCode defaultRegion:@"NZ" error:&anError];
            if (anError == nil)
                XCTFail(@"This should not parse without throwing an exception.");
            else {
                // Expected this exception. 00 is a correct IDD, but 210 is not a valid
                // country code.
                XCTAssertEqualObjects(@"INVALID_COUNTRY_CODE", anError.domain, @"Wrong error type stored in exception.");
            }
        }
        
        {
            NSError *anError = nil;
            NSString *someNumber = @"123 456 7890";
            [_aUtil parse:someNumber defaultRegion:NB_UNKNOWN_REGION error:&anError];
            if (anError == nil)
                XCTFail(@"Unknown region code not allowed: should fail.");
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"INVALID_COUNTRY_CODE", anError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *anError = nil;
            NSString *someNumber = @"123 456 7890";
            [_aUtil parse:someNumber defaultRegion:@"CS" error:&anError];
            if (anError == nil)
                XCTFail(@"Deprecated region code not allowed: should fail.");
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"INVALID_COUNTRY_CODE", anError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *anError = nil;
            NSString *someNumber = @"123 456 7890";
            [_aUtil parse:someNumber defaultRegion:nil error:&anError];
            if (anError == nil)
                XCTFail(@"nil region code not allowed: should fail.");
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"INVALID_COUNTRY_CODE", anError.domain, @"Wrong error type stored in exception.");
        }
        
        
        {
            NSError *anError = nil;
            NSString *someNumber = @"0044------";
            [_aUtil parse:someNumber defaultRegion:@"GB" error:&anError];
            if (anError == nil)
                XCTFail(@"No number provided, only region code: should fail");
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"TOO_SHORT_AFTER_IDD", anError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *anError = nil;
            NSString *someNumber = @"0044";
            [_aUtil parse:someNumber defaultRegion:@"GB" error:&anError];
            if (anError == nil)
                XCTFail(@"No number provided, only region code: should fail");
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"TOO_SHORT_AFTER_IDD", anError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *anError = nil;
            NSString *someNumber = @"011";
            [_aUtil parse:someNumber defaultRegion:@"US" error:&anError];
            if (anError == nil)
                XCTFail(@"Only IDD provided - should fail.");
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"TOO_SHORT_AFTER_IDD", anError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *anError = nil;
            NSString *someNumber = @"0119";
            [_aUtil parse:someNumber defaultRegion:@"US" error:&anError];
            if (anError == nil)
                XCTFail(@"Only IDD provided and then 9 - should fail.");
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"TOO_SHORT_AFTER_IDD", anError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *anError = nil;
            NSString *emptyNumber = @"";
            // Invalid region.
            [_aUtil parse:emptyNumber defaultRegion:NB_UNKNOWN_REGION error:&anError];
            if (anError == nil)
                XCTFail(@"Empty string - should fail.");
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"NOT_A_NUMBER", anError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *anError = nil;
            // Invalid region.
            [_aUtil parse:nil defaultRegion:NB_UNKNOWN_REGION error:&anError];
            if (anError == nil)
                XCTFail(@"nil string - should fail.");
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"NOT_A_NUMBER", anError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *anError = nil;
            [_aUtil parse:nil defaultRegion:@"US" error:&anError];
            if (anError == nil)
                XCTFail(@"nil string - should fail.");
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"NOT_A_NUMBER", anError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *anError = nil;
            NSString *domainRfcPhoneContext = @"tel:555-1234;phone-context=www.google.com";
            [_aUtil parse:domainRfcPhoneContext defaultRegion:NB_UNKNOWN_REGION error:&anError];
            if (anError == nil)
                XCTFail(@"Unknown region code not allowed: should fail.");
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"INVALID_COUNTRY_CODE", anError.domain, @"Wrong error type stored in exception.");
        }
        
        {
            NSError *anError = nil;
            // This is invalid because no '+' sign is present as part of phone-context.
            // This should not succeed in being parsed.
            
            NSString *invalidRfcPhoneContext = @"tel:555-1234;phone-context=1-331";
            [_aUtil parse:invalidRfcPhoneContext defaultRegion:NB_UNKNOWN_REGION error:&anError];
            if (anError == nil)
                XCTFail(@"Unknown region code not allowed: should fail.");
            else
                // Expected this exception.
                XCTAssertEqualObjects(@"INVALID_COUNTRY_CODE", anError.domain, @"Wrong error type stored in exception.");
        }
    }


    #pragma mark - testParseNumbersWithPlusWithNoRegion
    {
        NSLog(@"-------------- testParseNumbersWithPlusWithNoRegion");
        NSError *anError;
        // @"ZZ is allowed only if the number starts with a '+' - then the
        // country calling code can be calculated.
        XCTAssertTrue([NZ_NUMBER isEqual:[_aUtil parse:@"+64 3 331 6005" defaultRegion:NB_UNKNOWN_REGION error:&anError]]);
        // Test with full-width plus.
        XCTAssertTrue([NZ_NUMBER isEqual:[_aUtil parse:@"\uFF0B64 3 331 6005" defaultRegion:NB_UNKNOWN_REGION error:&anError]]);
        // Test with normal plus but leading characters that need to be stripped.
        XCTAssertTrue([NZ_NUMBER isEqual:[_aUtil parse:@"Tel: +64 3 331 6005" defaultRegion:NB_UNKNOWN_REGION error:&anError]]);
        XCTAssertTrue([NZ_NUMBER isEqual:[_aUtil parse:@"+64 3 331 6005" defaultRegion:nil error:&anError]]);
        XCTAssertTrue([INTERNATIONAL_TOLL_FREE isEqual:[_aUtil parse:@"+800 1234 5678" defaultRegion:nil error:&anError]]);
        XCTAssertTrue([UNIVERSAL_PREMIUM_RATE isEqual:[_aUtil parse:@"+979 123 456 789" defaultRegion:nil error:&anError]]);
        
        // Test parsing RFC3966 format with a phone context.
        XCTAssertTrue([NZ_NUMBER isEqual:[_aUtil parse:@"tel:03-331-6005;phone-context=+64" defaultRegion:NB_UNKNOWN_REGION error:&anError]]);
        XCTAssertTrue([NZ_NUMBER isEqual:[_aUtil parse:@"  tel:03-331-6005;phone-context=+64" defaultRegion:NB_UNKNOWN_REGION error:&anError]]);
        XCTAssertTrue([NZ_NUMBER isEqual:[_aUtil parse:@"tel:03-331-6005;isub=12345;phone-context=+64" defaultRegion:NB_UNKNOWN_REGION error:&anError]]);
        
        // It is important that we set the carrier code to an empty string, since we
        // used ParseAndKeepRawInput and no carrier code was found.
        
        id nzNumberWithRawInput = [NZ_NUMBER copy];
        [nzNumberWithRawInput setRawInput:@"+64 3 331 6005"];
        [nzNumberWithRawInput setCountryCodeSource:[NSNumber numberWithInteger:NBECountryCodeSourceFROM_NUMBER_WITH_PLUS_SIGN]];
        [nzNumberWithRawInput setPreferredDomesticCarrierCode:@""];
        XCTAssertTrue([nzNumberWithRawInput isEqual:[_aUtil parseAndKeepRawInput:@"+64 3 331 6005" defaultRegion:NB_UNKNOWN_REGION error:&anError]]);
        // nil is also allowed for the region code in these cases.
        XCTAssertTrue([nzNumberWithRawInput isEqual:[_aUtil parseAndKeepRawInput:@"+64 3 331 6005" defaultRegion:nil error:&anError]]);
    }


    #pragma mark - testParseExtensions
    {
        NSError *anError = nil;
        NSLog(@"-------------- testParseExtensions");
        NBPhoneNumber *nzNumber = [[NBPhoneNumber alloc] init];
        [nzNumber setCountryCode:@64];
        [nzNumber setNationalNumber:@33316005];
        [nzNumber setExtension:@"3456"];
        XCTAssertTrue([nzNumber isEqual:[_aUtil parse:@"03 331 6005 ext 3456" defaultRegion:@"NZ" error:&anError]]);
        XCTAssertTrue([nzNumber isEqual:[_aUtil parse:@"03-3316005x3456" defaultRegion:@"NZ" error:&anError]]);
        XCTAssertTrue([nzNumber isEqual:[_aUtil parse:@"03-3316005 int.3456" defaultRegion:@"NZ" error:&anError]]);
        XCTAssertTrue([nzNumber isEqual:[_aUtil parse:@"03 3316005 #3456" defaultRegion:@"NZ" error:&anError]]);
        
        // Test the following do not extract extensions:
        XCTAssertTrue([ALPHA_NUMERIC_NUMBER isEqual:[_aUtil parse:@"1800 six-flags" defaultRegion:@"US" error:&anError]]);
        XCTAssertTrue([ALPHA_NUMERIC_NUMBER isEqual:[_aUtil parse:@"1800 SIX FLAGS" defaultRegion:@"US" error:&anError]]);
        XCTAssertTrue([ALPHA_NUMERIC_NUMBER isEqual:[_aUtil parse:@"0~0 1800 7493 5247" defaultRegion:@"PL" error:&anError]]);
        XCTAssertTrue([ALPHA_NUMERIC_NUMBER isEqual:[_aUtil parse:@"(1800) 7493.5247" defaultRegion:@"US" error:&anError]]);
        
        // Check that the last instance of an extension token is matched.
        
        id extnNumber = [ALPHA_NUMERIC_NUMBER copy];
        [extnNumber setExtension:@"1234"];
        XCTAssertTrue([extnNumber isEqual:[_aUtil parse:@"0~0 1800 7493 5247 ~1234" defaultRegion:@"PL" error:&anError]]);
        
        // Verifying bug-fix where the last digit of a number was previously omitted
        // if it was a 0 when extracting the extension. Also verifying a few different
        // cases of extensions.
        
        id ukNumber = [[NBPhoneNumber alloc] init];
        [ukNumber setCountryCode:@44];
        [ukNumber setNationalNumber:@2034567890];
        [ukNumber setExtension:@"456"];
        XCTAssertTrue([ukNumber isEqual:[_aUtil parse:@"+44 2034567890x456" defaultRegion:@"NZ" error:&anError]]);
        XCTAssertTrue([ukNumber isEqual:[_aUtil parse:@"+44 2034567890x456" defaultRegion:@"GB" error:&anError]]);
        XCTAssertTrue([ukNumber isEqual:[_aUtil parse:@"+44 2034567890 x456" defaultRegion:@"GB" error:&anError]]);
        XCTAssertTrue([ukNumber isEqual:[_aUtil parse:@"+44 2034567890 X456" defaultRegion:@"GB" error:&anError]]);
        XCTAssertTrue([ukNumber isEqual:[_aUtil parse:@"+44 2034567890 X 456" defaultRegion:@"GB" error:&anError]]);
        XCTAssertTrue([ukNumber isEqual:[_aUtil parse:@"+44 2034567890 X  456" defaultRegion:@"GB" error:&anError]]);
        XCTAssertTrue([ukNumber isEqual:[_aUtil parse:@"+44 2034567890 x 456  " defaultRegion:@"GB" error:&anError]]);
        XCTAssertTrue([ukNumber isEqual:[_aUtil parse:@"+44 2034567890  X 456" defaultRegion:@"GB" error:&anError]]);
        XCTAssertTrue([ukNumber isEqual:[_aUtil parse:@"+44-2034567890;ext=456" defaultRegion:@"GB" error:&anError]]);
        XCTAssertTrue([ukNumber isEqual:[_aUtil parse:@"tel:2034567890;ext=456;phone-context=+44" defaultRegion:NB_UNKNOWN_REGION error:&anError]]);
        // Full-width extension, @"extn' only.
        XCTAssertTrue([ukNumber isEqual:[_aUtil parse:@"+442034567890\uFF45\uFF58\uFF54\uFF4E456" defaultRegion:@"GB" error:&anError]]);
        // 'xtn' only.
        XCTAssertTrue([ukNumber isEqual:[_aUtil parse:@"+442034567890\uFF58\uFF54\uFF4E456" defaultRegion:@"GB" error:&anError]]);
        // 'xt' only.
        XCTAssertTrue([ukNumber isEqual:[_aUtil parse:@"+442034567890\uFF58\uFF54456" defaultRegion:@"GB" error:&anError]]);
        
        id usWithExtension = [[NBPhoneNumber alloc] init];
        [usWithExtension setCountryCode:@1];
        [usWithExtension setNationalNumber:@8009013355];
        [usWithExtension setExtension:@"7246433"];
        XCTAssertTrue([usWithExtension isEqual:[_aUtil parse:@"(800) 901-3355 x 7246433" defaultRegion:@"US" error:&anError]]);
        XCTAssertTrue([usWithExtension isEqual:[_aUtil parse:@"(800) 901-3355 , ext 7246433" defaultRegion:@"US" error:&anError]]);
        XCTAssertTrue([usWithExtension isEqual:[_aUtil parse:@"(800) 901-3355 ,extension 7246433" defaultRegion:@"US" error:&anError]]);
        XCTAssertTrue([usWithExtension isEqual:[_aUtil parse:@"(800) 901-3355 ,extensi\u00F3n 7246433" defaultRegion:@"US" error:&anError]]);
        
        // Repeat with the small letter o with acute accent created by combining
        // characters.
        XCTAssertTrue([usWithExtension isEqual:[_aUtil parse:@"(800) 901-3355 ,extensio\u0301n 7246433" defaultRegion:@"US" error:&anError]]);
        XCTAssertTrue([usWithExtension isEqual:[_aUtil parse:@"(800) 901-3355 , 7246433" defaultRegion:@"US" error:&anError]]);
        XCTAssertTrue([usWithExtension isEqual:[_aUtil parse:@"(800) 901-3355 ext: 7246433" defaultRegion:@"US" error:&anError]]);
        
        // Test that if a number has two extensions specified, we ignore the second.
        id usWithTwoExtensionsNumber = [[NBPhoneNumber alloc] init];
        [usWithTwoExtensionsNumber setCountryCode:@1];
        [usWithTwoExtensionsNumber setNationalNumber:@2121231234];
        [usWithTwoExtensionsNumber setExtension:@"508"];
        XCTAssertTrue([usWithTwoExtensionsNumber isEqual:[_aUtil parse:@"(212)123-1234 x508/x1234" defaultRegion:@"US" error:&anError]]);
        XCTAssertTrue([usWithTwoExtensionsNumber isEqual:[_aUtil parse:@"(212)123-1234 x508/ x1234" defaultRegion:@"US" error:&anError]]);
        XCTAssertTrue([usWithTwoExtensionsNumber isEqual:[_aUtil parse:@"(212)123-1234 x508\\x1234" defaultRegion:@"US" error:&anError]]);
        
        // Test parsing numbers in the form (645) 123-1234-910# works, where the last
        // 3 digits before the # are an extension.
        usWithExtension = [[NBPhoneNumber alloc] init];
        [usWithExtension setCountryCode:@1];
        [usWithExtension setNationalNumber:@6451231234];
        [usWithExtension setExtension:@"910"];
        XCTAssertTrue([usWithExtension isEqual:[_aUtil parse:@"+1 (645) 123 1234-910#" defaultRegion:@"US" error:&anError]]);
        // Retry with the same number in a slightly different format.
        XCTAssertTrue([usWithExtension isEqual:[_aUtil parse:@"+1 (645) 123 1234 ext. 910#" defaultRegion:@"US" error:&anError]]);
    }


    #pragma mark - testParseAndKeepRaw
    {
        NSError *anError;
        NSLog(@"-------------- testParseAndKeepRaw");
        NBPhoneNumber *alphaNumericNumber = [ALPHA_NUMERIC_NUMBER copy];
        [alphaNumericNumber setRawInput:@"800 six-flags"];
        [alphaNumericNumber setCountryCodeSource:[NSNumber numberWithInteger:NBECountryCodeSourceFROM_DEFAULT_COUNTRY]];
        [alphaNumericNumber setPreferredDomesticCarrierCode:@""];
        XCTAssertTrue([alphaNumericNumber isEqual:[_aUtil parseAndKeepRawInput:@"800 six-flags" defaultRegion:@"US" error:&anError]]);
        
        id shorterAlphaNumber = [[NBPhoneNumber alloc] init];
        [shorterAlphaNumber setCountryCode:@1];
        [shorterAlphaNumber setNationalNumber:@8007493524];
        [shorterAlphaNumber setRawInput:@"1800 six-flag"];
        [shorterAlphaNumber setCountryCodeSource:[NSNumber numberWithInteger:NBECountryCodeSourceFROM_NUMBER_WITHOUT_PLUS_SIGN]];
        [shorterAlphaNumber setPreferredDomesticCarrierCode:@""];
        XCTAssertTrue([shorterAlphaNumber isEqual:[_aUtil parseAndKeepRawInput:@"1800 six-flag" defaultRegion:@"US" error:&anError]]);
        
        [shorterAlphaNumber setRawInput:@"+1800 six-flag"];
        [shorterAlphaNumber setCountryCodeSource:[NSNumber numberWithInteger:NBECountryCodeSourceFROM_NUMBER_WITH_PLUS_SIGN]];
        XCTAssertTrue([shorterAlphaNumber isEqual:[_aUtil parseAndKeepRawInput:@"+1800 six-flag" defaultRegion:@"NZ" error:&anError]]);
        
        [alphaNumericNumber setCountryCode:@1];
        [alphaNumericNumber setNationalNumber:@8007493524];
        [alphaNumericNumber setRawInput:@"001800 six-flag"];
        [alphaNumericNumber setCountryCodeSource:[NSNumber numberWithInteger:NBECountryCodeSourceFROM_NUMBER_WITH_IDD]];
        XCTAssertTrue([alphaNumericNumber isEqual:[_aUtil parseAndKeepRawInput:@"001800 six-flag" defaultRegion:@"NZ" error:&anError]]);
        
        // Invalid region code supplied.
        {
            [_aUtil parseAndKeepRawInput:@"123 456 7890" defaultRegion:@"CS" error:&anError];
            if (anError == nil)
                XCTFail(@"Deprecated region code not allowed: should fail.");
            else {
                // Expected this exception.
                XCTAssertEqualObjects(@"INVALID_COUNTRY_CODE", anError.domain, @"Wrong error type stored in exception.");
            }
        }
        
        id koreanNumber = [[NBPhoneNumber alloc] init];
        [koreanNumber setCountryCode:@82];
        [koreanNumber setNationalNumber:@22123456];
        [koreanNumber setRawInput:@"08122123456"];
        [koreanNumber setCountryCodeSource:[NSNumber numberWithInteger:NBECountryCodeSourceFROM_DEFAULT_COUNTRY]];
        [koreanNumber setPreferredDomesticCarrierCode:@"81"];
        XCTAssertTrue([koreanNumber isEqual:[_aUtil parseAndKeepRawInput:@"08122123456" defaultRegion:@"KR" error:&anError]]);
    }


    #pragma mark - testCountryWithNoNumberDesc
    {
        NSLog(@"-------------- testCountryWithNoNumberDesc");
        // Andorra is a country where we don't have PhoneNumberDesc info in the
        // metadata.
        NBPhoneNumber *adNumber = [[NBPhoneNumber alloc] init];
        [adNumber setCountryCode:@376];
        [adNumber setNationalNumber:@12345];
        XCTAssertEqualObjects(@"+376 12345", [_aUtil format:adNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"+37612345", [_aUtil format:adNumber numberFormat:NBEPhoneNumberFormatE164]);
        XCTAssertEqualObjects(@"12345", [_aUtil format:adNumber numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqual(NBEPhoneNumberTypeUNKNOWN, [_aUtil getNumberType:adNumber]);
        XCTAssertTrue([_aUtil isValidNumber:adNumber]);
        
        // Test dialing a US number from within Andorra.
        XCTAssertEqualObjects(@"00 1 650 253 0000", [_aUtil formatOutOfCountryCallingNumber:US_NUMBER regionCallingFrom:@"AD"]);
    }


    #pragma mark - testUnknownCountryCallingCode
    {
        NSLog(@"-------------- testUnknownCountryCallingCode");
        XCTAssertFalse([_aUtil isValidNumber:UNKNOWN_COUNTRY_CODE_NO_RAW_INPUT]);
        // It's not very well defined as to what the E164 representation for a number
        // with an invalid country calling code is, but just prefixing the country
        // code and national number is about the best we can do.
        XCTAssertEqualObjects(@"+212345", [_aUtil format:UNKNOWN_COUNTRY_CODE_NO_RAW_INPUT numberFormat:NBEPhoneNumberFormatE164]);
    }


    #pragma mark - testIsNumberMatchMatches
    {
        NSLog(@"-------------- testIsNumberMatchMatches");
        // Test simple matches where formatting is different, or leading zeroes,
        // or country calling code has been specified.
        
        NSError *anError = nil;
        
        NBPhoneNumber *num1 = [_aUtil parse:@"+64 3 331 6005" defaultRegion:@"NZ" error:&anError];
        NBPhoneNumber *num2 = [_aUtil parse:@"+64 03 331 6005" defaultRegion:@"NZ" error:&anError];
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:num1 second:num2]);
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:@"+64 3 331 6005" second:@"+64 03 331 6005"]);
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:@"+800 1234 5678" second:@"+80012345678"]);
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:@"+64 03 331-6005" second:@"+64 03331 6005"]);
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:@"+643 331-6005" second:@"+64033316005"]);
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:@"+643 331-6005" second:@"+6433316005"]);
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:@"+64 3 331-6005" second:@"+6433316005"]);
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:@"+64 3 331-6005" second:@"tel:+64-3-331-6005;isub=123"]);
        // Test alpha numbers.
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:@"+1800 siX-Flags" second:@"+1 800 7493 5247"]);
        // Test numbers with extensions.
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:@"+64 3 331-6005 extn 1234" second:@"+6433316005#1234"]);
        // Test proto buffers.
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:NZ_NUMBER second:@"+6403 331 6005"]);
        
        NBPhoneNumber *nzNumber = [NZ_NUMBER copy];
        [nzNumber setExtension:@"3456"];
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:nzNumber second:@"+643 331 6005 ext 3456"]);
        // Check empty extensions are ignored.
        [nzNumber setExtension:@""];
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:nzNumber second:@"+6403 331 6005"]);
        // Check variant with two proto buffers.
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:nzNumber second:NZ_NUMBER], @"Numbers did not match");
        
        // Check raw_input, country_code_source and preferred_domestic_carrier_code
        // are ignored.
        
        NBPhoneNumber *brNumberOne = [[NBPhoneNumber alloc] init];
        
        NBPhoneNumber *brNumberTwo = [[NBPhoneNumber alloc] init];
        [brNumberOne setCountryCode:@55];
        [brNumberOne setNationalNumber:@3121286979];
        [brNumberOne setCountryCodeSource:[NSNumber numberWithInteger:NBECountryCodeSourceFROM_NUMBER_WITH_PLUS_SIGN]];
        [brNumberOne setPreferredDomesticCarrierCode:@"12"];
        [brNumberOne setRawInput:@"012 3121286979"];
        [brNumberTwo setCountryCode:@55];
        [brNumberTwo setNationalNumber:@3121286979];
        [brNumberTwo setCountryCodeSource:[NSNumber numberWithInteger:NBECountryCodeSourceFROM_DEFAULT_COUNTRY]];
        [brNumberTwo setPreferredDomesticCarrierCode:@"14"];
        [brNumberTwo setRawInput:@"143121286979"];
        XCTAssertEqual(NBEMatchTypeEXACT_MATCH, [_aUtil isNumberMatch:brNumberOne second:brNumberTwo]);
    }

    #pragma mark - testIsNumberMatchNonMatches
    {
        NSLog(@"-------------- testIsNumberMatchNonMatches");
        // Non-matches.
        XCTAssertEqual(NBEMatchTypeNO_MATCH, [_aUtil isNumberMatch:@"03 331 6005" second:@"03 331 6006"]);
        XCTAssertEqual(NBEMatchTypeNO_MATCH, [_aUtil isNumberMatch:@"+800 1234 5678" second:@"+1 800 1234 5678"]);
        // Different country calling code, partial number match.
        XCTAssertEqual(NBEMatchTypeNO_MATCH, [_aUtil isNumberMatch:@"+64 3 331-6005" second:@"+16433316005"]);
        // Different country calling code, same number.
        XCTAssertEqual(NBEMatchTypeNO_MATCH, [_aUtil isNumberMatch:@"+64 3 331-6005" second:@"+6133316005"]);
        // Extension different, all else the same.
        XCTAssertEqual(NBEMatchTypeNO_MATCH, [_aUtil isNumberMatch:@"+64 3 331-6005 extn 1234" second:@"0116433316005#1235"]);
        XCTAssertEqual(NBEMatchTypeNO_MATCH, [_aUtil isNumberMatch:@"+64 3 331-6005 extn 1234" second:@"tel:+64-3-331-6005;ext=1235"]);
        // NSN matches, but extension is different - not the same number.
        XCTAssertEqual(NBEMatchTypeNO_MATCH, [_aUtil isNumberMatch:@"+64 3 331-6005 ext.1235" second:@"3 331 6005#1234"]);
        
        // Invalid numbers that can't be parsed.
        XCTAssertEqual(NBEMatchTypeNOT_A_NUMBER, [_aUtil isNumberMatch:@"4" second:@"3 331 6043"]);
        XCTAssertEqual(NBEMatchTypeNOT_A_NUMBER, [_aUtil isNumberMatch:@"+43" second:@"+64 3 331 6005"]);
        XCTAssertEqual(NBEMatchTypeNOT_A_NUMBER, [_aUtil isNumberMatch:@"+43" second:@"64 3 331 6005"]);
        XCTAssertEqual(NBEMatchTypeNOT_A_NUMBER, [_aUtil isNumberMatch:@"Dog" second:@"64 3 331 6005"]);
    }


    #pragma mark - testIsNumberMatchNsnMatches
    {
        NSLog(@"-------------- testIsNumberMatchNsnMatches");
        // NSN matches.
        XCTAssertEqual(NBEMatchTypeNSN_MATCH, [_aUtil isNumberMatch:@"+64 3 331-6005" second:@"03 331 6005"]);
        XCTAssertEqual(NBEMatchTypeNSN_MATCH, [_aUtil isNumberMatch:@"+64 3 331-6005" second:@"tel:03-331-6005;isub=1234;phone-context=abc.nz"]);
        XCTAssertEqual(NBEMatchTypeNSN_MATCH, [_aUtil isNumberMatch:NZ_NUMBER second:@"03 331 6005"]);
        // Here the second number possibly starts with the country calling code for
        // New Zealand, although we are unsure.
        
        NBPhoneNumber *unchangedNzNumber = [NZ_NUMBER copy];
        XCTAssertEqual(NBEMatchTypeNSN_MATCH, [_aUtil isNumberMatch:unchangedNzNumber second:@"(64-3) 331 6005"]);
        // Check the phone number proto was not edited during the method call.
        XCTAssertTrue([NZ_NUMBER isEqual:unchangedNzNumber]);
        
        // Here, the 1 might be a national prefix, if we compare it to the US number,
        // so the resultant match is an NSN match.
        XCTAssertEqual(NBEMatchTypeNSN_MATCH, [_aUtil isNumberMatch:US_NUMBER second:@"1-650-253-0000"]);
        XCTAssertEqual(NBEMatchTypeNSN_MATCH, [_aUtil isNumberMatch:US_NUMBER second:@"6502530000"]);
        XCTAssertEqual(NBEMatchTypeNSN_MATCH, [_aUtil isNumberMatch:@"+1 650-253 0000" second:@"1 650 253 0000"]);
        XCTAssertEqual(NBEMatchTypeNSN_MATCH, [_aUtil isNumberMatch:@"1 650-253 0000" second:@"1 650 253 0000"]);
        XCTAssertEqual(NBEMatchTypeNSN_MATCH, [_aUtil isNumberMatch:@"1 650-253 0000" second:@"+1 650 253 0000"]);
        // For this case, the match will be a short NSN match, because we cannot
        // assume that the 1 might be a national prefix, so don't remove it when
        // parsing.
        
        NBPhoneNumber *randomNumber = [[NBPhoneNumber alloc] init];
        [randomNumber setCountryCode:@41];
        [randomNumber setNationalNumber:@6502530000];
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [_aUtil isNumberMatch:randomNumber second:@"1-650-253-0000"]);
    }


    #pragma mark - testIsNumberMatchShortNsnMatches
    {
        NSLog(@"-------------- testIsNumberMatchShortNsnMatches");
        // Short NSN matches with the country not specified for either one or both
        // numbers.
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [_aUtil isNumberMatch:@"+64 3 331-6005" second:@"331 6005"]);
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [_aUtil isNumberMatch:@"+64 3 331-6005" second:@"tel:331-6005;phone-context=abc.nz"]);
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [_aUtil isNumberMatch:@"+64 3 331-6005" second:@"tel:331-6005;isub=1234;phone-context=abc.nz"]);
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [_aUtil isNumberMatch:@"+64 3 331-6005" second:@"tel:331-6005;isub=1234;phone-context=abc.nz;a=%A1"]);
        // We did not know that the '0' was a national prefix since neither number has
        // a country code, so this is considered a SHORT_NSN_MATCH.
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [_aUtil isNumberMatch:@"3 331-6005" second:@"03 331 6005"]);
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [_aUtil isNumberMatch:@"3 331-6005" second:@"331 6005"]);
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [_aUtil isNumberMatch:@"3 331-6005" second:@"tel:331-6005;phone-context=abc.nz"]);
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [_aUtil isNumberMatch:@"3 331-6005" second:@"+64 331 6005"]);
        // Short NSN match with the country specified.
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [_aUtil isNumberMatch:@"03 331-6005" second:@"331 6005"]);
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [_aUtil isNumberMatch:@"1 234 345 6789" second:@"345 6789"]);
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [_aUtil isNumberMatch:@"+1 (234) 345 6789" second:@"345 6789"]);
        // NSN matches, country calling code omitted for one number, extension missing
        // for one.
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [_aUtil isNumberMatch:@"+64 3 331-6005" second:@"3 331 6005#1234"]);
        // One has Italian leading zero, one does not.
        
        NBPhoneNumber *italianNumberOne = [[NBPhoneNumber alloc] init];
        [italianNumberOne setCountryCode:@39];
        [italianNumberOne setNationalNumber:@1234];
        [italianNumberOne setItalianLeadingZero:YES];
        
        NBPhoneNumber *italianNumberTwo = [[NBPhoneNumber alloc] init];
        [italianNumberTwo setCountryCode:@39];
        [italianNumberTwo setNationalNumber:@1234];
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [_aUtil isNumberMatch:italianNumberOne second:italianNumberTwo]);
        // One has an extension, the other has an extension of ''.
        [italianNumberOne setExtension:@"1234"];
        italianNumberOne.italianLeadingZero = NO;
        [italianNumberTwo setExtension:@""];
        XCTAssertEqual(NBEMatchTypeSHORT_NSN_MATCH, [_aUtil isNumberMatch:italianNumberOne second:italianNumberTwo]);
    }


    #pragma mark - testCanBeInternationallyDialled
    {
        NSLog(@"-------------- testCanBeInternationallyDialled");
        // We have no-international-dialling rules for the US in our test metadata
        // that say that toll-free numbers cannot be dialled internationally.
        XCTAssertFalse([_aUtil canBeInternationallyDialled:US_TOLLFREE]);
        
        // Normal US numbers can be internationally dialled.
        XCTAssertTrue([_aUtil canBeInternationallyDialled:US_NUMBER]);
        
        // Invalid number.
        XCTAssertTrue([_aUtil canBeInternationallyDialled:US_LOCAL_NUMBER]);
        
        // We have no data for NZ - should return true.
        XCTAssertTrue([_aUtil canBeInternationallyDialled:NZ_NUMBER]);
        XCTAssertTrue([_aUtil canBeInternationallyDialled:INTERNATIONAL_TOLL_FREE]);
    }


    #pragma mark - testIsAlphaNumber
    {
        NSLog(@"-------------- testIsAlphaNumber");
        XCTAssertTrue([_aUtil isAlphaNumber:@"1800 six-flags"]);
        XCTAssertTrue([_aUtil isAlphaNumber:@"1800 six-flags ext. 1234"]);
        XCTAssertTrue([_aUtil isAlphaNumber:@"+800 six-flags"]);
        XCTAssertTrue([_aUtil isAlphaNumber:@"180 six-flags"]);
        XCTAssertFalse([_aUtil isAlphaNumber:@"1800 123-1234"]);
        XCTAssertFalse([_aUtil isAlphaNumber:@"1 six-flags"]);
        XCTAssertFalse([_aUtil isAlphaNumber:@"18 six-flags"]);
        XCTAssertFalse([_aUtil isAlphaNumber:@"1800 123-1234 extension: 1234"]);
        XCTAssertFalse([_aUtil isAlphaNumber:@"+800 1234-1234"]);
    }
}

@end
