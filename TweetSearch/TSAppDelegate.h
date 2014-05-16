//
//  TSAppDelegate.h
//  TweetSearch
//
//  Created by Peng Wang on 5/14/14.
//
//

#import <UIKit/UIKit.h>

@interface TSAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic, readonly) NSManagedObjectContext *managedObjectContext; // We only need one context.
@property (strong, nonatomic, readonly) NSDateFormatter *tweetDateFormatter; // This is expensive, so share it.

@end
