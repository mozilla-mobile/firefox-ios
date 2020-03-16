//
//  ATLTestInfo.m
//  AdjustTestLibrary
//
//  Created by Pedro on 01.11.17.
//  Copyright © 2017 adjust. All rights reserved.
//

#import "ATLTestInfo.h"
#import "ATLUtil.h"

static NSString * const TEST_INFO_PATH = @"/test_info";

@interface ATLTestInfo()

@property (nonatomic, strong) NSOperationQueue* operationQueue;
@property (nonatomic, strong) NSMutableDictionary *infoToServer;
@property (nonatomic, weak) ATLTestLibrary * testLibrary;
@property (nonatomic, assign) BOOL closed;

@end

@implementation ATLTestInfo

- (id)initWithTestLibrary:(ATLTestLibrary *)testLibrary {
    self = [super init];
    if (self == nil) return nil;

    self.testLibrary = testLibrary;

    self.operationQueue = [[NSOperationQueue alloc] init];
    [self.operationQueue setMaxConcurrentOperationCount:1];

    self.closed = NO;

    return self;
}

- (void)teardown {
    self.closed = YES;
    if (self.operationQueue != nil) {
        [ATLUtil debug:@"queue cancel test info thread queue"];
        [ATLUtil addOperationAfterLast:self.operationQueue
                                 block:^{
                                     [ATLUtil debug:@"cancel test info thread queue"];
                                     if (self.operationQueue != nil) {
                                         [self.operationQueue cancelAllOperations];
                                     }
                                     self.operationQueue = nil;
                                     self.testLibrary = nil;
                                 }];
    } else {
        self.operationQueue = nil;
        self.testLibrary = nil;
    }
}

- (void)addInfoToSend:(NSString *)key
                value:(NSString *)value {
    [ATLUtil addOperationAfterLast:self.operationQueue
                             block:^{
                                 [self addInfoToSendI:key value:value];
                             }];
}

- (void)addInfoToSendI:(NSString *)key
                 value:(NSString *)value {
    if (key == nil || value == nil) {
        return;
    }
    if (self.infoToServer == nil) {
        self.infoToServer = [[NSMutableDictionary alloc] init];
    }

    [self.infoToServer setObject:value forKey:key];
}

- (void)sendInfoToServer:(NSString *)currentBasePath {
    [ATLUtil addOperationAfterLast:self.operationQueue
                             block:^{
                                 [self sendInfoToServerI:currentBasePath];
                             }];
}


- (void)sendInfoToServerI:(NSString *)currentBasePath {
    [ATLUtil debug:@"sendInfoToServer"];

    ATLHttpRequest * requestData = [[ATLHttpRequest alloc] init];

    requestData.path = [ATLUtil appendBasePath:currentBasePath path:TEST_INFO_PATH];

    if (self.infoToServer) {
        requestData.bodyString = [ATLUtil queryString:self.infoToServer];
    }

    [ATLUtilNetworking sendPostRequest:requestData
                       responseHandler:^(ATLHttpResponse *httpResponse) {
                           self.infoToServer = nil;
                           [self.testLibrary readResponse:httpResponse];
                       }];
}


@end
