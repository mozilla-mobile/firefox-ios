//
//  RootViewController.m
//  Testable
//
//  Created by Eric Firestone on 6/2/11.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "RootViewController.h"

@implementation RootViewController

@synthesize titles;

- (void)viewDidLoad
{
    self.tableView.delegate = self;
    self.titles = [NSArray arrayWithObjects:@"Red", @"Green", @"Blue", @"Purple", nil];
    
    [super viewDidLoad];
}

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.titles.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    cell.textLabel.text = [self.titles objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.navigationController.navigationBar.topItem.title = [NSString stringWithFormat:@"Selected: %@", [self.titles objectAtIndex:indexPath.row]];
}

@end
