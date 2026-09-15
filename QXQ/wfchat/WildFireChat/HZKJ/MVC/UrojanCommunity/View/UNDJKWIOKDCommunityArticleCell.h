//
//  UNDJKWIOKDCommunityArticleCell.h
//  WildFireChat
//
//  Created by wtb on 2026/4/17.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UNDJKWIOKDCommunityArticleCell : UITableViewCell
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIImageView *coverView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *authorLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UIButton *deleteButton;


- (void)configureWithArticle:(WFCCCommunity *)article
                    portrait:(NSString *)portrait
                  authorName:(NSString *)authorName
                         date:(NSString *)date
                    canDelete:(BOOL)canDelete;
- (void)setDeleteTarget:(id)target action:(SEL)action;

@end

NS_ASSUME_NONNULL_END
