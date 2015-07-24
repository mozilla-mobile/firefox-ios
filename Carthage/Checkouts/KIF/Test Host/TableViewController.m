//
//  TableViewController.m
//  KIF
//
//  Created by Hilton Campbell on 4/12/14.
//
//

@interface TableViewController : UITableViewController

@end

@implementation TableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    // Do nothing, this method is needed to activate reordering in edit mode
}

@end
