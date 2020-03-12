//
//  WebSocket.m
//  Zimt
//
//  Created by Esad Hajdarevic on 2/14/10.
//  Copyright 2010 OpenResearch Software Development OG. All rights reserved.
//  Copyright (c) 2010 Esad Hajdarevic <esad@eigenbyte.com>
//
//  This software is provided 'as-is', without any express or implied
//  warranty. In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to lalter it and redistribute it
//  freely, subject to the following restrictions:
//
//    1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software
//    in a product, an acknowledgment in the product documentation would be
//    appreciated but is not required.
//
//    2. Altered source versions must be plainly marked as such, and must not be
//    misrepresented as being the original software.
//
//    3. This notice may not be removed or altered from any source
//    distribution.

#import "Leanplum_WebSocket.h"
#import "Leanplum_AsyncSocket.h"


NSString* const Leanplum_WebSocketErrorDomain = @"WebSocketErrorDomain";
NSString* const Leanplum_WebSocketException = @"WebSocketException";

enum {
    WebSocketTagHandshake = 0,
    WebSocketTagMessage = 1
};

@implementation Leanplum_WebSocket

@synthesize delegate, url, origin, connected, runLoopModes;

#pragma mark Initializers

+ (id)webSocketWithURLString:(NSString*)urlString delegate:(id<Leanplum_WebSocketDelegate>)aDelegate {
    return [[Leanplum_WebSocket alloc] initWithURLString:urlString delegate:aDelegate];
}

-(id)initWithURLString:(NSString *)urlString delegate:(id<Leanplum_WebSocketDelegate>)aDelegate {
    self = [super init];
    if (self) {
        self.delegate = aDelegate;
        url = [NSURL URLWithString:urlString];
        if (![url.scheme isEqualToString:@"ws"]) {
            [NSException raise:Leanplum_WebSocketException format:@"Unsupported protocol %@", url];
        }
        socket = [[Leanplum_AsyncSocket alloc] initWithDelegate:self];
        self.runLoopModes = @[NSRunLoopCommonModes];
    }
    return self;
}

#pragma mark Delegate dispatch methods

-(void)_dispatchFailure:(NSNumber*)code {
    if(delegate && [delegate respondsToSelector:@selector(webSocket:didFailWithError:)]) {
        [delegate webSocket:self didFailWithError:[NSError errorWithDomain:Leanplum_WebSocketErrorDomain code:[code intValue] userInfo:nil]];
    }
}

-(void)_dispatchClosed {
    if (delegate && [delegate respondsToSelector:@selector(webSocketDidClose:)]) {
        [delegate webSocketDidClose:self];
    }
}

-(void)_dispatchOpened {
    if (delegate && [delegate respondsToSelector:@selector(webSocketDidOpen:)]) {
        [delegate webSocketDidOpen:self];
    }
}

-(void)_dispatchMessageReceived:(NSString*)message {
    if (delegate && [delegate respondsToSelector:@selector(webSocket:didReceiveMessage:)]) {
        [delegate webSocket:self didReceiveMessage:message];
    }
}

-(void)_dispatchMessageSent {
    if (delegate && [delegate respondsToSelector:@selector(webSocketDidSendMessage:)]) {
        [delegate webSocketDidSendMessage:self];
    }
}

#pragma mark Private

-(void)_readNextMessage {
    [socket readDataToData:[NSData dataWithBytes:"\xFF" length:1] withTimeout:-1 tag:WebSocketTagMessage];
}

#pragma mark Public interface

-(void)close {
    [socket disconnectAfterReadingAndWriting];
}

-(void)open {
    if (!connected) {
        [socket connectToHost:url.host onPort:[url.port intValue] withTimeout:5 error:nil];
        if (runLoopModes) [socket setRunLoopModes:runLoopModes];
    }
}

-(void)send:(NSString*)message {
    NSMutableData* data = [NSMutableData data];
    [data appendBytes:"\x00" length:1];
    [data appendData:[message dataUsingEncoding:NSUTF8StringEncoding]];
    [data appendBytes:"\xFF" length:1];
    [socket writeData:data withTimeout:-1 tag:WebSocketTagMessage];
}

#pragma mark AsyncSocket delegate methods

-(void)onSocketDidDisconnect:(Leanplum_AsyncSocket *)sock {
    connected = NO;
}

-(void)onSocket:(Leanplum_AsyncSocket *)sock willDisconnectWithError:(NSError *)err {
    if (!connected) {
        [self _dispatchFailure:[NSNumber numberWithInt:WebSocketErrorConnectionFailed]];
    } else {
        [self _dispatchClosed];
    }
}

- (void)onSocket:(Leanplum_AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    NSString* requestOrigin = self.origin;
    if (!requestOrigin) requestOrigin = [NSString stringWithFormat:@"http://%@",url.host];

    NSString *requestPath = url.path;
    if (url.query) {
        requestPath = [requestPath stringByAppendingFormat:@"?%@", url.query];
    }
    NSString* getRequest = [NSString stringWithFormat:@"GET %@ HTTP/1.1\r\n"
                            "Upgrade: WebSocket\r\n"
                            "Connection: Upgrade\r\n"
                            "Host: %@\r\n"
                            "Origin: %@\r\n"
                            "\r\n",
                            requestPath,url.host,requestOrigin];
    [socket writeData:[getRequest dataUsingEncoding:NSASCIIStringEncoding] withTimeout:-1 tag:WebSocketTagHandshake];
}

-(void)onSocket:(Leanplum_AsyncSocket *)sock didWriteDataWithTag:(long)tag {
    if (tag == WebSocketTagHandshake) {
        [sock readDataToData:[@"\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding] withTimeout:-1 tag:WebSocketTagHandshake];
    } else if (tag == WebSocketTagMessage) {
        [self _dispatchMessageSent];
    }
}

-(void)onSocket:(Leanplum_AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if (tag == WebSocketTagHandshake) {
        NSString* response = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        if ([response hasPrefix:@"HTTP/1.1 101 Web Socket Protocol Handshake\r\nUpgrade: WebSocket\r\nConnection: Upgrade\r\n"]) {
            connected = YES;
            [self _dispatchOpened];

            [self _readNextMessage];
        } else {
            [self _dispatchFailure:[NSNumber numberWithInt:WebSocketErrorHandshakeFailed]];
        }
    } else if (tag == WebSocketTagMessage) {
        char firstByte = 0xFF;
        [data getBytes:&firstByte length:1];
        if (firstByte != 0x00) return; // Discard message
        NSString* message = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(1, [data length]-2)] encoding:NSUTF8StringEncoding];

        [self _dispatchMessageReceived:message];
        [self _readNextMessage];
    }
}

#pragma mark Destructor

-(void)dealloc {
    socket.delegate = nil;
    [socket disconnect];
}

@end
