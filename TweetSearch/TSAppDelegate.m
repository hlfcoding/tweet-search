//
//  TSAppDelegate.m
//  TweetSearch
//
//  Created by Peng Wang on 5/14/14.
//
//

#import "TSAppDelegate.h"

@interface TSAppDelegate ()

@property (nonatomic, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite) NSDateFormatter *tweetDateFormatter;

- (void)setupCoreData;

@end

@implementation TSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  [self setupCoreData];
  self.tweetDateFormatter = [[NSDateFormatter alloc] init];
  self.tweetDateFormatter.dateFormat = @"EEE MMM d HH:mm:ss Z y";
  return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  NSError *error;
  BOOL didSave = [self.managedObjectContext save:&error];
  if (!didSave) {
    NSLog(@"Error when persisting saved tweets: %@", error.localizedDescription);
  }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  [self.managedObjectContext save:NULL];
}

#pragma mark - Own methods

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

@end
