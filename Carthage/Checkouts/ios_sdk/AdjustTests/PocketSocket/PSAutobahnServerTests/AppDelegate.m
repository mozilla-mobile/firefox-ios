//
//  AppDelegate.m
//  PSAutobahnServerTests
//
//  Created by Robert Payne on 31/03/16.
//  Copyright © 2016 Zwopple Limited. All rights reserved.
//

#import "AppDelegate.h"
#import "PSWebSocketServer.h"

@interface AppDelegate () <PSWebSocketServerDelegate>

@property (nonatomic, strong) PSWebSocketServer *server;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    self.server = [PSWebSocketServer serverWithHost:@"127.0.0.1" port:9001];
    self.server.delegate = self;
    [self.server start];
    
    return YES;
}

#pragma mark - PSWebSocketServerDelegate

- (void)serverDidStart:(PSWebSocketServer *)server {
}
- (void)server:(PSWebSocketServer *)server didFailWithError:(NSError *)error {
    [NSException raise:NSInternalInconsistencyException format:error.localizedDescription];
}
- (void)serverDidStop:(PSWebSocketServer *)server {
    [NSException raise:NSInternalInconsistencyException format:@"Server stopped unexpected."];
}

- (void)server:(PSWebSocketServer *)server webSocketDidOpen:(PSWebSocket *)webSocket {
    
}
- (void)server:(PSWebSocketServer *)server webSocket:(PSWebSocket *)webSocket didReceiveMessage:(id)message {
    [webSocket send:message];
}
- (void)server:(PSWebSocketServer *)server webSocket:(PSWebSocket *)webSocket didFailWithError:(NSError *)error {
    
}
- (void)server:(PSWebSocketServer *)server webSocket:(PSWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    
}

@end
