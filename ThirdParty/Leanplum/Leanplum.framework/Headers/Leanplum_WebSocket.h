//
//  WebSocket.h
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

#import <Foundation/Foundation.h>

@class Leanplum_AsyncSocket;
@class Leanplum_WebSocket;

@protocol Leanplum_WebSocketDelegate<NSObject>
@optional
- (void)webSocket:(Leanplum_WebSocket*)webSocket didFailWithError:(NSError*)error;
- (void)webSocketDidOpen:(Leanplum_WebSocket*)webSocket;
- (void)webSocketDidClose:(Leanplum_WebSocket*)webSocket;
- (void)webSocket:(Leanplum_WebSocket*)webSocket didReceiveMessage:(NSString*)message;
- (void)webSocketDidSendMessage:(Leanplum_WebSocket*)webSocket;
@end

@interface Leanplum_WebSocket : NSObject {
    id<Leanplum_WebSocketDelegate> __unsafe_unretained delegate;
    NSURL* url;
    Leanplum_AsyncSocket* socket;
    BOOL connected;
    NSString* origin;

    NSArray* runLoopModes;
}

@property(nonatomic,assign) id<Leanplum_WebSocketDelegate> delegate;
@property(nonatomic,readonly) NSURL* url;
@property(nonatomic,retain) NSString* origin;
@property(nonatomic,readonly) BOOL connected;
@property(nonatomic,retain) NSArray* runLoopModes;

+ (id)webSocketWithURLString:(NSString*)urlString delegate:(id<Leanplum_WebSocketDelegate>)delegate;
- (id)initWithURLString:(NSString*)urlString delegate:(id<Leanplum_WebSocketDelegate>)delegate;

- (void)open;
- (void)close;
- (void)send:(NSString*)message;

@end

enum {
    WebSocketErrorConnectionFailed = 1,
    WebSocketErrorHandshakeFailed = 2
};

extern NSString *const Leanplum_WebSocketException;
extern NSString* const Leanplum_WebSocketErrorDomain;
