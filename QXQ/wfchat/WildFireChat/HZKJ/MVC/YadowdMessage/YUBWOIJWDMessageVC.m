//
//  YUBWOIJWDMessageVC.m
//  WUHOIBDK
//
//  Created by Ruby on 11/20/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "YUBWOIJWDMessageVC.h"
#import <AVFoundation/AVFoundation.h>

#import "YUBWOIJWDAnnouncementCell.h"


#import "YUBWOIJWDGroupAnnouncementVC.h"

#import "YUBWOIJWDGroupSetupVC.h"
#import "YUBWOIJWDSingleSetupVC.h"

#import "RUJBVOGHUYMemberInfoVC.h"
#import "RUJBVOGHUYFriendInfoVC.h"
#import "YUBWOIJWDConversationSearchVC.h"
#import "EPIKNODWVContactVC.h"

#import "YUBWOIJWDAnnouncementTopView.h"
#import "YUBWOIJWDTopMessageView.h"
#import "YUBWOIJWDAllTopMessagePopupView.h"
#import "NFCNUOEYForwardVC.h"
#import "YUBWOIJWDTopMessageShowViewController.h"
#import "UIImageView+Avatar.h"
#import <WFChatUIKit/SMIOUEJMessageCell.h>


@interface YUBWOIJWDMessageVC ()<UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate, UINavigationControllerDelegate, SMIOUEJMessageCellDelegate, AVAudioPlayerDelegate, WDCARChatInputBarDelegate, UIGestureRecognizerDelegate, MWPhotoBrowserDelegate>  // SMIOUEJMultiCallOngoingExpendedCellDelegate removed: voip
{
    NSString *_saveOnlineText;
    BOOL _isShowInputState; // 当前账号是否展示输入状态
    
//    BOOL isManager; // 是否是管理员-包含群主 0227新增
    
    BOOL _isChinese;
    
    BOOL _isUpdateGroupAnnouncement; // 是否更新了群公告内容
}
@property (nonatomic, strong)NSMutableArray<AIOIUEHMessageModel *> *modelList;

@property (nonatomic, strong)NSMutableArray<WFCCMessage *> *mentionedMsgs;

@property (nonatomic, strong)NSMutableDictionary<NSNumber *, Class> *cellContentDict;

@property(nonatomic) AVAudioPlayer *player;
@property(nonatomic) NSTimer *playTimer;

@property(nonatomic, assign)long playingMessageId;
@property(nonatomic, assign)BOOL loadingMore;
@property(nonatomic, assign)BOOL hasMoreOld;

@property(nonatomic, strong)WFCCUserInfo *targetUser;
@property(nonatomic, strong)WFCCGroupInfo *targetGroup;
@property(nonatomic, strong) GroupExtraInfo *groupExtraInfo;
@property(nonatomic, strong)WFCCChannelInfo *targetChannel;
@property(nonatomic, strong)WFCCChatroomInfo *targetChatroom;
@property(nonatomic, strong)WFCCSecretChatInfo *secretChatInfo;

@property(nonatomic, strong)WDCARChatInputBar *chatInputBar;
@property (strong, nonatomic) UICollectionView *collectionView;

@property (strong, nonatomic)NSArray<WFCCMessage *> *imageMsgs;

@property (strong, nonatomic)NSString *orignalDraft;

@property (nonatomic, strong)id<UIGestureRecognizerDelegate> scrollBackDelegate;

@property (nonatomic, strong)UIView *backgroundView;

@property (nonatomic, assign)BOOL showAlias;

@property (nonatomic, strong)SMIOUEJMessageCellBase *cell4Menu;
@property (nonatomic, assign)BOOL firstAppear;

@property (nonatomic, assign)BOOL hasNewMessage;
@property (nonatomic, assign)BOOL loadingNew;

@property (nonatomic, strong)UICollectionReusableView *headerView;
@property (nonatomic, strong)UICollectionReusableView *footerView;
@property (nonatomic, strong)UIActivityIndicatorView *headerActivityView;
@property (nonatomic, strong)UIActivityIndicatorView *footerActivityView;

@property (nonatomic, strong)NSTimer *showTypingTimer;

@property (nonatomic, assign)BOOL isShowingKeyboard;

@property (nonatomic, strong)NSMutableDictionary<NSString *, NSNumber *> *deliveryDict; // 会话的每个用户的已送达时间
/**
 readDict==={
     2ygqmws2k = 1703055848830;
     rygqmws2k = 1703055594686;
 }
 2ygqmws2k 用户最新的已读信息的时间
 */
@property (nonatomic, strong)NSMutableDictionary<NSString *, NSNumber *> *readDict;
@property (nonatomic, strong)NSMutableSet<NSNumber *> *nMsgSet;

@property (nonatomic, strong)UIView *multiSelectPanel;

@property (nonatomic, assign)long firstUnreadMessageId;
@property (nonatomic, assign)int unreadMessageCount;

@property (nonatomic, strong)UIButton *tzboeuUnreadButton;
@property (nonatomic, strong)UIButton *mentionedButton;
@property (nonatomic, strong)UIButton *newMsgTipButton;

@property (nonatomic, assign)int64_t lastUid;

    // voip properties removed: ongoingCallDict, ongoingCallTableView, focusedOngoingCellIndex, checkOngoingCallTimer

@property (nonatomic, assign)BOOL isAtButtom;

@property (nonatomic, strong)NSMutableDictionary<NSString*, NSDictionary*> *typingDict;


@property (nonatomic, strong) UIView *userView; // 1204新增
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *tzboeuNameLabel;
@property (nonatomic, strong) UILabel *onlineLabel;
@property (nonatomic, strong) UIView *tzboeuOnlineView;

// 非群聊的阅后即焚相关属性
@property (nonatomic, assign) long long autoDelete;
@property (nonatomic, assign) NSInteger waitTime;

@property (nonatomic, strong) DUVOHJNGroupAnnouncement *groupAnnouncement; // 0116
// 群公告新发布时 顶部的弹窗提示
@property (nonatomic, strong) YUBWOIJWDAnnouncementTopView *announcementTopView;


@property (nonatomic, strong) YUBWOIJWDTopMessageView *topMessageView; // 顶部的消息置顶或者公告
@property (nonatomic, assign) BOOL topMsgIsHidden;
@property (nonatomic, strong) NSMutableArray<MessageTopList *> *topMessages;

@property (nonatomic, strong) UIImageView *chatBgImgV; // 聊天背景图片 0815新增 用户设置聊天的背景图片

//已读消息
@property (nonatomic, strong) NSTimer *readStatusTimer;
@property (nonatomic, assign) BOOL isUpdatingReadTime;
@property (nonatomic, assign) BOOL isInChat;
// 单聊的已读缓存只有在服务端查询成功后才可信，避免历史错误缓存导致消息误显示为已读。
@property (nonatomic, assign) BOOL hasLoadedPeerReadStatus;


@end

@implementation YUBWOIJWDMessageVC

/**
 // NO  纯净模式   YES 非纯净模式(可以自定义气泡颜色和背景颜色/图片)   默认为0
 #define kAppearanceStatus  @"AppearanceStatus"
 #define kAppearanceBubbleColor  @"AppearanceBubbleColor" // 对话气泡颜色--->7种  从1开始  int类型  默认为0
 
 #define kAppearanceChatBackgroundImg  @"AppearanceChatBackground" // 聊天背景图片 ---> 4种  从1开始  int类型  默认为0
 #define kAppearanceChatBackgroundImgAlpha  @"AppearanceChatBackgroundAlpha" // 聊天背景图片透明度 ---> n种  0.0～1.0   float类型 默认为0
 #define kAppearanceChatBackgroundColor  @"AppearanceChatBackgroundColor" // 背景颜色 4种 从0开始 int类型  默认为0
 ChatBgImgColors
 */

- (UIImageView *)chatBgImgV {
    if (!_chatBgImgV) {
        _chatBgImgV = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, WIDTH, HEIGHT-TabBarHeight)];
        _chatBgImgV.contentMode = UIViewContentModeScaleAspectFill;
        NSInteger chatBackgroundImg = [NSUserDefaults.standardUserDefaults integerForKey:kAppearanceChatBackgroundImg];
        float chatBackgroundImgAlpha = [NSUserDefaults.standardUserDefaults floatForKey:kAppearanceChatBackgroundImgAlpha];
        NSInteger chatBackgroundColor = [NSUserDefaults.standardUserDefaults integerForKey:kAppearanceChatBackgroundColor];
        _chatBgImgV.image = IMAGENAME(UNString(@"erovaeChatBgImg%ld", chatBackgroundImg));
        _chatBgImgV.backgroundColor = [ChatBgImgColors[chatBackgroundColor] alpha:chatBackgroundImgAlpha];
    }return _chatBgImgV;
}
- (UIView *)userView {
    if (!_userView) {
        _userView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, WIDTH-80.0, 44.0)];
        _userView.backgroundColor = UIColor.clearColor;
        _userView.userInteractionEnabled = YES;
        [_userView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onRightBarBtn:)]];
        
        UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 3.0, 38.0, 38.0)];
        iconView.contentMode = UIViewContentModeScaleAspectFill;
        iconView.layer.cornerRadius = 18.0;
        iconView.layer.masksToBounds = YES;
        [_userView addSubview:iconView];
        _iconView = iconView;
        
        UILabel *tzboeuNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(iconView.frame) + 10.0, 0.0, WIDTH-100.0, 25.3)];
        tzboeuNameLabel.textColor = UIColor.blackColor;
        tzboeuNameLabel.textAlignment = NSTextAlignmentLeft;
        tzboeuNameLabel.font = PINGFANG_M(18.0)
        tzboeuNameLabel.backgroundColor = UIColor.clearColor;
        [_userView addSubview:tzboeuNameLabel];
        _tzboeuNameLabel = tzboeuNameLabel;
        
        _tzboeuOnlineView = [[UIView alloc] initWithFrame:CGRectMake(33, 30, 10, 10)];
        _tzboeuOnlineView.layer.cornerRadius = 5.0;
        _tzboeuOnlineView.layer.masksToBounds = YES;
        _tzboeuOnlineView.layer.borderColor = UIColor.whiteColor.CGColor;
        _tzboeuOnlineView.layer.borderWidth = 2.0;
        _tzboeuOnlineView.backgroundColor = [UIColor colorWithRed:43/255.0 green:221/255.0 blue:48/255.0 alpha:1.f];
        [_userView addSubview:_tzboeuOnlineView];
        _tzboeuOnlineView.hidden = YES;
        
        UILabel *onlineLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(tzboeuNameLabel.frame), CGRectGetMaxY(tzboeuNameLabel.frame), WIDTH-100.0, 16.0)];
        onlineLabel.textColor = RGBA(0x9A9A9A);
        onlineLabel.textAlignment = NSTextAlignmentLeft;
        onlineLabel.font = PINGFANG_R(12.0)
        onlineLabel.backgroundColor = UIColor.clearColor;
        [_userView addSubview:onlineLabel];
        _onlineLabel = onlineLabel;
        

    }return _userView;
}
- (void)topUserInfo {
    if (self.conversation.type == Single_Type) {
        if (self.targetUser.portrait && self.targetUser.portrait.length > 0) {
            [self.iconView sd_setAvatarWithURLString:self.targetUser.portrait
                                         placeholder:[AIOIUEHImage imageNamed:@"PersonalChat"]
                                              userId:_targetGroup.target
                                        cornerRadius:0];
        } else {
            self.iconView.image = [AIOIUEHImage imageNamed:@"PersonalChat"];
        }
        
        if (self.targetUser.finalName.length > 0) {
            _tzboeuNameLabel.text = self.targetUser.finalName;
        } else if (self.targetUser.alias.length) {
            _tzboeuNameLabel.text = self.targetUser.alias;
        } else if (self.targetUser.groupAlias.length) {
            _tzboeuNameLabel.text = self.targetUser.groupAlias;
        } else if(self.targetUser.displayName.length > 0) {
            _tzboeuNameLabel.text = self.targetUser.displayName;
        } else {
            _tzboeuNameLabel.text = [NSString stringWithFormat:@"user<%@>", self.targetUser.userId];
        }
        if ([self.conversation.target isEqualToString:@"customer_service"]) {
            _iconView.image = IMAGENAME(@"customerService");
            _tzboeuNameLabel.text = LLLLLL(@"AppCustomerService");
        }else if ([self.conversation.target isEqualToString:@"FireRobot"]) {
            if (self.targetUser.portrait.length <= 0) {
                _iconView.image = IMAGENAME(@"QXQ IM");
            }
            _tzboeuNameLabel.text = @"QXQ IM";
        }else if ([self.conversation.target isEqualToString:@"wfc_file_transfer"]) {
            if (_isChinese) {
                _tzboeuNameLabel.text = @"文件传输助手";
            }else {
                _tzboeuNameLabel.text = @"Transmission Assistant";
            }
        }
        if ([[WFCCIMService sharedWFCIMService] isEnableUserOnlineState]) {
            
            UserExtraInfo *extraInfo = [UserExtraInfo mj_objectWithKeyValues:_targetUser.extra];
            if (extraInfo.disableShowLastLoginTime == 0) { // 0 所有人    1 仅通讯录联系人    2 不显示在线时间
                [self onlineState];
            }else if (extraInfo.disableShowLastLoginTime == 1) {
//                if ([CommonHelper.main isAddressBookContact:_targetUser.mobile]) {
                    [self onlineState];
//                }else {
//                    _tzboeuNameLabel.frame = CGRectMake(CGRectGetMaxX(_iconView.frame) + 10.0, 0.0, WIDTH-100.0, 44.0);
//                    _onlineLabel.hidden = YES;
//                }
            }else {
                _tzboeuNameLabel.frame = CGRectMake(CGRectGetMaxX(_iconView.frame) + 10.0, 0.0, WIDTH-100.0, 44.0);
            }
            
        }else {
            // 当前用户是否启用消息回执功能，仅专业版有效
            if (_isShowInputState == 1) {
                _tzboeuNameLabel.frame = CGRectMake(CGRectGetMaxX(_iconView.frame) + 10.0, 0.0, WIDTH-100.0, 25.0);
                _saveOnlineText = (_isChinese?@"近期上过线":@"Recently online");
                if (_saveOnlineText) {
                    _onlineLabel.text = _saveOnlineText;
                }
            }else {
                _tzboeuNameLabel.frame = CGRectMake(CGRectGetMaxX(_iconView.frame) + 10.0, 0.0, WIDTH-100.0, 44.0);
            }
        }
    }else if (self.conversation.type == Group_Type) {
        if (_targetGroup.portrait && _targetGroup.portrait.length > 0) {
            // 构造 URL（注意要对 URL 编码）
            [self.iconView sd_setAvatarWithURLString:_targetGroup.portrait
                                         placeholder:[UIImage imageNamed:@"groupIcon"]
                                              userId:_targetGroup.target
                                        cornerRadius:0];
        } else {
            self.iconView.image = [UIImage imageNamed:@"groupIcon"];
        }
        if (self.targetGroup.name) {
            //            _tzboeuNameLabel.text = self.targetGroup.name;
            _tzboeuNameLabel.text = [NSString stringWithFormat:@"%@ (%ld)",_targetGroup.name, _targetGroup.memberCount];
        }else {
            _tzboeuNameLabel.text = [NSString stringWithFormat:@"group<%@>", self.targetGroup.target];
        }
        
        _tzboeuNameLabel.frame = CGRectMake(CGRectGetMaxX(_iconView.frame) + 10.0, 0.0, WIDTH-100.0, 44.0);
    }
}
- (void)onlineState {
    self.tzboeuOnlineView.hidden = YES;
    WFCCUserOnlineStateModel *state = [[WFCCIMService sharedWFCIMService] getUserOnlineState1:self.conversation.target];
    if (state) {
        _tzboeuNameLabel.frame = CGRectMake(CGRectGetMaxX(_iconView.frame) + 10.0, 0.0, WIDTH-100.0, 25.0);
        _onlineLabel.hidden = NO;
        if ([state.online isEqualToString:@"1"]) {
            
            _onlineLabel.text = LLLLLL(@"Online");
            _saveOnlineText = _onlineLabel.text;
            self.tzboeuOnlineView.hidden = NO;
        } else {
            NSString *strSeenTime = [CommonHelper.main contactOnlineStatusDesc:[state.updateTimeStamp longLongValue]];
            if (strSeenTime.length) {
                _onlineLabel.text = [NSString stringWithFormat:@"%@ %@",strSeenTime, LLLLLL(@"Online")];
            }else {
                _onlineLabel.text = LLLLLL(@"JustOffTheLine");
            }
        }
    } else {
        _tzboeuNameLabel.frame = CGRectMake(CGRectGetMaxX(_iconView.frame) + 10.0, 0.0, WIDTH-100.0, 44.0);
        _onlineLabel.hidden = YES;
    }
}

- (BOOL)isManager {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    return ([self isGroupOwner] || [self isGroupManager:userId]);
}

// 头像点击
- (void)onRightBarBtn:(UIBarButtonItem *)sender {
    if (self.selectedMessageIds.count) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    if ([self.conversation.target isEqualToString:@"FireRobot"] || [self.conversation.target isEqualToString:@"wfc_file_transfer"] ||
        [self.conversation.target isEqualToString:@"customer_service"]) {
        return;
    }
    if (self.conversation.type == Group_Type) {
        YUBWOIJWDGroupSetupVC *vc = YUBWOIJWDGroupSetupVC.new;
        vc.conversation = self.conversation;
        vc.groupAnnouncement = _groupAnnouncement;
        [self.navigationController pushViewController:vc animated:YES];
    }else {
        YUBWOIJWDSingleSetupVC *gvc = YUBWOIJWDSingleSetupVC.new;
        gvc.conversation = self.conversation;
        gvc.autoDelete = self.autoDelete;
        gvc.waitTime = self.waitTime;
        [self.navigationController pushViewController:gvc animated:YES];
    }
}
- (void)onRightBarItem:(UIBarButtonItem *)item {
    [self onRightBarBtn:item];
}

- (void)setupNavigationItem {
    if (self.multiSelecting) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[AIOIUEHImage imageNamed:@"search"] style:UIBarButtonItemStyleDone target:self action:@selector(onSearchBarBtn:)];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"Cancel") style:UIBarButtonItemStyleDone target:self action:@selector(onMultiSelectCancel:)];
    } else {
        if (self.conversation.type == Single_Type) {
            //            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[AIOIUEHImage imageNamed:@"nav_chat_single"] style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
            
            self.navigationItem.titleView = self.userView;
            if ([self.targetUser.userId isEqualToString:@"FireRobot"] || [self.targetUser.userId isEqualToString:@"wfc_file_transfer"]) {
                
            }else {
                //暂时隐藏
                UIBarButtonItem *itemA = [[UIBarButtonItem alloc] initWithImage:IMAGENAME(@"coaeisgoxVoice") style:UIBarButtonItemStyleDone target:self action:@selector(videoVoice:)];
                itemA.tag = 1;
                UIBarButtonItem *itemB = [[UIBarButtonItem alloc] initWithImage:IMAGENAME(@"coaeisgoxVideo") style:UIBarButtonItemStyleDone target:self action:@selector(videoVoice:)];
                itemB.tag = 0;
//                self.navigationItem.rightBarButtonItems = @[itemA, itemB];
            }
        } else if(self.conversation.type == Group_Type) {
            //            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[AIOIUEHImage imageNamed:@"nav_chat_group"] style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarItem:)]; // 1211  15:15 打开的注视  用于测试要删掉
            
            self.navigationItem.titleView = self.userView;
        } else if(self.conversation.type == SecretChat_Type) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[AIOIUEHImage imageNamed:@"nav_chat_single"] style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
        }
        if (self.presented) {
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"Close") style:UIBarButtonItemStyleDone target:self action:@selector(onCloseBtn:)];
        } else {
            self.navigationItem.leftBarButtonItem = nil;
        }
    }
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] init];
}
- (void)videoVoice:(UIBarButtonItem *)item {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    [SVProgressHUD showInfoWithStatus:@"该功能即将上线！敬请期待！"];
    return;
    NSString *userId = self.targetUser.userId;
    if ([_conversation.target isEqualToString:@"customer_service"]) {
        userId = _conversation.target;
    }
    if (userId.length <= 0) {
        return;
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    //    [[WFCCIMService sharedWFCIMService] clearUnreadStatus:self.conversation];
    _isChinese = [CommonHelper.main isChinese];
    _isUpdateGroupAnnouncement = NO;
    [self removeControllerStackIfNeed];
    self.isAtButtom = YES;
    self.cellContentDict = [[NSMutableDictionary alloc] init];
    self.typingDict = [[NSMutableDictionary alloc] init];
    
    [self initializedSubViews];
    
    self.firstAppear = YES;
    self.hasMoreOld = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onResetKeyboard:)];
    [self.collectionView addGestureRecognizer:tap];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onReceiveMessages:) name:kReceiveMessages object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRecallMessages:) name:kRecallMessages object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDeleteMessages:) name:kDeleteMessages object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMessageDelivered:) name:kMessageDelivered object:nil];
    // 消息的已读回调
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMessageReaded:) name:kMessageReaded object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSendingMessage:) name:kSendingMessageStatusUpdated object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMessageListChanged:) name:kMessageListChanged object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMessageUpdated:) name:kMessageUpdated object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMenuHidden:) name:UIMenuControllerDidHideMenuNotification object:nil];
    
    // voip: onCallStateChanged removed
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSettingUpdated:) name:kSettingUpdated object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUserOnlineState) name:kUserOnlineStateUpdated object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSecretChatStateChanged:) name:kSecretChatStateUpdated object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSecretMessageStartBurning:) name:kSecretMessageStartBurning object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSecretMessageBurned:) name:kSecretMessageBurned object:nil];
    self.chatInputBar = [[WDCARChatInputBar alloc] initWithSuperView:self.backgroundView conversation:self.conversation delegate:self];
    
    __weak typeof(self)ws = self;
    if(self.conversation.type == Single_Type) {
        self.targetUser = [[WFCCUserDB sharedManager] getUserInfo:self.conversation.target];
        [self topUserInfo];
        [self reloadMessageList];
        [self queryChannelStatus];

        [[UserService shared] getUserInfo:self.conversation.target
                                  refresh:YES
                                  success:^(WFCCUserInfo * _Nonnull userInfo) {
            self.targetUser = userInfo;
            [self topUserInfo];
            [self reloadMessageList];
            [self queryOtherDevice];
        } error:^(int errorCode, NSString * _Nonnull message) {
            
        }];

    } else if(self.conversation.type == Group_Type) {
        
        self.targetGroup = [[WFCCGroupDB sharedManager] getGroupInfoFromDB:self.conversation.target];
        self.groupExtraInfo = [GroupExtraInfo mj_objectWithKeyValues:_targetGroup.extra];
        [self topUserInfo];
        [self reloadMessageList];
        [self queryGroupChannelStatus];

        //先获取群成员，有些成员被禁言
        [[GroupService shared] getGroupMembers:self.conversation.target
                                   forceUpdate:YES
                                       success:^(NSArray<WFCCGroupMember *> * _Nonnull members) {
            
            [self.collectionView reloadData];
            
            //获取群里所有用户信息
//            NSMutableArray *memberIds = [[NSMutableArray alloc] init];
//            for (WFCCGroupMember *member in members) {
//                [memberIds addObject:member.memberId];
//            }
//            [[UserService shared] getUserInfos:memberIds
//                                       inGroup:self.conversation.target
//                                       refresh:YES
//                                       success:^(NSArray<WFCCUserInfo *> * _Nonnull users) {
//                [self.collectionView reloadData];
//            } error:^(int errorCode, NSString * _Nonnull message) {
//            }];

        } error:^(int code, NSString * _Nonnull msg) {
            
        }];
        
        //再获取群详情
        [[GroupService shared] getGroupInfo:self.conversation.target
                                    refresh:YES
                                    success:^(WFCCGroupInfo * _Nonnull groupInfo) {
            self.targetGroup = groupInfo;
            self.groupExtraInfo = [GroupExtraInfo mj_objectWithKeyValues:groupInfo.extra];
            [self topUserInfo];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self reloadMessageList];
            });
        } error:^(int code, NSString * _Nonnull msg) {
            
        }];

    } else if (self.conversation.type == Channel_Type) {
        WFCCChannelInfo *channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:self.conversation.target refresh:YES];
        self.targetChannel = channelInfo;
        [self reloadMessageList];
    } else if(self.conversation.type == Chatroom_Type) {
        
        [[WFCCIMService sharedWFCIMService] getChatroomInfo:self.conversation.target upateDt:ws.targetChatroom.updateDt success:^(WFCCChatroomInfo *chatroomInfo) {
            ws.targetChatroom = chatroomInfo;
            [self reloadMessageList];
        } error:^(int error_code) {
            
        }];
    } else if(self.conversation.type == SecretChat_Type) {
        self.secretChatInfo = [[WFCCIMService sharedWFCIMService] getSecretChatInfo:self.conversation.target];
        [self reloadMessageList];
    }
    
    if(self.conversation.type == Single_Type || self.conversation.type == SecretChat_Type) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    } else if(self.conversation.type == Group_Type) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupInfoUpdated:) name:kGroupInfoUpdated object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupInfoUpdated1:) name:kGroupInfoUpdatedByWs object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupMuteMember:) name:kGroupMuteMemberWs object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupMemberUpdated:) name:kGroupMemberUpdated object:nil];
    } else if(self.conversation.type == Channel_Type) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onChannelInfoUpdated:) name:kChannelInfoUpdated object:nil];
    }
    WFCCUserInfo *userInfo = [[AppCache sharedAppCache] getMyInfo];
    _isShowInputState = ([UserExtraInfo mj_objectWithKeyValues:userInfo.extra].disableShowInputState == 1);

//    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:userId refresh:NO];
//    _isShowInputState = ([UserExtraInfo mj_objectWithKeyValues:userInfo.extra].disableShowInputState == 1);
    
    [self setupNavigationItem];
    
    self.orignalDraft = [[WFCCIMService sharedWFCIMService] getConversationInfo:self.conversation].draft;
    
    if (self.conversation.type == Chatroom_Type) {
        NSString *joinedChatroomId = [[WFCCIMService sharedWFCIMService] getJoinedChatroomId];
        
        if(![ws.conversation.target isEqualToString:joinedChatroomId]) {
            __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
            hud.label.text = LLLLLL(@"JoinChatroom");
            [hud showAnimated:YES];
            
            [[WFCCIMService sharedWFCIMService] joinChatroom:ws.conversation.target success:^{
                NSLog(@"join chatroom successs");
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [ws sendChatroomWelcomeMessage];
                });
                [hud hideAnimated:YES];
            } error:^(int error_code) {
                NSLog(@"join chatroom error");
                hud.mode = MBProgressHUDModeText;
                hud.label.text = LLLLLL(@"JoinChatroomFailure");
    //            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                [hud hideAnimated:YES afterDelay:1.f];
                hud.completionBlock = ^{
                    [ws.navigationController popViewControllerAnimated:YES];
                };
            }];
        } else {
            [[WFCCIMService sharedWFCIMService] joinChatroom:ws.conversation.target success:^{
                //需要拉取历史消息
                [ws loadMoreMessage:YES completion:nil];
            } error:^(int error_code) {
                
            }];
        }
    }
    if(self.conversation.type == Channel_Type) {
        WFCCEnterChannelChatMessageContent *enterContent = [[WFCCEnterChannelChatMessageContent alloc] init];
        [[WFCCIMService sharedWFCIMService] send:self.conversation content:enterContent success:nil error:nil];
    }
    
    WFCCConversationInfo *info = [[WFCCIMService sharedWFCIMService] getConversationInfo:self.conversation];
    self.chatInputBar.draft = info.draft;
    
//    if (self.conversation.type == Group_Type) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [[GroupService shared] getGroupMembers:self.conversation.target
//                                       forceUpdate:YES
//                                           success:^(NSArray<WFCCGroupMember *> * _Nonnull members) {
//                NSMutableArray *memberIds = [[NSMutableArray alloc] init];
//                for (WFCCGroupMember *member in members) {
//                    [memberIds addObject:member.memberId];
//                }
//                
//                //获取群里所有用户信息
//                [[UserService shared] getUserInfos:memberIds
//                                           inGroup:self.conversation.target
//                                           refresh:YES
//                                           success:^(NSArray<WFCCUserInfo *> * _Nonnull users) {
//                    [self.collectionView reloadData];
//                } error:^(int errorCode, NSString * _Nonnull message) {
//                }];
////                [[WFCCUserDB sharedManager] getUserInfos:memberIds inGroup:self.conversation.target];
//
//            } error:^(int code, NSString * _Nonnull msg) {
//                
//            }];
//        });
//    }
    
    if (self.multiSelecting) {
        self.multiSelectPanel.hidden = NO;
    }
    
    self.nMsgSet = [[NSMutableSet alloc] init];
    if(self.conversation.type == Single_Type || self.conversation.type == Group_Type || self.conversation.type == SecretChat_Type) {
        if([[WFCCIMService sharedWFCIMService] isEnableUserOnlineState]) {
            BOOL isFriend = false;
            if(self.conversation.type == Single_Type) {
                isFriend = [[WFCCIMService sharedWFCIMService] isMyFriend:self.conversation.target];
            } else if(self.conversation.type == SecretChat_Type) {
                isFriend = [[WFCCIMService sharedWFCIMService] isMyFriend:self.secretChatInfo.userId];
            }
            
            if(!isFriend) { //如果不是好友才需要watch他的在线状态
                [self updateTitle];
            }
        }
    }
    
    [self single_get_option]; // 获取阅后即焚相关属性
    [self updateReadTime];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(single_get_option) name:kBurnAfterReadingUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                              selector:@selector(onGroupShouldUpdateReadTime:)
                                                  name:@"kGroupShouldUpdateReadTime"
                                                object:nil];
    if (_conversation.type == Group_Type) {
        [self getAnnouncementInfo];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(topMessageList) name:kCancel_Group_Announcement_Top object:nil];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(getAnnouncementInfo) name:@"New_Group_Announcement_Top" object:nil];
    }
}

- (void)startQueryReadStatusTimer {
    if (self.readStatusTimer) return;
    
    self.readStatusTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                             target:self
                                                           selector:@selector(queryReadChannelStatus)
                                                           userInfo:nil
                                                            repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.readStatusTimer forMode:NSRunLoopCommonModes];
}

//更新已读时间
- (void)updateReadTime{
    [[AppService sharedAppService] updateMessageReadTime:@{@"to": self.conversation.target}
                                                 success:^{
    } error:^(int errCode, NSString * _Nonnull message) {
        
    }];
}

//来新的消息时定时3s后再更新自己的已读
- (void)onGroupShouldUpdateReadTime:(NSNotification *)note {
    NSString *gid = note.userInfo[@"groupId"];
    if ([gid isEqualToString:self.conversation.target]) {
        [self updateReadTime];
    }
}

//5s定时更新成员已读
- (void)queryReadChannelStatus {
    if (_conversation.type == Group_Type) {
        [self queryGroupChannelStatus];
    } else if (_conversation.type == Single_Type) {
        [self queryChannelStatus];
    }
}

//获取群聊已读时间
- (void)queryGroupChannelStatus{
    [[AppService sharedAppService] queryGroupChannelStatus:@{@"gid": self.conversation.target}
                                                   success:^(NSDictionary * _Nonnull status) {
        [[WFCCConversationDB sharedManager] saveReadDict:status forConversation:self.conversation];
        self.readDict = [[WFCCIMService sharedWFCIMService] getConversationRead:self.conversation];

        WFCCGroupInfo *groupInfo = nil;
        for (int i = 0; i < self.modelList.count; i++) {
            AIOIUEHMessageModel *model  = self.modelList[i];
            model.readDict = self.readDict;
            if (model.message.direction == MessageDirection_Receive || model.readRate == 1.f) {
                continue;
            }
            
            long long messageTS = model.message.serverTime;
            __block int delieveriedCount = 0;
            [model.readDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
                NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
                if (![key isEqualToString:userId]) {
                    if ([obj longLongValue] >= messageTS) {
                        delieveriedCount++;
                    }
                }
            }];
            
            if (!groupInfo) {
                groupInfo = [[WFCCGroupDB sharedManager] getGroupInfoFromDB:model.message.conversation.target];
            }
            
            float rate = (float)delieveriedCount/(groupInfo.memberCount - 1);
            if (rate != model.readRate) {
                model.readRate = rate;
                [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]]];
            }
        }
        
    } error:^(int errCode, NSString * _Nonnull message) {
        
    }];
}

//获取单聊已读时间
- (void)queryChannelStatus{
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    if (userId.length == 0) {
        return;
    }
    [[AppService sharedAppService] queryChannelStatus:@{@"from": self.conversation.target,
                                                        @"tos":@[userId]}
                                              success:^(NSDictionary * _Nonnull status) {
        [[WFCCConversationDB sharedManager] saveReadDict:status forConversation:self.conversation];
        self.hasLoadedPeerReadStatus = YES;
        self.readDict = [[WFCCIMService sharedWFCIMService] getConversationRead:self.conversation];

        for (int i = 0; i < self.modelList.count; i++) {
            AIOIUEHMessageModel *model  = self.modelList[i];
            model.readDict = self.readDict;
            if (model.message.direction == MessageDirection_Receive) {
                continue;
            }
            
            if (self.conversation.type == Single_Type || self.conversation.type == SecretChat_Type) {
                long long peerReadTime = [[model.readDict objectForKey:userId] longLongValue];
                float rate = (model.message.serverTime > 0 && model.message.serverTime <= peerReadTime) ? 1.f : 0.f;
                if (rate != model.readRate) {
                    model.readRate = rate;
                    [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]]];
                }
            }
        }

    } error:^(int errCode, NSString * _Nonnull message) {
        
    }];
}

//获取在线状态
- (void)queryOtherDevice {
    [[AppService sharedAppService] queryOtherDevices:@[self.conversation.target]
                                             success:^(NSArray<WFCCUserOnlineStateModel *> * _Nonnull onlineState) {
        [[WFCCIMService sharedWFCIMService] putUseOnlineStates1:onlineState];
        [self topUserInfo];
    } error:^(int errCode, NSString * _Nonnull message) {
        
    }];
}

- (BOOL)shouldRefreshOnlineStateForReceivedMessages:(NSArray<WFCCMessage *> *)messages {
    if (self.conversation.type != Single_Type || messages.count == 0) {
        return NO;
    }
    
    WFCCUserOnlineStateModel *state = [[WFCCIMService sharedWFCIMService] getUserOnlineState1:self.conversation.target];
    if ([state.online isEqualToString:@"1"]) {
        return NO;
    }
    
    for (WFCCMessage *msg in messages) {
        if ([msg.conversation isEqual:self.conversation] &&
            msg.direction == MessageDirection_Receive &&
            [msg.fromUser isEqualToString:self.conversation.target]) {
            return YES;
        }
    }
    return NO;
}

- (void)groupAnnouncementUpdate:(NSNotification *)noti {
    _groupAnnouncement = noti.object;
    _isUpdateGroupAnnouncement = YES;
    
    [self reloadTopMessageView];
}


- (void)onUserInfoUpdated:(NSNotification *)notification {
    NSLog(@"个人信息修改=======通知16==");
    
    NSString *userId = notification.object;
    if (userId.length > 0) {
        if ([self.conversation.target isEqualToString:userId]) {
            [[UserService shared] getUserInfo:userId
                                      refresh:YES
                                      success:^(WFCCUserInfo * _Nonnull userInfo) {
                self.targetUser = userInfo;
                [self topUserInfo];
            } error:^(int errorCode, NSString * _Nonnull message) {
                
            }];
        }
    }
}

- (void)onGroupInfoUpdated1:(NSNotification *)notification {
    NSLog(@"群详情改变=======通知17==");
    [[GroupService shared] getGroupInfo:self.conversation.target
                                success:^(WFCCGroupInfo * _Nonnull groupInfo) {
        [[GroupService shared] getGroupMembers:self.conversation.target
                                   forceUpdate:YES
                                       success:^(NSArray<WFCCGroupMember *> * _Nonnull members) {
            self.targetGroup = groupInfo;
            self.groupExtraInfo = [GroupExtraInfo mj_objectWithKeyValues:groupInfo.extra];
            [self topUserInfo];
            [self.collectionView reloadData];
        } error:^(int code, NSString * _Nonnull msg) {
            self.targetGroup = groupInfo;
            self.groupExtraInfo = [GroupExtraInfo mj_objectWithKeyValues:groupInfo.extra];
            [self topUserInfo];
        }];
    } error:^(int code, NSString * _Nonnull msg) {
        
    }];

}

//成员禁言刷新
- (void)onGroupMuteMember:(NSNotification *)notification {
    NSArray *targetIds = [notification object];
    if (targetIds.count > 0) {
        [[GroupService shared] getGroupMember:self.conversation.target
                                     memberId:targetIds[0]
                                      success:^(WFCCGroupMember * _Nonnull member) {
            WFCCGroupInfo *TmpgroupInfo = self.targetGroup;
            self.targetGroup = TmpgroupInfo;

        } error:^(int code, NSString * _Nonnull msg) {
            
        }];
    }
}

- (void)onGroupInfoUpdated:(NSNotification *)notification {
    NSLog(@"群详情改变=======通知17==");
    NSArray<WFCCGroupInfo *> *groupInfoList = notification.userInfo[@"groupInfoList"];
    for (WFCCGroupInfo *groupInfo in groupInfoList) {
        if ([self.conversation.target isEqualToString:groupInfo.target]) {
            self.targetGroup = groupInfo;
            self.groupExtraInfo = [GroupExtraInfo mj_objectWithKeyValues:groupInfo.extra];
            [self topUserInfo];
            break;
        }
    }
}

- (void)onGroupMemberUpdated:(NSNotification *)notification {
    if ([self.conversation.target isEqualToString:notification.object]) {
        NSLog(@"群成员发生改变=======通知105== %@",notification.object);
        [[GroupService shared] getGroupInfo:self.conversation.target
                                    success:^(WFCCGroupInfo * _Nonnull groupInfo) {
            self.targetGroup = groupInfo;
            self.groupExtraInfo = [GroupExtraInfo mj_objectWithKeyValues:self.targetGroup.extra];
            [self topUserInfo];
            [[GroupService shared] getGroupMembers:self.conversation.target
                                           success:^(NSArray<WFCCGroupMember *> * _Nonnull members) {
                
                [self.collectionView reloadData];
            } error:^(int code, NSString * _Nonnull msg) {
                
            }];
            
        } error:^(int code, NSString * _Nonnull msg) {
            
        }];
    }
}

- (void)onChannelInfoUpdated:(NSNotification *)notification {
    NSLog(@"Jian=======通知19==");
    NSArray<WFCCChannelInfo *> *channelInfoList = notification.userInfo[@"channelInfoList"];
    for (WFCCChannelInfo *channelInfo in channelInfoList) {
        if ([self.conversation.target isEqualToString:channelInfo.channelId]) {
            self.targetChannel = channelInfo;
            break;
        }
    }
}



- (void)removeControllerStackIfNeed {
    //highlightMessageId will be positive if the VC pushed from search VC
    if (self.highlightMessageId > 0) {
        if (self.navigationController.viewControllers.count < 3) {
            return;
        }
        NSMutableArray *controllers = [self.navigationController.viewControllers mutableCopy];
        BOOL foundParent = NO;
        NSMutableArray *tobeDeleteVCs = [[NSMutableArray alloc] init];
        for (int i = (int)controllers.count - 2; i >=0; i--) {
            UIViewController *controller = controllers[i];
            [tobeDeleteVCs addObject:controller];
        }
        
        if (foundParent) {
            [controllers removeObjectsInArray:tobeDeleteVCs];
            self.navigationController.viewControllers = [controllers copy];
        }
    }
}

- (void)onMultiSelectCancel:(id)sender {
    self.multiSelecting = !self.multiSelecting;
}

- (void)setLoadingMore:(BOOL)loadingMore {
    _loadingMore = loadingMore;
    if (_loadingMore) {
        [self.headerActivityView startAnimating];
    } else {
        [self.headerActivityView stopAnimating];
    }
}

- (UIActivityIndicatorView *)headerActivityView {
    if (!_headerActivityView) {
        _headerActivityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    return _headerActivityView;
}

- (UIActivityIndicatorView *)footerActivityView {
    if (!_footerActivityView) {
        _footerActivityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    return _footerActivityView;
}

- (void)setLoadingNew:(BOOL)loadingNew {
    _loadingNew = loadingNew;
    if (loadingNew) {
        [self.footerActivityView startAnimating];
    } else {
        [self.footerActivityView stopAnimating];
    }
}

- (void)setHasNewMessage:(BOOL)hasNewMessage {
    _hasNewMessage = hasNewMessage;
    UICollectionViewFlowLayout *_customFlowLayout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    if (hasNewMessage) {
        _customFlowLayout.footerReferenceSize = CGSizeMake(320.0f, 20.0f);
    } else {
        _customFlowLayout.footerReferenceSize = CGSizeZero;
    }
}

- (void)loadRemoteHistoryMessages:(void (^ __nullable)(BOOL more))completion {
    __weak typeof(self) weakSelf = self;
    if(!self.lastUid) {
        self.lastUid = self.modelList.lastObject.message.messageUid;
    }
    for (AIOIUEHMessageModel *model in self.modelList) {
        if (model.message.messageUid > 0 && model.message.messageUid < self.lastUid) {
            self.lastUid = model.message.messageUid;
        }
    }
    //  获取服务器消息
    [[WFCCIMService sharedWFCIMService] getRemoteMessages:weakSelf.conversation before:self.lastUid count:10 contentTypes:nil success:^(NSArray<WFCCMessage *> *messages) {
        NSMutableArray *reversedMsgs = [[NSMutableArray alloc] init];
        for (WFCCMessage *msg in messages) {
            [reversedMsgs insertObject:msg atIndex:0];
            //            NSLog(@"MSG====%@",msg.toJsonObj);
            if (msg.messageUid > 0 && msg.messageUid < self.lastUid) {
                self.lastUid = msg.messageUid;
            }
        }
        
        if (!reversedMsgs.count) {
            weakSelf.hasMoreOld = NO;
        } else {
            [weakSelf appendMessages:reversedMsgs newMessage:NO highlightId:0 forceButtom:NO];
        }
        weakSelf.loadingMore = NO;
        if (completion) {
            completion(messages.count > 0);
        }
    } error:^(int error_code) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.hasMoreOld = NO;
            weakSelf.loadingMore = NO;
        });
    }];
}

- (void)loadMoreMessage:(BOOL)isHistory completion:(void (^ __nullable)(BOOL more))completion {
    __weak typeof(self) weakSelf = self;
    if (isHistory) {
        if (self.loadingMore) {
            return;
        }
        self.loadingMore = YES;
        //按照时间过滤serverTime
        long lastIndex = 0;
        if (weakSelf.modelList.count) {
            lastIndex = [weakSelf.modelList firstObject].message.serverTime;
        }
        
        [[WFCCIMService sharedWFCIMService] getMessagesV2:weakSelf.conversation contentTypes:nil from:lastIndex count:10 withUser:self.privateChatUser  success:^(NSArray<WFCCMessage *> *messageList) {
            if(messageList.count) {
                [weakSelf appendMessages:messageList newMessage:NO highlightId:0 forceButtom:NO];
                weakSelf.loadingMore = NO;
                if (completion) {
                    completion(messageList.count > 0);
                }
            } else {
                [weakSelf loadRemoteHistoryMessages:completion];
            }
        } error:^(int error_code) {
            weakSelf.loadingMore = NO;
        }];
    } else {
        if (weakSelf.loadingNew || !weakSelf.hasNewMessage) {
            return;
        }
        weakSelf.loadingNew = YES;
        
        long lastIndex = 0;
        if (self.modelList.count) {
            lastIndex = [self.modelList lastObject].message.messageId;
        }
        
        dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
            NSArray *messageList = [[WFCCIMService sharedWFCIMService] getMessages:self.conversation contentTypes:nil from:lastIndex count:-10 withUser:self.privateChatUser];
            //            for (WFCCMessage *msg in messageList) {
            //                NSLog(@"MSG1====%@",msg.toJsonObj);
            //            }
            if (!messageList.count || messageList.count < 10) {
                self.hasNewMessage = NO;
            }
            NSMutableArray *mutableMessages = [messageList mutableCopy];
            for (int i = 0; i < mutableMessages.count/2; i++) {
                int j = (int)mutableMessages.count - 1 - i;
                WFCCMessage *msg = [mutableMessages objectAtIndex:i];
                [mutableMessages insertObject:[mutableMessages objectAtIndex:j] atIndex:i];
                [mutableMessages removeObjectAtIndex:i+1];
                [mutableMessages insertObject:msg atIndex:j];
                [mutableMessages removeObjectAtIndex:j+1];
            }
            [NSThread sleepForTimeInterval:0.5];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf appendMessages:mutableMessages newMessage:YES highlightId:0 forceButtom:NO];
                weakSelf.loadingNew = NO;
                if (completion) {
                    completion(messageList.count > 0);
                }
            });
        });
    }
}
- (void)sendChatroomWelcomeMessage {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    if(!self.silentJoinChatroom) {
        WFCCTipNotificationContent *tip = [[WFCCTipNotificationContent alloc] init];
        WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:userId];
        NSString *name = userInfo.alias.length > 0 ? userInfo.alias : userInfo.displayName;
        if (userInfo.finalName.length > 0) {
            name = userInfo.finalName;
        }
        if (_isChinese) {
            tip.tip = UNString(@"欢迎 %@ 加入聊天室", name);
        }else {
            tip.tip = UNString(@"Welcome %@ to the chat room", name);
        }
        [self sendMessage:tip];
    }
}

- (void)sendChatroomLeaveMessage {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    __block WFCCConversation *strongConv = self.conversation;
    if(!self.silentJoinChatroom) {
        dispatch_async(dispatch_get_main_queue(), ^{
            WFCCTipNotificationContent *tip = [[WFCCTipNotificationContent alloc] init];
            WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:userId];
            NSString *name = userInfo.alias.length > 0 ? userInfo.alias : userInfo.displayName;
            if (userInfo.finalName.length > 0) {
                name = userInfo.finalName;
            }
            if (self->_isChinese) {
                tip.tip = UNString(@"%@ 离开了聊天室", name);
            }else {
                tip.tip = UNString(@"%@ left the chat room", name);
            }
            
            [[WFCCIMService sharedWFCIMService] send:strongConv content:tip success:^(long long messageUid, long long timestamp) {
                [[WFCCIMService sharedWFCIMService] quitChatroom:strongConv.target success:nil error:nil];
            } error:^(int error_code) {
                [[WFCCIMService sharedWFCIMService] quitChatroom:strongConv.target success:nil error:nil];
            }];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[WFCCIMService sharedWFCIMService] quitChatroom:strongConv.target success:nil error:nil];
        });
    }
    
}
- (void)onCloseBtn:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)onLeftBtnPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didMoveToParentViewController:(UIViewController*)parent
{
    [super didMoveToParentViewController:parent];
    if(!parent){
        [self leftMessageVC];
    }
}

- (void)leftMessageVC {
    if (self.conversation.type == Chatroom_Type && !self.keepInChatroom) {
        [self sendChatroomLeaveMessage];
    }
    if(self.conversation.type == Channel_Type) {
        WFCCLeaveChannelChatMessageContent *leaveContent = [[WFCCLeaveChannelChatMessageContent alloc] init];
        [[WFCCIMService sharedWFCIMService] send:self.conversation content:leaveContent success:nil error:nil];
    }
    
    if(self.conversation.type == Single_Type || self.conversation.type == Group_Type || self.conversation.type == SecretChat_Type) {
        if([[WFCCIMService sharedWFCIMService] isEnableUserOnlineState]) {
            BOOL isFriend = false;
            if(self.conversation.type == Single_Type) {
                isFriend = [[WFCCIMService sharedWFCIMService] isMyFriend:self.conversation.target];
            } else if(self.conversation.type == SecretChat_Type) {
                isFriend = [[WFCCIMService sharedWFCIMService] isMyFriend:self.secretChatInfo.userId];
            }
        }
    }
    
    // voip: checkOngoingCallTimer removed
}


- (void)onSearchBarBtn:(id)sender {
    if (self.multiSelecting) {
        for (AIOIUEHMessageModel *model in self.modelList) {
            if (model.selected && ![self.selectedMessageIds containsObject:@(model.message.messageId)]) {
                [self.selectedMessageIds addObject:@(model.message.messageId)];
            }
        }
        
        YUBWOIJWDConversationSearchVC *mvc = [[YUBWOIJWDConversationSearchVC alloc] init];
        mvc.conversation = self.conversation;
        mvc.hidesBottomBarWhenPushed = YES;
        mvc.messageSelecting = YES;
        mvc.selectedMessageIds = self.selectedMessageIds;
        [self.navigationController pushViewController:mvc animated:YES];
    }
}
- (void)updateUserOnlineState {
    NSLog(@"Jian=======通知12==");
    [self topUserInfo];
    [self updateTitle];
}
- (void)updateTitle {
    if(self.conversation.type == Single_Type || self.conversation.type == SecretChat_Type) {
        if (self.targetUser.finalName.length > 0) {
            self.title = self.targetUser.finalName;
        } else if(self.targetUser.alias.length) {
            self.title = self.targetUser.alias;
        } else if(self.targetUser.displayName.length == 0) {
            self.title = [NSString stringWithFormat:@"%@<%@>", LLLLLL(@"User"), self.conversation.target];
        } else {
            self.title = self.targetUser.displayName;
        }
        /*
         int Platform_UNSET = 0;
         int Platform_iOS = 1;
         int Platform_Android = 2;
         int Platform_Windows = 3;
         int Platform_OSX = 4;
         int Platform_WEB = 5;
         int Platform_WX = 6;
         int Platform_LINUX = 7;
         int Platform_iPad = 8;
         int Platform_APad = 9;
         */
        if([[WFCCIMService sharedWFCIMService] isEnableUserOnlineState]) {
            NSString *userId = self.conversation.target;
            if(self.conversation.type == SecretChat_Type) {
                userId = self.secretChatInfo.userId;
            }
            WFCCUserOnlineState *onlineState = [[WFCCIMService sharedWFCIMService] getUserOnlineState:userId];
            if([onlineState.clientStates count]) {
                int pcState = -1;
                int mobileState = -1;
                int webState = -1;
                int wxState = -1;
                int padState = -1;
                BOOL hasOnline = NO;
                BOOL hasMobileSession = NO;
                long long mobileLastSeen = 0;
                for (WFCCClientState *cs in onlineState.clientStates) {
                    if(cs.platform >= 1 && cs.platform <= 9 && cs.state == 0) {
                        hasOnline = YES;
                    }
                    
                    if(cs.platform == 1 || cs.platform == 2) {
                        mobileState = cs.state;
                        if(cs.state == 1) {
                            hasMobileSession = YES;
                            if(mobileLastSeen < cs.lastSeen) {
                                mobileLastSeen = cs.lastSeen;
                            }
                        }
                    } else if(cs.platform == 3 || cs.platform == 4 || cs.platform == 7) {
                        pcState = cs.state;
                    } else if(cs.platform == 5) {
                        webState = cs.state;
                    } else if(cs.platform == 6) {
                        wxState = cs.state;
                    } else if(cs.platform == 8 || cs.platform == 9) {
                        padState = cs.state;
                    }
                }
                
                if(hasOnline) {
                    //0，未设置，1 忙碌，2 离开（主动设置），3 离开（长时间不操作），4 隐身，其它可以自主扩展。
                    if(onlineState.customState.state == 0) {
                        if(pcState == 0) {
                            self.title = [NSString stringWithFormat:@"%@(%@)", self.title, (_isChinese?@"电脑在线":@"Computer online")];
                        } else if(padState == 0) {
                            self.title = [NSString stringWithFormat:@"%@(%@)", self.title, _isChinese?@"平板在线":@"Tablet online"];
                        } else if(webState == 0) {
                            self.title = [NSString stringWithFormat:@"%@(%@)", self.title, _isChinese?@"网页在线":@"Web online"];
                        } else if(wxState == 0) {
                            self.title = [NSString stringWithFormat:@"%@(%@)", self.title, _isChinese?@"小程序在线":@"Mini program online"];
                        } else if(mobileState == 0) {
                            self.title = [NSString stringWithFormat:@"%@(%@)", self.title, _isChinese?@"手机在线":@"Mobile online"];
                        }
                    } else if(onlineState.customState.state == 1) {
                        self.title = [NSString stringWithFormat:@"%@(%@)", self.title, _isChinese?@"忙碌":@"Busy"];
                    } else if(onlineState.customState.state == 2 || onlineState.customState.state == 3) {
                        self.title = [NSString stringWithFormat:@"%@(%@)", self.title, _isChinese?@"离开":@"Leave"];
                    } else {
                        //其它情况需要客户自己开发。。。
                    }
                    
                } else if(hasMobileSession && mobileLastSeen) {
                    long long duration = [[[NSDate alloc] init] timeIntervalSince1970] - (mobileLastSeen/1000);
                    int days = (int)(duration / 86400);
                    if(days) {
                        self.title = [NSString stringWithFormat:@"%@(%d天前手机在线)", self.title, days];
                    } else {
                        int hours = (int)(duration/3600);
                        if(hours) {
                            self.title = [NSString stringWithFormat:@"%@(%d小时前手机在线)", self.title, hours];
                        } else {
                            int mins = (int)(duration/60);
                            if(mins) {
                                self.title = [NSString stringWithFormat:@"%@(%d分钟前手机在线)", self.title, mins];
                            } else {
                                self.title = [NSString stringWithFormat:@"%@(不久前手机在线)", self.title];
                            }
                        }
                    }
                }
            }
        }
        //        self.navigationItem.backBarButtonItem.title = self.title;
    } else if(self.conversation.type == Group_Type) {
        if(self.targetGroup.displayName.length == 0) {
            self.navigationItem.title = LLLLLL(@"GroupChat");
            //            self.navigationItem.backBarButtonItem.title = @"信息";
        } else {
            self.navigationItem.title = [NSString stringWithFormat:@"%@(%d)", self.targetGroup.displayName, (int)self.targetGroup.memberCount];
            //            self.navigationItem.backBarButtonItem.title = self.targetGroup.displayName;
        }
    } else if(self.conversation.type == Channel_Type) {
        if(self.targetChannel.name.length == 0) {
            self.navigationItem.title = LLLLLL(@"Channel");
            //            self.navigationItem.backBarButtonItem.title = @"信息";
        } else {
            self.navigationItem.title = self.targetChannel.name;
            //            self.navigationItem.backBarButtonItem.title = self.targetChannel.name;
        }
    } else if (self.conversation.type == Chatroom_Type) {
        if(self.targetChatroom.title.length == 0) {
            self.navigationItem.title = LLLLLL(@"Chatroom");
            //            self.navigationItem.backBarButtonItem.title = @"信息";
        } else {
            self.navigationItem.title = self.targetChatroom.title;
            //            self.navigationItem.backBarButtonItem.title = self.targetChatroom.title;
        }
    }
}

- (void)setTargetUser:(WFCCUserInfo *)targetUser {
    _targetUser = targetUser;
    [self updateTitle];
}

- (void)setTargetGroup:(WFCCGroupInfo *)targetGroup {
    _targetGroup = targetGroup;
    self.groupExtraInfo = [GroupExtraInfo mj_objectWithKeyValues:targetGroup.extra];
    _tzboeuNameLabel.text = [NSString stringWithFormat:@"%@ (%ld)",_targetGroup.name, _targetGroup.memberCount];
    [self updateTitle];
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    ChatInputBarStatus defaultStatus = ChatInputBarDefaultStatus;
    ChatInputBarStatus previousStatus = self.chatInputBar.inputBarStatus;
    WFCCGroupMember *member = [[WFCCGroupDB sharedManager] getGroupMember:targetGroup.target memberId:userId];
    BOOL canSpeakWhenMuted = [self canSpeakWhenGroupMuted:member];
    if (targetGroup.mute || member.type == Member_Type_Muted || [member.mute isEqualToString:@"1"]) {
        if ([targetGroup.owner isEqualToString:userId]) {
            self.chatInputBar.inputBarStatus =  defaultStatus;
        } else if(targetGroup.mute && (member.type == Member_Type_Allowed || canSpeakWhenMuted)) {
            self.chatInputBar.inputBarStatus =  defaultStatus;
        } else {
            WFCCGroupMember *gm = [[WFCCGroupDB sharedManager] getGroupMember:targetGroup.target memberId:userId];
            if (gm.type == Member_Type_Manager) {
                self.chatInputBar.inputBarStatus =  defaultStatus;
            } else {
                self.chatInputBar.inputBarStatus = ChatInputBarMuteStatus;
            }
        }
    } else {
        if(self.chatInputBar.inputBarStatus == ChatInputBarMuteStatus) {
            self.chatInputBar.inputBarStatus =  defaultStatus;
        }
    }
    if (self.isInChat &&
        previousStatus != ChatInputBarMuteStatus &&
        self.chatInputBar.inputBarStatus == ChatInputBarMuteStatus) {
        [self clearCurrentDraft];
    }
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

- (void)clearCurrentDraft {
    self.orignalDraft = nil;
    self.chatInputBar.draft = nil;
    [[WFCCIMService sharedWFCIMService] setConversation:self.conversation draft:nil];
}

- (void)setTargetChannel:(WFCCChannelInfo *)targetChannel {
    _targetChannel = targetChannel;
    [self updateTitle];
}

- (void)setTargetChatroom:(WFCCChatroomInfo *)targetChatroom {
    _targetChatroom = targetChatroom;
    [self updateTitle];
}

- (void)setSecretChatInfo:(WFCCSecretChatInfo *)secretChatInfo {
    _secretChatInfo = secretChatInfo;
    NSString *userId = self.secretChatInfo.userId;
    [[UserService shared] getUserInfo:userId
                              refresh:YES
                              success:^(WFCCUserInfo * _Nonnull userInfo) {
        self.targetUser = userInfo;
    } error:^(int errorCode, NSString * _Nonnull message) {
        
    }];
}

- (void)setShowAlias:(BOOL)showAlias {
    _showAlias = showAlias;
    if (self.modelList) {
        for (AIOIUEHMessageModel *model in self.modelList) {
            if (showAlias && model.message.direction == MessageDirection_Receive) {
                model.showtzboeuNameLabel = YES;
            } else {
                model.showtzboeuNameLabel = NO;
            }
        }
    }
}

- (void)setMultiSelecting:(BOOL)multiSelecting {
    _multiSelecting = multiSelecting;
    if (multiSelecting) {
        for (AIOIUEHMessageModel *model in self.modelList) {
            model.selecting = YES;
            model.selected = NO;
        }
        
        if (!self.selectedMessageIds) {
            self.selectedMessageIds = [[NSMutableArray alloc] init];
        }
        
        self.multiSelectPanel.hidden = NO;
    } else {
        for (AIOIUEHMessageModel *model in self.modelList) {
            model.selecting = NO;
            model.selected = NO;
        }
        self.selectedMessageIds = nil;
        self.multiSelectPanel.hidden = YES;
    }
    
    [self setupNavigationItem];
    [self.collectionView reloadData];
}
- (UIView *)multiSelectPanel {
    if (!_multiSelectPanel) {
        if (!self.backgroundView) {
            return nil;
        }
        _multiSelectPanel = [[UIView alloc] initWithFrame:CGRectMake(0, self.backgroundView.bounds.size.height - CHAT_INPUT_BAR_HEIGHT, self.backgroundView.bounds.size.width, CHAT_INPUT_BAR_HEIGHT)];
        _multiSelectPanel.backgroundColor = [UIColor colorWithHexString:@"0xf7f7f7"];
        UIButton *deleteBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, _multiSelectPanel.bounds.size.width/2, _multiSelectPanel.bounds.size.height)];
        [deleteBtn setTitle:LLLLLL(@"Delete") forState:UIControlStateNormal];
        [deleteBtn addTarget:self action:@selector(onDeleteMultiSelectedMessage:) forControlEvents:UIControlEventTouchDown];
        [deleteBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [_multiSelectPanel addSubview:deleteBtn];
        
        UIButton *forwardBtn = [[UIButton alloc] initWithFrame:CGRectMake(_multiSelectPanel.bounds.size.width/2, 0, _multiSelectPanel.bounds.size.width/2, _multiSelectPanel.bounds.size.height)];
        [forwardBtn setTitle:LLLLLL(@"Forwarding") forState:UIControlStateNormal];
        [forwardBtn addTarget:self action:@selector(onForwardMultiSelectedMessage:) forControlEvents:UIControlEventTouchDown];
        [forwardBtn setTitleColor:[UIColor systemGreenColor] forState:UIControlStateNormal];
        [_multiSelectPanel addSubview:forwardBtn];
        
        [self.backgroundView addSubview:_multiSelectPanel];
    }
    return _multiSelectPanel;
}

- (void)onDeleteMultiSelectedMessage:(id)sender {
    NSMutableArray *deletedModels = [[NSMutableArray alloc] init];
    for (AIOIUEHMessageModel *model in self.modelList) {
        if (model.selected) {
            [[WFCCIMService sharedWFCIMService] deleteMessage:model.message.messageId];
            [deletedModels addObject:model];
            [self.selectedMessageIds removeObject:@(model.message.messageId)];
        }
    }
    [self.modelList removeObjectsInArray:deletedModels];
    
    //有可能是经过多次搜索，选中了当前model列表中没有包含的
    for (NSNumber *IDS in self.selectedMessageIds) {
        [[WFCCIMService sharedWFCIMService] deleteMessage:[IDS longValue]];
    }
    
    self.multiSelecting = NO;
}

- (void)onForwardMultiSelectedMessage:(id)sender {
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    for (AIOIUEHMessageModel *model in self.modelList) {
        if (model.selected) {
            [messages addObject:model.message];
        }
    }
    
    [self.selectedMessageIds removeAllObjects];
    self.multiSelecting = NO;
    
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil];
    
    UIAlertAction *oneByOneAction = [UIAlertAction actionWithTitle:LLLLLL(@"ForwardingOneByOne") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NFCNUOEYForwardVC *controller = [[NFCNUOEYForwardVC alloc] init];
        controller.messages = messages;
//        UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:controller];
//        [self.navigationController presentViewController:navi animated:YES completion:nil];
        [self.navigationController pushViewController:controller animated:YES];
        
    }];
    UIAlertAction *AllInOneAction = [UIAlertAction actionWithTitle:LLLLLL(@"MergeForward") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        WFCCCompositeMessageContent *compositeContent = [[WFCCCompositeMessageContent alloc] init];
        
        if (self.conversation.type == Single_Type) {
            NSString *title = nil;
            if (self.targetUser.finalName.length > 0) {
                title = self.targetUser.finalName;
            } else if(self.targetUser.alias.length) {
                title = self.targetUser.alias;
            } else if(self.targetUser.displayName.length == 0) {
                title = [NSString stringWithFormat:@"%@<%@>", LLLLLL(@"User"), self.conversation.target];
            } else {
                title = self.targetUser.displayName;
            }
            NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
            WFCCUserInfo *myself = [[WFCCUserDB sharedManager] getUserInfo:userId];
            NSString *myname = myself.displayName;
            if (myself.finalName.length > 0) {
                myname = myself.finalName;
            }
            if (self->_isChinese) {
                compositeContent.title = [NSString stringWithFormat:@"%@和%@ 的聊天记录", title, myname];
            }else {
                compositeContent.title = [NSString stringWithFormat:@"%@ and %@'s chat history", title, myname];
            }
        } else if (self.conversation.type == Group_Type) {
            compositeContent.title = self->_isChinese?@"群的聊天记录":@"Group chat history";
        } else if (self.conversation.type == Channel_Type) {
            compositeContent.title = self->_isChinese?@"频道的聊天记录":@"Channel chat history";
        } else if(self.conversation.type == SecretChat_Type) {
            compositeContent.title = self->_isChinese?@"密聊记录":@"Secret chat history";
        } else {
            compositeContent.title = self->_isChinese?@"聊天记录":@"Chat history";
        }
        
        compositeContent.messages = messages;
        WFCCMessage *msg = [[WFCCMessage alloc] init];
        msg.content = compositeContent;
        
        NFCNUOEYForwardVC *controller = [[NFCNUOEYForwardVC alloc] init];
        controller.message = msg;
        UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:controller];
//        [self.navigationController presentViewController:navi animated:YES completion:nil];
        [self.navigationController pushViewController:controller animated:YES];

    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:oneByOneAction];
    [alertController addAction:AllInOneAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)scrollToBottom:(BOOL)animated {
    NSUInteger rowCount = [self.collectionView numberOfItemsInSection:0];
    if (rowCount == 0) {
        return;
    }
    NSUInteger finalRow = rowCount - 1;
    
    for (int i = 0; i < self.modelList.count; i++) {
        if ([self.modelList objectAtIndex:i].highlighted) {
            finalRow = i;
            break;
        }
    }
    
    NSIndexPath *finalIndexPath = [NSIndexPath indexPathForItem:finalRow inSection:0];
    [self.collectionView scrollToItemAtIndexPath:finalIndexPath
                                atScrollPosition:UICollectionViewScrollPositionBottom
                                        animated:animated];
    
    [self dismissNewMsgTip];
}

- (void)initializedSubViews {
    UICollectionViewFlowLayout *_customFlowLayout = [[UICollectionViewFlowLayout alloc] init];
    _customFlowLayout.minimumLineSpacing = 0.0f;
    _customFlowLayout.sectionInset = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
    _customFlowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    _customFlowLayout.headerReferenceSize = CGSizeMake(320.0f, 20.0f);
    
    CGRect frame = self.view.bounds;
    frame.origin.y += [AIOIUEHUtilities wf_navigationFullHeight];
    frame.size.height -= ([AIOIUEHUtilities wf_safeDistanceBottom] + [AIOIUEHUtilities wf_navigationFullHeight]);
    self.backgroundView = [[UIView alloc] initWithFrame:frame];
    [self.view addSubview:self.backgroundView];
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.backgroundView.bounds.size.width, self.backgroundView.bounds.size.height - CHAT_INPUT_BAR_HEIGHT) collectionViewLayout:_customFlowLayout];
    
    [self.backgroundView addSubview:self.collectionView];
    
    self.backgroundView.backgroundColor = UIColor.clearColor;
    self.collectionView.backgroundColor = UIColor.clearColor;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.alwaysBounceVertical = YES;
    
    
    self.view.backgroundColor = UIColor.whiteColor;
    if ([NSUserDefaults.standardUserDefaults boolForKey:kAppearanceStatus] == NO) { // NO  纯净模式
        
    }else { // 0815新增
        [self.view addSubview:self.chatBgImgV];
        [self.view sendSubviewToBack:self.chatBgImgV];
    }
    
    [self registerCell:[SMIOUEJTextCell class] forContent:[WFCCTextMessageContent class]];
    [self registerCell:[SMIOUEJTextCell class] forContent:[WFCCPTextMessageContent class]];
    [self registerCell:[SMIOUEJImageCell class] forContent:[WFCCImageMessageContent class]];
    [self registerCell:[SMIOUEJVoiceCell class] forContent:[WFCCSoundMessageContent class]];
    [self registerCell:[SMIOUEJVoiceCell class] forContent:[WFCCPTTSoundMessageContent class]];
    [self registerCell:[SMIOUEJVideoCell class] forContent:[WFCCVideoMessageContent class]]; // 视频类型
    [self registerCell:[SMIOUEJLocationCell class] forContent:[WFCCLocationMessageContent class]];
    [self registerCell:[SMIOUEJFileCell class] forContent:[WFCCFileMessageContent class]];
    [self registerCell:[SMIOUEJStickerCell class] forContent:[WFCCStickerMessageContent class]];
    
    [self registerCell:[SMIOUEJInformationCell class] forContent:[WFCCCreateGroupNotificationContent class]];
    [self registerCell:[SMIOUEJInformationCell class] forContent:[WFCCAddGroupeMemberNotificationContent class]];
    [self registerCell:[SMIOUEJInformationCell class] forContent:[WFCCKickoffGroupMemberNotificationContent class]];
    [self registerCell:[SMIOUEJInformationCell class] forContent:[WFCCQuitGroupNotificationContent class]];
    [self registerCell:[SMIOUEJInformationCell class] forContent:[WFCCKickoffGroupMemberVisibleNotificationContent class]];
    [self registerCell:[SMIOUEJInformationCell class] forContent:[WFCCQuitGroupVisibleNotificationContent class]];
    [self registerCell:[SMIOUEJInformationCell class] forContent:[WFCCDismissGroupNotificationContent class]];
    [self registerCell:[SMIOUEJInformationCell class] forContent:[WFCCTransferGroupOwnerNotificationContent class]];
    [self registerCell:[SMIOUEJInformationCell class] forContent:[WFCCModifyGroupAliasNotificationContent class]];
    [self registerCell:[SMIOUEJInformationCell class] forContent:[WFCCChangeGroupNameNotificationContent class]];
    [self registerCell:[SMIOUEJInformationCell class] forContent:[WFCCChangeGroupPortraitNotificationContent class]];
    [self registerCell:[SMIOUEJInformationCell class] forContent:[WFCCFriendAddedMessageContent class]];
    [self registerCell:[SMIOUEJInformationCell class] forContent:[WFCCFriendGreetingMessageContent class]];
    
    [self registerCell:[SMIOUEJCallSummaryCell class] forContent:[WFCCCallStartMessageContent class]];
    [self registerCell:[SMIOUEJInformationCell class] forContent:[WFCCTipNotificationContent class]];
    [self registerCell:[SMIOUEJInformationCell class] forContent:[WFCCUnknownMessageContent class]];
    [self registerCell:[SMIOUEJRecallCell class] forContent:[WFCCRecallMessageContent class]];
    [self registerCell:[SMIOUEJCardCell class] forContent:[WFCCCardMessageContent class]];
    [self registerCell:[SMIOUEJCompositeCell class] forContent:[WFCCCompositeMessageContent class]];
    [self registerCell:[SMIOUEJLinkCell class] forContent:[WFCCLinkMessageContent class]];
    [self registerCell:[SMIOUEJRichNotificationCell class] forContent:[WFCCRichNotificationMessageContent class]];
    [self registerCell:[SMIOUEJArticlesCell class] forContent:[WFCCArticlesMessageContent class]];
    
    // 自定义群公告消息 1130
    [self registerCell:[YUBWOIJWDAnnouncementCell class] forContent:[WFCCAnnouncementMessageContent class]];
    
    
    
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"FooterView"];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    // voip: ongoingCallTableView removed
}

- (void)registerCell:(Class)cellCls forContent:(Class)msgContentCls {
    [self.collectionView registerClass:cellCls
            forCellWithReuseIdentifier:[NSString stringWithFormat:@"%d", [msgContentCls getContentType]]];
    [self.cellContentDict setObject:cellCls forKey:@([msgContentCls getContentType])];
}

- (void)removeUserTyping:(NSString *)userId {
    [self.typingDict removeObjectForKey:userId];
    [self showTyping];
}

- (void)showUser:(NSString *)userId typing:(WFCCTypingType)typingType {
    int64_t now = [[[NSDate alloc] init] timeIntervalSince1970];
    [self.typingDict setValue:@{@"timestamp":@(now), @"type":@(typingType)} forKey:userId];
    [self showTyping];
}

- (void)showTyping {
    if(self.conversation.type == Channel_Type || self.conversation.type == Chatroom_Type) {
        return;
    }
    
    if (self.showTypingTimer) {
        [self.showTypingTimer invalidate];
    }
    self.showTypingTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(checkUserTyping) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:self.showTypingTimer forMode:NSDefaultRunLoopMode];
    
    if(self.typingDict.count == 1) {
        NSString *userId = self.typingDict.allKeys[0];
        NSDictionary *dict = self.typingDict[userId];
        WFCCTypingType typingType = [dict[@"type"] intValue];
        WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:userId inGroup:self.conversation.type == Group_Type?self.conversation.target:nil];
        NSString *name = @"有人";
        if (userInfo.finalName.length > 0) {
            name = userInfo.finalName;
        } else if(userInfo.alias.length) {
            name = userInfo.alias;
        } else if(userInfo.groupAlias.length) {
            name = userInfo.groupAlias;
        } else if(userInfo.displayName.length) {
            name = userInfo.displayName;
        }
        
        NSString *title;
        if(typingType == Typing_VOICE) {
            title = _isChinese?@"对方正在录音...":@"The other party is recording...";
        } else if(typingType == Typing_CAMERA) {
            title = _isChinese?@"对方正在拍照...":@"The other party is taking a picture";
        } else if(typingType == Typing_LOCATION) {
            title = _isChinese?@"对方正在选取位置...":@"The other party is selecting a location";
        } else if(typingType == Typing_FILE) {
            title = _isChinese?@"对方正在选取文件...":@"The other party is selecting a file";
        } else {
            title = _isChinese?@"对方正在输入...":@"The other party is entering...";
        }
        if (_isShowInputState == 1) {
            _onlineLabel.text = title;
        }
        //        self.navigationItem.title = [NSString stringWithFormat:@"%@ %@", name, title];
    } else if(self.typingDict.count > 1) {
        if (_isShowInputState == 1) {
            _onlineLabel.text = [NSString stringWithFormat:@"%ld%@",self.typingDict.count, (_isChinese?@"人正在输入":@" people are entering")];
        }
        //        self.navigationItem.title = [NSString stringWithFormat:@"%ld人正在输入", self.typingDict.count];
    }
}

- (void)checkUserTyping {
    NSMutableArray<NSString *> *expiredKeys = [[NSMutableArray alloc] init];
    int64_t now = [[[NSDate alloc] init] timeIntervalSince1970];
//    NSLog(@"now====%lld",now);
//    NSLog(@"typingDict====%@",self.typingDict);
    [self.typingDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary * _Nonnull obj, BOOL * _Nonnull stop) {
        int64_t timestamp = [obj[@"timestamp"] longLongValue];
        if(now - timestamp > 5) {
            [expiredKeys addObject:key];
        }
    }];
    [self.typingDict removeObjectsForKeys:expiredKeys];
    
    if (self.typingDict.count) {
        [self showTyping];
    } else {
        [self stopShowTyping];
        if (_saveOnlineText) {
            _onlineLabel.text = _saveOnlineText;
        }
    }
}

- (void)stopShowTyping {
    if (self.showTypingTimer != nil) {
        [self.showTypingTimer invalidate];
        self.showTypingTimer = nil;
        if (self.conversation.type == Single_Type || self.conversation.type == SecretChat_Type) {
            self.targetUser = self.targetUser;
        } else if(self.conversation.type == Group_Type) {
            self.targetGroup = self.targetGroup;
            self.groupExtraInfo = [GroupExtraInfo mj_objectWithKeyValues:self.targetGroup.extra];
        } else if(self.conversation.type == Channel_Type) {
            self.targetChannel = self.targetChannel;
        } else if(self.conversation.type == Group_Type) {
            self.targetGroup = self.targetGroup;
            self.groupExtraInfo = [GroupExtraInfo mj_objectWithKeyValues:self.targetGroup.extra];
        }
    }
}

- (void)onResetKeyboard:(id)sender {
    [self.chatInputBar resetInputBarStatue];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"count=====%ld",_topMessages.count);
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
//    _isManager = ([self isGroupOwner] || [self isGroupManager:userId]); // 0227
    if (!self.firstAppear) {
        [self.chatInputBar willAppear];
    }
    
    self.tabBarController.tabBar.hidden = YES;
    BOOL needReloadOnAppear = NO;
    
    if (self.navigationController.viewControllers.count > 1) {          // 记录系统返回手势的代理
        _scrollBackDelegate = self.navigationController.interactivePopGestureRecognizer.delegate;          // 设置系统返回手势的代理为当前控制器
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
    
    if (self.conversation.type == Group_Type) {
        BOOL showAlias = ![[WFCCIMService sharedWFCIMService] isHiddenGroupMemberName:self.targetGroup.target];
        if (self.showAlias != showAlias) {
            self.showAlias = showAlias;
            needReloadOnAppear = YES;
        }
    }
    
    if (needReloadOnAppear) {
        [self.collectionView reloadData];
    }
    
    if (self.firstAppear) {
        self.firstAppear = NO;
        [self scrollToBottom:NO];
    }
    [self updateTitle];
    
    self.isInChat = YES;
    [self startQueryReadStatusTimer];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([WFCCIMService.sharedWFCIMService isEnableSyncDraft]) {
        NSString *newDraft = self.chatInputBar.draft;
        if (![self.orignalDraft isEqualToString:newDraft]) {
            self.orignalDraft = newDraft;
            [[WFCCIMService sharedWFCIMService] setConversation:self.conversation draft:newDraft];
        }
    }
    // 设置系统返回手势的代理为我们刚进入控制器的时候记录的系统的返回手势代理
    self.navigationController.interactivePopGestureRecognizer.delegate = _scrollBackDelegate;
    
    [self.chatInputBar resetInputBarStatue];
    
    self.isInChat = NO;
    [self.readStatusTimer invalidate];
    self.readStatusTimer = nil;
    [self updateReadTime];
}


    // voip: onReceiveCallOngoingNotifications removed

- (void)onReceiveMessages:(NSNotification *)notification {
    NSLog(@"收到新的消息=======通知1==");
    if ((_conversation.type == Single_Type) && (_isShowInputState)) {
        if (_saveOnlineText) {
            _onlineLabel.text = _saveOnlineText;
        }
    }
    NSArray<WFCCMessage *> *messages = notification.object;
    if ([self shouldRefreshOnlineStateForReceivedMessages:messages]) {
        [self queryOtherDevice];
    }
    [self appendMessages:messages newMessage:YES highlightId:0 forceButtom:NO];
    
    // voip: ongoingCalls removed
    
    BOOL isActivelyViewingConversation = self.isInChat &&
        UIApplication.sharedApplication.applicationState == UIApplicationStateActive;
    BOOL hasIncomingMessageInCurrentConversation = NO;
    NSString *currentUserId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    for (WFCCMessage *message in messages) {
        if ([message.conversation isEqual:self.conversation] &&
            message.direction == MessageDirection_Receive &&
            ![message.fromUser isEqualToString:currentUserId]) {
            hasIncomingMessageInCurrentConversation = YES;
            break;
        }
    }
    if (isActivelyViewingConversation && hasIncomingMessageInCurrentConversation) {
        [[WFCCIMService sharedWFCIMService] clearUnreadStatus:self.conversation];
        if (self.conversation.type == Single_Type) {
            [self updateReadTime];
        }
    }
}

// 撤回的通知消息
- (void)onRecallMessages:(NSNotification *)notification {
    NSLog(@"回撤=======通知2==");
    long long messageUid = [notification.object longLongValue];
    if (self.conversation.type != Chatroom_Type) {
        WFCCMessage *msg = [[WFCCIMService sharedWFCIMService] getMessageByUid:messageUid];
        if (msg != nil) {
            for (int i = 0; i < self.modelList.count; i++) {
                AIOIUEHMessageModel *model = [self.modelList objectAtIndex:i];
                if (model.message.messageUid == messageUid) {
                    model.message = msg;
                    if ([model.message.content isKindOfClass:NSClassFromString(@"WFCCRecallMessageContent")]) { // 0415
                        continue;
                    }
                    [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]]];
                    break;
                }
            }
        }
    } else {
        for (int i = 0; i < self.modelList.count; i++) {
            AIOIUEHMessageModel *model = [self.modelList objectAtIndex:i];
            if (model.message.messageUid == messageUid) {
                WFCCRecallMessageContent *recallContent = [[WFCCRecallMessageContent alloc] init];
                recallContent.messageUid = messageUid;
                recallContent.operatorId = model.message.fromUser;
                recallContent.originalSender = model.message.fromUser;
                model.message.content = recallContent;
                
                [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]]];
                break;
            }
        }
    }
}

- (void)onDeleteMessages:(NSNotification *)notification {
    NSLog(@"删除=======通知3==");
    long long messageUid = [notification.object longLongValue];
    
    NSInteger indexToDelete = NSNotFound;
    for (int i = 0; i < self.modelList.count; i++) {
        AIOIUEHMessageModel *model = self.modelList[i];
        if (model.message.messageUid == messageUid) {
            indexToDelete = i;
            break;
        }
    }

    if (indexToDelete != NSNotFound) {
        [self.collectionView performBatchUpdates:^{
            [self.modelList removeObjectAtIndex:indexToDelete];
            [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexToDelete inSection:0]]];
        } completion:nil];
    }
}

/**
 发送消息
 
 conversation 会话
 content 消息内容
 toUsers 在会话中只发给该用户，如果为空则发到会话中
 expireDuration 消息的有效期，0不限期，单位秒
 successBlock 成功的回调
 errorBlock 失败的回调
 消息实体
 */
- (void)sendMessage:(WFCCMessageContent *)content {
    //发送消息时，client会发出"kSendingMessageStatusUpdated“的通知，消息界面收到通知后加入到列表中。
    __weak typeof(self) ws = self;
    NSMutableArray *tousers = nil;
    if (self.privateChatUser) {
        tousers = [[NSMutableArray alloc] init];
        [tousers addObject:self.privateChatUser];
    }
    [[WFCCIMService sharedWFCIMService] send:self.conversation content:content toUsers:tousers expireDuration:0 success:^(long long messageUid, long long timestamp) {
        NSLog(@"发送消息成功==");
        if ([content isKindOfClass:[WFCCStickerMessageContent class]]) {
            [ws saveStickerRemoteUrl:(WFCCStickerMessageContent *)content];
        }
        if (![content isKindOfClass:[WFCCTypingMessageContent class]]) {
            [ws.chatInputBar resetTyping];
        }
        //        for (AIOIUEHMessageModel *msg in _modelList) {
        //            NSLog(@"0000======%@",msg.message.toJsonObj);
        //        }
        
        if ([content isKindOfClass:NSClassFromString(@"WFCCImageMessageContent")] ||
            [content isKindOfClass:NSClassFromString(@"WFCCVideoMessageContent")]) {
            //            WFCCImageMessageContent *imgContent = (WFCCImageMessageContent *)[WFCCIMService.sharedWFCIMService getMessageByUid:messageUid].content;
            [ws.collectionView reloadData];
        }
    } error:^(int error_code) {
        if (error_code == ERROR_CODE_NOT_RIGHT) { // 删除好友后、发送消息会失败
            if (![[WFCCIMService sharedWFCIMService] isMyFriend:ws.conversation.target]) {
                // 不是好友、弹出添加好友的top view  未做
                
            }
        } else if (error_code == 500) {
            //好友已被删除
            [ws.view makeToast:LLLLLL(@"ChatSendFailedDeleted") duration:1 position:CSToastPositionCenter];
        } else if (error_code == 501) {
            //已被拉黑
            [ws.view makeToast:LLLLLL(@"ChatSendFailedBlocked") duration:1 position:CSToastPositionCenter];
        }
        if ([content isKindOfClass:[WFCCStickerMessageContent class]]) {
            [ws removeLocalStickerPreviewForContent:(WFCCStickerMessageContent *)content];
        }
        //        ERROR_CODE_NOT_IN_GROUP
        NSLog(@"发送消息失败==(%d)", error_code);
    }];
}
/** messageUid = 0的原因在这儿、   messageUid一直没有值
 修改方式：在WFCCIMService 3759行添加一个判断 if (![content.class isEqual:NSClassFromString(@"WFCCImageMessageContent")])
 不确定会不会导致其他的问题。
 */
- (void)onMessageUpdated:(NSNotification *)notification {
    NSLog(@"MessageUpdated=======通知8==");
    
    long messageId = [notification.object longValue];
    BOOL isUpdated = NO;
    for (AIOIUEHMessageModel *model in self.modelList) {
        if (model.message.messageId == messageId) {
            if (model.message.conversation.type != Chatroom_Type) {
                WFCCMessage *message = [[WFCCIMService sharedWFCIMService] getMessage:messageId];
                if (message.messageUid != 0) { // 不加判断会导致该条消息的messageUid = 0
                    model.message = message;
                    isUpdated = YES;
                }
            }
            break;
        }
    }
    
    if(isUpdated) {
        [self sortMessageModelsAndRefreshTimeLabels];
        [self.collectionView reloadData];
    }
}

- (void)onMessageDelivered:(NSNotification *)notification {
    NSLog(@"Jian=======通知4==");
    if (self.conversation.type != Single_Type && self.conversation.type != Group_Type && self.conversation.type != SecretChat_Type) {
        return;
    }
    
    NSArray<WFCCGroupMember *> *members = nil;
    if (self.conversation.type == Group_Type) {
        members = [[WFCCGroupDB sharedManager] getGroupMembers:self.conversation.target];
    }
    
    NSArray<WFCCDeliveryReport *> *delivereds = notification.object;
    __block BOOL refresh = NO;
    [delivereds enumerateObjectsUsingBlock:^(WFCCDeliveryReport * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (self.conversation.type == Single_Type) {
            if ([self.conversation.target isEqualToString:obj.userId]) {
                *stop = YES;
                refresh = YES;
            }
        } else if (self.conversation.type == Group_Type) {
            for (WFCCGroupMember *member in members) {
                if ([member.memberId isEqualToString:obj.userId]) {
                    *stop = YES;
                    refresh = YES;
                }
            }
        } else if(self.conversation.type == SecretChat_Type) {
            NSString *userId = self.secretChatInfo.userId;
            if ([userId isEqualToString:obj.userId]) {
                *stop = YES;
                refresh = YES;
            }
        }
    }];
    
    if (refresh) {
        self.deliveryDict = [[WFCCIMService sharedWFCIMService] getMessageDelivery:self.conversation];
        WFCCGroupInfo *groupInfo = nil;
        
        for (int i = 0; i < self.modelList.count; i++) {
            AIOIUEHMessageModel *model  = self.modelList[i];
            model.deliveryDict = self.deliveryDict;
            if (model.message.direction == MessageDirection_Receive || model.deliveryRate == 1.f) {
                continue;
            }
            
            if (self.conversation.type == Single_Type || self.conversation.type == SecretChat_Type) {
                NSString *userId = model.message.conversation.target;
                if(self.conversation.type == SecretChat_Type) {
                    userId = self.secretChatInfo.userId;
                }
                if (model.message.serverTime <= [[model.deliveryDict objectForKey:userId] longLongValue]) {
                    float rate = 1.f;
                    if (rate != model.deliveryRate) {
                        model.deliveryRate = rate;
                        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]]];
                    }
                }
            } else { //group
                long long messageTS = model.message.serverTime;
                __block int delieveriedCount = 0;
                [model.deliveryDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
                    if ([obj longLongValue] >= messageTS) {
                        delieveriedCount++;
                    }
                }];
                
                if (!groupInfo) {
                    groupInfo = [[WFCCGroupDB sharedManager] getGroupInfoFromDB:model.message.conversation.target];
                }
                
                float rate = (float)delieveriedCount/(groupInfo.memberCount - 1);
                if (rate != model.deliveryRate) {
                    model.deliveryRate = rate;
                    [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]]];
                }
            }
        }
    }
}
// 消息的已读回调
- (void)onMessageReaded:(NSNotification *)notification {
    NSLog(@"Jian=======通知5==");
    if (self.conversation.type != Single_Type && self.conversation.type != Group_Type && self.conversation.type != SecretChat_Type) {
        return;
    }
    
    NSArray<WFCCReadReport *> *readeds = notification.object;
    __block BOOL refresh = NO;
    [readeds enumerateObjectsUsingBlock:^(WFCCReadReport * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.conversation isEqual:self.conversation]) {
            *stop = YES;
            refresh = YES;
        }
    }];
    
    
    //    2ygqmws2k = 1702972764378;
    //    rygqmws2k = 1702972764378;
    //    yygqmws2k = 1702543605611;
    if (refresh) {
        // 获取会话内已读状态    会话的每个用户已读时间
        self.readDict = [[WFCCIMService sharedWFCIMService] getConversationRead:self.conversation];
        //        NSLog(@"readDict===%@",self.readDict);
        if(self.conversation.type == Group_Type) {
            NSArray<WFCCGroupMember *> *members = [[WFCCGroupDB sharedManager] getGroupMembers:self.conversation.target];
            NSMutableArray<NSString *> *tobeRemoveKeys = [[NSMutableArray alloc] init];
            [self.readDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
                BOOL exist = NO;
                for (WFCCGroupMember *member in members) {
                    if([member.memberId isEqualToString:key]) {
                        exist = YES;
                    }
                }
                
                if(!exist) {
                    [tobeRemoveKeys addObject:key];
                }
            }];
            [self.readDict removeObjectsForKeys:tobeRemoveKeys];
        }
        
        WFCCGroupInfo *groupInfo = nil;
        
        for (int i = 0; i < self.modelList.count; i++) {
            AIOIUEHMessageModel *model  = self.modelList[i];
            model.readDict = self.readDict;
            if (model.message.direction == MessageDirection_Receive || model.readRate == 1.f) {
                continue;
            }
            
            if (self.conversation.type == Single_Type || self.conversation.type == SecretChat_Type) {
                NSString *userId = model.message.conversation.target;
                if(self.conversation.type == SecretChat_Type) {
                    userId = self.secretChatInfo.userId;
                }
                if (model.message.serverTime <= [[model.readDict objectForKey:userId] longLongValue]) {
                    float rate = 1.f;
                    if (rate != model.readRate) {
                        model.readRate = rate;
                        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]]];
                    }
                }
            } else { //group
                long long messageTS = model.message.serverTime;
                __block int delieveriedCount = 0;
                [model.readDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
                    if ([obj longLongValue] >= messageTS) {
                        delieveriedCount++;
                    }
                }];
                
                if (!groupInfo) {
                    groupInfo = [[WFCCGroupDB sharedManager] getGroupInfoFromDB:model.message.conversation.target];
                }
                
                float rate = (float)delieveriedCount/(groupInfo.memberCount - 1);
                if (rate != model.readRate) {
                    model.readRate = rate;
                    [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]]];
                }
            }
        }
    }
}

    // voip: onCallStateChanged removed

// 1===选择视频后    发送消息状态更新
- (void)onSendingMessage:(NSNotification *)notification {
    NSLog(@"图片视频=======通知6==");
    WFCCMessage *message = [notification.userInfo objectForKey:@"message"];
    WFCCMessageStatus status = [[notification.userInfo objectForKey:@"status"] integerValue];
    if (status == Message_Status_Sending && message.messageId != 0) {
        if ([message.conversation isEqual:self.conversation]) {
            if ([message.content isKindOfClass:[WFCCStickerMessageContent class]]) {
                if ([self updateLocalStickerPreviewWithMessage:message]) {
                    return;
                }
            }
            [self appendMessages:@[message] newMessage:YES highlightId:0 forceButtom:YES];
        }
    }
}

- (void)onMessageListChanged:(NSNotification *)notification {
    NSLog(@"Jian=======通知7==");
    if([notification.object isEqual:self.conversation]) {
        [self reloadMessageList];
    }
}

- (void)onSettingUpdated:(NSNotification *)notification {
    NSLog(@"Jian=======通知11==");
    WFCCConversationInfo *info = [[WFCCIMService sharedWFCIMService] getConversationInfo:self.conversation];
    NSString *orignalDraftText = [self.chatInputBar getDraftText:self.orignalDraft];
    NSString *draftText = [self.chatInputBar getDraftText:info.draft];
    if(![orignalDraftText isEqualToString:draftText]) {
        self.orignalDraft = info.draft;
        self.chatInputBar.draft = info.draft;
    }
}

- (void)onSecretChatStateChanged:(NSNotification *)notification {
    NSLog(@"Jian=======通知13==");
    if(self.conversation.type == SecretChat_Type && [self.conversation.target isEqualToString:notification.object]) {
        self.secretChatInfo = [[WFCCIMService sharedWFCIMService] getSecretChatInfo:self.conversation.target];
        
        WFCCSecretChatState state = (WFCCSecretChatState)[notification.userInfo[@"state"] intValue];
        if(state == SecretChatState_Canceled) {
            [self.navigationController popToRootViewControllerAnimated:YES];
        } else {
            [self reloadMessageList];
        }
    }
}

- (void)onSecretMessageBurned:(NSNotification *)notification {
    NSLog(@"Jian=======通知15==");
    if(self.conversation.type == SecretChat_Type) {
        NSArray *messageIds = notification.userInfo[@"messageIds"];
        NSMutableArray *deletedModels = [[NSMutableArray alloc] init];
        NSMutableArray *deletedItems = [[NSMutableArray alloc] init];
        [self.modelList enumerateObjectsUsingBlock:^(AIOIUEHMessageModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if([messageIds containsObject:@(obj.message.messageId)]) {
                [deletedModels addObject:obj];
                [deletedItems addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
            }
        }];
        
        [self.modelList removeObjectsInArray:deletedModels];
        [self.collectionView deleteItemsAtIndexPaths:deletedItems];
    }
}

- (void)onSecretMessageStartBurning:(NSNotification *)notification {
    NSLog(@"Jian=======通知14==");
    if(self.conversation.type == SecretChat_Type) {
        NSString *targetId = (NSString *)notification.object;
        if(targetId.length) {
            //普通消息开始计时阅后即焚
        } else {
            long long playedMsgUid = [notification.userInfo[@"messageId"] longLongValue];
            for (int i = 0; i < self.modelList.count; ++i) {
                AIOIUEHMessageModel *model = self.modelList[i];
                if(model.message.messageUid == playedMsgUid) {
                    //媒体类消息开始阅后即焚
                }
            }
        }
    }
}

- (void)reloadMessageList {
    self.deliveryDict = [[WFCCIMService sharedWFCIMService] getMessageDelivery:self.conversation];
    if (self.conversation.type == Single_Type && !self.hasLoadedPeerReadStatus) {
        self.readDict = [NSMutableDictionary dictionary];
    } else {
        self.readDict = [[WFCCIMService sharedWFCIMService] getConversationRead:self.conversation];
    }
    //    NSLog(@"readDict===%@",self.readDict);
    NSArray *messageList;
    if (self.highlightMessageId > 0) {
        NSArray *messageListOld = [[WFCCIMService sharedWFCIMService] getMessages:self.conversation contentTypes:nil from:self.highlightMessageId+1 count:15 withUser:self.privateChatUser];
        NSArray *messageListNew = [[WFCCIMService sharedWFCIMService] getMessages:self.conversation contentTypes:nil from:self.highlightMessageId count:-15 withUser:self.privateChatUser];
        NSMutableArray *list = [[NSMutableArray alloc] init];
        [list addObjectsFromArray:messageListNew];
        [list addObjectsFromArray:messageListOld];
        messageList = [list copy];
        [[WFCCIMService sharedWFCIMService] clearUnreadStatus:self.conversation];
        if (messageListNew.count == 15) {
            self.hasNewMessage = YES;
        }
        self.modelList = [[NSMutableArray alloc] init];
        
        [self appendMessages:messageList newMessage:NO highlightId:self.highlightMessageId forceButtom:NO];
        self.highlightMessageId = 0;
        
        if(self.conversation.type == SecretChat_Type) {
            WFCCSecretChatInfo *secretChatInfo = [[WFCCIMService sharedWFCIMService] getSecretChatInfo:self.conversation.target];
            if(secretChatInfo.state == SecretChatState_Established) {
                if(self.chatInputBar.inputBarStatus == ChatInputBarMuteStatus) {
                    self.chatInputBar.inputBarStatus = ChatInputBarDefaultStatus;
                }
            } else {
                if(self.chatInputBar.inputBarStatus != ChatInputBarMuteStatus) {
                    self.chatInputBar.inputBarStatus = ChatInputBarMuteStatus;
                }
            }
        }
    } else {
        BOOL firstIn = NO;
        int count = (int)self.modelList.count;
        if(count == 0) {
            firstIn = YES;
        }
        count = 15;
        __weak typeof(self)ws = self;
        [[WFCCIMService sharedWFCIMService] getMessagesV2:self.conversation contentTypes:nil from:0 count:count withUser:self.privateChatUser success:^(NSArray<WFCCMessage *> *messages) {
            [[WFCCIMService sharedWFCIMService] getMessagesV2:ws.conversation messageStatus:@[@(Message_Status_Mentioned), @(Message_Status_AllMentioned)] from:0 count:100 withUser:ws.privateChatUser success:^(NSArray<WFCCMessage *> *messages) {
                ws.mentionedMsgs = [messages mutableCopy];
                if (ws.mentionedMsgs.count) {
                    [ws showMentionedLabel];
                }
            } error:^(int error_code) {
                
            }];
            
            if (firstIn) {
                WFCCConversationInfo *info = [[WFCCIMService sharedWFCIMService] getConversationInfo:ws.conversation];
                if (info.unreadCount.unread >= 10 && info.unreadCount.unread < 300) { //如果消息太多了就没有必要显示新消息了
                    ws.unreadMessageCount = info.unreadCount.unread;
                    ws.firstUnreadMessageId = [[WFCCIMService sharedWFCIMService] getFirstUnreadMessageId:ws.conversation];
                    [ws showUnreadLabel];
                }
                [[WFCCIMService sharedWFCIMService] clearUnreadStatus:ws.conversation];
            }
            
            ws.modelList = [[NSMutableArray alloc] init];
            //            for (WFCCMessage *msg in messages) {
            //                NSLog(@"msg==%@==%@",msg, msg.toJsonObj);
            //                msg.content.type
            //            }
            // 首次的值
            [ws appendMessages:messages newMessage:NO highlightId:ws.highlightMessageId forceButtom:NO];
            ws.highlightMessageId = 0;
            
            if(ws.conversation.type == SecretChat_Type) {
                WFCCSecretChatInfo *secretChatInfo = [[WFCCIMService sharedWFCIMService] getSecretChatInfo:ws.conversation.target];
                if(secretChatInfo.state == SecretChatState_Established) {
                    if(ws.chatInputBar.inputBarStatus == ChatInputBarMuteStatus) {
                        ws.chatInputBar.inputBarStatus = ChatInputBarDefaultStatus;
                    }
                } else {
                    if(ws.chatInputBar.inputBarStatus != ChatInputBarMuteStatus) {
                        ws.chatInputBar.inputBarStatus = ChatInputBarMuteStatus;
                    }
                }
            }
        } error:^(int error_code) {
            
        }];
        return;
    }
}

- (void)showMentionedLabel {
    if (!self.mentionedButton) {
        CGRect bount = self.view.bounds;
        self.mentionedButton = [[UIButton alloc] initWithFrame:CGRectMake(bount.size.width+15, 240, 0, 30)];
        self.mentionedButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [self.mentionedButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        self.mentionedButton.backgroundColor = [UIColor whiteColor];
        self.mentionedButton.layer.cornerRadius = 15;
        self.mentionedButton.layer.borderColor = [UIColor blackColor].CGColor;
        [self.mentionedButton addTarget:self action:@selector(onMentionedBtn:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.mentionedButton];
        [UIView animateWithDuration:0.8 animations:^{
            self.mentionedButton.frame = CGRectMake(bount.size.width - 85, 240, 100, 30);
        }];
    }
    [self.mentionedButton setTitle:[NSString stringWithFormat:@"%lu %@", self.mentionedMsgs.count, (_isChinese?@"条消息":@"messages")] forState:UIControlStateNormal];
}

- (void)dismissMentionedLabel {
    CGRect bount = self.view.bounds;
    [UIView animateWithDuration:0.5 animations:^{
        self.mentionedButton.frame = CGRectMake(bount.size.width+15, 240, 0, 30);
    } completion:^(BOOL finished) {
        [self.mentionedButton removeFromSuperview];
        self.mentionedButton = nil;
    }];
}

- (void)onMentionedBtn:(id)sender {
    if (![self checkLastMentionedMsgLoaded]) {
        [self loadMoreToLastMention];
    } else {
        [self scrollToLastMentionedMessage];
    }
}

- (void)loadMoreToLastMention {
    __weak typeof(self)ws = self;
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
    [self loadMoreMessage:YES completion:^(BOOL more){
        if (more && ![ws checkLastMentionedMsgLoaded]) {
            [ws loadMoreToLastMention];
        } else {
            [ws scrollToLastMentionedMessage];
        }
    }];
}

- (void)scrollToLastMentionedMessage {
    for (int i = 0; i < self.modelList.count; i++) {
        if (self.modelList[i].message.messageId == self.mentionedMsgs.firstObject.messageId) {
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
        }
    }
}

- (BOOL)checkLastMentionedMsgLoaded {
    for (AIOIUEHMessageModel *model in self.modelList) {
        if (model.message.messageId == self.mentionedMsgs.firstObject.messageId) {
            return YES;
        }
    }
    return NO;
}

- (void)showUnreadLabel {
    CGRect bount = self.view.bounds;
    self.tzboeuUnreadButton = [[UIButton alloc] initWithFrame:CGRectMake(bount.size.width+15, 200, 0, 30)];
    [self.tzboeuUnreadButton setTitle:[NSString stringWithFormat:@"%d %@",self.unreadMessageCount, (_isChinese?@"条新消息":@"new messages")] forState:UIControlStateNormal];
    self.tzboeuUnreadButton.titleLabel.font = [UIFont systemFontOfSize:12];
    [self.tzboeuUnreadButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    self.tzboeuUnreadButton.backgroundColor = [UIColor whiteColor];
    self.tzboeuUnreadButton.layer.cornerRadius = 15;
    self.tzboeuUnreadButton.layer.borderColor = [UIColor blackColor].CGColor;
    [self.tzboeuUnreadButton addTarget:self action:@selector(onUnreadBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.tzboeuUnreadButton];
    [UIView animateWithDuration:0.6 animations:^{
        self.tzboeuUnreadButton.frame = CGRectMake(bount.size.width - 85, 200, 100, 30);
    }];
}

- (void)dismissUnreadLabel {
    CGRect bount = self.view.bounds;
    [UIView animateWithDuration:0.5 animations:^{
        self.tzboeuUnreadButton.frame = CGRectMake(bount.size.width+15, 200, 0, 30);
    } completion:^(BOOL finished) {
        [self.tzboeuUnreadButton removeFromSuperview];
        self.tzboeuUnreadButton = nil;
    }];
}

- (void)onUnreadBtn:(id)sender {
    [self dismissUnreadLabel];
    if (![self checkFirstUnreadMsgLoaded]) {
        [self loadMoreToFirstUnread];
    } else {
        [self scrollToFirstUnreadMessage];
    }
}
- (BOOL)checkFirstUnreadMsgLoaded {
    for (AIOIUEHMessageModel *model in self.modelList) {
        if (model.message.messageId <= self.firstUnreadMessageId) {
            return YES;
        }
    }
    return NO;
}
- (void)loadMoreToFirstUnread {
    __weak typeof(self)ws = self;
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
    [self loadMoreMessage:YES completion:^(BOOL more){
        if (more && ![ws checkFirstUnreadMsgLoaded]) {
            [ws loadMoreToFirstUnread];
        } else {
            [ws scrollToFirstUnreadMessage];
        }
    }];
}
- (void)scrollToFirstUnreadMessage {
    for (int i = 0; i < self.modelList.count; i++) {
        if (self.modelList[i].message.messageId == self.firstUnreadMessageId) {
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
        }
    }
}


#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.modelList.count) { // 0226新增 处理“筛选通知消息的显示”导致的奔溃
        return CGSizeZero;
    }
    AIOIUEHMessageModel *model = self.modelList[indexPath.row];
    Class cellCls = self.cellContentDict[@([[model.message.content class] getContentType])];
    if (!cellCls) {
        cellCls = self.cellContentDict[@([[WFCCUnknownMessageContent class] getContentType])];
    }
    return [cellCls sizeForCell:model withViewWidth:self.collectionView.frame.size.width];
}

/**
 //通知消息类型
 //创建群的通知消息
 #define MESSAGE_CONTENT_TYPE_CREATE_GROUP 104
 //加群的通知消息
 #define MESSAGE_CONTENT_TYPE_ADD_GROUP_MEMBER 105
 
 WFCCGroupSetManagerNotificationContent // 设置/取消群管理员通知消息
 WFCCGroupMuteNotificationContent //  群禁言的通知消息 - 全员禁言
 WFCCKickoffGroupMemberVisibleNotificationContent // 群组踢人的通知消息
 WFCCKickoffGroupMemberNotificationContent // 群组踢人的通知消息
 WFCCGroupMemberMuteNotificationContent // 群成员被禁言的通知消息
 
 
 WFCCChangeGroupNameNotificationContent // 修改群名的通知消息
 WFCCChangeGroupPortraitNotificationContent // 修改群头像的通知消息
 WFCCModifyGroupAliasNotificationContent // 群成员修改群昵称的通知消息
 WFCCModifyGroupMemberExtraNotificationContent // 群成员修改群附加信息的通知消息
 WFCCModifyGroupExtraNotificationContent //              群成员修改群附加信息的通知消息
 
 WFCCGroupMemberAllowNotificationContent // 群成员禁言被允许的通知消息
 WFCCGroupPrivateChatNotificationContent // 建私有群的通知消息
 WFCCGroupJoinTypeNotificationContent // 建群的通知消息
 WFCCQuitGroupVisibleNotificationContent // 退群的通知消息
 WFCCGroupSettingsNotificationContent // 群设置的通知消息
 
 */
- (BOOL)filteringData:(AIOIUEHMessageModel *)model { // 返回NO 不添加该条数据
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    if (self.conversation.type == Single_Type) {
        if (_isChinese) {
            
        }else {
            if ([_conversation.target isEqualToString:@"FireRobot"] || [_conversation.target isEqualToString:@"wfc_file_transfer"]) {
                if ([model.message.content isKindOfClass:NSClassFromString(@"WFCCTextMessageContent")]) {
                    WFCCTextMessageContent *content = (WFCCTextMessageContent *)model.message.content;
                    if ([content.text containsString:@"我是官方客服"]) {
                        content.text = @"Hello, I am the official customer service! You can talk to me.";
                    }
                    if ([content.text containsString:@"我是文件传输助手"]) {
                        content.text = @"Hello, I'm a file transfer assistant";
                    }
                }
            }
        }
    }
    if (self.conversation.type != Group_Type) {
        return YES;
    }
    
    //    NSLog(@"modelList2===%@",model.message.mj_JSONObject);
//        NSLog(@"contentClass===%@",NSStringFromClass(model.message.content.class));
    
    if ([model.message.content isKindOfClass:NSClassFromString(@"WFCCGroupSetManagerNotificationContent")]) { // 设置/取消群管理员的通知消息
        // 仅群主和管理员可见
        if ([self isManager]) {
            return YES;
        }
        // 通过model.message.messageUid值进行删除   批量删除 batchDeleteMessages
        [self deleteLocalMessage:model.message.messageId];
        return NO;
    }else if ([model.message.content isKindOfClass:NSClassFromString(@"WFCCGroupMuteNotificationContent")] || // 群禁言的通知消息 - 全禁言
              [model.message.content isKindOfClass:NSClassFromString(@"WFCCGroupPrivateChatNotificationContent")] || // 这几个都是建群的通知消息
              [model.message.content isKindOfClass:NSClassFromString(@"WFCCGroupJoinTypeNotificationContent")]) {
        return YES;
    }
    else if ([model.message.content isKindOfClass:NSClassFromString(@"WFCCRecallMessageContent")]) { // 0415
        // 群聊内，管理员撤回消息提示是全员可见，需要改为仅管理员/群主可见
        WFCCRecallMessageContent *content = (WFCCRecallMessageContent *)model.message.content;
        //        NSLog(@"operatorId===%@",content.operatorId);
        
        //当群主在群内撤回消息时，无需提示XX撤回了消息 0811
        if ([self.targetGroup.owner isEqualToString:content.operatorId]) {
            [self deleteLocalMessage:model.message.messageId];
            return NO;
        }
        
        // 该撤回消息的是群主或者管理员  仅管理员和群主可见
        if ([self.targetGroup.owner isEqualToString:content.operatorId] || [self isGroupManager:content.operatorId]) {
            if ([self isManager]) { // 仅管理员和群主可见
                return YES;
            }else {
                [self deleteLocalMessage:model.message.messageId];
                return NO;
            }
        }else { // 普通用户撤回的消息，任何人都可见-->不做更改
            return YES;
        }
    }
    else if ([model.message.content isKindOfClass:NSClassFromString(@"WFCCKickoffGroupMemberNotificationContent")] ||
             [model.message.content isKindOfClass:NSClassFromString(@"WFCCKickoffGroupMemberVisibleNotificationContent")]) { // 群组踢人的通知消息
        if ([self isManager]) { // 群主和管理员可以正常看到
            return YES;
        }
        if ([model.message.content isKindOfClass:NSClassFromString(@"WFCCKickoffGroupMemberNotificationContent")]) {
            WFCCKickoffGroupMemberNotificationContent *content = (WFCCKickoffGroupMemberNotificationContent *)model.message.content;
            for (NSString *userid in content.kickedMembers) {
                if ([userid isEqualToString:userId]) {
                    return YES;
                }
            }
        }else {
            WFCCKickoffGroupMemberVisibleNotificationContent *content = (WFCCKickoffGroupMemberVisibleNotificationContent *)model.message.content;
            for (NSString *userid in content.kickedMembers) {
                if ([userid isEqualToString:userId]) {
                    return YES;
                }
            }
        }
        [self deleteLocalMessage:model.message.messageId];
        return NO;
    }else if ([model.message.content isKindOfClass:NSClassFromString(@"WFCCGroupMemberMuteNotificationContent")]) { // 群成员被禁言
        if ([self isManager]) { // 群主和管理员可以正常看到
            return YES;
        }
        WFCCGroupMemberMuteNotificationContent *content = (WFCCGroupMemberMuteNotificationContent *)model.message.content;
        for (NSString *userid in content.targetIds) {
            if ([userid isEqualToString:userId]) {
                return YES;
            }
        }
        [self deleteLocalMessage:model.message.messageId];
        return NO;
    }else if ([model.message.content isKindOfClass:NSClassFromString(@"WFCCGroupMemberAllowNotificationContent")]) { // 群成员禁言被允许的通知消息
        if ([self isManager]) { // 群主和管理员可以正常看到
            return YES;
        }
        WFCCGroupMemberAllowNotificationContent *content = (WFCCGroupMemberAllowNotificationContent *)model.message.content;
        for (NSString *userid in content.targetIds) {
            if ([userid isEqualToString:userId]) {
                return YES;
            }
        }
        [self deleteLocalMessage:model.message.messageId];
        return NO;
    }else if ([model.message.content isKindOfClass:NSClassFromString(@"WFCCQuitGroupVisibleNotificationContent")] ||
              [model.message.content isKindOfClass:NSClassFromString(@"WFCCQuitGroupNotificationContent")]) { // 退群的通知消息
        if ([self isManager]) { // 群主和管理员可以正常看到
            return YES;
        }
        [self deleteLocalMessage:model.message.messageId];
        return NO;
    }else if ([model.message.content isKindOfClass:NSClassFromString(@"WFCCChangeGroupNameNotificationContent")] ||
              [model.message.content isKindOfClass:NSClassFromString(@"WFCCChangeGroupPortraitNotificationContent")] ||
              [model.message.content isKindOfClass:NSClassFromString(@"WFCCModifyGroupAliasNotificationContent")] ||
              [model.message.content isKindOfClass:NSClassFromString(@"WFCCModifyGroupMemberExtraNotificationContent")] ||
              [model.message.content isKindOfClass:NSClassFromString(@"WFCCModifyGroupExtraNotificationContent")] ||
              [model.message.content isKindOfClass:NSClassFromString(@"WFCCGroupSettingsNotificationContent")]) { //
        if ([self isManager]) { // 群主和管理员可以正常看到
            return YES;
        }
        [self deleteLocalMessage:model.message.messageId];
        return NO;
    }
    
    return YES;
}
- (void)appendMessages:(NSArray<WFCCMessage *> *)messages newMessage:(BOOL)newMessage highlightId:(long)highlightId forceButtom:(BOOL)forceButtom {
    if (messages.count == 0) {
        return;
    }
    
    int count = 0;
    NSMutableArray *modifiedAliasUsers = [[NSMutableArray alloc] init];
    for (int i = 0; i < messages.count; i++) {
        WFCCMessage *message = [messages objectAtIndex:i];
        
        if (![message.conversation isEqual:self.conversation]) {
            continue;
        }
        
        if ([message.content isKindOfClass:[WFCCTypingMessageContent class]] && message.direction == MessageDirection_Receive) {
            WFCCTypingMessageContent *content = (WFCCTypingMessageContent *)message.content;
            [self showUser:message.fromUser typing:content.type];
            continue;
        }
        
        if(message.direction == MessageDirection_Receive) {
            [self removeUserTyping:message.fromUser];
        }
        
        if (message.messageId == 0) {
            continue;
        }
        if (message.messageId > 0 &&
            [message.content isKindOfClass:[WFCCStickerMessageContent class]] &&
            [self updateLocalStickerPreviewWithMessage:message]) {
            continue;
        }
        BOOL duplcated = NO;
        for (AIOIUEHMessageModel *model in self.modelList) {
            if (model.message.messageUid !=0 && model.message.messageUid == message.messageUid) {
                model.message.content = message.content;
                duplcated = YES;
                break;
            }
            if(message.messageId && message.messageId == model.message.messageId) {
                model.message.content = message.content;
                duplcated = YES;
                break;
            }
        }
        //        if (duplcated) { // 0415注销
        //            continue;
        //        }
        //        count++;
        
        if (duplcated) {
            if ([message.content isKindOfClass:NSClassFromString(@"WFCCRecallMessageContent")]) { // 0415新增
                BOOL showTime = YES;
                if (self.modelList.count > 0 && (message.serverTime -  (self.modelList[self.modelList.count - 1]).message.serverTime < 60 * 1000)) {
                    showTime = NO;
                }
                AIOIUEHMessageModel *model = [AIOIUEHMessageModel modelOf:message showName:message.direction == MessageDirection_Receive && self.showAlias showTime:showTime];
                [self filteringData:model];
            }
            
            continue;
        }
        
        count++;
        
        if (newMessage) {
            BOOL showTime = YES;
            if (self.modelList.count > 0 && (message.serverTime -  (self.modelList[self.modelList.count - 1]).message.serverTime < 60 * 1000)) {
                showTime = NO;
            }
            AIOIUEHMessageModel *model = [AIOIUEHMessageModel modelOf:message showName:message.direction == MessageDirection_Receive && self.showAlias showTime:showTime];
            if ([self filteringData:model] == NO) { // 0226新增 用于筛选通知消息的显示
                continue;
            }
            model.selecting = self.multiSelecting;
            model.selected = [self.selectedMessageIds containsObject:@(message.messageId)];
            model.deliveryDict = self.deliveryDict;
            model.readDict = self.readDict;
            [self.modelList addObject:model];
            if (self.conversation.type == Group_Type && [message.content isKindOfClass:[WFCCModifyGroupAliasNotificationContent class]]) {
                [modifiedAliasUsers addObject:message.fromUser];
            }
            
            [self.nMsgSet addObject:@(message.messageId)];
        } else {
            if (self.modelList.count > 0 && (self.modelList[0].message.serverTime - message.serverTime < 60 * 1000) && i != 0) {
                self.modelList[0].showTimeLabel = NO;
            }
            AIOIUEHMessageModel *model = [AIOIUEHMessageModel modelOf:message showName:message.direction == MessageDirection_Receive&&self.showAlias showTime:YES];
            if ([self filteringData:model] == NO) { // 0226新增 用于筛选通知消息的显示
                continue;
            }
            if (self.firstUnreadMessageId && message.messageId == self.firstUnreadMessageId) {
                model.lastReadMessage = YES;
            }
            model.selecting = self.multiSelecting;
            model.selected = [self.selectedMessageIds containsObject:@(message.messageId)];
            model.deliveryDict = self.deliveryDict;
            model.readDict = self.readDict;
            [self.modelList insertObject:model atIndex:0];
        }
    }
    
    if (count > 0) {
        [self stopShowTyping];
    }
    [self sortMessageModelsAndRefreshTimeLabels];
//    for (AIOIUEHMessageModel *model in self.modelList) {
//        NSLog(@"modelList1===%@",model.message.mj_JSONObject);
//        NSLog(@"modelList2===%@",model.message.toJsonObj);
//    }
//    NSLog(@"Count=====%ld====",self.modelList.count);
    [self.collectionView reloadData];
    
    if (newMessage || self.modelList.count == messages.count) {
        if(self.isAtButtom) {
            forceButtom = true;
        }
    } else {
        CGFloat offset = 0;
        for (int i = 0; i < count; i++) {
            CGSize size = [self collectionView:self.collectionView layout:self.collectionView.collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            offset += size.height;
        }
        self.collectionView.contentOffset = CGPointMake(0, offset);
        
        [UIView animateWithDuration:0.2 animations:^{
            self.collectionView.contentOffset = CGPointMake(0, offset - 20);
        }];
    }
    
    if (highlightId > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            int row = 0;
            for (int i = 0; i < self.modelList.count; i++) {
                AIOIUEHMessageModel *model = self.modelList[i];
                if (model.message.messageId == highlightId) {
                    row = i;
                    model.highlighted = YES;
                    break;
                }
            }
            if ([self.collectionView.indexPathsForVisibleItems containsObject:[NSIndexPath indexPathForRow:row inSection:0]]) {
                [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]]];
            } else {
                [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
            }
        });
    } else if (forceButtom) {
        [self scrollToBottom:YES];
    }
    
    if (modifiedAliasUsers.count) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSArray<NSIndexPath *> *visibleItems = self.collectionView.indexPathsForVisibleItems;
            NSMutableArray *needUpdateItems = [[NSMutableArray alloc] init];
            for (NSIndexPath *item in visibleItems) {
                AIOIUEHMessageModel *model = [self.modelList objectAtIndex:item.row];
                if ([modifiedAliasUsers containsObject:model.message.fromUser]) {
                    [needUpdateItems addObject:item];
                }
            }
            if (needUpdateItems.count) {
                [self.collectionView reloadItemsAtIndexPaths:needUpdateItems];
            }
        });
        
    }
    
    if (newMessage && !self.isAtButtom && self.nMsgSet.count > 0) {
        [self showNewMsgTip];
    } else {
        [self dismissNewMsgTip];
    }
}

- (void)sortMessageModelsAndRefreshTimeLabels {
    NSMutableDictionary<NSNumber *, NSNumber *> *orderMap = [[NSMutableDictionary alloc] init];
    [self.modelList enumerateObjectsUsingBlock:^(AIOIUEHMessageModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        orderMap[@((uintptr_t)obj)] = @(idx);
    }];
    
    [self.modelList sortUsingComparator:^NSComparisonResult(AIOIUEHMessageModel *obj1, AIOIUEHMessageModel *obj2) {
        if (obj1.message.serverTime > obj2.message.serverTime) {
            return NSOrderedDescending;
        }
        if (obj1.message.serverTime < obj2.message.serverTime) {
            return NSOrderedAscending;
        }
        
        NSNumber *leftIndex = orderMap[@((uintptr_t)obj1)];
        NSNumber *rightIndex = orderMap[@((uintptr_t)obj2)];
        if (leftIndex.integerValue > rightIndex.integerValue) {
            return NSOrderedDescending;
        }
        if (leftIndex.integerValue < rightIndex.integerValue) {
            return NSOrderedAscending;
        }
        
        return NSOrderedSame;
    }];
    
    AIOIUEHMessageModel *previousModel = nil;
    for (AIOIUEHMessageModel *model in self.modelList) {
        model.showTimeLabel = YES;
        if (previousModel && (model.message.serverTime - previousModel.message.serverTime < 60 * 1000)) {
            model.showTimeLabel = NO;
        }
        previousModel = model;
    }
}
/** 该方法备份一份
 - (void)appendMessages:(NSArray<WFCCMessage *> *)messages newMessage:(BOOL)newMessage highlightId:(long)highlightId forceButtom:(BOOL)forceButtom {
 if (messages.count == 0) {
 return;
 }
 
 int count = 0;
 NSMutableArray *modifiedAliasUsers = [[NSMutableArray alloc] init];
 for (int i = 0; i < messages.count; i++) {
 WFCCMessage *message = [messages objectAtIndex:i];
 
 if (![message.conversation isEqual:self.conversation]) {
 continue;
 }
 
 if ([message.content isKindOfClass:[WFCCTypingMessageContent class]] && message.direction == MessageDirection_Receive) {
 WFCCTypingMessageContent *content = (WFCCTypingMessageContent *)message.content;
 [self showUser:message.fromUser typing:content.type];
 continue;
 }
 
 if(message.direction == MessageDirection_Receive) {
 [self removeUserTyping:message.fromUser];
 }
 
 if (message.messageId == 0) {
 continue;
 }
 BOOL duplcated = NO;
 for (AIOIUEHMessageModel *model in self.modelList) {
 if (model.message.messageUid !=0 && model.message.messageUid == message.messageUid) {
 model.message.content = message.content;
 duplcated = YES;
 break;
 }
 if(message.messageId && message.messageId == model.message.messageId) {
 model.message.content = message.content;
 duplcated = YES;
 break;
 }
 }
 if (duplcated) {
 continue;
 }
 
 count++;
 
 if (newMessage) {
 BOOL showTime = YES;
 if (self.modelList.count > 0 && (message.serverTime -  (self.modelList[self.modelList.count - 1]).message.serverTime < 60 * 1000)) {
 showTime = NO;
 }
 AIOIUEHMessageModel *model = [AIOIUEHMessageModel modelOf:message showName:message.direction == MessageDirection_Receive && self.showAlias showTime:showTime];
 model.selecting = self.multiSelecting;
 model.selected = [self.selectedMessageIds containsObject:@(message.messageId)];
 model.deliveryDict = self.deliveryDict;
 model.readDict = self.readDict;
 [self.modelList addObject:model];
 if (self.conversation.type == Group_Type && [message.content isKindOfClass:[WFCCModifyGroupAliasNotificationContent class]]) {
 [modifiedAliasUsers addObject:message.fromUser];
 }
 
 [self.nMsgSet addObject:@(message.messageId)];
 } else {
 if (self.modelList.count > 0 && (self.modelList[0].message.serverTime - message.serverTime < 60 * 1000) && i != 0) {
 self.modelList[0].showTimeLabel = NO;
 }
 AIOIUEHMessageModel *model = [AIOIUEHMessageModel modelOf:message showName:message.direction == MessageDirection_Receive&&self.showAlias showTime:YES];
 if (self.firstUnreadMessageId && message.messageId == self.firstUnreadMessageId) {
 model.lastReadMessage = YES;
 }
 model.selecting = self.multiSelecting;
 model.selected = [self.selectedMessageIds containsObject:@(message.messageId)];
 model.deliveryDict = self.deliveryDict;
 model.readDict = self.readDict;
 [self.modelList insertObject:model atIndex:0];
 }
 }
 
 if (count > 0) {
 [self stopShowTyping];
 }
 //    for (AIOIUEHMessageModel *model in self.modelList) {
 //        NSLog(@"modelList2===%@",model.message.mj_JSONObject);
 //        if ([model.message.content isKindOfClass:NSClassFromString(@"WFCCGroupSetManagerNotificationContent")]) { // 设置/取消群管理员通知消息
 //            [self.modelList removeObject:model];
 //        }
 //    }
 
 [self.collectionView reloadData];
 
 if (newMessage || self.modelList.count == messages.count) {
 if(self.isAtButtom) {
 forceButtom = true;
 }
 } else {
 CGFloat offset = 0;
 for (int i = 0; i < count; i++) {
 CGSize size = [self collectionView:self.collectionView layout:self.collectionView.collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
 offset += size.height;
 }
 self.collectionView.contentOffset = CGPointMake(0, offset);
 
 [UIView animateWithDuration:0.2 animations:^{
 self.collectionView.contentOffset = CGPointMake(0, offset - 20);
 }];
 }
 
 if (highlightId > 0) {
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
 int row = 0;
 for (int i = 0; i < self.modelList.count; i++) {
 AIOIUEHMessageModel *model = self.modelList[i];
 if (model.message.messageId == highlightId) {
 row = i;
 model.highlighted = YES;
 break;
 }
 }
 if ([self.collectionView.indexPathsForVisibleItems containsObject:[NSIndexPath indexPathForRow:row inSection:0]]) {
 [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]]];
 } else {
 [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
 }
 });
 } else if (forceButtom) {
 [self scrollToBottom:YES];
 }
 
 if (modifiedAliasUsers.count) {
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
 NSArray<NSIndexPath *> *visibleItems = self.collectionView.indexPathsForVisibleItems;
 NSMutableArray *needUpdateItems = [[NSMutableArray alloc] init];
 for (NSIndexPath *item in visibleItems) {
 AIOIUEHMessageModel *model = [self.modelList objectAtIndex:item.row];
 if ([modifiedAliasUsers containsObject:model.message.fromUser]) {
 [needUpdateItems addObject:item];
 }
 }
 if (needUpdateItems.count) {
 [self.collectionView reloadItemsAtIndexPaths:needUpdateItems];
 }
 });
 
 }
 
 if (newMessage && !self.isAtButtom && self.nMsgSet.count > 0) {
 [self showNewMsgTip];
 } else {
 [self dismissNewMsgTip];
 }
 }
 */

- (void)showNewMsgTip {
    [self.newMsgTipButton setTitle:[NSString stringWithFormat:@"%ld", self.nMsgSet.count] forState:UIControlStateNormal];
    self.newMsgTipButton.hidden = NO;
}

- (void)dismissNewMsgTip {
    [self.nMsgSet removeAllObjects];
    _newMsgTipButton.hidden = YES;
}

- (UIButton *)newMsgTipButton {
    if (!_newMsgTipButton) {
        _newMsgTipButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 36, self.chatInputBar.frame.origin.y - 40, 24, 24)];
        _newMsgTipButton.layer.cornerRadius = 12;
        _newMsgTipButton.titleLabel.font = [UIFont systemFontOfSize:8];
        _newMsgTipButton.layer.borderColor = [UIColor blackColor].CGColor;
        _newMsgTipButton.backgroundColor = [UIColor blueColor];
        [_newMsgTipButton addTarget:self action:@selector(onNewMsgTipBtn:) forControlEvents:UIControlEventTouchUpInside];
        [_newMsgTipButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.backgroundView addSubview:_newMsgTipButton];
    }
    return _newMsgTipButton;;
}
- (void)onNewMsgTipBtn:(id)sender {
    self.isAtButtom = YES;
    [self scrollToBottom:YES];
}
- (AIOIUEHMessageModel *)modelOfMessage:(long)messageId {
    if (messageId == 0) {
        return nil;
    }
    for (AIOIUEHMessageModel *model in self.modelList) {
        if (model.message.messageId == messageId) {
            return model;
        }
    }
    return nil;
}

- (void)stopPlayer {
    if (self.player && [self.player isPlaying]) {
        [self.player stop];
        if ([self.playTimer isValid]) {
            [self.playTimer invalidate];
            self.playTimer = nil;
        }
    }
    [self modelOfMessage:self.playingMessageId].voicePlaying = NO;
    self.playingMessageId = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:kVoiceMessagePlayStoped object:nil];
}

-(void)prepardToPlay:(AIOIUEHMessageModel *)model {
    
    if (self.playingMessageId == model.message.messageId) {
        [self stopPlayer];
    } else {
        [self stopPlayer];
        
        self.playingMessageId = model.message.messageId;
        
        WFCCSoundMessageContent *soundContent = (WFCCSoundMessageContent *)model.message.content;
        if (soundContent.localPath.length == 0 || ![AIOIUEHUtilities isFileExist:soundContent.localPath]) {
            __weak typeof(self) weakSelf = self;
            
            BOOL isDownloading = [[AIOIUEHMediaMessageDownloader sharedDownloader] tryDownload:model.message success:^(long long messageUid, NSString *localPath) {
                model.mediaDownloading = NO;
                [weakSelf startPlay:model];
            } error:^(long long messageUid, int error_code) {
                model.mediaDownloading = NO;
            }];
            
            if (isDownloading) {
                model.mediaDownloading = YES;
            }
            
        } else {
            [self startPlay:model];
        }
        
    }
}

-(void)startPlay:(AIOIUEHMessageModel *)model {
    if(model.message.conversation.type == SecretChat_Type) {
        [[WFCCIMService sharedWFCIMService] setMediaMessagePlayed:model.message.messageId];
        model.message.status = Message_Status_Played;
        [self.collectionView reloadData];
    }
    
    if ([model.message.content isKindOfClass:[WFCCSoundMessageContent class]]) {
        // Setup audio session
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
        
        [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker
                                   error:nil];
        
        
        
        WFCCSoundMessageContent *snc = (WFCCSoundMessageContent *)model.message.content;
        NSError *error = nil;
        if(model.message.conversation.type == SecretChat_Type) {
            NSData *data = [NSData dataWithContentsOfFile:snc.localPath];
            data = [[WFCCIMService sharedWFCIMService] decodeSecretChat:model.message.conversation.target mediaData:data];
            if (![@"mp3" isEqualToString:[snc.localPath pathExtension]]) {
                NSString *cacheDir = [[AIOIUEHConfigManager globalManager] cachePathOf:model.message.conversation mediaType:0];
                NSString *savedPath = [cacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"media_%lld_tmp", model.message.messageUid]];
                [data writeToFile:savedPath atomically:YES];
                data = [[WFCCIMService sharedWFCIMService] getWavData:savedPath];
                [[NSFileManager defaultManager] removeItemAtPath:savedPath error:nil];
            }
            self.player = [[AVAudioPlayer alloc] initWithData:data error:&error];
        } else {
            self.player = [[AVAudioPlayer alloc] initWithData:[snc getWavData] error:&error];
        }
        [self.player setDelegate:self];
        [self.player prepareToPlay];
        [self.player play];
        model.voicePlaying = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:kVoiceMessageStartPlaying object:@(self.playingMessageId)];
    } else if([model.message.content isKindOfClass:[WFCCVideoMessageContent class]]) {
        [self.view makeToast:@"视频播放已关闭"];
        return;
    }
    
}


#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.modelList.count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AIOIUEHMessageModel *model = nil;
    if(indexPath.row < self.modelList.count) {
        model = self.modelList[indexPath.row];
    }
//    NSString *objName = [NSString stringWithFormat:@"%d", [model.message.content.class getContentType]];
    //    NSLog(@"objName======%@\n====%@",objName, _cellContentDict);
    
    NSNumber *contentTypeKey = @([model.message.content.class getContentType]);

    SMIOUEJMessageCellBase *cell = nil;
    if (!self.cellContentDict[contentTypeKey]) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:[NSString stringWithFormat:@"%ld", (long)[WFCCUnknownMessageContent getContentType]] forIndexPath:indexPath];
    } else {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:[contentTypeKey stringValue] forIndexPath:indexPath];
    }
    
//    if(![self.cellContentDict objectForKey:@([model.message.content.class getContentType])]) {
//        cell = [collectionView dequeueReusableCellWithReuseIdentifier:[NSString stringWithFormat:@"%d", [WFCCUnknownMessageContent getContentType]] forIndexPath:indexPath];
//    } else {
//        cell = [collectionView dequeueReusableCellWithReuseIdentifier:objName forIndexPath:indexPath];
//    }
    
    cell.delegate = self;
    
//    [[NSNotificationCenter defaultCenter] removeObserver:cell];
    cell.model = model;
    
    return cell;
}

- (UICollectionReusableView *) collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
//    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
//        if(!self.headerView) {
//            self.headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
//            self.headerActivityView.center = CGPointMake(self.headerView.bounds.size.width/2, self.headerView.bounds.size.height/2);
//            [self.headerView addSubview:self.headerActivityView];
//        }
//        return self.headerView;
//    } else {
//        if(!self.footerView) {
//            self.footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"FooterView" forIndexPath:indexPath];
//            self.footerActivityView.center = CGPointMake(self.footerView.bounds.size.width/2, self.footerView.bounds.size.height/2);
//            [self.footerView addSubview:self.footerActivityView];
//        }
//        return self.footerView;
//    }
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        self.headerActivityView.center = CGPointMake(headerView.bounds.size.width / 2, headerView.bounds.size.height / 2);
        [headerView addSubview:self.headerActivityView];
        return headerView;
    } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        UICollectionReusableView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"FooterView" forIndexPath:indexPath];
        self.footerActivityView.center = CGPointMake(footerView.bounds.size.width / 2, footerView.bounds.size.height / 2);
        [footerView addSubview:self.footerActivityView];
        return footerView;
    }
    return nil;
}

#pragma mark -UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    AIOIUEHMessageModel *model = self.modelList[indexPath.row];
    
    if (self.mentionedMsgs.count) {
        for (WFCCMessage *msg in self.mentionedMsgs) {
            if (msg.messageId == model.message.messageId) {
                [self.mentionedMsgs removeObject:msg];
                if (!self.mentionedMsgs.count) {
                    [self dismissMentionedLabel];
                } else {
                    [self showMentionedLabel];
                }
                break;
            }
        }
    }
    
    if (self.unreadMessageCount) {
        if (self.firstUnreadMessageId >= model.message.messageId) {
            self.unreadMessageCount = 0;
            self.firstUnreadMessageId = 0;
            [self dismissUnreadLabel];
        }
    }
    
    if (self.nMsgSet.count) {
        if ([self.nMsgSet containsObject:@(model.message.messageId)]) {
            [self.nMsgSet removeObject:@(model.message.messageId)];
            if (self.nMsgSet.count) {
                [self showNewMsgTip];
            } else {
                [self dismissNewMsgTip];
            }
        }
    }
}

#pragma mark - MessageCellDelegate  --  点击消息内容实现的方法 didSelect
- (void)didTapMessageCell:(SMIOUEJMessageCellBase *)cell withModel:(AIOIUEHMessageModel *)model {
    if ([model.message.content isKindOfClass:[WFCCAnnouncementMessageContent class]]) { // 1130新增。公告点击事件
        
        DUVOHJNGroupAnnouncement *ann = [[DUVOHJNGroupAnnouncement alloc] init];
        ann.groupId = self.conversation.target;
        ann.author = model.message.fromUser;
        ann.text = [(WFCCAnnouncementMessageContent *)model.message.content text];
        ann.timestamp = model.message.serverTime;
        
        YUBWOIJWDGroupAnnouncementVC *vc = [[YUBWOIJWDGroupAnnouncementVC alloc] init];
        vc.isCanPost = NO;
        vc.announcement = ann;
        if ([self.targetGroup.owner isEqualToString:ann.author]) {
            vc.type = Member_Type_Owner;
        }
        if ([self isGroupManager:ann.author]) {
            vc.type = Member_Type_Manager;
        }
        [self.navigationController pushViewController:vc animated:YES];
        
    }else if ([model.message.content isKindOfClass:[WFCCImageMessageContent class]] || [model.message.content isKindOfClass:[WFCCVideoMessageContent class]]) {
        if(self.conversation.type == SecretChat_Type) {
            typeof(self) ws = self;
            __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.label.text = LLLLLL(@"Loading");
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                WFCCMediaMessageContent *mediaContent = (WFCCMediaMessageContent *)model.message.content;
                NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:mediaContent.remoteUrl]];
                data = [[WFCCIMService sharedWFCIMService] decodeSecretChat:model.message.conversation.target mediaData:data];
                if([model.message.content isKindOfClass:[WFCCImageMessageContent class]]) {
                    UIImage *image = [UIImage imageWithData:data];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if(image) {
                            [[WFCCIMService sharedWFCIMService] setMediaMessagePlayed:model.message.messageId];
                            [hud hideAnimated:YES];
                            JUAHODJNKImagePreviewViewController *previewVC = [[JUAHODJNKImagePreviewViewController alloc] init];
                            previewVC.image = image;
                            [ws.navigationController presentViewController:previewVC animated:YES completion:nil];
                        } else {
                            hud.mode = MBProgressHUDModeText;
                            hud.label.text = LLLLLL(@"LoadFailure");
                            [hud hideAnimated:YES afterDelay:1.f];
                        }
                    });
                } else {
                    //Todo play video
                }
            });
        } else {
            if (self.conversation.type == Chatroom_Type) {
                NSMutableArray *imageMsgs = [[NSMutableArray alloc] init];
                for (AIOIUEHMessageModel *msgModle in self.modelList) {
                    if ([msgModle.message.content isKindOfClass:[WFCCImageMessageContent class]] || [msgModle.message.content isKindOfClass:[WFCCVideoMessageContent class]]) {
                        [imageMsgs addObject:msgModle.message];
                    }
                }
                self.imageMsgs = imageMsgs;
            } else { // 获取图片、视频相关消息
                self.imageMsgs = [[WFCCIMService sharedWFCIMService] getMessages:self.conversation contentTypes:@[@(MESSAGE_CONTENT_TYPE_IMAGE), @(MESSAGE_CONTENT_TYPE_VIDEO)] from:0 count:100000 withUser:self.privateChatUser];
            }
            self.imageMsgs = [self.imageMsgs sortedArrayUsingComparator:^NSComparisonResult(WFCCMessage  * obj1, WFCCMessage  * obj2) {
                return obj1.serverTime >= obj2.serverTime;
            }];
            
            int i;
            for (i = 0; i < self.imageMsgs.count; i++) {
                if ([self.imageMsgs objectAtIndex:i].messageId == model.message.messageId) {
                    break;
                }
            }
            if (i == self.imageMsgs.count) {
                i = 0;
            }
            // 点击视频触发的地方  视频视频
            MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
            browser.displayActionButton = YES;
            browser.displayNavArrows = NO;
            browser.displaySelectionButtons = NO;
            browser.alwaysShowControls = NO;
            browser.zoomPhotosToFill = NO;
            browser.enableGrid = YES;
            browser.startOnGrid = NO;
            browser.enableSwipeToDismiss = NO;
            if([model.message.content isKindOfClass:[WFCCVideoMessageContent class]]) {
                browser.autoPlayOnAppear = YES;
            } else {
                browser.autoPlayOnAppear = NO;
            }
            //            typeof(self) ws = self;
            [browser setScanResult:^(NSString *strScanned) {
                [gQrCodeDelegate handleUrl:strScanned withNav:self.navigationController];
            }];
            [browser setCurrentPhotoIndex:i];
            [self.navigationController pushViewController:browser animated:YES];
        }
    } else if([model.message.content isKindOfClass:[WFCCSoundMessageContent class]]) {
        if (model.message.direction == MessageDirection_Receive && model.message.status != Message_Status_Played) {
            if(model.message.conversation.type != SecretChat_Type) {
                [[WFCCIMService sharedWFCIMService] setMediaMessagePlayed:model.message.messageId];
                model.message.status = Message_Status_Played;
                if ([self.collectionView indexPathForCell:cell]) {
                    [self.collectionView reloadItemsAtIndexPaths:@[[self.collectionView indexPathForCell:cell]]];
                }
            }
        }
        
        [self prepardToPlay:model];
    } else if ([model.message.content isKindOfClass:[WFCCLocationMessageContent class]]) {
        WFCCLocationMessageContent *locContent = (WFCCLocationMessageContent *)model.message.content;
        WDCARLocationViewController *vc = [[WDCARLocationViewController alloc] initWithLocationPoint:[[WDCARLocationPoint alloc] initWithCoordinate:locContent.coordinate andTitle:locContent.title]];
        [self.navigationController pushViewController:vc animated:YES];
    } else if ([model.message.content isKindOfClass:[WFCCFileMessageContent class]]) {
        WFCCFileMessageContent *fileContent = (WFCCFileMessageContent *)model.message.content;
        if (model.message.messageUid == 0) {
            //            NSLog(@"messageUid是空的空的空");
            return;
        }
        __weak typeof(self)ws = self;
        [[WFCCIMService sharedWFCIMService] getAuthorizedMediaUrl:model.message.messageUid mediaType:Media_Type_FILE mediaPath:fileContent.remoteUrl success:^(NSString *authorizedUrl, NSString *backupUrl) {
            JUAHODJNKBrowserVC *bvc = [[JUAHODJNKBrowserVC alloc] init];
            bvc.url = authorizedUrl;
            [ws.navigationController pushViewController:bvc animated:YES];
        } error:^(int error_code) {
            JUAHODJNKBrowserVC *bvc = [[JUAHODJNKBrowserVC alloc] init];
            bvc.url = fileContent.remoteUrl;
            [ws.navigationController pushViewController:bvc animated:YES];
        }];
    } else if ([model.message.content isKindOfClass:[WFCCCallStartMessageContent class]]) {
        // voip: didTouchVideoBtn removed
    } else if ([model.message.content isKindOfClass:[WFCCCardMessageContent class]]) { // 名片消息
        WFCCCardMessageContent *card = (WFCCCardMessageContent *)model.message.content;
        
        if (card.type == CardType_User) {
            WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:card.targetId];
            if (userInfo.deleted) {
                return;
            }
            
            BOOL isMyFriend = [[WFCCIMService sharedWFCIMService] isMyFriend:userInfo.userId]; // 本人与本人不是好友关系
            if (isMyFriend) { // 是好友关系
                RUJBVOGHUYMemberInfoVC *vc = RUJBVOGHUYMemberInfoVC.new;
                if (model.message.conversation.type == Group_Type) {
                    vc.groupId = model.message.conversation.target;
                }
                vc.userId = userInfo.userId;
                vc.isCardEnter = YES;
                [self.navigationController pushViewController:vc animated:YES];
            }else { // 本人或者 非好友关系
                RUJBVOGHUYFriendInfoVC *vc = RUJBVOGHUYFriendInfoVC.new;
//                if (model.message.conversation.type == Group_Type) {
//                    vc.groupId = model.message.conversation.target;
//                }
                vc.userId = card.targetId;
                vc.isCardEnter = YES;
                [self.navigationController pushViewController:vc animated:YES];
            }
        } else if (card.type == CardType_Group) {
            DUVOHJNGroupInfoVC *vc2 = [[DUVOHJNGroupInfoVC alloc] init];
            vc2.groupId = card.targetId;
            vc2.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc2 animated:YES];
        }
    } else if([model.message.content isKindOfClass:[WFCCCompositeMessageContent class]]) {
        AIOIUEHCompositeMessageVC *vc = [[AIOIUEHCompositeMessageVC alloc] init];
        vc.message = model.message;
        [self.navigationController pushViewController:vc animated:YES];
    } else if([model.message.content isKindOfClass:[WFCCLinkMessageContent class]]) {
        WFCCLinkMessageContent *content = (WFCCLinkMessageContent *)model.message.content;
        JUAHODJNKBrowserVC *bvc = [[JUAHODJNKBrowserVC alloc] init];
        bvc.url = content.url;
        [self.navigationController pushViewController:bvc animated:YES];
    } else if([model.message.content isKindOfClass:WFCCRichNotificationMessageContent.class]) {
        WFCCRichNotificationMessageContent *richNotification = (WFCCRichNotificationMessageContent *)model.message.content;
        if(richNotification.exUrl.length) {
            JUAHODJNKBrowserVC *bvc = [[JUAHODJNKBrowserVC alloc] init];
            bvc.url = richNotification.exUrl;
            [self.navigationController pushViewController:bvc animated:YES];
        }
    }
}

- (MBProgressHUD *)startProgress:(NSString *)text {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = text;
    [hud showAnimated:YES];
    return hud;
}

- (MBProgressHUD *)stopProgress:(MBProgressHUD *)hud finishText:(NSString *)text {
    [hud hideAnimated:YES];
    if(text) {
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = text;
        [hud hideAnimated:YES afterDelay:1.f];
    }
    return hud;
}

// 文本消息 双击进行放大处理
- (void)didDoubleTapMessageCell:(SMIOUEJMessageCellBase *)cell withModel:(AIOIUEHMessageModel *)model {
    if ([model.message.content isKindOfClass:[WFCCTextMessageContent class]]) {
        WFCCTextMessageContent *txtMsgContent = (WFCCTextMessageContent *)model.message.content;
        [self.chatInputBar resetInputBarStatue];
        
        UIView *textContainer = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        textContainer.backgroundColor = self.view.backgroundColor;
        
        UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, [AIOIUEHUtilities wf_navigationFullHeight], [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - [AIOIUEHUtilities wf_navigationFullHeight] - [AIOIUEHUtilities wf_safeDistanceBottom])];
        textView.text = txtMsgContent.text;
        textView.textAlignment = NSTextAlignmentCenter;
        textView.font = PINGFANG_M(26);
        textView.editable = NO;
        textView.backgroundColor = self.view.backgroundColor;
        
        [textContainer addSubview:textView];
        [textView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapTextMessageDetailView:)]];
        [[UIApplication sharedApplication].keyWindow addSubview:textContainer];
    }
}

- (void)didTapArticleCell:(SMIOUEJMessageCellBase *)cell withModel:(AIOIUEHMessageModel *)model withArticle:(WFCCArticle *)article {
    JUAHODJNKBrowserVC *bvc = [[JUAHODJNKBrowserVC alloc] init];
    bvc.url = article.url;
    [self.navigationController pushViewController:bvc animated:YES];
}

- (void)didTapTextMessageDetailView:(id)sender {
    if ([sender isKindOfClass:[UIGestureRecognizer class]]) {
        UIGestureRecognizer *gesture = (UIGestureRecognizer *)sender;
        [gesture.view.superview removeFromSuperview];
    }
    NSLog(@"close windows");
}

// 点击头像触发的事件
- (void)didTapMessagePortrait:(SMIOUEJMessageCellBase *)cell withModel:(AIOIUEHMessageModel *)model {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    if(self.conversation.type == Group_Type) {
        if (self.targetGroup.privateChat) {
            if (![self.targetGroup.owner isEqualToString:model.message.fromUser] && ![self.targetGroup.owner isEqualToString:userId]) {
                WFCCGroupMember *gm = [[WFCCGroupDB sharedManager] getGroupMember:self.conversation.target memberId:userId];
                if (gm.type != Member_Type_Manager) {
                    WFCCGroupMember *gm = [[WFCCGroupDB sharedManager] getGroupMember:self.conversation.target memberId:model.message.fromUser];
                    if (gm.type != Member_Type_Manager && ![self isManager]) {
                        [self.view makeToast:(_isChinese?@"管理员关闭了群组私聊权限":@"The administrator disables the group private chat permission") duration:1 position:CSToastPositionCenter];
                        return;
                    }
                }
            }
        }
    } else if (self.conversation.type == Channel_Type && model.message.direction == MessageDirection_Receive) { // 频道 & 接收方
        // 个人资料
        [self onRightBarBtn:nil];
        return;
    }
    
    WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:model.message.fromUser];
    if (!userInfo.deleted) {
        if ([userInfo.userId isEqualToString:@"FireRobot"] || [userInfo.userId isEqualToString:@"wfc_file_transfer"] || [userInfo.userId isEqualToString:@"customer_service"]) {
            return;
        }
        
        BOOL isMyFriend = [[WFCCIMService sharedWFCIMService] isMyFriend:userInfo.userId]; // 本人与本人不是好友关系
        if (isMyFriend) { // 是好友关系
            RUJBVOGHUYMemberInfoVC *vc = RUJBVOGHUYMemberInfoVC.new;
            if (model.message.conversation.type == Group_Type) {
                vc.groupId = model.message.conversation.target;
            }
            vc.userId = userInfo.userId;
            [self.navigationController pushViewController:vc animated:YES];
        }else { // 本人或者 非好友关系
            RUJBVOGHUYFriendInfoVC *vc = RUJBVOGHUYFriendInfoVC.new;
            if (model.message.conversation.type == Group_Type) {
                vc.groupId = model.message.conversation.target;
            }
            vc.userId = userInfo.userId;
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}

- (void)didLongPressMessageCell:(SMIOUEJMessageCellBase *)cell withModel:(AIOIUEHMessageModel *)model {
    if ([cell isKindOfClass:[SMIOUEJMessageCellBase class]]) {
        //        if (!self.isFirstResponder) {
        //            [self becomeFirstResponder];
        //        }
        
        [self displayMenu:(SMIOUEJMessageCellBase *)cell];
    }
}

- (void)didLongPressMessagePortrait:(SMIOUEJMessageCellBase *)cell withModel:(AIOIUEHMessageModel *)model {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    if (self.conversation.type == Group_Type) {
        if (model.message.direction == MessageDirection_Receive) {
            WFCCUserInfo *sender = [[WFCCUserDB sharedManager] getUserInfo:model.message.fromUser inGroup:self.conversation.target];
            NSString *userName = sender.alias.length ? sender.alias : sender.displayName;
            if (sender.groupAlias.length > 0) {
                userName = sender.groupAlias;
            }
            [self.chatInputBar appendMention:model.message.fromUser name:userName];
        }
    } else if(self.conversation.type == Channel_Type) {
        WFCCChannelInfo *channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:self.conversation.target refresh:NO];
        if ([channelInfo.owner isEqualToString:userId]) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:(_isChinese?@"与订阅者私聊":@"Chat privately with subscribers") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                if (model.message.direction == MessageDirection_Receive) {
                    WFCCChannelInfo *channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:self.conversation.target refresh:NO];
                    if ([channelInfo.owner isEqualToString:userId]) {
                        YUBWOIJWDMessageVC *mvc = [[YUBWOIJWDMessageVC alloc] init];
                        mvc.conversation = [WFCCConversation conversationWithType:self.conversation.type target:self.conversation.target line:self.conversation.line];
                        mvc.privateChatUser = model.message.fromUser;
                        [self.navigationController pushViewController:mvc animated:YES];
                    }
                }
                
            }];
            [alertController addAction:cancelAction];
            [alertController addAction:okAction];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }
}
- (void)didTapResendBtn:(AIOIUEHMessageModel *)model {
    NSInteger index = [self.modelList indexOfObject:model];
    if (index >= 0) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
        [self.modelList removeObjectAtIndex:index];
        [self.collectionView deleteItemsAtIndexPaths:@[path]];
        [[WFCCMessageDB sharedManager] deleteMessage:model.message.messageId];
        [self sendMessage:model.message.content];
    }
}
// 文本里面的链接、电话点击事件
- (void)didSelectUrl:(SMIOUEJMessageCellBase *)cell withModel:(AIOIUEHMessageModel *)model withUrl:(NSString *)urlString {
    NSString *trimmedUrlString = [urlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *normalizedUrlString = trimmedUrlString;
    if (normalizedUrlString.length && [normalizedUrlString rangeOfString:@"://"].location == NSNotFound) {
        normalizedUrlString = [@"https://" stringByAppendingString:normalizedUrlString];
    }

    if ([model.message.content.class isEqual:NSClassFromString(@"WFCCAnnouncementMessageContent")]) { // 群公告点击链接
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:urlString message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        WS(weakself)
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *openAction = [UIAlertAction actionWithTitle:LLLLLL(@"OpenTheLink") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            JUAHODJNKBrowserVC *bvc = [[JUAHODJNKBrowserVC alloc] init];
            bvc.url = normalizedUrlString;
            [weakself.navigationController pushViewController:bvc animated:YES];
        }];
        UIAlertAction *copyAction = [UIAlertAction actionWithTitle:LLLLLL(@"Copy") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = urlString;
            [SVProgressHUD showSuccessWithStatus:LLLLLL(@"CopySuccessfully")];
            [SVProgressHUD dismissWithDelay:1.0];
        }];
        [alertController addAction:cancelAction];
        [alertController addAction:openAction];
        [alertController addAction:copyAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }else {
        NSURL *url = [NSURL URLWithString:normalizedUrlString];
        if (url && [[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        }
//        JUAHODJNKBrowserVC *bvc = [[JUAHODJNKBrowserVC alloc] init];
//        bvc.url = normalizedUrlString;
//        [self.navigationController pushViewController:bvc animated:YES];
    }
}

- (void)didSelectPhoneNumber:(SMIOUEJMessageCellBase *)cell withModel:(AIOIUEHMessageModel *)model withPhoneNumber:(NSString *)phoneNumber {
    if(self.chatInputBar.inputBarStatus == ChatInputBarKeyboardStatus || self.chatInputBar.inputBarStatus == ChatInputBarEmojiStatus || self.chatInputBar.inputBarStatus == ChatInputBarPluginStatus) {
        self.chatInputBar.inputBarStatus = ChatInputBarDefaultStatus;
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:LLLLLL(@"PhoneNumberHint"), phoneNumber] message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *callAction = [UIAlertAction actionWithTitle:LLLLLL(@"Calls") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [UIApplication.sharedApplication openURL:URL(UNString(@"telprompt:%@", phoneNumber)) options:@{} completionHandler:nil];
    }];
    
    UIAlertAction *copyAction = [UIAlertAction actionWithTitle:LLLLLL(@"Copy") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = phoneNumber;
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:callAction];
    [alertController addAction:copyAction];
    //    [alertController addAction:addContactAction];
    [self presentViewController:alertController animated:YES completion:nil];
}
- (void)reeditRecalledMessage:(SMIOUEJMessageCellBase *)cell withModel:(AIOIUEHMessageModel *)model {
    WFCCRecallMessageContent *recall = (WFCCRecallMessageContent *)model.message.content;
    [self.chatInputBar appendText:recall.originalSearchableContent];
}

- (void)didTapReceiptView:(SMIOUEJMessageCellBase *)cell withModel:(AIOIUEHMessageModel *)model {
    DUVOHJNReceiptVC *receipt = [[DUVOHJNReceiptVC alloc] init];
    receipt.message = model.message;
    [self.navigationController pushViewController:receipt animated:YES];
}

// 点击内容引用  触发的事件   公告已实现
- (void)showQuote:(WFCCQuoteInfo *)quoteInfo ofMessage:(WFCCMessage *)msg {
    if ([msg.content isKindOfClass:[WFCCTextMessageContent class]]) {
        WFCCTextMessageContent *txtContent = (WFCCTextMessageContent *)msg.content;
        
        [self.chatInputBar resetInputBarStatue];
        
        UIView *textContainer = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        textContainer.backgroundColor = self.view.backgroundColor;
        
        UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, [AIOIUEHUtilities wf_navigationFullHeight], [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - [AIOIUEHUtilities wf_navigationFullHeight] - [AIOIUEHUtilities wf_safeDistanceBottom])];
        textView.text = txtContent.text;
        textView.textAlignment = NSTextAlignmentCenter;
        textView.font = [UIFont systemFontOfSize:28];
        textView.editable = NO;
        textView.backgroundColor = self.view.backgroundColor;
        
        [textContainer addSubview:textView];
        [textView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapTextMessageDetailView:)]];
        [[UIApplication sharedApplication].keyWindow addSubview:textContainer];
    } else if ([msg.content isKindOfClass:[WFCCImageMessageContent class]] || [msg.content isKindOfClass:[WFCCVideoMessageContent class]]) {
        self.imageMsgs = @[msg];
        MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
        browser.displayActionButton = YES;
        browser.displayNavArrows = NO;
        browser.displaySelectionButtons = NO;
        browser.alwaysShowControls = NO;
        browser.zoomPhotosToFill = YES;
        browser.enableGrid = NO;
        browser.startOnGrid = NO;
        browser.enableSwipeToDismiss = NO;
        browser.autoPlayOnAppear = NO;
        [browser setCurrentPhotoIndex:0];
        [self.navigationController pushViewController:browser animated:YES];
    } else if ([msg.content isKindOfClass:[WFCCLocationMessageContent class]]) {
        WFCCLocationMessageContent *locContent = (WFCCLocationMessageContent *)msg.content;
        WDCARLocationViewController *vc = [[WDCARLocationViewController alloc] initWithLocationPoint:[[WDCARLocationPoint alloc] initWithCoordinate:locContent.coordinate andTitle:locContent.title]];
        [self.navigationController pushViewController:vc animated:YES];
    } else if ([msg.content isKindOfClass:[WFCCFileMessageContent class]]) {
        WFCCFileMessageContent *fileContent = (WFCCFileMessageContent *)msg.content;
        
        __weak typeof(self)ws = self;
        [[WFCCIMService sharedWFCIMService] getAuthorizedMediaUrl:msg.messageUid mediaType:Media_Type_FILE mediaPath:fileContent.remoteUrl success:^(NSString *authorizedUrl, NSString *backupUrl) {
            JUAHODJNKBrowserVC *bvc = [[JUAHODJNKBrowserVC alloc] init];
            bvc.url = authorizedUrl;
            [ws.navigationController pushViewController:bvc animated:YES];
        } error:^(int error_code) {
            JUAHODJNKBrowserVC *bvc = [[JUAHODJNKBrowserVC alloc] init];
            bvc.url = fileContent.remoteUrl;
            [ws.navigationController pushViewController:bvc animated:YES];
        }];
    } else if ([msg.content isKindOfClass:[WFCCCardMessageContent class]]) {
        WFCCCardMessageContent *card = (WFCCCardMessageContent *)msg.content;
        
        if (card.type == CardType_User) {
            BOOL isMyFriend = [[WFCCIMService sharedWFCIMService] isMyFriend:card.targetId]; // 本人与本人不是好友关系
            if (isMyFriend) { // 是好友关系
                RUJBVOGHUYMemberInfoVC *vc = RUJBVOGHUYMemberInfoVC.new;
                vc.userId = card.targetId;
                vc.isCardEnter = YES;
                [self.navigationController pushViewController:vc animated:YES];
            }else { // 本人或者 非好友关系
                RUJBVOGHUYFriendInfoVC *vc = RUJBVOGHUYFriendInfoVC.new;
                vc.userId = card.targetId;
                vc.isCardEnter = YES;
                [self.navigationController pushViewController:vc animated:YES];
            }
        } else if(card.type == CardType_Group) {
            DUVOHJNGroupInfoVC *vc2 = [[DUVOHJNGroupInfoVC alloc] init];
            vc2.groupId = card.targetId;
            vc2.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc2 animated:YES];
        } // CardType_Channel removed
    } else if ([msg.content isKindOfClass:[WFCCAnnouncementMessageContent class]]) { // 1130新增 引用群公告引用
        //        WS(weakself)
        //        [[AIOIUEHConfigManager globalManager].appServiceProvider getGroupAnnouncement:self.conversation.target success:^(DUVOHJNGroupAnnouncement *announcement) {
        //            dispatch_async(dispatch_get_main_queue(), ^{
        //            });
        //        } error:^(int error_code) {
        //        }];
        
        DUVOHJNGroupAnnouncement *ann = [[DUVOHJNGroupAnnouncement alloc] init];
        ann.groupId = self.conversation.target;
        ann.author = msg.fromUser;
        ann.text = [(WFCCAnnouncementMessageContent *)msg.content text];
        ann.timestamp = msg.serverTime;
        
        YUBWOIJWDGroupAnnouncementVC *vc = [[YUBWOIJWDGroupAnnouncementVC alloc] init];
        vc.isCanPost = NO;
        vc.announcement = ann;
        if ([self.targetGroup.owner isEqualToString:ann.author]) {
            vc.type = Member_Type_Owner;
        }
        if ([self isGroupManager:ann.author]) {
            vc.type = Member_Type_Manager;
        }
        [self.navigationController pushViewController:vc animated:YES];
    }else {
        //有些消息内容不能在当前页面显示，跳转到新的页面显示
        //            if ([msg.content isKindOfClass:[WFCCSoundMessageContent class]])
        //            if ([msg.content isKindOfClass:[WFCCStickerMessageContent class]])
        //            if ([msg.content isKindOfClass:[WFCCVideoMessageContent class]])
        // 1120 空白页面
        //        AIOIUEHQuoteVC *vc = [[AIOIUEHQuoteVC alloc] init];
        //        vc.messageUid = msg.messageUid;
        //        [self.navigationController pushViewController:vc animated:YES];
        
    }
}
- (BOOL)isGroupOwner {
    if (self.conversation.type != Group_Type) {
        return false;
    }
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    return [self.targetGroup.owner isEqualToString:userId];
}

- (BOOL)isGroupManager:(NSString *)targetId {
    if (self.conversation.type != Group_Type) {
        return false;
    }
    __block BOOL manager = false;
    NSArray<WFCCGroupMember *> *groupMembers = [[WFCCGroupDB sharedManager] getGroupMembers:self.conversation.target];
    [groupMembers enumerateObjectsUsingBlock:^(WFCCGroupMember * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.memberId isEqualToString:targetId]) {
            if (obj.type == Member_Type_Manager) {
                manager = YES;
            }
            *stop = YES;
        }
    }];
    return manager;
}

- (void)didTaptzboeuQuoteLabel:(SMIOUEJMessageCellBase *)cell withModel:(AIOIUEHMessageModel *)model {
    WFCCQuoteInfo *quoteInfo = [SMIOUEJMessageCell quoteInfoForModel:model];
    if (quoteInfo) {
            __block WFCCMessage *msg = [[WFCCIMService sharedWFCIMService] getMessageByUid:quoteInfo.messageUid];
            if ([msg.content isKindOfClass:[WFCCRecallMessageContent class]]) {
                [self.view makeToast:LLLLLL(@"MessageDoesntExist")];
                NSLog(@"msg not exist");
                return;
            }
            
            if(msg) {
                [self showQuote:quoteInfo ofMessage:msg];
            } else {
                [self.modelList enumerateObjectsUsingBlock:^(AIOIUEHMessageModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if(obj.message.messageUid == quoteInfo.messageUid) {
                        msg = obj.message;
                        *stop = YES;
                    }
                }];
                if(msg) {
                    [self showQuote:quoteInfo ofMessage:msg];
                } else {
                    __weak typeof(self)ws = self;
                    [[WFCCIMService sharedWFCIMService] getRemoteMessage:quoteInfo.messageUid success:^(WFCCMessage *message) {
                        if (!message.content || [message.content isKindOfClass:[WFCCRecallMessageContent class]]) {
                            [ws.view makeToast:LLLLLL(@"MessageDoesntExist")];
                            NSLog(@"msg not exist");
                            return;
                        } else {
                            [ws showQuote:quoteInfo ofMessage:message];
                        }
                    } error:^(int error_code) {
                        if(error_code == 253) {
                            [ws.view makeToast:LLLLLL(@"MessageDoesntExist")];
                        } else {
                            [ws.view makeToast:LLLLLL(@"NetworkError")];
                        }
                    }];
                }
            }
    }
    
}

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    NSLog(@"player finished");
    [self stopPlayer];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    NSLog(@"player decode error");
    [[[UIAlertView alloc] initWithTitle:LLLLLL(@"Warning") message:LLLLLL(@"NetworkError") delegate:nil cancelButtonTitle:LLLLLL(@"AlertButton") otherButtonTitles:nil, nil] show];
    [self stopPlayer];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.chatInputBar resetInputBarStatue];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (self.hasNewMessage && ceil(targetContentOffset->y)+1 >= ceil(scrollView.contentSize.height - scrollView.bounds.size.height)) {
        [self loadMoreMessage:NO completion:nil];
    }
    if (targetContentOffset->y <= 0 && self.hasMoreOld) {
        [self loadMoreMessage:YES completion:nil];
    }
    
    CGSize size = self.collectionView.contentSize;
    self.isAtButtom = (scrollView.bounds.size.height + targetContentOffset->y - size.height) > -5;
//    NSLog(@"is at buttom %d", self.isAtButtom);
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    
    
}
#pragma mark - ChatInputBarDelegate

- (void)didClickCard { // 点击Bar的名片
    EPIKNODWVContactVC *vc = EPIKNODWVContactVC.new;
    vc.conversationType = _conversation.type;
    vc.target = _conversation.target;
    vc.filterId = _conversation.target;
    vc.type = 2;
    UINavigationController *naviVC = [[UINavigationController alloc] initWithRootViewController:vc];
    naviVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:naviVC animated:YES completion:nil];
    //    [self.navigationController pushViewController:vc animated:YES];
}

- (void)imageDidCapture:(UIImage *)capturedImage fullImage:(BOOL)fullImage {
    [self imageDidCapture:capturedImage fullImage:fullImage extra:nil];
}

- (void)imageDidCapture:(UIImage *)capturedImage fullImage:(BOOL)fullImage extra:(NSString *)extra {
    if (!capturedImage) {
        return;
    }
    
    UInt64 recordTime = [[NSDate date] timeIntervalSince1970]*1000;
    NSString *cacheDir = [[AIOIUEHConfigManager globalManager] cachePathOf:self.conversation mediaType:Media_Type_IMAGE];
    
    NSString *path = [cacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"img%lld.jpg", recordTime++]];
    
    
    WFCCImageMessageContent *imgContent = [WFCCImageMessageContent contentFrom:capturedImage cachePath:path fullImage:fullImage];
    imgContent.extra = extra;
    [self sendMessage:imgContent];
}

-(void)gifDidCapture:(NSData *)gifData {
    //save gif
    UInt64 recordTime = [[NSDate date] timeIntervalSince1970]*1000;
    NSString *cacheDir = [[AIOIUEHConfigManager globalManager] cachePathOf:self.conversation mediaType:Media_Type_STICKER];
    NSString *filePath = [cacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"gif%lld.jpg", recordTime]];
    
    [gifData writeToFile:filePath atomically:YES];
    
    WFCCStickerMessageContent *stickerContent = [WFCCStickerMessageContent contentFrom:filePath];
    [self sendMessage:stickerContent];
}
//   上传视频视频视频视频
- (void)videoDidCapture:(NSString *)videoPath thumbnail:(UIImage *)image duration:(long)duration {
    [self videoDidCapture:videoPath thumbnail:image duration:duration extra:nil];
}

- (void)videoDidCapture:(NSString *)videoPath
              thumbnail:(UIImage *)image
               duration:(long)duration
                  extra:(NSString *)extra {
    WFCCVideoMessageContent *videoContent = [WFCCVideoMessageContent contentPath:videoPath thumbnail:image];
    videoContent.duration = duration;
    videoContent.extra = extra;
    [self sendMessage:videoContent];
}

- (void)imageDataDidSelect:(NSArray<UIImage *> *)selectedImages isFullImage:(BOOL)fullImage {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        UInt64 recordTime = [[NSDate date] timeIntervalSince1970]*1000;
        NSString *cacheDir = [[AIOIUEHConfigManager globalManager] cachePathOf:self.conversation mediaType:Media_Type_IMAGE];
        
        for (UIImage *image in selectedImages) {
            NSString *path = [cacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"img%lld.jpg", recordTime++]];
            
            WFCCImageMessageContent *imgContent = [WFCCImageMessageContent contentFrom:image cachePath:path];
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self sendMessage:imgContent];
            });
            [NSThread sleepForTimeInterval:0.2];
        }
    });
}

- (void)didTapChannelMenu:(WFCCChannelMenu *)channelMenu {
    if ([channelMenu.type isEqualToString:@"view"] && channelMenu.url.length) {
        JUAHODJNKBrowserVC *bvc = [[JUAHODJNKBrowserVC alloc] init];
        bvc.url = channelMenu.url;
        [self.navigationController pushViewController:bvc animated:YES];
    } else if([channelMenu.type isEqualToString:@"miniprogram"] && channelMenu.appId.length) {
        //打开小程序。。。
    }
}

- (NSString *)mentionTokenWithTarget:(NSString *)userId {
    NSString *safeUserId = userId ?: @"";
    return [NSString stringWithFormat:@"@{%@} ", safeUserId];
}

- (NSString *)normalizedMentionTextForOthersFrom:(NSString *)text mentionInfos:(NSArray<WFCUMetionInfo *> *)mentionInfos {
    if (self.conversation.type != Group_Type || text.length == 0 || mentionInfos.count == 0) {
        return text ?: @"";
    }

    NSArray<WFCUMetionInfo *> *userMentions = [mentionInfos filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(WFCUMetionInfo *mention, __unused NSDictionary *bindings) {
        return mention.target.length > 0 && mention.mentionType != 2;
    }]];
    if (userMentions.count == 0) {
        return text;
    }

    NSArray<WFCUMetionInfo *> *sortedMentions = [userMentions sortedArrayUsingComparator:^NSComparisonResult(WFCUMetionInfo *obj1, WFCUMetionInfo *obj2) {
        if (obj1.range.location < obj2.range.location) {
            return NSOrderedAscending;
        }
        if (obj1.range.location > obj2.range.location) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];

    NSMutableString *mutableText = [text mutableCopy];
    NSInteger delta = 0;
    for (WFCUMetionInfo *mention in sortedMentions) {
        NSRange originalRange = mention.range;
        NSInteger location = (NSInteger)originalRange.location + delta;
        if (location < 0 || location > mutableText.length) {
            continue;
        }
        NSInteger maxLength = (NSInteger)mutableText.length - location;
        NSInteger safeLength = MIN((NSInteger)originalRange.length, maxLength);
        if (safeLength < 0) {
            safeLength = 0;
        }

        NSString *replacement = [self mentionTokenWithTarget:mention.target];
        NSRange safeRange = NSMakeRange((NSUInteger)location, (NSUInteger)safeLength);
        [mutableText replaceCharactersInRange:safeRange withString:replacement];
        delta += (NSInteger)replacement.length - safeLength;
    }

    return mutableText;
}

- (void)didTouchSend:(NSString *)stringContent withMentionInfos:(NSMutableArray<WFCUMetionInfo *> *)mentionInfos withQuoteInfo:(WFCCQuoteInfo *)quoteInfo {
    if (stringContent.length == 0) {
        return;
    }
    
    NSArray<WFCUMetionInfo *> *safeMentionInfos = [mentionInfos copy] ?: @[];
    WFCCTextMessageContent *txtContent = [[WFCCTextMessageContent alloc] init];
    txtContent.text = [self normalizedMentionTextForOthersFrom:stringContent mentionInfos:safeMentionInfos];
    NSMutableArray<NSString *> *mentionTargets = [[NSMutableArray alloc] init];
    BOOL mentionAll = NO;
    for (WFCUMetionInfo *mentionInfo in safeMentionInfos) {
        if (mentionInfo.mentionType == 2) {
            mentionAll = YES;
            break;
        }
        if (mentionInfo.target.length > 0) {
            [mentionTargets addObject:mentionInfo.target];
        }
    }
    if (mentionAll) {
        txtContent.mentionedType = 2;
    } else if (mentionTargets.count > 0) {
        txtContent.mentionedType = 1;
        txtContent.mentionedTargets = [mentionTargets copy];
    }
    txtContent.quoteInfo = quoteInfo;
    
    if(self.orignalDraft) {
        self.orignalDraft = nil;
        [[WFCCIMService sharedWFCIMService] setConversation:self.conversation draft:nil];
    }
    
    [self sendMessage:txtContent];
    
}

- (void)needSaveDraft {
    if ([WFCCIMService.sharedWFCIMService isEnableSyncDraft]) {
        self.orignalDraft = self.chatInputBar.draft;
        [[WFCCIMService sharedWFCIMService] setConversation:self.conversation draft:self.orignalDraft];
    }
}

- (void)recordDidEnd:(NSString *)dataUri duration:(long)duration error:(NSError *)error {
    NSString *cacheDir = [[AIOIUEHConfigManager globalManager] cachePathOf:self.conversation mediaType:Media_Type_VOICE];
    
    UInt64 recordTime = [[NSDate date] timeIntervalSince1970]*1000;
    NSString *amrPath = [cacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"img%lld.amr", recordTime]];
    
    [self sendMessage:[WFCCSoundMessageContent soundMessageContentForWav:dataUri destinationAmrPath:amrPath duration:duration]];
}

- (BOOL)isEqualRect:(CGRect)first second:(CGRect)second {
    return first.origin.x == second.origin.x
    && first.origin.y == second.origin.y
    && first.size.width == second.size.width
    && first.size.height == second.size.height;
}

- (void)willChangeFrame:(CGRect)newFrame withDuration:(CGFloat)duration keyboardShowing:(BOOL)keyboardShowing {
    if (!self.isShowingKeyboard) {
        CGRect frame = self.collectionView.frame;
        CGFloat diff = MIN(frame.size.height, self.collectionView.contentSize.height) - newFrame.origin.y;
        if(diff > 0) {
            frame.origin.y = -diff;
        } else {
            frame = CGRectMake(0, 0, self.backgroundView.bounds.size.width, newFrame.origin.y);
        }
        if([self isEqualRect:frame second:self.collectionView.frame]) {
            return;
        }
        
        self.isShowingKeyboard = YES;
        [UIView animateWithDuration:duration animations:^{
            self.collectionView.frame = frame;
        } completion:^(BOOL finished) {
            self.collectionView.frame = CGRectMake(0, 0, self.backgroundView.bounds.size.width, newFrame.origin.y);
            
            if (keyboardShowing) {
                [self scrollToBottom:NO];
            }
            self.isShowingKeyboard = NO;
        }];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.collectionView.frame.size.height != newFrame.origin.y) {
                self.collectionView.frame = CGRectMake(0, 0, self.backgroundView.bounds.size.width, newFrame.origin.y);
                [self scrollToBottom:YES];
            }
        });
    }
    
}

- (UINavigationController *)requireNavi {
    return self.navigationController;
}

- (void)locationDidSelect:(CLLocationCoordinate2D)location locationName:(NSString *)locationName mapScreenShot:(UIImage *)mapScreenShot {
    WFCCLocationMessageContent *content = [WFCCLocationMessageContent contentWith:location title:locationName thumbnail:mapScreenShot];
    [self sendMessage:content];
}

- (void)didSelectFiles:(NSArray *)files {
    if(![[WFCCIMService sharedWFCIMService] isSupportBigFilesUpload]) {
        for (NSString *file in files) {
            WFCCFileMessageContent *content = [WFCCFileMessageContent fileMessageContentFromPath:file];
            if(content.size >= 100 * 1024 * 1024) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LLLLLL(@"Warning") message:(_isChinese?@"文件内容超大，无法发送！":@"The file content is too large to send!") preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:LLLLLL(@"iGotIt") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    
                }];
                
                [alertController addAction:actionCancel];
                
                [self presentViewController:alertController animated:YES completion:nil];
                return;
            }
        }
    }
    
    for (NSString *file in files) {
        BOOL isDir = NO;
        [[NSFileManager defaultManager] fileExistsAtPath:file isDirectory:&isDir];
        if(isDir) {
            NSLog(@"file is directiory");
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:[NSString stringWithFormat:@"%@: %@",(_isChinese?@"无法发送文件夹":@"Unable to send folder"), file.lastPathComponent] preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                
            }];
            
            [alertController addAction:actionCancel];
            
            [self presentViewController:alertController animated:YES completion:nil];
            continue;;
        }
        
        WFCCFileMessageContent *content = [WFCCFileMessageContent fileMessageContentFromPath:file];
        [self sendMessage:content];
        [NSThread sleepForTimeInterval:0.05];
    }
}

- (void)saveStickerRemoteUrl:(WFCCStickerMessageContent *)stickerContent {
    if (stickerContent.localPath.length && [AIOIUEHUtilities isFileExist:stickerContent.localPath] && stickerContent.remoteUrl.length) {
        if(self.conversation.type == SecretChat_Type) {
            [[NSUserDefaults standardUserDefaults] setObject:stickerContent.remoteUrl forKey:[NSString stringWithFormat:@"sticker_remote_for_sh_%@_%ld", self.conversation.target, stickerContent.localPath.hash]];
        } else {
            [[NSUserDefaults standardUserDefaults] setObject:stickerContent.remoteUrl forKey:[NSString stringWithFormat:@"sticker_remote_for_%ld", stickerContent.localPath.hash]];
        }
        
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)appendLocalStickerPreviewForContent:(WFCCStickerMessageContent *)stickerContent {
    static long localStickerPreviewId = -100000000;
    WFCCMessage *message = [[WFCCMessage alloc] init];
    message.messageId = localStickerPreviewId--;
    message.messageUid = 0;
    message.conversation = self.conversation;
    message.fromUser = [WFCCNetworkService sharedInstance].userId;
    message.content = stickerContent;
    message.direction = MessageDirection_Send;
    message.status = Message_Status_Sending;
    message.serverTime = [[NSDate date] timeIntervalSince1970] * 1000;
    [self appendMessages:@[message] newMessage:YES highlightId:0 forceButtom:YES];
}

- (void)removeLocalStickerPreviewForContent:(WFCCStickerMessageContent *)stickerContent {
    if (!stickerContent.localPath.length) {
        return;
    }
    for (NSInteger i = self.modelList.count - 1; i >= 0; i--) {
        AIOIUEHMessageModel *model = self.modelList[i];
        if (model.message.messageId >= 0 || ![model.message.content isKindOfClass:[WFCCStickerMessageContent class]]) {
            continue;
        }
        WFCCStickerMessageContent *localContent = (WFCCStickerMessageContent *)model.message.content;
        if ([localContent.localPath isEqualToString:stickerContent.localPath]) {
            [self.modelList removeObjectAtIndex:i];
            [self.collectionView reloadData];
            break;
        }
    }
}

- (BOOL)updateLocalStickerPreviewWithMessage:(WFCCMessage *)message {
    if (![message.content isKindOfClass:[WFCCStickerMessageContent class]]) {
        return NO;
    }
    WFCCStickerMessageContent *stickerContent = (WFCCStickerMessageContent *)message.content;
    NSInteger fallbackIndex = NSNotFound;
    for (NSInteger i = 0; i < self.modelList.count; i++) {
        AIOIUEHMessageModel *model = self.modelList[i];
        if (model.message.messageId >= 0 || ![model.message.content isKindOfClass:[WFCCStickerMessageContent class]]) {
            continue;
        }
        if (fallbackIndex == NSNotFound) {
            fallbackIndex = i;
        }
        WFCCStickerMessageContent *localContent = (WFCCStickerMessageContent *)model.message.content;
        if (stickerContent.localPath.length && [localContent.localPath isEqualToString:stickerContent.localPath]) {
            model.message = message;
            [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]]];
            return YES;
        }
    }
    if (fallbackIndex != NSNotFound) {
        AIOIUEHMessageModel *model = self.modelList[fallbackIndex];
        model.message = message;
        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:fallbackIndex inSection:0]]];
        return YES;
    }
    return NO;
}

- (void)didSelectSticker:(NSString *)stickerPath {
    WFCCStickerMessageContent * content = [WFCCStickerMessageContent contentFrom:stickerPath];
    NSString *remoteUrl;
    if(self.conversation.type == SecretChat_Type) {
        remoteUrl = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"sticker_remote_for_sh_%@_%ld", self.conversation.target, stickerPath.hash]];
    } else {
        remoteUrl = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"sticker_remote_for_%ld", stickerPath.hash]];
    }
    content.remoteUrl = remoteUrl;
    
    [self appendLocalStickerPreviewForContent:content];
    [self sendMessage:content];
}

- (void)onTyping:(WFCCTypingType)type {
    if (self.conversation.type == Single_Type || self.conversation.type == SecretChat_Type || self.conversation.type == Group_Type) {
        [self sendMessage:[WFCCTypingMessageContent contentType:type]];
    }
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return self.navigationController.childViewControllers.count > 1;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return self.navigationController.viewControllers.count > 1;
}


#pragma mark - menu
- (void)displayMenu:(SMIOUEJMessageCellBase *)baseCell {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    UIMenuController *menu = [UIMenuController sharedMenuController];
    
    UIMenuItem *deleteItem = [[UIMenuItem alloc] initWithTitle:LLLLLL(@"Delete") action:@selector(performDelete:)];
    UIMenuItem *cancelItem = [[UIMenuItem alloc] initWithTitle:LLLLLL(@"Cancel") action:@selector(performCancel:)];
    UIMenuItem *copyItem = [[UIMenuItem alloc] initWithTitle:LLLLLL(@"Copy") action:@selector(performCopy:)];
    UIMenuItem *forwardItem = [[UIMenuItem alloc] initWithTitle:LLLLLL(@"Forwarding") action:@selector(performForward:)];
    UIMenuItem *recallItem = [[UIMenuItem alloc] initWithTitle:LLLLLL(@"Recall") action:@selector(performRecall:)];
    UIMenuItem *complainItem = [[UIMenuItem alloc] initWithTitle:LLLLLL(@"Complain") action:@selector(performComplain:)];
    UIMenuItem *multiSelectItem = [[UIMenuItem alloc] initWithTitle:LLLLLL(@"MultiSelect") action:@selector(performMultiSelect:)];
    UIMenuItem *quoteItem = [[UIMenuItem alloc] initWithTitle:LLLLLL(@"Quote") action:@selector(performQuote:)];
    UIMenuItem *favoriteItem = [[UIMenuItem alloc] initWithTitle:LLLLLL(@"Favorite") action:@selector(performFavorite:)];
    
    CGRect menuPos;
    if ([baseCell isKindOfClass:[SMIOUEJMessageCell class]]) {
        SMIOUEJMessageCell *msgCell = (SMIOUEJMessageCell *)baseCell;
        menuPos = msgCell.tzboeuBubbleView.frame;
    } else {
        menuPos = baseCell.frame;
    }
    
    [menu setTargetRect:menuPos inView:baseCell];
    WFCCMessage *msg = baseCell.model.message;
    
    NSMutableArray *items = [[NSMutableArray alloc] init];
    [items addObject:deleteItem];
    if ([msg.content isKindOfClass:[WFCCTextMessageContent class]]/* || [msg.content isKindOfClass:WFCCAnnouncementMessageContent.class]*/) {
        [items addObject:copyItem];
    }
    
    if (baseCell.model.message.direction == MessageDirection_Send && baseCell.model.message.status == Message_Status_Sending && [baseCell.model.message.content isKindOfClass:[WFCCMediaMessageContent class]]) {
        [items addObject:cancelItem];
    }
    
    if (baseCell.model.message.direction == MessageDirection_Receive) {
        //屏蔽投诉
//        [items addObject:complainItem];
    }
    
    if(self.conversation.type != SecretChat_Type) {
        if ([msg.content isKindOfClass:[WFCCImageMessageContent class]] ||
            [msg.content isKindOfClass:[WFCCTextMessageContent class]] ||
            [msg.content isKindOfClass:[WFCCLinkMessageContent class]] ||
            [msg.content isKindOfClass:[WFCCArticlesMessageContent class]] ||
            [msg.content isKindOfClass:[WFCCLocationMessageContent class]] ||
            [msg.content isKindOfClass:[WFCCFileMessageContent class]] ||
            [msg.content isKindOfClass:[WFCCVideoMessageContent class]] ||
            [msg.content isKindOfClass:[WFCCCardMessageContent class]] ||
            // [msg.content isKindOfClass:[WFCCConferenceInviteMessageContent class]] || // removed: channel
            [msg.content isKindOfClass:[WFCCCompositeMessageContent class]] ||
            //        [msg.content isKindOfClass:[WFCCSoundMessageContent class]] || //语音消息禁止转发，出于安全原因考虑，微信就禁止转发。如果您能确保安全，可以把这行注释打开
            [msg.content isKindOfClass:[WFCCStickerMessageContent class]]) {
//            [items addObject:forwardItem];
            [items insertObject:forwardItem atIndex:0];
        }
    }
    
    BOOL canRecall = NO;
    if ([baseCell isKindOfClass:[SMIOUEJMessageCell class]]) {
        if(msg.direction == MessageDirection_Send) {
            NSDate *cur = [NSDate date];
            if ([cur timeIntervalSince1970]*1000 - msg.serverTime < 60 * 1000) {
                canRecall = YES;
            }
        } else if (self.conversation.type == Group_Type) {
            WFCCGroupInfo *groupInfo = [[WFCCGroupDB sharedManager] getGroupInfoFromDB:self.conversation.target];
            if([groupInfo.owner isEqualToString:userId]) {
                canRecall = YES;
            } else {
                __block BOOL isMyselfManager = false;
                __block BOOL isTargetManager = false;
                NSArray *memberList = [[WFCCGroupDB sharedManager] getGroupMembers:self.conversation.target];
                [memberList enumerateObjectsUsingBlock:^(WFCCGroupMember * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj.memberId isEqualToString:userId]) {
                        if (obj.type == Member_Type_Manager || obj.type == Member_Type_Owner) {
                            isMyselfManager = YES;
                        }
                    }
                    if([obj.memberId isEqualToString:msg.fromUser]) {
                        if ((obj.type == Member_Type_Manager || obj.type == Member_Type_Owner)) {
                            isTargetManager = YES;
                        }
                    }
                }];
                if(isMyselfManager && !isTargetManager) {
                    canRecall = YES;
                }
            }
        }
    }
    
    if(self.conversation.type == SecretChat_Type && msg.direction == MessageDirection_Send) {
        canRecall = YES;
    }
    
    if (canRecall) {
        [items addObject:recallItem];
    }
    
    if(self.conversation.type != SecretChat_Type) {
        if ([baseCell isKindOfClass:[SMIOUEJMessageCell class]] || [baseCell isKindOfClass:[SMIOUEJArticlesCell class]]) {
            [items addObject:multiSelectItem];
        }
    }
    
    if (msg.messageUid > 0) {
        if ([msg.content.class getContentFlags] & 0x2) {
            [items addObject:quoteItem];
        }
    }
    
    if(self.conversation.type != SecretChat_Type) {
        if ([msg.content isKindOfClass:[WFCCImageMessageContent class]] ||
            [msg.content isKindOfClass:[WFCCTextMessageContent class]] ||
            [msg.content isKindOfClass:[WFCCLocationMessageContent class]] ||
            [msg.content isKindOfClass:[WFCCFileMessageContent class]] ||
            [msg.content isKindOfClass:[WFCCVideoMessageContent class]] ||
            [msg.content isKindOfClass:[WFCCSoundMessageContent class]] ||
            [msg.content isKindOfClass:[WFCCFileMessageContent class]] ||
            [msg.content isKindOfClass:[WFCCLinkMessageContent class]] ||
            [msg.content isKindOfClass:[WFCCArticlesMessageContent class]] ||
            [msg.content isKindOfClass:[WFCCCompositeMessageContent class]]) {
            //暂时隐藏
//            [items addObject:favoriteItem];
        }
    }
    
    // 0426新增 - 消息类型置顶操作(目前只开放 文本消息、文件、公告) --- 开始
    //0331 图片置顶
    //0512 视频置顶
    if (_conversation.type == Group_Type) {
        if ([msg.content isKindOfClass:[WFCCTextMessageContent class]] ||
            [msg.content isKindOfClass:[WFCCFileMessageContent class]] ||
            [msg.content isKindOfClass:[WFCCAnnouncementMessageContent class]] ||
            [msg.content isKindOfClass:[WFCCImageMessageContent class]] ||
            [msg.content isKindOfClass:[WFCCVideoMessageContent class]]) {
            if ([self isManager]) { // 群聊 && 消息类型(文本、文件、公告) && 群主或管理员   才能置顶操作
                NSString *isPinned = LLLLLL(@"Pinned"); // 是否已经置顶了
                for (MessageTopList *topList in self.topMessages) {
                    if (topList.messageUid == msg.messageUid) {
                        isPinned = LLLLLL(@"Unpinned"); // 已经置顶了，那就取消置顶
                        break;
                    }
                }
//                NSLog(@"消息可以%@了",isPinned);
                UIMenuItem *topItem = [[UIMenuItem alloc] initWithTitle:isPinned action:@selector(performPinned:)];
                [items addObject:topItem];
            }
        }
    }
    
    // 0426新增 - 到这儿结束
    
    [menu setMenuItems:items];
    self.cell4Menu = baseCell;
    
    [menu setMenuVisible:YES];
}


-(BOOL)canBecomeFirstResponder {
    return YES;
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if(self.cell4Menu) {
        if (action == @selector(performDelete:) || action == @selector(performCancel:) || action == @selector(performCopy:) || action == @selector(performForward:) || action == @selector(performRecall:) || action == @selector(performComplain:) || action == @selector(performMultiSelect:) || action == @selector(performQuote:) || action == @selector(performFavorite:) || action == @selector(performPinned:)) {
            return YES; //显示自定义的菜单项
        } else {
            return NO;
        }
    }
    
    if (action == @selector(paste:)) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        return pasteboard.string != nil;
    }
    return NO;//[super canPerformAction:action withSender:sender];
}

- (void)paste:(id)sender {
    [self.chatInputBar paste:sender];
}

- (void)deleteMessageUI:(long long)messageId {
    for (int i = 0; i < self.modelList.count; i++) {
        AIOIUEHMessageModel *model = [self.modelList objectAtIndex:i];
        if (model.message.messageId == messageId) {
            [self.modelList removeObject:model];
            [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]]];
            break;
        }
    }
}

- (void)deleteLocalMessage:(long)messageId {
    [[WFCCMessageDB sharedManager] deleteMessage:messageId];
    [self deleteMessageUI:messageId];
}

- (void)deleteRemoteMessage:(long)messageId {
    //    NSLog(@"Jianshili===删除=%ld",messageId);
    [[WFCCIMService sharedWFCIMService] deleteMessage:messageId];
    [self deleteMessageUI:messageId];
}

-(void)performDelete:(UIMenuController *)sender {
    WFCCMessage *message = self.cell4Menu.model.message;
    //    for (AIOIUEHMessageModel *msg in _modelList) {
    //        NSLog(@"toJsonObj======%@",msg.message.toJsonObj);
    //    }
    //    NSLog(@"isCommercialServer====%d",[[WFCCIMService sharedWFCIMService] isCommercialServer]);
    // isCommercialServer 是否是商业版IM服务
    if([[WFCCIMService sharedWFCIMService] isCommercialServer] && self.conversation.type != Channel_Type) {
        __weak typeof(self)weakSelf = self;
        
        UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:LLLLLL(@"ConfirmDelete") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        UIAlertAction *actionLocalDelete = [UIAlertAction actionWithTitle:LLLLLL(@"DeleteLocalMsg") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf deleteLocalMessage:message.messageId];
        }];
        
        [actionSheet addAction:actionLocalDelete];
        
        bool superGroup = false;
        if(self.conversation.type == Group_Type) {
            superGroup = self.targetGroup.superGroup>0;
        }
        
        //超级群组不支持远端删除
        if(!superGroup) {
            if (message.direction == MessageDirection_Send) { // 1126只能多端删除自己发送的消息
                UIAlertAction *actionRemoteDelete = [UIAlertAction actionWithTitle:LLLLLL(@"DeleteRemoteMsg") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:weakSelf.view animated:YES];
                    hud.label.text = LLLLLL(@"Deleting");
                    [hud showAnimated:YES];
                    
                    if (message.messageUid == 0) {
                        //                        [[WFCCIMService sharedWFCIMService] deleteRemoteMessage:message.messageUid success:^{
                        [weakSelf deleteMessageUI:message.messageId];
                        [hud hideAnimated:YES];
                        //                        } error:^(int error_code) {
                        //                            hud.mode = MBProgressHUDModeText;
                        //                            hud.label.text = @"删除失败";
                        //                            [hud hideAnimated:YES afterDelay:1.f];
                        //                        }];
                    }else {
                        [AppService.sharedAppService deleteMessage:@{@"messageUid":@(message.messageUid)} success:^(NSDictionary * _Nonnull dict) {
                            [weakSelf deleteMessageUI:message.messageId];
                            [hud hideAnimated:YES];
                        } error:^(int errCode, NSString * _Nonnull message) {
                            hud.mode = MBProgressHUDModeText;
                            hud.label.text = LLLLLL(@"DeleteFailed");
                            [hud hideAnimated:YES afterDelay:1.f];
                        }];
                    }
                }];
                [actionSheet addAction:actionRemoteDelete];
            }else {
                UIAlertAction *actionRemoteDelete = [UIAlertAction actionWithTitle:(_isChinese?@"删除服务器消息":@"Delete server message") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:weakSelf.view animated:YES];
                    hud.label.text = LLLLLL(@"Deleting");
                    [hud showAnimated:YES];
                    [[WFCCIMService sharedWFCIMService] deleteRemoteMessage:message.messageUid success:^{
                        [weakSelf deleteMessageUI:message.messageId];
                        [hud hideAnimated:YES];
                    } error:^(int error_code) {
                        hud.mode = MBProgressHUDModeText;
                        hud.label.text = LLLLLL(@"DeleteFailed");
                        [hud hideAnimated:YES afterDelay:1.f];
                    }];
                }];
                [actionSheet addAction:actionRemoteDelete];
            }
        }
        [actionSheet addAction:actionCancel];
        
        [self presentViewController:actionSheet animated:YES completion:nil];
    } else {
        
        WS(weakself)
        UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:LLLLLL(@"ConfirmDelete") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {

        }];
        UIAlertAction *actionLocalDelete = [UIAlertAction actionWithTitle:LLLLLL(@"DeleteLocalMsg") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            [self deleteLocalMessage:message.messageId];
        }];
        
        UIAlertAction *actionRemoteDelete = [UIAlertAction actionWithTitle:LLLLLL(@"DeleteRemoteMsg") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self deleteRemoteMessage:message.messageId];
        }];
        
        [actionSheet addAction:actionLocalDelete];
        
        //群聊只有群主/管理员有远程删除，单聊只能远程删除自己的
        if(self.conversation.type == Single_Type) {
            NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
            if ([message.fromUser isEqualToString:userId]) {
                [actionSheet addAction:actionRemoteDelete];
            }
        } else {
            if ([self isManager]) {
                if(self.conversation.type != SecretChat_Type) {
                    [actionSheet addAction:actionRemoteDelete];
                }
            }
        }
        [actionSheet addAction:actionCancel];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:actionSheet animated:YES completion:nil];
        });
    }
}

-(void)performCancel:(UIMenuController *)sender {
    if (self.cell4Menu) {
        if(![[WFCCIMService sharedWFCIMService] cancelSendingMessage:self.cell4Menu.model.message.messageId]) {
            [self.view makeToast:(_isChinese?@"取消失败":@"Cancel failure") duration:1 position:CSToastPositionCenter];
        }
    }
}

-(void)performCopy:(UIMenuItem *)sender {
    if (self.cell4Menu) {
        if ([self.cell4Menu.model.message.content isKindOfClass:[WFCCTextMessageContent class]]) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = ((WFCCTextMessageContent *)self.cell4Menu.model.message.content).text;
        }
    }
}

-(void)performForward:(UIMenuItem *)sender {
    if (self.cell4Menu) {
        NFCNUOEYForwardVC *controller = [[NFCNUOEYForwardVC alloc] init];
        controller.message = self.cell4Menu.model.message;
//        UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:controller];
//        [self.navigationController presentViewController:navi animated:YES completion:nil];
        [self.navigationController pushViewController:controller animated:YES];

    }
}

//撤回
-(void)performRecall:(UIMenuItem *)sender {
    if (self.cell4Menu.model.message) {
        __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.label.text = LLLLLL(@"Recalling");
        [hud showAnimated:YES];
        __weak typeof(self) ws = self;
        long messageId = self.cell4Menu.model.message.messageId;
        SMIOUEJMessageCellBase *cell = self.cell4Menu;
        [[WFCCIMService sharedWFCIMService] recall:self.cell4Menu.model.message success:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];
                if (cell.model.message.messageId == messageId) {
                    if(messageId > 0) {
                        cell.model.message = [[WFCCIMService sharedWFCIMService] getMessage:messageId];
                    } else {
                        //client will replace the message content
                    }
                    NSIndexPath *indexPath = [ws.collectionView indexPathForCell:cell];
                    if (indexPath) {
                        [ws.collectionView reloadItemsAtIndexPaths:@[indexPath]];
                    }
                }
            });
        } error:^(int error_code) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"错误码===%d",error_code);
                hud.mode = MBProgressHUDModeText;
                hud.label.text = LLLLLL(@"RecallFailure");
                [hud hideAnimated:YES afterDelay:1.f];
            });
        }];
    }
}

- (void)performComplain:(UIMenuItem *)sender {
    NSString *message = @"";
    if (_isChinese) {
        message = @"如果您发现有违反法律和道德的内容，或者您的合法权益受到侵犯，请截图之后发送给我们。我们会在24小时之内处理。处理办法包括不限于删除内容，对作者进行警告，冻结账号，甚至报警处理。举报请到\"设置->设置->举报\"联系我们！";
    }else {
        message = @"If you find that there is a violation of law and ethics, or your legitimate rights and interests have been violated, please take a screenshot and send it to us. We'll deal with it within 24 hours. Handling methods include but are not limited to deleting the content, warning the author, freezing the account, and even alarming the police. Report to \"Settings -> Settings -> Report\" contact us!";
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LLLLLL(@"Complain") message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
    }];
    [alertController addAction:action];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)performMultiSelect:(UIMenuItem *)sender {
    self.multiSelecting = !self.multiSelecting;
}

- (void)performQuote:(UIMenuItem *)sender {
    if (self.cell4Menu.model.message) {
        [self.chatInputBar appendQuote:self.cell4Menu.model.message];
    }
}

- (void)performFavorite:(UIMenuItem *)sender {
    if (self.cell4Menu.model.message) {
        AIOIUEHFavoriteItem *item = [AIOIUEHFavoriteItem itemFromMessage:self.cell4Menu.model.message];
        if (!item) {
            [self.view makeToast:(_isChinese?@"暂不支持":@"Not supported yet") duration:1 position:CSToastPositionCenter];
            return;
        }
        
        item.sender = self.cell4Menu.model.message.fromUser;
        item.conversation = self.cell4Menu.model.message.conversation;
        if (self.cell4Menu.model.message.conversation.type == Single_Type || self.cell4Menu.model.message.conversation.type == SecretChat_Type) {
            WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:self.cell4Menu.model.message.fromUser];
            item.origin = userInfo.finalName;
        } else if (self.cell4Menu.model.message.conversation.type == Group_Type) {
            WFCCGroupInfo *groupInfo = [[WFCCGroupDB sharedManager] getGroupInfoFromDB:self.cell4Menu.model.message.conversation.target];
            item.origin = groupInfo.displayName;
        } else if (self.cell4Menu.model.message.conversation.type == Channel_Type) {
            WFCCChannelInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:self.cell4Menu.model.message.conversation.target refresh:NO];
            item.origin = groupInfo.name;
        } else {
            WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:self.cell4Menu.model.message.fromUser];
            item.origin = userInfo.finalName;
        }
        
        
        __weak typeof(self)ws = self;
        [[AIOIUEHConfigManager globalManager].appServiceProvider addFavoriteItem:item success:^{
            NSLog(@"added");
            [ws.view makeToast:(self->_isChinese?@"已收藏":@"Collected") duration:1 position:CSToastPositionCenter];
        } error:^(int error_code) {
            NSLog(@"add failure");
            [ws.view makeToast:LLLLLL(@"NetworkError") duration:1 position:CSToastPositionCenter];
        }];
    }
}

- (void)onMenuHidden:(id)sender {
//    NSLog(@"MenuHidden=======通知9==");
    UIMenuController *menu = [UIMenuController sharedMenuController];
    [menu setMenuItems:nil];
    __weak typeof(self)ws = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        ws.cell4Menu = nil;
    });
}

//- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
//    [super traitCollectionDidChange:previousTraitCollection];
//    if (@available(iOS 13.0, *)) {
//        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
//            [self.navigationController popViewControllerAnimated:NO];
//        }
//    }
//}
    // voip: UITableView delegate/datasource methods removed (numberOfRowsInSection, cellForRowAtIndexPath, heightForRowAtIndexPath, didSelectRowAtIndexPath, didJoinButtonPressed, didCancelButtonPressed)

//self.imageMsgs = imageMsgs;

#pragma mark - MWPhotoBrowserDelegate
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.imageMsgs.count;
}
//  点击图片视频的触发   视频视频
- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    WFCCMessage *msg = self.imageMsgs[index];
    if([msg.content isKindOfClass:[WFCCImageMessageContent class]]) {
        WFCCImageMessageContent *imgCnt = (WFCCImageMessageContent *)msg.content;
        MWPhoto *photo = [MWPhoto photoWithURL:URL(imgCnt.remoteUrl)];
        photo.message = msg;
        return photo;
    } else if([msg.content isKindOfClass:[WFCCVideoMessageContent class]]) {
        WFCCVideoMessageContent *videoCnt = (WFCCVideoMessageContent *)msg.content;
        MWPhoto *photo = [MWPhoto videoWithURL:URL(videoCnt.remoteUrl)];
        photo.message = msg;
        return photo;
    }
    return nil;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    WFCCMessage *msg = self.imageMsgs[index];
    UIImage *image = nil;
    NSString *remoteUrl = @"";
    BOOL video = NO;
    if([msg.content isKindOfClass:[WFCCImageMessageContent class]]) {
        WFCCImageMessageContent *imgCnt = (WFCCImageMessageContent *)msg.content;
        image = imgCnt.thumbnail;
        remoteUrl = imgCnt.remoteUrl;
    } else if([msg.content isKindOfClass:[WFCCVideoMessageContent class]]) {
        WFCCVideoMessageContent *videoCnt = (WFCCVideoMessageContent *)msg.content;
        image = videoCnt.thumbnail;
        remoteUrl = videoCnt.remoteUrl;
        video = YES;
    }
    MWPhoto *photo = [MWPhoto photoWithImage:image];
    //    NSLog(@"image====%@",image);
    //    MWPhoto *photo = [MWPhoto photoWithURL:URL(remoteUrl)];
    photo.isVideo = video;
    return photo;
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    NSLog(@"Did start viewing photo at index %lu", (unsigned long)index);
}

- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser isPhotoSelectedAtIndex:(NSUInteger)index {
    return NO;
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index selectedChanged:(BOOL)selected {
    NSLog(@"Photo at index %lu selected %@", (unsigned long)index, selected ? @"YES" : @"NO");
}

- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser {
    // If we subscribe to this method we must dismiss the view controller ourselves
    NSLog(@"Did finish modal presentation");
    [self dismissViewControllerAnimated:YES completion:nil];
}

//选择图片转发
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index {
    WFCCMessage *msg = self.imageMsgs[index];
    NFCNUOEYForwardVC *controller = [[NFCNUOEYForwardVC alloc] init];
    controller.message = msg;
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - 阅后即焚相关内容

- (void)setGroupExtraInfo:(GroupExtraInfo *)groupExtraInfo { // 群聊的属性
    _groupExtraInfo = groupExtraInfo;
    
    self.autoDelete = _groupExtraInfo.autoDelete;
    self.waitTime = _groupExtraInfo.waitTime;
}

- (void)single_get_option {
    if (_conversation.type == Group_Type) {
        return;
    }
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    WS(weakself)
    [AppService.sharedAppService requestUrl:@"/single/get_option" params:@{@"current":userId, @"target":_conversation.target} success:^(NSDictionary * _Nonnull dict) {
        weakself.autoDelete = [dict[@"result"][@"autoDelete"] longLongValue];
        weakself.waitTime = [dict[@"result"][@"waitTime"] integerValue];
    } error:^(int errCode, NSString * _Nonnull message) {
        weakself.autoDelete = 0;
        weakself.waitTime = 0;
    }];
}

- (void)dealloc {
    NSLog(@"%@ - dealloc",NSStringFromClass(self.class));
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //    if ([self.conversation.target isEqualToString:@"customer_service"]) {
    //    }
    if (self.autoDelete == 0 || self.waitTime == 0) {
        return;
    }
    
    //    if (self.conversation.type == Group_Type) {
    /**
     如果是我发的消息、那么就要确保有人已读、才能进行删除操作
     如果不是我发的消息，那么在进入该界面后，返回时就进行删除在规定时间范围内的消息
     */
    BOOL isRead = NO; // 是否已读
    for (NSString *key in self.readDict.allKeys) {
        long long time = [self.readDict[key] longLongValue];
        // 已读时间 >= 开启“阅后即焚”的时间 + 等待时间   意味着可以进行删除了
        if (time >= self.autoDelete + self.waitTime * 1000) {
            isRead = YES;
            break;
        }
    }
    
    BOOL isNoti = NO;
    for (NSInteger i = 0; i<self.modelList.count; i++) {
        SMIOUEJMessageCellBase *cell = [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        if (![cell isKindOfClass:SMIOUEJMessageCell.class]) {
            continue;
        }
        AIOIUEHMessageModel *model = self.modelList[i];
        if (model.message.direction == MessageDirection_Send) { // 如果是发送方 则需要判断该条消息是否已读
            if (((SMIOUEJMessageCell *)cell).tzboeuUnreadButton.selected == NO || isRead == NO) { // 该条消息没有人已读
                continue;
            }
        }else {
            
        }
        long long currentTime = [NSDate.date timeIntervalSince1970] * 1000;
        if (model.message.serverTime > self.autoDelete &&
            (model.message.serverTime + self.waitTime * 1000 < currentTime)) {
            // 该消息必须是已读状态 且 消息的发送时间要在开启“阅后即焚”状态之后 并且 (发送时间➕等待时间 < 当前时间)
//            [[WFCCIMService sharedWFCIMService] deleteMessage:model.message.messageId];
            isNoti = YES;
        }
    }
    if (isNoti) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kSecretMessageBurned object:nil userInfo:nil];
    }
    
    //    }
}



#pragma mark - 群公告新发布时 顶部的弹窗提示

//- (YUBWOIJWDAnnouncementTopView *)announcementTopView {
//    if (!_announcementTopView) {
//        _announcementTopView = [[YUBWOIJWDAnnouncementTopView alloc] init];
//    }
//    return _announcementTopView;
//}
- (void)getAnnouncementInfo {
    WS(weakself)
    _isUpdateGroupAnnouncement = NO;
    [AppService.sharedAppService groupAnnouncementGet:_conversation.target success:^(DUVOHJNGroupAnnouncement * announcement) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself topMessageList];
            if (announcement == nil || announcement.text.length <= 0) {
                return;
            }
            if (weakself.groupAnnouncement != nil && [weakself.groupAnnouncement.text isEqualToString:announcement.text]) {
                return;
            }
            weakself.groupAnnouncement = announcement;
            
            NSString *timestamp = [NSUserDefaults.standardUserDefaults valueForKey:kAnnouncementTimestamp];
            NSString *currentTime = UNString(@"%ld", announcement.timestamp);
            if ([currentTime isEqualToString:timestamp]) { // 说明没有更新群公告内容
                self->_isUpdateGroupAnnouncement = NO;
            }else { // 更新了群公告、显示顶部view
//                [weakself showTopAnnouncementView];
                self->_isUpdateGroupAnnouncement = YES;
            }
        });
    } error:^(int error_code) {
        self->_isUpdateGroupAnnouncement = NO;
        [weakself topMessageList];
    }];
}

- (void)topMessageList {
    [self.topMessages removeAllObjects];
    WS(weakself)
    [AppService.sharedAppService requestUrl:@"/group/message/top/list" params:@{@"gid":_conversation.target} success:^(NSDictionary * _Nonnull dict) {
        NSArray *result = dict[@"result"];
        NSMutableArray *mList = [NSMutableArray new];
        for (NSDictionary *dict in result) {
            NSString *content = dict[@"content"];
            NSDictionary *contentDic = [JSONHelper jsonObjectFromString:content];
            MessageTopList *ms = [[MessageTopList alloc] init];
            if (dict[@"id"]) {
                ms.id = [dict[@"id"] intValue];
            }
            if (contentDic[@"uid"]) {
                ms.messageUid = [contentDic[@"uid"] longLongValue];
            }
            ms.groupId = contentDic[@"to"];
            ms.userId = dict[@"userId"];
            ms.fromUser = contentDic[@"from"];
            MessageContent *contentM = [[MessageContent alloc] init];
            if (contentDic[@"type"]) {
                contentM.type = [contentDic[@"type"] intValue];
            }
            contentM.searchableContent = contentDic[@"message"];
            contentM.remoteMediaUrl = contentDic[@"remoteUrl"];
            ms.content = contentM;
            [mList addObject:ms];
        }
        weakself.topMessages = mList;
        [weakself reloadTopMessageView];
    }error:^(int errCode, NSString * _Nonnull message) {
        [weakself.view makeToast:message duration:1.0 position:CSToastPositionCenter];
    }];
}
- (void)reloadTopMessageView {
    NSString *timestamp = [NSUserDefaults.standardUserDefaults valueForKey:kAnnouncementTimestamp];
    NSString *currentTime = UNString(@"%ld", self.groupAnnouncement.timestamp);
    if ([currentTime isEqualToString:timestamp]) { // 说明没有更新群公告内容 - 这个判断用于通知 kCancel_Group_Announcement_Top
    }else {
        if (self->_isUpdateGroupAnnouncement) { // 将更新的群公告插入第一条消息
            MessageTopList *announcementTopList = MessageTopList.new;

            MessageContent *content = MessageContent.new;
            content.type = 2000;
            content.searchableContent = self.groupAnnouncement.text;
            announcementTopList.content = content;
            
            if (self.topMessages.count <= 0) {
                [self.topMessages addObject:announcementTopList];
            }else {
                if (self.topMessages.firstObject.content.type == 2000) {
                    [self.topMessages replaceObjectAtIndex:0 withObject:announcementTopList];
                }else {
                    [self.topMessages insertObject:announcementTopList atIndex:0];
                }
            }
        }else {
        }
    }
    
    if (self.topMessages.count <= 0) {
        self.topMsgIsHidden = YES;
    }else {
        self.topMsgIsHidden = NO;
        [self.topMessageView reloadView:self.topMessages];
    }
}
#pragma mark - 对文本、文件、群公告长按置顶/取消置顶 ------------ 点击事件

- (void)performPinned:(UIMenuItem *)sender {
    WFCCMessage *message = self.cell4Menu.model.message;
    
    NSInteger topId = -1; // id > 0 说明已经置顶了，取消置顶操作
    for (MessageTopList *topList in self.topMessages) {
        if (topList.messageUid == message.messageUid) {
            topId = topList.id;
            break;
        }
    }
    
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [hud showAnimated:YES];

    WS(weakself)
    if (topId == -1) { // 消息置顶
        [AppService.sharedAppService requestUrl:@"/group/message/top" params:@{@"groupId":_conversation.target, @"messageUid":@(message.messageUid)} success:^(NSDictionary * _Nonnull dict) {
            [hud hideAnimated:YES];
            [weakself topMessageList];
        }error:^(int errCode, NSString * _Nonnull message) {
            [hud hideAnimated:YES];
            [weakself.view makeToast:message duration:1.0 position:CSToastPositionCenter];
        }];
    }else { // 已经置顶了，那就做“取消置顶操作”、
        [AppService.sharedAppService requestUrl:@"/group/message/top/delete" params:@{@"id":@(topId)} success:^(NSDictionary * _Nonnull dict) {
            [hud hideAnimated:YES];
            [weakself topMessageList];
        }error:^(int errCode, NSString * _Nonnull message) {
            [hud hideAnimated:YES];
            [weakself.view makeToast:message duration:1.0 position:CSToastPositionCenter];
        }];
    }
}

#pragma mark - 对文本、文件、群公告长按置顶/取消置顶 ------------ View

- (YUBWOIJWDTopMessageView *)topMessageView {
    if (!_topMessageView) {
        _topMessageView = [[YUBWOIJWDTopMessageView alloc] init];
        [_backgroundView addSubview:_topMessageView];
        [_topMessageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickTopMessage)]];
        [_topMessageView.yzdoajRemoveBtn addTarget:self action:@selector(yzdoajRemove:) forControlEvents:UIControlEventTouchUpInside];
    }return _topMessageView;
}

- (void)clickTopMessage {
    if (self.topMessages.count <= 0) {
        return;
    }
    if (self.topMessages.count == 1) { // 有且只有1个置顶消息、并且是更新群公告消息
        if (self.topMessageView.yzdoajRemoveBtn.selected) {
            self.topMessageView.yzdoajRemoveBtn.selected = NO;
            self.topMessageView.yzdoajRemoveBtn.backgroundColor = UIColor.clearColor;
            return;
        }
        if (self.topMessages.firstObject.content.type == 2000) { // 群公告消息更新的一个弹窗
            [self enterGroupAnnouncement:NO];
            //点击群公告时不消失
            //            [self.topMessages removeAllObjects];
            //            self.topMsgIsHidden = YES;
            //            [NSUserDefaults.standardUserDefaults setValue:UNString(@"%ld", _groupAnnouncement.timestamp) forKey:kAnnouncementTimestamp];
        }else {
            [self dealData:self.topMessages.firstObject];
        }
        return;
    }
    YUBWOIJWDAllTopMessagePopupView *popupView = [[YUBWOIJWDAllTopMessagePopupView alloc] init];
    WS(weakself)
    [popupView setClickBlock:^(NSInteger type) {
        if (type == 2000) {
            [weakself enterGroupAnnouncement:NO];
        }else {
            [weakself dealData:self.topMessages[type]];
        }
    }];
    [popupView setGonggaoDelBlock:^(NSInteger tag) {
        [NSUserDefaults.standardUserDefaults setValue:UNString(@"%ld", _groupAnnouncement.timestamp) forKey:kAnnouncementTimestamp];
        [self topMessageList];
    }];
    [popupView showWithResult:self.topMessages];
}
- (void)dealData:(MessageTopList *)topList {
    /** content.type
     * 1  文本消息
     * 5  文件消息
     * 1001  公告消息
     */
    if (topList.content.type == 1001) { // 1001  公告消息
        [self enterGroupAnnouncement:NO];
    }else if (topList.content.type == 1) { // 1  文本消息
        UIView *textContainer = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        textContainer.backgroundColor = self.view.backgroundColor;
        
        UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, [AIOIUEHUtilities wf_navigationFullHeight], [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - [AIOIUEHUtilities wf_navigationFullHeight] - [AIOIUEHUtilities wf_safeDistanceBottom])];
        textView.text = topList.content.searchableContent;
        textView.textAlignment = NSTextAlignmentCenter;
        textView.font = PINGFANG_M(26);
        textView.editable = NO;
        textView.backgroundColor = self.view.backgroundColor;
        
        [textContainer addSubview:textView];
        [textView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapTextMessageDetailView:)]];
        [[UIApplication sharedApplication].keyWindow addSubview:textContainer];
    }else if (topList.content.type == 5) { // 5  文件消息
        if (topList.messageUid == 0) {
            return;
        }
        __weak typeof(self)ws = self;
        [[WFCCIMService sharedWFCIMService] getAuthorizedMediaUrl:topList.messageUid mediaType:Media_Type_FILE mediaPath:topList.content.remoteMediaUrl success:^(NSString *authorizedUrl, NSString *backupUrl) {
            JUAHODJNKBrowserVC *bvc = [[JUAHODJNKBrowserVC alloc] init];
            bvc.url = authorizedUrl;
            [ws.navigationController pushViewController:bvc animated:YES];
        } error:^(int error_code) {
            JUAHODJNKBrowserVC *bvc = [[JUAHODJNKBrowserVC alloc] init];
            bvc.url = topList.content.remoteMediaUrl;
            [ws.navigationController pushViewController:bvc animated:YES];
        }];
    } else if (topList.content.type == 3) {
        //图片
        YUBWOIJWDTopMessageShowViewController *vc = [[YUBWOIJWDTopMessageShowViewController alloc] init];
        vc.topList = topList;
        [self.navigationController pushViewController:vc animated:YES];
    } else if (topList.content.type == 6) {
        //视频
        // 点击视频触发的地方  视频视频
        self.imageMsgs = [[WFCCIMService sharedWFCIMService] getMessages:self.conversation contentTypes:@[@(MESSAGE_CONTENT_TYPE_IMAGE), @(MESSAGE_CONTENT_TYPE_VIDEO)] from:0 count:100 withUser:self.privateChatUser];
        self.imageMsgs = [self.imageMsgs sortedArrayUsingComparator:^NSComparisonResult(WFCCMessage  * obj1, WFCCMessage  * obj2) {
            return obj1.serverTime >= obj2.serverTime;
        }];
        
        int i;
        for (i = 0; i < self.imageMsgs.count; i++) {
            if ([self.imageMsgs objectAtIndex:i].messageUid == topList.messageUid) {
                break;
            }
        }
        if (i == self.imageMsgs.count) {
            i = 0;
        }
        
        MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
        browser.displayActionButton = YES;
        browser.displayNavArrows = NO;
        browser.displaySelectionButtons = NO;
        browser.alwaysShowControls = NO;
        browser.zoomPhotosToFill = NO;
        browser.enableGrid = YES;
        browser.startOnGrid = NO;
        browser.enableSwipeToDismiss = NO;
        browser.autoPlayOnAppear = YES;
        //            typeof(self) ws = self;
        [browser setScanResult:^(NSString *strScanned) {
            [gQrCodeDelegate handleUrl:strScanned withNav:self.navigationController];
        }];
        [browser setCurrentPhotoIndex:i];
        [self.navigationController pushViewController:browser animated:YES];
    }
}

- (void)enterGroupAnnouncement:(BOOL)isCanHidden { // 多个置顶数据，且点击的是新发布的群公告 isCanHidden 为 YES
    YUBWOIJWDGroupAnnouncementVC *vc = [[YUBWOIJWDGroupAnnouncementVC alloc] init];
    vc.isCanPost = NO;
    vc.announcement = _groupAnnouncement;
    if ([_targetGroup.owner isEqualToString:_groupAnnouncement.author]) {
        vc.type = Member_Type_Owner;
    }
    if ([self isGroupManager:_groupAnnouncement.author]) {
        vc.type = Member_Type_Manager;
    }
    [self.navigationController pushViewController:vc animated:YES];
    
    if (isCanHidden) {
        [NSUserDefaults.standardUserDefaults setValue:UNString(@"%ld", _groupAnnouncement.timestamp) forKey:kAnnouncementTimestamp];
        [self topMessageList];
    }
}

// 该删除方法，仅仅当topMessages.count = 1 时才会执行
- (void)yzdoajRemove:(UIButton *)sender {
    MessageTopList *topList = self.topMessages.firstObject;
    //公告
    if (topList.content.type == 2000) {
        [NSUserDefaults.standardUserDefaults setValue:UNString(@"%ld", _groupAnnouncement.timestamp) forKey:kAnnouncementTimestamp];
        [self topMessageList];
        return;
    }
    if (sender.selected) {
        if (self.topMessages.count <= 0) {
            return;
        }
        WS(weakself)
        [AppService.sharedAppService requestUrl:@"/group/message/top/delete" params:@{@"id":@(self.topMessages.firstObject.id)} success:^(NSDictionary * _Nonnull dict) {
            [weakself topMessageList];
        }error:^(int errCode, NSString * _Nonnull message) {
        }];
        return;
    }
    sender.selected = YES;
    sender.backgroundColor = UIColor.whiteColor;
    sender.layer.cornerRadius = 6.0;
}


- (void)setTopMsgIsHidden:(BOOL)topMsgIsHidden {
    if (self.topMessageView.isHidden == topMsgIsHidden) {
        return;
    }
    _topMsgIsHidden = topMsgIsHidden;
    
    self.topMessageView.hidden = topMsgIsHidden;
    if (topMsgIsHidden) { // 隐藏
        CGRect collectionViewFrame = self.collectionView.frame;
        collectionViewFrame.origin.y = 0.0;
        collectionViewFrame.size.height = self.backgroundView.bounds.size.height - CHAT_INPUT_BAR_HEIGHT;
        self.collectionView.frame = collectionViewFrame;
    }else {
        CGRect collectionViewFrame = self.collectionView.frame;
        collectionViewFrame.origin.y = 60.0;
        collectionViewFrame.size.height = self.backgroundView.bounds.size.height - CHAT_INPUT_BAR_HEIGHT - 60.0;
        self.collectionView.frame = collectionViewFrame;
    }
//    [self scrollToBottom:YES];
}


- (NSMutableArray<MessageTopList *> *)topMessages {
    if (!_topMessages) {
        _topMessages = NSMutableArray.new;
    }return _topMessages;
}

@end
