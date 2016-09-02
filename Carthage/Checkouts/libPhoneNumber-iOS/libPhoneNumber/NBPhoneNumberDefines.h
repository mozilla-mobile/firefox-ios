//
//  NBPhoneNumberDefines.h
//  libPhoneNumber
//
//

@import Foundation;

#ifndef libPhoneNumber_NBPhoneNumberDefines_h
#define libPhoneNumber_NBPhoneNumberDefines_h

#define NB_YES [NSNumber numberWithBool:YES]
#define NB_NO [NSNumber numberWithBool:NO]

#pragma mark - Enum -

typedef NS_ENUM(NSInteger, NBEPhoneNumberFormat) {
    NBEPhoneNumberFormatE164 = 0,
    NBEPhoneNumberFormatINTERNATIONAL = 1,
    NBEPhoneNumberFormatNATIONAL = 2,
    NBEPhoneNumberFormatRFC3966 = 3
};


typedef NS_ENUM(NSInteger, NBEPhoneNumberType) {
    NBEPhoneNumberTypeFIXED_LINE = 0,
    NBEPhoneNumberTypeMOBILE = 1,
    // In some regions (e.g. the USA), it is impossible to distinguish between
    // fixed-line and mobile numbers by looking at the phone number itself.
    NBEPhoneNumberTypeFIXED_LINE_OR_MOBILE = 2,
    // Freephone lines
    NBEPhoneNumberTypeTOLL_FREE = 3,
    NBEPhoneNumberTypePREMIUM_RATE = 4,
    // The cost of this call is shared between the caller and the recipient, and
    // is hence typically less than PREMIUM_RATE calls. See
    // http://en.wikipedia.org/wiki/Shared_Cost_Service for more information.
    NBEPhoneNumberTypeSHARED_COST = 5,
    // Voice over IP numbers. This includes TSoIP (Telephony Service over IP).
    NBEPhoneNumberTypeVOIP = 6,
    // A personal number is associated with a particular person, and may be routed
    // to either a MOBILE or FIXED_LINE number. Some more information can be found
    // here = http://en.wikipedia.org/wiki/Personal_Numbers
    NBEPhoneNumberTypePERSONAL_NUMBER = 7,
    NBEPhoneNumberTypePAGER = 8,
    // Used for 'Universal Access Numbers' or 'Company Numbers'. They may be
    // further routed to specific offices, but allow one number to be used for a
    // company.
    NBEPhoneNumberTypeUAN = 9,
    // Used for 'Voice Mail Access Numbers'.
    NBEPhoneNumberTypeVOICEMAIL = 10,
    // A phone number is of type UNKNOWN when it does not fit any of the known
    // patterns for a specific region.
    NBEPhoneNumberTypeUNKNOWN = -1
};


typedef NS_ENUM(NSInteger, NBEMatchType) {
    NBEMatchTypeNOT_A_NUMBER = 0,
    NBEMatchTypeNO_MATCH = 1,
    NBEMatchTypeSHORT_NSN_MATCH = 2,
    NBEMatchTypeNSN_MATCH = 3,
    NBEMatchTypeEXACT_MATCH = 4
};


typedef NS_ENUM(NSInteger, NBEValidationResult) {
    NBEValidationResultUNKNOWN = 0,
    NBEValidationResultIS_POSSIBLE = 1,
    NBEValidationResultINVALID_COUNTRY_CODE = 2,
    NBEValidationResultTOO_SHORT = 3,
    NBEValidationResultTOO_LONG = 4
};


typedef NS_ENUM(NSInteger, NBECountryCodeSource) {
    NBECountryCodeSourceFROM_NUMBER_WITH_PLUS_SIGN = 1,
    NBECountryCodeSourceFROM_NUMBER_WITH_IDD = 5,
    NBECountryCodeSourceFROM_NUMBER_WITHOUT_PLUS_SIGN = 10,
    NBECountryCodeSourceFROM_DEFAULT_COUNTRY = 20
};

extern NSString * const NB_UNKNOWN_REGION;
extern NSString * const NB_NON_BREAKING_SPACE;
extern NSString * const NB_PLUS_CHARS;
extern NSString * const NB_VALID_DIGITS_STRING;
extern NSString * const NB_REGION_CODE_FOR_NON_GEO_ENTITY;

#endif
