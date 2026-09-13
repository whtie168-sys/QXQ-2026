//
//  RUJBVOGHUYMemberInfoVC.m
//  QXQ
//
//  Created by Loooooo on 10/18/23.
//

#import "RUJBVOGHUYMemberInfoVC.h"
#import "YUBWOIJWDMessageVC.h"

#import "EPIKNODWVContactVC.h"
#import "WOPMKDIOFZTTextModifyVC.h"
#import "RUJBVOGHUYCommonGroupVC.h"
#import "RUJBVOGHUYShareCardVC.h"


@interface RUJBVOGHUYMemberInfoVC ()
{
    NSArray *_groupIds;
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIScrollView *raeuionjyScrollView;

@property (weak, nonatomic) IBOutlet UIImageView *raeuionjyIconView;
@property (weak, nonatomic) IBOutlet UILabel *raeuionjytzboeuNameLabel;

@property (weak, nonatomic) IBOutlet UIView *raeuionjyIDView;
@property (weak, nonatomic) IBOutlet UILabel *raeuionjyIdLabel;
@property (weak, nonatomic) IBOutlet UILabel *raeuionjySignLabel;

@property (weak, nonatomic) IBOutlet UIView *muteView;
@property (weak, nonatomic) IBOutlet UISwitch *muteSW;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sexTop;
@property (weak, nonatomic) IBOutlet UILabel *raeuionjySexLabel;
@property (weak, nonatomic) IBOutlet UILabel *raeuionjyPhoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *raeuionjyRemarkLabel;

@property (weak, nonatomic) IBOutlet UILabel *raeuionjyNumLabel;

@property (weak, nonatomic) IBOutlet UISwitch *raeuionjyDisturbSW;

@property (weak, nonatomic) IBOutlet UIButton *raeuionjyStarButton;
@property (weak, nonatomic) IBOutlet UIButton *raeuionjyMsgButton;


@property (nonatomic, strong) WFCCUserInfo *userInfo;
@property (nonatomic, strong) WFCCConversation *conversation;
@property (nonatomic, strong) WFCCConversationInfo *conversationInfo;
@property (nonatomic, strong) UserExtraInfo *extraInfo;

@property (nonatomic, strong) WFCCGroupInfo *groupInfo;

@property (weak, nonatomic) IBOutlet UILabel *muteL;
@property (weak, nonatomic) IBOutlet UILabel *sexL;
@property (weak, nonatomic) IBOutlet UILabel *phoneL;
@property (weak, nonatomic) IBOutlet UILabel *remarkL;
@property (weak, nonatomic) IBOutlet UILabel *commonGroupL;
@property (weak, nonatomic) IBOutlet UILabel *shareL;
@property (weak, nonatomic) IBOutlet UILabel *disturbL;

@property (weak, nonatomic) IBOutlet UILabel *voiceL;
@property (weak, nonatomic) IBOutlet UILabel *videoL;
@property (weak, nonatomic) IBOutlet UILabel *starL;


@end

@implementation RUJBVOGHUYMemberInfoVC

- (void)onGroupMemberUpdated:(NSNotification *)notification {
    if ([self.conversation.target isEqualToString:notification.object]) {
        
        [[GroupService shared] getGroupMember:_groupId
                                     memberId:_userId
                                      success:^(WFCCGroupMember * _Nonnull member) {
            
        } error:^(int code, NSString * _Nonnull msg) {
            
        }];
    }
}
- (void)onGroupInfoUpdated:(NSNotification *)notification {
    NSArray<WFCCGroupInfo *> *groupInfoList = notification.userInfo[@"groupInfoList"];
    for (WFCCGroupInfo *groupInfo in groupInfoList) {
        if ([self.conversation.target isEqualToString:groupInfo.target]) {

            break;
        }
    }
}
//- (void)onGroupMemberUpdated:(NSNotification *)notification {
//    if ([self.groupId isEqualToString:notification.object]) {
//        _memberList = [[WFCCIMService sharedWFCIMService] getGroupMembers:_groupId forceUpdate:NO].mutableCopy;
//    }
//}
//- (void)onGroupInfoUpdated:(NSNotification *)notification {
//    NSArray<WFCCGroupInfo *> *groupInfoList = notification.userInfo[@"groupInfoList"];
//    for (WFCCGroupInfo *groupInfo in groupInfoList) {
//        if ([self.groupId isEqualToString:groupInfo.target]) {
//            _groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:_groupId refresh:NO];
//        }
//    }
//}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[self itemImage:@"xaicosgoeMore" action:@selector(raeuionjyMore)]];
    
    _isChinese = [CommonHelper.main isChinese];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOnlineState) name:kUserOnlineStateUpdated object:nil];
    
    _groupIds = NSArray.new;
    if (_groupId.length > 0) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupMemberUpdated:) name:kGroupMemberUpdated object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupInfoUpdated:) name:kGroupInfoUpdated object:nil];
        
        [SVProgressHUD show];
        WS(weakself)
        [[GroupService shared] getGroupInfo:weakself.groupId
                                    success:^(WFCCGroupInfo * _Nonnull groupInfo) {
            weakself.groupInfo = groupInfo;
            
            [[GroupService shared] getGroupMember:weakself.groupId
                                         memberId:weakself.userId
                                          success:^(WFCCGroupMember * _Nonnull member) {
                [SVProgressHUD dismiss];
                self.userInfo = member.userInfo;
                [weakself loadData];
                [weakself muteStatus];
            } error:^(int code, NSString * _Nonnull msg) {
                [SVProgressHUD dismiss];
            }];
        } error:^(int code, NSString * _Nonnull msg) {
            [SVProgressHUD dismiss];

        }];
        
    } else {
        [SVProgressHUD show];
        [[UserService shared] getUserInfo:_userId
                                  success:^(WFCCUserInfo * _Nonnull userInfo) {
            [SVProgressHUD dismiss];
            self.userInfo = userInfo;
            [self loadData];
            [self muteStatus];
        } error:^(int errorCode, NSString * _Nonnull message) {
            [SVProgressHUD dismiss];
        }];
    }
    [self getFriendGroups];

    ViewRadius(_raeuionjyIconView, 38.0);
    ViewRadius(_raeuionjyIDView, 15.0)
    ViewRadius(_raeuionjyMsgButton, 20.0);

    [self queryOtherDevices];
    if (_isChinese) {
        
    }else {
        _phoneL.text = @"Tel";
        _remarkL.text = @"Note name";
        _commonGroupL.text = @"Group chat";
        _shareL.text = @"Share contacts";
        _disturbL.text = @"Do not disturb";
        
        _voiceL.text = @"Voice call";
        _videoL.text = @"Video call";
        _starL.text = @"Starmark";
        
        [_raeuionjyMsgButton setTitle:@"Send" forState:UIControlStateNormal];
    }
    _muteL.text = LLLLLL(@"Mute");
    _sexL.text = LLLLLL(@"Gender");
    
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

- (void)loadData {
    self.conversation = [WFCCConversation conversationWithType:Single_Type target:_userId line:0];
    self.conversationInfo = [WFCCIMService.sharedWFCIMService getConversationInfo:_conversation];
    
    self.extraInfo = [UserExtraInfo mj_objectWithKeyValues:self.userInfo.extra];
    
    [_raeuionjyIconView sd_setImageWithURL:URL(_userInfo.portrait) placeholderImage:[AIOIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                                   context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    
    if (_groupId.length > 0) {
        _raeuionjytzboeuNameLabel.text = _userInfo.displayName;
//        _raeuionjytzboeuNameLabel.text = [[WFCCGroupDB sharedManager] getGroupMember:self.groupId memberId:self.userId].finalName;
    } else {
        if (_userInfo.displayName.length) {
            _raeuionjytzboeuNameLabel.text = _userInfo.displayName;
        } else if (_userInfo.alias.length) {
            _raeuionjytzboeuNameLabel.text = _userInfo.alias;
        } else if (_userInfo.groupAlias.length) {
            _raeuionjytzboeuNameLabel.text = _userInfo.groupAlias;
        } else if (_userInfo.finalName.length > 0) {
            _raeuionjytzboeuNameLabel.text = _userInfo.finalName;
        } else {
            _raeuionjytzboeuNameLabel.text = @"";
        }
    }
    
    _raeuionjyIdLabel.text = _userInfo.name;
    NSString *gender = LLLLLL(@"Other");
    if (_userInfo.gender == 0) {
        gender = LLLLLL(@"Male");
    } else if (_userInfo.gender == 1) {
        gender = LLLLLL(@"Female");
    }
    _raeuionjySexLabel.text = gender;
    _raeuionjyRemarkLabel.text = _userInfo.alias;
    
    _raeuionjyDisturbSW.on = _conversationInfo.isSilent;
    
    
    _raeuionjySignLabel.text = _extraInfo.sign.length ? _extraInfo.sign : (_isChinese?@"对方什么都没有写":@"Nothing written");
    _raeuionjyPhoneLabel.text = (_extraInfo.disableShowPhone == 1 ? _userInfo.mobile : (_isChinese?@"联系人不展示电话":@"Contacts do not display phone numbers"));
    
    _raeuionjyStarButton.selected = [WFCCIMService.sharedWFCIMService isFavUser:self.userId];
}

- (void)raeuionjyMore {
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    WS(weakself)
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
    UIAlertAction *deleteFriendAction = [UIAlertAction actionWithTitle:(_isChinese?@"删除联系人":@"Delete contacts") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:weakself.view animated:YES];
        hud.label.text = LLLLLL(@"Loading");
        [hud showAnimated:YES];
        
        [[AppService sharedAppService] friendDelete:weakself.userId
                                            success:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];

                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:weakself.view animated:YES];
                hud.mode = MBProgressHUDModeText;
                hud.label.text = LLLLLL(@"SuccessfulOperation");
                hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                [hud hideAnimated:YES afterDelay:1.f];
                [[NSNotificationCenter defaultCenter] postNotificationName:kFriendListUpdated object:nil];
                [weakself.navigationController popViewControllerAnimated:YES];
            });
        } error:^(int errCode, NSString * _Nonnull message) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];

                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:weakself.view animated:YES];
                hud.mode = MBProgressHUDModeText;
                hud.label.text = LLLLLL(@"LoadFailure");
                hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                [hud hideAnimated:YES afterDelay:1.f];
            });
        }];
        
//        [[WFCCIMService sharedWFCIMService] deleteFriend:weakself.userId success:^{
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [hud hideAnimated:YES];
//
//                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:weakself.view animated:YES];
//                hud.mode = MBProgressHUDModeText;
//                hud.label.text = LLLLLL(@"SuccessfulOperation");
//                hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
//                [hud hideAnimated:YES afterDelay:1.f];
//                
//                [weakself.navigationController popViewControllerAnimated:YES];
//            });
//        } error:^(int error_code) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [hud hideAnimated:YES];
//
//                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:weakself.view animated:YES];
//                hud.mode = MBProgressHUDModeText;
//                hud.label.text = LLLLLL(@"LoadFailure");
//                hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
//                [hud hideAnimated:YES afterDelay:1.f];
//            });
//        }];
    }];
    [actionSheet addAction:blackListAction];
    [actionSheet addAction:deleteFriendAction];
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


// 备注名
- (IBAction)raeuionjyRemark:(UIButton *)sender {
    WOPMKDIOFZTTextModifyVC *vc = WOPMKDIOFZTTextModifyVC.new;
    vc.modifyType = Modify_FriendAlias;
    vc.userId = self.userId;
    vc.defaultValue = _raeuionjyRemarkLabel.text;
    WS(weakself)
    [vc setOnModified:^(NSString * _Nonnull value) {
        weakself.raeuionjyRemarkLabel.text = value;
//        if (value.length > 0) {
//            weakself.raeuionjytzboeuNameLabel.text = value;
//        }
    }];
    [self.navigationController pushViewController:vc animated:YES];
}


// 共同群聊
- (IBAction)raeuionjyGroupchat:(UIButton *)sender {
//    if (_groupIds.count <= 0) {
//        return;
//    }
    RUJBVOGHUYCommonGroupVC *groupsVC = RUJBVOGHUYCommonGroupVC.new;
    groupsVC.groupIds = _groupIds;
    groupsVC.userId = self.userId;
    [self.navigationController pushViewController:groupsVC animated:YES];
}
// 分享联系人
- (IBAction)raeuionjyShare:(UIButton *)sender {
//    EPIKNODWVContactVC *vc = EPIKNODWVContactVC.new;
//    vc.conversationType = Single_Type;
//    vc.type = 1;
//    vc.target = _userId;
//    vc.filterId = _userId;
//    [self.navigationController pushViewController:vc animated:YES];

    RUJBVOGHUYShareCardVC *vc = RUJBVOGHUYShareCardVC.new;
    vc.targetId = _userId;
    [self.navigationController pushViewController:vc animated:YES];
}

// 消息免打扰
- (IBAction)raeuionjyDisturb:(UISwitch *)sender {
    if (_conversation == nil) {
        return;
    }
    [WFCCIMService.sharedWFCIMService setConversation:_conversation silent:sender.isOn success:^{
    } error:^(int error_code) {
    }];
}


// 语音通话
- (IBAction)raeuionjyVoice:(UIButton *)sender {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    [SVProgressHUD showInfoWithStatus:@"该功能即将上线！敬请期待！"];
}

// 视频通话
- (IBAction)raeuionjyVideo:(UIButton *)sender {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    [SVProgressHUD showInfoWithStatus:@"该功能即将上线！敬请期待！"];
}

// 设为星标
- (IBAction)raeuionjyStar:(UIButton *)sender {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"Loading");
    [hud showAnimated:YES];
    [[WFCCIMService sharedWFCIMService] setFavUser:_userId fav:!_raeuionjyStarButton.selected success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            sender.selected = !sender.selected;

            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.label.text = LLLLLL(@"SuccessfulOperation");
            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [hud hideAnimated:YES afterDelay:1.f];
        });
    } error:^(int errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];

            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.label.text = LLLLLL(@"LoadFailure");
            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [hud hideAnimated:YES afterDelay:1.f];
        });
    }];
}

// 发消息
- (IBAction)raeuionjyMsg:(UIButton *)sender {
    YUBWOIJWDMessageVC *mvc = YUBWOIJWDMessageVC.new;
    mvc.hidesBottomBarWhenPushed = YES;
    mvc.conversation = _conversation;
    [self.navigationController pushViewController:mvc animated:YES];
}




#pragma mark - 禁言相关

// 禁言   isSet    设置或取消
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
    NSString *myuserId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    if ([self isGroupOwner:myuserId]) { // 判断当前登录账号是否是群主
        isShowMute = YES;
    }else { // 如果不是群主  进一步判断是否是管理员
        if ([self isGroupManager:myuserId]) { // 是管理员
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
        WFCCGroupMember *member = [[WFCCGroupDB sharedManager] getGroupMember:self.groupId memberId:self.userId];
        if (self.groupInfo.mute) {
            _muteSW.on = ![self canSpeakWhenGroupMuted:member];
        } else {
            _muteSW.on = [member.mute isEqualToString:@"1"];
        }
    }else {
        _muteSW.on = NO;
    }
}

- (void)isShowMute:(BOOL)isShow {
    if (isShow) {
        _muteView.hidden = NO;
        _sexTop.constant = 66.0 + 20.0;
    }else {
        _muteView.hidden = YES;
        _sexTop.constant = 20.0;
    }
}

- (BOOL)isGroupOwner:(NSString *)userId {
    return [self.groupInfo.owner isEqualToString:userId];
}
- (BOOL)isGroupManager:(NSString *)userId {
    return [[WFCCGroupDB sharedManager] getGroupMember:self.groupId memberId:userId].type == Member_Type_Manager;
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


- (void)getFriendGroups {
    [[AppService sharedAppService] groupListQueryUser:@{@"id": self.userId}
                                              success:^(NSArray<WFCCGroupInfo *> * _Nonnull friendgroups) {
        
        [[AppService sharedAppService] groupListQuery:^(NSArray<WFCCGroupInfo *> * _Nonnull mygroups) {
            [self getCommGroups:friendgroups myGroups:mygroups];
        } error:^(int errCode, NSString * _Nonnull message) {
        }];

    } error:^(int errCode, NSString * _Nonnull message) {
    }];
}

- (void)getCommGroups:(NSArray *)friendgroups myGroups:(NSArray *)mygroups {
    NSMutableArray *comms = [NSMutableArray new];
    for (WFCCGroupInfo *group1 in friendgroups) {
        for (WFCCGroupInfo *group2 in mygroups) {
            if ([group1.target isEqualToString:group2.target]) {
                [comms addObject:group1];
                break;
            }
        }
    }
    
    self.raeuionjyNumLabel.text = [NSString stringWithFormat:@"%ld%@",comms.count, (self->_isChinese?@"个":@"")];
}


@end
