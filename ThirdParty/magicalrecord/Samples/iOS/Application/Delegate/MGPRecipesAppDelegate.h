//
//  MGPAppDelegate.h
//  Recipes
//
//  Created by Saul Mora on 5/19/13.
//
//

#import <UIKit/UIKit.h>
#import "RecipeListTableViewController.h"

@interface MGPRecipesAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet UITabBarController *tabBarController;
@property (nonatomic, strong) IBOutlet RecipeListTableViewController *recipeListController;

@end
