//
//  WOPMKDIOFZTCheckInVC.m
//  WildFireChat
//

#import "WOPMKDIOFZTCheckInVC.h"
#import "AppService.h"
#import "MBProgressHUD.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <WFChatClient/WFCChatClient.h>

static NSString *WOPMKDIOFZTSafeText(id value) {
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    if ([value respondsToSelector:@selector(stringValue)]) {
        return [value stringValue];
    }
    return @"";
}

@interface WOPMKDIOFZTCheckInUserCell : UITableViewCell

@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIImageView *checkView;
@property (nonatomic, strong) UIView *bottomLine;

@end

@implementation WOPMKDIOFZTCheckInUserCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.avatarView = [[UIImageView alloc] init];
    self.avatarView.translatesAutoresizingMaskIntoConstraints = NO;
    self.avatarView.layer.cornerRadius = 26.0;
    self.avatarView.layer.masksToBounds = YES;
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    [self.contentView addSubview:self.avatarView];
    
    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightRegular];
    self.nameLabel.textColor = [UIColor colorWithRed:0.16 green:0.16 blue:0.16 alpha:1.0];
    [self.contentView addSubview:self.nameLabel];
    
    self.checkView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"me_checkIn_select_user"]];
    self.checkView.translatesAutoresizingMaskIntoConstraints = NO;
    self.checkView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:self.checkView];
    
    self.bottomLine = [[UIView alloc] init];
    self.bottomLine.translatesAutoresizingMaskIntoConstraints = NO;
    self.bottomLine.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
    [self.contentView addSubview:self.bottomLine];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.avatarView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:34],
        [self.avatarView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.avatarView.widthAnchor constraintEqualToConstant:52],
        [self.avatarView.heightAnchor constraintEqualToConstant:52],
        
        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.avatarView.trailingAnchor constant:26],
        [self.nameLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.checkView.leadingAnchor constant:-16],
        
        [self.checkView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-36],
        [self.checkView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.checkView.widthAnchor constraintEqualToConstant:27],
        [self.checkView.heightAnchor constraintEqualToConstant:18],
        
        [self.bottomLine.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:34],
        [self.bottomLine.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-34],
        [self.bottomLine.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
        [self.bottomLine.heightAnchor constraintEqualToConstant:0.5]
    ]];
}

- (void)configWithTask:(WFCCSignTask *)task selected:(BOOL)selected {
    NSString *taskName = WOPMKDIOFZTSafeText(task.taskName);
    NSString *creatorName = WOPMKDIOFZTSafeText(task.creatorDisplayName);
    self.nameLabel.text = taskName.length ? taskName : (creatorName.length ? creatorName : @"用户名称");
    UIImage *placeholder = [UIImage imageNamed:@"me_checkIn_user_avatar"];
    if (task.creatorPortrait.length > 0) {
        [self.avatarView sd_setImageWithURL:[NSURL URLWithString:task.creatorPortrait] placeholderImage:placeholder options:SDWebImageScaleDownLargeImages];
    } else {
        self.avatarView.image = placeholder;
    }
    self.checkView.hidden = !selected;
}

@end

@interface WOPMKDIOFZTCheckInVC () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *userView;
@property (nonatomic, strong) UIImageView *userBgImageView;
@property (nonatomic, strong) UIImageView *userAvatarView;
@property (nonatomic, strong) UILabel *userNameLabel;
@property (nonatomic, strong) UIImageView *arrowView;

@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UILabel *continuousLabel;
@property (nonatomic, strong) UILabel *timezoneLabel;
@property (nonatomic, strong) NSMutableArray<UIImageView *> *dayImageViews;
@property (nonatomic, strong) NSMutableArray<UIImageView *> *dayCheckImageViews;
@property (nonatomic, strong) NSMutableArray<UILabel *> *dateLabels;
@property (nonatomic, strong) UIButton *checkButton;
@property (nonatomic, strong) UILabel *walletHintLabel;
@property (nonatomic, strong) UILabel *ruleTitleLabel;
@property (nonatomic, strong) UILabel *ruleLabel;

@property (nonatomic, strong) UIView *maskView;
@property (nonatomic, strong) UIView *successPanel;
@property (nonatomic, strong) UIView *selectorPanel;
@property (nonatomic, strong) UITableView *selectorTableView;
@property (nonatomic, strong) NSLayoutConstraint *selectorPanelHeightConstraint;

@property (nonatomic, strong) NSArray<WFCCSignTask *> *tasks;
@property (nonatomic, strong) WFCCSignTask *selectedTask;
@property (nonatomic, strong) WFCCSignTask *pendingSelectedTask;
@property (nonatomic, strong) WFCCSignTasks *taskSnapshot;
@property (nonatomic, strong) NSArray<NSDate *> *weekDates;
@property (nonatomic, assign) BOOL loading;

@end

@implementation WOPMKDIOFZTCheckInVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:225.0 / 255.0 green:243.0 / 255.0 blue:226.0 / 255.0 alpha:1.0];
    self.title = @"签到福利";
    self.dayImageViews = [NSMutableArray array];
    self.dayCheckImageViews = [NSMutableArray array];
    self.dateLabels = [NSMutableArray array];
    self.tasks = @[];
    [self reloadWeekDates];
    [self setupUI];
    [self loadSignTasks];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = NO;
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
}

#pragma mark - UI

- (void)setupUI {
    [self setupContentView];
    [self setupUserView];
    [self setupCheckInCard];
    [self setupRuleView];
    [self setupMaskView];
}

- (void)setupContentView {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.scrollView];
    
    self.contentView = [[UIView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentView.backgroundColor = [UIColor clearColor];
    [self.scrollView addSubview:self.contentView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        
        [self.contentView.topAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.topAnchor],
        [self.contentView.leadingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.trailingAnchor],
        [self.contentView.bottomAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.bottomAnchor],
        [self.contentView.widthAnchor constraintEqualToAnchor:self.scrollView.frameLayoutGuide.widthAnchor]
    ]];
}

- (void)setupUserView {
    self.userView = [[UIView alloc] init];
    self.userView.translatesAutoresizingMaskIntoConstraints = NO;
    self.userView.layer.cornerRadius = 29.0;
    self.userView.layer.masksToBounds = YES;
    self.userView.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.userView];
    
    self.userBgImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"me_checkIn_user_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(29, 60, 29, 60) resizingMode:UIImageResizingModeStretch]];
    self.userBgImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.userBgImageView.contentMode = UIViewContentModeScaleToFill;
    [self.userView addSubview:self.userBgImageView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showUserSelector)];
    [self.userView addGestureRecognizer:tap];
    
    self.userAvatarView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"me_checkIn_user_avatar"]];
    self.userAvatarView.translatesAutoresizingMaskIntoConstraints = NO;
    self.userAvatarView.layer.cornerRadius = 25.0;
    self.userAvatarView.layer.masksToBounds = YES;
    self.userAvatarView.contentMode = UIViewContentModeScaleAspectFill;
    [self.userView addSubview:self.userAvatarView];
    
    self.userNameLabel = [[UILabel alloc] init];
    self.userNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.userNameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.userNameLabel.textColor = [UIColor colorWithRed:0.17 green:0.17 blue:0.17 alpha:1.0];
    self.userNameLabel.text = @"用户名称";
    [self.userView addSubview:self.userNameLabel];
    
    self.arrowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"me_checkIn_user_arrow"]];
    self.arrowView.translatesAutoresizingMaskIntoConstraints = NO;
    self.arrowView.contentMode = UIViewContentModeScaleAspectFit;
    [self.userView addSubview:self.arrowView];
    
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.userView.topAnchor constraintEqualToAnchor:safe.topAnchor constant:12],
        [self.userView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:14.5],
        [self.userView.widthAnchor constraintEqualToConstant:218],
        [self.userView.heightAnchor constraintEqualToConstant:58],
        
        [self.userBgImageView.topAnchor constraintEqualToAnchor:self.userView.topAnchor],
        [self.userBgImageView.leadingAnchor constraintEqualToAnchor:self.userView.leadingAnchor],
        [self.userBgImageView.trailingAnchor constraintEqualToAnchor:self.userView.trailingAnchor],
        [self.userBgImageView.bottomAnchor constraintEqualToAnchor:self.userView.bottomAnchor],
        
        [self.userAvatarView.leadingAnchor constraintEqualToAnchor:self.userView.leadingAnchor constant:8],
        [self.userAvatarView.centerYAnchor constraintEqualToAnchor:self.userView.centerYAnchor],
        [self.userAvatarView.widthAnchor constraintEqualToConstant:50],
        [self.userAvatarView.heightAnchor constraintEqualToConstant:50],
        
        [self.arrowView.trailingAnchor constraintEqualToAnchor:self.userView.trailingAnchor constant:-27],
        [self.arrowView.centerYAnchor constraintEqualToAnchor:self.userView.centerYAnchor],
        [self.arrowView.widthAnchor constraintEqualToConstant:11],
        [self.arrowView.heightAnchor constraintEqualToConstant:20],
        
        [self.userNameLabel.leadingAnchor constraintEqualToAnchor:self.userAvatarView.trailingAnchor constant:16],
        [self.userNameLabel.trailingAnchor constraintEqualToAnchor:self.arrowView.leadingAnchor constant:-10],
        [self.userNameLabel.centerYAnchor constraintEqualToAnchor:self.userView.centerYAnchor]
    ]];
}

- (void)setupCheckInCard {
    self.cardView = [[UIView alloc] init];
    self.cardView.translatesAutoresizingMaskIntoConstraints = NO;
    self.cardView.backgroundColor = [UIColor clearColor];
    self.cardView.layer.cornerRadius = 18.0;
    self.cardView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.cardView];
    
    UIImageView *cardBgImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"me_checkIn_check_section_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(30, 30, 30, 30) resizingMode:UIImageResizingModeStretch]];
    cardBgImageView.translatesAutoresizingMaskIntoConstraints = NO;
    cardBgImageView.contentMode = UIViewContentModeScaleToFill;
    [self.cardView addSubview:cardBgImageView];
    
    self.continuousLabel = [[UILabel alloc] init];
    self.continuousLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.continuousLabel.font = [UIFont systemFontOfSize:19 weight:UIFontWeightRegular];
    self.continuousLabel.textColor = [UIColor colorWithRed:0.16 green:0.16 blue:0.16 alpha:1.0];
    [self.cardView addSubview:self.continuousLabel];
    
    self.timezoneLabel = [[UILabel alloc] init];
    self.timezoneLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.timezoneLabel.text = @"UTC + 8";
    self.timezoneLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    self.timezoneLabel.textColor = [UIColor colorWithRed:0.34 green:0.34 blue:0.34 alpha:1.0];
    [self.cardView addSubview:self.timezoneLabel];
    
    UIView *weekContainer = [[UIView alloc] init];
    weekContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cardView addSubview:weekContainer];
    
    NSMutableArray<UIView *> *dayContainers = [NSMutableArray array];
    for (NSInteger i = 0; i < 7; i++) {
        UIView *dayContainer = [[UIView alloc] init];
        dayContainer.translatesAutoresizingMaskIntoConstraints = NO;
        [weekContainer addSubview:dayContainer];
        [dayContainers addObject:dayContainer];
        
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [dayContainer addSubview:imageView];
        [self.dayImageViews addObject:imageView];
        
        UIImageView *checkImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"me_checkIn_checked"]];
        checkImageView.translatesAutoresizingMaskIntoConstraints = NO;
        checkImageView.contentMode = UIViewContentModeScaleAspectFit;
        checkImageView.hidden = YES;
        [dayContainer addSubview:checkImageView];
        [self.dayCheckImageViews addObject:checkImageView];
        
        UILabel *dateLabel = [[UILabel alloc] init];
        dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
        dateLabel.textAlignment = NSTextAlignmentCenter;
        dateLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        [dayContainer addSubview:dateLabel];
        [self.dateLabels addObject:dateLabel];
        
        [NSLayoutConstraint activateConstraints:@[
            [imageView.topAnchor constraintEqualToAnchor:dayContainer.topAnchor],
            [imageView.centerXAnchor constraintEqualToAnchor:dayContainer.centerXAnchor],
            [imageView.widthAnchor constraintEqualToConstant:42],
            [imageView.heightAnchor constraintEqualToConstant:58],
            
            [checkImageView.centerXAnchor constraintEqualToAnchor:imageView.centerXAnchor],
            [checkImageView.centerYAnchor constraintEqualToAnchor:imageView.centerYAnchor],
            [checkImageView.widthAnchor constraintEqualToConstant:30],
            [checkImageView.heightAnchor constraintEqualToConstant:30],
            
            [dateLabel.topAnchor constraintEqualToAnchor:imageView.bottomAnchor constant:14],
            [dateLabel.leadingAnchor constraintEqualToAnchor:dayContainer.leadingAnchor],
            [dateLabel.trailingAnchor constraintEqualToAnchor:dayContainer.trailingAnchor],
            [dateLabel.bottomAnchor constraintEqualToAnchor:dayContainer.bottomAnchor]
        ]];
    }
    for (NSInteger i = 0; i < dayContainers.count; i++) {
        UIView *dayContainer = dayContainers[i];
        [NSLayoutConstraint activateConstraints:@[
            [dayContainer.topAnchor constraintEqualToAnchor:weekContainer.topAnchor],
            [dayContainer.bottomAnchor constraintEqualToAnchor:weekContainer.bottomAnchor],
            [dayContainer.widthAnchor constraintEqualToAnchor:weekContainer.widthAnchor multiplier:1.0 / 7.0]
        ]];
        if (i == 0) {
            [dayContainer.leadingAnchor constraintEqualToAnchor:weekContainer.leadingAnchor].active = YES;
        } else {
            [dayContainer.leadingAnchor constraintEqualToAnchor:dayContainers[i - 1].trailingAnchor].active = YES;
        }
        if (i == dayContainers.count - 1) {
            [dayContainer.trailingAnchor constraintEqualToAnchor:weekContainer.trailingAnchor].active = YES;
        }
    }
    
    self.checkButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.checkButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.checkButton.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    [self.checkButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.checkButton setTitle:@"立即签到" forState:UIControlStateNormal];
    UIImage *buttonImage = [[UIImage imageNamed:@"me_checkIn_btn_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(20, 30, 20, 30) resizingMode:UIImageResizingModeStretch];
    [self.checkButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.checkButton addTarget:self action:@selector(checkButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.cardView addSubview:self.checkButton];
    
    self.walletHintLabel = [[UILabel alloc] init];
    self.walletHintLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.walletHintLabel.text = @"签到奖励存入球币钱包";
    self.walletHintLabel.textAlignment = NSTextAlignmentCenter;
    self.walletHintLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    self.walletHintLabel.textColor = [UIColor colorWithWhite:0.68 alpha:1.0];
    [self.cardView addSubview:self.walletHintLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [cardBgImageView.topAnchor constraintEqualToAnchor:self.cardView.topAnchor],
        [cardBgImageView.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor],
        [cardBgImageView.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor],
        [cardBgImageView.bottomAnchor constraintEqualToAnchor:self.cardView.bottomAnchor],
        
        [self.cardView.topAnchor constraintEqualToAnchor:self.userView.bottomAnchor constant:34],
        [self.cardView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:14.5],
        [self.cardView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-14.5],
        [self.cardView.heightAnchor constraintEqualToConstant:304],
        
        [self.continuousLabel.topAnchor constraintEqualToAnchor:self.cardView.topAnchor constant:27],
        [self.continuousLabel.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:16.5],
        [self.continuousLabel.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-32],
        
        [self.timezoneLabel.topAnchor constraintEqualToAnchor:self.continuousLabel.bottomAnchor constant:10],
        [self.timezoneLabel.leadingAnchor constraintEqualToAnchor:self.continuousLabel.leadingAnchor],
        
        [weekContainer.topAnchor constraintEqualToAnchor:self.cardView.topAnchor constant:116],
        [weekContainer.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor],
        [weekContainer.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor],
        [weekContainer.heightAnchor constraintEqualToConstant:94],
        
        [self.checkButton.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:35],
        [self.checkButton.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-35],
        [self.checkButton.topAnchor constraintEqualToAnchor:self.cardView.topAnchor constant:226],
        [self.checkButton.heightAnchor constraintEqualToConstant:40],
        
        [self.walletHintLabel.topAnchor constraintEqualToAnchor:self.checkButton.bottomAnchor constant:10],
        [self.walletHintLabel.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:30],
        [self.walletHintLabel.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-30]
    ]];
}

- (void)setupRuleView {
    self.ruleTitleLabel = [[UILabel alloc] init];
    self.ruleTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.ruleTitleLabel.text = @"签到规则:";
    self.ruleTitleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    self.ruleTitleLabel.textColor = [UIColor colorWithRed:0.13 green:0.15 blue:0.15 alpha:1.0];
    [self.contentView addSubview:self.ruleTitleLabel];
    
    self.ruleLabel = [[UILabel alloc] init];
    self.ruleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.ruleLabel.numberOfLines = 0;
    self.ruleLabel.text = @"";
    self.ruleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.ruleLabel.textColor = [UIColor colorWithRed:0.13 green:0.15 blue:0.15 alpha:1.0];
    [self.contentView addSubview:self.ruleLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.ruleTitleLabel.topAnchor constraintEqualToAnchor:self.cardView.bottomAnchor constant:28],
        [self.ruleTitleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:15.5],
        [self.ruleTitleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-15.5],
        
        [self.ruleLabel.topAnchor constraintEqualToAnchor:self.ruleTitleLabel.bottomAnchor constant:12],
        [self.ruleLabel.leadingAnchor constraintEqualToAnchor:self.ruleTitleLabel.leadingAnchor],
        [self.ruleLabel.trailingAnchor constraintEqualToAnchor:self.ruleTitleLabel.trailingAnchor],
        [self.ruleLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-40]
    ]];
}

- (void)setupMaskView {
    self.maskView = [[UIView alloc] init];
    self.maskView.translatesAutoresizingMaskIntoConstraints = NO;
    self.maskView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.55];
    self.maskView.hidden = YES;
    [self.view addSubview:self.maskView];
    [self.maskView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissModalViews)]];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.maskView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.maskView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.maskView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.maskView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

#pragma mark - Data

- (void)loadSignTasks {
    if (self.loading) {
        return;
    }
    self.loading = YES;
    MBProgressHUD *hud = [self showLoadingHUD];
    __weak typeof(self) weakSelf = self;
    [[AppService sharedAppService] signTasks:^(WFCCSignTasks * _Nonnull tasks) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [hud hideAnimated:YES];
            strongSelf.loading = NO;
            strongSelf.taskSnapshot = tasks;
            strongSelf.tasks = tasks.tasks ?: @[];
            if (!strongSelf.selectedTask || ![strongSelf.tasks containsObject:strongSelf.selectedTask]) {
                strongSelf.selectedTask = strongSelf.tasks.firstObject;
            }
            [strongSelf refreshContent];
        });
    } error:^(int errCode, NSString * _Nonnull message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [hud hideAnimated:YES];
            strongSelf.loading = NO;
            [strongSelf showTextHUD:(message.length ? message : @"获取签到信息失败")];
            [strongSelf refreshContent];
        });
    }];
}

- (void)refreshContent {
    WFCCSignTask *task = self.selectedTask;
    NSString *taskName = WOPMKDIOFZTSafeText(task.taskName);
    NSString *creatorName = WOPMKDIOFZTSafeText(task.creatorDisplayName);
    NSString *userName = taskName.length ? taskName : (creatorName.length ? creatorName : @"暂无活动用户");
    self.userNameLabel.text = userName;
    NSString *rewardDesc = WOPMKDIOFZTSafeText(task.rewardDesc);
    self.ruleLabel.text = rewardDesc.length ? rewardDesc : @"暂无签到规则";
    
    UIImage *placeholder = [UIImage imageNamed:@"me_checkIn_user_avatar"];
    if (task.creatorPortrait.length > 0) {
        [self.userAvatarView sd_setImageWithURL:[NSURL URLWithString:task.creatorPortrait] placeholderImage:placeholder options:SDWebImageScaleDownLargeImages];
    } else {
        self.userAvatarView.image = placeholder;
    }
    
    self.arrowView.hidden = self.tasks.count <= 1;
    self.userView.userInteractionEnabled = self.tasks.count > 1;
    
    NSInteger continuousDays = [task.progress integerValue];
    if (continuousDays <= 0 && task.recent7DaySummary.count > 0) {
        continuousDays = [task.recent7DaySummary.firstObject.signedDays integerValue];
    }
    self.continuousLabel.attributedText = [self continuousText:MAX(continuousDays, 0)];
    
    NSSet<NSString *> *signedDateKeys = [self signedDateKeysForTask:task];
    NSString *todayKey = [self dayKeyForDate:[NSDate date]];
    BOOL todaySigned = [signedDateKeys containsObject:todayKey];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:8 * 3600];
    formatter.dateFormat = @"MM/dd";
    
    for (NSInteger i = 0; i < self.weekDates.count && i < self.dayImageViews.count; i++) {
        NSDate *date = self.weekDates[i];
        NSString *key = [self dayKeyForDate:date];
        BOOL signedDay = [signedDateKeys containsObject:key];
        UIImageView *imageView = self.dayImageViews[i];
        UIImageView *checkImageView = self.dayCheckImageViews[i];
        UILabel *label = self.dateLabels[i];
        imageView.image = [UIImage imageNamed:(signedDay ? @"me_checkIn_checked_bg" : @"me_checkIn_uncheck")];
        checkImageView.hidden = !signedDay;
        label.text = [formatter stringFromDate:date];
        label.textColor = signedDay ? [UIColor colorWithRed:0.13 green:0.13 blue:0.13 alpha:1.0] : [UIColor colorWithWhite:0.68 alpha:1.0];
    }
    
    BOOL hasTask = task != nil;
    self.checkButton.enabled = hasTask && !todaySigned;
    self.checkButton.alpha = self.checkButton.enabled ? 1.0 : 0.65;
    [self.checkButton setTitle:(hasTask ? (todaySigned ? @"今日已签到" : @"立即签到") : @"暂无签到活动") forState:UIControlStateNormal];
}

#pragma mark - Actions

- (void)checkButtonAction {
    if (!self.selectedTask.taskId.length || self.loading) {
        return;
    }
    self.loading = YES;
    MBProgressHUD *hud = [self showLoadingHUD];
    __weak typeof(self) weakSelf = self;
    [[AppService sharedAppService] signSubmit:@{@"taskId" : self.selectedTask.taskId} success:^(WFCCSign * _Nonnull sign) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [hud hideAnimated:YES];
            strongSelf.loading = NO;
            [strongSelf showSuccessPanelWithPoints:[sign.earnedPoints integerValue]];
            [strongSelf loadSignTasks];
        });
    } error:^(int errCode, NSString * _Nonnull message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [hud hideAnimated:YES];
            strongSelf.loading = NO;
            [strongSelf showTextHUD:(message.length ? message : @"签到失败")];
            [strongSelf loadSignTasks];
        });
    }];
}

- (void)showUserSelector {
    if (self.tasks.count <= 1) {
        return;
    }
    self.maskView.hidden = NO;
    self.pendingSelectedTask = self.selectedTask;
    [self.selectorPanel removeFromSuperview];
    [self setupSelectorPanel];
    [self.selectorTableView reloadData];
}

#pragma mark - Modal

- (void)showSuccessPanelWithPoints:(NSInteger)points {
    self.maskView.hidden = NO;
    [self.successPanel removeFromSuperview];
    
    self.successPanel = [[UIView alloc] init];
    self.successPanel.translatesAutoresizingMaskIntoConstraints = NO;
    self.successPanel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.successPanel];
    
    UIImageView *panelBgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"me_checkIn_alert_bg"]];
    panelBgImageView.translatesAutoresizingMaskIntoConstraints = NO;
    panelBgImageView.contentMode = UIViewContentModeScaleToFill;
    [self.successPanel addSubview:panelBgImageView];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = @"签到成功";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:21 weight:UIFontWeightSemibold];
    titleLabel.textColor = [UIColor colorWithRed:0.16 green:0.16 blue:0.16 alpha:1.0];
    [self.successPanel addSubview:titleLabel];
    
    UILabel *pointsLabel = [[UILabel alloc] init];
    pointsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    pointsLabel.text = [NSString stringWithFormat:@"+%ld", (long)points];
    pointsLabel.textAlignment = NSTextAlignmentCenter;
    pointsLabel.font = [UIFont systemFontOfSize:42 weight:UIFontWeightSemibold];
    pointsLabel.textColor = [UIColor colorWithRed:1.0 green:0.62 blue:0.08 alpha:1.0];
    [self.successPanel addSubview:pointsLabel];
    
    UILabel *hintLabel = [[UILabel alloc] init];
    hintLabel.translatesAutoresizingMaskIntoConstraints = NO;
    hintLabel.text = @"明天继续签到领取奖励";
    hintLabel.textAlignment = NSTextAlignmentCenter;
    hintLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    hintLabel.textColor = [UIColor colorWithWhite:0.66 alpha:1.0];
    [self.successPanel addSubview:hintLabel];
    
    UIButton *confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
    confirmButton.translatesAutoresizingMaskIntoConstraints = NO;
    confirmButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    [confirmButton setTitle:@"确认" forState:UIControlStateNormal];
    [confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    UIImage *buttonImage = [[UIImage imageNamed:@"me_checkIn_btn_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(20, 30, 20, 30) resizingMode:UIImageResizingModeStretch];
    [confirmButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [confirmButton addTarget:self action:@selector(dismissModalViews) forControlEvents:UIControlEventTouchUpInside];
    [self.successPanel addSubview:confirmButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.successPanel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.successPanel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:24],
        [self.successPanel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:45],
        [self.successPanel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-45],
        [self.successPanel.heightAnchor constraintEqualToConstant:370],
        
        [panelBgImageView.topAnchor constraintEqualToAnchor:self.successPanel.topAnchor],
        [panelBgImageView.leadingAnchor constraintEqualToAnchor:self.successPanel.leadingAnchor],
        [panelBgImageView.trailingAnchor constraintEqualToAnchor:self.successPanel.trailingAnchor],
        [panelBgImageView.bottomAnchor constraintEqualToAnchor:self.successPanel.bottomAnchor],
        
        [titleLabel.topAnchor constraintEqualToAnchor:self.successPanel.topAnchor constant:132],
        [titleLabel.leadingAnchor constraintEqualToAnchor:self.successPanel.leadingAnchor],
        [titleLabel.trailingAnchor constraintEqualToAnchor:self.successPanel.trailingAnchor],
        
        [pointsLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:18],
        [pointsLabel.leadingAnchor constraintEqualToAnchor:self.successPanel.leadingAnchor],
        [pointsLabel.trailingAnchor constraintEqualToAnchor:self.successPanel.trailingAnchor],
        
        [hintLabel.topAnchor constraintEqualToAnchor:pointsLabel.bottomAnchor constant:26],
        [hintLabel.leadingAnchor constraintEqualToAnchor:self.successPanel.leadingAnchor constant:20],
        [hintLabel.trailingAnchor constraintEqualToAnchor:self.successPanel.trailingAnchor constant:-20],
        
        [confirmButton.leadingAnchor constraintEqualToAnchor:self.successPanel.leadingAnchor constant:30],
        [confirmButton.trailingAnchor constraintEqualToAnchor:self.successPanel.trailingAnchor constant:-30],
        [confirmButton.bottomAnchor constraintEqualToAnchor:self.successPanel.bottomAnchor constant:-34],
        [confirmButton.heightAnchor constraintEqualToConstant:44]
    ]];
}

- (void)setupSelectorPanel {
    self.selectorPanel = [[UIView alloc] init];
    self.selectorPanel.translatesAutoresizingMaskIntoConstraints = NO;
    self.selectorPanel.backgroundColor = [UIColor whiteColor];
    self.selectorPanel.layer.cornerRadius = 18.0;
    self.selectorPanel.layer.masksToBounds = YES;
    [self.view addSubview:self.selectorPanel];
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    cancelButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor colorWithWhite:0.62 alpha:1.0] forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(dismissModalViews) forControlEvents:UIControlEventTouchUpInside];
    [self.selectorPanel addSubview:cancelButton];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = @"选择用户";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    [self.selectorPanel addSubview:titleLabel];
    
    UIButton *confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
    confirmButton.translatesAutoresizingMaskIntoConstraints = NO;
    confirmButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [confirmButton setTitle:@"确定" forState:UIControlStateNormal];
    [confirmButton setTitleColor:[UIColor colorWithRed:0.18 green:0.86 blue:0.24 alpha:1.0] forState:UIControlStateNormal];
    [confirmButton addTarget:self action:@selector(confirmUserSelection) forControlEvents:UIControlEventTouchUpInside];
    [self.selectorPanel addSubview:confirmButton];
    
    UIView *line = [[UIView alloc] init];
    line.translatesAutoresizingMaskIntoConstraints = NO;
    line.backgroundColor = [UIColor colorWithWhite:0.90 alpha:1.0];
    [self.selectorPanel addSubview:line];
    
    self.selectorTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.selectorTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.selectorTableView.backgroundColor = [UIColor whiteColor];
    self.selectorTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.selectorTableView.rowHeight = 88.0;
    self.selectorTableView.delegate = self;
    self.selectorTableView.dataSource = self;
    [self.selectorTableView registerClass:[WOPMKDIOFZTCheckInUserCell class] forCellReuseIdentifier:@"WOPMKDIOFZTCheckInUserCell"];
    [self.selectorPanel addSubview:self.selectorTableView];
    
    CGFloat panelHeight = MIN(420.0, 112.0 + self.tasks.count * 88.0);
    self.selectorPanelHeightConstraint = [self.selectorPanel.heightAnchor constraintEqualToConstant:panelHeight];
    self.selectorPanelHeightConstraint.active = YES;
    
    [NSLayoutConstraint activateConstraints:@[
        [self.selectorPanel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.selectorPanel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.selectorPanel.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        
        [cancelButton.leadingAnchor constraintEqualToAnchor:self.selectorPanel.leadingAnchor constant:18],
        [cancelButton.topAnchor constraintEqualToAnchor:self.selectorPanel.topAnchor constant:16],
        [cancelButton.widthAnchor constraintEqualToConstant:70],
        [cancelButton.heightAnchor constraintEqualToConstant:44],
        
        [titleLabel.centerXAnchor constraintEqualToAnchor:self.selectorPanel.centerXAnchor],
        [titleLabel.centerYAnchor constraintEqualToAnchor:cancelButton.centerYAnchor],
        
        [confirmButton.trailingAnchor constraintEqualToAnchor:self.selectorPanel.trailingAnchor constant:-18],
        [confirmButton.centerYAnchor constraintEqualToAnchor:cancelButton.centerYAnchor],
        [confirmButton.widthAnchor constraintEqualToConstant:70],
        [confirmButton.heightAnchor constraintEqualToConstant:44],
        
        [line.topAnchor constraintEqualToAnchor:self.selectorPanel.topAnchor constant:75.5],
        [line.leadingAnchor constraintEqualToAnchor:self.selectorPanel.leadingAnchor],
        [line.trailingAnchor constraintEqualToAnchor:self.selectorPanel.trailingAnchor],
        [line.heightAnchor constraintEqualToConstant:0.5],
        
        [self.selectorTableView.topAnchor constraintEqualToAnchor:line.bottomAnchor],
        [self.selectorTableView.leadingAnchor constraintEqualToAnchor:self.selectorPanel.leadingAnchor],
        [self.selectorTableView.trailingAnchor constraintEqualToAnchor:self.selectorPanel.trailingAnchor],
        [self.selectorTableView.bottomAnchor constraintEqualToAnchor:self.selectorPanel.bottomAnchor]
    ]];
}

- (void)dismissModalViews {
    self.maskView.hidden = YES;
    self.pendingSelectedTask = nil;
    [self.successPanel removeFromSuperview];
    self.successPanel = nil;
    [self.selectorPanel removeFromSuperview];
    self.selectorPanel = nil;
    self.selectorTableView = nil;
}

- (void)confirmUserSelection {
    if (self.pendingSelectedTask) {
        self.selectedTask = self.pendingSelectedTask;
        [self refreshContent];
    }
    [self dismissModalViews];
}

#pragma mark - Date

- (void)reloadWeekDates {
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:8 * 3600];
    calendar.firstWeekday = 2;
    NSDate *startOfWeek = nil;
    NSTimeInterval interval = 0;
    [calendar rangeOfUnit:NSCalendarUnitWeekOfYear startDate:&startOfWeek interval:&interval forDate:[NSDate date]];
    
    NSMutableArray *dates = [NSMutableArray arrayWithCapacity:7];
    for (NSInteger i = 0; i < 7; i++) {
        NSDate *date = [calendar dateByAddingUnit:NSCalendarUnitDay value:i toDate:startOfWeek options:0];
        if (date) {
            [dates addObject:date];
        }
    }
    self.weekDates = dates;
}

- (NSSet<NSString *> *)signedDateKeysForTask:(WFCCSignTask *)task {
    NSMutableSet *set = [NSMutableSet set];
    for (WFCCSignTaskSignRecord *record in task.signRecords) {
        NSString *key = [self dayKeyForTimestampString:record.dateTimestamp];
        if (key.length == 0) {
            continue;
        }
        BOOL hasPoints = [record.points integerValue] > 0;
        NSString *status = [record.status lowercaseString];
        BOOL signedStatus = status.length == 0 || [status containsString:@"sign"] || [status containsString:@"success"] || [status isEqualToString:@"1"] || [status isEqualToString:@"done"];
        if (hasPoints || signedStatus) {
            [set addObject:key];
        }
    }
    return set;
}

- (NSString *)dayKeyForTimestampString:(NSString *)timestampString {
    long long value = [timestampString longLongValue];
    if (value <= 0) {
        return @"";
    }
    if (value > 1000000000000LL) {
        value = value / 1000;
    }
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:value];
    return [self dayKeyForDate:date];
}

- (NSString *)dayKeyForDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:8 * 3600];
    formatter.dateFormat = @"yyyyMMdd";
    return [formatter stringFromDate:date];
}

- (NSAttributedString *)continuousText:(NSInteger)days {
    NSString *text = [NSString stringWithFormat:@"已连续签到 %ld 天", (long)days];
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:19 weight:UIFontWeightRegular], NSForegroundColorAttributeName : [UIColor colorWithRed:0.16 green:0.16 blue:0.16 alpha:1.0]}];
    NSString *dayString = [NSString stringWithFormat:@"%ld", (long)days];
    NSRange range = [text rangeOfString:dayString];
    if (range.location != NSNotFound) {
        [attr addAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:0.18 green:0.86 blue:0.24 alpha:1.0]} range:range];
    }
    return attr;
}

#pragma mark - HUD

- (MBProgressHUD *)showLoadingHUD {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"Loading");
    [hud showAnimated:YES];
    return hud;
}

- (void)showTextHUD:(NSString *)message {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = message ?: @"";
    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
    [hud hideAnimated:YES afterDelay:1.0];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tasks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WOPMKDIOFZTCheckInUserCell *cell = [tableView dequeueReusableCellWithIdentifier:@"WOPMKDIOFZTCheckInUserCell" forIndexPath:indexPath];
    WFCCSignTask *task = self.tasks[indexPath.row];
    WFCCSignTask *selectedTask = self.pendingSelectedTask ?: self.selectedTask;
    [cell configWithTask:task selected:(task == selectedTask)];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.tasks.count) {
        return;
    }
    self.pendingSelectedTask = self.tasks[indexPath.row];
    [self.selectorTableView reloadData];
}

@end
