//
//  UNDJKWIOKDCommunityDetailVC.m
//  WUHOIBDK
//

#import "UNDJKWIOKDCommunityDetailVC.h"
#import "AppService.h"
#import <WFChatClient/WFCCCommunity.h>
#import <WFChatClient/WFCChatClient.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "UNDJKWIOKDCommunityBBCode.h"

@interface WFCCCommunity (UNDJKWIOKDCommunityDetail)
@end

@implementation WFCCCommunity (UNDJKWIOKDCommunityDetail)

+ (NSDictionary *)mj_objectClassInArray {
    return @{@"contents": [WFCCCommunityContent class]};
}

@end

@interface UNDJKWIOKDCommunityDetailVC () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *topBar;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *authorLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UILabel *readCountLabel;
@property (nonatomic, strong) UILabel *summaryLabel;
@property (nonatomic, strong) UIStackView *contentsStackView;
@property (nonatomic, strong) UIButton *linkButton;
@property (nonatomic, strong) NSLayoutConstraint *linkButtonHeightConstraint;
@property (nonatomic, strong) id<UIGestureRecognizerDelegate> popGestureDelegate;

@end

@implementation UNDJKWIOKDCommunityDetailVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    [self buildViews];
    [self renderArticle:self.article];
    [self loadArticleDetail];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    if (self.navigationController.interactivePopGestureRecognizer) {
        self.popGestureDelegate = self.navigationController.interactivePopGestureRecognizer.delegate;
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
    if (self.navigationController.interactivePopGestureRecognizer.delegate == self) {
        self.navigationController.interactivePopGestureRecognizer.delegate = self.popGestureDelegate;
    }
}

- (void)buildViews {
    self.topBar = [[UIView alloc] init];
    self.topBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.topBar];

    self.backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.backButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backButton setTitle:@"‹" forState:UIControlStateNormal];
    [self.backButton setTitleColor:RGBA(0x222222) forState:UIControlStateNormal];
    self.backButton.titleLabel.font = [UIFont systemFontOfSize:28 weight:UIFontWeightLight];
    [self.backButton addTarget:self action:@selector(backButtonDidTap) forControlEvents:UIControlEventTouchUpInside];
    [self.topBar addSubview:self.backButton];

    self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.deleteButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.deleteButton setImage:[UIImage imageNamed:@"community_delete"] forState:UIControlStateNormal];
    [self.deleteButton addTarget:self action:@selector(deleteButtonDidTap) forControlEvents:UIControlEventTouchUpInside];
    [self.topBar addSubview:self.deleteButton];

    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.scrollView];

    self.contentView = [[UIView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.contentView];

    self.coverImageView = [[UIImageView alloc] init];
    self.coverImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.coverImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.coverImageView.clipsToBounds = YES;
    self.coverImageView.backgroundColor = UIColor.blackColor;
    [self.contentView addSubview:self.coverImageView];

    self.titleLabel = [self labelWithFont:[UIFont systemFontOfSize:16 weight:UIFontWeightMedium] textColor:RGBA(0x222222)];
    self.titleLabel.numberOfLines = 2;
    [self.contentView addSubview:self.titleLabel];

    self.avatarView = [[UIImageView alloc] init];
    self.avatarView.translatesAutoresizingMaskIntoConstraints = NO;
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarView.clipsToBounds = YES;
    self.avatarView.layer.cornerRadius = 15;
    self.avatarView.image = [AIOIUEHImage imageNamed:@"PersonalChat"];
    [self.contentView addSubview:self.avatarView];

    self.authorLabel = [self labelWithFont:[UIFont systemFontOfSize:12 weight:UIFontWeightMedium] textColor:RGBA(0x333333)];
    [self.contentView addSubview:self.authorLabel];

    self.dateLabel = [self labelWithFont:[UIFont systemFontOfSize:11] textColor:RGBA(0x999999)];
    [self.contentView addSubview:self.dateLabel];

    self.readCountLabel = [self labelWithFont:[UIFont systemFontOfSize:11] textColor:RGBA(0x999999)];
    self.readCountLabel.textAlignment = NSTextAlignmentRight;
    [self.contentView addSubview:self.readCountLabel];

    self.summaryLabel = [self labelWithFont:[UIFont systemFontOfSize:14] textColor:RGBA(0x777777)];
    self.summaryLabel.numberOfLines = 0;
    [self.contentView addSubview:self.summaryLabel];

    self.contentsStackView = [[UIStackView alloc] init];
    self.contentsStackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentsStackView.axis = UILayoutConstraintAxisVertical;
    self.contentsStackView.spacing = 18;
    [self.contentView addSubview:self.contentsStackView];

    self.linkButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.linkButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.linkButton.backgroundColor = RGBA(0xF6F6F6);
    self.linkButton.layer.cornerRadius = 6;
    self.linkButton.clipsToBounds = YES;
    [self.linkButton setTitleColor:RGBA(0x2BDD30) forState:UIControlStateNormal];
    self.linkButton.titleLabel.font = PINGFANG_M(14);
    [self.linkButton addTarget:self action:@selector(linkButtonDidTap) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.linkButton];

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    self.linkButtonHeightConstraint = [self.linkButton.heightAnchor constraintEqualToConstant:40];
    [NSLayoutConstraint activateConstraints:@[
        [self.topBar.topAnchor constraintEqualToAnchor:safeArea.topAnchor],
        [self.topBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.topBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.topBar.heightAnchor constraintEqualToConstant:44],

        [self.backButton.leadingAnchor constraintEqualToAnchor:self.topBar.leadingAnchor],
        [self.backButton.centerYAnchor constraintEqualToAnchor:self.topBar.centerYAnchor],
        [self.backButton.widthAnchor constraintEqualToConstant:48],
        [self.backButton.heightAnchor constraintEqualToConstant:44],

        [self.deleteButton.trailingAnchor constraintEqualToAnchor:self.topBar.trailingAnchor constant:-14],
        [self.deleteButton.centerYAnchor constraintEqualToAnchor:self.topBar.centerYAnchor],
        [self.deleteButton.widthAnchor constraintEqualToConstant:40],
        [self.deleteButton.heightAnchor constraintEqualToConstant:40],

        [self.scrollView.topAnchor constraintEqualToAnchor:self.topBar.bottomAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor],

        [self.contentView.topAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.topAnchor],
        [self.contentView.leadingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.trailingAnchor],
        [self.contentView.bottomAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.bottomAnchor],
        [self.contentView.widthAnchor constraintEqualToAnchor:self.scrollView.frameLayoutGuide.widthAnchor],

        [self.coverImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.coverImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.coverImageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.coverImageView.heightAnchor constraintEqualToConstant:210],

        [self.titleLabel.topAnchor constraintEqualToAnchor:self.coverImageView.bottomAnchor constant:12],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:15],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-15],

        [self.avatarView.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:12],
        [self.avatarView.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.avatarView.widthAnchor constraintEqualToConstant:30],
        [self.avatarView.heightAnchor constraintEqualToConstant:30],

        [self.authorLabel.leadingAnchor constraintEqualToAnchor:self.avatarView.trailingAnchor constant:8],
        [self.authorLabel.topAnchor constraintEqualToAnchor:self.avatarView.topAnchor constant:-1],

        [self.dateLabel.leadingAnchor constraintEqualToAnchor:self.authorLabel.leadingAnchor],
        [self.dateLabel.topAnchor constraintEqualToAnchor:self.authorLabel.bottomAnchor constant:1],

        [self.readCountLabel.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor],
        [self.readCountLabel.centerYAnchor constraintEqualToAnchor:self.avatarView.centerYAnchor],
        [self.readCountLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.authorLabel.trailingAnchor constant:8],

        [self.summaryLabel.topAnchor constraintEqualToAnchor:self.avatarView.bottomAnchor constant:22],
        [self.summaryLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.summaryLabel.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor],

        [self.contentsStackView.topAnchor constraintEqualToAnchor:self.summaryLabel.bottomAnchor constant:22],
        [self.contentsStackView.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.contentsStackView.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor],

        [self.linkButton.topAnchor constraintEqualToAnchor:self.contentsStackView.bottomAnchor constant:24],
        [self.linkButton.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.linkButton.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor],
        self.linkButtonHeightConstraint,
        [self.linkButton.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-24],
    ]];
}

- (UILabel *)labelWithFont:(UIFont *)font textColor:(UIColor *)textColor {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = font;
    label.textColor = textColor;
    return label;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return self.navigationController.viewControllers.count > 1;
}

- (void)loadArticleDetail {
    if (self.article.articleId.length == 0) {
        return;
    }
    NSDictionary *param = @{@"articleId": @([self.article.articleId longLongValue])};
    __weak typeof(self) weakSelf = self;
    [[AppService sharedAppService] communityArticleDetail:param success:^(WFCCCommunity *articleDetail) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.article = articleDetail ?: weakSelf.article;
            [weakSelf renderArticle:weakSelf.article];
        });
    } error:^(int errCode, NSString *message) {
    }];
}

- (void)renderArticle:(WFCCCommunity *)article {
    if (!article) {
        return;
    }
    [self.coverImageView sd_setImageWithURL:URL(article.cover) placeholderImage:nil options:SDWebImageScaleDownLargeImages];
    [self updateAuthorAvatar:article];
    self.titleLabel.text = article.title ?: @"";
    self.authorLabel.text = article.authorName.length > 0 ? article.authorName : article.authorUid;
    self.dateLabel.text = [self dateTimeFromString:article.createTime.length > 0 ? article.createTime : article.updateTime];
    self.readCountLabel.text = article.readCount.length > 0 ? [NSString stringWithFormat:LLLLLL(@"CommunityDetail_ReadCount"), article.readCount] : @"";
    self.summaryLabel.attributedText =
        [UNDJKWIOKDCommunityBBCode attributedStringFromString:article.summary
                                                    baseFont:self.summaryLabel.font
                                                   textColor:self.summaryLabel.textColor];
    self.deleteButton.hidden = ![article.authorUid isEqualToString:self.currentUserId];
    [self renderContents:article.contents];

    BOOL hasLink = article.linkUrl.length > 0 || article.linkText.length > 0;
    self.linkButton.hidden = !hasLink;
    self.linkButtonHeightConstraint.constant = hasLink ? 40 : 0;
    [self.linkButton setTitle:(article.linkText.length > 0 ? article.linkText : LLLLLL(@"CommunityDetail_OpenLink")) forState:UIControlStateNormal];
}

- (void)updateAuthorAvatar:(WFCCCommunity *)article {
    NSString *portrait = self.authorPortrait ?: @"";
    if (portrait.length == 0) {
        NSString *authorUid = article.authorUid ?: @"";
        if (authorUid.length > 0) {
        WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:authorUid];
        portrait = userInfo.portrait ?: @"";
        }
    }
    [self.avatarView sd_setImageWithURL:URL(portrait)
                       placeholderImage:[AIOIUEHImage imageNamed:@"PersonalChat"]
                                options:SDWebImageScaleDownLargeImages];
}

- (void)renderContents:(NSArray<WFCCCommunityContent *> *)contents {
    for (UIView *view in self.contentsStackView.arrangedSubviews) {
        [self.contentsStackView removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    for (id item in contents) {
        WFCCCommunityContent *content = [self communityContentFromObject:item];
        if (!content) {
            continue;
        }
        if (content.imageUrl.length > 0) {
            UIImageView *imageView = [[UIImageView alloc] init];
            imageView.translatesAutoresizingMaskIntoConstraints = NO;
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            imageView.clipsToBounds = YES;
            imageView.backgroundColor = UIColor.blackColor;
            [imageView sd_setImageWithURL:URL(content.imageUrl) placeholderImage:nil options:SDWebImageScaleDownLargeImages];
            [self.contentsStackView addArrangedSubview:imageView];
            [imageView.heightAnchor constraintEqualToConstant:210].active = YES;
        }
        if (content.text.length > 0) {
            UILabel *label = [self labelWithFont:[UIFont systemFontOfSize:14] textColor:RGBA(0x777777)];
            label.numberOfLines = 0;
            label.attributedText =
                [UNDJKWIOKDCommunityBBCode attributedStringFromString:content.text
                                                            baseFont:label.font
                                                           textColor:label.textColor];
            [self.contentsStackView addArrangedSubview:label];
        }
    }
}

- (WFCCCommunityContent *)communityContentFromObject:(id)object {
    if ([object isKindOfClass:WFCCCommunityContent.class]) {
        return object;
    }
    if ([object isKindOfClass:NSDictionary.class]) {
        return [WFCCCommunityContent mj_objectWithKeyValues:object];
    }
    return nil;
}

- (NSString *)dateTimeFromString:(NSString *)dateString {
    NSString *value = [dateString stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
    if (value.length == 0) {
        return @"";
    }

    NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    if ([value rangeOfCharacterFromSet:nonDigits].location == NSNotFound) {
        NSTimeInterval timestamp = value.doubleValue;
        if (value.length > 10) {
            timestamp = timestamp / 1000.0;
        }
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        return [formatter stringFromDate:date];
    }

    NSMutableString *normalized = [[value stringByReplacingOccurrencesOfString:@"/" withString:@"-"] mutableCopy];
    if (normalized.length > 7) {
        if ([normalized characterAtIndex:4] == '.') {
            [normalized replaceCharactersInRange:NSMakeRange(4, 1) withString:@"-"];
        }
        if ([normalized characterAtIndex:7] == '.') {
            [normalized replaceCharactersInRange:NSMakeRange(7, 1) withString:@"-"];
        }
    }
    if (normalized.length > 10 && [normalized characterAtIndex:10] == 'T') {
        [normalized replaceCharactersInRange:NSMakeRange(10, 1) withString:@" "];
    }
    if (normalized.length >= 19) {
        return [normalized substringToIndex:19];
    }
    if (normalized.length >= 16) {
        return [[normalized substringToIndex:16] stringByAppendingString:@":00"];
    }
    if (normalized.length >= 10) {
        return [[normalized substringToIndex:10] stringByAppendingString:@" 00:00:00"];
    }
    return normalized;
}

- (void)backButtonDidTap {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)deleteButtonDidTap {
    if (self.article.articleId.length == 0) {
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LLLLLL(@"Community_DeleteMomentTitle") message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Community_Cancel") style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Community_Delete") style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        [weakSelf deleteCurrentArticle];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)deleteCurrentArticle {
    NSDictionary *param = @{@"articleId": @([self.article.articleId longLongValue])};
    __weak typeof(self) weakSelf = self;
    [[AppService sharedAppService] communityArticleDelete:param success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.articleDidUpdateBlock) {
                weakSelf.articleDidUpdateBlock();
            }
            [weakSelf.navigationController popViewControllerAnimated:YES];
        });
    } error:^(int errCode, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.view makeToast:(message.length > 0 ? message : LLLLLL(@"Community_DeleteFailed")) duration:1.2 position:CSToastPositionCenter];
        });
    }];
}

- (void)linkButtonDidTap {
    NSString *urlString = self.article.linkUrl ?: @"";
    if (urlString.length == 0) {
        return;
    }
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url.scheme.length) {
        url = [NSURL URLWithString:[@"https://" stringByAppendingString:urlString]];
    }
    if (url) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}

@end
