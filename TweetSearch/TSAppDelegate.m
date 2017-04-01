//
//  TSAppDelegate.m
//  TweetSearch
//
//  Created by Peng Wang on 5/14/14.
//

#import "TSAppDelegate.h"

@interface TSAppDelegate ()

@property (nonatomic, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite) UIColor *primaryColor;
@property (nonatomic, readwrite) NSDateFormatter *tweetDateFormatter;

- (void)setupAppearances;
- (void)setupCoreData;

@end

@implementation TSAppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  [self setupAppearances];
  return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  [self setupCoreData];
  return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  NSError *error;
  if (![self.managedObjectContext save:&error]) {
    NSLog(@"Error when persisting saved tweets: %@", error.localizedDescription);
  }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  [self.managedObjectContext save:NULL];
}

#pragma mark - Private

- (UIColor *)primaryColor {
  if (!_primaryColor) {
    _primaryColor = [UIColor colorWithRed:29/255.0 green:161/255.0 blue:242/255.0 alpha:1];
  }
  return _primaryColor;
}

- (void)setupAppearances
{
  [UINavigationBar appearance].barTintColor = self.primaryColor;
  [UINavigationBar appearance].titleTextAttributes =
  @{ NSFontAttributeName: [UIFont systemFontOfSize:17 weight:UIFontWeightMedium],
     NSForegroundColorAttributeName: [UIColor whiteColor] };
  [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UINavigationBar class]]]
  .tintColor = [UIColor colorWithWhite:1 alpha:0.7];
}

- (void)setupCoreData
{
  NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:nil];
  NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
  context.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
  NSError *error;
  NSURL *storeURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentationDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL];
  storeURL = [storeURL URLByAppendingPathComponent:@"db.sqlite"];
  [context.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error];
  if (error) {
    NSLog(@"Error adding store: %@", error.localizedDescription);
  }
  self.managedObjectContext = context;
}

- (NSDateFormatter *)tweetDateFormatter
{
  if (!_tweetDateFormatter) {
    _tweetDateFormatter = [[NSDateFormatter alloc] init];
    _tweetDateFormatter.dateFormat = @"EEE MMM d HH:mm:ss Z y";
  }
  return _tweetDateFormatter;
}

@end
