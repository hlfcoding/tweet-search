//
//  TSTweet.m
//  TweetSearch
//
//  Created by Peng Wang on 5/15/14.
//
//

#import "TSTweet.h"

@implementation TSTweet

@dynamic text;
@dynamic userScreenName;
@dynamic profileImageURL;
@dynamic tweetID;
@dynamic createdAt;

+ (instancetype)insertTweetFromDictionary:(NSDictionary *)dictionary withDateFormatter:(NSDateFormatter *)dateFormatter inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
  TSTweet *tweet = [NSEntityDescription insertNewObjectForEntityForName:TSTweetEntityName inManagedObjectContext:managedObjectContext];
  tweet.text = dictionary[@"text"];
  tweet.userScreenName = dictionary[@"user"][@"screen_name"];
  tweet.profileImageURL = [NSURL URLWithString:dictionary[@"user"][@"profile_image_url"]];
  tweet.tweetID = dictionary[@"id"];
  tweet.createdAt = [dateFormatter dateFromString:dictionary[@"created_at"]];
  return tweet;
}

@end
