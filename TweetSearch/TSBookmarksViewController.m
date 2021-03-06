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

<UISearchBarDelegate, NSFetchedResultsControllerDelegate>

// Accounts.
@property (nonatomic, weak) ACAccount *twitterAccount;
@property (nonatomic) ACAccountStore *accountStore;

// Data.
@property (nonatomic) NSArray *searchResults;
@property (nonatomic) NSFetchedResultsController *bookmarks;

// Misc.
@property (nonatomic, weak) TSAppDelegate *sharedContext;
@property (nonatomic) NSIndexPath *currentSearchResultIndexPath;

@property (nonatomic, getter=isSearching) BOOL searching;
@property (nonatomic) BOOL didJustClearSearch;
@property (nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic) IBOutlet UIBarButtonItem *searchDoneButtonItem;

- (void)accessTwitterAccount;
- (void)loadBookmarks;
- (void)performTwitterSearchForQuery:(NSString *)query
                      withCompletion:(void (^)(NSDictionary *tweetsData))completion;
- (void)presentErrorAlertWithMessage:(NSString *)message;
- (void)resetSearch;

@end

@implementation TSBookmarksViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.sharedContext = (TSAppDelegate *)[UIApplication sharedApplication].delegate;

  self.navigationItem.rightBarButtonItem = self.editButtonItem;
  self.title = NSLocalizedString(@"TweetSearch", nil);

  [self accessTwitterAccount];
  [self resetSearch];

  [self loadBookmarks];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Clear out some temporary data.
  [self resetSearch];
}

- (IBAction)endSearch:(UIBarButtonItem *)sender
{
  self.searching = NO;
  [self.searchBar resignFirstResponder];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  if (self.isSearching) {
    return self.searchResults.count;
  }
  return self.bookmarks.fetchedObjects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  TSTweetCell *cell;
  if (self.isSearching) {
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
  if (editingStyle == UITableViewCellEditingStyleInsert && self.isSearching) {
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
  if (self.isSearching) {
    // We can just style these cells as inserting.
    return UITableViewCellEditingStyleInsert;
  }
  return UITableViewCellEditingStyleDelete;
}

#pragma mark - UISearchBarDelegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
  if (self.didJustClearSearch) {
    self.didJustClearSearch = NO;
    return NO;
  }
  return YES;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
  self.searching = YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
  self.didJustClearSearch = !searchBar.isFirstResponder && (!searchText || searchText.length == 0);
  if (self.didJustClearSearch) {
    self.searching = NO;
    [searchBar resignFirstResponder];
  }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
  [searchBar resignFirstResponder];
  [self performTwitterSearchForQuery:searchBar.text withCompletion:^(NSDictionary *tweetsData) {
    self.searchResults = [TSTweet parseTweets:tweetsData[@"statuses"]];
    [self.tableView reloadData];
  }];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
  if (type == NSFetchedResultsChangeInsert) {
    NSLog(@"Saved tweet: %@", anObject);
    [[self.tableView cellForRowAtIndexPath:self.currentSearchResultIndexPath] setEditing:NO animated:YES];
  } else if (type == NSFetchedResultsChangeDelete) {
    NSLog(@"Removed tweet: %@", anObject);
    [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationFade];
  }
}

#pragma mark - Private

- (void)setSearching:(BOOL)searching
{
  if (searching == _searching) { return; }
  _searching = searching;

  [self resetSearch];
  // We're making use of UITableViewCellEditingStyleInsert.
  [self.tableView setEditing:_searching animated:NO];
  [self.tableView reloadData];
  [self.navigationItem setRightBarButtonItem:(_searching ? self.searchDoneButtonItem : self.editButtonItem) animated:YES];
  if (!_searching) {
    self.searchBar.text = nil;
    NSError *error;
    if (![self.sharedContext.managedObjectContext save:&error]) {
      NSLog(@"Error when persisting saved tweets: %@", error.localizedDescription);
    }
  }
}

- (void)accessTwitterAccount
{
  if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
    self.accountStore = [[ACAccountStore alloc] init];
    self.searchBar.userInteractionEnabled = NO;
    __weak typeof(self) weakSelf = self;
    // Check access if there are accounts.
    ACAccountType *accountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [self.accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        if (granted) {
          // Save account if we get access.
          NSArray *accounts = [weakSelf.accountStore accountsWithAccountType:accountType];
          if (accounts.count) {
            weakSelf.searchBar.userInteractionEnabled = YES;
            NSLog(@"Got access for Twitter account: %@", weakSelf.twitterAccount);
          }
        } else {
          // Disable UI and show an alert if we don't.
          weakSelf.searchBar.userInteractionEnabled = NO;
          [weakSelf presentErrorAlertWithMessage:@"Error fetching tweets"];
        }
        if (error) {
          NSLog(@"Error when requesting access: %@", error.localizedDescription);
        }
      });
    }];
  } else {
    // Disable UI and show an alert if there aren't any.
    self.searchBar.userInteractionEnabled = NO;
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
  __weak typeof(self) weakSelf = self;
  ACAccountType *accountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
  // Perform search.
  NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/search/tweets.json"];
  NSDictionary *params = @{ @"q": [query stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] };
  SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:url parameters:params];
  request.account = [weakSelf.accountStore accountsWithAccountType:accountType].firstObject;
  [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
    dispatch_block_t presentErrorAlert = ^{
      dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf presentErrorAlertWithMessage:@"Error fetching tweets"];
      });
    };
    if (error) {
      presentErrorAlert();
      NSLog(@"Request error: %@", error.localizedDescription);
      return;
    }
    if (responseData && urlResponse.statusCode >= 200 && urlResponse.statusCode < 300) {
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
      presentErrorAlert();
      NSLog(@"Request not considered successful, status code: %d, description: %@", urlResponse.statusCode, urlResponse.debugDescription);
    }
  }];
}

- (void)presentErrorAlertWithMessage:(NSString *)message
{
  UIAlertController *alert = [UIAlertController
                              alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                              message:NSLocalizedString(message, nil)
                              preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    [alert dismissViewControllerAnimated:YES completion:nil];
  }]];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)resetSearch
{
  self.searchResults = @[];
}

@end
