//
//  NSDate+RFC1123.h
//  MKNetworkKit
//
//  Created by Marcus Rohrmoser
//  http://blog.mro.name/2009/08/nsdateformatter-http-header/
//  http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.3.1

// Note from above link:

// I’ve been asked about which license this code is under: I put this into Public Domain.
// No warranty whatsoever. Still I’d be happy about attribution but don’t require such.
#import <UIKit/UIKit.h>

#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000

@interface LPRFC1123 : NSObject
/**
 Convert a RFC1123 'Full-Date' string
 (http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.3.1)
 into NSDate.
 */
+ (NSDate *)dateFromRFC1123:(NSString*)value_;

/**
 Convert NSDate into a RFC1123 'Full-Date' string
 (http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.3.1).
 */
+ (NSString *)rfc1123String:(NSDate *)date;

@end

#endif
