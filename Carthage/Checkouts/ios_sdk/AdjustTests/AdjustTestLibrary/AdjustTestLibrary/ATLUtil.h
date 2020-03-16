//
//  ATLUtil.h
//  AdjustTestLibrary
//
//  Created by Pedro on 18.04.17.
//  Copyright © 2017 adjust. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^selfInjectedBlock)(id);
typedef void (^operationBlock)(NSBlockOperation *);

@interface ATLUtil : NSObject

+ (void)debug:(NSString *)format, ...;
+ (void)launchInQueue:(dispatch_queue_t)queue
           selfInject:(id)selfInject
                block:(selfInjectedBlock)block;
+ (void)addOperationAfterLast:(NSOperationQueue *)operationQueue
                        block:(dispatch_block_t)block;
+ (void)addOperationAfterLast:(NSOperationQueue *)operationQueue
           blockWithOperation:(operationBlock)blockWithOperation;
+ (BOOL)isNull:(id)value;
+ (NSString *)adjTrim:(NSString *)value;
+ (NSString *)formatDate:(NSDate *)value;
+ (NSString *)parseDictionaryToJsonString:(NSDictionary *) dictionary;
+ (NSString *)appendBasePath:(NSString *)basePath path:(NSString *)path;
+ (NSString *)queryString:(NSDictionary *)parameters;
@end
