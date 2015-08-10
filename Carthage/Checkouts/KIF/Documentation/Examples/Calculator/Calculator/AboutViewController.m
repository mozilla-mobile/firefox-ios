//
//  AboutViewController.m
//  Calculator
//
//  Created by Brian Nickel on 12/14/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "AboutViewController.h"

@interface AboutViewController ()

@end

@implementation AboutViewController

- (id)init
{
    self = [super initWithNibName:@"AboutViewController" bundle:nil];
    if (self) {
        self.title = @"About";
    }
    return self;
}

@end
