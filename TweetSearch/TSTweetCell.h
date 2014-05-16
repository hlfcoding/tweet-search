//
//  TSTweetCell.h
//  TweetSearch
//
//  Created by Peng Wang on 5/15/14.
//
//

#import <UIKit/UIKit.h>

@interface TSTweetCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *tweetTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *screenNameLabel;

@end
