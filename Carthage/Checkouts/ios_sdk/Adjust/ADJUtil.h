//
//  ADJUtil.h
//  Adjust
//
//  Created by Christian Wellenbrock on 2013-07-05.
//  Copyright (c) 2013 adjust GmbH. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "ADJActivityKind.h"
#import "ADJResponseData.h"
#import "ADJActivityPackage.h"
#import "ADJEvent.h"
#import "ADJBackoffStrategy.h"
#import "ADJConfig.h"

typedef void (^selfInjectedBlock)(id);

@interface ADJUtil : NSObject

+ (void)updateUrlSessionConfiguration:(ADJConfig *)config;

+ (NSString *)baseUrl;
+ (NSString *)clientSdk;

+ (void)excludeFromBackup:(NSString *)filename;
+ (NSString *)formatSeconds1970:(double)value;
+ (NSString *)formatDate:(NSDate *)value;
+ (NSDictionary *) buildJsonDict:(NSData *)jsonData
                    exceptionPtr:(NSException **)exceptionPtr
                        errorPtr:(NSError **)error;

+ (NSString *)getFullFilename:(NSString *) baseFilename;

+ (id)readObject:(NSString *)filename
      objectName:(NSString *)objectName
           class:(Class) classToRead;

+ (void)writeObject:(id)object
           filename:(NSString *)filename
         objectName:(NSString *)objectName;

+ (NSString *) queryString:(NSDictionary *)parameters;
+ (BOOL)isNull:(id)value;
+ (BOOL)isNotNull:(id)value;

+ (void)sendPostRequest:(NSURL *)baseUrl
              queueSize:(NSUInteger)queueSize
     prefixErrorMessage:(NSString *)prefixErrorMessage
     suffixErrorMessage:(NSString *)suffixErrorMessage
        activityPackage:(ADJActivityPackage *)activityPackage
    responseDataHandler:(void (^) (ADJResponseData * responseData))responseDataHandler;

+ (void)sendRequest:(NSMutableURLRequest *)request
 prefixErrorMessage:(NSString *)prefixErrorMessage
    activityPackage:(ADJActivityPackage *)activityPackage
responseDataHandler:(void (^) (ADJResponseData * responseData))responseDataHandler;

+ (void)sendRequest:(NSMutableURLRequest *)request
 prefixErrorMessage:(NSString *)prefixErrorMessage
 suffixErrorMessage:(NSString *)suffixErrorMessage
    activityPackage:(ADJActivityPackage *)activityPackage
responseDataHandler:(void (^) (ADJResponseData * responseData))responseDataHandler;

+ (NSDictionary *)convertDictionaryValues:(NSDictionary *)dictionary;

+ (NSURL*)convertUniversalLink:(NSURL *)url scheme:(NSString *)scheme;
+ (NSString*)idfa;
+ (NSString *)secondsNumberFormat:(double)seconds;
+ (NSTimeInterval)waitingTime:(NSInteger)retries
              backoffStrategy:(ADJBackoffStrategy *)backoffStrategy;
+ (void)launchInMainThread:(NSObject *)receiver
                  selector:(SEL)selector
                withObject:(id)object;
+ (void)launchInMainThread:(dispatch_block_t)block;
+ (BOOL)isValidParameter:(NSString *)attribute
           attributeType:(NSString *)attributeType
           parameterName:(NSString *)parameterName;
+ (NSDictionary *)mergeParameters:(NSDictionary *)target
                           source:(NSDictionary *)source
                    parameterName:(NSString *)parameterName;

+ (void)launchInQueue:(dispatch_queue_t)queue
           selfInject:(id)selfInject
                block:(selfInjectedBlock)block;
+ (BOOL)deleteFile:(NSString *)filename;

+ (void)launchDeepLinkMain:(NSURL *)deepLinkUrl;
@end
