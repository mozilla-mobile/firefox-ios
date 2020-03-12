//
//  ATAAdjustDelegateSessionSuccess.m
//  AdjustTestApp
//
//  Created by Uglješa Erceg (uerceg) on 8th December 2017.
//  Copyright © 2017 Adjust GmbH. All rights reserved.
//

#import "ATAAdjustDelegateSessionSuccess.h"

@interface ATAAdjustDelegateSessionSuccess ()

@property (nonatomic, strong) ATLTestLibrary *testLibrary;
@property (nonatomic, copy) NSString *basePath;

@end

@implementation ATAAdjustDelegateSessionSuccess

- (id)initWithTestLibrary:(ATLTestLibrary *)testLibrary andBasePath:(NSString *)basePath {
    self = [super init];
    
    if (nil == self) {
        return nil;
    }
    
    self.testLibrary = testLibrary;
    self.basePath = basePath;

    return self;
}

- (void)adjustSessionTrackingSucceeded:(ADJSessionSuccess *)sessionSuccessResponseData {
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

@end
