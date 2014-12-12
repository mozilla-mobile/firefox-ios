//
//  MGPAppDelegate.m
//  Recipes
//
//  Created by Saul Mora on 5/19/13.
//
//

#import "MGPRecipesAppDelegate.h"

static NSString * const kRecipesStoreName = @"Recipes.sqlite";

@implementation MGPRecipesAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self copyDefaultStoreIfNecessary];
    [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelVerbose];
    [MagicalRecord setupCoreDataStackWithStoreNamed:kRecipesStoreName];

    // Override point for customization after application launch.
//    self.window.backgroundColor = [UIColor whiteColor];
    self.recipeListController.managedObjectContext = [NSManagedObjectContext MR_defaultContext];
    [self.window addSubview:self.tabBarController.view];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void) copyDefaultStoreIfNecessary;
{
	NSFileManager *fileManager = [NSFileManager defaultManager];

    NSURL *storeURL = [NSPersistentStore MR_urlForStoreName:kRecipesStoreName];

	// If the expected store doesn't exist, copy the default store.
	if (![fileManager fileExistsAtPath:[storeURL path]])
    {
		NSString *defaultStorePath = [[NSBundle mainBundle] pathForResource:[kRecipesStoreName stringByDeletingPathExtension] ofType:[kRecipesStoreName pathExtension]];
        
		if (defaultStorePath)
        {
            NSError *error;
			BOOL success = [fileManager copyItemAtPath:defaultStorePath toPath:[storeURL path] error:&error];
            if (!success)
            {
                NSLog(@"Failed to install default recipe store");
            }
		}
	}

}
@end
