//
//  LPLocationManager.h
//  Version 1.4.3
//
//  Copyright (c) 2016 Leanplum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface LPLocationManager : NSObject <CLLocationManagerDelegate>

+ (LPLocationManager *)sharedManager;

/**
 * Set before [Leanplum start].
 * Chooses whether to authorize the location permission automatically when the app starts.
 * Call -authorize if needsAuthorization returns YES.
 */
@property (nonatomic, assign) BOOL authorizeAutomatically;

/**
 * Returns YES if the user has not given the appropriate level of permissions for location access.
 * You should call -authorize if needsAuthorization is YES and authorizeAutomatically is NO.
 */
@property (nonatomic, readonly) BOOL needsAuthorization;

/**
 * Authorizes location access by prompting the user for permission.
 * Prompts for use within the app if there are active in-app messages using regions.
 * Prompts for use in the background if there are active push notifications using regions.
 */
- (void)authorize;

@end
