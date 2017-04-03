//
//  TSBookmarksViewController.m
//  TweetSearch
//
//  Created by Peng Wang on 5/14/14.
//

#import "TSBookmarksViewController.h"

#import <Accounts/Accounts.h>
#import <Social/Social.h>

#import <SDWebImage/UIImageView+WebCache.h>

#import "TSAppDelegate.h"
#import "TSTweet.h"
#import "TSTweetCell.h"

@interface TSBookmarksViewController ()

<UISearchBarDelegate, UISearchDisplayDelegate, NSFetchedResultsControllerDelegate>

// Accounts.
@property (nonatomic, weak) ACAccount *twitterAccount;
@property (nonatomic) ACAccountStore *accountStore;

// Data.
@property (nonatomic) NSArray *searchResults;
@property (nonatomic) NSFetchedResultsController *bookmarks;

// Misc.
@property (nonatomic, weak) TSAppDelegate *sharedContext;
@property (nonatomic) NSIndexPath *currentSearchResultIndexPath;

- (void)checkTwitterAccountAccess;
- (void)loadBookmarks;
- (void)performTwitterSearchForQuery:(NSString *)query
                      withCompletion:(void (^)(NSDictionary *tweetsData))completion;
- (void)presentErrorAlertWithMessage:(NSString *)message;
- (void)setUpSearch;

@end

@implementation TSBookmarksViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.sharedContext = (TSAppDelegate *)[UIApplication sharedApplication].delegate;

  self.navigationItem.rightBarButtonItem = self.editButtonItem;
  self.title = NSLocalizedString(@"TweetSearch", nil);

  self.accountStore = [[ACAccountStore alloc] init];
  [self checkTwitterAccountAccess];

  [self setUpSearch];

  [self loadBookmarks];

  id cancelButtonAppearance = [UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil];
  [cancelButtonAppearance setTitle:@"Done"];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Clear out some temporary data.
  self.searchResults = nil;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  if (tableView == self.searchDisplayController.searchResultsTableView) {
    return self.searchResults.count;
  }
  return self.bookmarks.fetchedObjects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  TSTweetCell *cell;
  if (tableView == self.searchDisplayController.searchResultsTableView) {
    // Set up search result cell.
    cell = [self.tableView dequeueReusableCellWithIdentifier:TSTweetCellReuseIdentifier]; // Another workaround for search display cells.
    NSDictionary *tweet = self.searchResults[indexPath.row];
    cell.tweetTextLabel.text = tweet[@"text"];
    cell.screenNameLabel.text = tweet[@"user"][@"screen_name"];
    [cell.profileImageView sd_setImageWithURL:[NSURL URLWithString:tweet[@"user"][@"profile_image_url_https"]]];
    return cell;
  }
  // Set up bookmark cell.
  cell = [self.tableView dequeueReusableCellWithIdentifier:TSTweetCellReuseIdentifier forIndexPath:indexPath];
  TSTweet *tweet = [self.bookmarks objectAtIndexPath:indexPath];
  cell.tweetTextLabel.text = tweet.text;
  cell.screenNameLabel.text = [NSString stringWithFormat:@"@%@", tweet.userScreenName];
  [cell.profileImageView sd_setImageWithURL:tweet.profileImageURL];
  return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
  return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (editingStyle == UITableViewCellEditingStyleInsert
      && tableView == self.searchDisplayController.searchResultsTableView
      ) {
    NSDictionary *tweet = self.searchResults[indexPath.row];
    NSArray *existingTweets = [self.bookmarks.fetchedObjects filteredArrayUsingPredicate:
                               [NSPredicate predicateWithFormat:@"text == %@", tweet[@"text"]]];
    if (existingTweets.count) {
      NSLog(@"Preventing insert. Similar tweet already saved: %@", existingTweets.firstObject);
      [[tableView cellForRowAtIndexPath:indexPath] setEditing:NO animated:YES];
      return;
    }
    [TSTweet insertTweetFromDictionary:tweet
                     withDateFormatter:self.sharedContext.tweetDateFormatter
                inManagedObjectContext:self.sharedContext.managedObjectContext];
    self.currentSearchResultIndexPath = indexPath;
  } else if (editingStyle == UITableViewCellEditingStyleDelete) {
    [self.sharedContext.managedObjectContext deleteObject:[self.bookmarks objectAtIndexPath:indexPath]];
  }
}

#pragma mark - UITableViewDelegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (tableView == self.searchDisplayController.searchResultsTableView) {
    // We can just style these cells as inserting.
    return UITableViewCellEditingStyleInsert;
  }
  return UITableViewCellEditingStyleDelete;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return 77; // Another workaround for search display cells.
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
  return NO;
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
  if (self.searchResults) {
    self.searchResults = nil;
  }
}
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
  [self performTwitterSearchForQuery:searchBar.text withCompletion:^(NSDictionary *tweetsData) {
    self.searchResults = [TSTweet parseTweets:tweetsData[@"statuses"]];
    [self.searchDisplayController.searchResultsTableView reloadData];
  }];
}

#pragma mark - UISearchDisplayDelegate

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
  self.searchResults = nil;
  [self.tableView reloadData];
  NSError *error;
  if (![self.sharedContext.managedObjectContext save:&error]) {
    NSLog(@"Error when persisting saved tweets: %@", error.localizedDescription);
  }
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
  if (type == NSFetchedResultsChangeInsert) {
    NSLog(@"Saved tweet: %@", anObject);
    [[self.searchDisplayController.searchResultsTableView cellForRowAtIndexPath:self.currentSearchResultIndexPath] setEditing:NO animated:YES];
  } else if (type == NSFetchedResultsChangeDelete) {
    NSLog(@"Removed tweet: %@", anObject);
    [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationFade];
  }
}

#pragma mark - Private

- (void)checkTwitterAccountAccess
{
  ACAccountStore *accountStore = self.accountStore;
  ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
  UISearchBar *searchBar = self.searchDisplayController.searchBar;
  if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
    // Check access if there are accounts.
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
      if (granted) {
        // Save account if we get access.
        NSArray *accounts = [accountStore accountsWithAccountType:accountType];
        if (accounts.count) {
          searchBar.userInteractionEnabled = YES;
          NSLog(@"Got access for Twitter account: %@", self.twitterAccount);
        }
      } else {
        // Disable UI and show an alert if we don't.
        searchBar.userInteractionEnabled = NO;
        [self presentErrorAlertWithMessage:@"No permission to access any Twitter accounts"];
      }
      if (error) {
        NSLog(@"Error when requesting access: %@", error.localizedDescription);
      }
    }];
  } else {
    // Disable UI and show an alert if there aren't any.
    searchBar.userInteractionEnabled = NO;
    [self presentErrorAlertWithMessage:@"Could not find any Twitter accounts"];
  }
}

- (void)loadBookmarks
{
  NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:TSTweetEntityName];
  request.sortDescriptors = @[];
  self.bookmarks = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                       managedObjectContext:self.sharedContext.managedObjectContext
                                                         sectionNameKeyPath:nil cacheName:nil];
  self.bookmarks.delegate = self;
  NSError *error;
  if (![self.bookmarks performFetch:&error]) {
    [self presentErrorAlertWithMessage:@"Error fetching saved tweets"];
    NSLog(@"Error when fetching persisted Tweets: %@", error.localizedDescription);
  }
}

- (void)performTwitterSearchForQuery:(NSString *)query withCompletion:(void (^)(NSDictionary *tweetsData))completion
{
  ACAccountStore *accountStore = self.accountStore;
  ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
  [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
    if (granted) {
      // Perform search.
      NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/search/tweets.json"];
      NSDictionary *params = @{ @"q": [query stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] };
      SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:url parameters:params];
      request.account = [accountStore accountsWithAccountType:accountType].firstObject;
      [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        if (responseData) {
          if (urlResponse.statusCode >= 200 && urlResponse.statusCode < 300) {
            NSError *jsonError;
            NSDictionary *tweetsData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:&jsonError];
            if (tweetsData) {
              NSLog(@"Tweets: %@", tweetsData);
              if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                  completion(tweetsData);
                });
              }
            } else {
              NSLog(@"Error when serializing from JSON: %@", jsonError.localizedDescription);
            }
          } else {
            NSLog(@"Request not considered successful, status code: %d, description: %@", urlResponse.statusCode, urlResponse.debugDescription);
          }
        }
      }];
    }
  }];
}

- (void)presentErrorAlertWithMessage:(NSString *)message
{
  UIAlertController *alert = [UIAlertController
                              alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                              message:NSLocalizedString(message, nil)
                              preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    [alert dismissViewControllerAnimated:YES completion:nil];
  }]];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)setUpSearch
{
  // Only option I found that works with IB.
  [self.searchDisplayController.searchResultsTableView registerClass:[TSTweetCell class] forCellReuseIdentifier:TSTweetCellReuseIdentifier];
  // We're making use of UITableViewCellEditingStyleInsert.
  [self.searchDisplayController.searchResultsTableView setEditing:YES animated:NO];

  self.searchResults = @[];
}

@end
