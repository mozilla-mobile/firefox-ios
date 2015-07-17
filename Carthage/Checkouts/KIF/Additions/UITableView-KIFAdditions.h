//
//  UITableView-KIFAdditions.h
//  KIF
//
//  Created by Hilton Campbell on 4/12/14.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import <UIKit/UIKit.h>

@interface UITableView (KIFAdditions)

- (BOOL)dragCell:(UITableViewCell *)cell toIndexPath:(NSIndexPath *)indexPath error:(NSError **)error;

@end
