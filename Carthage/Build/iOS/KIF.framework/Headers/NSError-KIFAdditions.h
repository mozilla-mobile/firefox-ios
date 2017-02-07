//
//  NSError+KIFAdditions.h
//  KIF
//
//  Created by Brian Nickel on 7/27/13.
//
//

#import <Foundation/Foundation.h>

@interface NSError (KIFAdditions)

+ (instancetype)KIFErrorWithUnderlyingError:(NSError *)underlyingError format:(NSString *)format, ... NS_FORMAT_FUNCTION(2,3);
+ (instancetype)KIFErrorWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);

@end
