SWTableViewCell
===============

<p align="center"><img src="http://i.imgur.com/njKCjK8.gif"/></p>

An easy-to-use UITableViewCell subclass that implements a swipeable content view which exposes utility buttons (similar to iOS 7 Mail Application)

##Usage
In your Podfile:
<pre>pod 'SWTableViewCell', '~> 0.3.7'</pre>

Or just clone this repo and manually add source to project

##Functionality
###Right Utility Buttons
Utility buttons that become visible on the right side of the Table View Cell when the user swipes left. This behavior is similar to that seen in the iOS apps Mail and Reminders.

<p align="center"><img src="http://i.imgur.com/gDZFRpr.gif"/></p>

###Left Utility Buttons
Utility buttons that become visible on the left side of the Table View Cell when the user swipes right. 

<p align="center"><img src="http://i.imgur.com/qt6aISz.gif"/></p>

###Features
* Dynamic utility button scalling. As you add more buttons to a cell, the other buttons on that side get smaller to make room
* Smart selection: The cell will pick up touch events and either scroll the cell back to center or fire the delegate method `- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath` 
<p align="center"><img src="http://i.imgur.com/TYGx9h8.gif"/></p>
So the cell will not be considered selected when the user touches the cell while utility buttons are visible, instead the cell will slide back into place (same as iOS 7 Mail App functionality)
* Create utilty buttons with either a title or an icon along with a RGB color
* Tested on iOS 6.1 and above, including iOS 7

##Usage

###Standard Table View Cells

In your `tableView:cellForRowAtIndexPath:` method you set up the SWTableView cell and add an arbitrary amount of utility buttons to it using the included `NSMutableArray+SWUtilityButtons` category.

```objc
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    
    SWTableViewCell *cell = (SWTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[SWTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.leftUtilityButtons = [self leftButtons];
        cell.rightUtilityButtons = [self rightButtons];
        cell.delegate = self;
    }
    
    NSDate *dateObject = _testArray[indexPath.row];
    cell.textLabel.text = [dateObject description];
    cell.detailTextLabel.text = @"Some detail text";
    
    return cell;
}

- (NSArray *)rightButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0]
                                                title:@"More"];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                title:@"Delete"];

    return rightUtilityButtons;
}

- (NSArray *)leftButtons
{
    NSMutableArray *leftUtilityButtons = [NSMutableArray new];
    
    [leftUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.07 green:0.75f blue:0.16f alpha:1.0]
                                                icon:[UIImage imageNamed:@"check.png"]];
    [leftUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:1.0f blue:0.35f alpha:1.0]
                                                icon:[UIImage imageNamed:@"clock.png"]];
    [leftUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188f alpha:1.0]
                                                icon:[UIImage imageNamed:@"cross.png"]];
    [leftUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.55f green:0.27f blue:0.07f alpha:1.0]
                                                icon:[UIImage imageNamed:@"list.png"]];
    
    return leftUtilityButtons;
}
```

###Custom Table View Cells

Thanks to [Matt Bowman](https://github.com/MattCBowman) you can now create custom table view cells using Interface Builder that have the capabilities of an SWTableViewCell

The first step is to design your cell either in a standalone nib or inside of a
table view using prototype cells. Make sure to set the custom class on the 
cell in interface builder to the subclass you made for it:

<p align="center"><img src="http://i.imgur.com/mfrT1Ex.png"/></p>

Then set the cell reuse identifier:

<p align="center"><img src="http://i.imgur.com/dlmArZ1.png"/></p>

When writing your custom table view cell's code, make sure your cell is a
subclass of SWTableViewCell:

```objc

#import <SWTableViewCell.h>

@interface MyCustomTableViewCell : SWTableViewCell

@property (weak, nonatomic) UILabel *customLabel;
@property (weak, nonatomic) UIImageView *customImageView;

@end

```

If you are using a separate nib and not a prototype cell, you'll need to be sure to register the nib in your table view:

```objc

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerNib:[UINib nibWithNibName:@"MyCustomTableViewCellNibFileName" bundle:nil] forCellReuseIdentifier:@"MyCustomCell"];
}

```

Then, in the `tableView:cellForRowAtIndexPath:` method of your `UITableViewDelegate` (usually your view controller), initialize your custom cell:

```objc
- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString *cellIdentifier = @"MyCustomCell";
    
    MyCustomTableViewCell *cell = (MyCustomTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier 
                                                                                           forIndexPath:indexPath];

    cell.leftUtilityButtons = [self leftButtons];
    cell.rightUtilityButtons = [self rightButtons];
    cell.delegate = self;
    
    cell.customLabel.text = @"Some Text";
    cell.customImageView.image = [UIImage imageNamed:@"MyAwesomeTableCellImage"];
    [cell setCellHeight:cell.frame.size.height];
    return cell;
}
```

###Delegate

The delegate `SWTableViewCellDelegate` is used by the developer to find out which button was pressed. There are five methods:

```objc
// click event on left utility button
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index;

// click event on right utility button
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index;

// utility button open/close event
- (void)swipeableTableViewCell:(SWTableViewCell *)cell scrollingToState:(SWCellState)state;

// prevent multiple cells from showing utilty buttons simultaneously
- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell;

// prevent cell(s) from displaying left/right utility buttons
- (BOOL)swipeableTableViewCell:(SWTableViewCell *)cell canSwipeToState:(SWCellState)state;
```

The index signifies which utility button the user pressed, for each side the button indices are ordered from right to left 0...n

####Example

```objc
#pragma mark - SWTableViewDelegate

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index {
    switch (index) {
        case 0:
            NSLog(@"check button was pressed");
            break;
        case 1:
            NSLog(@"clock button was pressed");
            break;
        case 2:
            NSLog(@"cross button was pressed");
            break;
        case 3:
            NSLog(@"list button was pressed");
        default:
            break;
    }
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    switch (index) {
        case 0:
            NSLog(@"More button was pressed");
            break;
        case 1:
        {
            // Delete button was pressed
            NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
            
            [_testArray removeObjectAtIndex:cellIndexPath.row];
            [self.tableView deleteRowsAtIndexPaths:@[cellIndexPath] 
                    withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        }
        default:
            break;
    }
}
```

(This is all code from the included example project)

###Gotchas

#### Seperator Insets
* If you have left utility button on iOS 7, I recommend changing your Table View's seperatorInset so the seperator stretches the length of the screen
<pre> tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0); </pre>


##Contributing
Use [Github issues](https://github.com/cewendel/SWTableViewCell/issues) to track bugs and feature requests.

##Contact

Chris Wendel

- http://twitter.com/CEWendel

## Licence

MIT 





