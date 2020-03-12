//
//  ATAAdjustDelegate.m
//  AdjustTestApp
//
//  Created by Pedro da Silva (@nonelse) on 26th October 2017.
//  Copyright © 2017 Аdjust GmbH. All rights reserved.
//

#import <objc/runtime.h>
#import "ATAAdjustDelegate.h"

@interface ATAAdjustDelegate ()

@property (nonatomic, strong) ATLTestLibrary *testLibrary;
@property (nonatomic, copy) NSString *basePath;

@end

@implementation ATAAdjustDelegate

- (id)initWithTestLibrary:(ATLTestLibrary *)testLibrary andBasePath:(NSString *)basePath {
    self = [super init];

    if (nil == self) {
        return nil;
    }

    self.testLibrary = testLibrary;
    self.basePath = basePath;

    [self swizzleCallbackMethod:@selector(adjustAttributionChanged:)
               swizzledSelector:@selector(adjustAttributionChangedWannabeEmpty:)];

    [self swizzleCallbackMethod:@selector(adjustEventTrackingSucceeded:)
               swizzledSelector:@selector(adjustEventTrackingSucceededWannabeEmpty:)];

    [self swizzleCallbackMethod:@selector(adjustEventTrackingFailed:)
               swizzledSelector:@selector(adjustEventTrackingFailedWannabeEmpty:)];

    [self swizzleCallbackMethod:@selector(adjustSessionTrackingSucceeded:)
               swizzledSelector:@selector(adjustSessionTrackingSucceededWannabeEmpty:)];

    [self swizzleCallbackMethod:@selector(adjustSessionTrackingFailed:)
               swizzledSelector:@selector(adjustSessionTrackingFailedWananbeEmpty:)];

    return self;
}

- (void)swizzleAttributionCallback:(BOOL)swizzleAttributionCallback
            eventSucceededCallback:(BOOL)swizzleEventSucceededCallback
               eventFailedCallback:(BOOL)swizzleEventFailedCallback
          sessionSucceededCallback:(BOOL)swizzleSessionSucceededCallback
             sessionFailedCallback:(BOOL)swizzleSessionFailedCallback {
    // Do the swizzling where and if needed.
    if (swizzleAttributionCallback) {
        [self swizzleCallbackMethod:@selector(adjustAttributionChanged:)
                   swizzledSelector:@selector(adjustAttributionChangedWannabe:)];
    }

    if (swizzleEventSucceededCallback) {
        [self swizzleCallbackMethod:@selector(adjustEventTrackingSucceeded:)
                   swizzledSelector:@selector(adjustEventTrackingSucceededWannabe:)];
    }

    if (swizzleEventFailedCallback) {
        [self swizzleCallbackMethod:@selector(adjustEventTrackingFailed:)
                   swizzledSelector:@selector(adjustEventTrackingFailedWannabe:)];
    }

    if (swizzleSessionSucceededCallback) {
        [self swizzleCallbackMethod:@selector(adjustSessionTrackingSucceeded:)
                   swizzledSelector:@selector(adjustSessionTrackingSucceededWannabe:)];
    }

    if (swizzleSessionFailedCallback) {
        [self swizzleCallbackMethod:@selector(adjustSessionTrackingFailed:)
                   swizzledSelector:@selector(adjustSessionTrackingFailedWananbe:)];
    }
}

- (void)swizzleCallbackMethod:(SEL)originalSelector
             swizzledSelector:(SEL)swizzledSelector {
    Class className = [self class];

    Method originalMethod = class_getInstanceMethod(className, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(className, swizzledSelector);

    BOOL didAddMethod = class_addMethod(className,
                                        originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));

    if (didAddMethod) {
        class_replaceMethod(className,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (void)adjustAttributionChangedWannabe:(ADJAttribution *)attribution {
    NSLog(@"Attribution callback called!");
    NSLog(@"Attribution: %@", attribution);
    
    [self.testLibrary addInfoToSend:@"trackerToken" value:attribution.trackerToken];
    [self.testLibrary addInfoToSend:@"trackerName" value:attribution.trackerName];
    [self.testLibrary addInfoToSend:@"network" value:attribution.network];
    [self.testLibrary addInfoToSend:@"campaign" value:attribution.campaign];
    [self.testLibrary addInfoToSend:@"adgroup" value:attribution.adgroup];
    [self.testLibrary addInfoToSend:@"creative" value:attribution.creative];
    [self.testLibrary addInfoToSend:@"clickLabel" value:attribution.clickLabel];
    [self.testLibrary addInfoToSend:@"adid" value:attribution.adid];
    
    [self.testLibrary sendInfoToServer:self.basePath];
}

- (void)adjustEventTrackingSucceededWannabe:(ADJEventSuccess *)eventSuccessResponseData {
    NSLog(@"Event success callback called!");
    NSLog(@"Event success data: %@", eventSuccessResponseData);

    [self.testLibrary addInfoToSend:@"message" value:eventSuccessResponseData.message];
    [self.testLibrary addInfoToSend:@"timestamp" value:eventSuccessResponseData.timeStamp];
    [self.testLibrary addInfoToSend:@"adid" value:eventSuccessResponseData.adid];
    [self.testLibrary addInfoToSend:@"eventToken" value:eventSuccessResponseData.eventToken];

    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:eventSuccessResponseData.jsonResponse
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];

    if (!jsonData) {
        NSLog(@"Unable to conver NSDictionary with JSON response to JSON string: %@", error);
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [self.testLibrary addInfoToSend:@"jsonResponse" value:jsonString];
    }

    [self.testLibrary sendInfoToServer:self.basePath];
}

- (void)adjustEventTrackingFailedWannabe:(ADJEventFailure *)eventFailureResponseData {
    NSLog(@"Event failure callback called!");
    NSLog(@"Event failure data: %@", eventFailureResponseData);

    [self.testLibrary addInfoToSend:@"message" value:eventFailureResponseData.message];
    [self.testLibrary addInfoToSend:@"timestamp" value:eventFailureResponseData.timeStamp];
    [self.testLibrary addInfoToSend:@"adid" value:eventFailureResponseData.adid];
    [self.testLibrary addInfoToSend:@"eventToken" value:eventFailureResponseData.eventToken];
    [self.testLibrary addInfoToSend:@"willRetry" value:(eventFailureResponseData.willRetry ? @"true" : @"false")];

    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:eventFailureResponseData.jsonResponse
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];

    if (!jsonData) {
        NSLog(@"Unable to conver NSDictionary with JSON response to JSON string: %@", error);
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [self.testLibrary addInfoToSend:@"jsonResponse" value:jsonString];
    }

    [self.testLibrary sendInfoToServer:self.basePath];
}

- (void)adjustSessionTrackingSucceededWannabe:(ADJSessionSuccess *)sessionSuccessResponseData {
    NSLog(@"Session success callback called!");
    NSLog(@"Session success data: %@", sessionSuccessResponseData);
    
    [self.testLibrary addInfoToSend:@"message" value:sessionSuccessResponseData.message];
    [self.testLibrary addInfoToSend:@"timestamp" value:sessionSuccessResponseData.timeStamp];
    [self.testLibrary addInfoToSend:@"adid" value:sessionSuccessResponseData.adid];
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:sessionSuccessResponseData.jsonResponse
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    
    if (!jsonData) {
        NSLog(@"Unable to conver NSDictionary with JSON response to JSON string: %@", error);
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [self.testLibrary addInfoToSend:@"jsonResponse" value:jsonString];
    }
    
    [self.testLibrary sendInfoToServer:self.basePath];
}

- (void)adjustSessionTrackingFailedWananbe:(ADJSessionFailure *)sessionFailureResponseData {
    NSLog(@"Session failure callback called!");
    NSLog(@"Session failure data: %@", sessionFailureResponseData);
    
    [self.testLibrary addInfoToSend:@"message" value:sessionFailureResponseData.message];
    [self.testLibrary addInfoToSend:@"timestamp" value:sessionFailureResponseData.timeStamp];
    [self.testLibrary addInfoToSend:@"adid" value:sessionFailureResponseData.adid];
    [self.testLibrary addInfoToSend:@"willRetry" value:(sessionFailureResponseData.willRetry ? @"true" : @"false")];
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:sessionFailureResponseData.jsonResponse
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    
    if (!jsonData) {
        NSLog(@"Unable to conver NSDictionary with JSON response to JSON string: %@", error);
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [self.testLibrary addInfoToSend:@"jsonResponse" value:jsonString];
    }
    
    [self.testLibrary sendInfoToServer:self.basePath];
}

- (void)adjustAttributionChangedWannabeEmpty:(ADJAttribution *)attribution {
    NSLog(@"Attribution callback called!");
    NSLog(@"Attribution: %@", attribution);
}

- (void)adjustEventTrackingSucceededWannabeEmpty:(ADJEventSuccess *)eventSuccessResponseData {
    NSLog(@"Event success callback called!");
    NSLog(@"Event success data: %@", eventSuccessResponseData);
}

- (void)adjustEventTrackingFailedWannabeEmpty:(ADJEventFailure *)eventFailureResponseData {
    NSLog(@"Event failure callback called!");
    NSLog(@"Event failure data: %@", eventFailureResponseData);
}

- (void)adjustSessionTrackingSucceededWannabeEmpty:(ADJSessionSuccess *)sessionSuccessResponseData {
    NSLog(@"Session success callback called!");
    NSLog(@"Session success data: %@", sessionSuccessResponseData);
}

- (void)adjustSessionTrackingFailedWananbeEmpty:(ADJSessionFailure *)sessionFailureResponseData {
    NSLog(@"Session failure callback called!");
    NSLog(@"Session failure data: %@", sessionFailureResponseData);
}

@end
