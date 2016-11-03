#ifndef SwrveCommonConnectionDelegate_h
#define SwrveCommonConnectionDelegate_h

#import <Foundation/Foundation.h>

typedef void (^ConnectionCompletionHandler)(NSURLResponse* response, NSData* data, NSError* error);

@interface SwrveCommonConnectionDelegate : NSObject <NSURLConnectionDataDelegate>

@property (atomic, retain) NSDate* startTime;
@property (atomic, retain) NSMutableDictionary* metrics;
@property (atomic, retain) NSMutableData* data;
@property (atomic, retain) NSURLResponse* response;
@property (atomic, strong) ConnectionCompletionHandler handler;

- (id)init:(ConnectionCompletionHandler)handler;
- (void)addHttpPerformanceMetrics:(NSString*)metricsString;

@end


#endif /* SwrveCommonConnectionDelegate_h */
