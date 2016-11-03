//
//  NBPhoneNumber.h
//  libPhoneNumber
//  
//

#import <Foundation/Foundation.h>
#import "NBPhoneNumberDefines.h"


@interface NBPhoneNumber : NSObject <NSCopying, NSCoding>

// from phonemetadata.pb.js
/* 1 */ @property (nonatomic, strong, readwrite) NSNumber *countryCode;
/* 2 */ @property (nonatomic, strong, readwrite) NSNumber *nationalNumber;
/* 3 */ @property (nonatomic, strong, readwrite) NSString *extension;
/* 4 */ @property (nonatomic, assign, readwrite) BOOL italianLeadingZero;
/* 5 */ @property (nonatomic, strong, readwrite) NSString *rawInput;
/* 6 */ @property (nonatomic, strong, readwrite) NSNumber *countryCodeSource;
/* 7 */ @property (nonatomic, strong, readwrite) NSString *preferredDomesticCarrierCode;

- (void)clearCountryCodeSource;
- (NBECountryCodeSource)getCountryCodeSourceOrDefault;

@end
