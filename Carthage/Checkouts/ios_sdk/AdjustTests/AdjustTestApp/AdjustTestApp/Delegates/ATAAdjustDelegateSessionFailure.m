//
//  ATAAdjustDelegateSessionFailure.m
//  AdjustTestApp
//
//  Created by Uglješa Erceg (uerceg) on 8th December 2017.
//  Copyright © 2017 Adjust GmbH. All rights reserved.
//

#import "ATAAdjustDelegateSessionFailure.h"

@interface ATAAdjustDelegateSessionFailure ()

@property (nonatomic, strong) ATLTestLibrary *testLibrary;
@property (nonatomic, copy) NSString *basePath;

@end

@implementation ATAAdjustDelegateSessionFailure

- (id)initWithTestLibrary:(ATLTestLibrary *)testLibrary andBasePath:(NSString *)basePath {
    self = [super init];
    
    if (nil == self) {
        return nil;
    }
    
    self.testLibrary = testLibrary;
    self.basePath = basePath;

    return self;
}

- (void)adjustSessionTrackingFailed:(ADJSessionFailure *)sessionFailureResponseData {
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

@end
