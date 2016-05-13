//
//  M2PhoneMetaData.h
//  libPhoneNumber
//
//

#import <Foundation/Foundation.h>


@class NBPhoneNumberDesc, NBNumberFormat;

@interface NBPhoneMetaData : NSObject

// from phonemetadata.pb.js
/*  1 */ @property (nonatomic, strong) NBPhoneNumberDesc *generalDesc;
/*  2 */ @property (nonatomic, strong) NBPhoneNumberDesc *fixedLine;
/*  3 */ @property (nonatomic, strong) NBPhoneNumberDesc *mobile;
/*  4 */ @property (nonatomic, strong) NBPhoneNumberDesc *tollFree;
/*  5 */ @property (nonatomic, strong) NBPhoneNumberDesc *premiumRate;
/*  6 */ @property (nonatomic, strong) NBPhoneNumberDesc *sharedCost;
/*  7 */ @property (nonatomic, strong) NBPhoneNumberDesc *personalNumber;
/*  8 */ @property (nonatomic, strong) NBPhoneNumberDesc *voip;
/* 21 */ @property (nonatomic, strong) NBPhoneNumberDesc *pager;
/* 25 */ @property (nonatomic, strong) NBPhoneNumberDesc *uan;
/* 27 */ @property (nonatomic, strong) NBPhoneNumberDesc *emergency;
/* 28 */ @property (nonatomic, strong) NBPhoneNumberDesc *voicemail;
/* 24 */ @property (nonatomic, strong) NBPhoneNumberDesc *noInternationalDialling;
/*  9 */ @property (nonatomic, strong) NSString *codeID;
/* 10 */ @property (nonatomic, strong) NSNumber *countryCode;
/* 11 */ @property (nonatomic, strong) NSString *internationalPrefix;
/* 17 */ @property (nonatomic, strong) NSString *preferredInternationalPrefix;
/* 12 */ @property (nonatomic, strong) NSString *nationalPrefix;
/* 13 */ @property (nonatomic, strong) NSString *preferredExtnPrefix;
/* 15 */ @property (nonatomic, strong) NSString *nationalPrefixForParsing;
/* 16 */ @property (nonatomic, strong) NSString *nationalPrefixTransformRule;
/* 18 */ @property (nonatomic, assign) BOOL sameMobileAndFixedLinePattern;
/* 19 */ @property (nonatomic, strong) NSMutableArray *numberFormats;
/* 20 */ @property (nonatomic, strong) NSMutableArray *intlNumberFormats;
/* 22 */ @property (nonatomic, assign) BOOL mainCountryForCode;
/* 23 */ @property (nonatomic, strong) NSString *leadingDigits;
/* 26 */ @property (nonatomic, assign) BOOL leadingZeroPossible;

@end
