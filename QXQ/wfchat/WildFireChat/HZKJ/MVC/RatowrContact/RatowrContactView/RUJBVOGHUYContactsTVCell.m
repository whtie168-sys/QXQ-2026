//
//  RUJBVOGHUYContactsTVCell.m
//  WUHOIBDK
//
//  Created by Ruby on 12/4/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "RUJBVOGHUYContactsTVCell.h"
#import "UIImageView+Avatar.h"

@interface RUJBVOGHUYContactsTVCell ()

@property (weak, nonatomic) IBOutlet UIImageView *trewqPortraitView;
@property (weak, nonatomic) IBOutlet UILabel *tzboeuNameLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nameTop;
@property (weak, nonatomic) IBOutlet UILabel *onlineLabel;
@property (weak, nonatomic) IBOutlet UIView *tzboeuOnlineView;

@property (nonatomic, assign) BOOL isEnableOnline;

@property (nonatomic, strong) WFCCUserInfo *userInfo;
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *groupId;

@property (weak, nonatomic) IBOutlet UILabel *groupOwenLabel;
@property (nonatomic, strong) UIImageView *badgeImageView;


// 新增头像缓存和复用控制属性
@property (nonatomic, copy) NSString *cachedAvatarURL;
@property (nonatomic, copy) NSString *cachedUserId;
@property (nonatomic, copy) NSString *cachedNameText;
@property (nonatomic, copy) NSString *cachedOnlineText;
@property (nonatomic, assign) BOOL cachedOnlineHidden;
@property (nonatomic, assign) CGFloat cachedNameTop;
@property (nonatomic, assign) BOOL isChinese;

@end

static char kAvatarIdentifierKey;

@implementation RUJBVOGHUYContactsTVCell

- (void)awakeFromNib {
    [super awakeFromNib];
    _trewqPortraitView.layer.cornerRadius = 25.0;
    _trewqPortraitView.layer.masksToBounds = YES;
    _tzboeuOnlineView.layer.cornerRadius = 5.0;
    _tzboeuOnlineView.layer.masksToBounds = YES;
    _tzboeuOnlineView.layer.borderColor = UIColor.whiteColor.CGColor;
    _tzboeuOnlineView.layer.borderWidth = 2.0;
    _tzboeuOnlineView.hidden = YES;
    _cachedOnlineHidden = YES;
    _cachedNameTop = _nameTop.constant;

    // 初始化语言设置
    _isChinese = [CommonHelper.main isChinese];
    
    self.badgeImageView = [[UIImageView alloc] init];
    self.badgeImageView.hidden = YES;
    [self.contentView addSubview:self.badgeImageView];
}


//显示管理员
- (void)showGroupManager {
    _groupOwenLabel.hidden = NO;
    _groupOwenLabel.text = LLLLLL(@"Manager");
    _groupOwenLabel.clipsToBounds = YES;
    _groupOwenLabel.layer.cornerRadius = 5;
    _groupOwenLabel.font = [UIFont systemFontOfSize:12];
    _groupOwenLabel.backgroundColor = [UIColor colorWithHexString:@"#4DA5FF"];
    [self updateBadgeImageNamed:@"管理员"];
}

//显示群主
- (void)showGroupOwn {
    _groupOwenLabel.hidden = NO;
    _groupOwenLabel.text = LLLLLL(@"Owner");
    _groupOwenLabel.clipsToBounds = YES;
    _groupOwenLabel.layer.cornerRadius = 5;
    _groupOwenLabel.font = [UIFont systemFontOfSize:12];
    _groupOwenLabel.backgroundColor = [UIColor colorWithHexString:@"#F8C21F"];
    [self updateBadgeImageNamed:@"群主"];
}

//普通成员
- (void)showMember {
    _groupOwenLabel.hidden = YES;
    [self updateBadgeImageNamed:nil];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat badgeWidth = 15;
    CGFloat badgeHeight = 15;
    self.badgeImageView.frame = CGRectMake(CGRectGetMaxX(self.trewqPortraitView.frame) - badgeWidth + 2.0,
                                           CGRectGetMaxY(self.trewqPortraitView.frame) - badgeHeight + 2.0,
                                           badgeWidth,
                                           badgeHeight);
}

- (void)updateBadgeImageNamed:(NSString *)imageName {
    self.badgeImageView.image = imageName.length ? [UIImage imageNamed:imageName] : nil;
    self.badgeImageView.hidden = (imageName.length == 0);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)onUserInfoUpdated:(NSNotification *)notification {
    NSArray<WFCCUserInfo *> *userInfoList = notification.userInfo[@"userInfoList"];
    
    // 优化：检查当前cell是否仍然显示相同的用户
    NSString *currentUserId = [self.trewqPortraitView avatarIdentifier];
    if (!currentUserId) return;
    
    for (WFCCUserInfo *userInfo in userInfoList) {
        if ([currentUserId isEqualToString:userInfo.userId]) {
            [self updateUserInfo:userInfo];
            break;
        }
    }
}

- (void)setUserId:(NSString *)userId groupId:(NSString *)groupId {
    _userId = userId;
    _groupId = groupId;
    
    // 优化：统一管理通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOnlineStateIfNeeded) name:kUserOnlineStateUpdated object:nil];
    
    WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:userId inGroup:groupId];
    if(userInfo.userId.length == 0) {
        userInfo = [[WFCCUserInfo alloc] init];
        userInfo.userId = userId;
    }
    [self updateUserInfo:userInfo];
}

- (void)updateOnlineState {
    [self updateUserInfo:_userInfo];
}

- (void)updateUserInfo:(WFCCUserInfo *)userInfo {
    if(!userInfo) {
        return;
    }
    
    _userInfo = userInfo;
    
    // 优化2：移除旧的通知监听，添加新的
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kUserInfoUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    
    // 优化3：处理特殊用户（客服、机器人等）- 这些需要立即设置，不参与缓存检查
    if ([self handleSpecialUsers:userInfo]) {
        [self updateOnlineStateIfNeeded];
        return;
    }
    
    // 优化4：普通用户的头像缓存检查
    if ([_cachedAvatarURL isEqualToString:userInfo.portrait] &&
        [_cachedUserId isEqualToString:userInfo.userId]) {
        // 头像信息未变化，跳过加载
        NSLog(@"🔄 头像缓存命中，跳过加载: %@", userInfo.userId);
    } else {
        _cachedAvatarURL = userInfo.portrait;
        _cachedUserId = userInfo.userId;
        
        if (userInfo.portrait && userInfo.portrait.length > 0) {
            [self.trewqPortraitView sd_setAvatarWithURLString:userInfo.portrait
                                                 placeholder:[AIOIUEHImage imageNamed:@"PersonalChat"]
                                                      userId:userInfo.userId
                                                cornerRadius:0];
        } else {
            [self.trewqPortraitView setAvatarIdentifier:userInfo.userId ?: @""];
            self.trewqPortraitView.image = [AIOIUEHImage imageNamed:@"PersonalChat"];
        }
    }
    
    // 优化5：设置用户名
    [self setupUserName:userInfo];
    [self updateOnlineStateIfNeeded];
}

// 新增方法：处理特殊用户
- (BOOL)handleSpecialUsers:(WFCCUserInfo *)userInfo {
    NSString *userId = userInfo.userId;
    
    [self.trewqPortraitView setAvatarIdentifier:userId ?: @""];
    
    if ([userId isEqualToString:@"customer_service"]) {
        self.trewqPortraitView.image = IMAGENAME(@"customerService");
        self.tzboeuNameLabel.text = LLLLLL(@"AppCustomerService");
        return YES;
    } else if ([userId isEqualToString:@"group_message"]) {
        self.trewqPortraitView.image = [AIOIUEHImage imageNamed:@"GroupNotiIcon"];
        self.tzboeuNameLabel.text = LLLLLL(@"GroupNotifications");
        return YES;
    } else if ([userId isEqualToString:@"FireRobot"]) {
        if (userInfo.portrait.length <= 0) {
            self.trewqPortraitView.image = IMAGENAME(@"QXQ IM");
        }
        self.tzboeuNameLabel.text = @"QXQ IM";
        return YES;
    } else if ([userId isEqualToString:@"wfc_file_transfer"]) {
        self.tzboeuNameLabel.text = _isChinese ? @"文件传输助手" : @"Transmission Assistant";
        // 文件传输助手可能也需要特殊头像处理
        if (!userInfo.portrait || userInfo.portrait.length == 0) {
            self.trewqPortraitView.image = [AIOIUEHImage imageNamed:@"PersonalChat"];
        }
        return YES;
    }
    
    return NO;
}

// 新增方法：设置用户名
- (void)setupUserName:(WFCCUserInfo *)userInfo {
    NSString *nameText = nil;
    if (_groupId.length > 0) {
        // 群聊场景
        if (userInfo.alias.length) {
            nameText = userInfo.alias;
        } else if (userInfo.groupAlias.length) {
            nameText = userInfo.groupAlias;
        } else if(userInfo.displayName.length > 0) {
            nameText = userInfo.displayName;
        } else if (userInfo.finalName.length) {
            nameText = userInfo.finalName;
        } else {
            nameText = [NSString stringWithFormat:@"user<%@>", userInfo.userId];
        }
    } else {
        // 非群聊场景
        if (userInfo.alias.length) {
            nameText = userInfo.alias;
        } else if (userInfo.groupAlias.length) {
            nameText = userInfo.groupAlias;
        } else if(userInfo.displayName.length > 0) {
            nameText = userInfo.displayName;
        } else if (userInfo.finalName.length > 0) {
            nameText = userInfo.finalName;
        } else {
            nameText = [NSString stringWithFormat:@"user<%@>", userInfo.userId];
        }
    }

    if ([self.cachedNameText isEqualToString:nameText]) {
        return;
    }
    self.cachedNameText = nameText;
    self.tzboeuNameLabel.text = nameText;
}

// 优化 updateOnlineStateIfNeeded 方法
- (void)updateOnlineStateIfNeeded {
    if (![WFCCIMService.sharedWFCIMService isEnableUserOnlineState]) {
        self.isEnableOnline = NO;
        [self updateOnlineLabelText:nil showDot:NO];
        return;
    }

    UserExtraInfo *extraInfo = [UserExtraInfo mj_objectWithKeyValues:self->_userInfo.extra];
    if ([self.cachedUserId isEqualToString:self->_userInfo.userId]) {
        [self updateOnlineViewWithExtraInfo:extraInfo];
    }
}

- (void)updateOnlineLabelText:(NSString *)text showDot:(BOOL)showDot {
    BOOL hidden = !self.isEnableOnline || !showDot;
    BOOL labelHidden = !self.isEnableOnline || text.length == 0;
    [UIView performWithoutAnimation:^{
        if (self.cachedOnlineHidden != hidden) {
            self.cachedOnlineHidden = hidden;
            self.tzboeuOnlineView.hidden = hidden;
        }

        if (self.onlineLabel.hidden != labelHidden) {
            self.onlineLabel.hidden = labelHidden;
        }

        if ((text == nil && self.cachedOnlineText != nil) ||
            (text != nil && ![self.cachedOnlineText isEqualToString:text])) {
            self.cachedOnlineText = text;
            self.onlineLabel.text = text;
        }
    }];
}

- (void)updateOnlineViewWithExtraInfo:(UserExtraInfo *)extraInfo {
    if (extraInfo != nil) {
        // 0 所有人    1 仅通讯录联系人    2 不显示在线时间
        if (extraInfo.disableShowLastLoginTime == 0) {
            self.isEnableOnline = YES;
            [self onlineState];
        } else if (extraInfo.disableShowLastLoginTime == 1) {
            if ([[WFCCIMService sharedWFCIMService] isMyFriend:_userInfo.userId]) {
                self.isEnableOnline = YES;
                [self onlineState];
            } else {
                self.isEnableOnline = NO;
                [self updateOnlineLabelText:nil showDot:NO];
            }
        } else {
            self.isEnableOnline = NO;
            [self updateOnlineLabelText:nil showDot:NO];
        }
    } else {
        self.isEnableOnline = NO;
        [self updateOnlineLabelText:nil showDot:NO];
    }
}

// 优化 onlineState 方法
- (void)onlineState {
    // 检查复用
    if (![[self.trewqPortraitView avatarIdentifier] isEqualToString:_userInfo.userId]) {
        return;
    }
    WFCCUserOnlineStateModel *state = [[WFCCIMService sharedWFCIMService] getUserOnlineState1:_userInfo.userId];
    NSString *platformStr = [CommonHelper.main customerPlatform:state.platform];
    if (state) {
        if ([state.online isEqualToString:@"1"]) {
            [self updateOnlineLabelText:LLLLLL(@"Online") showDot:YES];
        } else {
            NSString *strSeenTime = [CommonHelper.main contactOnlineStatusDesc:[state.updateTimeStamp longLongValue]];
            NSString *text = nil;
            if (strSeenTime.length) {
                text = [NSString stringWithFormat:@"%@ %@",strSeenTime, LLLLLL(@"Online")];
                if (platformStr) {
                    text = [NSString stringWithFormat:@"%@ %@(%@)",strSeenTime, LLLLLL(@"Online"),platformStr];
                }
            } else {
                text = LLLLLL(@"JustOffTheLine");
            }
            [self updateOnlineLabelText:text showDot:NO];
        }
    } else {
        self.isEnableOnline = NO;
        [self updateOnlineLabelText:nil showDot:NO];
    }
}

- (void)setIsEnableOnline:(BOOL)isEnableOnline {
    if (_isEnableOnline == isEnableOnline) {
        return;
    }
    _isEnableOnline = isEnableOnline;

    [UIView performWithoutAnimation:^{
        CGFloat targetTop = _isEnableOnline ? 3.0 : (50.0-21.0)/2.0;
        if (fabs(_nameTop.constant - targetTop) > 0.1) {
            _nameTop.constant = targetTop;
        }

        if (!_isEnableOnline && _tzboeuOnlineView.hidden != YES) {
            _tzboeuOnlineView.hidden = YES;
            _cachedOnlineHidden = YES;
        }
        [self.contentView layoutIfNeeded];
    }];
}

- (void)prepareForReuse {
    [super prepareForReuse];

    // 保留已显示内容，避免复用时文字闪烁
    self.groupOwenLabel.hidden = YES;
    [self updateBadgeImageNamed:nil];

    // 复用时不清空文本，新的 setUserId 会同步刷新
    _userInfo = nil;

    // 移除通知监听
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kUserInfoUpdated object:nil];

    // 取消图片加载
    [self.trewqPortraitView sd_cancelCurrentImageLoad];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // 清理关联对象
    id observer = objc_getAssociatedObject(self, &kAvatarIdentifierKey);
    if (observer) {
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    }
}

@end
