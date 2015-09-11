//
//  RootViewController.h
//  Testable
//
//  Created by Eric Firestone on 6/2/11.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import <UIKit/UIKit.h>

@interface RootViewController : UITableViewController {
    NSArray *titles;
}

@property (nonatomic, strong) NSArray *titles;

@end
