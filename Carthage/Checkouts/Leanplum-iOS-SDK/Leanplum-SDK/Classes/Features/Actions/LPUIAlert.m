//
//  LPUIAlert.m
//  Shows an alert with a callback block.
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

#import "LPUIAlert.h"
#import "LPConstants.h"
#import "LPCountAggregator.h"

@implementation LPUIAlert

+ (void)showWithTitle:(NSString *)title
              message:(NSString *)message
    cancelButtonTitle:(NSString *)cancelButtonTitle
    otherButtonTitles:(NSArray *)otherButtonTitles
                block:(LeanplumUIAlertCompletionBlock)block
{
    if (NSClassFromString(@"UIAlertController")) {
        UIAlertController *alert =
            [UIAlertController alertControllerWithTitle:title
                                                message:message
                                         preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:cancelButtonTitle
                                                         style:[otherButtonTitles count] ? UIAlertActionStyleCancel : UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
                                                           if (block) {
                                                               block(0);
                                                           }
                                                       }];
        [alert addAction:action];
        
        int currentIndex = 0;
        for (NSString *buttonTitle in otherButtonTitles) {
            int buttonIndex = ++currentIndex;
            UIAlertAction *action = [UIAlertAction actionWithTitle:buttonTitle
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *action) {
                                                               if (block) {
                                                                   block(buttonIndex);
                                                               }
                                                           }];
            [alert addAction:action];
        }

        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert
                                                                                     animated:YES
                                                                                   completion:nil];
    } else
    {
        LPUIAlertView *alertView = [[LPUIAlertView alloc] initWithTitle:title
                                                                message:message
                                                               delegate:nil
                                                      cancelButtonTitle:cancelButtonTitle
                                                      otherButtonTitles:nil];
        alertView.delegate = alertView;
        for (NSString *buttonTitle in otherButtonTitles) {
            [alertView addButtonWithTitle:buttonTitle];
        }
        if (block) {
            alertView->block = block;
        }
        [alertView show];
    }
    [[LPCountAggregator sharedAggregator] incrementCount:@"show_With_title"];
}

@end

@implementation LPUIAlertView

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    LeanplumUIAlertCompletionBlock completion = ((LPUIAlertView*) alertView)->block;
    if (completion)
    {
        completion(buttonIndex);
    }
}

@end
