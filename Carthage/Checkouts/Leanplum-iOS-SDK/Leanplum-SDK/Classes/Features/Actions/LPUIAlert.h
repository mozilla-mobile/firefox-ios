//
//  LPUIAlert.h
//  Show an alert with a callback block.
//
//  Created by Ryan Maxwell on 29/08/13.
//  Copyright (c) 2013 Ryan Maxwell. All rights reserved.
//  Copyright (c) 2013 Leanplum, Inc. All rights reserved.
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.

#import "LPConstants.h"
#import <UIKit/UIKit.h>

typedef void (^LeanplumUIAlertCompletionBlock) (NSInteger buttonIndex);

@interface LPUIAlert : NSObject

+ (void)showWithTitle:(NSString *)title
              message:(NSString *)message
    cancelButtonTitle:(NSString *)cancelButtonTitle
    otherButtonTitles:(NSArray *)otherButtonTitles
                block:(LeanplumUIAlertCompletionBlock)block;

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wstrict-prototypes"
@interface LPUIAlertView : UIAlertView <UIAlertViewDelegate> {
  @public
    LeanplumUIAlertCompletionBlock block;
}
@end
#pragma clang diagnostic pop
