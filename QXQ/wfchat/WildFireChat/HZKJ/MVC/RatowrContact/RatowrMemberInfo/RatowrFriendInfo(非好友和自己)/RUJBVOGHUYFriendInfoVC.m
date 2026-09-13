//
//  RUJBVOGHUYFriendInfoVC.m
//  WUHOIBDK
//
//  Created by Ruby on 12/13/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "RUJBVOGHUYFriendInfoVC.h"

#import "WOPMKDIOFZTTextModifyVC.h"
#import "EPIKNODWVAddValidationVC.h"


@interface RUJBVOGHUYFriendInfoVC ()
{
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIScrollView *raeuionjyScrollView;

@property (weak, nonatomic) IBOutlet UIImageView *raeuionjyIconView;
@property (weak, nonatomic) IBOutlet UILabel *raeuionjytzboeuNameLabel;

@property (weak, nonatomic) IBOutlet UIView *raeuionjyIDView;
@property (weak, nonatomic) IBOutlet UILabel *raeuionjyIdLabel;

@property (weak, nonatomic) IBOutlet UIView *muteView;
@property (weak, nonatomic) IBOutlet UISwitch *muteSW;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *lineViewTop;

@property (weak, nonatomic) IBOutlet UIView *raeuionjy86IDView;
@property (weak, nonatomic) IBOutlet UILabel *raeuionjyIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *raeuionjySexLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *raeuionjySexTop;
@property (weak, nonatomic) IBOutlet UILabel *raeuionjySignLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *raeuionjySignLabelRight;

@property (weak, nonatomic) IBOutlet UIButton *signButton;
@property (weak, nonatomic) IBOutlet UIButton *addFriendButton;


@property (nonatomic, strong) WFCCUserInfo *userInfo;
@property (nonatomic, strong) UserExtraInfo *extraInfo;

@property (nonatomic, strong) NSMutableArray<WFCCGroupMember *> *memberList;
@property (nonatomic, strong) WFCCGroupInfo *groupInfo;


@property (weak, nonatomic) IBOutlet UILabel *muteL;
@property (weak, nonatomic) IBOutlet UILabel *sexL;
@property (weak, nonatomic) IBOutlet UILabel *signL;

@end

@implementation RUJBVOGHUYFriendInfoVC

- (void)loadData {
    self.extraInfo = [UserExtraInfo mj_objectWithKeyValues:self.userInfo.extra];
//    NSLog(@"userInfo2===%@",_userInfo.mj_JSONObject);
    
    [_raeuionjyIconView sd_setImageWithURL:URL(_userInfo.portrait) placeholderImage:[AIOIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                                   context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    if (_userInfo.finalName.length > 0) {
        _raeuionjytzboeuNameLabel.text = _userInfo.finalName;
    } else if (_userInfo.alias.length) {
        _raeuionjytzboeuNameLabel.text = _userInfo.alias;
    }else if (_userInfo.groupAlias.length) {
        _raeuionjytzboeuNameLabel.text = _userInfo.groupAlias;
    }else if (_userInfo.displayName.length) {
        _raeuionjytzboeuNameLabel.text = _userInfo.displayName;
    }else {
        _raeuionjytzboeuNameLabel.text = @"";
    }
    _raeuionjyIdLabel.text = _userInfo.name;
    _raeuionjyIDLabel.text = _userInfo.name;
    NSString *gender = LLLLLL(@"Other");
    if (_userInfo.gender == 0) {
        gender = LLLLLL(@"Male");
    } else if (_userInfo.gender == 1) {
        gender = LLLLLL(@"Female");
    }
    _raeuionjySexLabel.text = gender;
    
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    BOOL isImy = [self.userId isEqualToString:userId]; // 是否是本人
    _raeuionjySignLabel.text = _extraInfo.sign.length ? _extraInfo.sign : (isImy ? (_isChinese?@"我什么都没写":@"Nothing written") : (_isChinese?@"对方什么都没有写":@"Nothing written"));
    
    if ([self isGroupOwner:userId] || [self isGroupManager:userId] || isImy) {
        // 是群主或管理员或者本人
        
    }else { // 非本人 非好友
        BOOL isMyFriend = [[WFCCIMService sharedWFCIMService] isMyFriend:self.userId];
        if (!isMyFriend) {
            _raeuionjyIDView.hidden = YES;
            _lineViewTop.constant = 20.0;
            _raeuionjy86IDView.hidden = YES;
            _raeuionjySexTop.constant = 0.0;
        }
    }
    if (isImy) { // 本人
        _addFriendButton.hidden = YES;
    }else {
        _signButton.hidden = YES;
        _raeuionjySignLabelRight.constant = 20.0;
        
        if (_groupId.length > 0) { // 通过群聊过来的、要判断群扩展字段(是否允许群成员互加好友)
            if (_isCardEnter) { // 名片消息进来的
                _addFriendButton.hidden = NO;
            }else {
                WFCCGroupInfo *groupInfo = [WFCCGroupDB.sharedManager getGroupInfoFromDB:_groupId];
                GroupExtraInfo *groupExtra = [GroupExtraInfo mj_objectWithKeyValues:groupInfo.extra];
                if (groupExtra.disableAddFriend == 1) { // 是否禁止群成员互加好友
                    if ([self isGroupOwner:userId]) {
                        _addFriendButton.hidden = NO;
                    } else if ([self isGroupManager:userId]) {
                        WFCCGroupMember *myPermissionMember = [self currentGroupMemberPermission:userId];
                        _addFriendButton.hidden = (myPermissionMember.disableAddFriend.intValue == 1);
                    } else {
                        _addFriendButton.hidden = YES;
                    }
                }else {
                    _addFriendButton.hidden = NO;
                }
            }
        }else {
            _addFriendButton.hidden = NO;
        }
    }
    if (_userInfo == nil) {
        _addFriendButton.hidden = YES;
    }
}
- (void)onGroupMemberUpdated:(NSNotification *)notification {
    if ([self.groupId isEqualToString:notification.object]) {
        _memberList = [[WFCCGroupDB sharedManager] getGroupMembers:_groupId].mutableCopy;
    }
}
- (void)onGroupInfoUpdated:(NSNotification *)notification {
    NSArray<WFCCGroupInfo *> *groupInfoList = notification.userInfo[@"groupInfoList"];
    for (WFCCGroupInfo *groupInfo in groupInfoList) {
        if ([self.groupId isEqualToString:groupInfo.target]) {
            _groupInfo = [[WFCCGroupDB sharedManager] getGroupInfoFromDB:_groupId];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [CommonHelper.main isChinese];
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    if (![self.userId isEqualToString:userId]) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[self itemImage:@"xaicosgoeMore" action:@selector(raeuionjyMore)]];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOnlineState) name:kUserOnlineStateUpdated object:nil];
    
    _raeuionjyIconView.layer.cornerRadius = 38.0;
    _raeuionjyIDView.layer.cornerRadius = 15.0;
    _addFriendButton.layer.cornerRadius = 25.0;
    

//    self.userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:_userId inGroup:_groupId refresh:YES];
    if (_groupId.length > 0) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupMemberUpdated:) name:kGroupMemberUpdated object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupInfoUpdated:) name:kGroupInfoUpdated object:nil];
        [[GroupService shared] getGroupMembers:_groupId
                                                 forceUpdate:YES
                                                     success:^(NSArray<WFCCGroupMember *> * _Nonnull members) {
            self.memberList = [NSMutableArray arrayWithArray:members];
            for (WFCCGroupMember *mem in self.memberList) {
                if ([mem.memberId isEqualToString:self.userId]) {
                    self.userInfo = mem.userInfo;
                    break;
                }
            }
            [self loadData];
            [self muteStatus];
        } error:^(int code, NSString * _Nonnull msg) {
            
        }];
        [[GroupService shared] getGroupInfo:_groupId
                                    refresh:YES
                                    success:^(WFCCGroupInfo * _Nonnull groupInfo) {
            self.groupInfo = groupInfo;
            
            [self loadData];
            [self muteStatus];

        } error:^(int code, NSString * _Nonnull msg) {
            
        }];
    } else {
        [[UserService shared] getUserInfo:_userId
                                  refresh:YES
                                  success:^(WFCCUserInfo * _Nonnull userInfo) {
            self.userInfo = userInfo;
            
            [self loadData];
            [self muteStatus];
        } error:^(int errorCode, NSString * _Nonnull message) {
            
        }];
    }
    
//    [self loadData];
//    [self muteStatus];
    
    [self queryOtherDevices];

    _muteL.text = LLLLLL(@"Mute");
    _sexL.text = LLLLLL(@"Gender");
    _signL.text = LLLLLL(@"PersonalSignature");
    [_addFriendButton setTitle:(_isChinese ? @"添加" : @"Add") forState:UIControlStateNormal];
}

- (void)queryOtherDevices {
    [[AppService sharedAppService] queryOtherDevices:@[self.userId]
                                             success:^(NSArray<WFCCUserOnlineStateModel *> * _Nonnull onlineState) {
        [[WFCCIMService sharedWFCIMService] putUseOnlineStates1:onlineState];
        [self updateOnlineState];
    } error:^(int errCode, NSString * _Nonnull message) {
        
    }];
}

- (void)updateOnlineState {
    if ([WFCCIMService.sharedWFCIMService isEnableUserOnlineState]) { // 是否开启了在线状态
        
        UserExtraInfo *extraInfo = [UserExtraInfo mj_objectWithKeyValues:_userInfo.extra];
        if (extraInfo.disableShowLastLoginTime == 0) { // 0 所有人    1 仅通讯录联系人    2 不显示在线时间
            [self onlineState];
        }else if (extraInfo.disableShowLastLoginTime == 1) {
            if ([CommonHelper.main isAddressBookContact:_userInfo.mobile]) {
                [self onlineState];
            }else {
                
            }
        }else {
            
        }
        
    }
}
- (void)onlineState {
    WFCCUserOnlineStateModel *state = [[WFCCIMService sharedWFCIMService] getUserOnlineState1:self.userId];
    NSString *platformStr = [CommonHelper.main customerPlatform:state.platform];

    if ([state.online isEqualToString:@"1"]) {
        self.navigationItem.title = LLLLLL(@"Online");
    } else {
        self.navigationItem.title = LLLLLL(@"Offline");
        if (state) {
            NSString *strSeenTime = [CommonHelper.main contactOnlineStatusDesc:[state.updateTimeStamp longLongValue]];
            
            if (strSeenTime.length) {                
                self.navigationItem.title = [NSString stringWithFormat:@"%@ %@",strSeenTime, LLLLLL(@"Online")];
                if (platformStr) {
                    self.navigationItem.title = [NSString stringWithFormat:@"%@ %@(%@)",strSeenTime, LLLLLL(@"Online"),platformStr];
                }

            }
        }
    }
    
//    BOOL online = NO;
//    BOOL hasMobileSession = NO;
//    long long mobileLastSeen = 0;
//    if(state.clientStates.count) { //有设备在线
//        if(state.customState.state != 4) { //没有设置为隐身
//            for (WFCCClientState *cs in state.clientStates) {
//                if(cs.state == 0) { // 设备的在线状态，0是在线，1是有session但不在线，其它不在线。
//                    online = YES;
//                    break;
//                }
//                if (cs.state == 1 && (cs.platform == 1 || cs.platform == 2)) {
//                    hasMobileSession = YES;
//                    if(mobileLastSeen < cs.lastSeen) {
//                        mobileLastSeen = cs.lastSeen;
//                    }
//                }
//            }
//        }
//    }
//    if (!online) {
//        if (hasMobileSession && mobileLastSeen > 0) {
//            NSString *strSeenTime = [CommonHelper.main onlineStatusDesc:mobileLastSeen];
//            if (strSeenTime.length) {
//                self.navigationItem.title = [NSString stringWithFormat:@"%@ %@",strSeenTime, LLLLLL(@"Online")];
//            }else {
//                self.navigationItem.title = LLLLLL(@"JustOffTheLine");
//            }
//        }
//    }else {
//        self.navigationItem.title = LLLLLL(@"Online");
//    }
}

- (void)raeuionjyMore {
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    UIAlertAction *blackListAction = [UIAlertAction actionWithTitle:LLLLLL(@"JoinTheBlacklist") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        
        UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:(self->_isChinese?@"加入黑名单后，你将不再接收到对方的任何消息":@"After you are added to the blacklist, you will not receive any messages from the other party") message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAct = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];
        WS(weakself)
        UIAlertAction *okAct = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [weakself addBlackList];
        }];
        [actionSheet addAction:cancelAct];
        [actionSheet addAction:okAct];
        [self presentViewController:actionSheet animated:YES completion:nil];
        
    }];
    [actionSheet addAction:blackListAction];
    [actionSheet addAction:actionCancel];
    [self presentViewController:actionSheet animated:YES completion:nil];
}
- (void)addBlackList {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"Loading");
    [hud showAnimated:YES];
    
    [[AppService sharedAppService] friendBlack:self.userId
                                       success:^{
        [hud hideAnimated:YES];

        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = LLLLLL(@"SuccessfulOperation");
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud hideAnimated:YES afterDelay:1.f];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });

    } error:^(int errCode, NSString * _Nonnull message) {
        [hud hideAnimated:YES];

        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = LLLLLL(@"LoadFailure");
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud hideAnimated:YES afterDelay:1.f];

    }];
    
//    [[WFCCIMService sharedWFCIMService] setBlackList:self.userId isBlackListed:YES success:^{
//        [hud hideAnimated:YES];
//
//        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//        hud.mode = MBProgressHUDModeText;
//        hud.label.text = LLLLLL(@"SuccessfulOperation");
//        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
//        [hud hideAnimated:YES afterDelay:1.f];
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [self.navigationController popViewControllerAnimated:YES];
//        });
//    } error:^(int error_code) {
//        [hud hideAnimated:YES];
//
//        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//        hud.mode = MBProgressHUDModeText;
//        hud.label.text = LLLLLL(@"LoadFailure");
//        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
//        [hud hideAnimated:YES afterDelay:1.f];
//    }];
}

// 复制ID
- (IBAction)raeuionjyCopy:(UIButton *)sender {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = _raeuionjyIdLabel.text;
    
    [SVProgressHUD showSuccessWithStatus:LLLLLL(@"CopySuccessfully")];
    [SVProgressHUD dismissWithDelay:1.0];
}

- (IBAction)sign:(UIButton *)sender { // 个性签名
    WOPMKDIOFZTTextModifyVC *vc = WOPMKDIOFZTTextModifyVC.new;
    vc.modifyType = Modify_Sign;
    vc.defaultValue = _extraInfo.sign;
    WS(weakself)
    [vc setOnModified:^(NSString * _Nonnull value) {
        weakself.raeuionjySignLabel.text = value;
    }];
    [self.navigationController pushViewController:vc animated:YES];
}


- (IBAction)addFriend:(UIButton *)sender { // 添加好友
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    WFCCUserInfo *myUserInfo = [[WFCCUserDB sharedManager] getUserInfo:userId];
    
    EPIKNODWVAddValidationVC *vc = EPIKNODWVAddValidationVC.new;
    vc.userInfo = _userInfo;
    NSString *name = (myUserInfo.alias.length > 0 ? myUserInfo.alias : myUserInfo.displayName);
    if (myUserInfo.finalName.length > 0) {
        name = myUserInfo.finalName;
    }
    vc.name = name;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onUserInfoUpdated:(NSNotification *)notification {
    NSArray<WFCCUserInfo *> *userInfoList = notification.userInfo[@"userInfoList"];
    for (WFCCUserInfo *userInfo in userInfoList) {
        if ([self.userId isEqualToString:userInfo.userId]) {
            self.userInfo = userInfo;
            [self loadData];
            break;
        }
    }
}




#pragma mark - 禁言相关

- (IBAction)mute:(UISwitch *)sender {
    if (self.groupInfo.mute) {
        NSString *speakWhenMuted = sender.isOn ? @"0" : @"1";
        [[AppService sharedAppService] groupMemberExtra:@{@"groupId": _groupId,
                                                          @"gid": _groupId,
                                                          @"uid": _userId,
                                                          @"speakWhenMuted": speakWhenMuted} success:^{
            
        } error:^(int errCode, NSString * _Nonnull message) {
            sender.on = !sender.isOn;
        }];
    } else {
        NSString *mute = sender.isOn ? @"1" : @"0";
        [[AppService sharedAppService] groupMemberUpdate:@{@"gid":_groupId, @"uid":_userId, @"mute": mute} success:^{
            
        } error:^(int error_code, NSString * _Nonnull message) {
            sender.on = !sender.isOn;
            if (error_code == ERROR_CODE_NOT_IMPLEMENT) {
                [self.view makeToast:LLLLLL(@"Unrealized")];
            }
        }];
    }
    
//    [WFCCIMService.sharedWFCIMService muteGroupMember:_groupId isSet:(sender.isOn) memberIds:@[_userId] notifyLines:@[@(0)] notifyContent:nil success:^{
//        
//    } error:^(int error_code) {
//        if (error_code == ERROR_CODE_NOT_IMPLEMENT) {
//            [self.view makeToast:LLLLLL(@"Unrealized")];
//        }
//    }];
}

/** 禁言 -> 禁言遵循的原则：
* 群主可以设置所有人禁言(包括管理员)、管理员可以设置普通用户禁言
 */
- (void)muteStatus {
    if (_isCardEnter) {
        [self isShowMute:NO];
        return;
    }
    if (_groupId.length <= 0) {
        [self isShowMute:NO];
        return;
    }
    BOOL isShowMute = NO;
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    if ([self isGroupOwner:userId]) { // 判断当前登录账号是否是群主
        isShowMute = YES;
        if ([self.userId isEqualToString:userId]) { // 是否进入自己的信息页面
            isShowMute = NO;
        }
    }else { // 如果不是群主  进一步判断是否是管理员
        if ([self isGroupManager:userId]) { // 是管理员
            // 必须得判断对方是否是管理员或者群主
            if ([self isGroupOwner:_userId] || [self isGroupManager:_userId]) { // 如果对方是管理员或者群组 -> 无权设置对方禁言
                isShowMute = NO;
            }else {
                isShowMute = YES;
            }
        }else {
            isShowMute = NO;
        }
    }
    [self isShowMute:isShowMute];
    
    if (isShowMute) {
        for (WFCCGroupMember *member in _memberList) {
            if ([member.memberId isEqualToString:_userId]) {
                if (self.groupInfo.mute) {
                    _muteSW.on = ![self canSpeakWhenGroupMuted:member];
                } else if (member.type == Member_Type_Muted || [member.mute isEqualToString:@"1"]) {
                    _muteSW.on = YES;
                }else {
                    _muteSW.on = NO;
                }
                break;
            }
        }
//        _muteSW.enabled = (_groupInfo.mute == 0);
    }else {
        _muteSW.on = NO;
    }
}

- (void)isShowMute:(BOOL)isShow {
    if (isShow) {
        _muteView.hidden = NO;
        _lineViewTop.constant = 66.0 + 20.0;
    }else {
        _muteView.hidden = YES;
        _lineViewTop.constant = 20.0;
    }
}


- (BOOL)isGroupOwner:(NSString *)userId {
    return [self.groupInfo.owner isEqualToString:userId];
}
- (BOOL)isGroupManager:(NSString *)userId {
    __block BOOL isManager = false;
    [self.memberList enumerateObjectsUsingBlock:^(WFCCGroupMember * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.memberId isEqualToString:userId]) {
            if (obj.type == Member_Type_Manager) {
                isManager = YES;
            }
            *stop = YES;
        }
    }];
    return isManager;
}

- (WFCCGroupMember *)currentGroupMemberPermission:(NSString *)userId {
    for (WFCCGroupMember *member in self.memberList) {
        if ([member.memberId isEqualToString:userId]) {
            if (!member.extra.length) {
                return member;
            }
            WFCCGroupMember *permissionMember = [WFCCGroupMember mj_objectWithKeyValues:member.extra];
            return permissionMember ?: member;
        }
    }
    return nil;
}

- (BOOL)canSpeakWhenGroupMuted:(WFCCGroupMember *)member {
    if (!member.extra.length) {
        return NO;
    }
    NSDictionary *extraDict = member.extra.mj_JSONObject;
    if (![extraDict isKindOfClass:NSDictionary.class]) {
        return NO;
    }
    return [extraDict[@"speakWhenMuted"] integerValue] == 1;
}



@end
