//
//  ADJUtil.h
//  Adjust
//
//  Created by Christian Wellenbrock on 2013-07-05.
//  Copyright (c) 2013 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ADJEvent.h"
#import "ADJConfig.h"
#import "ADJActivityKind.h"
#import "ADJResponseData.h"
#import "ADJActivityPackage.h"
#import "ADJBackoffStrategy.h"

typedef void (^selfInjectedBlock)(id);
typedef void (^isInactiveInjected)(BOOL);

@interface ADJUtil : NSObject

+ (void)teardown;

+ (id)readObject:(NSString *)fileName
      objectName:(NSString *)objectName
           class:(Class)classToRead;

+ (void)excludeFromBackup:(NSString *)filename;

+ (void)launchDeepLinkMain:(NSURL *)deepLinkUrl;

+ (void)launchInMainThread:(dispatch_block_t)block;

+ (BOOL)isMainThread;

+ (BOOL)isInactive;

+ (void)launchInMainThreadWithInactive:(isInactiveInjected)isInactiveblock;

+ (void)updateUrlSessionConfiguration:(ADJConfig *)config;

+ (void)writeObject:(id)object
           fileName:(NSString *)fileName
         objectName:(NSString *)objectName;

+ (void)launchInMainThread:(NSObject *)receiver
                  selector:(SEL)selector
                withObject:(id)object;

+ (void)launchInQueue:(dispatch_queue_t)queue
           selfInject:(id)selfInject
                block:(selfInjectedBlock)block;

+ (void)sendGetRequest:(NSURL *)baseUrl
              basePath:(NSString *)basePath
    prefixErrorMessage:(NSString *)prefixErrorMessage
       activityPackage:(ADJActivityPackage *)activityPackage
   responseDataHandler:(void (^)(ADJResponseData *responseData))responseDataHandler;

+ (void)sendPostRequest:(NSURL *)baseUrl
              queueSize:(NSUInteger)queueSize
     prefixErrorMessage:(NSString *)prefixErrorMessage
     suffixErrorMessage:(NSString *)suffixErrorMessage
        activityPackage:(ADJActivityPackage *)activityPackage
    responseDataHandler:(void (^)(ADJResponseData *responseData))responseDataHandler;

+ (NSString *)idfa;

+ (NSString *)clientSdk;

+ (NSString *)getUpdateTime;

+ (NSString *)getInstallTime;

+ (NSString *)formatDate:(NSDate *)value;

+ (NSString *)formatSeconds1970:(double)value;

+ (NSString *)secondsNumberFormat:(double)seconds;

+ (NSString *)queryString:(NSDictionary *)parameters;

+ (NSString *)convertDeviceToken:(NSData *)deviceToken;

+ (BOOL)isNull:(id)value;

+ (BOOL)isNotNull:(id)value;

+ (BOOL)deleteFileWithName:(NSString *)filename;

+ (BOOL)checkAttributionDetails:(NSDictionary *)attributionDetails;

+ (BOOL)isValidParameter:(NSString *)attribute
           attributeType:(NSString *)attributeType
           parameterName:(NSString *)parameterName;

+ (NSDictionary *)convertDictionaryValues:(NSDictionary *)dictionary;

+ (NSDictionary *)buildJsonDict:(NSData *)jsonData
                   exceptionPtr:(NSException **)exceptionPtr
                       errorPtr:(NSError **)error;

+ (NSDictionary *)mergeParameters:(NSDictionary *)target
                           source:(NSDictionary *)source
                    parameterName:(NSString *)parameterName;

+ (NSURL *)convertUniversalLink:(NSURL *)url scheme:(NSString *)scheme;

+ (NSTimeInterval)waitingTime:(NSInteger)retries
              backoffStrategy:(ADJBackoffStrategy *)backoffStrategy;

+ (NSNumber *)readReachabilityFlags;

+ (BOOL)isDeeplinkValid:(NSURL *)url;

+ (NSString *)sdkVersion;

#if !TARGET_OS_TV
+ (NSString *)readMCC;

+ (NSString *)readMNC;

+ (NSString *)readCurrentRadioAccessTechnology;
#endif

@end
