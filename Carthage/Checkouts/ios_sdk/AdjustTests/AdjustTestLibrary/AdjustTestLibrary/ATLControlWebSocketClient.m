//
//  ATLControlWebSocketClient.m
//  AdjustTestLibrary
//
//  Created by Serj on 20.02.19.
//  Copyright © 2019 adjust. All rights reserved.
//

#import "ATLControlWebSocketClient.h"
#import "ATLControlSignal.h"
#import "ATLUtil.h"
#import "ATLConstants.h"

@interface ATLControlWebSocketClient()

@property (nonatomic, strong) PSWebSocket *socket;
@property (nonatomic, weak) ATLTestLibrary *testLibrary;

@end

@implementation ATLControlWebSocketClient

- (void)initializeWebSocketWithControlUrl:(NSString*)controlUrl
                           andTestLibrary:(ATLTestLibrary*)testLibrary
{
    self.testLibrary = testLibrary;
    
    // create the NSURLRequest that will be sent as the handshake
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:controlUrl]];
    
    // create the socket and assign delegate
    self.socket = [PSWebSocket clientSocketWithRequest:request];
    self.socket.delegate = self;
    
    // open socket
    [self.socket open];
}

- (void)reconnectIfNeeded {
    if ([self.socket readyState] == PSWebSocketReadyStateOpen || [self.socket readyState] == PSWebSocketReadyStateConnecting) {
        return;
    }
    [ATLUtil debug:@"[WebSocket] reconnecting web socket client ..."];
    [NSThread sleepForTimeInterval:ONE_SECOND];
    [self.socket open];
}

- (void)sendInitTestSessionSignal:(NSString*)testSessionId {
    ATLControlSignal *initSignal = [[ATLControlSignal alloc] initWithSignalType:ATLSignalTypeInitTestSession andSignalValue:testSessionId];
    [self.socket send:[initSignal toJson]];
}

#pragma mark - PSWebSocketDelegate

- (void)webSocketDidOpen:(PSWebSocket *)webSocket {
    [ATLUtil debug:@"[WebSocket] connection opened with the server"];
}

- (void)webSocket:(PSWebSocket *)webSocket didReceiveMessage:(id)message {
    [ATLUtil debug:@"[WebSocket] received a message: %@", message];
    ATLControlSignal *incomingSignal = [[ATLControlSignal alloc] initWithJson:message];
    [self handleIncomingSignal:incomingSignal];
}

- (void)handleIncomingSignal:(ATLControlSignal*)incomingSignal {
    if ([incomingSignal getType] == ATLSignalTypeInfo) {
        [ATLUtil debug:@"[WebSocket] info from the server: %@", [incomingSignal getValue]];
    } else if ([incomingSignal getType] == ATLSignalTypeEndWait) {
        NSString *reason = [incomingSignal getValue];
        [ATLUtil debug:@"[WebSocket] end wait signal recevied, reason: %@", reason];
        [[self testLibrary] signalEndWaitWithReason:reason];
    } else if ([incomingSignal getType] == ATLSignalTypeCancelCurrentTest) {
        NSString *reason = [incomingSignal getValue];
        [ATLUtil debug:@"[WebSocket] cancel test recevied, reason: %@", reason];
        [[self testLibrary] cancelTestAndGetNext];
    } else {
        [ATLUtil debug:@"[WebSocket] unknown signal received by the server. Value: %@", [incomingSignal getValue]];
    }
}

- (void)webSocket:(PSWebSocket *)webSocket didFailWithError:(NSError *)error {
    [ATLUtil debug:@"[WebSocket] handshake/connection failed with an error: %@", error];
}

- (void)webSocket:(PSWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    [ATLUtil debug:@"[WebSocket] connection closed with code: %@, reason: %@, wasClean: %@", @(code), reason, (wasClean) ? @"YES" : @"NO"];
}

@end
