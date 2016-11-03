//
//  HomeViewController.m
//  Calculator
//
//  Created by Brian Nickel on 12/14/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "HomeViewController.h"
#import "AboutViewController.h"
#import "BasicCalculatorViewController.h"

@interface HomeViewController ()

@end

@implementation HomeViewController

- (id)init
{
    self = [super initWithNibName:@"HomeViewController" bundle:nil];
    if (self) {
        self.title = @"Home";
    }
    return self;
}

- (IBAction)showBasicCalculator
{
    [self.navigationController pushViewController:[[BasicCalculatorViewController alloc] init] animated:YES];
}

- (IBAction)showAbout
{
    [self.navigationController pushViewController:[[AboutViewController alloc] init] animated:YES];
}

@end
