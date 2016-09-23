//
//  NBPhoneMetaData.m
//  libPhoneNumber
//
//

#import "NBPhoneMetaData.h"
#import "NBPhoneNumberDesc.h"
#import "NBNumberFormat.h"


@implementation NBPhoneMetaData


- (id)init
{
    self = [super init];
    
    if (self) {
        _numberFormats = [[NSMutableArray alloc] init];
        _intlNumberFormats = [[NSMutableArray alloc] init];

        _leadingZeroPossible = NO;
        _mainCountryForCode = NO;
    }
    
    return self;
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"* codeID[%@] countryCode[%@] generalDesc[%@] fixedLine[%@] mobile[%@] tollFree[%@] premiumRate[%@] sharedCost[%@] personalNumber[%@] voip[%@] pager[%@] uan[%@] emergency[%@] voicemail[%@] noInternationalDialling[%@] internationalPrefix[%@] preferredInternationalPrefix[%@] nationalPrefix[%@] preferredExtnPrefix[%@] nationalPrefixForParsing[%@] nationalPrefixTransformRule[%@] sameMobileAndFixedLinePattern[%@] numberFormats[%@] intlNumberFormats[%@] mainCountryForCode[%@] leadingDigits[%@] leadingZeroPossible[%@]",
             _codeID, _countryCode, _generalDesc, _fixedLine, _mobile, _tollFree, _premiumRate, _sharedCost, _personalNumber, _voip, _pager, _uan, _emergency, _voicemail, _noInternationalDialling, _internationalPrefix, _preferredInternationalPrefix, _nationalPrefix, _preferredExtnPrefix, _nationalPrefixForParsing, _nationalPrefixTransformRule, _sameMobileAndFixedLinePattern?@"Y":@"N", _numberFormats, _intlNumberFormats, _mainCountryForCode?@"Y":@"N", _leadingDigits, _leadingZeroPossible?@"Y":@"N"];
}


- (id)initWithCoder:(NSCoder*)coder
{
    if (self = [super init]) {
        _generalDesc = [coder decodeObjectForKey:@"generalDesc"];
        _fixedLine = [coder decodeObjectForKey:@"fixedLine"];
        _mobile = [coder decodeObjectForKey:@"mobile"];
        _tollFree = [coder decodeObjectForKey:@"tollFree"];
        _premiumRate = [coder decodeObjectForKey:@"premiumRate"];
        _sharedCost = [coder decodeObjectForKey:@"sharedCost"];
        _personalNumber = [coder decodeObjectForKey:@"personalNumber"];
        _voip = [coder decodeObjectForKey:@"voip"];
        _pager = [coder decodeObjectForKey:@"pager"];
        _uan = [coder decodeObjectForKey:@"uan"];
        _emergency = [coder decodeObjectForKey:@"emergency"];
        _voicemail = [coder decodeObjectForKey:@"voicemail"];
        _noInternationalDialling = [coder decodeObjectForKey:@"noInternationalDialling"];
        _codeID = [coder decodeObjectForKey:@"codeID"];
        _countryCode = [coder decodeObjectForKey:@"countryCode"];
        _internationalPrefix = [coder decodeObjectForKey:@"internationalPrefix"];
        _preferredInternationalPrefix = [coder decodeObjectForKey:@"preferredInternationalPrefix"];
        _nationalPrefix = [coder decodeObjectForKey:@"nationalPrefix"];
        _preferredExtnPrefix = [coder decodeObjectForKey:@"preferredExtnPrefix"];
        _nationalPrefixForParsing = [coder decodeObjectForKey:@"nationalPrefixForParsing"];
        _nationalPrefixTransformRule = [coder decodeObjectForKey:@"nationalPrefixTransformRule"];
        _sameMobileAndFixedLinePattern = [[coder decodeObjectForKey:@"sameMobileAndFixedLinePattern"] boolValue];
        _numberFormats = [coder decodeObjectForKey:@"numberFormats"];
        _intlNumberFormats = [coder decodeObjectForKey:@"intlNumberFormats"];
        _mainCountryForCode = [[coder decodeObjectForKey:@"mainCountryForCode"] boolValue];
        _leadingDigits = [coder decodeObjectForKey:@"leadingDigits"];
        _leadingZeroPossible = [[coder decodeObjectForKey:@"leadingZeroPossible"] boolValue];
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeObject:_generalDesc forKey:@"generalDesc"];
    [coder encodeObject:_fixedLine forKey:@"fixedLine"];
    [coder encodeObject:_mobile forKey:@"mobile"];
    [coder encodeObject:_tollFree forKey:@"tollFree"];
    [coder encodeObject:_premiumRate forKey:@"premiumRate"];
    [coder encodeObject:_sharedCost forKey:@"sharedCost"];
    [coder encodeObject:_personalNumber forKey:@"personalNumber"];
    [coder encodeObject:_voip forKey:@"voip"];
    [coder encodeObject:_pager forKey:@"pager"];
    [coder encodeObject:_uan forKey:@"uan"];
    [coder encodeObject:_emergency forKey:@"emergency"];
    [coder encodeObject:_voicemail forKey:@"voicemail"];
    [coder encodeObject:_noInternationalDialling forKey:@"noInternationalDialling"];
    [coder encodeObject:_codeID forKey:@"codeID"];
    [coder encodeObject:_countryCode forKey:@"countryCode"];
    [coder encodeObject:_internationalPrefix forKey:@"internationalPrefix"];
    [coder encodeObject:_preferredInternationalPrefix forKey:@"preferredInternationalPrefix"];
    [coder encodeObject:_nationalPrefix forKey:@"nationalPrefix"];
    [coder encodeObject:_preferredExtnPrefix forKey:@"preferredExtnPrefix"];
    [coder encodeObject:_nationalPrefixForParsing forKey:@"nationalPrefixForParsing"];
    [coder encodeObject:_nationalPrefixTransformRule forKey:@"nationalPrefixTransformRule"];
    [coder encodeObject:[NSNumber numberWithBool:_sameMobileAndFixedLinePattern] forKey:@"sameMobileAndFixedLinePattern"];
    [coder encodeObject:_numberFormats forKey:@"numberFormats"];
    [coder encodeObject:_intlNumberFormats forKey:@"intlNumberFormats"];
    [coder encodeObject:[NSNumber numberWithBool:_mainCountryForCode] forKey:@"mainCountryForCode"];
    [coder encodeObject:_leadingDigits forKey:@"leadingDigits"];
    [coder encodeObject:[NSNumber numberWithBool:_leadingZeroPossible] forKey:@"leadingZeroPossible"];
}


@end
