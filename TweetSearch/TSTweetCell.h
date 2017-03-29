//
//  TSTweetCell.h
//  TweetSearch
//
//  Created by Peng Wang on 5/15/14.
//
//

#import <UIKit/UIKit.h>

@interface TSTweetCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView *profileImageView;
@property (nonatomic, weak) IBOutlet UILabel *tweetTextLabel;
@property (nonatomic, weak) IBOutlet UILabel *screenNameLabel;

@end
