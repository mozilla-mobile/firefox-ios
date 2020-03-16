//
//  ADJFailureResponseData.h
//  adjust
//
//  Created by Pedro Filipe on 05/01/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ADJSessionFailure : NSObject <NSCopying>

/**
 * @brief Message from the adjust backend.
 */
@property (nonatomic, copy, nullable) NSString *message;

/**
 * @brief Timestamp from the adjust backend.
 */
@property (nonatomic, copy, nullable) NSString *timeStamp;

/**
 * @brief Adjust identifier of the device.
 */
@property (nonatomic, copy, nullable) NSString *adid;

/**
 * @brief Information whether sending of the package will be retried or not.
 */
@property (nonatomic, assign) BOOL willRetry;

/**
 * @brief Backend response in JSON format.
 */
@property (nonatomic, strong, nullable) NSDictionary *jsonResponse;

/**
 * @brief Initialisation method.
 *
 * @return ADJSessionFailure instance.
 */
+ (nullable ADJSessionFailure *)sessionFailureResponseData;

@end
