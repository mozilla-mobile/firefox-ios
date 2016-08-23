//
//  NBPhoneNumberUtil.h
//  libPhoneNumber
//
//  Created by tabby on 2015. 2. 8..
//  Copyright (c) 2015년 ohtalk.me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NBPhoneNumberDefines.h"


@class NBPhoneMetaData, NBPhoneNumber;

@interface NBPhoneNumberUtil : NSObject

+ (NBPhoneNumberUtil*)sharedInstance;

// regular expressions
- (NSArray*)matchesByRegex:(NSString*)sourceString regex:(NSString*)pattern;
- (NSArray*)matchedStringByRegex:(NSString*)sourceString regex:(NSString*)pattern;
- (NSString*)replaceStringByRegex:(NSString*)sourceString regex:(NSString*)pattern withTemplate:(NSString*)templateString;
- (int)stringPositionByRegex:(NSString*)sourceString regex:(NSString*)pattern;

// libPhoneNumber Util functions
- (NSString*)convertAlphaCharactersInNumber:(NSString*)number;

- (NSString*)normalizePhoneNumber:(NSString*)phoneNumber;
- (NSString*)normalizeDigitsOnly:(NSString*)number;

- (BOOL)isNumberGeographical:(NBPhoneNumber*)phoneNumber;

- (NSString*)extractPossibleNumber:(NSString*)phoneNumber;
- (NSNumber*)extractCountryCode:(NSString*)fullNumber nationalNumber:(NSString**)nationalNumber;
#if TARGET_OS_IPHONE && !TARGET_OS_WATCH
- (NSString *)countryCodeByCarrier;
#endif

- (NSString*)getNddPrefixForRegion:(NSString*)regionCode stripNonDigits:(BOOL)stripNonDigits;
- (NSString*)getNationalSignificantNumber:(NBPhoneNumber*)phoneNumber;

- (NSArray *)getSupportedRegions;

- (NBEPhoneNumberType)getNumberType:(NBPhoneNumber*)phoneNumber;

- (NSNumber*)getCountryCodeForRegion:(NSString*)regionCode;

- (NSString*)getRegionCodeForCountryCode:(NSNumber*)countryCallingCode;
- (NSArray*)getRegionCodesForCountryCode:(NSNumber*)countryCallingCode;
- (NSString*)getRegionCodeForNumber:(NBPhoneNumber*)phoneNumber;

- (NBPhoneNumber*)getExampleNumber:(NSString*)regionCode error:(NSError**)error;
- (NBPhoneNumber*)getExampleNumberForType:(NSString*)regionCode type:(NBEPhoneNumberType)type error:(NSError**)error;
- (NBPhoneNumber*)getExampleNumberForNonGeoEntity:(NSNumber*)countryCallingCode error:(NSError**)error;

- (BOOL)canBeInternationallyDialled:(NBPhoneNumber*)number error:(NSError**)error;

- (BOOL)truncateTooLongNumber:(NBPhoneNumber*)number;

- (BOOL)isValidNumber:(NBPhoneNumber*)number;
- (BOOL)isViablePhoneNumber:(NSString*)phoneNumber;
- (BOOL)isAlphaNumber:(NSString*)number;
- (BOOL)isValidNumberForRegion:(NBPhoneNumber*)number regionCode:(NSString*)regionCode;
- (BOOL)isNANPACountry:(NSString*)regionCode;
- (BOOL)isLeadingZeroPossible:(NSNumber*)countryCallingCode;

- (NBEValidationResult)isPossibleNumberWithReason:(NBPhoneNumber*)number error:(NSError**)error;

- (BOOL)isPossibleNumber:(NBPhoneNumber*)number;
- (BOOL)isPossibleNumber:(NBPhoneNumber*)number error:(NSError**)error;
- (BOOL)isPossibleNumberString:(NSString*)number regionDialingFrom:(NSString*)regionDialingFrom error:(NSError**)error;

- (NBEMatchType)isNumberMatch:(id)firstNumberIn second:(id)secondNumberIn error:(NSError**)error;

- (int)getLengthOfGeographicalAreaCode:(NBPhoneNumber*)phoneNumber error:(NSError**)error;
- (int)getLengthOfNationalDestinationCode:(NBPhoneNumber*)phoneNumber error:(NSError**)error;

- (BOOL)maybeStripNationalPrefixAndCarrierCode:(NSString**)numberStr metadata:(NBPhoneMetaData*)metadata carrierCode:(NSString**)carrierCode;
- (NBECountryCodeSource)maybeStripInternationalPrefixAndNormalize:(NSString**)numberStr possibleIddPrefix:(NSString*)possibleIddPrefix;

- (NSNumber*)maybeExtractCountryCode:(NSString*)number metadata:(NBPhoneMetaData*)defaultRegionMetadata
                      nationalNumber:(NSString**)nationalNumber keepRawInput:(BOOL)keepRawInput
                         phoneNumber:(NBPhoneNumber**)phoneNumber error:(NSError**)error;

- (NBPhoneNumber*)parse:(NSString*)numberToParse defaultRegion:(NSString*)defaultRegion error:(NSError**)error;
- (NBPhoneNumber*)parseAndKeepRawInput:(NSString*)numberToParse defaultRegion:(NSString*)defaultRegion error:(NSError**)error;
- (NBPhoneNumber*)parseWithPhoneCarrierRegion:(NSString*)numberToParse error:(NSError**)error;

- (NSString*)format:(NBPhoneNumber*)phoneNumber numberFormat:(NBEPhoneNumberFormat)numberFormat error:(NSError**)error;
- (NSString*)formatByPattern:(NBPhoneNumber*)number numberFormat:(NBEPhoneNumberFormat)numberFormat userDefinedFormats:(NSArray*)userDefinedFormats error:(NSError**)error;
- (NSString*)formatNumberForMobileDialing:(NBPhoneNumber*)number regionCallingFrom:(NSString*)regionCallingFrom withFormatting:(BOOL)withFormatting error:(NSError**)error;
- (NSString*)formatOutOfCountryCallingNumber:(NBPhoneNumber*)number regionCallingFrom:(NSString*)regionCallingFrom error:(NSError**)error;
- (NSString*)formatOutOfCountryKeepingAlphaChars:(NBPhoneNumber*)number regionCallingFrom:(NSString*)regionCallingFrom error:(NSError**)error;
- (NSString*)formatNationalNumberWithCarrierCode:(NBPhoneNumber*)number carrierCode:(NSString*)carrierCode error:(NSError**)error;
- (NSString*)formatInOriginalFormat:(NBPhoneNumber*)number regionCallingFrom:(NSString*)regionCallingFrom error:(NSError**)error;
- (NSString*)formatNationalNumberWithPreferredCarrierCode:(NBPhoneNumber*)number fallbackCarrierCode:(NSString*)fallbackCarrierCode error:(NSError**)error;

- (BOOL)formattingRuleHasFirstGroupOnly:(NSString*)nationalPrefixFormattingRule;

@property (nonatomic, strong, readonly) NSDictionary *DIGIT_MAPPINGS;
@property (nonatomic, strong, readonly) NSBundle *libPhoneBundle;

@end
