//  Copyright 2014-Present Zwopple Limited
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "PSAutobahnClientWebSocketOperation.h"
#import "PSWebSocket.h"

@interface PSAutobahnClientWebSocketOperation() <PSWebSocketDelegate>

@property (strong) PSWebSocket *webSocket;
@property (assign) BOOL isFinished;
@property (assign) BOOL isExecuting;

@end
@implementation PSAutobahnClientWebSocketOperation

#pragma mark - Class Properties

+ (BOOL)automaticallyNotifiesObserversOfIsExecuting {
    return NO;
}
+ (BOOL)automaticallyNotifiesObserversOfIsFinished {
    return NO;
}

#pragma mark - Initialization

- (instancetype)initWithURL:(NSURL *)URL {
    if((self = [super init])) {
        NSURLRequest *request = [NSURLRequest requestWithURL:URL];
        _webSocket = [PSWebSocket clientSocketWithRequest:request];
        _webSocket.delegate = self;
        _webSocket.delegateQueue = dispatch_queue_create(nil, nil);
        _isExecuting = NO;
        _isFinished = NO;
    }
    return self;
}

#pragma mark - NSOperation

- (BOOL)isConcurrent {
    return YES;
}
- (void)start {
    self.isExecuting = YES;
    [_webSocket open];
}

#pragma mark - PSWebSocketDelegate

- (void)webSocketDidOpen:(PSWebSocket *)webSocket {
//    NSLog(@"webSocketDidOpen:");
}
- (void)webSocket:(PSWebSocket *)webSocket didReceiveMessage:(id)message {
//    NSLog(@"webSocket: didReceiveMessage: %@", message);
    if(self.echo) {
        [webSocket send:message];
    } else {
        self.message = message;
    }
}
- (void)webSocket:(PSWebSocket *)webSocket didFailWithError:(NSError *)error {
//    NSLog(@"webSocket: didFailWithError: %@", error);
    self.error = error;
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    self.isFinished = YES;
    self.isExecuting = NO;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
    self.webSocket.delegate = nil;
    self.webSocket = nil;
}
- (void)webSocket:(PSWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
//    NSLog(@"webSocket: didCloseWithCode: %@, reason: %@, wasClean: %@", @(code), reason, (wasClean) ? @"YES" : @"NO");
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    self.isFinished = YES;
    self.isExecuting = NO;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
    self.webSocket.delegate = nil;
    self.webSocket = nil;
}

@end
