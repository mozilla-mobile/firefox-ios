//
//  SocketIO.m
//  v.01
//
//  based on
//  socketio-cocoa https://github.com/fpotter/socketio-cocoa
//  by Fred Potter <fpotter@pieceable.com>
//
//  using
//  https://github.com/erichocean/cocoa-websocket
//  http://regexkit.sourceforge.net/RegexKitLite/
//  https://github.com/stig/json-framework/
//  http://allseeing-i.com/ASIHTTPRequest/
//
//  reusing some parts of
//  /socket.io/socket.io.js
//
//  Created by Philipp Kyeck http://beta_interactive.de
//  Copyright (c) 2011-12 Philipp Kyeck <http://beta-interactive.de>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//  Modified by Ruben Nine http://leftbee.net in order to add SSL support

#import "Leanplum_SocketIO.h"
#import "LPConstants.h"

#import "LPNetworkProtocol.h"
#import "Leanplum_WebSocket.h"

#import "LPJSON.h"

#define DEBUG_LOGS DEBUG
#define HANDSHAKE_URL @"http%@://%@:%d/socket.io/1/?t=%d"
#define SOCKET_URL @"ws%@://%@:%d/socket.io/1/websocket/%@"


# pragma mark -
# pragma mark SocketIO's private interface

@interface Leanplum_SocketIO (FP_Private) <Leanplum_WebSocketDelegate>

- (void) log:(NSString *)message;

- (void) setTimeout;
- (void) onTimeout;

- (void) onConnect;
- (void) onDisconnect;

- (void) sendDisconnect;
- (void) sendHearbeat;
- (void) send:(Leanplum_SocketIOPacket *)packet;

- (NSString *) addAcknowledge:(SEL)function;
- (void) removeAcknowledgeForKey:(NSString *)key;

@end


# pragma mark -
# pragma mark SocketIO implementation

@implementation Leanplum_SocketIO

- (id) initWithDelegate:(id<Leanplum_SocketIODelegate>)delegate
{
    self = [super init];
    if (self)
    {
        _delegate = delegate;

        _queue = [[NSMutableArray alloc] init];

        _ackCount = 0;
        _acks = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void) connectWithEngine:(id<LPNetworkEngineProtocol>)engine withHost:(NSString*)host onPort:(NSInteger)port
{
    [self connectWithEngine:engine withHost:host onPort:port secureConnection:NO];
}

- (void) connectWithEngine:(id<LPNetworkEngineProtocol>)engine withHost:(NSString*)host onPort:(NSInteger)port secureConnection:(BOOL)useTLS
{
    if (!_isConnected && !_isConnecting)
    {
        _isConnecting = YES;

        _host = host;
        _port = port;
        _useTLS  = useTLS;

        // do handshake via HTTP/HTTPS request
        NSString *s = [NSString stringWithFormat:HANDSHAKE_URL, useTLS ? @"s" : @"", _host, (int) _port, rand()];
        NSURL *url = [NSURL URLWithString:s];

        id<LPNetworkOperationProtocol> op = [engine operationWithURLString:[url description]];
        [op addCompletionHandler:^(id<LPNetworkOperationProtocol> operation, id json) {
            @try {
                [self requestFinished:operation];
            }
            @catch (NSException *exception) {
                // Ignore. This can happen sometimes.
            }
        } errorHandler:^(id<LPNetworkOperationProtocol> operation, NSError *error) {
            @try {
                [self requestFailed:error];
            }
            @catch (NSException *exception) {
                // Ignore. This can happen sometimes.
            }
        }];

        // if (_useTLS) [request setValidatesSecureCertificate:NO];
        [engine enqueueOperation: op];
    }
}

- (void) disconnect
{
    [self sendDisconnect];
}

- (void) sendMessage:(NSString *)data
{
    [self sendMessage:data withAcknowledge:nil];
}

- (void) sendMessage:(NSString *)data withAcknowledge:(SEL)function
{
    Leanplum_SocketIOPacket *packet = [[Leanplum_SocketIOPacket alloc] initWithType:@"message"];
    packet.data = data;
    packet.pId = [self addAcknowledge:function];
    [self send:packet];
}

- (void) sendJSON:(NSDictionary *)data
{
    [self sendJSON:data withAcknowledge:nil];
}

- (void) sendJSON:(NSDictionary *)data withAcknowledge:(SEL)function
{
    Leanplum_SocketIOPacket *packet = [[Leanplum_SocketIOPacket alloc] initWithType:@"json"];
    packet.data = [LPJSON stringFromJSON:data];
    packet.pId = [self addAcknowledge:function];
    [self send:packet];
}

- (void) sendEvent:(NSString *)eventName withData:(NSDictionary *)data
{
    [self sendEvent:eventName withData:data andAcknowledge:nil];
}

- (void) sendEvent:(NSString *)eventName withData:(NSDictionary *)data andAcknowledge:(SEL)function
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:eventName forKey:@"name"];
    dict[@"args"] = data;

    Leanplum_SocketIOPacket *packet = [[Leanplum_SocketIOPacket alloc] initWithType:@"event"];
    packet.data = [LPJSON stringFromJSON:dict];
    packet.pId = [self addAcknowledge:function];
    if (function)
    {
        packet.ack = @"data";
    }
    [self send:packet];
}

- (void)sendAcknowledgement:(NSString *)pId withArgs:(NSArray *)data {
    Leanplum_SocketIOPacket *packet = [[Leanplum_SocketIOPacket alloc] initWithType:@"ack"];
    packet.data = [LPJSON stringFromJSON:data];
    packet.pId = pId;
    packet.ack = @"data";

    [self send:packet];
}

# pragma mark -
# pragma mark private methods

- (void) openSocket
{
    NSString *url = [NSString stringWithFormat:SOCKET_URL, _useTLS ? @"s" : @"", _host, (int) (_port == 443 ? 80 : _port), _sid];

    _webSocket = nil;

    _webSocket = [[Leanplum_WebSocket alloc] initWithURLString:url delegate:self];
    [self log:[NSString stringWithFormat:@"Opening %@", url]];
    [_webSocket open];
}

- (void) sendDisconnect
{
    Leanplum_SocketIOPacket *packet = [[Leanplum_SocketIOPacket alloc] initWithType:@"disconnect"];
    [self send:packet];
}

- (void) sendHeartbeat
{
    Leanplum_SocketIOPacket *packet = [[Leanplum_SocketIOPacket alloc] initWithType:@"heartbeat"];
    [self send:packet];
}

- (void) send:(Leanplum_SocketIOPacket *)packet
{
    NSNumber *type = [packet typeAsNumber];
    NSMutableArray *encoded = [NSMutableArray arrayWithObject:type];

    NSString *pId = packet.pId != nil ? packet.pId : @"";
    if ([packet.ack isEqualToString:@"data"])
    {
        pId = [pId stringByAppendingString:@"+"];
    }

    // Do not write pid for acknowledgements
    if ([type intValue] != 6) {
        [encoded addObject:pId];
    }

    // not yet sure what this is for
    NSString *endPoint = @"";
    [encoded addObject:endPoint];


    if (packet.data != nil)
    {
        NSString *ackpId = @"";
        // This is an acknowledgement packet, so, prepend the ack pid to the data
        if ([type intValue] == 6) {
            ackpId = [NSString stringWithFormat:@":%@%@", packet.pId, @"+"];
        }

        [encoded addObject:[NSString stringWithFormat:@"%@%@", ackpId, packet.data]];
    }

    NSString *req = [encoded componentsJoinedByString:@":"];
    if (!_isConnected)
    {
        [_queue addObject:packet];
    }
    else
    {
        [_webSocket send:req];

        if ([_delegate respondsToSelector:@selector(socketIO:didSendMessage:)])
        {
            [_delegate socketIO:self didSendMessage:packet];
        }
    }
}

+ (NSArray *) arrayOfCaptureComponentsOfString:(NSString *)data matchedBy:(NSRegularExpression *)regExpression
{
    NSMutableArray *test = [NSMutableArray array];

    NSArray *matches = [regExpression matchesInString:data options:0 range:NSMakeRange(0, data.length)];

    for(NSTextCheckingResult *match in matches) {
        NSMutableArray *result = [NSMutableArray arrayWithCapacity:match.numberOfRanges];
        for(NSInteger i=0; i<match.numberOfRanges; i++) {
            NSRange matchRange = [match rangeAtIndex:i];
            NSString *matchStr = nil;
            if(matchRange.location != NSNotFound) {
                matchStr = [data substringWithRange:matchRange];
            } else {
                matchStr = @"";
            }
            [result addObject:matchStr];
        }
        [test addObject:result];
    }
    return test;
}

+ (NSArray *) arrayOfCaptureComponentsOfString:(NSString *)data matchedByRegex:(NSString *)regex
{
    NSError *error = NULL;
    NSRegularExpression *regExpression = [NSRegularExpression regularExpressionWithPattern:regex options:NSRegularExpressionCaseInsensitive error:&error];
    return [self arrayOfCaptureComponentsOfString:data matchedBy:regExpression];
}

- (void) onData:(NSString *)data
{
    // data arrived -> reset timeout
    [self setTimeout];

    // check if data is valid (from socket.io.js)
    NSString *regex = @"^([^:]+):([0-9]+)?(\\+)?:([^:]+)?:?(.*)?$";
    NSString *regexPieces = @"^([0-9]+)(\\+)?(.*)";
    NSArray *test = [Leanplum_SocketIO arrayOfCaptureComponentsOfString:data matchedByRegex:regex];

    // valid data-string arrived
    if ([test count] > 0)
    {
        NSArray *result = test[0];

        int idx = [result[1] intValue];
        Leanplum_SocketIOPacket *packet = [[Leanplum_SocketIOPacket alloc] initWithTypeIndex:idx];

        packet.pId = result[2];

        packet.ack = result[3];
        packet.endpoint = result[4];
        packet.data = result[5];

        //
        switch (idx)
        {
            case 0:
                // TODO: Not sure about the purpose of this one --Ruben
                [self onDisconnect];
                break;

            case 1:
                // TODO: Not sure about the purpose of this one --Ruben
                // from socket.io.js ... not sure when data will contain sth?!
                // packet.qs = data || '';
                [self onConnect];
                break;

            case 2:
                [self sendHeartbeat];
                break;

            case 3:
                if (packet.data && ![packet.data isEqualToString:@""])
                {
                    if ([_delegate respondsToSelector:@selector(socketIO:didReceiveMessage:)])
                    {
                        [_delegate socketIO:self didReceiveMessage:packet];
                    }
                }
                break;

            case 4:
                if (packet.data && ![packet.data isEqualToString:@""])
                {
                    if ([_delegate respondsToSelector:@selector(socketIO:didReceiveJSON:)])
                    {
                        [_delegate socketIO:self didReceiveJSON:packet];
                    }
                }
                break;

            case 5:
                if (packet.data && ![packet.data isEqualToString:@""])
                {
                    NSDictionary *json = [packet dataAsJSON];
                    packet.name = json[@"name"];
                    packet.args = json[@"args"];
                    if ([_delegate respondsToSelector:@selector(socketIO:didReceiveEvent:)])
                    {
                        [_delegate socketIO:self didReceiveEvent:packet];
                    }
                }
                break;

            case 6:
                [self handleAck:packet regexPieces:regexPieces];
                break;

            case 7:
                [self log:@"error"];
                break;

            case 8:
                [self log:@"noop"];
                break;

            default:
                [self log:@"command not found or not yet supported"];
                break;
        }
    }
    else
    {
        [self log:@"ERROR: data that has arrived wasn't valid"];
    }
}

- (void)handleAck:(Leanplum_SocketIOPacket *)packet regexPieces:(NSString *)regexPieces {
    NSArray *pieces = [Leanplum_SocketIO arrayOfCaptureComponentsOfString:packet.data
                                                           matchedByRegex:regexPieces];

    if ([pieces count] > 0) {
        NSArray *piece = pieces[0];
        int ackId = [piece[1] intValue];

        NSString *argsStr = piece[3];
        id argsData = nil;
        if (argsStr && ![argsStr isEqualToString:@""]) {
            argsData = [LPJSON JSONFromString:argsStr];
            if ([argsData count] > 0) {
                argsData = [argsData objectAtIndex:0];
            }
        }

        // get selector for ackId
        NSString *key = [NSString stringWithFormat:@"%d", ackId];
        SEL function = NSSelectorFromString(_acks[key]);
        if ([_delegate respondsToSelector:function]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            if (argsData != nil) {
                [_delegate performSelector:function withObject:argsData];
            } else {
                [_delegate performSelector:function];
            }
#pragma clang diagnostic pop
            [self removeAcknowledgeForKey:key];
        }
    }
}

- (void) doQueue
{
    // TODO send all packets at once ... not as separate packets
    while ([_queue count] > 0)
    {
        Leanplum_SocketIOPacket *packet = _queue[0];
        [self send:packet];
        [_queue removeObject:packet];
    }
}

- (void) onConnect
{
    _isConnected = YES;
    _isConnecting = NO;

    if ([_delegate respondsToSelector:@selector(socketIODidConnect:)])
    {
        [_delegate socketIODidConnect:self];
    }

    // semd amy queued packets
    [self doQueue];

    [self setTimeout];
}

- (void) onDisconnect
{
    BOOL wasConnected = _isConnected;

    _isConnected = NO;
    _isConnecting = NO;
    _sid = nil;

    [_queue removeAllObjects];

    if (wasConnected && [_delegate respondsToSelector:@selector(socketIODidDisconnect:)])
    {
        [_delegate socketIODidDisconnect:self];
    }
}

# pragma mark -
# pragma mark Acknowledge methods

- (NSString *) addAcknowledge:(SEL)function
{
    if (function)
    {
        ++_ackCount;
        NSString *ac = [NSString stringWithFormat:@"%ld", (long)_ackCount];
        _acks[ac] = NSStringFromSelector(function);
        return ac;
    }
    return nil;
}

- (void) removeAcknowledgeForKey:(NSString *)key
{
    [_acks removeObjectForKey:key];
}

# pragma mark -
# pragma mark Heartbeat methods

- (void) onTimeout
{
    [self log:@"Timed out waiting for heartbeat."];
    [self onDisconnect];
}

- (void) setTimeout
{
    if (_timeout != nil)
    {
        [_timeout invalidate];
        _timeout = nil;
    }

    _timeout = [NSTimer scheduledTimerWithTimeInterval:_heartbeatTimeout
                                                 target:self
                                               selector:@selector(onTimeout)
                                               userInfo:nil
                                                repeats:NO];
}


# pragma mark -
# pragma mark Handshake callbacks

- (void) requestFinished:(id<LPNetworkOperationProtocol>)op
{
    NSString *responseString = [op responseString];
    [self log:[NSString stringWithFormat:@"requestFinished() %@", responseString]];
    NSArray *data = [responseString componentsSeparatedByString:@":"];

    if ([data count] < 4) {
        NSLog(@"Leanplum: Development socket error. Missing data: %@", data);
        return;
    }

    _sid = data[0];
    [self log:[NSString stringWithFormat:@"sid: %@", _sid]];

    // add small buffer of 7sec (magic xD)
    _heartbeatTimeout = [data[1] floatValue] + 7.0;
    [self log:[NSString stringWithFormat:@"heartbeatTimeout: %f", _heartbeatTimeout]];

    // index 2 => connection timeout

    NSString *t = data[3];
    NSArray *transports = [t componentsSeparatedByString:@","];
    [self log:[NSString stringWithFormat:@"transports: %@", transports]];

    [self openSocket];
}

- (void) requestFailed:(NSError *)error
{
    NSLog(@"Leanplum: ERROR: handshake failed ... %@", [error localizedDescription]);

    _isConnecting = NO;
    _isConnected  = NO;

    if ([_delegate respondsToSelector:@selector(socketIOHandshakeFailed:)])
    {
        [_delegate socketIOHandshakeFailed:self];
    }
}

# pragma mark -
# pragma mark WebSocket Delegate Methods

- (void) webSocketDidClose:(Leanplum_WebSocket*)webSocket
{
    [self log:[NSString stringWithFormat:@"Connection closed."]];
    [self onDisconnect];
}

- (void) webSocketDidOpen:(Leanplum_WebSocket *)ws
{
    [self log:[NSString stringWithFormat:@"Connection opened."]];
    [self onConnect];
}

- (void) webSocket:(Leanplum_WebSocket *)ws didFailWithError:(NSError *)error
{
    NSLog(@"Leanplum: ERROR: Connection failed with error ... %@", [error localizedDescription]);
}

- (void) webSocket:(Leanplum_WebSocket *)ws didReceiveMessage:(NSString*)message
{
    [self onData:message];
}

# pragma mark -

- (void) log:(NSString *)message
{
#ifdef DEBUG
    NSLog(@"Leanplum: %@", message);
#endif
}

- (void) dealloc
{
    [_timeout invalidate];
}

@end


# pragma mark -
# pragma mark SocketIOPacket implementation

@implementation Leanplum_SocketIOPacket

@synthesize type, pId, name, ack, data, args, endpoint;

- (id) init
{
    self = [super init];
    if (self)
    {
        _types = @[@"disconnect",
                   @"connect",
                   @"heartbeat",
                   @"message",
                   @"json",
                   @"event",
                   @"ack",
                   @"error",
                   @"noop"];
    }
    return self;
}

- (id) initWithType:(NSString *)packetType
{
    self = [self init];
    if (self)
    {
        self.type = packetType;
    }
    return self;
}

- (id) initWithTypeIndex:(int)index
{
    self = [self init];
    if (self)
    {
        self.type = [self typeForIndex:index];
    }
    return self;
}

- (id) dataAsJSON
{
    return [LPJSON JSONFromString:self.data];
}

- (NSNumber *) typeAsNumber
{
    int index = (int) [_types indexOfObject:self.type];
    NSNumber *num = [NSNumber numberWithInt:index];
    return num;
}

- (NSString *) typeForIndex:(int)index
{
    return _types[index];
}

@end
