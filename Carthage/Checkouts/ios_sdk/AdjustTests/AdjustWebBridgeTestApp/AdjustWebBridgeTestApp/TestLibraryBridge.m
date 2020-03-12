//
//  TestLibraryBridge.m
//  AdjustWebBridgeTestApp
//
//  Created by Pedro Silva (@nonelse) on 6th August 2018.
//  Copyright © 2018 Adjust GmbH. All rights reserved.
//

#import "TestLibraryBridge.h"

@interface TestLibraryBridge ()

@property WVJBResponseCallback commandExecutorCallback;
@property (nonatomic, strong) ATLTestLibrary *testLibrary;
@property (nonatomic, weak) AdjustBridgeRegister *adjustBridgeRegister;

@end

@implementation TestLibraryBridge

- (id)initWithAdjustBridgeRegister:(AdjustBridgeRegister *)adjustBridgeRegister {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    self.testLibrary = [ATLTestLibrary testLibraryWithBaseUrl:baseUrl
                                                andControlUrl:controlUrl
                                           andCommandDelegate:self];

    [adjustBridgeRegister registerHandler:@"adjustTLB_startTestSession" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"TestLibraryBridge adjustTLB_startTestSession");
        // self.commandExecutorCallback = responseCallback;
        [self.adjustBridgeRegister callHandler:@"adjustjs_commandExecutor" data:@"test"];
        [self.testLibrary startTestSession:(NSString *)data];
    }];

    [adjustBridgeRegister registerHandler:@"adjustTLB_addInfoToSend" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"TestLibraryBridge adjustTLB_addInfoToSend");
        NSString *key = [data objectForKey:@"key"];
        NSString *value = [data objectForKey:@"value"];
        [self.testLibrary addInfoToSend:key value:value];
    }];

    [adjustBridgeRegister registerHandler:@"adjustTLB_sendInfoToServer" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"TestLibraryBridge adjustTLB_sendInfoToServer");
        if (![data isKindOfClass:[NSString class]]) {
            NSLog(@"TestLibraryBridge adjustTLB_sendInfoToServer data not string %@", data);
            return;
        }

        NSString *basePath = (NSString *)data;
        [self.testLibrary sendInfoToServer:basePath];
    }];

    self.adjustBridgeRegister = adjustBridgeRegister;
    NSLog(@"TestLibraryBridge initWithAdjustBridgeRegister");
    return self;
}

- (void)executeCommandRawJson:(NSString *)json {
    NSLog(@"TestLibraryBridge executeCommandRawJson: %@", json);
    if (self.commandExecutorCallback == nil) {
        NSLog(@"TestLibraryBridge nil commandExecutorCallback");
    }
    // self.commandExecutorCallback(json);
    [self.adjustBridgeRegister callHandler:@"adjustJS_commandExecutor" data:json];
}

@end
