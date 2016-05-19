//
//  NBPhoneNumberDesc.h
//  libPhoneNumber
//
//

#import <Foundation/Foundation.h>


@interface NBPhoneNumberDesc : NSObject

// from phonemetadata.pb.js
/* 2 */ @property (nonatomic, strong, readwrite) NSString *nationalNumberPattern;
/* 3 */ @property (nonatomic, strong, readwrite) NSString *possibleNumberPattern;
/* 6 */ @property (nonatomic, strong, readwrite) NSString *exampleNumber;

- (id)initWithNationalNumberPattern:(NSString *)nnp withPossibleNumberPattern:(NSString *)pnp withExample:(NSString *)exp;

@end
