//
//  TSTweet.h
//  TweetSearch
//
//  Created by Peng Wang on 5/15/14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface TSTweet : NSManagedObject

@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) NSString *userScreenName;
@property (nonatomic, retain) NSURL *profileImageURL;
@property (nonatomic, retain) NSNumber *tweetID;
@property (nonatomic, retain) NSDate *createdAt;

+ (instancetype)insertTweetFromDictionary:(NSDictionary *)dictionary
                        withDateFormatter:(NSDateFormatter *)dateFormatter
                   inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end
