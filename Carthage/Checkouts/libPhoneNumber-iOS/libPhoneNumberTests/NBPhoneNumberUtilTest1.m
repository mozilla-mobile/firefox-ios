//
//  NBPhoneNumberUtilTests.m
//  NBPhoneNumberUtilTests
//
//

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


@interface NBPhoneNumberUtilTest1 : XCTestCase
@end


@interface NBPhoneNumberUtilTest1 ()

@property (nonatomic, strong) NBPhoneNumberUtil *aUtil;

@end


@implementation NBPhoneNumberUtilTest1

- (void)setUp
{
    [super setUp];
    _aUtil = [[NBPhoneNumberUtil alloc] init];
}

- (void)tearDown
{
    [super tearDown];
}

- (NSString*)stringForNumberType:(NBEPhoneNumberType)type
{
    NSString *stringType = @"UNKNOWN";
    
    switch (type) {
        case 0: return @"FIXED_LINE";
        case 1: return @"MOBILE";
        case 2: return @"FIXED_LINE_OR_MOBILE";
        case 3: return @"TOLL_FREE";
        case 4: return @"PREMIUM_RATE";
        case 5: return @"SHARED_COST";
        case 6: return @"VOIP";
        case 7: return @"PERSONAL_NUMBER";
        case 8: return @"PAGER";
        case 9: return @"UAN";
        case 10: return @"VOICEMAIL";
        default:
            break;
    }
    
    return stringType;
}

 
- (void)testForGetMetadataForRegionTwice
{
    NBMetadataHelper *helper = [[NBMetadataHelper alloc] init];
    [helper getMetadataForRegion:@"US"];
    [helper getMetadataForRegion:@"KR"];
    [helper getMetadataForRegion:nil];
    [helper getMetadataForRegion:NULL];
    [helper getMetadataForRegion:@""];
    [helper getMetadataForRegion:0];
    [helper getMetadataForRegion:@" AU"];
    [helper getMetadataForRegion:@" JP        "];
}

- (void)testNSDictionaryalbeKey
{
    NSError *anError = nil;

    NBPhoneNumber *myNumber1 = [_aUtil parse:@"971600123456" defaultRegion:@"AE" error:&anError];
    NBPhoneNumber *myNumber2 = [_aUtil parse:@"5491187654321" defaultRegion:@"AR" error:&anError];
    NBPhoneNumber *myNumber3 = [_aUtil parse:@"12423570000" defaultRegion:@"BS" error:&anError];
    NBPhoneNumber *myNumber4 = [_aUtil parse:@"39236618300" defaultRegion:@"IT" error:&anError];
    NBPhoneNumber *myNumber5 = [_aUtil parse:@"16502530000" defaultRegion:@"US" error:&anError];
    
    NSMutableDictionary *dicTest = [[NSMutableDictionary alloc] init];
    [dicTest setObject:@"AE" forKey:myNumber1];
    [dicTest setObject:@"AR" forKey:myNumber2];
    [dicTest setObject:@"BS" forKey:myNumber3];
    [dicTest setObject:@"IT" forKey:myNumber4];
    [dicTest setObject:@"US" forKey:myNumber5];
    
    NSLog(@"%@", [dicTest objectForKey:myNumber1]);
    NSLog(@"%@", [dicTest objectForKey:myNumber2]);
    NSLog(@"%@", [dicTest objectForKey:myNumber3]);
    NSLog(@"%@", [dicTest objectForKey:myNumber4]);
    NSLog(@"%@", [dicTest objectForKey:myNumber5]);
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
    
    #pragma mark - testGetInstanceLoadUSMetadata
    {
        
        NBPhoneMetaData *metadata = [helper getMetadataForRegion:@"US"];

        XCTAssertEqualObjects(@"US", metadata.codeID);
        XCTAssertEqualObjects(@1, metadata.countryCode);
        XCTAssertEqualObjects(@"011", metadata.internationalPrefix);
        XCTAssertTrue(metadata.nationalPrefix != nil);
        XCTAssertEqual(2, (int)[metadata.numberFormats count]);
        XCTAssertEqualObjects(@"(\\d{3})(\\d{3})(\\d{4})", ((NBNumberFormat*)metadata.numberFormats[1]).pattern);
        XCTAssertEqualObjects(@"$1 $2 $3", ((NBNumberFormat*)metadata.numberFormats[1]).format);
        XCTAssertEqualObjects(@"[13-689]\\d{9}|2[0-35-9]\\d{8}", metadata.generalDesc.nationalNumberPattern);
        XCTAssertEqualObjects(@"\\d{7}(?:\\d{3})?", metadata.generalDesc.possibleNumberPattern);
        XCTAssertTrue([metadata.generalDesc isEqual:metadata.fixedLine]);
        XCTAssertEqualObjects(@"\\d{10}", metadata.tollFree.possibleNumberPattern);
        XCTAssertEqualObjects(@"900\\d{7}", metadata.premiumRate.nationalNumberPattern);
        // No shared-cost data is available, so it should be initialised to 'NA'.
        XCTAssertEqualObjects(@"NA", metadata.sharedCost.nationalNumberPattern);
        XCTAssertEqualObjects(@"NA", metadata.sharedCost.possibleNumberPattern);
    }
                                           
    #pragma mark - testGetInstanceLoadDEMetadata
    {
        NBPhoneMetaData *metadata = [helper getMetadataForRegion:@"DE"];
        XCTAssertEqualObjects(@"DE", metadata.codeID);
        XCTAssertEqualObjects(@49, metadata.countryCode);
        XCTAssertEqualObjects(@"00", metadata.internationalPrefix);
        XCTAssertEqualObjects(@"0", metadata.nationalPrefix);
        XCTAssertEqual(6, (int)[metadata.numberFormats count]);
        XCTAssertEqual(1, (int)[((NBNumberFormat*)metadata.numberFormats[5]).leadingDigitsPatterns count]);
        XCTAssertEqualObjects(@"900", ((NBNumberFormat*)metadata.numberFormats[5]).leadingDigitsPatterns[0]);
        XCTAssertEqualObjects(@"(\\d{3})(\\d{3,4})(\\d{4})", ((NBNumberFormat*)metadata.numberFormats[5]).pattern);
        XCTAssertEqualObjects(@"$1 $2 $3", ((NBNumberFormat*)metadata.numberFormats[5]).format);
        XCTAssertEqualObjects(@"(?:[24-6]\\d{2}|3[03-9]\\d|[789](?:[1-9]\\d|0[2-9]))\\d{1,8}", metadata.fixedLine.nationalNumberPattern);
        XCTAssertEqualObjects(@"\\d{2,14}", metadata.fixedLine.possibleNumberPattern);
        XCTAssertEqualObjects(@"30123456", metadata.fixedLine.exampleNumber);
        XCTAssertEqualObjects(@"\\d{10}", metadata.tollFree.possibleNumberPattern);
        XCTAssertEqualObjects(@"900([135]\\d{6}|9\\d{7})", metadata.premiumRate.nationalNumberPattern);
    }


    #pragma mark - testGetInstanceLoadARMetadata
    {
        NBPhoneMetaData *metadata = [helper getMetadataForRegion:@"AR"];
        XCTAssertEqualObjects(@"AR", metadata.codeID);
        XCTAssertEqualObjects(@54, metadata.countryCode);
        XCTAssertEqualObjects(@"00", metadata.internationalPrefix);
        XCTAssertEqualObjects(@"0", metadata.nationalPrefix);
        XCTAssertEqualObjects(@"0(?:(11|343|3715)15)?", metadata.nationalPrefixForParsing);
        XCTAssertEqualObjects(@"9$1", metadata.nationalPrefixTransformRule);
        XCTAssertEqualObjects(@"$2 15 $3-$4", ((NBNumberFormat*)metadata.numberFormats[2]).format);
        XCTAssertEqualObjects(@"(9)(\\d{4})(\\d{2})(\\d{4})", ((NBNumberFormat*)metadata.numberFormats[3]).pattern);
        XCTAssertEqualObjects(@"(9)(\\d{4})(\\d{2})(\\d{4})", ((NBNumberFormat*)metadata.intlNumberFormats[3]).pattern);
        XCTAssertEqualObjects(@"$1 $2 $3 $4", ((NBNumberFormat*)metadata.intlNumberFormats[3]).format);
    }


    #pragma mark - testGetInstanceLoadInternationalTollFreeMetadata
    {
        NBPhoneMetaData *metadata = [helper getMetadataForNonGeographicalRegion:@800];
        XCTAssertEqualObjects(@"001", metadata.codeID);
        XCTAssertEqualObjects(@800, metadata.countryCode);
        XCTAssertEqualObjects(@"$1 $2", ((NBNumberFormat*)metadata.numberFormats[0]).format);
        XCTAssertEqualObjects(@"(\\d{4})(\\d{4})", ((NBNumberFormat*)metadata.numberFormats[0]).pattern);
        XCTAssertEqualObjects(@"12345678", metadata.generalDesc.exampleNumber);
        XCTAssertEqualObjects(@"12345678", metadata.tollFree.exampleNumber);
    }
                                                                

    #pragma mark - testIsNumberGeographical
    {
        // Bahamas, mobile phone number.
        XCTAssertFalse([_aUtil isNumberGeographical:BS_MOBILE]);
        // Australian fixed line number.
        XCTAssertTrue([_aUtil isNumberGeographical:AU_NUMBER]);
        // International toll free number.
        XCTAssertFalse([_aUtil isNumberGeographical:INTERNATIONAL_TOLL_FREE]);
    }
                                                                

    #pragma mark - testIsLeadingZeroPossible
    {
        // Italy
        XCTAssertTrue([_aUtil isLeadingZeroPossible:@39]);
        // USA
        XCTAssertFalse([_aUtil isLeadingZeroPossible:@1]);
        // International toll free
        XCTAssertTrue([_aUtil isLeadingZeroPossible:@800]);
        // International premium-rate
        XCTAssertFalse([_aUtil isLeadingZeroPossible:@979]);
        // Not in metadata file, just default to false.
        XCTAssertFalse([_aUtil isLeadingZeroPossible:@888]);
    }
        

    #pragma mark - testgetLengthOfGeographicalAreaCode
    {
        // Google MTV, which has area code '650'.
        XCTAssertEqual(3, [_aUtil getLengthOfGeographicalAreaCode:US_NUMBER]);
        
        // A North America toll-free number, which has no area code.
        XCTAssertEqual(0, [_aUtil getLengthOfGeographicalAreaCode:US_TOLLFREE]);
        
        // Google London, which has area code '20'.
        XCTAssertEqual(2, [_aUtil getLengthOfGeographicalAreaCode:GB_NUMBER]);
        
        // A UK mobile phone, which has no area code.
        XCTAssertEqual(0, [_aUtil getLengthOfGeographicalAreaCode:GB_MOBILE]);
        
        // Google Buenos Aires, which has area code '11'.
        XCTAssertEqual(2, [_aUtil getLengthOfGeographicalAreaCode:AR_NUMBER]);
        
        // Google Sydney, which has area code '2'.
        XCTAssertEqual(1, [_aUtil getLengthOfGeographicalAreaCode:AU_NUMBER]);
        
        // Italian numbers - there is no national prefix, but it still has an area
        // code.
        XCTAssertEqual(2, [_aUtil getLengthOfGeographicalAreaCode:IT_NUMBER]);
        
        // Google Singapore. Singapore has no area code and no national prefix.
        XCTAssertEqual(0, [_aUtil getLengthOfGeographicalAreaCode:SG_NUMBER]);
        
        // An invalid US number (1 digit shorter), which has no area code.
        XCTAssertEqual(0, [_aUtil getLengthOfGeographicalAreaCode:US_SHORT_BY_ONE_NUMBER]);
        
        // An international toll free number, which has no area code.
        XCTAssertEqual(0, [_aUtil getLengthOfGeographicalAreaCode:INTERNATIONAL_TOLL_FREE]);
    }

    
    #pragma mark - testGetLengthOfNationalDestinationCode
    {
        // Google MTV, which has national destination code (NDC) '650'.
        XCTAssertEqual(3, [_aUtil getLengthOfNationalDestinationCode:US_NUMBER]);
        
        // A North America toll-free number, which has NDC '800'.
        XCTAssertEqual(3, [_aUtil getLengthOfNationalDestinationCode:US_TOLLFREE]);
        
        // Google London, which has NDC '20'.
        XCTAssertEqual(2, [_aUtil getLengthOfNationalDestinationCode:GB_NUMBER]);
        
        // A UK mobile phone, which has NDC '7912'.
        XCTAssertEqual(4, [_aUtil getLengthOfNationalDestinationCode:GB_MOBILE]);
        
        // Google Buenos Aires, which has NDC '11'.
        XCTAssertEqual(2, [_aUtil getLengthOfNationalDestinationCode:AR_NUMBER]);
        
        // An Argentinian mobile which has NDC '911'.
        XCTAssertEqual(3, [_aUtil getLengthOfNationalDestinationCode:AR_MOBILE]);
        
        // Google Sydney, which has NDC '2'.
        XCTAssertEqual(1, [_aUtil getLengthOfNationalDestinationCode:AU_NUMBER]);
        
        // Google Singapore, which has NDC '6521'.
        XCTAssertEqual(4, [_aUtil getLengthOfNationalDestinationCode:SG_NUMBER]);
        
        // An invalid US number (1 digit shorter), which has no NDC.
        XCTAssertEqual(0,
                     [_aUtil getLengthOfNationalDestinationCode:US_SHORT_BY_ONE_NUMBER]);
        
        // A number containing an invalid country calling code, which shouldn't have
        // any NDC.
        
        NBPhoneNumber *number = [[NBPhoneNumber alloc] init];
        [number setCountryCode:@123];
        [number setNationalNumber:@6502530000];
        XCTAssertEqual(0, [_aUtil getLengthOfNationalDestinationCode:number]);
        
        // An international toll free number, which has NDC '1234'.
        XCTAssertEqual(4, [_aUtil getLengthOfNationalDestinationCode:INTERNATIONAL_TOLL_FREE]);
    }
        
    #pragma mark - testGetNationalSignificantNumber
    {
        XCTAssertEqualObjects(@"6502530000", [_aUtil getNationalSignificantNumber:US_NUMBER]);
        
        // An Italian mobile number.
        XCTAssertEqualObjects(@"345678901", [_aUtil getNationalSignificantNumber:IT_MOBILE]);
        
        // An Italian fixed line number.
        XCTAssertEqualObjects(@"0236618300", [_aUtil getNationalSignificantNumber:IT_NUMBER]);
        
        XCTAssertEqualObjects(@"12345678", [_aUtil getNationalSignificantNumber:INTERNATIONAL_TOLL_FREE]);
    }

    
    #pragma mark - testGetExampleNumber
    {
        XCTAssertTrue([DE_NUMBER isEqual:[_aUtil getExampleNumber:@"DE" error:nil]]);
        
        XCTAssertTrue([DE_NUMBER isEqual:[_aUtil getExampleNumberForType:@"DE" type:NBEPhoneNumberTypeFIXED_LINE error:nil]]);
        XCTAssertNil([_aUtil getExampleNumberForType:@"DE" type:NBEPhoneNumberTypeMOBILE error:nil]);
        // For the US, the example number is placed under general description, and
        // hence should be used for both fixed line and mobile, so neither of these
        // should return nil.
        XCTAssertNotNil([_aUtil getExampleNumberForType:@"US" type:NBEPhoneNumberTypeFIXED_LINE error:nil]);
        XCTAssertNotNil([_aUtil getExampleNumberForType:@"US" type:NBEPhoneNumberTypeMOBILE error:nil]);
        // CS is an invalid region, so we have no data for it.
        XCTAssertNil([_aUtil getExampleNumberForType:@"CS" type:NBEPhoneNumberTypeMOBILE error:nil]);
        // RegionCode 001 is reserved for supporting non-geographical country calling
        // code. We don't support getting an example number for it with this method.
        XCTAssertNil([_aUtil getExampleNumber:@"001" error:nil]);
    }

    
    #pragma mark - testexampleNumberForNonGeoEntity
    {
        XCTAssertTrue([INTERNATIONAL_TOLL_FREE isEqual:[_aUtil getExampleNumberForNonGeoEntity:@800 error:nil]]);
        XCTAssertTrue([UNIVERSAL_PREMIUM_RATE isEqual:[_aUtil getExampleNumberForNonGeoEntity:@979 error:nil]]);
    }

    
    #pragma mark - testConvertAlphaCharactersInNumber
    {
        NSString *input = @"1800-ABC-DEF";
        // Alpha chars are converted to digits; everything else is left untouched.
        
        NSString *expectedOutput = @"1800-222-333";
        XCTAssertEqualObjects(expectedOutput, [_aUtil convertAlphaCharactersInNumber:input]);
    }

    
    #pragma mark - testNormaliseRemovePunctuation
    {
        NSString *inputNumber = @"034-56&+#2\u00AD34";
        NSString *expectedOutput = @"03456234";
        XCTAssertEqualObjects(expectedOutput, [_aUtil normalizePhoneNumber:inputNumber], @"Conversion did not correctly remove punctuation");
    }

    
    #pragma mark - testNormaliseReplaceAlphaCharacters
    {
        NSString *inputNumber = @"034-I-am-HUNGRY";
        NSString *expectedOutput = @"034426486479";
        XCTAssertEqualObjects(expectedOutput, [_aUtil normalizePhoneNumber:inputNumber], @"Conversion did not correctly replace alpha characters");
    }

    
    #pragma mark - testNormaliseOtherDigits
    {
        NSString *inputNumber = @"\uFF125\u0665";
        NSString *expectedOutput = @"255";
        XCTAssertEqualObjects(expectedOutput, [_aUtil normalizePhoneNumber:inputNumber], @"Conversion did not correctly replace non-latin digits");
        // Eastern-Arabic digits.
        inputNumber = @"\u06F52\u06F0";
        expectedOutput = @"520";
        XCTAssertEqualObjects(expectedOutput, [_aUtil normalizePhoneNumber:inputNumber], @"Conversion did not correctly replace non-latin digits");
    }

    
    #pragma mark - testNormaliseStripAlphaCharacters
    {
        NSString *inputNumber = @"034-56&+a#234";
        NSString *expectedOutput = @"03456234";
        XCTAssertEqualObjects(expectedOutput, [_aUtil normalizeDigitsOnly:inputNumber], @"Conversion did not correctly remove alpha character");
    }

    
    #pragma mark - testFormatUSNumber
    {
        XCTAssertEqualObjects(@"650 253 0000", [_aUtil format:US_NUMBER numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+1 650 253 0000", [_aUtil format:US_NUMBER numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"800 253 0000", [_aUtil format:US_TOLLFREE numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+1 800 253 0000", [_aUtil format:US_TOLLFREE numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"900 253 0000", [_aUtil format:US_PREMIUM numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+1 900 253 0000", [_aUtil format:US_PREMIUM numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"tel:+1-900-253-0000", [_aUtil format:US_PREMIUM numberFormat:NBEPhoneNumberFormatRFC3966]);
        // Numbers with all zeros in the national number part will be formatted by
        // using the raw_input if that is available no matter which format is
        // specified.
        XCTAssertEqualObjects(@"000-000-0000", [_aUtil format:US_SPOOF_WITH_RAW_INPUT numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"0", [_aUtil format:US_SPOOF numberFormat:NBEPhoneNumberFormatNATIONAL]);
    }

    
    #pragma mark - testFormatBSNumber
    {
        XCTAssertEqualObjects(@"242 365 1234", [_aUtil format:BS_NUMBER numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+1 242 365 1234", [_aUtil format:BS_NUMBER numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
    }
    

    #pragma mark - testFormatGBNumber
    {
        XCTAssertEqualObjects(@"(020) 7031 3000", [_aUtil format:GB_NUMBER numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+44 20 7031 3000", [_aUtil format:GB_NUMBER numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"(07912) 345 678", [_aUtil format:GB_MOBILE numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+44 7912 345 678", [_aUtil format:GB_MOBILE numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
    }
    

    #pragma mark - testFormatDENumber
    {
        id deNumber = [[NBPhoneNumber alloc] init];
        [deNumber setCountryCode:@49];
        [deNumber setNationalNumber:@301234];
        XCTAssertEqualObjects(@"030/1234", [_aUtil format:deNumber numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+49 30/1234", [_aUtil format:deNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"tel:+49-30-1234", [_aUtil format:deNumber numberFormat:NBEPhoneNumberFormatRFC3966]);
        
        deNumber = [[NBPhoneNumber alloc] init];
        [deNumber setCountryCode:@49];
        [deNumber setNationalNumber:@291123];
        XCTAssertEqualObjects(@"0291 123", [_aUtil format:deNumber numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+49 291 123", [_aUtil format:deNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        
        deNumber = [[NBPhoneNumber alloc] init];
        [deNumber setCountryCode:@49];
        [deNumber setNationalNumber:@29112345678];
        XCTAssertEqualObjects(@"0291 12345678", [_aUtil format:deNumber numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+49 291 12345678", [_aUtil format:deNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        
        deNumber = [[NBPhoneNumber alloc] init];
        [deNumber setCountryCode:@49];
        [deNumber setNationalNumber:@912312345];
        XCTAssertEqualObjects(@"09123 12345", [_aUtil format:deNumber numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+49 9123 12345", [_aUtil format:deNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        
        deNumber = [[NBPhoneNumber alloc] init];
        [deNumber setCountryCode:@49];
        [deNumber setNationalNumber:@80212345];
        XCTAssertEqualObjects(@"08021 2345", [_aUtil format:deNumber numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+49 8021 2345", [_aUtil format:deNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        
        // Note this number is correctly formatted without national prefix. Most of
        // the numbers that are treated as invalid numbers by the library are short
        // numbers, and they are usually not dialed with national prefix.
        XCTAssertEqualObjects(@"1234", [_aUtil format:DE_SHORT_NUMBER numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+49 1234", [_aUtil format:DE_SHORT_NUMBER numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        
        deNumber = [[NBPhoneNumber alloc] init];
        [deNumber setCountryCode:@49];
        [deNumber setNationalNumber:@41341234];
        XCTAssertEqualObjects(@"04134 1234", [_aUtil format:deNumber numberFormat:NBEPhoneNumberFormatNATIONAL]);
    }

    #pragma mark - testFormatITNumber
    {
        XCTAssertEqualObjects(@"02 3661 8300", [_aUtil format:IT_NUMBER numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+39 02 3661 8300", [_aUtil format:IT_NUMBER numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"+390236618300", [_aUtil format:IT_NUMBER numberFormat:NBEPhoneNumberFormatE164]);
        XCTAssertEqualObjects(@"345 678 901", [_aUtil format:IT_MOBILE numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+39 345 678 901", [_aUtil format:IT_MOBILE numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"+39345678901", [_aUtil format:IT_MOBILE numberFormat:NBEPhoneNumberFormatE164]);
    }

    #pragma mark - testFormatAUNumber
    {
        XCTAssertEqualObjects(@"02 3661 8300", [_aUtil format:AU_NUMBER numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+61 2 3661 8300", [_aUtil format:AU_NUMBER numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"+61236618300", [_aUtil format:AU_NUMBER numberFormat:NBEPhoneNumberFormatE164]);
        
        id auNumber = [[NBPhoneNumber alloc] init];
        [auNumber setCountryCode:@61];
        [auNumber setNationalNumber:@1800123456];
        XCTAssertEqualObjects(@"1800 123 456", [_aUtil format:auNumber numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+61 1800 123 456", [_aUtil format:auNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"+611800123456", [_aUtil format:auNumber numberFormat:NBEPhoneNumberFormatE164]);
    }

    #pragma mark - testFormatARNumber
    {
        XCTAssertEqualObjects(@"011 8765-4321", [_aUtil format:AR_NUMBER numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+54 11 8765-4321", [_aUtil format:AR_NUMBER numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"+541187654321", [_aUtil format:AR_NUMBER numberFormat:NBEPhoneNumberFormatE164]);
        XCTAssertEqualObjects(@"011 15 8765-4321", [_aUtil format:AR_MOBILE numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+54 9 11 8765 4321", [_aUtil format:AR_MOBILE numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"+5491187654321", [_aUtil format:AR_MOBILE numberFormat:NBEPhoneNumberFormatE164]);
    }

    #pragma mark - testFormatMXNumber
    {
        XCTAssertEqualObjects(@"045 234 567 8900", [_aUtil format:MX_MOBILE1 numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+52 1 234 567 8900", [_aUtil format:MX_MOBILE1 numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"+5212345678900", [_aUtil format:MX_MOBILE1 numberFormat:NBEPhoneNumberFormatE164]);
        XCTAssertEqualObjects(@"045 55 1234 5678", [_aUtil format:MX_MOBILE2 numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+52 1 55 1234 5678", [_aUtil format:MX_MOBILE2 numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"+5215512345678", [_aUtil format:MX_MOBILE2 numberFormat:NBEPhoneNumberFormatE164]);
        XCTAssertEqualObjects(@"01 33 1234 5678", [_aUtil format:MX_NUMBER1 numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+52 33 1234 5678", [_aUtil format:MX_NUMBER1 numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"+523312345678", [_aUtil format:MX_NUMBER1 numberFormat:NBEPhoneNumberFormatE164]);
        XCTAssertEqualObjects(@"01 821 123 4567", [_aUtil format:MX_NUMBER2 numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"+52 821 123 4567", [_aUtil format:MX_NUMBER2 numberFormat:NBEPhoneNumberFormatINTERNATIONAL]);
        XCTAssertEqualObjects(@"+528211234567", [_aUtil format:MX_NUMBER2 numberFormat:NBEPhoneNumberFormatE164]);
    }

    #pragma mark - testFormatOutOfCountryCallingNumber
    {
        XCTAssertEqualObjects(@"00 1 900 253 0000", [_aUtil formatOutOfCountryCallingNumber:US_PREMIUM regionCallingFrom:@"DE"]);
        XCTAssertEqualObjects(@"1 650 253 0000", [_aUtil formatOutOfCountryCallingNumber:US_NUMBER regionCallingFrom:@"BS"]);
        XCTAssertEqualObjects(@"00 1 650 253 0000", [_aUtil formatOutOfCountryCallingNumber:US_NUMBER regionCallingFrom:@"PL"]);
        XCTAssertEqualObjects(@"011 44 7912 345 678", [_aUtil formatOutOfCountryCallingNumber:GB_MOBILE regionCallingFrom:@"US"]);
        XCTAssertEqualObjects(@"00 49 1234", [_aUtil formatOutOfCountryCallingNumber:DE_SHORT_NUMBER regionCallingFrom:@"GB"]);
        // Note this number is correctly formatted without national prefix. Most of
        // the numbers that are treated as invalid numbers by the library are short
        // numbers, and they are usually not dialed with national prefix.
        XCTAssertEqualObjects(@"1234", [_aUtil formatOutOfCountryCallingNumber:DE_SHORT_NUMBER regionCallingFrom:@"DE"]);
        XCTAssertEqualObjects(@"011 39 02 3661 8300", [_aUtil formatOutOfCountryCallingNumber:IT_NUMBER regionCallingFrom:@"US"]);
        XCTAssertEqualObjects(@"02 3661 8300", [_aUtil formatOutOfCountryCallingNumber:IT_NUMBER regionCallingFrom:@"IT"]);
        XCTAssertEqualObjects(@"+39 02 3661 8300", [_aUtil formatOutOfCountryCallingNumber:IT_NUMBER regionCallingFrom:@"SG"]);
        XCTAssertEqualObjects(@"6521 8000", [_aUtil formatOutOfCountryCallingNumber:SG_NUMBER regionCallingFrom:@"SG"]);
        XCTAssertEqualObjects(@"011 54 9 11 8765 4321", [_aUtil formatOutOfCountryCallingNumber:AR_MOBILE regionCallingFrom:@"US"]);
        XCTAssertEqualObjects(@"011 800 1234 5678", [_aUtil formatOutOfCountryCallingNumber:INTERNATIONAL_TOLL_FREE regionCallingFrom:@"US"]);
        
        id arNumberWithExtn = [AR_MOBILE copy];
        [arNumberWithExtn setExtension:@"1234"];
        XCTAssertEqualObjects(@"011 54 9 11 8765 4321 ext. 1234", [_aUtil formatOutOfCountryCallingNumber:arNumberWithExtn regionCallingFrom:@"US"]);
        XCTAssertEqualObjects(@"0011 54 9 11 8765 4321 ext. 1234", [_aUtil formatOutOfCountryCallingNumber:arNumberWithExtn regionCallingFrom:@"AU"]);
        XCTAssertEqualObjects(@"011 15 8765-4321 ext. 1234", [_aUtil formatOutOfCountryCallingNumber:arNumberWithExtn regionCallingFrom:@"AR"]);
    }

    
    #pragma mark - testFormatOutOfCountryWithInvalidRegion
    {
        // AQ/Antarctica isn't a valid region code for phone number formatting,
        // so this falls back to intl formatting.
        XCTAssertEqualObjects(@"+1 650 253 0000", [_aUtil formatOutOfCountryCallingNumber:US_NUMBER regionCallingFrom:@"AQ"]);
        // For region code 001, the out-of-country format always turns into the
        // international format.
        XCTAssertEqualObjects(@"+1 650 253 0000", [_aUtil formatOutOfCountryCallingNumber:US_NUMBER regionCallingFrom:@"001"]);
    }
    

    #pragma mark - testFormatOutOfCountryWithPreferredIntlPrefix
    {
        // This should use 0011, since that is the preferred international prefix
        // (both 0011 and 0012 are accepted as possible international prefixes in our
        // test metadta.)
        XCTAssertEqualObjects(@"0011 39 02 3661 8300", [_aUtil formatOutOfCountryCallingNumber:IT_NUMBER regionCallingFrom:@"AU"]);
    }
    

    #pragma mark - testFormatOutOfCountryKeepingAlphaChars
    {
        id alphaNumericNumber = [[NBPhoneNumber alloc] init];
        [alphaNumericNumber setCountryCode:@1];
        [alphaNumericNumber setNationalNumber:@8007493524];
        [alphaNumericNumber setRawInput:@"1800 six-flag"];
        XCTAssertEqualObjects(@"0011 1 800 SIX-FLAG", [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"AU"]);
        
        [alphaNumericNumber setRawInput:@"1-800-SIX-flag"];
        XCTAssertEqualObjects(@"0011 1 800-SIX-FLAG", [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"AU"]);
        
        [alphaNumericNumber setRawInput:@"Call us from UK: 00 1 800 SIX-flag"];
        XCTAssertEqualObjects(@"0011 1 800 SIX-FLAG", [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"AU"]);
        
        [alphaNumericNumber setRawInput:@"800 SIX-flag"];
        XCTAssertEqualObjects(@"0011 1 800 SIX-FLAG", [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"AU"]);
        
        // Formatting from within the NANPA region.
        XCTAssertEqualObjects(@"1 800 SIX-FLAG", [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"US"]);
        XCTAssertEqualObjects(@"1 800 SIX-FLAG", [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"BS"]);
        
        // Testing that if the raw input doesn't exist, it is formatted using
        // formatOutOfCountryCallingNumber.
        [alphaNumericNumber setRawInput:nil];
        XCTAssertEqualObjects(@"00 1 800 749 3524", [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"DE"]);
        
        // Testing AU alpha number formatted from Australia.
        [alphaNumericNumber setCountryCode:@61];
        [alphaNumericNumber setNationalNumber:@827493524];
        [alphaNumericNumber setRawInput:@"+61 82749-FLAG"];
        // This number should have the national prefix fixed.
        XCTAssertEqualObjects(@"082749-FLAG", [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"AU"]);
        
        [alphaNumericNumber setRawInput:@"082749-FLAG"];
        XCTAssertEqualObjects(@"082749-FLAG", [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"AU"]);
        
        [alphaNumericNumber setNationalNumber:@18007493524];
        [alphaNumericNumber setRawInput:@"1-800-SIX-flag"];
        // This number should not have the national prefix prefixed, in accordance
        // with the override for this specific formatting rule.
        XCTAssertEqualObjects(@"1-800-SIX-FLAG", [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"AU"]);
        
        // The metadata should not be permanently changed, since we copied it before
        // modifying patterns. Here we check this.
        [alphaNumericNumber setNationalNumber:@1800749352];
        XCTAssertEqualObjects(@"1800 749 352", [_aUtil formatOutOfCountryCallingNumber:alphaNumericNumber regionCallingFrom:@"AU"]);
        
        // Testing a region with multiple international prefixes.
        XCTAssertEqualObjects(@"+61 1-800-SIX-FLAG", [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"SG"]);
        // Testing the case of calling from a non-supported region.
        XCTAssertEqualObjects(@"+61 1-800-SIX-FLAG", [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"AQ"]);
        
        // Testing the case with an invalid country calling code.
        [alphaNumericNumber setCountryCode:0];
        [alphaNumericNumber setNationalNumber:@18007493524];
        [alphaNumericNumber setRawInput:@"1-800-SIX-flag"];
        // Uses the raw input only.
        XCTAssertEqualObjects(@"1-800-SIX-flag", [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"DE"]);
        
        // Testing the case of an invalid alpha number.
        [alphaNumericNumber setCountryCode:@1];
        [alphaNumericNumber setNationalNumber:@80749];
        [alphaNumericNumber setRawInput:@"180-SIX"];
        // No country-code stripping can be done.
        XCTAssertEqualObjects(@"00 1 180-SIX", [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"DE"]);
        
        // Testing the case of calling from a non-supported region.
        [alphaNumericNumber setCountryCode:@1];
        [alphaNumericNumber setNationalNumber:@80749];
        [alphaNumericNumber setRawInput:@"180-SIX"];
        // No country-code stripping can be done since the number is invalid.
        XCTAssertEqualObjects(@"+1 180-SIX", [_aUtil formatOutOfCountryKeepingAlphaChars:alphaNumericNumber regionCallingFrom:@"AQ"]);
    }
    

    #pragma mark - testFormatWithCarrierCode()
    {
        // We only support this for AR in our test metadata, and only for mobile
        // numbers starting with certain values.
        
        NBPhoneNumber *arMobile = [[NBPhoneNumber alloc] init];
        [arMobile setCountryCode:@54];
        [arMobile setNationalNumber:@92234654321];
        XCTAssertEqualObjects(@"02234 65-4321", [_aUtil format:arMobile numberFormat:NBEPhoneNumberFormatNATIONAL]);
        // Here we force 14 as the carrier code.
        XCTAssertEqualObjects(@"02234 14 65-4321", [_aUtil formatNationalNumberWithCarrierCode:arMobile carrierCode:@"14"]);
        // Here we force the number to be shown with no carrier code.
        XCTAssertEqualObjects(@"02234 65-4321", [_aUtil formatNationalNumberWithCarrierCode:arMobile carrierCode:@""]);
        // Here the international rule is used, so no carrier code should be present.
        XCTAssertEqualObjects(@"+5492234654321", [_aUtil format:arMobile numberFormat:NBEPhoneNumberFormatE164]);
        // We don't support this for the US so there should be no change.
        XCTAssertEqualObjects(@"650 253 0000", [_aUtil formatNationalNumberWithCarrierCode:US_NUMBER carrierCode:@"15"]);
        // Invalid country code should just get the NSN.
        XCTAssertEqualObjects(@"12345", [_aUtil formatNationalNumberWithCarrierCode:UNKNOWN_COUNTRY_CODE_NO_RAW_INPUT carrierCode:@"89"]);
    }
    

    #pragma mark - testFormatWithPreferredCarrierCode
    {
        // We only support this for AR in our test metadata.
        
        NBPhoneNumber *arNumber = [[NBPhoneNumber alloc] init];
        [arNumber setCountryCode:@54];
        [arNumber setNationalNumber:@91234125678];
        // Test formatting with no preferred carrier code stored in the number itself.
        XCTAssertEqualObjects(@"01234 15 12-5678", [_aUtil formatNationalNumberWithPreferredCarrierCode:arNumber fallbackCarrierCode:@"15"]);
        XCTAssertEqualObjects(@"01234 12-5678", [_aUtil formatNationalNumberWithPreferredCarrierCode:arNumber fallbackCarrierCode:@""]);
        // Test formatting with preferred carrier code present.
        [arNumber setPreferredDomesticCarrierCode:@"19"];
        XCTAssertEqualObjects(@"01234 12-5678", [_aUtil format:arNumber numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"01234 19 12-5678", [_aUtil formatNationalNumberWithPreferredCarrierCode:arNumber fallbackCarrierCode:@"15"]);
        XCTAssertEqualObjects(@"01234 19 12-5678", [_aUtil formatNationalNumberWithPreferredCarrierCode:arNumber fallbackCarrierCode:@""]);
        // When the preferred_domestic_carrier_code is present (even when it contains
        // an empty string), use it instead of the default carrier code passed in.
        [arNumber setPreferredDomesticCarrierCode:@""];
        XCTAssertEqualObjects(@"01234 12-5678", [_aUtil formatNationalNumberWithPreferredCarrierCode:arNumber fallbackCarrierCode:@"15"]);
        // We don't support this for the US so there should be no change.
        
        NBPhoneNumber *usNumber = [[NBPhoneNumber alloc] init];
        [usNumber setCountryCode:@1];
        [usNumber setNationalNumber:@4241231234];
        [usNumber setPreferredDomesticCarrierCode:@"99"];
        XCTAssertEqualObjects(@"424 123 1234", [_aUtil format:usNumber numberFormat:NBEPhoneNumberFormatNATIONAL]);
        XCTAssertEqualObjects(@"424 123 1234", [_aUtil formatNationalNumberWithPreferredCarrierCode:usNumber fallbackCarrierCode:@"15"]);
    }
    

    #pragma mark - testFormatNumberForMobileDialing
    {
        // Numbers are normally dialed in national format in-country, and
        // international format from outside the country.
        XCTAssertEqualObjects(@"030123456", [_aUtil formatNumberForMobileDialing:DE_NUMBER regionCallingFrom:@"DE" withFormatting:NO]);
        XCTAssertEqualObjects(@"+4930123456", [_aUtil formatNumberForMobileDialing:DE_NUMBER regionCallingFrom:@"CH" withFormatting:NO]);
        id deNumberWithExtn = [DE_NUMBER copy];
        [deNumberWithExtn setExtension:@"1234"];
        XCTAssertEqualObjects(@"030123456", [_aUtil formatNumberForMobileDialing:deNumberWithExtn regionCallingFrom:@"DE" withFormatting:NO]);
        XCTAssertEqualObjects(@"+4930123456", [_aUtil formatNumberForMobileDialing:deNumberWithExtn regionCallingFrom:@"CH" withFormatting:NO]);
        
        // US toll free numbers are marked as noInternationalDialling in the test
        // metadata for testing purposes.
        XCTAssertEqualObjects(@"800 253 0000", [_aUtil formatNumberForMobileDialing:US_TOLLFREE regionCallingFrom:@"US" withFormatting:YES]);
        XCTAssertEqualObjects(@"", [_aUtil formatNumberForMobileDialing:US_TOLLFREE regionCallingFrom:@"CN" withFormatting:YES]);
        XCTAssertEqualObjects(@"+1 650 253 0000", [_aUtil formatNumberForMobileDialing:US_NUMBER regionCallingFrom:@"US" withFormatting:YES]);
        
        id usNumberWithExtn = [US_NUMBER copy];
        [usNumberWithExtn setExtension:@"1234"];
        XCTAssertEqualObjects(@"+1 650 253 0000", [_aUtil formatNumberForMobileDialing:usNumberWithExtn regionCallingFrom:@"US" withFormatting:YES]);
        XCTAssertEqualObjects(@"8002530000", [_aUtil formatNumberForMobileDialing:US_TOLLFREE regionCallingFrom:@"US" withFormatting:NO]);
        XCTAssertEqualObjects(@"", [_aUtil formatNumberForMobileDialing:US_TOLLFREE regionCallingFrom:@"CN" withFormatting:NO]);
        XCTAssertEqualObjects(@"+16502530000", [_aUtil formatNumberForMobileDialing:US_NUMBER regionCallingFrom:@"US" withFormatting:NO]);
        XCTAssertEqualObjects(@"+16502530000", [_aUtil formatNumberForMobileDialing:usNumberWithExtn regionCallingFrom:@"US" withFormatting:NO]);

        // An invalid US number, which is one digit too long.
        XCTAssertEqualObjects(@"+165025300001", [_aUtil formatNumberForMobileDialing:US_LONG_NUMBER regionCallingFrom:@"US" withFormatting:NO]);
        XCTAssertEqualObjects(@"+1 65025300001", [_aUtil formatNumberForMobileDialing:US_LONG_NUMBER regionCallingFrom:@"US" withFormatting:YES]);

        // Star numbers. In real life they appear in Israel, but we have them in JP
        // in our test metadata.
        XCTAssertEqualObjects(@"*2345", [_aUtil formatNumberForMobileDialing:JP_STAR_NUMBER regionCallingFrom:@"JP" withFormatting:NO]);
        XCTAssertEqualObjects(@"*2345", [_aUtil formatNumberForMobileDialing:JP_STAR_NUMBER regionCallingFrom:@"JP" withFormatting:YES]);
        XCTAssertEqualObjects(@"+80012345678", [_aUtil formatNumberForMobileDialing:INTERNATIONAL_TOLL_FREE regionCallingFrom:@"JP" withFormatting:NO]);
        XCTAssertEqualObjects(@"+800 1234 5678", [_aUtil formatNumberForMobileDialing:INTERNATIONAL_TOLL_FREE regionCallingFrom:@"JP" withFormatting:YES]);
        
        // UAE numbers beginning with 600 (classified as UAN) need to be dialled
        // without +971 locally.
        XCTAssertEqualObjects(@"+971600123456", [_aUtil formatNumberForMobileDialing:AE_UAN regionCallingFrom:@"JP" withFormatting:NO]);
        XCTAssertEqualObjects(@"600123456", [_aUtil formatNumberForMobileDialing:AE_UAN regionCallingFrom:@"AE" withFormatting:NO]);
        XCTAssertEqualObjects(@"+523312345678",
                             [_aUtil formatNumberForMobileDialing:MX_NUMBER1 regionCallingFrom:@"MX" withFormatting:NO]);
        XCTAssertEqualObjects(@"+523312345678",
                             [_aUtil formatNumberForMobileDialing:MX_NUMBER1 regionCallingFrom:@"US" withFormatting:NO]);
        
        // Non-geographical numbers should always be dialed in international format.
        XCTAssertEqualObjects(@"+80012345678", [_aUtil formatNumberForMobileDialing:INTERNATIONAL_TOLL_FREE regionCallingFrom:@"US" withFormatting:NO]);
        XCTAssertEqualObjects(@"+80012345678", [_aUtil formatNumberForMobileDialing:INTERNATIONAL_TOLL_FREE regionCallingFrom:@"UN001" withFormatting:NO]);

    }

    
    #pragma mark - testFormatByPattern
    {
        NBNumberFormat *newNumFormat = [[NBNumberFormat alloc] init];
        [newNumFormat setPattern:@"(\\d{3})(\\d{3})(\\d{4})"];
        [newNumFormat setFormat:@"($1) $2-$3"];
        
        XCTAssertEqualObjects(@"(650) 253-0000", [_aUtil formatByPattern:US_NUMBER numberFormat:NBEPhoneNumberFormatNATIONAL userDefinedFormats:@[newNumFormat]]);
        
        XCTAssertEqualObjects(@"+1 (650) 253-0000", [_aUtil formatByPattern:US_NUMBER numberFormat:NBEPhoneNumberFormatINTERNATIONAL userDefinedFormats:@[newNumFormat]]);
        XCTAssertEqualObjects(@"tel:+1-650-253-0000", [_aUtil formatByPattern:US_NUMBER numberFormat:NBEPhoneNumberFormatRFC3966 userDefinedFormats:@[newNumFormat]]);
        
        // $NP is set to '1' for the US. Here we check that for other NANPA countries
        // the US rules are followed.
        [newNumFormat setNationalPrefixFormattingRule:@"$NP ($FG)"];
        [newNumFormat setFormat:@"$1 $2-$3"];
        XCTAssertEqualObjects(@"1 (242) 365-1234", [_aUtil formatByPattern:BS_NUMBER numberFormat:NBEPhoneNumberFormatNATIONAL userDefinedFormats:@[newNumFormat]]);
        XCTAssertEqualObjects(@"+1 242 365-1234", [_aUtil formatByPattern:BS_NUMBER numberFormat:NBEPhoneNumberFormatINTERNATIONAL userDefinedFormats:@[newNumFormat]]);
        
        [newNumFormat setPattern:@"(\\d{2})(\\d{5})(\\d{3})"];
        [newNumFormat setFormat:@"$1-$2 $3"];
        
        XCTAssertEqualObjects(@"02-36618 300", [_aUtil formatByPattern:IT_NUMBER numberFormat:NBEPhoneNumberFormatNATIONAL userDefinedFormats:@[newNumFormat]]);
        XCTAssertEqualObjects(@"+39 02-36618 300", [_aUtil formatByPattern:IT_NUMBER numberFormat:NBEPhoneNumberFormatINTERNATIONAL userDefinedFormats:@[newNumFormat]]);
        
        [newNumFormat setNationalPrefixFormattingRule:@"$NP$FG"];
        [newNumFormat setPattern:@"(\\d{2})(\\d{4})(\\d{4})"];
        [newNumFormat setFormat:@"$1 $2 $3"];
        XCTAssertEqualObjects(@"020 7031 3000", [_aUtil formatByPattern:GB_NUMBER numberFormat:NBEPhoneNumberFormatNATIONAL userDefinedFormats:@[newNumFormat]]);
        
        [newNumFormat setNationalPrefixFormattingRule:@"($NP$FG)"];
        XCTAssertEqualObjects(@"(020) 7031 3000", [_aUtil formatByPattern:GB_NUMBER numberFormat:NBEPhoneNumberFormatNATIONAL userDefinedFormats:@[newNumFormat]]);
        
        [newNumFormat setNationalPrefixFormattingRule:@""];
        XCTAssertEqualObjects(@"20 7031 3000", [_aUtil formatByPattern:GB_NUMBER numberFormat:NBEPhoneNumberFormatNATIONAL userDefinedFormats:@[newNumFormat]]);
        XCTAssertEqualObjects(@"+44 20 7031 3000", [_aUtil formatByPattern:GB_NUMBER numberFormat:NBEPhoneNumberFormatINTERNATIONAL userDefinedFormats:@[newNumFormat]]);
    }
    

    #pragma mark - testFormatE164Number
    {
        XCTAssertEqualObjects(@"+16502530000", [_aUtil format:US_NUMBER numberFormat:NBEPhoneNumberFormatE164]);
        XCTAssertEqualObjects(@"+4930123456", [_aUtil format:DE_NUMBER numberFormat:NBEPhoneNumberFormatE164]);
        XCTAssertEqualObjects(@"+80012345678", [_aUtil format:INTERNATIONAL_TOLL_FREE numberFormat:NBEPhoneNumberFormatE164]);
    }
    

    #pragma mark - testFormatNumberWithExtension
    {
        id nzNumber = [NZ_NUMBER copy];
        [nzNumber setExtension:@"1234"];
        // Uses default extension prefix:
        XCTAssertEqualObjects(@"03-331 6005 ext. 1234", [_aUtil format:nzNumber numberFormat:NBEPhoneNumberFormatNATIONAL]);
        // Uses RFC 3966 syntax.
        XCTAssertEqualObjects(@"tel:+64-3-331-6005;ext=1234", [_aUtil format:nzNumber numberFormat:NBEPhoneNumberFormatRFC3966]);
        // Extension prefix overridden in the territory information for the US:
        
        id usNumberWithExtension = [US_NUMBER copy];
        [usNumberWithExtension setExtension:@"4567"];
        XCTAssertEqualObjects(@"650 253 0000 extn. 4567", [_aUtil format:usNumberWithExtension numberFormat:NBEPhoneNumberFormatNATIONAL]);
    }


    #pragma mark - testFormatInOriginalFormat
    {
        NSError *anError = nil;
        NBPhoneNumber *number1 = [_aUtil parseAndKeepRawInput:@"+442087654321" defaultRegion:@"GB" error:&anError];
        XCTAssertEqualObjects(@"+44 20 8765 4321", [_aUtil formatInOriginalFormat:number1 regionCallingFrom:@"GB"]);
        
        NBPhoneNumber *number2 = [_aUtil parseAndKeepRawInput:@"02087654321" defaultRegion:@"GB" error:&anError];
        XCTAssertEqualObjects(@"(020) 8765 4321", [_aUtil formatInOriginalFormat:number2 regionCallingFrom:@"GB"]);
        
        NBPhoneNumber *number3 = [_aUtil parseAndKeepRawInput:@"011442087654321" defaultRegion:@"US" error:&anError];
        XCTAssertEqualObjects(@"011 44 20 8765 4321", [_aUtil formatInOriginalFormat:number3 regionCallingFrom:@"US"]);
        
        NBPhoneNumber *number4 = [_aUtil parseAndKeepRawInput:@"442087654321" defaultRegion:@"GB" error:&anError];
        XCTAssertEqualObjects(@"44 20 8765 4321", [_aUtil formatInOriginalFormat:number4 regionCallingFrom:@"GB"]);
        
        NBPhoneNumber *number5 = [_aUtil parse:@"+442087654321" defaultRegion:@"GB" error:&anError];
        XCTAssertEqualObjects(@"(020) 8765 4321", [_aUtil formatInOriginalFormat:number5 regionCallingFrom:@"GB"]);
        
        // Invalid numbers that we have a formatting pattern for should be formatted
        // properly. Note area codes starting with 7 are intentionally excluded in
        // the test metadata for testing purposes.
        NBPhoneNumber *number6 = [_aUtil parseAndKeepRawInput:@"7345678901" defaultRegion:@"US" error:&anError];
        XCTAssertEqualObjects(@"734 567 8901", [_aUtil formatInOriginalFormat:number6 regionCallingFrom:@"US"]);
        
        // US is not a leading zero country, and the presence of the leading zero
        // leads us to format the number using raw_input.
        NBPhoneNumber *number7 = [_aUtil parseAndKeepRawInput:@"0734567 8901" defaultRegion:@"US" error:&anError];
        XCTAssertEqualObjects(@"0734567 8901", [_aUtil formatInOriginalFormat:number7 regionCallingFrom:@"US"]);
        
        // This number is valid, but we don't have a formatting pattern for it.
        // Fall back to the raw input.
        NBPhoneNumber *number8 = [_aUtil parseAndKeepRawInput:@"02-4567-8900" defaultRegion:@"KR" error:&anError];
        XCTAssertEqualObjects(@"02-4567-8900", [_aUtil formatInOriginalFormat:number8 regionCallingFrom:@"KR"]);
        
        NBPhoneNumber *number9 = [_aUtil parseAndKeepRawInput:@"01180012345678" defaultRegion:@"US" error:&anError];
        XCTAssertEqualObjects(@"011 800 1234 5678", [_aUtil formatInOriginalFormat:number9 regionCallingFrom:@"US"]);
        
        NBPhoneNumber *number10 = [_aUtil parseAndKeepRawInput:@"+80012345678" defaultRegion:@"KR" error:&anError];
        XCTAssertEqualObjects(@"+800 1234 5678", [_aUtil formatInOriginalFormat:number10 regionCallingFrom:@"KR"]);
        
        // US local numbers are formatted correctly, as we have formatting patterns
        // for them.
        NBPhoneNumber *localNumberUS = [_aUtil parseAndKeepRawInput:@"2530000" defaultRegion:@"US" error:&anError];
        XCTAssertEqualObjects(@"253 0000", [_aUtil formatInOriginalFormat:localNumberUS regionCallingFrom:@"US"]);
        
        NBPhoneNumber *numberWithNationalPrefixUS = [_aUtil parseAndKeepRawInput:@"18003456789" defaultRegion:@"US" error:&anError];
        XCTAssertEqualObjects(@"1 800 345 6789", [_aUtil formatInOriginalFormat:numberWithNationalPrefixUS regionCallingFrom:@"US"]);
        
        NBPhoneNumber *numberWithoutNationalPrefixGB = [_aUtil parseAndKeepRawInput:@"2087654321" defaultRegion:@"GB" error:&anError];
        XCTAssertEqualObjects(@"20 8765 4321", [_aUtil formatInOriginalFormat:numberWithoutNationalPrefixGB regionCallingFrom:@"GB"]);
        
        // Make sure no metadata is modified as a result of the previous function
        // call.
        XCTAssertEqualObjects(@"(020) 8765 4321", [_aUtil formatInOriginalFormat:number5 regionCallingFrom:@"GB" error:&anError]);
        
        NBPhoneNumber *numberWithNationalPrefixMX = [_aUtil parseAndKeepRawInput:@"013312345678" defaultRegion:@"MX" error:&anError];
        XCTAssertEqualObjects(@"01 33 1234 5678", [_aUtil formatInOriginalFormat:numberWithNationalPrefixMX regionCallingFrom:@"MX"]);
        
        NBPhoneNumber *numberWithoutNationalPrefixMX = [_aUtil parseAndKeepRawInput:@"3312345678" defaultRegion:@"MX" error:&anError];
        XCTAssertEqualObjects(@"33 1234 5678", [_aUtil formatInOriginalFormat:numberWithoutNationalPrefixMX regionCallingFrom:@"MX"]);
        
        NBPhoneNumber *italianFixedLineNumber = [_aUtil parseAndKeepRawInput:@"0212345678" defaultRegion:@"IT" error:&anError];
        XCTAssertEqualObjects(@"02 1234 5678", [_aUtil formatInOriginalFormat:italianFixedLineNumber regionCallingFrom:@"IT"]);
        
        NBPhoneNumber *numberWithNationalPrefixJP = [_aUtil parseAndKeepRawInput:@"00777012" defaultRegion:@"JP" error:&anError];
        XCTAssertEqualObjects(@"0077-7012", [_aUtil formatInOriginalFormat:numberWithNationalPrefixJP regionCallingFrom:@"JP"]);
        
        NBPhoneNumber *numberWithoutNationalPrefixJP = [_aUtil parseAndKeepRawInput:@"0777012" defaultRegion:@"JP" error:&anError];
        XCTAssertEqualObjects(@"0777012", [_aUtil formatInOriginalFormat:numberWithoutNationalPrefixJP regionCallingFrom:@"JP"]);
        
        NBPhoneNumber *numberWithCarrierCodeBR = [_aUtil parseAndKeepRawInput:@"012 3121286979" defaultRegion:@"BR" error:&anError];
        XCTAssertEqualObjects(@"012 3121286979", [_aUtil formatInOriginalFormat:numberWithCarrierCodeBR regionCallingFrom:@"BR"]);
        
        // The default national prefix used in this case is 045. When a number with
        // national prefix 044 is entered, we return the raw input as we don't want to
        // change the number entered.
        NBPhoneNumber *numberWithNationalPrefixMX1 = [_aUtil parseAndKeepRawInput:@"044(33)1234-5678" defaultRegion:@"MX" error:&anError];
        XCTAssertEqualObjects(@"044(33)1234-5678", [_aUtil formatInOriginalFormat:numberWithNationalPrefixMX1 regionCallingFrom:@"MX"]);
        
        NBPhoneNumber *numberWithNationalPrefixMX2 = [_aUtil parseAndKeepRawInput:@"045(33)1234-5678" defaultRegion:@"MX" error:&anError];
        XCTAssertEqualObjects(@"045 33 1234 5678", [_aUtil formatInOriginalFormat:numberWithNationalPrefixMX2 regionCallingFrom:@"MX"]);
        
        // The default international prefix used in this case is 0011. When a number
        // with international prefix 0012 is entered, we return the raw input as we
        // don't want to change the number entered.
        id outOfCountryNumberFromAU1 = [_aUtil parseAndKeepRawInput:@"0012 16502530000" defaultRegion:@"AU" error:&anError];
        XCTAssertEqualObjects(@"0012 16502530000", [_aUtil formatInOriginalFormat:outOfCountryNumberFromAU1 regionCallingFrom:@"AU"]);
        
        id outOfCountryNumberFromAU2 = [_aUtil parseAndKeepRawInput:@"0011 16502530000" defaultRegion:@"AU" error:&anError];
        XCTAssertEqualObjects(@"0011 1 650 253 0000", [_aUtil formatInOriginalFormat:outOfCountryNumberFromAU2 regionCallingFrom:@"AU"]);
        
        // Test the star sign is not removed from or added to the original input by
        // this method.
        id starNumber = [_aUtil parseAndKeepRawInput:@"*1234" defaultRegion:@"JP" error:&anError];
        XCTAssertEqualObjects(@"*1234", [_aUtil formatInOriginalFormat:starNumber regionCallingFrom:@"JP"]);
        
        NBPhoneNumber *numberWithoutStar = [_aUtil parseAndKeepRawInput:@"1234" defaultRegion:@"JP" error:&anError];
        XCTAssertEqualObjects(@"1234", [_aUtil formatInOriginalFormat:numberWithoutStar regionCallingFrom:@"JP"]);
        
        // Test an invalid national number without raw input is just formatted as the
        // national number.
        XCTAssertEqualObjects(@"650253000", [_aUtil formatInOriginalFormat:US_SHORT_BY_ONE_NUMBER regionCallingFrom:@"US"]);
    }

    #pragma mark - testIsPremiumRate
    {
        XCTAssertEqual(NBEPhoneNumberTypePREMIUM_RATE, [_aUtil getNumberType:US_PREMIUM]);
        
        NBPhoneNumber *premiumRateNumber = [[NBPhoneNumber alloc] init];
        premiumRateNumber = [[NBPhoneNumber alloc] init];
        [premiumRateNumber setCountryCode:@39];
        [premiumRateNumber setNationalNumber:@892123];
        XCTAssertEqual(NBEPhoneNumberTypePREMIUM_RATE, [_aUtil getNumberType:premiumRateNumber]);
        
        premiumRateNumber = [[NBPhoneNumber alloc] init];
        [premiumRateNumber setCountryCode:@44];
        [premiumRateNumber setNationalNumber:@9187654321];
        XCTAssertEqual(NBEPhoneNumberTypePREMIUM_RATE, [_aUtil getNumberType:premiumRateNumber]);
        
        premiumRateNumber = [[NBPhoneNumber alloc] init];
        [premiumRateNumber setCountryCode:@49];
        [premiumRateNumber setNationalNumber:@9001654321];
        XCTAssertEqual(NBEPhoneNumberTypePREMIUM_RATE, [_aUtil getNumberType:premiumRateNumber]);
        
        premiumRateNumber = [[NBPhoneNumber alloc] init];
        [premiumRateNumber setCountryCode:@49];
        [premiumRateNumber setNationalNumber:@90091234567];
        XCTAssertEqual(NBEPhoneNumberTypePREMIUM_RATE, [_aUtil getNumberType:premiumRateNumber]);
        XCTAssertEqual(NBEPhoneNumberTypePREMIUM_RATE, [_aUtil getNumberType:UNIVERSAL_PREMIUM_RATE]);
    }
    

    #pragma mark - testIsTollFree
    {
        NBPhoneNumber *tollFreeNumber = [[NBPhoneNumber alloc] init];
        
        [tollFreeNumber setCountryCode:@1];
        [tollFreeNumber setNationalNumber:@8881234567];
        XCTAssertEqual(NBEPhoneNumberTypeTOLL_FREE, [_aUtil getNumberType:tollFreeNumber]);
        
        tollFreeNumber = [[NBPhoneNumber alloc] init];
        [tollFreeNumber setCountryCode:@39];
        [tollFreeNumber setNationalNumber:@803123];
        XCTAssertEqual(NBEPhoneNumberTypeTOLL_FREE, [_aUtil getNumberType:tollFreeNumber]);
        
        tollFreeNumber = [[NBPhoneNumber alloc] init];
        [tollFreeNumber setCountryCode:@44];
        [tollFreeNumber setNationalNumber:@8012345678];
        XCTAssertEqual(NBEPhoneNumberTypeTOLL_FREE, [_aUtil getNumberType:tollFreeNumber]);
        
        tollFreeNumber = [[NBPhoneNumber alloc] init];
        [tollFreeNumber setCountryCode:@49];
        [tollFreeNumber setNationalNumber:@8001234567];
        XCTAssertEqual(NBEPhoneNumberTypeTOLL_FREE, [_aUtil getNumberType:tollFreeNumber]);
        
        XCTAssertEqual(NBEPhoneNumberTypeTOLL_FREE, [_aUtil getNumberType:INTERNATIONAL_TOLL_FREE]);
    }
    

    #pragma mark - testIsMobile
    {
        XCTAssertEqual(NBEPhoneNumberTypeMOBILE, [_aUtil getNumberType:BS_MOBILE]);
        XCTAssertEqual(NBEPhoneNumberTypeMOBILE, [_aUtil getNumberType:GB_MOBILE]);
        XCTAssertEqual(NBEPhoneNumberTypeMOBILE, [_aUtil getNumberType:IT_MOBILE]);
        XCTAssertEqual(NBEPhoneNumberTypeMOBILE, [_aUtil getNumberType:AR_MOBILE]);
        
        NBPhoneNumber *mobileNumber = [[NBPhoneNumber alloc] init];
        [mobileNumber setCountryCode:@49];
        [mobileNumber setNationalNumber:@15123456789];
        XCTAssertEqual(NBEPhoneNumberTypeMOBILE, [_aUtil getNumberType:mobileNumber]);
    }

    
    #pragma mark - testIsFixedLine
    {
        XCTAssertEqual(NBEPhoneNumberTypeFIXED_LINE, [_aUtil getNumberType:BS_NUMBER]);
        XCTAssertEqual(NBEPhoneNumberTypeFIXED_LINE, [_aUtil getNumberType:IT_NUMBER]);
        XCTAssertEqual(NBEPhoneNumberTypeFIXED_LINE, [_aUtil getNumberType:GB_NUMBER]);
        XCTAssertEqual(NBEPhoneNumberTypeFIXED_LINE, [_aUtil getNumberType:DE_NUMBER]);
    }

    
    #pragma mark - testIsFixedLineAndMobile
    {
        XCTAssertEqual(NBEPhoneNumberTypeFIXED_LINE_OR_MOBILE, [_aUtil getNumberType:US_NUMBER]);
        
        NBPhoneNumber *fixedLineAndMobileNumber = [[NBPhoneNumber alloc] init];
        [fixedLineAndMobileNumber setCountryCode:@54];
        [fixedLineAndMobileNumber setNationalNumber:@1987654321];
        XCTAssertEqual(NBEPhoneNumberTypeFIXED_LINE_OR_MOBILE, [_aUtil getNumberType:fixedLineAndMobileNumber]);
    }

    
    #pragma mark - testIsSharedCost
    {
        NBPhoneNumber *gbNumber = [[NBPhoneNumber alloc] init];
        [gbNumber setCountryCode:@44];
        [gbNumber setNationalNumber:@8431231234];
        XCTAssertEqual(NBEPhoneNumberTypeSHARED_COST, [_aUtil getNumberType:gbNumber]);
    }

    
    #pragma mark - testIsVoip
    {
        NBPhoneNumber *gbNumber = [[NBPhoneNumber alloc] init];
        [gbNumber setCountryCode:@44];
        [gbNumber setNationalNumber:@5631231234];
        XCTAssertEqual(NBEPhoneNumberTypeVOIP, [_aUtil getNumberType:gbNumber]);
    }

    
    #pragma mark - testIsPersonalNumber
    {
        NBPhoneNumber *gbNumber = [[NBPhoneNumber alloc] init];
        [gbNumber setCountryCode:@44];
        [gbNumber setNationalNumber:@7031231234];
        XCTAssertEqual(NBEPhoneNumberTypePERSONAL_NUMBER, [_aUtil getNumberType:gbNumber]);
    }
    

    #pragma mark - testIsUnknown
    {
        // Invalid numbers should be of type UNKNOWN.
        XCTAssertEqual(NBEPhoneNumberTypeUNKNOWN, [_aUtil getNumberType:US_LOCAL_NUMBER]);
    }
    

    #pragma mark - testisValidNumber
    {
        XCTAssertTrue([_aUtil isValidNumber:US_NUMBER]);
        XCTAssertTrue([_aUtil isValidNumber:IT_NUMBER]);
        XCTAssertTrue([_aUtil isValidNumber:GB_MOBILE]);
        XCTAssertTrue([_aUtil isValidNumber:INTERNATIONAL_TOLL_FREE]);
        XCTAssertTrue([_aUtil isValidNumber:UNIVERSAL_PREMIUM_RATE]);
        
        NBPhoneNumber *nzNumber = [[NBPhoneNumber alloc] init];
        [nzNumber setCountryCode:@64];
        [nzNumber setNationalNumber:@21387835];
        XCTAssertTrue([_aUtil isValidNumber:nzNumber]);
    }

    
    #pragma mark - testIsValidForRegion
    {
        // This number is valid for the Bahamas, but is not a valid US number.
        XCTAssertTrue([_aUtil isValidNumber:BS_NUMBER]);
        XCTAssertTrue([_aUtil isValidNumberForRegion:BS_NUMBER regionCode:@"BS"]);
        XCTAssertFalse([_aUtil isValidNumberForRegion:BS_NUMBER regionCode:@"US"]);
        
        NBPhoneNumber *bsInvalidNumber = [[NBPhoneNumber alloc] init];
        [bsInvalidNumber setCountryCode:@1];
        [bsInvalidNumber setNationalNumber:@2421232345];
        // This number is no longer valid.
        XCTAssertFalse([_aUtil isValidNumber:bsInvalidNumber]);
        
        // La Mayotte and Reunion use 'leadingDigits' to differentiate them.
        
        NBPhoneNumber *reNumber = [[NBPhoneNumber alloc] init];
        [reNumber setCountryCode:@262];
        [reNumber setNationalNumber:@262123456];
        XCTAssertTrue([_aUtil isValidNumber:reNumber]);
        XCTAssertTrue([_aUtil isValidNumberForRegion:reNumber regionCode:@"RE"]);
        XCTAssertFalse([_aUtil isValidNumberForRegion:reNumber regionCode:@"YT"]);
        
        // Now change the number to be a number for La Mayotte.
        [reNumber setNationalNumber:@269601234];
        XCTAssertTrue([_aUtil isValidNumberForRegion:reNumber regionCode:@"YT"]);
        XCTAssertFalse([_aUtil isValidNumberForRegion:reNumber regionCode:@"RE"]);
        
        // This number is no longer valid for La Reunion.
        [reNumber setNationalNumber:@269123456];
        XCTAssertFalse([_aUtil isValidNumberForRegion:reNumber regionCode:@"YT"]);
        XCTAssertFalse([_aUtil isValidNumberForRegion:reNumber regionCode:@"RE"]);
        XCTAssertFalse([_aUtil isValidNumber:reNumber]);
        
        // However, it should be recognised as from La Mayotte, since it is valid for
        // this region.
        XCTAssertEqualObjects(@"YT", [_aUtil getRegionCodeForNumber:reNumber]);
        
        // This number is valid in both places.
        [reNumber setNationalNumber:@800123456];
        XCTAssertTrue([_aUtil isValidNumberForRegion:reNumber regionCode:@"YT"]);
        XCTAssertTrue([_aUtil isValidNumberForRegion:reNumber regionCode:@"RE"]);
        XCTAssertTrue([_aUtil isValidNumberForRegion:INTERNATIONAL_TOLL_FREE regionCode:@"001"]);
        XCTAssertFalse([_aUtil isValidNumberForRegion:INTERNATIONAL_TOLL_FREE regionCode:@"US"]);
        XCTAssertFalse([_aUtil isValidNumberForRegion:INTERNATIONAL_TOLL_FREE regionCode:NB_UNKNOWN_REGION]);
        
        NBPhoneNumber *invalidNumber = [[NBPhoneNumber alloc] init];
        // Invalid country calling codes.
        [invalidNumber setCountryCode:@3923];
        [invalidNumber setNationalNumber:@2366];
        XCTAssertFalse([_aUtil isValidNumberForRegion:invalidNumber regionCode:NB_UNKNOWN_REGION]);
        XCTAssertFalse([_aUtil isValidNumberForRegion:invalidNumber regionCode:@"001"]);
        [invalidNumber setCountryCode:0];
        XCTAssertFalse([_aUtil isValidNumberForRegion:invalidNumber regionCode:@"001"]);
        XCTAssertFalse([_aUtil isValidNumberForRegion:invalidNumber regionCode:NB_UNKNOWN_REGION]);
    }

    
    #pragma mark - testIsNotValidNumber
    {
        XCTAssertFalse([_aUtil isValidNumber:US_LOCAL_NUMBER]);
        
        NBPhoneNumber *invalidNumber = [[NBPhoneNumber alloc] init];
        [invalidNumber setCountryCode:@39];
        [invalidNumber setNationalNumber:@23661830000];
        [invalidNumber setItalianLeadingZero:YES];
        XCTAssertFalse([_aUtil isValidNumber:invalidNumber]);
        
        invalidNumber = [[NBPhoneNumber alloc] init];
        [invalidNumber setCountryCode:@44];
        [invalidNumber setNationalNumber:@791234567];
        XCTAssertFalse([_aUtil isValidNumber:invalidNumber]);
        
        invalidNumber = [[NBPhoneNumber alloc] init];
        [invalidNumber setCountryCode:@0];
        [invalidNumber setNationalNumber:@1234];
        XCTAssertFalse([_aUtil isValidNumber:invalidNumber]);
        
        invalidNumber = [[NBPhoneNumber alloc] init];
        [invalidNumber setCountryCode:@64];
        [invalidNumber setNationalNumber:@3316005];
        XCTAssertFalse([_aUtil isValidNumber:invalidNumber]);
        
        invalidNumber = [[NBPhoneNumber alloc] init];
        // Invalid country calling codes.
        [invalidNumber setCountryCode:@3923];
        [invalidNumber setNationalNumber:@2366];
        XCTAssertFalse([_aUtil isValidNumber:invalidNumber]);
        [invalidNumber setCountryCode:@0];
        XCTAssertFalse([_aUtil isValidNumber:invalidNumber]);
        
        XCTAssertFalse([_aUtil isValidNumber:INTERNATIONAL_TOLL_FREE_TOO_LONG]);
    }
    

    #pragma mark - testgetRegionCodeForCountryCode
    {
        XCTAssertEqualObjects(@"US", [_aUtil getRegionCodeForCountryCode:@1]);
        XCTAssertEqualObjects(@"GB", [_aUtil getRegionCodeForCountryCode:@44]);
        XCTAssertEqualObjects(@"DE", [_aUtil getRegionCodeForCountryCode:@49]);
        XCTAssertEqualObjects(@"001", [_aUtil getRegionCodeForCountryCode:@800]);
        XCTAssertEqualObjects(@"001", [_aUtil getRegionCodeForCountryCode:@979]);
    }
    

    #pragma mark - testgetRegionCodeForNumber
    {
        XCTAssertEqualObjects(@"BS", [_aUtil getRegionCodeForNumber:BS_NUMBER]);
        XCTAssertEqualObjects(@"US", [_aUtil getRegionCodeForNumber:US_NUMBER]);
        XCTAssertEqualObjects(@"GB", [_aUtil getRegionCodeForNumber:GB_MOBILE]);
        XCTAssertEqualObjects(@"001", [_aUtil getRegionCodeForNumber:INTERNATIONAL_TOLL_FREE]);
        XCTAssertEqualObjects(@"001", [_aUtil getRegionCodeForNumber:UNIVERSAL_PREMIUM_RATE]);
    }
    

    #pragma mark - testGetRegionCodesForCountryCode
    {
        NSArray *regionCodesForNANPA = [_aUtil getRegionCodesForCountryCode:@1];
        XCTAssertTrue([regionCodesForNANPA containsObject:@"US"]);
        XCTAssertTrue([regionCodesForNANPA containsObject:@"BS"]);
        XCTAssertTrue([[_aUtil getRegionCodesForCountryCode:@44] containsObject:@"GB"]);
        XCTAssertTrue([[_aUtil getRegionCodesForCountryCode:@49] containsObject:@"DE"]);
        XCTAssertTrue([[_aUtil getRegionCodesForCountryCode:@800] containsObject:@"001"]);
        // Test with invalid country calling code.
        XCTAssertTrue([[_aUtil getRegionCodesForCountryCode:@-1] count] == 0);
    }
    

    #pragma mark - testGetCountryCodeForRegion
    {
        XCTAssertEqualObjects(@1, [_aUtil getCountryCodeForRegion:@"US"]);
        XCTAssertEqualObjects(@64, [_aUtil getCountryCodeForRegion:@"NZ"]);
        XCTAssertEqualObjects(@0, [_aUtil getCountryCodeForRegion:nil]);
        XCTAssertEqualObjects(@0, [_aUtil getCountryCodeForRegion:NB_UNKNOWN_REGION]);
        XCTAssertEqualObjects(@0, [_aUtil getCountryCodeForRegion:@"001"]);
        // CS is already deprecated so the library doesn't support it.
        XCTAssertEqualObjects(@0, [_aUtil getCountryCodeForRegion:@"CS"]);
    }
    

    #pragma mark - testGetNationalDiallingPrefixForRegion
    {
        XCTAssertEqualObjects(@"1", [_aUtil getNddPrefixForRegion:@"US" stripNonDigits:NO]);

        // Test non-main country to see it gets the national dialling prefix for the
        // main country with that country calling code.
        XCTAssertEqualObjects(@"1", [_aUtil getNddPrefixForRegion:@"BS" stripNonDigits:NO]);
        XCTAssertEqualObjects(@"0", [_aUtil getNddPrefixForRegion:@"NZ" stripNonDigits:NO]);

        // Test case with non digit in the national prefix.
        XCTAssertEqualObjects(@"0~0", [_aUtil getNddPrefixForRegion:@"AO" stripNonDigits:NO]);
        XCTAssertEqualObjects(@"00", [_aUtil getNddPrefixForRegion:@"AO" stripNonDigits:YES]);

        // Test cases with invalid regions.
        XCTAssertNil([_aUtil getNddPrefixForRegion:nil stripNonDigits:NO]);
        XCTAssertNil([_aUtil getNddPrefixForRegion:NB_UNKNOWN_REGION stripNonDigits:NO]);
        XCTAssertNil([_aUtil getNddPrefixForRegion:@"001" stripNonDigits:NO]);

        // CS is already deprecated so the library doesn't support it.
        XCTAssertNil([_aUtil getNddPrefixForRegion:@"CS" stripNonDigits:NO]);
    }


    #pragma mark - testIsNANPACountry
    {
        XCTAssertTrue([_aUtil isNANPACountry:@"US"]);
        XCTAssertTrue([_aUtil isNANPACountry:@"BS"]);
        XCTAssertFalse([_aUtil isNANPACountry:@"DE"]);
        XCTAssertFalse([_aUtil isNANPACountry:NB_UNKNOWN_REGION]);
        XCTAssertFalse([_aUtil isNANPACountry:@"001"]);
        XCTAssertFalse([_aUtil isNANPACountry:nil]);
    }

    
    #pragma mark - testIsPossibleNumber
    {
        XCTAssertTrue([_aUtil isPossibleNumber:US_NUMBER]);
        XCTAssertTrue([_aUtil isPossibleNumber:US_LOCAL_NUMBER]);
        XCTAssertTrue([_aUtil isPossibleNumber:GB_NUMBER]);
        XCTAssertTrue([_aUtil isPossibleNumber:INTERNATIONAL_TOLL_FREE]);
        
        XCTAssertTrue([_aUtil isPossibleNumberString:@"+1 650 253 0000" regionDialingFrom:@"US" error:nil]);
        XCTAssertTrue([_aUtil isPossibleNumberString:@"+1 650 GOO OGLE" regionDialingFrom:@"US" error:nil]);
        XCTAssertTrue([_aUtil isPossibleNumberString:@"(650) 253-0000" regionDialingFrom:@"US" error:nil]);
        XCTAssertTrue([_aUtil isPossibleNumberString:@"253-0000" regionDialingFrom:@"US" error:nil]);
        XCTAssertTrue([_aUtil isPossibleNumberString:@"+1 650 253 0000" regionDialingFrom:@"GB" error:nil]);
        XCTAssertTrue([_aUtil isPossibleNumberString:@"+44 20 7031 3000" regionDialingFrom:@"GB" error:nil]);
        XCTAssertTrue([_aUtil isPossibleNumberString:@"(020) 7031 3000" regionDialingFrom:@"GB" error:nil]);
        XCTAssertTrue([_aUtil isPossibleNumberString:@"7031 3000" regionDialingFrom:@"GB" error:nil]);
        XCTAssertTrue([_aUtil isPossibleNumberString:@"3331 6005" regionDialingFrom:@"NZ" error:nil]);
        XCTAssertTrue([_aUtil isPossibleNumberString:@"+800 1234 5678" regionDialingFrom:@"001" error:nil]);
    }
    

    #pragma mark - testIsPossibleNumberWithReason
    {
        // National numbers for country calling code +1 that are within 7 to 10 digits
        // are possible.
        XCTAssertEqual(NBEValidationResultIS_POSSIBLE, [_aUtil isPossibleNumberWithReason:US_NUMBER]);
        XCTAssertEqual(NBEValidationResultIS_POSSIBLE, [_aUtil isPossibleNumberWithReason:US_LOCAL_NUMBER]);
        XCTAssertEqual(NBEValidationResultTOO_LONG, [_aUtil isPossibleNumberWithReason:US_LONG_NUMBER]);
        
        NBPhoneNumber *number = [[NBPhoneNumber alloc] init];
        [number setCountryCode:@0];
        [number setNationalNumber:@2530000];
        XCTAssertEqual(NBEValidationResultINVALID_COUNTRY_CODE, [_aUtil isPossibleNumberWithReason:number]);
        
        number = [[NBPhoneNumber alloc] init];
        [number setCountryCode:@1];
        [number setNationalNumber:@253000];
        XCTAssertEqual(NBEValidationResultTOO_SHORT, [_aUtil isPossibleNumberWithReason:number]);
        
        number = [[NBPhoneNumber alloc] init];
        [number setCountryCode:@65];
        [number setNationalNumber:@1234567890];
        XCTAssertEqual(NBEValidationResultIS_POSSIBLE, [_aUtil isPossibleNumberWithReason:number]);
        XCTAssertEqual(NBEValidationResultTOO_LONG, [_aUtil isPossibleNumberWithReason:INTERNATIONAL_TOLL_FREE_TOO_LONG]);
        
        // Try with number that we don't have metadata for.
        
        NBPhoneNumber *adNumber = [[NBPhoneNumber alloc] init];
        [adNumber setCountryCode:@376];
        [adNumber setNationalNumber:@12345];
        XCTAssertEqual(NBEValidationResultIS_POSSIBLE, [_aUtil isPossibleNumberWithReason:adNumber]);
        
        [adNumber setCountryCode:@376];
        [adNumber setNationalNumber:@1];
        XCTAssertEqual(NBEValidationResultTOO_SHORT, [_aUtil isPossibleNumberWithReason:adNumber]);
        
        [adNumber setCountryCode:@376];
        [adNumber setNationalNumber:@12345678901234567];
        XCTAssertEqual(NBEValidationResultTOO_LONG, [_aUtil isPossibleNumberWithReason:adNumber]);
    }


    #pragma mark - testIsNotPossibleNumber
    {
        XCTAssertFalse([_aUtil isPossibleNumber:US_LONG_NUMBER]);
        XCTAssertFalse([_aUtil isPossibleNumber:INTERNATIONAL_TOLL_FREE_TOO_LONG]);
        
        NBPhoneNumber *number = [[NBPhoneNumber alloc] init];
        [number setCountryCode:@1];
        [number setNationalNumber:@253000];
        XCTAssertFalse([_aUtil isPossibleNumber:number]);
        
        number = [[NBPhoneNumber alloc] init];
        [number setCountryCode:@44];
        [number setNationalNumber:@300];
        XCTAssertFalse([_aUtil isPossibleNumber:number]);
        XCTAssertFalse([_aUtil isPossibleNumberString:@"+1 650 253 00000" regionDialingFrom:@"US" error:nil]);
        XCTAssertFalse([_aUtil isPossibleNumberString:@"(650) 253-00000" regionDialingFrom:@"US" error:nil]);
        XCTAssertFalse([_aUtil isPossibleNumberString:@"I want a Pizza" regionDialingFrom:@"US" error:nil]);
        XCTAssertFalse([_aUtil isPossibleNumberString:@"253-000" regionDialingFrom:@"US" error:nil]);
        XCTAssertFalse([_aUtil isPossibleNumberString:@"1 3000" regionDialingFrom:@"GB" error:nil]);
        XCTAssertFalse([_aUtil isPossibleNumberString:@"+44 300" regionDialingFrom:@"GB" error:nil]);
        XCTAssertFalse([_aUtil isPossibleNumberString:@"+800 1234 5678 9" regionDialingFrom:@"001" error:nil]);
    }


    #pragma mark - testTruncateTooLongNumber
    {
        // GB number 080 1234 5678, but entered with 4 extra digits at the end.
        NBPhoneNumber *tooLongNumber = [[NBPhoneNumber alloc] init];
        [tooLongNumber setCountryCode:@44];
        [tooLongNumber setNationalNumber:@80123456780123];
        
        NBPhoneNumber *validNumber = [[NBPhoneNumber alloc] init];
        [validNumber setCountryCode:@44];
        [validNumber setNationalNumber:@8012345678];
        XCTAssertTrue([_aUtil truncateTooLongNumber:tooLongNumber]);
        XCTAssertTrue([validNumber isEqual:tooLongNumber]);
        
        // IT number 022 3456 7890, but entered with 3 extra digits at the end.
        tooLongNumber = [[NBPhoneNumber alloc] init];
        [tooLongNumber setCountryCode:@39];
        [tooLongNumber setNationalNumber:@2234567890123];
        [tooLongNumber setItalianLeadingZero:YES];
                                             
        validNumber = [[NBPhoneNumber alloc] init];
        [validNumber setCountryCode:@39];
        [validNumber setNationalNumber:@2234567890];
        [validNumber setItalianLeadingZero:YES];
        XCTAssertTrue([_aUtil truncateTooLongNumber:tooLongNumber]);
        XCTAssertTrue([validNumber isEqual:tooLongNumber]);
        
        // US number 650-253-0000, but entered with one additional digit at the end.
        tooLongNumber = [US_LONG_NUMBER copy];
        XCTAssertTrue([_aUtil truncateTooLongNumber:tooLongNumber]);
        XCTAssertTrue([US_NUMBER isEqual:tooLongNumber]);
        
        tooLongNumber = [INTERNATIONAL_TOLL_FREE_TOO_LONG copy];
        XCTAssertTrue([_aUtil truncateTooLongNumber:tooLongNumber]);
        XCTAssertTrue([INTERNATIONAL_TOLL_FREE isEqual:tooLongNumber]);
        
        // Tests what happens when a valid number is passed in.
        
        NBPhoneNumber *validNumberCopy = [validNumber copy];
        XCTAssertTrue([_aUtil truncateTooLongNumber:validNumber]);
        // Tests the number is not modified.
        XCTAssertTrue([validNumber isEqual:validNumberCopy]);
        
        // Tests what happens when a number with invalid prefix is passed in.
        
        NBPhoneNumber *numberWithInvalidPrefix = [[NBPhoneNumber alloc] init];
        // The test metadata says US numbers cannot have prefix 240.
        [numberWithInvalidPrefix setCountryCode:@1];
        [numberWithInvalidPrefix setNationalNumber:@2401234567];
        
        NBPhoneNumber *invalidNumberCopy = [numberWithInvalidPrefix copy];
        XCTAssertFalse([_aUtil truncateTooLongNumber:numberWithInvalidPrefix]);
        // Tests the number is not modified.
        XCTAssertTrue([numberWithInvalidPrefix isEqual:invalidNumberCopy]);
        
        // Tests what happens when a too short number is passed in.
        
        NBPhoneNumber *tooShortNumber = [[NBPhoneNumber alloc] init];
        [tooShortNumber setCountryCode:@1];
        [tooShortNumber setNationalNumber:@1234];
        
        NBPhoneNumber *tooShortNumberCopy = [tooShortNumber copy];
        XCTAssertFalse([_aUtil truncateTooLongNumber:tooShortNumber]);
        // Tests the number is not modified.
        XCTAssertTrue([tooShortNumber isEqual:tooShortNumberCopy]);
    }
    

    #pragma mark - testIsViablePhoneNumber
    {
        NSLog(@"-------------- testIsViablePhoneNumber");
        XCTAssertFalse([_aUtil isViablePhoneNumber:@"1"]);
        // Only one or two digits before strange non-possible punctuation.
        XCTAssertFalse([_aUtil isViablePhoneNumber:@"1+1+1"]);
        XCTAssertFalse([_aUtil isViablePhoneNumber:@"80+0"]);
        // Two digits is viable.
        XCTAssertTrue([_aUtil isViablePhoneNumber:@"00"]);
        XCTAssertTrue([_aUtil isViablePhoneNumber:@"111"]);
        // Alpha numbers.
        XCTAssertTrue([_aUtil isViablePhoneNumber:@"0800-4-pizza"]);
        XCTAssertTrue([_aUtil isViablePhoneNumber:@"0800-4-PIZZA"]);
        // We need at least three digits before any alpha characters.
        XCTAssertFalse([_aUtil isViablePhoneNumber:@"08-PIZZA"]);
        XCTAssertFalse([_aUtil isViablePhoneNumber:@"8-PIZZA"]);
        XCTAssertFalse([_aUtil isViablePhoneNumber:@"12. March"]);
    }


    #pragma mark - testIsViablePhoneNumberNonAscii
    {
        NSLog(@"-------------- testIsViablePhoneNumberNonAscii");
        // Only one or two digits before possible punctuation followed by more digits.
        XCTAssertTrue([_aUtil isViablePhoneNumber:@"1\u300034"]);
        XCTAssertFalse([_aUtil isViablePhoneNumber:@"1\u30003+4"]);
        // Unicode variants of possible starting character and other allowed
        // punctuation/digits.
        XCTAssertTrue([_aUtil isViablePhoneNumber:@"\uFF081\uFF09\u30003456789"]);
        // Testing a leading + is okay.
        XCTAssertTrue([_aUtil isViablePhoneNumber:@"+1\uFF09\u30003456789"]);
    }


    #pragma mark - testExtractPossibleNumber
    {
        NSLog(@"-------------- testExtractPossibleNumber");
        // Removes preceding funky punctuation and letters but leaves the rest
        // untouched.
        XCTAssertEqualObjects(@"0800-345-600", [_aUtil extractPossibleNumber:@"Tel:0800-345-600"]);
        XCTAssertEqualObjects(@"0800 FOR PIZZA", [_aUtil extractPossibleNumber:@"Tel:0800 FOR PIZZA"]);
        // Should not remove plus sign
        XCTAssertEqualObjects(@"+800-345-600", [_aUtil extractPossibleNumber:@"Tel:+800-345-600"]);
        // Should recognise wide digits as possible start values.
        XCTAssertEqualObjects(@"\uFF10\uFF12\uFF13", [_aUtil extractPossibleNumber:@"\uFF10\uFF12\uFF13"]);
        // Dashes are not possible start values and should be removed.
        XCTAssertEqualObjects(@"\uFF11\uFF12\uFF13", [_aUtil extractPossibleNumber:@"Num-\uFF11\uFF12\uFF13"]);
        // If not possible number present, return empty string.
        XCTAssertEqualObjects(@"", [_aUtil extractPossibleNumber:@"Num-...."]);
        // Leading brackets are stripped - these are not used when parsing.
        XCTAssertEqualObjects(@"650) 253-0000", [_aUtil extractPossibleNumber:@"(650) 253-0000"]);
        
        // Trailing non-alpha-numeric characters should be removed.
        XCTAssertEqualObjects(@"650) 253-0000", [_aUtil extractPossibleNumber:@"(650) 253-0000..- .."]);
        XCTAssertEqualObjects(@"650) 253-0000", [_aUtil extractPossibleNumber:@"(650) 253-0000."]);
        // This case has a trailing RTL char.
        XCTAssertEqualObjects(@"650) 253-0000", [_aUtil extractPossibleNumber:@"(650) 253-0000\u200F"]);
    }

    
    #pragma mark - testMaybeStripNationalPrefix
    {
        NSLog(@"-------------- testMaybeStripNationalPrefix");
        NBPhoneMetaData *metadata = [[NBPhoneMetaData alloc] init];
        [metadata setNationalPrefixForParsing:@"34"];
        
        NBPhoneNumberDesc *generalDesc = [[NBPhoneNumberDesc alloc] init];
        [generalDesc setNationalNumberPattern:@"\\d{4,8}"];
        [metadata setGeneralDesc:generalDesc];
        
        NBPhoneNumber *numberToStrip = [[NBPhoneNumber alloc] init];
        [numberToStrip setRawInput:@"34356778"];
        
        NSString *strippedNumber = @"356778";
        NSString *rawInput = numberToStrip.rawInput;
        XCTAssertTrue([_aUtil maybeStripNationalPrefixAndCarrierCode:&rawInput metadata:metadata carrierCode:nil]);
        XCTAssertEqualObjects(strippedNumber, rawInput, @"Should have had national prefix stripped.");
        
        // Retry stripping - now the number should not start with the national prefix,
        // so no more stripping should occur.
        XCTAssertFalse([_aUtil maybeStripNationalPrefixAndCarrierCode:&rawInput metadata:metadata carrierCode:nil]);
        XCTAssertEqualObjects(strippedNumber, rawInput, @"Should have had no change - no national prefix present.");
                             
        // Some countries have no national prefix. Repeat test with none specified.
        [metadata setNationalPrefixForParsing:@""];
        XCTAssertFalse([_aUtil maybeStripNationalPrefixAndCarrierCode:&rawInput metadata:metadata carrierCode:nil]);
        XCTAssertEqualObjects(strippedNumber, rawInput, @"Should not strip anything with empty national prefix.");

        // If the resultant number doesn't match the national rule, it shouldn't be
        // stripped.
        [metadata setNationalPrefixForParsing:@"3"];
        numberToStrip.rawInput = @"3123";
        rawInput = numberToStrip.rawInput;
        strippedNumber = @"3123";
        XCTAssertFalse([_aUtil maybeStripNationalPrefixAndCarrierCode:&rawInput metadata:metadata carrierCode:nil]);
        XCTAssertEqualObjects(strippedNumber, rawInput, @"Should have had no change - after stripping, it would not have matched the national rule.");
        
        // Test extracting carrier selection code.
        [metadata setNationalPrefixForParsing:@"0(81)?"];
        numberToStrip.rawInput = @"08122123456";
        strippedNumber = @"22123456";
        rawInput = numberToStrip.rawInput;
        NSString *carrierCode = @"";
        XCTAssertTrue([_aUtil maybeStripNationalPrefixAndCarrierCode:&rawInput metadata:metadata carrierCode:&carrierCode]);
        XCTAssertEqualObjects(@"81", carrierCode);
        XCTAssertEqualObjects(strippedNumber, rawInput, @"Should have had national prefix and carrier code stripped.");
        
        // If there was a transform rule, check it was applied.
        [metadata setNationalPrefixTransformRule:@"5$15"];
        // Note that a capturing group is present here.
        [metadata setNationalPrefixForParsing:@"0(\\d{2})"];
        numberToStrip.rawInput = @"031123";
        rawInput = numberToStrip.rawInput;
        NSString *transformedNumber = @"5315123";
        XCTAssertTrue([_aUtil maybeStripNationalPrefixAndCarrierCode:&rawInput metadata:metadata carrierCode:nil]);
        XCTAssertEqualObjects(transformedNumber, rawInput, @"Should transform the 031 to a 5315.");
    }


    #pragma mark - testMaybeStripInternationalPrefix
    {
        NSLog(@"-------------- testMaybeStripInternationalPrefix");
        NSString *internationalPrefix = @"00[39]";
        
        NSString *numberToStripPrefix = @"0034567700-3898003";
        
        // Note the dash is removed as part of the normalization.
        NSString *strippedNumberString = @"45677003898003";
        XCTAssertEqual(NBECountryCodeSourceFROM_NUMBER_WITH_IDD, [_aUtil maybeStripInternationalPrefixAndNormalize:&numberToStripPrefix
                                                                                possibleIddPrefix:internationalPrefix]);
        XCTAssertEqualObjects(strippedNumberString, numberToStripPrefix, @"The number supplied was not stripped of its international prefix.");
        // Now the number no longer starts with an IDD prefix, so it should now report
        // FROM_DEFAULT_COUNTRY.
        XCTAssertEqual(NBECountryCodeSourceFROM_DEFAULT_COUNTRY, [_aUtil maybeStripInternationalPrefixAndNormalize:&numberToStripPrefix
                                                                                      possibleIddPrefix:internationalPrefix]);
        
        numberToStripPrefix = @"00945677003898003";
        XCTAssertEqual(NBECountryCodeSourceFROM_NUMBER_WITH_IDD, [_aUtil maybeStripInternationalPrefixAndNormalize:&numberToStripPrefix
                                                                                possibleIddPrefix:internationalPrefix]);
        XCTAssertEqualObjects(strippedNumberString, numberToStripPrefix, @"The number supplied was not stripped of its international prefix.");
        // Test it works when the international prefix is broken up by spaces.
        numberToStripPrefix = @"00 9 45677003898003";
        XCTAssertEqual(NBECountryCodeSourceFROM_NUMBER_WITH_IDD, [_aUtil maybeStripInternationalPrefixAndNormalize:&numberToStripPrefix
                                                                                possibleIddPrefix:internationalPrefix]);
        XCTAssertEqualObjects(strippedNumberString, numberToStripPrefix, @"The number supplied was not stripped of its international prefix.");
        // Now the number no longer starts with an IDD prefix, so it should now report
        // FROM_DEFAULT_COUNTRY.
        XCTAssertEqual(NBECountryCodeSourceFROM_DEFAULT_COUNTRY, [_aUtil maybeStripInternationalPrefixAndNormalize:&numberToStripPrefix
                                                                                possibleIddPrefix:internationalPrefix]);
        
        // Test the + symbol is also recognised and stripped.
        numberToStripPrefix = @"+45677003898003";
        strippedNumberString = @"45677003898003";
        XCTAssertEqual(NBECountryCodeSourceFROM_NUMBER_WITH_PLUS_SIGN, [_aUtil maybeStripInternationalPrefixAndNormalize:&numberToStripPrefix
                                                                                      possibleIddPrefix:internationalPrefix]);
        XCTAssertEqualObjects(strippedNumberString, numberToStripPrefix, @"The number supplied was not stripped of the plus symbol.");
        
        // If the number afterwards is a zero, we should not strip this - no country
        // calling code begins with 0.
        numberToStripPrefix = @"0090112-3123";
        strippedNumberString = @"00901123123";
        XCTAssertEqual(NBECountryCodeSourceFROM_DEFAULT_COUNTRY, [_aUtil maybeStripInternationalPrefixAndNormalize:&numberToStripPrefix
                                                                                possibleIddPrefix:internationalPrefix]);
        XCTAssertEqualObjects(strippedNumberString, numberToStripPrefix, @"The number supplied had a 0 after the match so should not be stripped.");
        // Here the 0 is separated by a space from the IDD.
        numberToStripPrefix = @"009 0-112-3123";
        XCTAssertEqual(NBECountryCodeSourceFROM_DEFAULT_COUNTRY, [_aUtil maybeStripInternationalPrefixAndNormalize:&numberToStripPrefix
                                                                                possibleIddPrefix:internationalPrefix]);
    }
}
@end
