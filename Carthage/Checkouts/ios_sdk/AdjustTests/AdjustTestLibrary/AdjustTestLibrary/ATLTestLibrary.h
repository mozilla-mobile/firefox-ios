//
//  AdjustTestLibrary.h
//  AdjustTestLibrary
//
//  Created by Pedro on 18.04.17.
//  Copyright © 2017 adjust. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ATLUtilNetworking.h"
#import "ATLBlockingQueue.h"

@protocol AdjustCommandDelegate <NSObject>
@optional
- (void)executeCommand:(NSString *)className
            methodName:(NSString *)methodName
            parameters:(NSDictionary *)parameters;

- (void)executeCommand:(NSString *)className
            methodName:(NSString *)methodName
        jsonParameters:(NSString *)jsonParameters;

- (void)executeCommandRawJson:(NSString *)json;
@end

@interface ATLTestLibrary : NSObject

- (NSString *)currentBasePath;

- (ATLBlockingQueue *)waitControlQueue;

- (id)initWithBaseUrl:(NSString *)baseUrl
        andControlUrl:(NSString *)controlUrl
   andCommandDelegate:(NSObject<AdjustCommandDelegate> *)commandDelegate;

- (void)addTest:(NSString *)testName;

- (void)addTestDirectory:(NSString *)testDirectory;

- (void)startTestSession:(NSString *)clientSdk;

- (void)resetTestLibrary;

- (void)readResponse:(ATLHttpResponse *)httpResponse;

- (void)addInfoToSend:(NSString *)key
                value:(NSString *)value;

- (void)sendInfoToServer:(NSString *)basePath;

- (void)signalEndWaitWithReason:(NSString *)reason;

- (void)cancelTestAndGetNext;

- (void)doNotExitAfterEnd;

+ (ATLTestLibrary *)testLibraryWithBaseUrl:(NSString *)baseUrl
                             andControlUrl:(NSString *)controlUrl
                        andCommandDelegate:(NSObject<AdjustCommandDelegate> *)commandDelegate;

+ (NSURL *)baseUrl;

@end
