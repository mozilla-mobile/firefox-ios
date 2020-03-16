//
//  ADJEventSuccess.h
//  adjust
//
//  Created by Pedro Filipe on 17/02/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ADJEventSuccess : NSObject

/**
 * @brief Message from the adjust backend.
 */
@property (nonatomic, copy) NSString *message;

/**
 * @brief Timestamp from the adjust backend.
 */
@property (nonatomic, copy) NSString *timeStamp;

/**
 * @brief Adjust identifier of the device.
 */
@property (nonatomic, copy) NSString *adid;

/**
 * @brief Event token value.
 */
@property (nonatomic, copy) NSString *eventToken;

/**
 * @brief Event callback ID.
 */
@property (nonatomic, copy) NSString *callbackId;

/**
 * @brief Backend response in JSON format.
 */
@property (nonatomic, strong) NSDictionary *jsonResponse;

/**
 * @brief Initialisation method.
 *
 * @return ADJEventSuccess instance.
 */
+ (ADJEventSuccess *)eventSuccessResponseData;

@end
