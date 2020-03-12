//
//  ADJSuccessResponseData.h
//  adjust
//
//  Created by Pedro Filipe on 05/01/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ADJSessionSuccess : NSObject <NSCopying>

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
 * @brief Backend response in JSON format.
 */
@property (nonatomic, strong, nullable) NSDictionary *jsonResponse;

/**
 * @brief Initialisation method.
 *
 * @return ADJSessionSuccess instance.
 */
+ (nullable ADJSessionSuccess *)sessionSuccessResponseData;

@end
