//
//  AppDelegate.h
//  AdjustExample-ObjC
//
//  Created by Pedro Filipe (@nonelse) on 12th October 2015.
//  Copyright © 2015-2019 Adjust GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Adjust.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, AdjustDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
