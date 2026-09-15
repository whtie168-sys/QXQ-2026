//
//  UNDJKWIOKDCommunityArticleCell.m
//  WildFireChat
//
//  Created by wtb on 2026/4/17.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import "UNDJKWIOKDCommunityArticleCell.h"
#import "UNDJKWIOKDCommunityBBCode.h"

static CGFloat const kCommunityPagePadding = 15.0;
static CGFloat const kCommunityArticleCoverHeight = 200.0;

@implementation UNDJKWIOKDCommunityArticleCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self buildViews];
    }
    return self;
}

- (void)buildViews {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = UIColor.clearColor;
    self.contentView.backgroundColor = UIColor.clearColor;

    self.cardView = [[UIView alloc] init];
    self.cardView.translatesAutoresizingMaskIntoConstraints = NO;
    self.cardView.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1];
    self.cardView.layer.cornerRadius = 7;
    self.cardView.clipsToBounds = YES;
    [self.contentView addSubview:self.cardView];

    self.coverView = [[UIImageView alloc] init];
    self.coverView.translatesAutoresizingMaskIntoConstraints = NO;
    self.coverView.contentMode = UIViewContentModeScaleAspectFit;
    self.coverView.clipsToBounds = YES;
    self.coverView.backgroundColor = UIColor.blackColor;
    [self.cardView addSubview:self.coverView];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    self.titleLabel.textColor = [UIColor colorWithWhite:0.12 alpha:1];
    self.titleLabel.numberOfLines = 2;
    [self.cardView addSubview:self.titleLabel];

    self.avatarView = [[UIImageView alloc] init];
    self.avatarView.translatesAutoresizingMaskIntoConstraints = NO;
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarView.clipsToBounds = YES;
    self.avatarView.layer.cornerRadius = 15;
    [self.cardView addSubview:self.avatarView];

    self.authorLabel = [[UILabel alloc] init];
    self.authorLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.authorLabel.font = [UIFont boldSystemFontOfSize:12];
    self.authorLabel.textColor = [UIColor colorWithWhite:0.28 alpha:1];
    [self.cardView addSubview:self.authorLabel];

    self.dateLabel = [[UILabel alloc] init];
    self.dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.dateLabel.font = [UIFont systemFontOfSize:11];
    self.dateLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1];
    [self.cardView addSubview:self.dateLabel];

    self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.deleteButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.deleteButton setImage:[UIImage imageNamed:@"community_delete"] forState:UIControlStateNormal];
    [self.deleteButton setTitleColor:[UIColor colorWithRed:0.93 green:0.19 blue:0.16 alpha:1] forState:UIControlStateNormal];
    self.deleteButton.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [self.cardView addSubview:self.deleteButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.cardView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:7],
        [self.cardView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:kCommunityPagePadding],
        [self.cardView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-kCommunityPagePadding],
        [self.cardView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-7],

        [self.coverView.topAnchor constraintEqualToAnchor:self.cardView.topAnchor],
        [self.coverView.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor],
        [self.coverView.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor],
        [self.coverView.heightAnchor constraintEqualToConstant:kCommunityArticleCoverHeight],

        [self.titleLabel.topAnchor constraintEqualToAnchor:self.coverView.bottomAnchor constant:8],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:10],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-10],

        [self.avatarView.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:10],
        [self.avatarView.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:12],
        [self.avatarView.widthAnchor constraintEqualToConstant:30],
        [self.avatarView.heightAnchor constraintEqualToConstant:30],
        [self.avatarView.bottomAnchor constraintEqualToAnchor:self.cardView.bottomAnchor constant:-12],

        [self.authorLabel.leadingAnchor constraintEqualToAnchor:self.avatarView.trailingAnchor constant:7],
        [self.authorLabel.topAnchor constraintEqualToAnchor:self.avatarView.topAnchor constant:-1],
        [self.authorLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.deleteButton.leadingAnchor constant:-8],

        [self.dateLabel.leadingAnchor constraintEqualToAnchor:self.authorLabel.leadingAnchor],
        [self.dateLabel.topAnchor constraintEqualToAnchor:self.authorLabel.bottomAnchor constant:1],

        [self.deleteButton.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-8],
        [self.deleteButton.centerYAnchor constraintEqualToAnchor:self.avatarView.centerYAnchor],
        [self.deleteButton.widthAnchor constraintEqualToConstant:42],
        [self.deleteButton.heightAnchor constraintEqualToConstant:36],
    ]];
}

- (void)configureWithArticle:(WFCCCommunity *)article
                    portrait:(NSString *)portrait
                  authorName:(NSString *)authorName
                         date:(NSString *)date
                    canDelete:(BOOL)canDelete {
    if (article.title.length > 0) {
        self.titleLabel.text = article.title;
    } else {
        self.titleLabel.attributedText =
            [UNDJKWIOKDCommunityBBCode attributedStringFromString:article.summary
                                                        baseFont:self.titleLabel.font
                                                       textColor:self.titleLabel.textColor];
    }
    self.authorLabel.text = authorName;
    self.dateLabel.text = date;
    self.deleteButton.hidden = !canDelete;
    self.deleteButton.accessibilityIdentifier = article.articleId;
    [self.coverView sd_setImageWithURL:URL(article.cover) placeholderImage:nil options:SDWebImageScaleDownLargeImages];
    [self.avatarView sd_setImageWithURL:URL(portrait) placeholderImage:[AIOIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages];
}

- (void)setDeleteTarget:(id)target action:(SEL)action {
    [self.deleteButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.deleteButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}



@end
