//
//  ATLControlWebSocketClient.h
//  AdjustTestLibrary
//
//  Created by Serj on 20.02.19.
//  Copyright © 2019 adjust. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PocketSocket/PSWebSocket.h"
#import "ATLTestLibrary.h"

NS_ASSUME_NONNULL_BEGIN

@interface ATLControlWebSocketClient : NSObject <PSWebSocketDelegate>

- (void)initializeWebSocketWithControlUrl:(NSString*)controlUrl
                           andTestLibrary:(ATLTestLibrary*)testLibrary;

- (void)reconnectIfNeeded;

- (void)sendInitTestSessionSignal:(NSString*)testSessionId;

@end

NS_ASSUME_NONNULL_END
