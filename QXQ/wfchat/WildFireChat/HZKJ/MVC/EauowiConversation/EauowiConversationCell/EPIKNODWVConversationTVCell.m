//
//  EPIKNODWVConversationTVCell.m
//  WUHOIBDK
//
//  Created by Ruby on 1/31/24.
//

#import "EPIKNODWVConversationTVCell.h"
#import "UIImageView+Avatar.h"

@interface EPIKNODWVConversationTVCell ()
{
    BOOL _isManager;
    
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIView *contentBgView;

@property (weak, nonatomic) IBOutlet UIImageView *wsedcPotraitView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *wsedcPotraitViewWidth;
@property (weak, nonatomic) IBOutlet UILabel *wsedcTargetLabel;
@property (weak, nonatomic) IBOutlet UIImageView *wsedcStatusView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *wsedcStatusViewWidth;
@property (weak, nonatomic) IBOutlet UILabel *wsedcDigestLabel;

@property (weak, nonatomic) IBOutlet UILabel *wsedcTimeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *wsedcSilentImgView;

@property (weak, nonatomic) IBOutlet UIView *tzboeuOnlineView;


@property (nonatomic, strong) JUAHODJNKBubbleTipView *tzboeuBubbleView;
@property (nonatomic, strong) WFCCConversationSearchInfo *searchInfo;

@property (strong, nonatomic) WFCCUserInfo *userInfo; // 0129新增


@property (nonatomic, copy) NSString *cachedAvatarURL;
@property (nonatomic, copy) NSString *cachedUserId;
@property (nonatomic, strong) WFCCConversationInfo *lastInfo;

@end

@implementation EPIKNODWVConversationTVCell

+ (NSRegularExpression *)inlineEmojiRegex {
    static NSRegularExpression *regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"\\[\\[wfemoji:([^\\]]+)\\]\\]"
                                                         options:0
                                                           error:nil];
    });
    return regex;
}

- (NSString *)stickerBundlePath {
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Stickers" ofType:@"bundle"];
    if (bundlePath.length) {
        return bundlePath;
    }

    for (NSBundle *bundle in [NSBundle allBundles]) {
        bundlePath = [bundle pathForResource:@"Stickers" ofType:@"bundle"];
        if (bundlePath.length) {
            return bundlePath;
        }
    }

    for (NSBundle *bundle in [NSBundle allFrameworks]) {
        bundlePath = [bundle pathForResource:@"Stickers" ofType:@"bundle"];
        if (bundlePath.length) {
            return bundlePath;
        }
    }

    return nil;
}

- (NSAttributedString *)attachmentStringForInlineEmojiToken:(NSString *)token attributes:(NSDictionary<NSAttributedStringKey, id> *)attributes {
    NSTextCheckingResult *match = [[[self class] inlineEmojiRegex] firstMatchInString:token options:0 range:NSMakeRange(0, token.length)];
    UIFont *font = attributes[NSFontAttributeName] ?: self.wsedcDigestLabel.font ?: [UIFont systemFontOfSize:14];
    if (!match || match.numberOfRanges < 2) {
        return [[NSAttributedString alloc] initWithString:token attributes:attributes];
    }

    NSString *relativePath = [token substringWithRange:[match rangeAtIndex:1]];
    NSString *bundlePath = [self stickerBundlePath];
    UIImage *image = nil;
    if (bundlePath.length) {
        image = [UIImage imageWithContentsOfFile:[bundlePath stringByAppendingPathComponent:relativePath]];
    }

    if (!image) {
        return [[NSAttributedString alloc] initWithString:token attributes:attributes];
    }

    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.image = image;
    CGFloat targetHeight = MAX(font.lineHeight + 2.0, 16.0);
    CGFloat ratio = image.size.height > 0 ? image.size.width / image.size.height : 1.0;
    CGFloat targetWidth = MIN(MAX(targetHeight * ratio, targetHeight * 0.8), targetHeight * 1.4);
    attachment.bounds = CGRectMake(0, font.descender - 1.0, targetWidth, targetHeight);

    NSMutableAttributedString *attachmentString = [[NSMutableAttributedString alloc] initWithAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
    [attachmentString addAttributes:attributes range:NSMakeRange(0, attachmentString.length)];
    return attachmentString;
}

- (NSMutableAttributedString *)attributedDigestStringForString:(NSString *)string {
    NSDictionary *attributes = @{
        NSFontAttributeName : self.wsedcDigestLabel.font ?: [UIFont systemFontOfSize:14],
        NSForegroundColorAttributeName : self.wsedcDigestLabel.textColor ?: [UIColor blackColor]
    };
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[self sanitizedDigestString:string] attributes:attributes];
    return [self attributedDigestStringFromAttributedString:attributedString];
}

- (NSMutableAttributedString *)attributedDigestStringFromAttributedString:(NSAttributedString *)attributedString {
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:attributedString ?: [[NSAttributedString alloc] initWithString:@""]];
    NSString *sanitizedString = [self sanitizedDigestString:mutableAttributedString.string];
    if (![sanitizedString isEqualToString:mutableAttributedString.string]) {
        NSDictionary *baseAttributes = (mutableAttributedString.length > 0 ? [mutableAttributedString attributesAtIndex:0 effectiveRange:nil] : nil) ?: @{
            NSFontAttributeName : self.wsedcDigestLabel.font ?: [UIFont systemFontOfSize:14],
            NSForegroundColorAttributeName : self.wsedcDigestLabel.textColor ?: [UIColor blackColor]
        };
        mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:sanitizedString attributes:baseAttributes];
    }
    NSArray<NSTextCheckingResult *> *matches = [[[self class] inlineEmojiRegex] matchesInString:mutableAttributedString.string options:0 range:NSMakeRange(0, mutableAttributedString.string.length)];
    for (NSTextCheckingResult *match in matches.reverseObjectEnumerator) {
        NSDictionary *attributes = [mutableAttributedString attributesAtIndex:match.range.location effectiveRange:nil];
        NSString *token = [mutableAttributedString.string substringWithRange:match.range];
        NSAttributedString *attachmentString = [self attachmentStringForInlineEmojiToken:token attributes:attributes];
        [mutableAttributedString replaceCharactersInRange:match.range withAttributedString:attachmentString];
    }
    return mutableAttributedString;
}

- (NSString *)sanitizedDigestString:(NSString *)string {
    NSString *digestString = [self resolvedMentionDigestString:(string ?: @"")];
    if (![self.wsedcTargetLabel.text isEqualToString:LLLLLL(@"GroupNotifications")]) {
        return digestString;
    }

    digestString = [digestString stringByReplacingOccurrencesOfString:@"（null）" withString:@""];
    digestString = [digestString stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
    digestString = [digestString stringByReplacingOccurrencesOfString:@"null邀请您加入群聊" withString:@"邀请您加入群聊"];
    return [digestString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)mentionDisplayNameForTarget:(NSString *)target
                              preferAlias:(BOOL)preferAlias
                                   groupId:(NSString *)groupId {
    WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:target inGroup:groupId];
    if (preferAlias) {
        if (userInfo.alias.length > 0) {
            return userInfo.alias;
        }
        if (userInfo.groupAlias.length > 0) {
            return userInfo.groupAlias;
        }
    } else {
        if (userInfo.groupAlias.length > 0) {
            return userInfo.groupAlias;
        }
        if (userInfo.displayName.length > 0) {
            return userInfo.displayName;
        }
    }
    if (userInfo.displayName.length > 0) {
        return userInfo.displayName;
    }
    if (userInfo.alias.length > 0) {
        return userInfo.alias;
    }
    return userInfo.userId.length > 0 ? userInfo.userId : target;
}

- (NSString *)resolvedMentionDigestString:(NSString *)digestString {
    if (self.info.conversation.type != Group_Type || digestString.length == 0) {
        return digestString;
    }

    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"@\\{([^\\}]+)\\}" options:0 error:&error];
    if (error) {
        return digestString;
    }

    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:digestString options:0 range:NSMakeRange(0, digestString.length)];
    if (matches.count == 0) {
        return digestString;
    }

    BOOL preferAlias = self.info.lastMessage.direction == MessageDirection_Send;
    NSString *groupId = self.info.conversation.target;
    NSMutableString *mutableString = [digestString mutableCopy];
    NSInteger delta = 0;
    for (NSTextCheckingResult *match in matches) {
        if (match.numberOfRanges < 2) {
            continue;
        }
        NSRange targetRange = [match rangeAtIndex:1];
        if (targetRange.location == NSNotFound || NSMaxRange(targetRange) > digestString.length) {
            continue;
        }
        NSString *target = [digestString substringWithRange:targetRange];
        NSString *name = [self mentionDisplayNameForTarget:target preferAlias:preferAlias groupId:groupId];
        NSString *replacement = [NSString stringWithFormat:@"@%@", name];

        NSInteger location = (NSInteger)match.range.location + delta;
        if (location < 0 || location > mutableString.length) {
            continue;
        }
        NSInteger maxLength = (NSInteger)mutableString.length - location;
        NSInteger safeLength = MIN((NSInteger)match.range.length, maxLength);
        if (safeLength < 0) {
            safeLength = 0;
        }
        NSRange safeRange = NSMakeRange((NSUInteger)location, (NSUInteger)safeLength);
        [mutableString replaceCharactersInRange:safeRange withString:replacement];
        delta += (NSInteger)replacement.length - safeLength;
    }
    return mutableString;
}

- (void)applyDigestText:(NSString *)text {
    self.wsedcDigestLabel.attributedText = [self attributedDigestStringForString:text];
}

- (void)applyDigestAttributedText:(NSAttributedString *)attributedText {
    self.wsedcDigestLabel.attributedText = [self attributedDigestStringFromAttributedString:attributedText];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    _stateButton.hidden = YES;
    _iconLeft.constant = 0.0;
    
    _wsedcPotraitView.layer.cornerRadius = 24.0;
    
    _tzboeuOnlineView.hidden = YES;
    _tzboeuOnlineView.layer.cornerRadius = 5.0;
    _tzboeuOnlineView.layer.masksToBounds = YES;
    _tzboeuOnlineView.layer.borderColor = UIColor.whiteColor.CGColor;
    _tzboeuOnlineView.layer.borderWidth = 2.0;
    
    _wsedcSilentImgView.image = [AIOIUEHImage imageNamed:@"conversation_mute"];
    
    _isManager = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOnlineState) name:kUserOnlineStateUpdated object:nil];
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!self.isBig) {
        _wsedcPotraitViewWidth.constant = 40.0;
        _wsedcPotraitView.layer.cornerRadius = 20.0;
    }
}

- (void)updateUserInfo:(WFCCUserInfo *)userInfo {
    // 在方法开始时设置头像标识，防止复用问题
    [self.wsedcPotraitView setAvatarIdentifier:userInfo.userId];
    
    _userInfo = userInfo;
    _isChinese = [CommonHelper.main isChinese];
    
    // 移除旧的通知监听，添加新的
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kUserInfoUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    
    // 处理特殊用户（客服、机器人等）- 这些需要立即设置，不参与缓存检查
    if ([self handleSpecialUsers:userInfo]) {
        [self updateOnlineState];
        return;
    }
    
    // 普通用户的头像缓存检查
    if ([_cachedAvatarURL isEqualToString:userInfo.portrait] &&
        [_cachedUserId isEqualToString:userInfo.userId]) {
        // 头像信息未变化，跳过加载
    } else {
        _cachedAvatarURL = userInfo.portrait;
        _cachedUserId = userInfo.userId;
        
        if (userInfo.portrait && userInfo.portrait.length > 0) {
            [self.wsedcPotraitView sd_setAvatarWithURLString:userInfo.portrait
                                                 placeholder:[AIOIUEHImage imageNamed:@"PersonalChat"]
                                                      userId:userInfo.userId
                                                cornerRadius:0];
        } else {
            // 重要：设置默认头像时也要检查复用
            if ([[self.wsedcPotraitView avatarIdentifier] isEqualToString:userInfo.userId]) {
                self.wsedcPotraitView.image = [AIOIUEHImage imageNamed:@"PersonalChat"];
            }
        }
    }
    
    [self setupUserName:userInfo];
    [self updateOnlineState];
}

// 新增方法：处理特殊用户
- (BOOL)handleSpecialUsers:(WFCCUserInfo *)userInfo {
    NSString *userId = userInfo.userId;
    
    // 检查当前cell是否仍然显示这个用户（防止复用）
    if (![[self.wsedcPotraitView avatarIdentifier] isEqualToString:userId]) {
        return NO;
    }
    
    if ([userId isEqualToString:@"customer_service"]) {
        self.wsedcPotraitView.image = IMAGENAME(@"customerService");
        self.wsedcTargetLabel.text = LLLLLL(@"AppCustomerService");
        return YES;
    } else if ([userId isEqualToString:@"group_message"]) {
        self.wsedcPotraitView.image = [AIOIUEHImage imageNamed:@"GroupNotiIcon"];
        self.wsedcTargetLabel.text = LLLLLL(@"GroupNotifications");
        return YES;
    } else if ([userId isEqualToString:@"FireRobot"]) {
        if (userInfo.portrait.length <= 0) {
            self.wsedcPotraitView.image = IMAGENAME(@"QXQ IM");
        }
        self.wsedcTargetLabel.text = @"QXQ IM";
        return YES;
    } else if ([userId isEqualToString:@"wfc_file_transfer"]) {
        self.wsedcTargetLabel.text = _isChinese ? @"文件传输助手" : @"Transmission Assistant";
        // 文件传输助手可能也需要特殊头像处理
        if (!userInfo.portrait || userInfo.portrait.length == 0) {
            self.wsedcPotraitView.image = [AIOIUEHImage imageNamed:@"PersonalChat"];
        }
        return YES;
    }
    
    return NO;
}

// 新增方法：设置用户名
- (void)setupUserName:(WFCCUserInfo *)userInfo {
    // 检查复用
    if (![[self.wsedcPotraitView avatarIdentifier] isEqualToString:userInfo.userId]) {
        return;
    }
    
    if (userInfo.finalName.length > 0) {
        self.wsedcTargetLabel.text = userInfo.finalName;
    } else if (userInfo.alias.length) {
        self.wsedcTargetLabel.text = userInfo.alias;
    } else if(userInfo.displayName.length > 0) {
        self.wsedcTargetLabel.text = userInfo.displayName;
    } else {
        self.wsedcTargetLabel.text = [NSString stringWithFormat:@"user<%@>", self.info.conversation.target];
    }
}


// 优化 updateOnlineState 方法
- (void)updateOnlineState {
    if (![WFCCIMService.sharedWFCIMService isEnableUserOnlineState]) {
        self.tzboeuOnlineView.hidden = YES;
        return;
    }
    
    // 优化：避免频繁的异步操作
    static dispatch_queue_t onlineStateQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        onlineStateQueue = dispatch_queue_create("com.app.onlinestate", DISPATCH_QUEUE_SERIAL);
    });
    
    // 使用串行队列避免并发过多
    dispatch_async(onlineStateQueue, ^{
        UserExtraInfo *extraInfo = [UserExtraInfo mj_objectWithKeyValues:self->_userInfo.extra];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // 检查cell是否仍然显示相同的数据
            if ([self.cachedUserId isEqualToString:self->_userInfo.userId]) {
                [self updateOnlineViewWithExtraInfo:extraInfo];
            }
        });
    });
}


- (void)updateOnlineViewWithExtraInfo:(UserExtraInfo *)extraInfo {
    if (extraInfo != nil) {
        // 0 所有人    1 仅通讯录联系人    2 不显示在线时间
        if (extraInfo.disableShowLastLoginTime == 0) {
            [self onlineState];
        }else if (extraInfo.disableShowLastLoginTime == 1) {
            if ([CommonHelper.main isAddressBookContact:_userInfo.mobile]) {
                [self onlineState];
            }else {
                self.tzboeuOnlineView.hidden = YES;
            }
        }else {
            self.tzboeuOnlineView.hidden = YES;
        }
    }else {
        self.tzboeuOnlineView.hidden = YES;
    }
}


- (void)onlineState {
    WFCCUserOnlineStateModel *state = [[WFCCIMService sharedWFCIMService] getUserOnlineState1:self.info.conversation.target];
    self.tzboeuOnlineView.hidden = ![state.online isEqualToString:@"1"];

    
//    BOOL online = NO;
//    if (state.clientStates.count) { //有设备在线
//        if(state.customState.state != 4) { //没有设置为隐身
//            for (WFCCClientState *cs in state.clientStates) {
//                if(cs.state == 0) { // 设备的在线状态，0是在线，1是有session但不在线，其它不在线。
//                    online = YES;
//                    break;
//                }
//            }
//        }
//    }
//    self.tzboeuOnlineView.hidden = !online;
}

- (void)updateGroupInfo:(WFCCGroupInfo *)groupInfo {
    // 优化1：在方法开始时记录当前群ID，防止复用问题
    NSString *currentGroupId = groupInfo.target;
    [self.wsedcPotraitView setAvatarIdentifier:currentGroupId];
    
    // 优化2：统一管理通知
    [self setupGroupNotificationsForGroupId:currentGroupId];
    
    if (groupInfo.type == GroupType_Organization) {
        if (groupInfo.portrait.length) {
            [self.wsedcPotraitView sd_setAvatarWithURLString:groupInfo.portrait
                                                placeholder:[AIOIUEHImage imageNamed:@"organization_icon"]
                                                     userId:currentGroupId
                                               cornerRadius:0];
        } else {
            // 优化3：使用占位图，但确保复用正确
            if ([[self.wsedcPotraitView avatarIdentifier] isEqualToString:currentGroupId]) {
                self.wsedcPotraitView.image = [AIOIUEHImage imageNamed:@"organization_icon"];
            }
        }
    } else {
        if (groupInfo.portrait.length) {
            [self.wsedcPotraitView sd_setAvatarWithURLString:groupInfo.portrait
                                                placeholder:[AIOIUEHImage imageNamed:@"groupIcon"]
                                                    userId:currentGroupId
                                               cornerRadius:0];
        } else {
            // 优化4：重构群头像生成逻辑，避免重复监听
            [self setupDefaultGroupAvatarForGroupId:currentGroupId groupInfo:groupInfo];
        }
    }
    
    // 设置群名称
    [self setupGroupDisplayName:groupInfo];
}

// 新增方法：统一管理群通知
- (void)setupGroupNotificationsForGroupId:(NSString *)groupId {
    // 移除所有群相关通知
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kGroupInfoUpdated object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"GroupPortraitChanged" object:nil];
    
    // 添加群信息更新通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(onGroupInfoUpdated:)
                                                name:kGroupInfoUpdated
                                              object:nil];
}

// 新增方法：处理默认群头像
- (void)setupDefaultGroupAvatarForGroupId:(NSString *)groupId groupInfo:(WFCCGroupInfo *)groupInfo {
    __weak typeof(self) weakSelf = self;
    
    // 优化5：使用一次性通知监听，避免重复添加
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:@"GroupPortraitChanged"
                                                                    object:groupId
                                                                     queue:[NSOperationQueue mainQueue]
                                                                usingBlock:^(NSNotification * _Nonnull note) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        // 优化6：严格检查cell当前显示的群ID
        NSString *currentDisplayGroupId = [strongSelf.wsedcPotraitView avatarIdentifier];
        if (![currentDisplayGroupId isEqualToString:groupId]) {
            return; // cell已经复用于其他群，不处理
        }
        
        NSString *path = [note.userInfo objectForKey:@"path"];
        if (path) {
            [strongSelf.wsedcPotraitView sd_setImageWithURL:[NSURL fileURLWithPath:path]
                                           placeholderImage:[AIOIUEHImage imageNamed:@"groupIcon"]
                                                    options:SDWebImageScaleDownLargeImages
                                                    context:@{
                                                        SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever),
                                                        SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)
                                                    }];
        }
    }];
    
    // 存储observer以便后续移除
    objc_setAssociatedObject(self, &kGroupPortraitObserverKey, observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // 设置默认头像（带复用检查）
    if ([[self.wsedcPotraitView avatarIdentifier] isEqualToString:groupId]) {
        self.wsedcPotraitView.image = [AIOIUEHImage imageNamed:@"groupIcon"];
    }
}

// 新增方法：设置群显示名称
- (void)setupGroupDisplayName:(WFCCGroupInfo *)groupInfo {
    if (groupInfo.displayName.length > 0) {
        self.wsedcTargetLabel.text = groupInfo.displayName;
    } else {
        self.wsedcTargetLabel.text = _isChinese ? @"群聊" : @"Group chat";
    }
}

- (void)setInfo:(WFCCConversationInfo *)info {
    _info = info;
    if (![WFCCIMService.sharedWFCIMService isEnableSyncDraft]) {
        _info.draft = @"";
    }
    
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    _isManager = [self isGroupManager:userId];
    
    if (info.unreadCount.unread == 0) {
        self.tzboeuBubbleView.hidden = YES;
    } else {
        self.tzboeuBubbleView.hidden = NO;
        if (info.isSilent) {
            self.tzboeuBubbleView.isShowNotificationNumber = NO;
        } else {
            self.tzboeuBubbleView.isShowNotificationNumber = YES;
        }
        [self.tzboeuBubbleView setBubbleTipNumber:info.unreadCount.unread];
    }
    
    if (info.isSilent) {
        _wsedcSilentImgView.hidden = NO;
    }else {
        _wsedcSilentImgView.hidden = YES;
    }
  
    [self update:info.conversation];
    self.wsedcTimeLabel.hidden = NO;
    self.wsedcTimeLabel.text = [AIOIUEHUtilities formatTimeLabel:info.timestamp];
    
    BOOL darkMode = NO;
    if (@available(iOS 13.0, *)) {
        if(UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            darkMode = YES;
        }
    }
    if (darkMode) {
        if (info.isTop) {
            [self.contentView setBackgroundColor:[UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.f]];
        } else {
            self.contentView.backgroundColor = [AIOIUEHConfigManager globalManager].backgroudColor;
        }
    } else {
        if (info.isTop) {
            [self.contentView setBackgroundColor:[UIColor colorWithHexString:@"0xf7f7f7"]];
        } else {
            self.contentView.backgroundColor = [UIColor whiteColor];
        }
    }
    
    if (info.lastMessage && info.lastMessage.direction == MessageDirection_Send) {
        if (info.lastMessage.status == Message_Status_Sending) {
            self.wsedcStatusView.image = [AIOIUEHImage imageNamed:@"conversation_message_sending"];
            self.wsedcStatusView.hidden = NO;
            self.wsedcStatusViewWidth.constant = 17.0;
        } else if(info.lastMessage.status == Message_Status_Send_Failure) {
            self.wsedcStatusView.image = [AIOIUEHImage imageNamed:@"MessageSendError"];
            self.wsedcStatusView.hidden = NO;
            self.wsedcStatusViewWidth.constant = 17.0;
        } else {
            self.wsedcStatusView.hidden = YES;
            self.wsedcStatusViewWidth.constant = 0.0;
        }
    }else {
        self.wsedcStatusView.hidden = YES;
        self.wsedcStatusViewWidth.constant = 0.0;
    }
}


- (void)update:(WFCCConversation *)conversation {
    // 优化：只在必要时移除通知
    if (_lastInfo.conversation.type != conversation.type ||
        ![_lastInfo.conversation.target isEqualToString:conversation.target]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    _lastInfo = self.info; // 保存当前info

//    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _isChinese = [CommonHelper.main isChinese];
    
    WFCCGroupInfo *groupInfo;
    if(conversation.type == Single_Type) {
        WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:conversation.target];
        if(userInfo.userId.length == 0) {
            userInfo = [[WFCCUserInfo alloc] init];
            userInfo.userId = conversation.target;
        }
        [self updateUserInfo:userInfo];
    } else if (conversation.type == Group_Type) {
        groupInfo = [[WFCCGroupDB sharedManager] getGroupInfoFromDB:conversation.target];
        if(groupInfo.target.length == 0) {
            groupInfo = [[WFCCGroupInfo alloc] init];
            groupInfo.target = conversation.target;
        }
        [self updateGroupInfo:groupInfo];
        self.tzboeuOnlineView.hidden = YES;
    } else if(conversation.type == Channel_Type) {
        WFCCChannelInfo *channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:conversation.target refresh:NO];
        if (channelInfo.channelId.length == 0) {
            channelInfo = [[WFCCChannelInfo alloc] init];
            channelInfo.channelId = conversation.target;
        }
        [self updateChannelInfo:channelInfo];
        self.tzboeuOnlineView.hidden = YES;
    } else if(conversation.type == SecretChat_Type){
//        WFCCSecretChatInfo *secretInfo = [[WFCCIMService sharedWFCIMService] getSecretChatInfo:conversation.target];
        NSString *userId = [[WFCCIMService sharedWFCIMService] getSecretChatInfo:conversation.target].userId;
        WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:userId];
        [self updateUserInfo:userInfo];
    } else {
        self.wsedcTargetLabel.text = _isChinese ? @"聊天室" : @"Chat room";
        self.tzboeuOnlineView.hidden = YES;
    }
    
    self.wsedcDigestLabel.attributedText = nil;
    
    NSString *secretChatStateText = nil;
    if(conversation.type == SecretChat_Type) {
        WFCCSecretChatState secretChatState = [[WFCCIMService sharedWFCIMService] getSecretChatInfo:conversation.target].state;
        if (secretChatState == SecretChatState_Starting) {
            secretChatStateText = _isChinese ? @"密聊会话建立中，正在等待对方响应。" : @"The secret chat is being established and is waiting for a response from the peer.";
        } else if(secretChatState == SecretChatState_Canceled) {
            secretChatStateText = _isChinese ? @"密聊会话已取消！" : @"Secret Chat session has been cancelled!";
        }
    }
    
    if (secretChatStateText) {
        [self applyDigestText:secretChatStateText];
    }else if (_info.draft.length) { // 草稿
        NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:(_isChinese ? @"[草稿]" : @"[Draft]") attributes:@{NSForegroundColorAttributeName : [UIColor redColor]}];
        
        NSError *__error = nil;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:[_info.draft dataUsingEncoding:NSUTF8StringEncoding]
                                                                   options:kNilOptions
                                                                     error:&__error];
        
        NSString *text = _info.draft;
        if (!__error) {
            //兼容android/web端
            if([dictionary[@"content"] isKindOfClass:[NSString class]]) {
                text = dictionary[@"content"];
            } else if([dictionary[@"text"] isKindOfClass:[NSString class]]) {
                text = dictionary[@"text"];
            }
        }
        
        [attString appendAttributedString:[[NSAttributedString alloc] initWithString:text]];

        if (_info.conversation.type == Group_Type && _info.unreadCount.unreadMentionAll + _info.unreadCount.unreadMention > 0) {
            NSMutableAttributedString *tmp = [[NSMutableAttributedString alloc] initWithString:(_isChinese ? @"[有人@你]" : @"[Someone @ you]") attributes:@{NSForegroundColorAttributeName : [UIColor redColor]}];
            [tmp appendAttributedString:attString];
            attString = tmp;
        }
        [self applyDigestAttributedText:attString];
    } else if (_info.lastMessage.direction == MessageDirection_Receive && _info.conversation.type == Group_Type) { // 接收
        NSString *groupId = nil;
        if (_info.conversation.type == Group_Type) {
            groupId = _info.conversation.target;
        }
        WFCCUserInfo *sender = [[WFCCUserDB sharedManager] getUserInfo:_info.lastMessage.fromUser inGroup:groupId];
        if (sender.groupAlias.length && ![_info.lastMessage.content isKindOfClass:[WFCCNotificationMessageContent class]]) {
            [self applyDigestText:[NSString stringWithFormat:@"%@:%@", sender.groupAlias, _info.lastMessage.digest]];
        } else if (sender.alias.length && ![_info.lastMessage.content isKindOfClass:[WFCCNotificationMessageContent class]]) {
            [self applyDigestText:[NSString stringWithFormat:@"%@:%@", sender.alias, _info.lastMessage.digest]];
        } else if (sender.displayName.length && ![_info.lastMessage.content isKindOfClass:[WFCCNotificationMessageContent class]]) {
            [self applyDigestText:[NSString stringWithFormat:@"%@:%@", sender.displayName, _info.lastMessage.digest]];
        } else if (sender.finalName.length && ![_info.lastMessage.content isKindOfClass:[WFCCNotificationMessageContent class]]) {
            [self applyDigestText:[NSString stringWithFormat:@"%@:%@", sender.finalName, _info.lastMessage.digest]];
        } else {
//            self.wsedcDigestLabel.text = _info.lastMessage.digest;
            if ([self filteringData:_info.lastMessage.content]) { // YES 可以将最后一条消息显示出来  0229新增判断
                [self applyDigestText:_info.lastMessage.digest];
            }else {
                [self applyDigestText:@""];
            }
        }
        
        if (_info.unreadCount.unreadMentionAll + _info.unreadCount.unreadMention > 0) {
            NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:(_isChinese ? @"[有人@你]" : @"[Someone @ you]") attributes:@{NSForegroundColorAttributeName : [UIColor redColor]}];
            NSString *digestString = self.wsedcDigestLabel.attributedText.string ?: @"";
            if (digestString.length) {
                [attString appendAttributedString:[[NSAttributedString alloc] initWithString:digestString attributes:@{
                    NSFontAttributeName : self.wsedcDigestLabel.font ?: [UIFont systemFontOfSize:14],
                    NSForegroundColorAttributeName : self.wsedcDigestLabel.textColor ?: [UIColor blackColor]
                }]];
            }
            
            [self applyDigestAttributedText:attString];
        }
    } else { // WFCCGroupSetManagerNotificationContent      子类重写：- (NSString *)digest:(WFCCMessage *)message
//        if ([_info.lastMessage.content.class isEqual:NSClassFromString(@"WFCCGroupSetManagerNotificationContent")]) {
//            self.wsedcDigestLabel.text = @"";
//            return;
//        }
        if ([self filteringData:_info.lastMessage.content]) { // YES 可以将最后一条消息显示出来  0229新增判断
            if (_isChinese) {
                [self applyDigestText:_info.lastMessage.digest];
            }else {
                if ([_info.lastMessage.digest containsString:@"我是群通知"]) {
                    [self applyDigestText:@"Hello, this is group notification"];
                }else if ([_info.lastMessage.digest containsString:@"我是文件传输助手"]) {
                    [self applyDigestText:@"Hello, I'm a file transfer assistant"];
                }else if ([_info.lastMessage.digest containsString:@"我是官方客服"]) {
                    [self applyDigestText:@"Hello, I am the official customer service! You can talk to me."];
                }else {
                    [self applyDigestText:_info.lastMessage.digest];
                }
            }
        }else {
            [self applyDigestText:@""];
        }
    }
}

- (void)reloadCell {
    [self setInfo:self.info];
}


- (void)onUserInfoUpdated:(NSNotification *)notification {
    NSArray<WFCCUserInfo *> *userInfoList = notification.userInfo[@"userInfoList"];
    WFCCConversationInfo *conv = self.info;
    
    for (WFCCUserInfo *userInfo in userInfoList) {
        if (conv.conversation.type == Single_Type || conv.conversation.type == SecretChat_Type) {
            if([userInfo.userId isEqualToString:conv.conversation.target]) {
                [self reloadCell];
                break;
            }
        }
        if ([conv.lastMessage.fromUser isEqualToString:userInfo.userId]) {
            [self reloadCell];
            break;
        }
    }
}

- (void)onGroupInfoUpdated:(NSNotification *)notification {
    NSArray<WFCCGroupInfo *> *groupInfoList = notification.userInfo[@"groupInfoList"];
    WFCCConversationInfo *conv = self.info;
    if(conv.conversation.type == Group_Type) {
        for (WFCCGroupInfo *groupInfo in groupInfoList) {
            if ([conv.conversation.target isEqualToString:groupInfo.target]) {
                [self reloadCell];
                break;
            }
        }
    }
}

- (void)onChannelInfoUpdated:(NSNotification *)notification {
    NSArray<WFCCChannelInfo *> *channelInfoList = notification.userInfo[@"channelInfoList"];
    WFCCConversationInfo *conv = self.info;
    if(conv.conversation.type == Channel_Type) {
        for (WFCCChannelInfo *channelInfo in channelInfoList) {
            if ([conv.conversation.target isEqualToString:channelInfo.channelId]) {
                [self reloadCell];
                break;
            }
        }
    }
}



- (void)setSearchInfo:(WFCCConversationSearchInfo *)searchInfo {
    _searchInfo = searchInfo;
    self.tzboeuBubbleView.hidden = YES;
    self.wsedcTimeLabel.hidden = YES;
    [self update:searchInfo.conversation];
    if (searchInfo.marchedCount > 1) {
        [self applyDigestText:[NSString stringWithFormat:@"%d %@", searchInfo.marchedCount, (_isChinese?@"条记录":@"records")]];
    } else {
        NSString *strContent = searchInfo.marchedMessage.digest;
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:strContent];
        NSRange range = [strContent rangeOfString:searchInfo.keyword options:NSCaseInsensitiveSearch];
        [attrStr addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:range];
        [self applyDigestAttributedText:attrStr];
    }
}

- (void)updateChannelInfo:(WFCCChannelInfo *)channelInfo {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onChannelInfoUpdated:) name:kChannelInfoUpdated object:nil];
    
    [self.wsedcPotraitView sd_setAvatarWithURLString:channelInfo.portrait placeholder:[AIOIUEHImage imageNamed:@"channel_default_portrait"] userId:channelInfo.channelId cornerRadius:0];
    if (channelInfo.name.length > 0) {
        self.wsedcTargetLabel.text = channelInfo.name;
    }else {
        self.wsedcTargetLabel.text = _isChinese ? @"频道" : @"Channel";
    }
}


- (JUAHODJNKBubbleTipView *)tzboeuBubbleView {
    if (!_tzboeuBubbleView) {
        if (self.wsedcPotraitView) {
            _tzboeuBubbleView = [[JUAHODJNKBubbleTipView alloc] initWithSuperView:self.contentBgView];
            _tzboeuBubbleView.hidden = YES;
        }
    }
    return _tzboeuBubbleView;
}

#pragma mark - 公屏显示问题 0229新增


- (BOOL)filteringData:(WFCCMessageContent *)content { // 返回NO 不添加该条数据
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    if (_info.conversation.type != Group_Type) {
        return YES;
    }
    
//    NSLog(@"contentClass===%@",NSStringFromClass(content.class));
    
    if ([content isKindOfClass:NSClassFromString(@"WFCCGroupSetManagerNotificationContent")]) { // 设置/取消群管理员的通知消息
        // 仅群主和管理员可见
        if (_isManager) {
            return YES;
        }
        [self deleteMessage];
        return NO;
    }else if ([content isKindOfClass:NSClassFromString(@"WFCCGroupMuteNotificationContent")] || // 群禁言的通知消息 - 全禁言
              [content isKindOfClass:NSClassFromString(@"WFCCGroupPrivateChatNotificationContent")] || // 这几个都是建群的通知消息
              [content isKindOfClass:NSClassFromString(@"WFCCGroupJoinTypeNotificationContent")]) {
        return YES;
    }
    else if ([content isKindOfClass:NSClassFromString(@"WFCCRecallMessageContent")]) { // 0415
        // 群聊内，管理员撤回消息提示是全员可见，需要改为仅管理员/群主可见
        WFCCRecallMessageContent *contentAA = (WFCCRecallMessageContent *)content;
        // 该撤回消息的是群主或者管理员  仅管理员和群主可见
        if ([self isGroupManager:contentAA.operatorId]) {
            if (_isManager) { // 仅管理员和群主可见
                return YES;
            }else {
                [self deleteMessage];
                return NO;
            }
        }else { // 普通用户撤回的消息，任何人都可见-->不做更改
                return YES;
        }
    }
    else if ([content isKindOfClass:NSClassFromString(@"WFCCKickoffGroupMemberNotificationContent")] ||
              [content isKindOfClass:NSClassFromString(@"WFCCKickoffGroupMemberVisibleNotificationContent")]) { // 群组踢人的通知消息
        if (_isManager) { // 群主和管理员可以正常看到
            return YES;
        }
        if ([content isKindOfClass:NSClassFromString(@"WFCCKickoffGroupMemberNotificationContent")]) {
            WFCCKickoffGroupMemberNotificationContent *contentAA = (WFCCKickoffGroupMemberNotificationContent *)content;
            for (NSString *userid in contentAA.kickedMembers) {
                if ([userid isEqualToString:userId]) {
                    return YES;
                }
            }
        }else {
            WFCCKickoffGroupMemberVisibleNotificationContent *contentAA = (WFCCKickoffGroupMemberVisibleNotificationContent *)content;
            for (NSString *userid in contentAA.kickedMembers) {
                if ([userid isEqualToString:userId]) {
                    return YES;
                }
            }
        }
        [self deleteMessage];
        return NO;
    }else if ([content isKindOfClass:NSClassFromString(@"WFCCGroupMemberMuteNotificationContent")]) { // 群成员被禁言
        if (_isManager) { // 群主和管理员可以正常看到
            return YES;
        }
        WFCCGroupMemberMuteNotificationContent *contentAA = (WFCCGroupMemberMuteNotificationContent *)content;
        for (NSString *userid in contentAA.targetIds) {
            if ([userid isEqualToString:userId]) {
                return YES;
            }
        }
        [self deleteMessage];
        return NO;
    }else if ([content isKindOfClass:NSClassFromString(@"WFCCGroupMemberAllowNotificationContent")]) { // 群成员禁言被允许的通知消息
        if (_isManager) { // 群主和管理员可以正常看到
            return YES;
        }
        WFCCGroupMemberAllowNotificationContent *contentAA = (WFCCGroupMemberAllowNotificationContent *)content;
        for (NSString *userid in contentAA.targetIds) {
            if ([userid isEqualToString:userId]) {
                return YES;
            }
        }
        [self deleteMessage];
        return NO;
    }else if ([content isKindOfClass:NSClassFromString(@"WFCCQuitGroupVisibleNotificationContent")] ||
              [content isKindOfClass:NSClassFromString(@"WFCCQuitGroupNotificationContent")]) { // 退群的通知消息
        if (_isManager) { // 群主和管理员可以正常看到
            return YES;
        }
        [self deleteMessage];
        return NO;
    }else if ([content isKindOfClass:NSClassFromString(@"WFCCChangeGroupNameNotificationContent")] ||
              [content isKindOfClass:NSClassFromString(@"WFCCChangeGroupPortraitNotificationContent")] ||
              [content isKindOfClass:NSClassFromString(@"WFCCModifyGroupAliasNotificationContent")] ||
              [content isKindOfClass:NSClassFromString(@"WFCCModifyGroupMemberExtraNotificationContent")] ||
              [content isKindOfClass:NSClassFromString(@"WFCCModifyGroupExtraNotificationContent")] ||
              [content isKindOfClass:NSClassFromString(@"WFCCGroupSettingsNotificationContent")]) { //
        if (_isManager) { // 群主和管理员可以正常看到
            return YES;
        }
        [self deleteMessage];
        return NO;
    }
    
    return YES;
}

- (void)deleteMessage {
    BOOL isSuccess = [[WFCCMessageDB sharedManager] deleteMessage:self.info.lastMessage.messageId];
    if (isSuccess) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kDeleteMessages object:@(self.info.lastMessage.messageUid)];
    }
}

- (BOOL)isGroupManager:(NSString *)targetUserId {
    if (self.info.conversation.type != Group_Type) {
        return NO;
    }
    __block BOOL isManager = NO;
    NSArray<WFCCGroupMember *> *groupMembers = [[WFCCGroupDB sharedManager] getGroupMembers:self.info.conversation.target];
    [groupMembers enumerateObjectsUsingBlock:^(WFCCGroupMember * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.memberId isEqualToString:targetUserId]) {
            if (obj.type == Member_Type_Owner || obj.type == Member_Type_Manager) {
                isManager = YES;
            }
            *stop = YES;
        }
    }];
    return isManager;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    // 重置所有UI状态
    self.wsedcPotraitView.image = nil;
    self.wsedcTargetLabel.text = nil;
    
    // 清除缓存数据
    _cachedAvatarURL = nil;
    _cachedUserId = nil;
    _userInfo = nil;
    
    // 移除通知监听
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kUserInfoUpdated object:nil];
    
    // 重置头像标识（重要！）
    [self.wsedcPotraitView setAvatarIdentifier:nil];
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // 清理关联对象
    id observer = objc_getAssociatedObject(self, &kGroupPortraitObserverKey);
    if (observer) {
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    }
}

@end
