/*
     File: RecipeDetailViewController.m 
 Abstract: Table view controller to manage an editable table view that displays information about a recipe.
 The table view uses different cell types for different row types.
  
  Version: 1.5 
  
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple 
 Inc. ("Apple") in consideration of your agreement to the following 
 terms, and your use, installation, modification or redistribution of 
 this Apple software constitutes acceptance of these terms.  If you do 
 not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software. 
  
 In consideration of your agreement to abide by the following terms, and 
 subject to these terms, Apple grants you a personal, non-exclusive 
 license, under Apple's copyrights in this original Apple software (the 
 "Apple Software"), to use, reproduce, modify and redistribute the Apple 
 Software, with or without modifications, in source and/or binary forms; 
 provided that if you redistribute the Apple Software in its entirety and 
 without modifications, you must retain this notice and the following 
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. may 
 be used to endorse or promote products derived from the Apple Software 
 without specific prior written permission from Apple.  Except as 
 expressly stated in this notice, no other rights or licenses, express or 
 implied, are granted by Apple herein, including but not limited to any 
 patent rights that may be infringed by your derivative works or by other 
 works in which the Apple Software may be incorporated. 
  
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE 
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION 
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS 
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND 
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS. 
  
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL 
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, 
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED 
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), 
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE 
 POSSIBILITY OF SUCH DAMAGE. 
  
 Copyright (C) 2011 Apple Inc. All Rights Reserved. 
  
 */

#import "MGPRecipesAppDelegate.h"
#import "RecipeDetailViewController.h"

#import "Recipe.h"
#import "Ingredient.h"

#import "InstructionsViewController.h"
#import "TypeSelectionViewController.h"
#import "RecipePhotoViewController.h"
#import "IngredientDetailViewController.h"


@interface RecipeDetailViewController (PrivateMethods)
- (void)updatePhotoButton;
@end




@implementation RecipeDetailViewController

#define TYPE_SECTION 0
#define INGREDIENTS_SECTION 1
#define INSTRUCTIONS_SECTION 2


#pragma mark -
#pragma mark View controller

// this listens for the notification that the app delegate has processed new changes from iCloud
// it then decides if it wants to reload the view based on whether or not the recipe shown in the
// detail view is impacted by those changes.
// Basically it trolls through the notification userInfo to see if our recipe or its photo was changed
- (void)reloadRecipe:(NSNotification*)note {
    NSDictionary* ui = [note userInfo];
    NSManagedObjectID* recipeID = [self.recipe objectID];
    NSManagedObjectID* photoID = [self.recipe.image objectID];
    
    if (recipeID) {
        BOOL shouldReload = (ui[NSInvalidatedAllObjectsKey] != nil);
        BOOL wasInvalidated = (ui[NSInvalidatedAllObjectsKey] != nil);
        
        NSArray *interestingKeys = @[NSUpdatedObjectsKey, NSRefreshedObjectsKey, NSInvalidatedObjectsKey];
        
        for (NSString* key in interestingKeys) {
            NSSet* collection = ui[key];
            for (NSManagedObjectID* moid in collection) {
                if ([moid isEqual:recipeID] || [moid isEqual:photoID]) {
                    if ([key isEqual:NSInvalidatedObjectsKey]) {
                        wasInvalidated = YES;
                    }
                    shouldReload = YES;
                    break;
                }
            }
            if (shouldReload) {
                break;
            }
        }

        if (shouldReload) {
            NSManagedObjectContext *moc = self.recipe.managedObjectContext;
            
            if (wasInvalidated) {
// if the object was invalidated, it is no longer a part of our MOC
// we need a new MO for the objectID we care about
// this generally only happens if the object was released to rc 0, the persistent store removed, or the MOC reset
                self.recipe = (Recipe*)[moc objectWithID:recipeID];
            }
            
            [self viewWillAppear:NO];
        }
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // Create and set the table header view.
    if (self.tableHeaderView == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"DetailHeaderView" owner:self options:nil];
        self.tableView.tableHeaderView = self.tableHeaderView;
        self.tableView.allowsSelectionDuringEditing = YES;
    }
    
// listen to our app delegates notification that we might want to refresh our detail view
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadRecipe:) name:@"RefreshAllViews" object:[[UIApplication sharedApplication] delegate]];
}


- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
	
    [self.photoButton setImage:self.recipe.thumbnailImage forState:UIControlStateNormal];
	self.navigationItem.title = self.recipe.name;
    self.nameTextField.text = self.recipe.name;
    self.overviewTextField.text = self.recipe.overview;
    self.prepTimeTextField.text = self.recipe.prepTime;
	[self updatePhotoButton];

	/*
	 Create a mutable array that contains the recipe's ingredients ordered by displayOrder.
	 The table view uses this array to display the ingredients.
	 Core Data relationships are represented by sets, so have no inherent order. Order is "imposed" using the displayOrder attribute, but it would be inefficient to create and sort a new array each time the ingredients section had to be laid out or updated.
	 */
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayOrder" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:&sortDescriptor count:1];
	
	NSMutableArray *sortedIngredients = [[NSMutableArray alloc] initWithArray:[self.recipe.ingredients allObjects]];
	[sortedIngredients sortUsingDescriptors:sortDescriptors];
	self.ingredients = sortedIngredients;
	
	// Update recipe type and ingredients on return.
    [self.tableView reloadData]; 
}


- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.tableHeaderView = nil;
	self.photoButton = nil;
	self.nameTextField = nil;
	self.overviewTextField = nil;
	self.prepTimeTextField = nil;
	[super viewDidUnload];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


#pragma mark -
#pragma mark Editing

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    
    [super setEditing:editing animated:animated];
    
	[self updatePhotoButton];
	self.nameTextField.enabled = editing;
	self.overviewTextField.enabled = editing;
	self.prepTimeTextField.enabled = editing;
	[self.navigationItem setHidesBackButton:editing animated:YES];
	

	[self.tableView beginUpdates];
	
    NSUInteger ingredientsCount = [self.recipe.ingredients count];

    NSArray *ingredientsInsertIndexPath = @[[NSIndexPath indexPathForRow:ingredientsCount inSection:INGREDIENTS_SECTION]];
    
    if (editing) {
        [self.tableView insertRowsAtIndexPaths:ingredientsInsertIndexPath withRowAnimation:UITableViewRowAnimationTop];
		self.overviewTextField.placeholder = @"Overview";
	} else {
        [self.tableView deleteRowsAtIndexPaths:ingredientsInsertIndexPath withRowAnimation:UITableViewRowAnimationTop];
		self.overviewTextField.placeholder = @"";
    }
    
    [self.tableView endUpdates];
	
	/*
	 If editing is finished, save the managed object context.
	 */
	if (!editing) {
		NSManagedObjectContext *context = self.recipe.managedObjectContext;
        [context MR_saveToPersistentStoreAndWait];
	}
}


- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	
	if (textField == self.nameTextField) {
		self.recipe.name = self.nameTextField.text;
		self.navigationItem.title = self.recipe.name;
	}
	else if (textField == self.overviewTextField) {
		self.recipe.overview = self.overviewTextField.text;
	}
	else if (textField == self.prepTimeTextField) {
		self.recipe.prepTime = self.prepTimeTextField.text;
	}
	return YES;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}


#pragma mark -
#pragma mark UITableView Delegate/Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title = nil;
    // Return a title or nil as appropriate for the section.
    switch (section) {
        case TYPE_SECTION:
            title = @"Category";
            break;
        case INGREDIENTS_SECTION:
            title = @"Ingredients";
            break;
        default:
            break;
    }
    return title;;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 0;
    
    /*
     The number of rows depends on the section.
     In the case of ingredients, if editing, add a row in editing mode to present an "Add Ingredient" cell.
	 */
    switch (section) {
        case TYPE_SECTION:
        case INSTRUCTIONS_SECTION:
            rows = 1;
            break;
        case INGREDIENTS_SECTION:
            rows = [self.recipe.ingredients count];
            if (self.editing) {
                rows++;
            }
            break;
		default:
            break;
    }
    return rows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
     // For the Ingredients section, if necessary create a new cell and configure it with an additional label for the amount.  Give the cell a different identifier from that used for cells in other sections so that it can be dequeued separately.
    if (indexPath.section == INGREDIENTS_SECTION) {
		NSUInteger ingredientCount = [self.recipe.ingredients count];
        NSInteger row = indexPath.row;
		
        if (indexPath.row < ingredientCount) {
            // If the row is within the range of the number of ingredients for the current recipe, then configure the cell to show the ingredient name and amount.
			static NSString *IngredientsCellIdentifier = @"IngredientsCell";
			
			cell = [tableView dequeueReusableCellWithIdentifier:IngredientsCellIdentifier];
			
			if (cell == nil) {
				 // Create a cell to display an ingredient.
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:IngredientsCellIdentifier];
				cell.accessoryType = UITableViewCellAccessoryNone;
			}
			
            Ingredient *ingredient = (self.ingredients)[row];
            cell.textLabel.text = ingredient.name;
			cell.detailTextLabel.text = ingredient.amount;
        } else {
            // If the row is outside the range, it's the row that was added to allow insertion (see tableView:numberOfRowsInSection:) so give it an appropriate label.
			static NSString *AddIngredientCellIdentifier = @"AddIngredientCell";
			
			cell = [tableView dequeueReusableCellWithIdentifier:AddIngredientCellIdentifier];
			if (cell == nil) {
				 // Create a cell to display "Add Ingredient".
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:AddIngredientCellIdentifier];
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			}
            cell.textLabel.text = @"Add Ingredient";
        }
    } else {
         // If necessary create a new cell and configure it appropriately for the section.  Give the cell a different identifier from that used for cells in the Ingredients section so that it can be dequeued separately.
        static NSString *MyIdentifier = @"GenericCell";
        
        cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        NSString *text = nil;
        
        switch (indexPath.section) {
            case TYPE_SECTION: // type -- should be selectable -> checkbox
                text = [self.recipe.type valueForKey:@"name"];
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
                break;
            case INSTRUCTIONS_SECTION: // instructions
                text = @"Instructions";
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.editingAccessoryType = UITableViewCellAccessoryNone;
                break;
            default:
                break;
        }
        
        cell.textLabel.text = text;
    }
    return cell;
}


#pragma mark -
#pragma mark Editing rows

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSIndexPath *rowToSelect = indexPath;
    NSInteger section = indexPath.section;
    BOOL isEditing = self.editing;
    
    // If editing, don't allow instructions to be selected
    // Not editing: Only allow instructions to be selected
    if ((isEditing && section == INSTRUCTIONS_SECTION) || (!isEditing && section != INSTRUCTIONS_SECTION)) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        rowToSelect = nil;    
    }

	return rowToSelect;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger section = indexPath.section;
    UIViewController *nextViewController = nil;
    
    /*
     What to do on selection depends on what section the row is in.
     For Type, Instructions, and Ingredients, create and push a new view controller of the type appropriate for the next screen.
     */
    switch (section) {
        case TYPE_SECTION:
            nextViewController = [[TypeSelectionViewController alloc] initWithStyle:UITableViewStyleGrouped];
            ((TypeSelectionViewController *)nextViewController).recipe = self.recipe;
            break;
			
        case INSTRUCTIONS_SECTION:
            nextViewController = [[InstructionsViewController alloc] initWithNibName:@"InstructionsView" bundle:nil];
            ((InstructionsViewController *)nextViewController).recipe = self.recipe;
            break;
			
        case INGREDIENTS_SECTION:
            nextViewController = [[IngredientDetailViewController alloc] initWithStyle:UITableViewStyleGrouped];
            ((IngredientDetailViewController *)nextViewController).recipe = self.recipe;
            
            if (indexPath.row < [self.recipe.ingredients count]) {
                Ingredient *ingredient = (self.ingredients)[indexPath.row];
                ((IngredientDetailViewController *)nextViewController).ingredient = ingredient;
            }
            break;
			
        default:
            break;
    }
    
    // If we got a new view controller, push it .
    if (nextViewController) {
        [self.navigationController pushViewController:nextViewController animated:YES];
    }
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCellEditingStyle style = UITableViewCellEditingStyleNone;
    // Only allow editing in the ingredients section.
    // In the ingredients section, the last row (row number equal to the count of ingredients) is added automatically (see tableView:cellForRowAtIndexPath:) to provide an insertion cell, so configure that cell for insertion; the other cells are configured for deletion.
    if (indexPath.section == INGREDIENTS_SECTION) {
        // If this is the last item, it's the insertion row.
        if (indexPath.row == [self.recipe.ingredients count]) {
            style = UITableViewCellEditingStyleInsert;
        }
        else {
            style = UITableViewCellEditingStyleDelete;
        }
    }
    
    return style;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Only allow deletion, and only in the ingredients section
    if ((editingStyle == UITableViewCellEditingStyleDelete) && (indexPath.section == INGREDIENTS_SECTION)) {
        // Remove the corresponding ingredient object from the recipe's ingredient list and delete the appropriate table view cell.
        Ingredient *ingredient = (self.ingredients)[indexPath.row];
        [self.recipe removeIngredientsObject:ingredient];
        [self.ingredients removeObject:ingredient];

        [ingredient MR_deleteEntity];
        
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
    }
}


#pragma mark -
#pragma mark Moving rows

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL canMove = NO;
    // Moves are only allowed within the ingredients section.  Within the ingredients section, the last row (Add Ingredient) cannot be moved.
    if (indexPath.section == INGREDIENTS_SECTION) {
        canMove = indexPath.row != [self.recipe.ingredients count];
    }
    return canMove;
}


- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    NSIndexPath *target = proposedDestinationIndexPath;
    
    /*
     Moves are only allowed within the ingredients section, so make sure the destination is in the ingredients section.
     If the destination is in the ingredients section, make sure that it's not the Add Ingredient row -- if it is, retarget for the penultimate row.
     */
	NSUInteger proposedSection = proposedDestinationIndexPath.section;
	
    if (proposedSection < INGREDIENTS_SECTION) {
        target = [NSIndexPath indexPathForRow:0 inSection:INGREDIENTS_SECTION];
    } else if (proposedSection > INGREDIENTS_SECTION) {
        target = [NSIndexPath indexPathForRow:([self.recipe.ingredients count] - 1) inSection:INGREDIENTS_SECTION];
    } else {
        NSUInteger ingredientsCount_1 = [self.recipe.ingredients count] - 1;
        
        if (proposedDestinationIndexPath.row > ingredientsCount_1) {
            target = [NSIndexPath indexPathForRow:ingredientsCount_1 inSection:INGREDIENTS_SECTION];
        }
    }
	
    return target;
}


- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	
	/*
	 Update the ingredients array in response to the move.
	 Update the display order indexes within the range of the move.
	 */
    Ingredient *ingredient = (self.ingredients)[fromIndexPath.row];
    [self.ingredients removeObjectAtIndex:fromIndexPath.row];
    [self.ingredients insertObject:ingredient atIndex:toIndexPath.row];
	
	NSInteger start = fromIndexPath.row;
	if (toIndexPath.row < start) {
		start = toIndexPath.row;
	}
	NSInteger end = toIndexPath.row;
	if (fromIndexPath.row > end) {
		end = fromIndexPath.row;
	}
	for (NSInteger i = start; i <= end; i++) {
		ingredient = (self.ingredients)[i];
		ingredient.displayOrder = @(i);
	}
}


#pragma mark -
#pragma mark Photo

- (IBAction)photoTapped {
    // If in editing state, then display an image picker; if not, create and push a photo view controller.
	if (self.editing) {
		UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
		imagePicker.delegate = self;
        [self presentViewController:imagePicker animated:YES completion:nil];
	} else {	
		RecipePhotoViewController *recipePhotoViewController = [[RecipePhotoViewController alloc] init];
        recipePhotoViewController.hidesBottomBarWhenPushed = YES;
		recipePhotoViewController.recipe = self.recipe;
		[self.navigationController pushViewController:recipePhotoViewController animated:YES];
	}
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)selectedImage editingInfo:(NSDictionary *)editingInfo {
	
	// Delete any existing image.
	NSManagedObject *oldImage = self.recipe.image;
	if (oldImage != nil) {
		[self.recipe.managedObjectContext deleteObject:oldImage];
	}
	
    // Create an image object for the new image.
	NSManagedObject *image = [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext:self.recipe.managedObjectContext];
	self.recipe.image = image;

	// Set the image for the image managed object.
	[image setValue:selectedImage forKey:@"image"];
	
	// Create a thumbnail version of the image for the recipe object.
	CGSize size = selectedImage.size;
	CGFloat ratio = 0;
	if (size.width > size.height) {
		ratio = 44.0 / size.width;
	} else {
		ratio = 44.0 / size.height;
	}
	CGRect rect = CGRectMake(0.0, 0.0, ratio * size.width, ratio * size.height);
	
	UIGraphicsBeginImageContext(rect.size);
	[selectedImage drawInRect:rect];
	self.recipe.thumbnailImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
    [self dismissModalViewControllerAnimated:YES];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)updatePhotoButton {
	/*
	 How to present the photo button depends on the editing state and whether the recipe has a thumbnail image.
	 * If the recipe has a thumbnail, set the button's highlighted state to the same as the editing state (it's highlighted if editing).
	 * If the recipe doesn't have a thumbnail, then: if editing, enable the button and show an image that says "Choose Photo" or similar; if not editing then disable the button and show nothing.  
	 */
	BOOL editing = self.editing;
	
	if (self.recipe.thumbnailImage != nil) {
		self.photoButton.highlighted = editing;
	} else {
		self.photoButton.enabled = editing;
		
		if (editing) {
			[self.photoButton setImage:[UIImage imageNamed:@"choosePhoto.png"] forState:UIControlStateNormal];
		} else {
			[self.photoButton setImage:nil forState:UIControlStateNormal];
		}
	}
}


@end
