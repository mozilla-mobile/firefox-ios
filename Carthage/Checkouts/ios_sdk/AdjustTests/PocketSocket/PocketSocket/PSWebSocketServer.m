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

#import "PSWebSocketServer.h"
#import "PSWebSocket.h"
#import "PSWebSocketDriver.h"
#import "PSWebSocketInternal.h"
#import "PSWebSocketBuffer.h"
#import "PSWebSocketNetworkThread.h"
#import <CFNetwork/CFNetwork.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <netinet/in.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <arpa/inet.h>
#import <Security/SecureTransport.h>

typedef NS_ENUM(NSInteger, PSWebSocketServerConnectionReadyState) {
    PSWebSocketServerConnectionReadyStateConnecting = 0,
    PSWebSocketServerConnectionReadyStateOpen,
    PSWebSocketServerConnectionReadyStateClosing,
    PSWebSocketServerConnectionReadyStateClosed
};

@interface PSWebSocketServerConnection : NSObject

@property (nonatomic, strong, readonly) NSString *identifier;
@property (nonatomic, assign) PSWebSocketServerConnectionReadyState readyState;
@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, assign) BOOL inputStreamOpenCompleted;
@property (nonatomic, assign) BOOL outputStreamOpenCompleted;
@property (nonatomic, strong) PSWebSocketBuffer *inputBuffer;
@property (nonatomic, strong) PSWebSocketBuffer *outputBuffer;

@end
@implementation PSWebSocketServerConnection

- (instancetype)init {
    if((self = [super init])) {
        _identifier = [[NSProcessInfo processInfo] globallyUniqueString];
        _readyState = PSWebSocketServerConnectionReadyStateConnecting;
        _inputBuffer = [[PSWebSocketBuffer alloc] init];
        _outputBuffer = [[PSWebSocketBuffer alloc] init];
    }
    return self;
}

@end


void PSWebSocketServerAcceptCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);

@interface PSWebSocketServer() <NSStreamDelegate, PSWebSocketDelegate> {
    dispatch_queue_t _workQueue;
    
    NSArray *_SSLCertificates;
    BOOL _secure;
    
    NSData *_addrData;
    CFSocketContext _socketContext;
    
    BOOL _running;
    CFSocketRef _socket;
    CFRunLoopSourceRef _socketRunLoopSource;
    
    NSMutableSet *_connections;
    NSMapTable *_connectionsByStreams;
    
    NSMutableSet *_webSockets;
}
@end
@implementation PSWebSocketServer

#pragma mark - Properties

- (NSRunLoop *)runLoop {
    return [[PSWebSocketNetworkThread sharedNetworkThread] runLoop];
}

#pragma mark - Initialization

+ (instancetype)serverWithHost:(NSString *)host port:(NSUInteger)port {
    return [[self alloc] initWithHost:host port:port SSLCertificates:nil];
}
+ (instancetype)serverWithHost:(NSString *)host port:(NSUInteger)port SSLCertificates:(NSArray *)SSLCertificates {
    return [[self alloc] initWithHost:host port:port SSLCertificates:SSLCertificates];
}
- (instancetype)initWithHost:(NSString *)host port:(NSUInteger)port SSLCertificates:(NSArray *)SSLCertificates {
    NSParameterAssert(port);
    if((self = [super init])) {
        _workQueue = dispatch_queue_create(nil, nil);
        
        // copy SSL certificates
        _SSLCertificates = [SSLCertificates copy];
        _secure = (_SSLCertificates != nil);
        
        // create addr data
        struct sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_len = sizeof(addr);
        addr.sin_family = AF_INET;
        if(host && ![host isEqualToString:@"0.0.0.0"]) {
            addr.sin_addr.s_addr = inet_addr(host.UTF8String);
            if(!addr.sin_addr.s_addr) {
                [NSException raise:@"Invalid host" format:@"Could not formulate internet address from host: %@", host];
                return nil;
            }
        } else {
            addr.sin_addr.s_addr = htonl(INADDR_ANY);
        }
        addr.sin_port = htons(port);
        _addrData = [NSData dataWithBytes:&addr length:sizeof(addr)];
        
        // create socket context
        _socketContext = (CFSocketContext){0, (__bridge void *)self, NULL, NULL, NULL};
        
        _connections = [NSMutableSet set];
        _connectionsByStreams = [NSMapTable weakToWeakObjectsMapTable];
        
        _webSockets = [NSMutableSet set];
        
    }
    return self;
}

#pragma mark - Actions

- (void)start {
    [self executeWork:^{
        [self connect:NO];
    }];
}
- (void)stop {
    [self executeWork:^{
        [self disconnectGracefully:NO];
    }];
}

#pragma mark - Connection

- (void)connect:(BOOL)silent {
    if(_running) {
        return;
    }
    
    // create socket
    _socket = CFSocketCreate(kCFAllocatorDefault,
                             PF_INET,
                             SOCK_STREAM,
                             IPPROTO_TCP,
                             kCFSocketAcceptCallBack,
                             PSWebSocketServerAcceptCallback,
                             &_socketContext);
    // configure socket
    int yes = 1;
    setsockopt(CFSocketGetNative(_socket), SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes));
    
    // bind
    CFSocketError err = CFSocketSetAddress(_socket, (__bridge CFDataRef)_addrData);
    if(err == kCFSocketError) {
        if(!silent) {
            [self notifyDelegateFailedToStart:[NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil]];
        }
        return;
    } else if(err == kCFSocketTimeout) {
        if(!silent) {
            [self notifyDelegateFailedToStart:[NSError errorWithDomain:NSPOSIXErrorDomain code:ETIME userInfo:nil]];
        }
        return;
    }
    
    // schedule
    _socketRunLoopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socket, 0);
    
    CFRunLoopRef runLoop = [[self runLoop] getCFRunLoop];
    CFRunLoopAddSource(runLoop, _socketRunLoopSource, kCFRunLoopCommonModes);
    
    _running = YES;
    
    if(!silent) {
        [self notifyDelegateDidStart];
    }
}
- (void)disconnectGracefully:(BOOL)silent {
    if(!_running) {
        return;
    }
    
    for(PSWebSocketServerConnection *connection in _connections.allObjects) {
        [self disconnectConnectionGracefully:connection statusCode:500 description:@"Service Going Away" headers: nil];
    }
    for(PSWebSocket *webSocket in _webSockets.allObjects) {
        [webSocket close];
    }
    
    [self pumpOutput];
    
    // disconnect
    [self executeWork:^{
        [self disconnect:silent];
    }];
    
    _running = NO;
}
- (void)disconnect:(BOOL)silent {
    if(_socketRunLoopSource) {
        CFRunLoopRef runLoop = [[self runLoop] getCFRunLoop];
        CFRunLoopRemoveSource(runLoop, _socketRunLoopSource, kCFRunLoopCommonModes);
        CFRelease(_socketRunLoopSource);
        _socketRunLoopSource = nil;
    }
    
    if(_socket) {
        if(CFSocketIsValid(_socket)) {
            CFSocketInvalidate(_socket);
        }
        CFRelease(_socket);
        _socket = nil;
    }
    
    _running = NO;
    
    if(!silent) {
        [self notifyDelegateDidStop];
    }
}

#pragma mark - Accepting

- (void)accept:(CFSocketNativeHandle)handle {
    [self executeWork:^{
        // create streams
        CFReadStreamRef readStream = nil;
        CFWriteStreamRef writeStream = nil;
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, handle, &readStream, &writeStream);
        
        // fail if we couldn't get streams
        if(!readStream || !writeStream) {
            return;
        }
        
        // configure streams
        CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
        CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
        
        // enable SSL
        if(_secure) {
            NSMutableDictionary *opts = [NSMutableDictionary dictionary];
            
            opts[(__bridge id)kCFStreamSSLIsServer] = @YES;
            opts[(__bridge id)kCFStreamSSLCertificates] = _SSLCertificates;
            opts[(__bridge id)kCFStreamSSLValidatesCertificateChain] = @NO; // i.e. client certs
            
            CFReadStreamSetProperty(readStream, kCFStreamPropertySSLSettings, (__bridge CFDictionaryRef)opts);
            CFWriteStreamSetProperty(writeStream, kCFStreamPropertySSLSettings, (__bridge CFDictionaryRef)opts);

            SSLContextRef context = (SSLContextRef)CFWriteStreamCopyProperty(writeStream, kCFStreamPropertySSLContext);
            SSLSetClientSideAuthenticate(context, kTryAuthenticate);
            CFRelease(context);
        }
        
        // create connection
        PSWebSocketServerConnection *connection = [[PSWebSocketServerConnection alloc] init];
        connection.inputStream = CFBridgingRelease(readStream);
        connection.outputStream = CFBridgingRelease(writeStream);
        
        // attach connection
        [self attachConnection:connection];
        
        // open
        [connection.inputStream open];
        [connection.outputStream open];
        
    }];
}

#pragma mark - WebSockets

- (void)attachWebSocket:(PSWebSocket *)webSocket {
    if([_webSockets containsObject:webSocket]) {
        return;
    }
    [_webSockets addObject:webSocket];
    webSocket.delegate = self;
    webSocket.delegateQueue = _workQueue;
}
- (void)detachWebSocket:(PSWebSocket *)webSocket {
    if(![_webSockets containsObject:webSocket]) {
        return;
    }
    [_webSockets removeObject:webSocket];
    webSocket.delegate = nil;
}

#pragma mark - PSWebSocketDelegate

- (void)webSocketDidOpen:(PSWebSocket *)webSocket {
    [self notifyDelegateWebSocketDidOpen:webSocket];
}
- (void)webSocket:(PSWebSocket *)webSocket didReceiveMessage:(id)message {
    [self notifyDelegateWebSocket:webSocket didReceiveMessage:message];
}
- (void)webSocket:(PSWebSocket *)webSocket didFailWithError:(NSError *)error {
    [self detachWebSocket:webSocket];
    [self notifyDelegateWebSocket:webSocket didFailWithError:error];
}
- (void)webSocket:(PSWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    [self detachWebSocket:webSocket];
    [self notifyDelegateWebSocket:webSocket didCloseWithCode:code reason:reason wasClean:wasClean];
}
- (void)webSocketDidFlushInput:(PSWebSocket *)webSocket {
    [self notifyDelegateWebSocketDidFlushInput:webSocket];
}
- (void)webSocketDidFlushOutput:(PSWebSocket *)webSocket {
    [self notifyDelegateWebSocketDidFlushOutput:webSocket];
}

#pragma mark - Connections

- (void)attachConnection:(PSWebSocketServerConnection *)connection {
    if([_connections containsObject:connection]) {
        return;
    }
    [_connections addObject:connection];
    [_connectionsByStreams setObject:connection forKey:connection.inputStream];
    [_connectionsByStreams setObject:connection forKey:connection.outputStream];
    connection.inputStream.delegate = self;
    connection.outputStream.delegate = self;
    [connection.inputStream scheduleInRunLoop:[self runLoop] forMode:NSRunLoopCommonModes];
    [connection.outputStream scheduleInRunLoop:[self runLoop] forMode:NSRunLoopCommonModes];
}
- (void)detatchConnection:(PSWebSocketServerConnection *)connection {
    if(![_connections containsObject:connection]) {
        return;
    }
    [_connections removeObject:connection];
    [_connectionsByStreams removeObjectForKey:connection.inputStream];
    [_connectionsByStreams removeObjectForKey:connection.outputStream];
    [connection.inputStream removeFromRunLoop:[self runLoop] forMode:NSRunLoopCommonModes];
    [connection.outputStream removeFromRunLoop:[self runLoop] forMode:NSRunLoopCommonModes];
    connection.inputStream.delegate = nil;
    connection.outputStream.delegate = nil;
}
- (void)disconnectConnectionGracefully:(PSWebSocketServerConnection *)connection
                            statusCode:(NSInteger)statusCode
                           description:(NSString *)description
                               headers:(NSDictionary*)headers
{
    if(connection.readyState >= PSWebSocketServerConnectionReadyStateClosing) {
        return;
    }
    connection.readyState = PSWebSocketServerConnectionReadyStateClosing;
    if (!description)
        description = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
    CFHTTPMessageRef msg = CFHTTPMessageCreateResponse(kCFAllocatorDefault, statusCode, (__bridge CFStringRef)description, kCFHTTPVersion1_1);
    for (NSString* name in headers) {
        CFHTTPMessageSetHeaderFieldValue(msg, (__bridge CFStringRef)name,
                                         (__bridge CFStringRef)headers[name]);
    }
    CFHTTPMessageSetHeaderFieldValue(msg, CFSTR("Connection"), CFSTR("Close"));
    CFHTTPMessageSetHeaderFieldValue(msg, CFSTR("Content-Length"), CFSTR("0"));
    NSData *data = CFBridgingRelease(CFHTTPMessageCopySerializedMessage(msg));
    CFRelease(msg);
    [connection.outputBuffer appendData:data];
    [self pumpOutput];
    __weak typeof(self)weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), _workQueue, ^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if(strongSelf) {
            [strongSelf disconnectConnection:connection];
        }
    });
}
- (void)disconnectConnection:(PSWebSocketServerConnection *)connection {
    if(connection.readyState == PSWebSocketServerConnectionReadyStateClosed) {
        return;
    }
    connection.readyState = PSWebSocketServerConnectionReadyStateClosed;
    [self detatchConnection:connection];
    [connection.inputStream close];
    [connection.outputStream close];
}

#pragma mark - Pumping

- (void)pumpInput {
    uint8_t chunkBuffer[4096];
    for(PSWebSocketServerConnection *connection in _connections.allObjects) {
        if(connection.readyState != PSWebSocketServerConnectionReadyStateOpen ||
           !connection.inputStream.hasBytesAvailable) {
            continue;
        }
        
        while(connection.inputStream.hasBytesAvailable) {
            NSInteger readLength = [connection.inputStream read:chunkBuffer maxLength:sizeof(chunkBuffer)];
            if(readLength > 0) {
                [connection.inputBuffer appendBytes:chunkBuffer length:readLength];
            } else if(readLength < 0) {
                [self disconnectConnection:connection];
            }
            if(readLength < sizeof(chunkBuffer)) {
                break;
            }
        }
        
        if(connection.inputBuffer.bytesAvailable > 4) {
            void* boundary = memmem(connection.inputBuffer.bytes,
                                    connection.inputBuffer.bytesAvailable,
                                    "\r\n\r\n", 4);
            if (boundary == NULL) {
                // Haven't reached end of HTTP headers yet
                if(connection.inputBuffer.bytesAvailable >= 16384) {
                    [self disconnectConnection:connection];
                }
                continue;
            }
            NSUInteger boundaryOffset = boundary + 4 - connection.inputBuffer.bytes;
            
            CFHTTPMessageRef msg = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, YES);
            CFHTTPMessageAppendBytes(msg, connection.inputBuffer.bytes, connection.inputBuffer.bytesAvailable);
            if(!CFHTTPMessageIsHeaderComplete(msg)) {
                [self disconnectConnection:connection];
                CFRelease(msg);
                continue;
            }
            
            // move input buffer
            connection.inputBuffer.offset += boundaryOffset;
            if(connection.inputBuffer.hasBytesAvailable) {
                [self disconnectConnection:connection];
                CFRelease(msg);
                continue;
            }
            
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:CFBridgingRelease(CFHTTPMessageCopyRequestURL(msg))];
            request.HTTPMethod = CFBridgingRelease(CFHTTPMessageCopyRequestMethod(msg));
            
            NSDictionary *headers = CFBridgingRelease(CFHTTPMessageCopyAllHeaderFields(msg));
            [headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [request setValue:obj forHTTPHeaderField:key];
            }];
            
            if(![PSWebSocket isWebSocketRequest:request]) {
                [self disconnectConnectionGracefully:connection
                                          statusCode:501 description:@"WebSockets only, please"
                                             headers:nil];
                CFRelease(msg);
                continue;
            }

            NSString* protocol = nil;
            if(_delegate) {
                NSHTTPURLResponse* response = nil;
                if (![self askDelegateShouldAcceptConnection:connection
                                                     request:request
                                                    response:&response]) {
                    [self disconnectConnectionGracefully:connection
                                              statusCode:(response.statusCode ?: 403)
                                             description:nil
                                                 headers:response.allHeaderFields];
                    CFRelease(msg);
                    continue;
                }
                protocol = response.allHeaderFields[@"Sec-WebSocket-Protocol"];
            }
            
            // detach connection
            [self detatchConnection:connection];

            // create webSocket
            PSWebSocket *webSocket = [PSWebSocket serverSocketWithRequest:request inputStream:connection.inputStream outputStream:connection.outputStream];
            webSocket.delegateQueue = _workQueue;
            
            // attach webSocket
            [self attachWebSocket:webSocket];
            
            // open webSocket
            [webSocket open];
            
            // clean up
            CFRelease(msg);
        }
    }
}
- (void)pumpOutput {
    for(PSWebSocketServerConnection *connection in _connections.allObjects) {
        if(connection.readyState != PSWebSocketServerConnectionReadyStateOpen &&
           connection.readyState != PSWebSocketServerConnectionReadyStateClosing) {
            continue;
        }
        
        while(connection.outputStream.hasSpaceAvailable && connection.outputBuffer.hasBytesAvailable) {
            NSInteger writeLength = [connection.outputStream write:connection.outputBuffer.bytes maxLength:connection.outputBuffer.bytesAvailable];
            if(writeLength > 0) {
                connection.outputBuffer.offset += writeLength;
            } else if(writeLength < 0) {
                [self disconnectConnection:connection];
                break;
            }
            
            if(writeLength == 0) {
                break;
            }
        }
        
        if(connection.readyState == PSWebSocketServerConnectionReadyStateClosing &&
           !connection.outputBuffer.hasBytesAvailable) {
            [self disconnectConnection:connection];
        }
    }
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)event {
    [self executeWork:^{
        if(stream.delegate != self) {
            [stream.delegate stream:stream handleEvent:event];
            return;
        }
        
        PSWebSocketServerConnection *connection = [_connectionsByStreams objectForKey:stream];
        NSAssert(connection, @"Connection should not be nil");
        
        if(event == NSStreamEventOpenCompleted) {
            if(stream == connection.inputStream) {
                connection.inputStreamOpenCompleted = YES;
            } else if(stream == connection.outputStream) {
                connection.outputStreamOpenCompleted = YES;
            }
        }
        if(!connection.inputStreamOpenCompleted || !connection.outputStreamOpenCompleted) {
            return;
        }
        
        switch(event) {
            case NSStreamEventOpenCompleted: {
                if(connection.readyState == PSWebSocketServerConnectionReadyStateConnecting) {
                    connection.readyState = PSWebSocketServerConnectionReadyStateOpen;
                }
                [self pumpInput];
                [self pumpOutput];
                break;
            }
            case NSStreamEventErrorOccurred: {
                [self disconnectConnection:connection];
                break;
            }
            case NSStreamEventEndEncountered: {
                [self disconnectConnection:connection];
                break;
            }
            case NSStreamEventHasBytesAvailable: {
                [self pumpInput];
                break;
            }
            case NSStreamEventHasSpaceAvailable: {
                [self pumpOutput];
                break;
            }
            default:
                break;
        }
    }];
}

#pragma mark - Delegation

- (void)notifyDelegateDidStart {
    [self executeDelegate:^{
        [_delegate serverDidStart:self];
    }];
}
- (void)notifyDelegateFailedToStart:(NSError *)error {
    [self executeDelegate:^{
        [_delegate server:self didFailWithError:error];
    }];
}
- (void)notifyDelegateDidStop {
    [self executeDelegate:^{
        [_delegate serverDidStop:self];
    }];
}

- (void)notifyDelegateWebSocketDidOpen:(PSWebSocket *)webSocket {
    [self executeDelegate:^{
        [_delegate server:self webSocketDidOpen:webSocket];
    }];
}
- (void)notifyDelegateWebSocket:(PSWebSocket *)webSocket didReceiveMessage:(id)message {
    [self executeDelegate:^{
        [_delegate server:self webSocket:webSocket didReceiveMessage:message];
    }];
}

- (void)notifyDelegateWebSocket:(PSWebSocket *)webSocket didFailWithError:(NSError *)error {
    [self executeDelegate:^{
        [_delegate server:self webSocket:webSocket didFailWithError:error];
    }];
}
- (void)notifyDelegateWebSocket:(PSWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    [self executeDelegate:^{
        [_delegate server:self webSocket:webSocket didCloseWithCode:code reason:reason wasClean:wasClean];
    }];
}
- (void)notifyDelegateWebSocketDidFlushInput:(PSWebSocket *)webSocket {
    [self executeDelegate:^{
        if ([_delegate respondsToSelector: @selector(server:webSocketDidFlushInput:)]) {
            [_delegate server:self webSocketDidFlushInput:webSocket];
        };
    }];
}
- (void)notifyDelegateWebSocketDidFlushOutput:(PSWebSocket *)webSocket {
    [self executeDelegate:^{
        if ([_delegate respondsToSelector: @selector(server:webSocketDidFlushOutput:)]) {
            [_delegate server:self webSocketDidFlushOutput:webSocket];
        }
    }];
}
- (BOOL)askDelegateShouldAcceptConnection:(PSWebSocketServerConnection *)connection
                                  request: (NSURLRequest *)request
                                 response:(NSHTTPURLResponse **)outResponse {
    __block BOOL accept;
    __block NSHTTPURLResponse* response = nil;
    [self executeDelegateAndWait:^{
        if([_delegate respondsToSelector:@selector(server:acceptWebSocketWithRequest:address:trust:response:)]) {
            NSData* address = PSPeerAddressOfInputStream(connection.inputStream);
            SecTrustRef trust = (SecTrustRef)CFReadStreamCopyProperty(
                                                  (__bridge CFReadStreamRef)connection.inputStream,
                                                  kCFStreamPropertySSLPeerTrust);
            accept = [_delegate server:self
            acceptWebSocketWithRequest:request
                               address:address
                                 trust:trust
                              response:&response];
            if(trust) {
                CFRelease(trust);
            }
        } else if([_delegate respondsToSelector:@selector(server:acceptWebSocketWithRequest:)]) {
            accept = [_delegate server:self acceptWebSocketWithRequest:request];
        } else {
            accept = YES;
        }
    }];
    *outResponse = response;
    return accept;
}

#pragma mark - Queueing

- (void)executeWork:(void (^)(void))work {
    NSParameterAssert(work);
    dispatch_async(_workQueue, work);
}
- (void)executeWorkAndWait:(void (^)(void))work {
    NSParameterAssert(work);
    dispatch_sync(_workQueue, work);
}
- (void)executeDelegate:(void (^)(void))work {
    NSParameterAssert(work);
    dispatch_async((_delegateQueue) ? _delegateQueue : dispatch_get_main_queue(), work);
}
- (void)executeDelegateAndWait:(void (^)(void))work {
    NSParameterAssert(work);
    dispatch_sync((_delegateQueue) ? _delegateQueue : dispatch_get_main_queue(), work);
}

#pragma mark - Dealloc

- (void)dealloc {
    [self executeWorkAndWait:^{
        [self disconnect:YES];
    }];
}

@end

void PSWebSocketServerAcceptCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    [(__bridge PSWebSocketServer *)info accept:*(CFSocketNativeHandle *)data];
}
