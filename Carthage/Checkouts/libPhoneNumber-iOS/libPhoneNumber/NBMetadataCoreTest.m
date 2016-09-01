#import "NBMetadataCoreTest.h"
#import "NBPhoneNumberDefines.h"
#import "NBPhoneNumberDesc.h"

#import "NBNumberFormat.h"

@implementation NBPhoneMetadataTestAD
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"AD";
        self.countryCode = [NSNumber numberWithInteger:376];
        self.internationalPrefix = @"00";
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = nil;
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = nil;
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = YES;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = nil;
        self.leadingZeroPossible = NO;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTestBR
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"BR";
        self.countryCode = [NSNumber numberWithInteger:55];
        self.internationalPrefix = nil;
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = nil;
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = nil;
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = YES;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = nil;
        self.leadingZeroPossible = NO;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTestAU
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"[1-578]\\d{4,14}" withPossibleNumberPattern:@"\\d{5,15}" withExample:nil];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"[2378]\\d{8}" withPossibleNumberPattern:@"\\d{9}" withExample:nil];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"4\\d{8}" withPossibleNumberPattern:@"\\d{9}" withExample:nil];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"1800\\d{6}" withPossibleNumberPattern:@"\\d{10}" withExample:nil];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"190[0126]\\d{6}" withPossibleNumberPattern:@"\\d{10}" withExample:nil];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"AU";
        self.countryCode = [NSNumber numberWithInteger:61];
        self.internationalPrefix = @"001[12]";
        self.preferredInternationalPrefix = @"0011";
        self.nationalPrefix = @"0";
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = @"0";
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = NO;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];

        NSMutableArray *numberFormats0_patternArray = [[NSMutableArray alloc] init];
        [numberFormats0_patternArray addObject:@"1"];
        NBNumberFormat *numberFormats0 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{4})(\\d{3})(\\d{3})" withFormat:@"$1 $2 $3" withLeadingDigitsPatterns:numberFormats0_patternArray withNationalPrefixFormattingRule:@"$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats0];

        NSMutableArray *numberFormats1_patternArray = [[NSMutableArray alloc] init];
        [numberFormats1_patternArray addObject:@"[2-478]"];
        NBNumberFormat *numberFormats1 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{1})(\\d{4})(\\d{4})" withFormat:@"$1 $2 $3" withLeadingDigitsPatterns:numberFormats1_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats1];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = nil;
        self.leadingZeroPossible = NO;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTestBB
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"BB";
        self.countryCode = [NSNumber numberWithInteger:1];
        self.internationalPrefix = @"011";
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = nil;
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = nil;
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = YES;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = nil;
        self.leadingZeroPossible = NO;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTestAE
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"[1-9]\\d{8}" withPossibleNumberPattern:@"\\d{9}" withExample:nil];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"[1-9]\\d{8}" withPossibleNumberPattern:@"\\d{9}" withExample:nil];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"[1-9]\\d{8}" withPossibleNumberPattern:@"\\d{9}" withExample:nil];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"600\\d{6}" withPossibleNumberPattern:@"\\d{9}" withExample:@"600123456"];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"AE";
        self.countryCode = [NSNumber numberWithInteger:971];
        self.internationalPrefix = @"00";
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = nil;
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = nil;
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = YES;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = nil;
        self.leadingZeroPossible = NO;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTestCX
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"CX";
        self.countryCode = [NSNumber numberWithInteger:61];
        self.internationalPrefix = @"00";
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = nil;
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = nil;
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = YES;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = nil;
        self.leadingZeroPossible = NO;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTestBS
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"(242|8(00|66|77|88)|900)\\d{7}" withPossibleNumberPattern:@"\\d{7,10}" withExample:nil];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"242(?:3(?:02|[236][1-9]|4[0-24-9]|5[0-68]|7[3-57]|9[2-5])|4(?:2[237]|51|64|77)|502|636|702)\\d{4}" withPossibleNumberPattern:@"\\d{7,10}" withExample:nil];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"242(357|359|457|557)\\d{4}" withPossibleNumberPattern:@"\\d{10}" withExample:nil];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"8(00|66|77|88)\\d{7}" withPossibleNumberPattern:@"\\d{10}" withExample:nil];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"900\\d{7}" withPossibleNumberPattern:@"\\d{10}" withExample:nil];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"BS";
        self.countryCode = [NSNumber numberWithInteger:1];
        self.internationalPrefix = @"011";
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = @"1";
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = @"1";
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = NO;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = nil;
        self.leadingZeroPossible = NO;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTestDE
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"\\d{4,14}" withPossibleNumberPattern:@"\\d{2,14}" withExample:nil];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"(?:[24-6]\\d{2}|3[03-9]\\d|[789](?:[1-9]\\d|0[2-9]))\\d{1,8}" withPossibleNumberPattern:@"\\d{2,14}" withExample:@"30123456"];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"1(5\\d{9}|7\\d{8}|6[02]\\d{8}|63\\d{7})" withPossibleNumberPattern:@"\\d{10,11}" withExample:nil];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"800\\d{7}" withPossibleNumberPattern:@"\\d{10}" withExample:nil];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"900([135]\\d{6}|9\\d{7})" withPossibleNumberPattern:@"\\d{10,11}" withExample:nil];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"DE";
        self.countryCode = [NSNumber numberWithInteger:49];
        self.internationalPrefix = @"00";
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = @"0";
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = @"0";
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = NO;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];

        NSMutableArray *numberFormats0_patternArray = [[NSMutableArray alloc] init];
        [numberFormats0_patternArray addObject:@"2|3[3-9]|906|[4-9][1-9]1"];
        NBNumberFormat *numberFormats0 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{3})(\\d{3,8})" withFormat:@"$1 $2" withLeadingDigitsPatterns:numberFormats0_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats0];

        NSMutableArray *numberFormats1_patternArray = [[NSMutableArray alloc] init];
        [numberFormats1_patternArray addObject:@"[34]0|[68]9"];
        NBNumberFormat *numberFormats1 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{2})(\\d{4,11})" withFormat:@"$1/$2" withLeadingDigitsPatterns:numberFormats1_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats1];

        NSMutableArray *numberFormats2_patternArray = [[NSMutableArray alloc] init];
        [numberFormats2_patternArray addObject:@"[4-9]"];
        [numberFormats2_patternArray addObject:@"[4-6]|[7-9](?:\\d[1-9]|[1-9]\\d)"];
        NBNumberFormat *numberFormats2 = [[NBNumberFormat alloc] initWithPattern:@"([4-9]\\d)(\\d{2})" withFormat:@"$1 $2" withLeadingDigitsPatterns:numberFormats2_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats2];

        NSMutableArray *numberFormats3_patternArray = [[NSMutableArray alloc] init];
        [numberFormats3_patternArray addObject:@"[4-9]"];
        [numberFormats3_patternArray addObject:@"[4-6]|[7-9](?:\\d[1-9]|[1-9]\\d)"];
        NBNumberFormat *numberFormats3 = [[NBNumberFormat alloc] initWithPattern:@"([4-9]\\d{3})(\\d{2,7})" withFormat:@"$1 $2" withLeadingDigitsPatterns:numberFormats3_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats3];

        NSMutableArray *numberFormats4_patternArray = [[NSMutableArray alloc] init];
        [numberFormats4_patternArray addObject:@"800"];
        NBNumberFormat *numberFormats4 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{3})(\\d{1})(\\d{6})" withFormat:@"$1 $2 $3" withLeadingDigitsPatterns:numberFormats4_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats4];

        NSMutableArray *numberFormats5_patternArray = [[NSMutableArray alloc] init];
        [numberFormats5_patternArray addObject:@"900"];
        NBNumberFormat *numberFormats5 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{3})(\\d{3,4})(\\d{4})" withFormat:@"$1 $2 $3" withLeadingDigitsPatterns:numberFormats5_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats5];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = nil;
        self.leadingZeroPossible = NO;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTestKR
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"[1-7]\\d{3,9}|8\\d{8}" withPossibleNumberPattern:@"\\d{4,10}" withExample:nil];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"(?:2|[34][1-3]|5[1-5]|6[1-4])(?:1\\d{2,3}|[2-9]\\d{6,7})" withPossibleNumberPattern:@"\\d{4,10}" withExample:@"22123456"];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"1[0-25-9]\\d{7,8}" withPossibleNumberPattern:@"\\d{9,10}" withExample:@"1023456789"];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"80\\d{7}" withPossibleNumberPattern:@"\\d{9}" withExample:@"801234567"];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"60[2-9]\\d{6}" withPossibleNumberPattern:@"\\d{9}" withExample:@"602345678"];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"50\\d{8}" withPossibleNumberPattern:@"\\d{10}" withExample:@"5012345678"];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"70\\d{8}" withPossibleNumberPattern:@"\\d{10}" withExample:@"7012345678"];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"KR";
        self.countryCode = [NSNumber numberWithInteger:82];
        self.internationalPrefix = @"00(?:[124-68]|[37]\\d{2})";
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = @"0";
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = @"0(8[1-46-8]|85\\d{2})?";
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = NO;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];

        NSMutableArray *numberFormats0_patternArray = [[NSMutableArray alloc] init];
        [numberFormats0_patternArray addObject:@"1(?:0|1[19]|[69]9|5[458])|[57]0"];
        [numberFormats0_patternArray addObject:@"1(?:0|1[19]|[69]9|5(?:44|59|8))|[57]0"];
        NBNumberFormat *numberFormats0 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{2})(\\d{4})(\\d{4})" withFormat:@"$1-$2-$3" withLeadingDigitsPatterns:numberFormats0_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats0];

        NSMutableArray *numberFormats1_patternArray = [[NSMutableArray alloc] init];
        [numberFormats1_patternArray addObject:@"1(?:[169][2-8]|[78]|5[1-4])|[68]0|[3-6][1-9][2-9]"];
        [numberFormats1_patternArray addObject:@"1(?:[169][2-8]|[78]|5(?:[1-3]|4[56]))|[68]0|[3-6][1-9][2-9]"];
        NBNumberFormat *numberFormats1 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{2})(\\d{3})(\\d{4})" withFormat:@"$1-$2-$3" withLeadingDigitsPatterns:numberFormats1_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats1];

        NSMutableArray *numberFormats2_patternArray = [[NSMutableArray alloc] init];
        [numberFormats2_patternArray addObject:@"131"];
        [numberFormats2_patternArray addObject:@"1312"];
        NBNumberFormat *numberFormats2 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{3})(\\d)(\\d{4})" withFormat:@"$1-$2-$3" withLeadingDigitsPatterns:numberFormats2_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats2];

        NSMutableArray *numberFormats3_patternArray = [[NSMutableArray alloc] init];
        [numberFormats3_patternArray addObject:@"131"];
        [numberFormats3_patternArray addObject:@"131[13-9]"];
        NBNumberFormat *numberFormats3 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{3})(\\d{2})(\\d{4})" withFormat:@"$1-$2-$3" withLeadingDigitsPatterns:numberFormats3_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats3];

        NSMutableArray *numberFormats4_patternArray = [[NSMutableArray alloc] init];
        [numberFormats4_patternArray addObject:@"13[2-9]"];
        NBNumberFormat *numberFormats4 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{3})(\\d{3})(\\d{4})" withFormat:@"$1-$2-$3" withLeadingDigitsPatterns:numberFormats4_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats4];

        NSMutableArray *numberFormats5_patternArray = [[NSMutableArray alloc] init];
        [numberFormats5_patternArray addObject:@"30"];
        NBNumberFormat *numberFormats5 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{2})(\\d{2})(\\d{3})(\\d{4})" withFormat:@"$1-$2-$3-$4" withLeadingDigitsPatterns:numberFormats5_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats5];

        NSMutableArray *numberFormats6_patternArray = [[NSMutableArray alloc] init];
        [numberFormats6_patternArray addObject:@"2(?:[26]|3[0-467])"];
        [numberFormats6_patternArray addObject:@"2(?:[26]|3(?:01|1[45]|2[17-9]|39|4|6[67]|7[078]))"];
        NBNumberFormat *numberFormats6 = [[NBNumberFormat alloc] initWithPattern:@"(\\d)(\\d{4})(\\d{4})" withFormat:@"$1-$2-$3" withLeadingDigitsPatterns:numberFormats6_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats6];

        NSMutableArray *numberFormats7_patternArray = [[NSMutableArray alloc] init];
        [numberFormats7_patternArray addObject:@"2(?:3[0-35-9]|[457-9])"];
        [numberFormats7_patternArray addObject:@"2(?:3(?:0[02-9]|1[0-36-9]|2[02-6]|3[0-8]|6[0-589]|7[1-69]|[589])|[457-9])"];
        NBNumberFormat *numberFormats7 = [[NBNumberFormat alloc] initWithPattern:@"(\\d)(\\d{3})(\\d{4})" withFormat:@"$1-$2-$3" withLeadingDigitsPatterns:numberFormats7_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats7];

        NSMutableArray *numberFormats8_patternArray = [[NSMutableArray alloc] init];
        [numberFormats8_patternArray addObject:@"21[0-46-9]"];
        [numberFormats8_patternArray addObject:@"21(?:[0-247-9]|3[124]|6[1269])"];
        NBNumberFormat *numberFormats8 = [[NBNumberFormat alloc] initWithPattern:@"(\\d)(\\d{3})" withFormat:@"$1-$2" withLeadingDigitsPatterns:numberFormats8_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats8];

        NSMutableArray *numberFormats9_patternArray = [[NSMutableArray alloc] init];
        [numberFormats9_patternArray addObject:@"21[36]"];
        [numberFormats9_patternArray addObject:@"21(?:3[035-9]|6[03-578])"];
        NBNumberFormat *numberFormats9 = [[NBNumberFormat alloc] initWithPattern:@"(\\d)(\\d{4})" withFormat:@"$1-$2" withLeadingDigitsPatterns:numberFormats9_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats9];

        NSMutableArray *numberFormats10_patternArray = [[NSMutableArray alloc] init];
        [numberFormats10_patternArray addObject:@"[3-6][1-9]1"];
        [numberFormats10_patternArray addObject:@"[3-6][1-9]1(?:[0-46-9])"];
        [numberFormats10_patternArray addObject:@"[3-6][1-9]1(?:[0-247-9]|3[124]|6[1269])"];
        NBNumberFormat *numberFormats10 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{2})(\\d{3})" withFormat:@"$1-$2" withLeadingDigitsPatterns:numberFormats10_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats10];

        NSMutableArray *numberFormats11_patternArray = [[NSMutableArray alloc] init];
        [numberFormats11_patternArray addObject:@"[3-6][1-9]1"];
        [numberFormats11_patternArray addObject:@"[3-6][1-9]1[36]"];
        [numberFormats11_patternArray addObject:@"[3-6][1-9]1(?:3[035-9]|6[03-578])"];
        NBNumberFormat *numberFormats11 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{2})(\\d{4})" withFormat:@"$1-$2" withLeadingDigitsPatterns:numberFormats11_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats11];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = nil;
        self.leadingZeroPossible = NO;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTestNZ
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"[289]\\d{7,9}|[3-7]\\d{7}" withPossibleNumberPattern:@"\\d{7,10}" withExample:nil];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"24099\\d{3}|(?:3[2-79]|[479][2-689]|6[235-9])\\d{6}" withPossibleNumberPattern:@"\\d{7,8}" withExample:nil];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"2(?:[027]\\d{7}|9\\d{6,7}|1(?:0\\d{5,7}|[12]\\d{5,6}|[3-9]\\d{5})|4[1-9]\\d{6}|8\\d{7,8})" withPossibleNumberPattern:@"\\d{8,10}" withExample:nil];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"800\\d{6,7}" withPossibleNumberPattern:@"\\d{9,10}" withExample:nil];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"900\\d{6,7}" withPossibleNumberPattern:@"\\d{9,10}" withExample:nil];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"NZ";
        self.countryCode = [NSNumber numberWithInteger:64];
        self.internationalPrefix = @"00";
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = @"0";
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = @"0";
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = NO;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];

        NSMutableArray *numberFormats0_patternArray = [[NSMutableArray alloc] init];
        [numberFormats0_patternArray addObject:@"24|[34679]"];
        NBNumberFormat *numberFormats0 = [[NBNumberFormat alloc] initWithPattern:@"(\\d)(\\d{3})(\\d{4})" withFormat:@"$1-$2 $3" withLeadingDigitsPatterns:numberFormats0_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats0];

        NSMutableArray *numberFormats1_patternArray = [[NSMutableArray alloc] init];
        [numberFormats1_patternArray addObject:@"2[179]"];
        NBNumberFormat *numberFormats1 = [[NBNumberFormat alloc] initWithPattern:@"(\\d)(\\d{3})(\\d{3,5})" withFormat:@"$1-$2 $3" withLeadingDigitsPatterns:numberFormats1_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats1];

        NSMutableArray *numberFormats2_patternArray = [[NSMutableArray alloc] init];
        [numberFormats2_patternArray addObject:@"[89]"];
        NBNumberFormat *numberFormats2 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{3})(\\d{3})(\\d{3,4})" withFormat:@"$1 $2 $3" withLeadingDigitsPatterns:numberFormats2_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats2];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = nil;
        self.leadingZeroPossible = NO;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTestPL
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"[1-9]\\d{8}" withPossibleNumberPattern:@"\\d{9}" withExample:nil];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"[1-9]\\d{8}" withPossibleNumberPattern:@"\\d{9}" withExample:nil];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"(?:5[01]|6[069]|7[289]|88)\\d{7}" withPossibleNumberPattern:@"\\d{9}" withExample:nil];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"800\\d{6}" withPossibleNumberPattern:@"\\d{9}" withExample:nil];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"70\\d{7}" withPossibleNumberPattern:@"\\d{9}" withExample:nil];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"PL";
        self.countryCode = [NSNumber numberWithInteger:48];
        self.internationalPrefix = @"00";
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = @"0";
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = @"0";
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = NO;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];

        NSMutableArray *numberFormats0_patternArray = [[NSMutableArray alloc] init];
        NBNumberFormat *numberFormats0 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{2})(\\d{3})(\\d{2})(\\d{2})" withFormat:@"$1 $2 $3 $4" withLeadingDigitsPatterns:numberFormats0_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats0];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = nil;
        self.leadingZeroPossible = NO;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTestSE
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"SE";
        self.countryCode = [NSNumber numberWithInteger:46];
        self.internationalPrefix = @"00";
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = nil;
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = nil;
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = YES;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = nil;
        self.leadingZeroPossible = NO;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTestCA
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"CA";
        self.countryCode = [NSNumber numberWithInteger:1];
        self.internationalPrefix = @"011";
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = nil;
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = nil;
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = YES;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = nil;
        self.leadingZeroPossible = NO;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTestAO
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"[29]\\d{8}" withPossibleNumberPattern:@"\\d{9}" withExample:nil];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"2\\d(?:[26-9]\\d|\\d[26-9])\\d{5}" withPossibleNumberPattern:@"\\d{9}" withExample:@"222123456"];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"9[1-3]\\d{7}" withPossibleNumberPattern:@"\\d{9}" withExample:@"923123456"];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"AO";
        self.countryCode = [NSNumber numberWithInteger:244];
        self.internationalPrefix = @"00";
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = @"0~0";
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = @"0~0";
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = NO;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];

        NSMutableArray *numberFormats0_patternArray = [[NSMutableArray alloc] init];
        NBNumberFormat *numberFormats0 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{3})(\\d{3})(\\d{3})" withFormat:@"$1 $2 $3" withLeadingDigitsPatterns:numberFormats0_patternArray withNationalPrefixFormattingRule:nil whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats0];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = nil;
        self.leadingZeroPossible = NO;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTest800
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"\\d{8}" withPossibleNumberPattern:@"\\d{8}" withExample:@"12345678"];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:@"12345678"];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:@"12345678"];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"\\d{8}" withPossibleNumberPattern:@"\\d{8}" withExample:@"12345678"];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"001";
        self.countryCode = [NSNumber numberWithInteger:800];
        self.internationalPrefix = nil;
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = nil;
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = nil;
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = YES;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];

        NSMutableArray *numberFormats0_patternArray = [[NSMutableArray alloc] init];
        NBNumberFormat *numberFormats0 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{4})(\\d{4})" withFormat:@"$1 $2" withLeadingDigitsPatterns:numberFormats0_patternArray withNationalPrefixFormattingRule:nil whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats0];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = nil;
        self.leadingZeroPossible = YES;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTestYT
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"[268]\\d{8}" withPossibleNumberPattern:@"\\d{9}" withExample:nil];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"2696[0-4]\\d{4}" withPossibleNumberPattern:@"\\d{9}" withExample:@"269601234"];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"639\\d{6}" withPossibleNumberPattern:@"\\d{9}" withExample:@"639123456"];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"80\\d{7}" withPossibleNumberPattern:@"\\d{9}" withExample:@"801234567"];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"YT";
        self.countryCode = [NSNumber numberWithInteger:262];
        self.internationalPrefix = @"00";
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = @"0";
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = @"0";
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = NO;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = @"269|639";
        self.leadingZeroPossible = NO;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTestFR
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"3\\d{6}" withPossibleNumberPattern:@"\\d{7}" withExample:nil];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"3\\d{6}" withPossibleNumberPattern:@"\\d{7}" withExample:nil];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"3\\d{6}" withPossibleNumberPattern:@"\\d{7}" withExample:nil];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"FR";
        self.countryCode = [NSNumber numberWithInteger:33];
        self.internationalPrefix = @"00";
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = @"0";
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = @"0";
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = YES;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];

        NSMutableArray *numberFormats0_patternArray = [[NSMutableArray alloc] init];
        [numberFormats0_patternArray addObject:@"3"];
        NBNumberFormat *numberFormats0 = [[NBNumberFormat alloc] initWithPattern:@"(\\d)(\\d{2})(\\d{2})(\\d{2})" withFormat:@"$1 $2 $3 $4" withLeadingDigitsPatterns:numberFormats0_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats0];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = nil;
        self.leadingZeroPossible = NO;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTestGG
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"GG";
        self.countryCode = [NSNumber numberWithInteger:44];
        self.internationalPrefix = nil;
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = nil;
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = nil;
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = YES;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = nil;
        self.leadingZeroPossible = NO;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTestHU
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"30\\d{7}" withPossibleNumberPattern:@"\\d{9}" withExample:nil];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"30\\d{7}" withPossibleNumberPattern:@"\\d{9}" withExample:nil];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"30\\d{7}" withPossibleNumberPattern:@"\\d{9}" withExample:nil];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"HU";
        self.countryCode = [NSNumber numberWithInteger:36];
        self.internationalPrefix = nil;
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = @"06";
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = @"06";
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = YES;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = nil;
        self.leadingZeroPossible = NO;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTestSG
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"[13689]\\d{7,10}" withPossibleNumberPattern:@"\\d{8}|\\d{10,11}" withExample:nil];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"[36]\\d{7}" withPossibleNumberPattern:@"\\d{8}" withExample:nil];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"[89]\\d{7}" withPossibleNumberPattern:@"\\d{8}" withExample:nil];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"1?800\\d{7}" withPossibleNumberPattern:@"\\d{10,11}" withExample:nil];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"1900\\d{7}" withPossibleNumberPattern:@"\\d{11}" withExample:nil];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"SG";
        self.countryCode = [NSNumber numberWithInteger:65];
        self.internationalPrefix = @"0[0-3][0-9]";
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = nil;
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = @"777777";
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = NO;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];

        NSMutableArray *numberFormats0_patternArray = [[NSMutableArray alloc] init];
        [numberFormats0_patternArray addObject:@"[369]|8[1-9]"];
        NBNumberFormat *numberFormats0 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{4})(\\d{4})" withFormat:@"$1 $2" withLeadingDigitsPatterns:numberFormats0_patternArray withNationalPrefixFormattingRule:nil whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats0];

        NSMutableArray *numberFormats1_patternArray = [[NSMutableArray alloc] init];
        [numberFormats1_patternArray addObject:@"1[89]"];
        NBNumberFormat *numberFormats1 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{4})(\\d{3})(\\d{4})" withFormat:@"$1 $2 $3" withLeadingDigitsPatterns:numberFormats1_patternArray withNationalPrefixFormattingRule:nil whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats1];

        NSMutableArray *numberFormats2_patternArray = [[NSMutableArray alloc] init];
        [numberFormats2_patternArray addObject:@"800"];
        NBNumberFormat *numberFormats2 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{3})(\\d{3})(\\d{4})" withFormat:@"$1 $2 $3" withLeadingDigitsPatterns:numberFormats2_patternArray withNationalPrefixFormattingRule:nil whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats2];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = nil;
        self.leadingZeroPossible = NO;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTestJP
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"07\\d{5}|[1-357-9]\\d{3,10}" withPossibleNumberPattern:@"\\d{4,11}" withExample:nil];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"07\\d{5}|[1-357-9]\\d{3,10}" withPossibleNumberPattern:@"\\d{4,11}" withExample:nil];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"07\\d{5}|[1-357-9]\\d{3,10}" withPossibleNumberPattern:@"\\d{4,11}" withExample:nil];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"0777[01]\\d{2}" withPossibleNumberPattern:@"\\d{7}" withExample:@"0777012"];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"[23]\\d{3}" withPossibleNumberPattern:@"\\d{4}" withExample:nil];
        self.codeID = @"JP";
        self.countryCode = [NSNumber numberWithInteger:81];
        self.internationalPrefix = @"010";
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = @"0";
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = @"0";
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = YES;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];

        NSMutableArray *numberFormats0_patternArray = [[NSMutableArray alloc] init];
        [numberFormats0_patternArray addObject:@"[57-9]0"];
        NBNumberFormat *numberFormats0 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{2})(\\d{4})(\\d{4})" withFormat:@"$1 $2 $3" withLeadingDigitsPatterns:numberFormats0_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats0];

        NSMutableArray *numberFormats1_patternArray = [[NSMutableArray alloc] init];
        [numberFormats1_patternArray addObject:@"[57-9]0"];
        NBNumberFormat *numberFormats1 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{2})(\\d{2})(\\d{3})(\\d{4})" withFormat:@"$1 $2 $3 $4" withLeadingDigitsPatterns:numberFormats1_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats1];

        NSMutableArray *numberFormats2_patternArray = [[NSMutableArray alloc] init];
        [numberFormats2_patternArray addObject:@"111|222|333"];
        [numberFormats2_patternArray addObject:@"(?:111|222|333)1"];
        [numberFormats2_patternArray addObject:@"(?:111|222|333)11"];
        NBNumberFormat *numberFormats2 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{2})(\\d{3})(\\d{4})" withFormat:@"$1 $2 $3" withLeadingDigitsPatterns:numberFormats2_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats2];

        NSMutableArray *numberFormats3_patternArray = [[NSMutableArray alloc] init];
        [numberFormats3_patternArray addObject:@"222|333"];
        [numberFormats3_patternArray addObject:@"2221|3332"];
        [numberFormats3_patternArray addObject:@"22212|3332"];
        [numberFormats3_patternArray addObject:@"222120|3332"];
        NBNumberFormat *numberFormats3 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{4})(\\d)(\\d{4})" withFormat:@"$1 $2 $3" withLeadingDigitsPatterns:numberFormats3_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats3];

        NSMutableArray *numberFormats4_patternArray = [[NSMutableArray alloc] init];
        [numberFormats4_patternArray addObject:@"[23]"];
        NBNumberFormat *numberFormats4 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{3})(\\d{2})(\\d{4})" withFormat:@"$1 $2 $3" withLeadingDigitsPatterns:numberFormats4_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats4];

        NSMutableArray *numberFormats5_patternArray = [[NSMutableArray alloc] init];
        [numberFormats5_patternArray addObject:@"077"];
        NBNumberFormat *numberFormats5 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{3})(\\d{4})" withFormat:@"$1-$2" withLeadingDigitsPatterns:numberFormats5_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats5];

        NSMutableArray *numberFormats6_patternArray = [[NSMutableArray alloc] init];
        [numberFormats6_patternArray addObject:@"[23]"];
        NBNumberFormat *numberFormats6 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{4})" withFormat:@"*$1" withLeadingDigitsPatterns:numberFormats6_patternArray withNationalPrefixFormattingRule:@"$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats6];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = nil;
        self.leadingZeroPossible = YES;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTestCC
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"CC";
        self.countryCode = [NSNumber numberWithInteger:61];
        self.internationalPrefix = nil;
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = nil;
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = nil;
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = YES;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = nil;
        self.leadingZeroPossible = NO;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTestMX
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"[1-9]\\d{9,10}" withPossibleNumberPattern:@"\\d{7,11}" withExample:nil];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"[2-9]\\d{9}" withPossibleNumberPattern:@"\\d{7,10}" withExample:nil];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"1\\d{10}" withPossibleNumberPattern:@"\\d{11}" withExample:nil];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"800\\d{7}" withPossibleNumberPattern:@"\\d{10}" withExample:nil];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"900\\d{7}" withPossibleNumberPattern:@"\\d{10}" withExample:nil];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"MX";
        self.countryCode = [NSNumber numberWithInteger:52];
        self.internationalPrefix = @"00";
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = @"01";
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = @"01|04[45](\\d{10})";
        self.nationalPrefixTransformRule = @"1$1";
        self.sameMobileAndFixedLinePattern = NO;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];

        NSMutableArray *numberFormats0_patternArray = [[NSMutableArray alloc] init];
        [numberFormats0_patternArray addObject:@"[89]00"];
        NBNumberFormat *numberFormats0 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{3})(\\d{3})(\\d{4})" withFormat:@"$1 $2 $3" withLeadingDigitsPatterns:numberFormats0_patternArray withNationalPrefixFormattingRule:@"01 $1" whenFormatting:YES withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats0];

        NSMutableArray *numberFormats1_patternArray = [[NSMutableArray alloc] init];
        [numberFormats1_patternArray addObject:@"33|55|81"];
        NBNumberFormat *numberFormats1 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{2})(\\d{4})(\\d{4})" withFormat:@"$1 $2 $3" withLeadingDigitsPatterns:numberFormats1_patternArray withNationalPrefixFormattingRule:@"01 $1" whenFormatting:YES withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats1];

        NSMutableArray *numberFormats2_patternArray = [[NSMutableArray alloc] init];
        [numberFormats2_patternArray addObject:@"[2467]|3[0-24-9]|5[0-46-9]|8[2-9]|9[1-9]"];
        NBNumberFormat *numberFormats2 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{3})(\\d{3})(\\d{4})" withFormat:@"$1 $2 $3" withLeadingDigitsPatterns:numberFormats2_patternArray withNationalPrefixFormattingRule:@"01 $1" whenFormatting:YES withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats2];

        NSMutableArray *numberFormats3_patternArray = [[NSMutableArray alloc] init];
        [numberFormats3_patternArray addObject:@"1(?:33|55|81)"];
        NBNumberFormat *numberFormats3 = [[NBNumberFormat alloc] initWithPattern:@"(1)(\\d{2})(\\d{4})(\\d{4})" withFormat:@"045 $2 $3 $4" withLeadingDigitsPatterns:numberFormats3_patternArray withNationalPrefixFormattingRule:@"$1" whenFormatting:YES withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats3];

        NSMutableArray *numberFormats4_patternArray = [[NSMutableArray alloc] init];
        [numberFormats4_patternArray addObject:@"1(?:[124579]|3[0-24-9]|5[0-46-9]|8[02-9])"];
        NBNumberFormat *numberFormats4 = [[NBNumberFormat alloc] initWithPattern:@"(1)(\\d{3})(\\d{3})(\\d{4})" withFormat:@"045 $2 $3 $4" withLeadingDigitsPatterns:numberFormats4_patternArray withNationalPrefixFormattingRule:@"$1" whenFormatting:YES withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats4];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];

        NSMutableArray *intlNumberFormats0_patternArray = [[NSMutableArray alloc] init];
        [intlNumberFormats0_patternArray addObject:@"[89]00"];
        NBNumberFormat *intlNumberFormats0 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{3})(\\d{3})(\\d{4})" withFormat:@"$1 $2 $3" withLeadingDigitsPatterns:intlNumberFormats0_patternArray withNationalPrefixFormattingRule:@"01 $1" whenFormatting:YES withDomesticCarrierCodeFormattingRule:nil];
        [intlNumberFormats_FormatArray addObject:intlNumberFormats0];

        NSMutableArray *intlNumberFormats1_patternArray = [[NSMutableArray alloc] init];
        [intlNumberFormats1_patternArray addObject:@"33|55|81"];
        NBNumberFormat *intlNumberFormats1 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{2})(\\d{4})(\\d{4})" withFormat:@"$1 $2 $3" withLeadingDigitsPatterns:intlNumberFormats1_patternArray withNationalPrefixFormattingRule:@"01 $1" whenFormatting:YES withDomesticCarrierCodeFormattingRule:nil];
        [intlNumberFormats_FormatArray addObject:intlNumberFormats1];

        NSMutableArray *intlNumberFormats2_patternArray = [[NSMutableArray alloc] init];
        [intlNumberFormats2_patternArray addObject:@"[2467]|3[0-24-9]|5[0-46-9]|8[2-9]|9[1-9]"];
        NBNumberFormat *intlNumberFormats2 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{3})(\\d{3})(\\d{4})" withFormat:@"$1 $2 $3" withLeadingDigitsPatterns:intlNumberFormats2_patternArray withNationalPrefixFormattingRule:@"01 $1" whenFormatting:YES withDomesticCarrierCodeFormattingRule:nil];
        [intlNumberFormats_FormatArray addObject:intlNumberFormats2];

        NSMutableArray *intlNumberFormats3_patternArray = [[NSMutableArray alloc] init];
        [intlNumberFormats3_patternArray addObject:@"1(?:33|55|81)"];
        NBNumberFormat *intlNumberFormats3 = [[NBNumberFormat alloc] initWithPattern:@"(1)(\\d{2})(\\d{4})(\\d{4})" withFormat:@"$1 $2 $3 $4" withLeadingDigitsPatterns:intlNumberFormats3_patternArray withNationalPrefixFormattingRule:nil whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [intlNumberFormats_FormatArray addObject:intlNumberFormats3];

        NSMutableArray *intlNumberFormats4_patternArray = [[NSMutableArray alloc] init];
        [intlNumberFormats4_patternArray addObject:@"1(?:[124579]|3[0-24-9]|5[0-46-9]|8[02-9])"];
        NBNumberFormat *intlNumberFormats4 = [[NBNumberFormat alloc] initWithPattern:@"(1)(\\d{3})(\\d{3})(\\d{4})" withFormat:@"$1 $2 $3 $4" withLeadingDigitsPatterns:intlNumberFormats4_patternArray withNationalPrefixFormattingRule:nil whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [intlNumberFormats_FormatArray addObject:intlNumberFormats4];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = nil;
        self.leadingZeroPossible = NO;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTestUS
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"[13-689]\\d{9}|2[0-35-9]\\d{8}" withPossibleNumberPattern:@"\\d{7}(?:\\d{3})?" withExample:@"1234567890"];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"[13-689]\\d{9}|2[0-35-9]\\d{8}" withPossibleNumberPattern:@"\\d{7}(?:\\d{3})?" withExample:@"1234567890"];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"[13-689]\\d{9}|2[0-35-9]\\d{8}" withPossibleNumberPattern:@"\\d{7}(?:\\d{3})?" withExample:@"1234567890"];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"8(?:00|66|77|88)\\d{7}" withPossibleNumberPattern:@"\\d{10}" withExample:@"1234567890"];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"900\\d{7}" withPossibleNumberPattern:@"\\d{10}" withExample:@"1234567890"];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"800\\d{7}" withPossibleNumberPattern:@"\\d{10}" withExample:@"1234567890"];
        self.codeID = @"US";
        self.countryCode = [NSNumber numberWithInteger:1];
        self.internationalPrefix = @"011";
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = @"1";
        self.preferredExtnPrefix = @" extn. ";
        self.nationalPrefixForParsing = @"1";
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = YES;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];

        NSMutableArray *numberFormats0_patternArray = [[NSMutableArray alloc] init];
        NBNumberFormat *numberFormats0 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{3})(\\d{4})" withFormat:@"$1 $2" withLeadingDigitsPatterns:numberFormats0_patternArray withNationalPrefixFormattingRule:nil whenFormatting:YES withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats0];

        NSMutableArray *numberFormats1_patternArray = [[NSMutableArray alloc] init];
        NBNumberFormat *numberFormats1 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{3})(\\d{3})(\\d{4})" withFormat:@"$1 $2 $3" withLeadingDigitsPatterns:numberFormats1_patternArray withNationalPrefixFormattingRule:nil whenFormatting:YES withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats1];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];

        NSMutableArray *intlNumberFormats0_patternArray = [[NSMutableArray alloc] init];
        NBNumberFormat *intlNumberFormats0 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{3})(\\d{3})(\\d{4})" withFormat:@"$1 $2 $3" withLeadingDigitsPatterns:intlNumberFormats0_patternArray withNationalPrefixFormattingRule:nil whenFormatting:YES withDomesticCarrierCodeFormattingRule:nil];
        [intlNumberFormats_FormatArray addObject:intlNumberFormats0];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = YES;
        self.leadingDigits = nil;
        self.leadingZeroPossible = NO;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTestIT
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"[0389]\\d{5,10}" withPossibleNumberPattern:@"\\d{6,11}" withExample:nil];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"0\\d{9,10}" withPossibleNumberPattern:@"\\d{10,11}" withExample:nil];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"3\\d{8,9}" withPossibleNumberPattern:@"\\d{9,10}" withExample:nil];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"80(?:0\\d{6}|3\\d{3})" withPossibleNumberPattern:@"\\d{6,9}" withExample:nil];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"89(?:2\\d{3}|9\\d{6})" withPossibleNumberPattern:@"\\d{6,9}" withExample:nil];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"IT";
        self.countryCode = [NSNumber numberWithInteger:39];
        self.internationalPrefix = @"00";
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = nil;
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = nil;
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = NO;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];

        NSMutableArray *numberFormats0_patternArray = [[NSMutableArray alloc] init];
        [numberFormats0_patternArray addObject:@"0[26]"];
        NBNumberFormat *numberFormats0 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{2})(\\d{4})(\\d{4})" withFormat:@"$1 $2 $3" withLeadingDigitsPatterns:numberFormats0_patternArray withNationalPrefixFormattingRule:nil whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats0];

        NSMutableArray *numberFormats1_patternArray = [[NSMutableArray alloc] init];
        [numberFormats1_patternArray addObject:@"0[13-57-9]"];
        NBNumberFormat *numberFormats1 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{3})(\\d{4})(\\d{3,4})" withFormat:@"$1 $2 $3" withLeadingDigitsPatterns:numberFormats1_patternArray withNationalPrefixFormattingRule:nil whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats1];

        NSMutableArray *numberFormats2_patternArray = [[NSMutableArray alloc] init];
        [numberFormats2_patternArray addObject:@"3"];
        NBNumberFormat *numberFormats2 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{3})(\\d{3})(\\d{3,4})" withFormat:@"$1 $2 $3" withLeadingDigitsPatterns:numberFormats2_patternArray withNationalPrefixFormattingRule:nil whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats2];

        NSMutableArray *numberFormats3_patternArray = [[NSMutableArray alloc] init];
        [numberFormats3_patternArray addObject:@"8"];
        NBNumberFormat *numberFormats3 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{3})(\\d{3,6})" withFormat:@"$1 $2" withLeadingDigitsPatterns:numberFormats3_patternArray withNationalPrefixFormattingRule:nil whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats3];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = nil;
        self.leadingZeroPossible = YES;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTestAR
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"[1-3689]\\d{9,10}" withPossibleNumberPattern:@"\\d{6,11}" withExample:nil];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"[1-3]\\d{9}" withPossibleNumberPattern:@"\\d{6,10}" withExample:nil];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"9\\d{10}|[1-3]\\d{9}" withPossibleNumberPattern:@"\\d{10,11}" withExample:nil];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"80\\d{8}" withPossibleNumberPattern:@"\\d{10}" withExample:nil];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"6(0\\d|10)\\d{7}" withPossibleNumberPattern:@"\\d{10}" withExample:nil];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"AR";
        self.countryCode = [NSNumber numberWithInteger:54];
        self.internationalPrefix = @"00";
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = @"0";
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = @"0(?:(11|343|3715)15)?";
        self.nationalPrefixTransformRule = @"9$1";
        self.sameMobileAndFixedLinePattern = NO;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];

        NSMutableArray *numberFormats0_patternArray = [[NSMutableArray alloc] init];
        [numberFormats0_patternArray addObject:@"11"];
        NBNumberFormat *numberFormats0 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{2})(\\d{4})(\\d{4})" withFormat:@"$1 $2-$3" withLeadingDigitsPatterns:numberFormats0_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats0];

        NSMutableArray *numberFormats1_patternArray = [[NSMutableArray alloc] init];
        [numberFormats1_patternArray addObject:@"1[02-9]|[23]"];
        NBNumberFormat *numberFormats1 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{4})(\\d{2})(\\d{4})" withFormat:@"$1 $2-$3" withLeadingDigitsPatterns:numberFormats1_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats1];

        NSMutableArray *numberFormats2_patternArray = [[NSMutableArray alloc] init];
        [numberFormats2_patternArray addObject:@"911"];
        NBNumberFormat *numberFormats2 = [[NBNumberFormat alloc] initWithPattern:@"(9)(11)(\\d{4})(\\d{4})" withFormat:@"$2 15 $3-$4" withLeadingDigitsPatterns:numberFormats2_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats2];

        NSMutableArray *numberFormats3_patternArray = [[NSMutableArray alloc] init];
        [numberFormats3_patternArray addObject:@"9(?:1[02-9]|[23])"];
        NBNumberFormat *numberFormats3 = [[NBNumberFormat alloc] initWithPattern:@"(9)(\\d{4})(\\d{2})(\\d{4})" withFormat:@"$2 $3-$4" withLeadingDigitsPatterns:numberFormats3_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:@"0$1 $CC"];
        [numberFormats_FormatArray addObject:numberFormats3];

        NSMutableArray *numberFormats4_patternArray = [[NSMutableArray alloc] init];
        [numberFormats4_patternArray addObject:@"[68]"];
        NBNumberFormat *numberFormats4 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{3})(\\d{3})(\\d{4})" withFormat:@"$1-$2-$3" withLeadingDigitsPatterns:numberFormats4_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats4];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];

        NSMutableArray *intlNumberFormats0_patternArray = [[NSMutableArray alloc] init];
        [intlNumberFormats0_patternArray addObject:@"11"];
        NBNumberFormat *intlNumberFormats0 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{2})(\\d{4})(\\d{4})" withFormat:@"$1 $2-$3" withLeadingDigitsPatterns:intlNumberFormats0_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [intlNumberFormats_FormatArray addObject:intlNumberFormats0];

        NSMutableArray *intlNumberFormats1_patternArray = [[NSMutableArray alloc] init];
        [intlNumberFormats1_patternArray addObject:@"1[02-9]|[23]"];
        NBNumberFormat *intlNumberFormats1 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{4})(\\d{2})(\\d{4})" withFormat:@"$1 $2-$3" withLeadingDigitsPatterns:intlNumberFormats1_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [intlNumberFormats_FormatArray addObject:intlNumberFormats1];

        NSMutableArray *intlNumberFormats2_patternArray = [[NSMutableArray alloc] init];
        [intlNumberFormats2_patternArray addObject:@"911"];
        NBNumberFormat *intlNumberFormats2 = [[NBNumberFormat alloc] initWithPattern:@"(9)(11)(\\d{4})(\\d{4})" withFormat:@"$1 $2 $3 $4" withLeadingDigitsPatterns:intlNumberFormats2_patternArray withNationalPrefixFormattingRule:nil whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [intlNumberFormats_FormatArray addObject:intlNumberFormats2];

        NSMutableArray *intlNumberFormats3_patternArray = [[NSMutableArray alloc] init];
        [intlNumberFormats3_patternArray addObject:@"9(?:1[02-9]|[23])"];
        NBNumberFormat *intlNumberFormats3 = [[NBNumberFormat alloc] initWithPattern:@"(9)(\\d{4})(\\d{2})(\\d{4})" withFormat:@"$1 $2 $3 $4" withLeadingDigitsPatterns:intlNumberFormats3_patternArray withNationalPrefixFormattingRule:nil whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [intlNumberFormats_FormatArray addObject:intlNumberFormats3];

        NSMutableArray *intlNumberFormats4_patternArray = [[NSMutableArray alloc] init];
        [intlNumberFormats4_patternArray addObject:@"[68]"];
        NBNumberFormat *intlNumberFormats4 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{3})(\\d{3})(\\d{4})" withFormat:@"$1-$2-$3" withLeadingDigitsPatterns:intlNumberFormats4_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [intlNumberFormats_FormatArray addObject:intlNumberFormats4];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = nil;
        self.leadingZeroPossible = NO;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTest979
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"\\d{9}" withPossibleNumberPattern:@"\\d{9}" withExample:@"123456789"];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:@"123456789"];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:@"123456789"];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"\\d{9}" withPossibleNumberPattern:@"\\d{9}" withExample:@"123456789"];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"001";
        self.countryCode = [NSNumber numberWithInteger:979];
        self.internationalPrefix = nil;
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = nil;
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = nil;
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = YES;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];

        NSMutableArray *numberFormats0_patternArray = [[NSMutableArray alloc] init];
        NBNumberFormat *numberFormats0 = [[NBNumberFormat alloc] initWithPattern:@"(\\d)(\\d{4})(\\d{4})" withFormat:@"$1 $2 $3" withLeadingDigitsPatterns:numberFormats0_patternArray withNationalPrefixFormattingRule:nil whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats0];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = nil;
        self.leadingZeroPossible = NO;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTestGB
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"\\d{10}" withPossibleNumberPattern:@"\\d{6,10}" withExample:nil];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"[1-6]\\d{9}" withPossibleNumberPattern:@"\\d{6,10}" withExample:nil];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"7[1-57-9]\\d{8}" withPossibleNumberPattern:@"\\d{10}" withExample:nil];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"80\\d{8}" withPossibleNumberPattern:@"\\d{10}" withExample:nil];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"9[018]\\d{8}" withPossibleNumberPattern:@"\\d{10}" withExample:nil];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"8(?:4[3-5]|7[0-2])\\d{7}" withPossibleNumberPattern:@"\\d{10}" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"70\\d{8}" withPossibleNumberPattern:@"\\d{10}" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"56\\d{8}" withPossibleNumberPattern:@"\\d{10}" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"76\\d{8}" withPossibleNumberPattern:@"\\d{10}" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"GB";
        self.countryCode = [NSNumber numberWithInteger:44];
        self.internationalPrefix = @"00";
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = @"0";
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = @"0";
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = NO;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];

        NSMutableArray *numberFormats0_patternArray = [[NSMutableArray alloc] init];
        [numberFormats0_patternArray addObject:@"[1-59]|[78]0"];
        NBNumberFormat *numberFormats0 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{2})(\\d{4})(\\d{4})" withFormat:@"$1 $2 $3" withLeadingDigitsPatterns:numberFormats0_patternArray withNationalPrefixFormattingRule:@"(0$1)" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats0];

        NSMutableArray *numberFormats1_patternArray = [[NSMutableArray alloc] init];
        [numberFormats1_patternArray addObject:@"6"];
        NBNumberFormat *numberFormats1 = [[NBNumberFormat alloc] initWithPattern:@"(\\d)(\\d{3})(\\d{3})(\\d{3})" withFormat:@"$1 $2 $3 $4" withLeadingDigitsPatterns:numberFormats1_patternArray withNationalPrefixFormattingRule:@"(0$1)" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats1];

        NSMutableArray *numberFormats2_patternArray = [[NSMutableArray alloc] init];
        [numberFormats2_patternArray addObject:@"7[1-57-9]"];
        NBNumberFormat *numberFormats2 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{4})(\\d{3})(\\d{3})" withFormat:@"$1 $2 $3" withLeadingDigitsPatterns:numberFormats2_patternArray withNationalPrefixFormattingRule:@"(0$1)" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats2];

        NSMutableArray *numberFormats3_patternArray = [[NSMutableArray alloc] init];
        [numberFormats3_patternArray addObject:@"8[47]"];
        NBNumberFormat *numberFormats3 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{3})(\\d{3})(\\d{4})" withFormat:@"$1 $2 $3" withLeadingDigitsPatterns:numberFormats3_patternArray withNationalPrefixFormattingRule:@"(0$1)" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats3];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = nil;
        self.leadingZeroPossible = NO;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTestBY
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"[1-9]\\d{5}" withPossibleNumberPattern:@"\\d{6}" withExample:nil];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"[1-9]\\d{5}" withPossibleNumberPattern:@"\\d{6}" withExample:@"112345"];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"[1-9]\\d{5}" withPossibleNumberPattern:@"\\d{6}" withExample:nil];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"BY";
        self.countryCode = [NSNumber numberWithInteger:375];
        self.internationalPrefix = @"810";
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = @"8";
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = @"80?|99999";
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = YES;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];

        NSMutableArray *numberFormats0_patternArray = [[NSMutableArray alloc] init];
        [numberFormats0_patternArray addObject:@"[1-8]"];
        NBNumberFormat *numberFormats0 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{4})" withFormat:@"$1" withLeadingDigitsPatterns:numberFormats0_patternArray withNationalPrefixFormattingRule:@"8 $1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats0];

        NSMutableArray *numberFormats1_patternArray = [[NSMutableArray alloc] init];
        [numberFormats1_patternArray addObject:@"[1-8]"];
        NBNumberFormat *numberFormats1 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{2})(\\d{3})" withFormat:@"$1 $2" withLeadingDigitsPatterns:numberFormats1_patternArray withNationalPrefixFormattingRule:@"8$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats1];

        NSMutableArray *numberFormats2_patternArray = [[NSMutableArray alloc] init];
        [numberFormats2_patternArray addObject:@"[1-8]"];
        NBNumberFormat *numberFormats2 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{3})(\\d{3})" withFormat:@"$1 $2" withLeadingDigitsPatterns:numberFormats2_patternArray withNationalPrefixFormattingRule:@"8 $1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats2];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = nil;
        self.leadingZeroPossible = NO;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTestCN
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"CN";
        self.countryCode = [NSNumber numberWithInteger:86];
        self.internationalPrefix = nil;
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = nil;
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = nil;
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = YES;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];

        NSMutableArray *numberFormats0_patternArray = [[NSMutableArray alloc] init];
        [numberFormats0_patternArray addObject:@"[3-9]"];
        [numberFormats0_patternArray addObject:@"[3-9]\\d{2}[19]"];
        [numberFormats0_patternArray addObject:@"[3-9]\\d{2}(?:10|95)"];
        NBNumberFormat *numberFormats0 = [[NBNumberFormat alloc] initWithPattern:@"(\\d{3})(\\d{5,6})" withFormat:@"$1 $2" withLeadingDigitsPatterns:numberFormats0_patternArray withNationalPrefixFormattingRule:@"$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:@"$CC $1"];
        [numberFormats_FormatArray addObject:numberFormats0];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = nil;
        self.leadingZeroPossible = NO;
    }
    return self;
}
@end

@implementation NBPhoneMetadataTestRE
- (id)init
{
    self = [super init];
    if (self) {
        self.generalDesc = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"[268]\\d{8}" withPossibleNumberPattern:@"\\d{9}" withExample:nil];
        self.fixedLine = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"262\\d{6}" withPossibleNumberPattern:@"\\d{9}" withExample:@"262161234"];
        self.mobile = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"6(?:9[23]|47)\\d{6}" withPossibleNumberPattern:@"\\d{9}" withExample:@"692123456"];
        self.tollFree = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"80\\d{7}" withPossibleNumberPattern:@"\\d{9}" withExample:@"801234567"];
        self.premiumRate = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"8(?:1[01]|2[0156]|84|9[0-37-9])\\d{6}" withPossibleNumberPattern:@"\\d{9}" withExample:@"810123456"];
        self.sharedCost = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.personalNumber = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.voip = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.pager = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.uan = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.emergency = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:nil withPossibleNumberPattern:nil withExample:nil];
        self.voicemail = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.noInternationalDialling = [[NBPhoneNumberDesc alloc] initWithNationalNumberPattern:@"NA" withPossibleNumberPattern:@"NA" withExample:nil];
        self.codeID = @"RE";
        self.countryCode = [NSNumber numberWithInteger:262];
        self.internationalPrefix = @"00";
        self.preferredInternationalPrefix = nil;
        self.nationalPrefix = @"0";
        self.preferredExtnPrefix = nil;
        self.nationalPrefixForParsing = @"0";
        self.nationalPrefixTransformRule = nil;
        self.sameMobileAndFixedLinePattern = NO;

        NSMutableArray *numberFormats_FormatArray = [[NSMutableArray alloc] init];

        NSMutableArray *numberFormats0_patternArray = [[NSMutableArray alloc] init];
        NBNumberFormat *numberFormats0 = [[NBNumberFormat alloc] initWithPattern:@"([268]\\d{2})(\\d{2})(\\d{2})(\\d{2})" withFormat:@"$1 $2 $3 $4" withLeadingDigitsPatterns:numberFormats0_patternArray withNationalPrefixFormattingRule:@"0$1" whenFormatting:NO withDomesticCarrierCodeFormattingRule:nil];
        [numberFormats_FormatArray addObject:numberFormats0];
        self.numberFormats = numberFormats_FormatArray;

        NSMutableArray *intlNumberFormats_FormatArray = [[NSMutableArray alloc] init];
        self.intlNumberFormats = intlNumberFormats_FormatArray;
        self.mainCountryForCode = NO;
        self.leadingDigits = @"262|6(?:9[23]|47)|8";
        self.leadingZeroPossible = NO;
    }
    return self;
}
@end

