//
//  UNDJKWIOKDCommunityVC.m
//  WUHOIBDK
//
//  Created by Loooooo on 8/12/24.
//

#import "UNDJKWIOKDCommunityVC.h"
#import "AppService.h"
#import <WFChatClient/WFCCCommunity.h>
#import <WFChatClient/WFCCCommunityUser.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "UNDJKWIOKDCommunityArticleCell.h"
#import "UNDJKWIOKDCommunityPublishVC.h"
#import "UNDJKWIOKDCommunityDetailVC.h"

static CGFloat const kCommunityPagePadding = 15.0;
static CGFloat const kCommunityAuthorAvatarSize = 42.0;
static NSInteger const kCommunityAuthorAvatarTag = 7001;
static NSInteger const kCommunityAuthorNameTag = 7002;
static NSInteger const kCommunityAuthorUnreadDotTag = 7003;
static NSString * const kCommunityAuthorReadTimeKeyPrefix = @"kCommunityAuthorReadTime_";
static NSString * const kCommunityReadStateChangedNotification = @"kCommunityReadStateChangedNotification";

@interface WFCCCommunityList (UNDJKWIOKDCommunity)
@end

@implementation WFCCCommunityList (UNDJKWIOKDCommunity)

+ (NSDictionary *)mj_objectClassInArray {
    return @{@"content": [WFCCCommunity class]};
}

@end


@interface UNDJKWIOKDCommunityVC () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UIView *topBar;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *publishButton;
@property (nonatomic, strong) UIScrollView *authorsScrollView;
@property (nonatomic, strong) UIStackView *authorsStackView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *emptyLabel;

@property (nonatomic, copy) NSArray<WFCCCommunityUser *> *authors;
@property (nonatomic, copy) NSArray<WFCCCommunity *> *articles;
@property (nonatomic, strong) WFCCCommunityUser *selectedAuthor;
@property (nonatomic, copy) NSString *currentUserId;

@end

@implementation UNDJKWIOKDCommunityVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.currentUserId = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedUserId"] ?: @"";
    [self buildViews];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    [self refreshPermissionAndArticles];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    if (!self.isViewLoaded || self.view.window == nil) {
        return;
    }
    [self refreshPermissionAndArticles];
}

- (void)refreshPermissionAndArticles {
    self.currentUserId = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedUserId"] ?: @"";
    [self loadPublishPermission];
    if (self.selectedAuthor.uid.length > 0) {
        [self loadArticlesForAuthor:self.selectedAuthor];
    } else {
        [self loadAuthors];
    }
}

- (NSInteger)readTimeForAuthorUid:(NSString *)uid {
    if (uid.length == 0) {
        return 0;
    }
    NSString *key = [NSString stringWithFormat:@"%@%@", kCommunityAuthorReadTimeKeyPrefix, uid];
    return (NSInteger)[[NSUserDefaults standardUserDefaults] integerForKey:key];
}

- (void)markAuthorRead:(WFCCCommunityUser *)author {
    if (author.uid.length == 0) {
        return;
    }
    NSInteger readTime = [self readTimeForAuthorUid:author.uid];
    NSInteger latest = MAX(readTime, author.lastPublishTime);
    NSString *key = [NSString stringWithFormat:@"%@%@", kCommunityAuthorReadTimeKeyPrefix, author.uid];
    [[NSUserDefaults standardUserDefaults] setInteger:latest forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:kCommunityReadStateChangedNotification object:nil];
}

- (BOOL)shouldShowUnreadDotForAuthor:(WFCCCommunityUser *)author {
    if (!author || author.uid.length == 0 || author.lastPublishTime <= 0) {
        return NO;
    }
    return author.lastPublishTime > [self readTimeForAuthorUid:author.uid];
}

- (void)buildViews {
    self.topBar = [[UIView alloc] init];
    self.topBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.topBar];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.text = LLLLLL(@"Community");
    self.titleLabel.backgroundColor = UIColor.clearColor;
    self.titleLabel.textAlignment = NSTextAlignmentLeft;
    self.titleLabel.textColor = RGBA(0x222222);
    self.titleLabel.font = PINGFANG_M(23.0);
    [self.topBar addSubview:self.titleLabel];

    self.publishButton = [UIButton new];
    self.publishButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.publishButton.hidden = YES;
    UIImage *publishImage = [UIImage imageNamed:@"community_public"] ?: [AIOIUEHImage imageNamed:@"community_public"];
    publishImage = [publishImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [self.publishButton setImage:publishImage forState:UIControlStateNormal];
    self.publishButton.adjustsImageWhenHighlighted = NO;
    self.publishButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.publishButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    self.publishButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [self.publishButton addTarget:self action:@selector(publishButtonDidTap) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.publishButton];

    self.authorsScrollView = [[UIScrollView alloc] init];
    self.authorsScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.authorsScrollView.showsHorizontalScrollIndicator = NO;
    self.authorsScrollView.alwaysBounceHorizontal = YES;
    self.authorsScrollView.directionalLockEnabled = YES;
    [self.view addSubview:self.authorsScrollView];

    self.authorsStackView = [[UIStackView alloc] init];
    self.authorsStackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.authorsStackView.axis = UILayoutConstraintAxisHorizontal;
    self.authorsStackView.alignment = UIStackViewAlignmentTop;
    self.authorsStackView.spacing = 0;
    [self.authorsScrollView addSubview:self.authorsStackView];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = UIColor.whiteColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 260;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:UNDJKWIOKDCommunityArticleCell.class forCellReuseIdentifier:@"UNDJKWIOKDCommunityArticleCell"];
    [self.view addSubview:self.tableView];

    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.text = LLLLLL(@"Community_NoContent");
    self.emptyLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1];
    self.emptyLabel.font = [UIFont systemFontOfSize:15];
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.hidden = YES;
    self.tableView.backgroundView = self.emptyLabel;

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.topBar.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:44],
        [self.topBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.topBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.topBar.heightAnchor constraintEqualToConstant:56],

        [self.titleLabel.topAnchor constraintEqualToAnchor:self.topBar.topAnchor constant:12],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.topBar.leadingAnchor constant:20],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.topBar.trailingAnchor constant:-20],
        [self.titleLabel.heightAnchor constraintEqualToConstant:35],

        [self.publishButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.publishButton.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:8],
        [self.publishButton.widthAnchor constraintEqualToConstant:32],
        [self.publishButton.heightAnchor constraintEqualToConstant:32],

        [self.authorsScrollView.topAnchor constraintEqualToAnchor:self.topBar.bottomAnchor constant:10],
        [self.authorsScrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.authorsScrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.authorsScrollView.heightAnchor constraintEqualToConstant:80],

        [self.authorsStackView.topAnchor constraintEqualToAnchor:self.authorsScrollView.contentLayoutGuide.topAnchor],
        [self.authorsStackView.leadingAnchor constraintEqualToAnchor:self.authorsScrollView.contentLayoutGuide.leadingAnchor],
        [self.authorsStackView.trailingAnchor constraintEqualToAnchor:self.authorsScrollView.contentLayoutGuide.trailingAnchor],
        [self.authorsStackView.bottomAnchor constraintEqualToAnchor:self.authorsScrollView.contentLayoutGuide.bottomAnchor],
        [self.authorsStackView.heightAnchor constraintEqualToAnchor:self.authorsScrollView.frameLayoutGuide.heightAnchor],

        [self.tableView.topAnchor constraintEqualToAnchor:self.authorsScrollView.bottomAnchor constant:10],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor],
    ]];
}

- (void)loadPublishPermission {
    __weak typeof(self) weakSelf = self;
    [[AppService sharedAppService] communityArticlePublishPermission:^(BOOL canpublish) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.publishButton.hidden = !canpublish;
            [weakSelf.view bringSubviewToFront:weakSelf.publishButton];
        });
    } error:^(int errCode, NSString * _Nonnull message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.publishButton.hidden = YES;
        });
    }];
}

- (void)loadAuthors {
    __weak typeof(self) weakSelf = self;
    [[AppService sharedAppService] communityArticleAuthors:^(NSArray<WFCCCommunityUser *> * _Nonnull members) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.authors = members ?: @[];
            [weakSelf renderAuthors];
            if (weakSelf.authors.count > 0) {
                [weakSelf selectAuthor:weakSelf.authors.firstObject];
            } else {
                [weakSelf renderArticles:@[]];
            }
        });
    } error:^(int errCode, NSString * _Nonnull message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.authors = @[];
            [weakSelf renderAuthors];
            [weakSelf renderArticles:@[]];
        });
    }];
}

- (void)renderAuthors {
    for (UIView *view in self.authorsStackView.arrangedSubviews) {
        [self.authorsStackView removeArrangedSubview:view];
        [view removeFromSuperview];
    }

    CGFloat itemWidth = floor(CGRectGetWidth(UIScreen.mainScreen.bounds) / 4.0);
    for (WFCCCommunityUser *author in self.authors) {
        UIButton *button = [self authorButtonWithAuthor:author itemWidth:itemWidth];
        [self.authorsStackView addArrangedSubview:button];
        [button.widthAnchor constraintEqualToConstant:itemWidth].active = YES;
        [button.heightAnchor constraintEqualToConstant:80.0].active = YES;
    }
}

- (UIButton *)authorButtonWithAuthor:(WFCCCommunityUser *)author itemWidth:(CGFloat)itemWidth {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.tag = [self.authors indexOfObject:author];
    [button addTarget:self action:@selector(authorButtonDidTap:) forControlEvents:UIControlEventTouchUpInside];

    UIImageView *avatarView = [[UIImageView alloc] init];
    avatarView.translatesAutoresizingMaskIntoConstraints = NO;
    avatarView.contentMode = UIViewContentModeScaleAspectFill;
    avatarView.clipsToBounds = YES;
    avatarView.layer.cornerRadius = kCommunityAuthorAvatarSize / 2.0;
    avatarView.layer.borderWidth = 1.5;
    avatarView.layer.borderColor = RGBA(0xE8E8E8).CGColor;
    avatarView.tag = kCommunityAuthorAvatarTag;
    [avatarView sd_setImageWithURL:URL(author.portrait) placeholderImage:[AIOIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages];
    [button addSubview:avatarView];

    UIView *dotView = [[UIView alloc] init];
    dotView.translatesAutoresizingMaskIntoConstraints = NO;
    dotView.backgroundColor = UIColor.redColor;
    dotView.layer.cornerRadius = 4;
    dotView.clipsToBounds = YES;
    dotView.tag = kCommunityAuthorUnreadDotTag;
    dotView.hidden = ![self shouldShowUnreadDotForAuthor:author];
    [button addSubview:dotView];

    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    nameLabel.text = author.displayName.length > 0 ? author.displayName : author.uid;
    nameLabel.font = [UIFont systemFontOfSize:12];
    nameLabel.textColor = RGBA(0x333333);
    nameLabel.textAlignment = NSTextAlignmentCenter;
    nameLabel.tag = kCommunityAuthorNameTag;
    nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [button addSubview:nameLabel];

    [NSLayoutConstraint activateConstraints:@[
        [avatarView.topAnchor constraintEqualToAnchor:button.topAnchor constant:4],
        [avatarView.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
        [avatarView.widthAnchor constraintEqualToConstant:kCommunityAuthorAvatarSize],
        [avatarView.heightAnchor constraintEqualToConstant:kCommunityAuthorAvatarSize],

        [dotView.widthAnchor constraintEqualToConstant:8],
        [dotView.heightAnchor constraintEqualToConstant:8],
        [dotView.topAnchor constraintEqualToAnchor:avatarView.topAnchor constant:2],
        [dotView.trailingAnchor constraintEqualToAnchor:avatarView.trailingAnchor constant:-1],

        [nameLabel.topAnchor constraintEqualToAnchor:avatarView.bottomAnchor constant:7],
        [nameLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:button.leadingAnchor constant:4],
        [nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:button.trailingAnchor constant:-4],
        [nameLabel.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
        [nameLabel.bottomAnchor constraintLessThanOrEqualToAnchor:button.bottomAnchor constant:-4],
    ]];

    return button;
}

- (void)authorButtonDidTap:(UIButton *)sender {
    if (sender.tag < 0 || sender.tag >= self.authors.count) {
        return;
    }
    [self selectAuthor:self.authors[sender.tag]];
}

- (void)selectAuthor:(WFCCCommunityUser *)author {
    self.selectedAuthor = author;
    [self markAuthorRead:author];
    [self updateAuthorSelectionViews];
    [self loadArticlesForAuthor:author];
}

- (void)updateAuthorSelectionViews {
    for (UIButton *button in self.authorsStackView.arrangedSubviews) {
        if (![button isKindOfClass:UIButton.class]) {
            continue;
        }
        BOOL selected = button.tag < self.authors.count && [self.authors[button.tag].uid isEqualToString:self.selectedAuthor.uid];
        WFCCCommunityUser *author = button.tag < self.authors.count ? self.authors[button.tag] : nil;
        UIImageView *avatarView = (UIImageView *)[button viewWithTag:kCommunityAuthorAvatarTag];
        UILabel *nameLabel = (UILabel *)[button viewWithTag:kCommunityAuthorNameTag];
        UIView *dotView = [button viewWithTag:kCommunityAuthorUnreadDotTag];
        avatarView.layer.borderWidth = selected ? 2.0 : 1.5;
        avatarView.layer.borderColor = (selected ? RGBA(0x3B83D9) : RGBA(0xE8E8E8)).CGColor;
        nameLabel.textColor = selected ? RGBA(0x3B83D9) : RGBA(0x333333);
        dotView.hidden = ![self shouldShowUnreadDotForAuthor:author];
    }
}

- (void)loadArticlesForAuthor:(WFCCCommunityUser *)author {
    if (author.uid.length == 0) {
        [self renderArticles:@[]];
        return;
    }

    NSDictionary *param = @{
        @"page": @0,
        @"limit": @100,
        @"title": @"",
        @"authorUid": author.uid
    };

    __weak typeof(self) weakSelf = self;
    [[AppService sharedAppService] communityArticleList:param success:^(WFCCCommunityList * _Nonnull list) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf renderArticles:[weakSelf articlesFromList:list]];
        });
    } error:^(int errCode, NSString * _Nonnull message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf renderArticles:@[]];
        });
    }];
}

- (NSArray<WFCCCommunity *> *)articlesFromList:(WFCCCommunityList *)list {
    NSMutableArray<WFCCCommunity *> *articles = [NSMutableArray array];
    NSArray *content = (NSArray *)list.content;
    for (id item in content) {
        if ([item isKindOfClass:WFCCCommunity.class]) {
            [articles addObject:item];
        } else if ([item isKindOfClass:NSDictionary.class]) {
            WFCCCommunity *article = [WFCCCommunity mj_objectWithKeyValues:item];
            if (article) {
                [articles addObject:article];
            }
        } else if ([item respondsToSelector:@selector(mj_keyValues)]) {
            WFCCCommunity *article = [WFCCCommunity mj_objectWithKeyValues:[item mj_keyValues]];
            if (article) {
                [articles addObject:article];
            }
        }
    }
    return articles;
}

- (void)renderArticles:(NSArray<WFCCCommunity *> *)articles {
    self.articles = articles ?: @[];
    self.emptyLabel.hidden = self.articles.count > 0;
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.articles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UNDJKWIOKDCommunityArticleCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UNDJKWIOKDCommunityArticleCell" forIndexPath:indexPath];
    WFCCCommunity *article = self.articles[indexPath.row];
    NSString *authorName = article.authorName.length > 0 ? article.authorName : [self nameForArticle:article];
    NSString *date = [self dateTimeFromString:article.createTime.length > 0 ? article.createTime : article.updateTime];
    [cell configureWithArticle:article
                      portrait:[self portraitForArticle:article]
                    authorName:authorName
                          date:date
                     canDelete:[article.authorUid isEqualToString:self.currentUserId]];
    [cell setDeleteTarget:self action:@selector(deleteArticleButtonDidTap:)];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < 0 || indexPath.row >= self.articles.count) {
        return;
    }
    UNDJKWIOKDCommunityDetailVC *vc = [[UNDJKWIOKDCommunityDetailVC alloc] init];
    vc.article = self.articles[indexPath.row];
    vc.authorPortrait = [self portraitForArticle:vc.article];
    vc.currentUserId = self.currentUserId;
    __weak typeof(self) weakSelf = self;
    vc.articleDidUpdateBlock = ^{
        [weakSelf loadArticlesForAuthor:weakSelf.selectedAuthor];
    };
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (NSString *)portraitForArticle:(WFCCCommunity *)article {
    if ([article.authorUid isEqualToString:self.selectedAuthor.uid]) {
        return self.selectedAuthor.portrait ?: @"";
    }
    return @"";
}

- (NSString *)nameForArticle:(WFCCCommunity *)article {
    if ([article.authorUid isEqualToString:self.selectedAuthor.uid]) {
        return self.selectedAuthor.displayName ?: @"";
    }
    return article.authorUid ?: @"";
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

- (void)deleteArticleButtonDidTap:(UIButton *)sender {
    NSString *articleId = sender.accessibilityIdentifier;
    if (articleId.length == 0) {
        return;
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LLLLLL(@"Community_DeleteMomentTitle") message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Community_Cancel") style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Community_Delete") style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        [weakSelf deleteArticleWithId:articleId];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)deleteArticleWithId:(NSString *)articleId {
    NSDictionary *param = @{@"articleId": @([articleId longLongValue])};
    __weak typeof(self) weakSelf = self;
    [[AppService sharedAppService] communityArticleDelete:param success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf loadArticlesForAuthor:weakSelf.selectedAuthor];
        });
    } error:^(int errCode, NSString * _Nonnull message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.view makeToast:(message.length > 0 ? message : LLLLLL(@"Community_DeleteFailed")) duration:1.2 position:CSToastPositionCenter];
        });
    }];
}

- (void)publishButtonDidTap {
    UNDJKWIOKDCommunityPublishVC *vc = [[UNDJKWIOKDCommunityPublishVC alloc] init];
    __weak typeof(self) weakSelf = self;
    vc.publishSuccessBlock = ^{
        [weakSelf loadAuthors];
    };
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
