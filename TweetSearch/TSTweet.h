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

@property (nonatomic) NSString *text;
@property (nonatomic) NSString *userScreenName;
@property (nonatomic) NSURL *profileImageURL;
@property (nonatomic) NSNumber *tweetID;
@property (nonatomic) NSDate *createdAt;

+ (instancetype)insertTweetFromDictionary:(NSDictionary *)dictionary
                        withDateFormatter:(NSDateFormatter *)dateFormatter
                   inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end
