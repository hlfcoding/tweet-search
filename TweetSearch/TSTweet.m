//
//  TSTweet.m
//  TweetSearch
//
//  Created by Peng Wang on 5/15/14.
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
  tweet.profileImageURL = [NSURL URLWithString:dictionary[@"user"][@"profile_image_url_https"]];
  tweet.tweetID = dictionary[@"id"];
  tweet.createdAt = [dateFormatter dateFromString:dictionary[@"created_at"]];
  return tweet;
}

+ (NSDictionary *)parseTweet:(NSDictionary *)tweet
{
  NSMutableDictionary *parsed = [tweet mutableCopy];
  parsed[@"user"] = [tweet[@"user"] mutableCopy];
  parsed[@"user"][@"profile_image_url_https"] = [(NSString *)(tweet[@"user"][@"profile_image_url_https"])
                                                 stringByReplacingOccurrencesOfString:@"_normal" withString:@""];
  return [NSDictionary dictionaryWithDictionary:parsed];
}

+ (NSArray<NSDictionary *> *)parseTweets:(NSArray<NSDictionary *> *)tweets
{
  NSMutableArray<NSDictionary *> *parsed = [NSMutableArray arrayWithCapacity:tweets.count];
  for (NSDictionary *tweet in tweets) {
    [parsed addObject:[TSTweet parseTweet:tweet]];
  }
  return [NSArray arrayWithArray:parsed];
}

@end
