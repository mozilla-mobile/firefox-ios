//
//  TableViewController.m
//  KIF
//
//  Created by Hilton Campbell on 4/12/14.
//
//

@interface TableViewController : UITableViewController <UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@end

@implementation TableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;

    // Need to set this explicitly, as the default is different between iPhone and iPad and the value is ignored if set explicitly to "none"
    self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    // Do nothing, this method is needed to activate reordering in edit mode
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {

    return YES;
}

// Work around a bug on iOS9 that accessibility trait Selected doesn't get set
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if ([[[UIDevice currentDevice] systemVersion] compare:@"9.0" options:NSNumericSearch] == NSOrderedSame) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [cell setAccessibilityTraits:cell.accessibilityTraits | UIAccessibilityTraitSelected];
    }

    return indexPath;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if ([[[UIDevice currentDevice] systemVersion] compare:@"9.0" options:NSNumericSearch] == NSOrderedSame) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [cell setAccessibilityTraits:cell.accessibilityTraits ^ UIAccessibilityTraitSelected];
    }
    
    return indexPath;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return UITableViewCellEditingStyleDelete;
    
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Since the table view uses static cells, it is not possible to remove the row,
        // so let's just change the label to have something to check in unit tests
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        cell.textLabel.text = @"Deleted";
        [self.tableView setEditing:NO animated:YES];
        
        // NOTE: These don't work very well
        // [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        // [self.tableView reloadData];
    }
    
}

@end
