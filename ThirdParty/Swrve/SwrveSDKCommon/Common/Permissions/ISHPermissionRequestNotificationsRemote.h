//
//  ISHPermissionRequestNotificationsRemote.h
//  ISHPermissionKit
//
//  Created by Sergio Mira on 21.04.15.
//  Copyright (c) 2014 iosphere GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ISHPermissionRequest.h"

@interface ISHPermissionRequestNotificationsRemote : ISHPermissionRequest
@property (nonatomic) UIUserNotificationSettings *notificationSettings;

-(void)requestUserPermissionWithoutCompleteBlock;

@end
