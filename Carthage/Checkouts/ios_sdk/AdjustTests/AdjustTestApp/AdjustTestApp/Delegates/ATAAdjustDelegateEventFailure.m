//
//  ATAAdjustDelegateEventFailure.m
//  AdjustTestApp
//
//  Created by Uglješa Erceg (uerceg) on 8th December 2017.
//  Copyright © 2017 Adjust GmbH. All rights reserved.
//

#import "ATAAdjustDelegateEventFailure.h"

@interface ATAAdjustDelegateEventFailure ()

@property (nonatomic, strong) ATLTestLibrary *testLibrary;
@property (nonatomic, copy) NSString *basePath;

@end

@implementation ATAAdjustDelegateEventFailure

- (id)initWithTestLibrary:(ATLTestLibrary *)testLibrary andBasePath:(NSString *)basePath {
    self = [super init];
    
    if (nil == self) {
        return nil;
    }
    
    self.testLibrary = testLibrary;
    self.basePath = basePath;

    return self;
}

- (void)adjustEventTrackingFailed:(ADJEventFailure *)eventFailureResponseData {
    NSLog(@"Event failure callback called!");
    NSLog(@"Event failure data: %@", eventFailureResponseData);
    
    [self.testLibrary addInfoToSend:@"message" value:eventFailureResponseData.message];
    [self.testLibrary addInfoToSend:@"timestamp" value:eventFailureResponseData.timeStamp];
    [self.testLibrary addInfoToSend:@"adid" value:eventFailureResponseData.adid];
    [self.testLibrary addInfoToSend:@"eventToken" value:eventFailureResponseData.eventToken];
    [self.testLibrary addInfoToSend:@"callbackId" value:eventFailureResponseData.callbackId];
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

@end
