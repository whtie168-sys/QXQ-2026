//
//  MessageListViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/8/31.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "AIOIUEHMessageListVC.h"
#import <AVFoundation/AVFoundation.h>
#import "JUAHODJNKImagePreviewViewController.h"

#import "SMIOUEJImageCell.h"
#import "SMIOUEJTextCell.h"
#import "SMIOUEJVoiceCell.h"
#import "SMIOUEJLocationCell.h"
#import "SMIOUEJFileCell.h"
#import "SMIOUEJInformationCell.h"
#import "SMIOUEJCallSummaryCell.h"
#import "SMIOUEJStickerCell.h"
#import "SMIOUEJVideoCell.h"
#import "SMIOUEJMessageCell.h"
#import "SMIOUEJRecallCell.h"
#import "SMIOUEJCardCell.h"
#import "SMIOUEJCompositeCell.h"
#import "SMIOUEJLinkCell.h"
#import "SMIOUEJRichNotificationCell.h"
#import "JUAHODJNKBrowserVC.h"
#import <WFChatClient/WFCChatClient.h>
#import "WDCARChatInputBar.h"

#import "UIView+Toast.h"

#import "WDCARLocationViewController.h"
#import "WDCARLocationPoint.h"

#import "JUAHODJNKBrowserVC.h"

#import "MBProgressHUD.h"
#import "AIOIUEHMediaMessageDownloader.h"

#import "FCNUOEYForwardVC.h"

#import <WFChatClient/WFCChatClient.h>

#import "AIOIUEHConfigManager.h"
#import "HNWOUIDSeletedUserVC.h"

#import "DUVOHJNReceiptVC.h"

#import "UIColor+YH.h"
#import "DUVOHJNConversationSearchTableVC.h"


#import "DUVOHJNGroupInfoVC.h"
// #import "LUDHIOWIVChannelProfileVC.h"  // removed: channel feature

// #import "AIOIUEHQuoteVC.h"  // removed: unused by main app
#import "AIOIUEHCompositeMessageVC.h"

#import "AIOIUEHFavoriteItem.h"

#import "AIOIUEHUtilities.h"

// #import "SMIOUEJMultiCallOngoingCell.h"  // removed: voip feature
// #import "SMIOUEJMultiCallOngoingExpendedCell.h"  // removed: voip feature
#import "SMIOUEJArticlesCell.h"
#import "AIOIUEHImage.h"


#import "MWPhotoBrowser.h"

@interface AIOIUEHMessageListVC () <UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate, UINavigationControllerDelegate, SMIOUEJMessageCellDelegate, AVAudioPlayerDelegate, WDCARChatInputBarDelegate, UIGestureRecognizerDelegate, MWPhotoBrowserDelegate>  // SMIOUEJMultiCallOngoingExpendedCellDelegate removed: voip

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

@property (nonatomic, strong)NSMutableDictionary<NSString *, NSNumber *> *deliveryDict;
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
@end

@implementation AIOIUEHMessageListVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMessageReaded:) name:kMessageReaded object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSendingMessage:) name:kSendingMessageStatusUpdated object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMessageListChanged:) name:kMessageListChanged object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMessageUpdated:) name:kMessageUpdated object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMenuHidden:) name:UIMenuControllerDidHideMenuNotification object:nil];

    // voip: onCallStateChanged removed
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSettingUpdated:) name:kSettingUpdated object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTitle) name:kUserOnlineStateUpdated object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSecretChatStateChanged:) name:kSecretChatStateUpdated object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSecretMessageStartBurning:) name:kSecretMessageStartBurning object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSecretMessageBurned:) name:kSecretMessageBurned object:nil];
    
    
    self.chatInputBar = [[WDCARChatInputBar alloc] initWithSuperView:self.backgroundView conversation:self.conversation delegate:self];
    
    __weak typeof(self)ws = self;
    if(self.conversation.type == Single_Type) {
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.conversation.target refresh:YES];
        self.targetUser = userInfo;
    } else if(self.conversation.type == Group_Type) {
        WFCCGroupInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:self.conversation.target refresh:YES];
        self.targetGroup = groupInfo;
    } else if (self.conversation.type == Channel_Type) {
        WFCCChannelInfo *channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:self.conversation.target refresh:YES];
        self.targetChannel = channelInfo;
    } else if(self.conversation.type == Chatroom_Type) {
        
        [[WFCCIMService sharedWFCIMService] getChatroomInfo:self.conversation.target upateDt:ws.targetChatroom.updateDt success:^(WFCCChatroomInfo *chatroomInfo) {
            ws.targetChatroom = chatroomInfo;
        } error:^(int error_code) {
            
        }];
    } else if(self.conversation.type == SecretChat_Type) {
        self.secretChatInfo = [[WFCCIMService sharedWFCIMService] getSecretChatInfo:self.conversation.target];
    }
    
    if(self.conversation.type == Single_Type || self.conversation.type == SecretChat_Type) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    } else if(self.conversation.type == Group_Type) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupInfoUpdated:) name:kGroupInfoUpdated object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupMemberUpdated:) name:kGroupMemberUpdated object:nil];
    } else if(self.conversation.type == Channel_Type) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onChannelInfoUpdated:) name:kChannelInfoUpdated object:nil];
    }
    
    [self setupNavigationItem];
    
    self.orignalDraft = [[WFCCIMService sharedWFCIMService] getConversationInfo:self.conversation].draft;
    
    if (self.conversation.type == Chatroom_Type) {
        NSString *joinedChatroomId = [[WFCCIMService sharedWFCIMService] getJoinedChatroomId];

        if(![ws.conversation.target isEqualToString:joinedChatroomId]) {
            __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
            hud.label.text = @"进入聊天室...";
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
                hud.label.text = @"进入聊天室失败";
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
    
    if (self.conversation.type == Group_Type) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray<WFCCGroupMember *> *groupMembers = [[WFCCGroupDB sharedManager] getGroupMembers:self.conversation.target];
            NSMutableArray *memberIds = [[NSMutableArray alloc] init];
            for (WFCCGroupMember *member in groupMembers) {
                [memberIds addObject:member.memberId];
            }
            [[WFCCUserDB sharedManager] getUserInfos:memberIds inGroup:self.conversation.target];
        });
    }
    
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
    
    
    [self reloadMessageList];
}

- (void)onUserInfoUpdated:(NSNotification *)notification {
    NSArray<WFCCUserInfo *> *userInfoList = notification.userInfo[@"userInfoList"];
    for (WFCCUserInfo *userInfo in userInfoList) {
        if ([self.conversation.target isEqualToString:userInfo.userId]) {
            self.targetUser = userInfo;
            break;
        }
    }
}

- (void)onGroupInfoUpdated:(NSNotification *)notification {
    NSArray<WFCCGroupInfo *> *groupInfoList = notification.userInfo[@"groupInfoList"];
    for (WFCCGroupInfo *groupInfo in groupInfoList) {
        if ([self.conversation.target isEqualToString:groupInfo.target]) {
            self.targetGroup = groupInfo;
            break;
        }
    }
}

- (void)onGroupMemberUpdated:(NSNotification *)notification {
    if ([self.conversation.target isEqualToString:notification.object]) {
        self.targetGroup = self.targetGroup;
    }
}

- (void)onChannelInfoUpdated:(NSNotification *)notification {
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

- (void)setupNavigationItem {
    if (self.multiSelecting) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[AIOIUEHImage imageNamed:@"search"] style:UIBarButtonItemStyleDone target:self action:@selector(onSearchBarBtn:)];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Cancel") style:UIBarButtonItemStyleDone target:self action:@selector(onMultiSelectCancel:)];
    } else {
        if(self.conversation.type == Single_Type) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[AIOIUEHImage imageNamed:@"nav_chat_single"] style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
        } else if(self.conversation.type == Group_Type) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[AIOIUEHImage imageNamed:@"nav_chat_group"] style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
        } else if(self.conversation.type == Channel_Type) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[AIOIUEHImage imageNamed:@"nav_chat_channel"] style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
        } else if(self.conversation.type == SecretChat_Type) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[AIOIUEHImage imageNamed:@"nav_chat_single"] style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
        }
        if(self.presented) {
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStyleDone target:self action:@selector(onCloseBtn:)];
        } else {
            self.navigationItem.leftBarButtonItem = nil;
        }
    }
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] init];
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
    [[WFCCIMService sharedWFCIMService] getRemoteMessages:weakSelf.conversation before:self.lastUid count:10 contentTypes:nil success:^(NSArray<WFCCMessage *> *messages) {
        NSMutableArray *reversedMsgs = [[NSMutableArray alloc] init];
        for (WFCCMessage *msg in messages) {
            [reversedMsgs insertObject:msg atIndex:0];
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
        long lastIndex = 0;
        if (weakSelf.modelList.count) {
            lastIndex = [weakSelf.modelList firstObject].message.messageId;
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
    if(!self.silentJoinChatroom) {
        WFCCTipNotificationContent *tip = [[WFCCTipNotificationContent alloc] init];
        WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:[WFCCNetworkService sharedInstance].userId];
        tip.tip = [NSString stringWithFormat:WFCString(@"WelcomeJoinChatroomHint"), userInfo.displayName];
        [self sendMessage:tip];
    }
}

- (void)sendChatroomLeaveMessage {
    __block WFCCConversation *strongConv = self.conversation;
    if(!self.silentJoinChatroom) {
        dispatch_async(dispatch_get_main_queue(), ^{
            WFCCTipNotificationContent *tip = [[WFCCTipNotificationContent alloc] init];
            WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:[WFCCNetworkService sharedInstance].userId];
            tip.tip = [NSString stringWithFormat:WFCString(@"LeaveChatroomHint"), userInfo.displayName];
            
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

- (void)onRightBarBtn:(UIBarButtonItem *)sender {
}

- (void)onSearchBarBtn:(id)sender {
    if (self.multiSelecting) {
        for (AIOIUEHMessageModel *model in self.modelList) {
            if (model.selected && ![self.selectedMessageIds containsObject:@(model.message.messageId)]) {
                [self.selectedMessageIds addObject:@(model.message.messageId)];
            }
        }
        
        DUVOHJNConversationSearchTableVC *mvc = [[DUVOHJNConversationSearchTableVC alloc] init];
        mvc.conversation = self.conversation;
        mvc.hidesBottomBarWhenPushed = YES;
        mvc.messageSelecting = YES;
        mvc.selectedMessageIds = self.selectedMessageIds;
        [self.navigationController pushViewController:mvc animated:YES];
    }
}

- (void)updateTitle {
    if(self.conversation.type == Single_Type || self.conversation.type == SecretChat_Type) {
        if(self.targetUser.alias.length) {
            self.title = self.targetUser.alias;
        } else if(self.targetUser.displayName.length == 0) {
            self.title = [NSString stringWithFormat:@"%@<%@>", @"用户", self.conversation.target];
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
                            self.title = [NSString stringWithFormat:@"%@(%@)", self.title, @"电脑在线"];
                        } else if(padState == 0) {
                            self.title = [NSString stringWithFormat:@"%@(%@)", self.title, @"平板在线"];
                        } else if(webState == 0) {
                            self.title = [NSString stringWithFormat:@"%@(%@)", self.title, @"网页在线"];
                        } else if(wxState == 0) {
                            self.title = [NSString stringWithFormat:@"%@(%@)", self.title, @"小程序在线"];
                        } else if(mobileState == 0) {
                            self.title = [NSString stringWithFormat:@"%@(%@)", self.title, @"手机在线"];
                        }
                    } else if(onlineState.customState.state == 1) {
                        self.title = [NSString stringWithFormat:@"%@(%@)", self.title, @"忙碌"];
                    } else if(onlineState.customState.state == 2 || onlineState.customState.state == 3) {
                        self.title = [NSString stringWithFormat:@"%@(%@)", self.title, @"离开"];
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
        self.navigationItem.backBarButtonItem.title = self.title;
    } else if(self.conversation.type == Group_Type) {
        if(self.targetGroup.displayName.length == 0) {
            self.title = @"群聊";
            self.navigationItem.backBarButtonItem.title = @"信息";
        } else {
            self.title = [NSString stringWithFormat:@"%@(%d)", self.targetGroup.displayName, (int)self.targetGroup.memberCount];
            self.navigationItem.backBarButtonItem.title = self.targetGroup.displayName;
        }
    } else if(self.conversation.type == Channel_Type) {
        if(self.targetChannel.name.length == 0) {
            self.title = @"频道";
            self.navigationItem.backBarButtonItem.title = @"信息";
        } else {
            self.title = self.targetChannel.name;
            self.navigationItem.backBarButtonItem.title = self.targetChannel.name;
        }
    } else if (self.conversation.type == Chatroom_Type) {
        if(self.targetChatroom.title.length == 0) {
            self.title = @"聊天室";
            self.navigationItem.backBarButtonItem.title = @"信息";
        } else {
            self.title = self.targetChatroom.title;
            self.navigationItem.backBarButtonItem.title = self.targetChatroom.title;
        }
    }
}

- (void)setTargetUser:(WFCCUserInfo *)targetUser {
    _targetUser = targetUser;
    [self updateTitle];
}

- (void)setTargetGroup:(WFCCGroupInfo *)targetGroup {
    _targetGroup = targetGroup;
    [self updateTitle];
    
    ChatInputBarStatus defaultStatus = ChatInputBarDefaultStatus;
    WFCCGroupMember *member = [[WFCCGroupDB sharedManager] getGroupMember:targetGroup.target memberId:[WFCCNetworkService sharedInstance].userId];
    if (targetGroup.mute || member.type == Member_Type_Muted || [member.mute isEqualToString:@"1"]) {
        if ([targetGroup.owner isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
            self.chatInputBar.inputBarStatus =  defaultStatus;
        } else if(targetGroup.mute && member.type == Member_Type_Allowed) {
            self.chatInputBar.inputBarStatus =  defaultStatus;
        } else {
            WFCCGroupMember *gm = [[WFCCGroupDB sharedManager] getGroupMember:targetGroup.target memberId:[WFCCNetworkService sharedInstance].userId];
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
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:userId refresh:YES];
    self.targetUser = userInfo;
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
        [deleteBtn setTitle:@"删除" forState:UIControlStateNormal];
        [deleteBtn addTarget:self action:@selector(onDeleteMultiSelectedMessage:) forControlEvents:UIControlEventTouchDown];
        [deleteBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [_multiSelectPanel addSubview:deleteBtn];
        
        UIButton *forwardBtn = [[UIButton alloc] initWithFrame:CGRectMake(_multiSelectPanel.bounds.size.width/2, 0, _multiSelectPanel.bounds.size.width/2, _multiSelectPanel.bounds.size.height)];
        [forwardBtn setTitle:@"转发" forState:UIControlStateNormal];
        [forwardBtn addTarget:self action:@selector(onForwardMultiSelectedMessage:) forControlEvents:UIControlEventTouchDown];
        [forwardBtn setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
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
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:nil];
    
    UIAlertAction *oneByOneAction = [UIAlertAction actionWithTitle:@"逐条转发" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        FCNUOEYForwardVC *controller = [[FCNUOEYForwardVC alloc] init];
        controller.messages = messages;
//        UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:controller];
//        [self.navigationController presentViewController:navi animated:YES completion:nil];
        [self.navigationController pushViewController:controller animated:YES];

        
    }];
    UIAlertAction *AllInOneAction = [UIAlertAction actionWithTitle:@"合并转发" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        WFCCCompositeMessageContent *compositeContent = [[WFCCCompositeMessageContent alloc] init];

        if (self.conversation.type == Single_Type) {
            NSString *title = nil;
            if(self.targetUser.alias.length) {
                title = self.targetUser.alias;
            } else if(self.targetUser.displayName.length == 0) {
                title = [NSString stringWithFormat:@"%@<%@>", @"用户", self.conversation.target];
            } else {
                title = self.targetUser.displayName;
            }
            WFCCUserInfo *myself = [[WFCCUserDB sharedManager] getUserInfo:[WFCCNetworkService sharedInstance].userId];
            compositeContent.title = [NSString stringWithFormat:@"%@和%@ 的聊天记录", title, myself.displayName];
        } else if (self.conversation.type == Group_Type) {
            compositeContent.title = @"群的聊天记录";
        } else if (self.conversation.type == Channel_Type) {
            compositeContent.title = @"频道的聊天记录";
        } else if(self.conversation.type == SecretChat_Type) {
            compositeContent.title = @"密聊记录";
        } else {
            compositeContent.title = @"聊天记录";
        }
        
        compositeContent.messages = messages;
        WFCCMessage *msg = [[WFCCMessage alloc] init];
        msg.content = compositeContent;
        
        FCNUOEYForwardVC *controller = [[FCNUOEYForwardVC alloc] init];
        controller.message = msg;
//        UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:controller];
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
    
    self.backgroundView.backgroundColor = [AIOIUEHConfigManager globalManager].backgroudColor;
    self.collectionView.backgroundColor = [AIOIUEHConfigManager globalManager].backgroudColor;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.alwaysBounceVertical = YES;
    
    
    self.view.backgroundColor = self.collectionView.backgroundColor;
    
    [self registerCell:[SMIOUEJTextCell class] forContent:[WFCCTextMessageContent class]];
    [self registerCell:[SMIOUEJTextCell class] forContent:[WFCCPTextMessageContent class]];
    [self registerCell:[SMIOUEJImageCell class] forContent:[WFCCImageMessageContent class]];
    [self registerCell:[SMIOUEJVoiceCell class] forContent:[WFCCSoundMessageContent class]];
    [self registerCell:[SMIOUEJVoiceCell class] forContent:[WFCCPTTSoundMessageContent class]];
    [self registerCell:[SMIOUEJVideoCell class] forContent:[WFCCVideoMessageContent class]];
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
        if(userInfo.alias.length) {
            name = userInfo.alias;
        } else if(userInfo.groupAlias.length) {
            name = userInfo.groupAlias;
        } else if(userInfo.displayName.length) {
            name = userInfo.displayName;
        }
        
        NSString *title;
        if(typingType == Typing_VOICE) {
            title = @"对方正在录音...";
        } else if(typingType == Typing_CAMERA) {
            title = @"对方正在拍照...";
        } else if(typingType == Typing_LOCATION) {
            title = @"对方正在选取位置...";
        } else if(typingType == Typing_FILE) {
            title = @"对方正在选取文件...";
        } else {
            title = @"对方正在输入...";
        }
        self.title = [NSString stringWithFormat:@"%@ %@", name, title];
    } else if(self.typingDict.count > 1) {
        self.title = [NSString stringWithFormat:@"%ld人正在输入", self.typingDict.count];
    }
}

- (void)checkUserTyping {
    NSMutableArray<NSString *> *expiredKeys = [[NSMutableArray alloc] init];
    int64_t now = [[[NSDate alloc] init] timeIntervalSince1970];
    [self.typingDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary * _Nonnull obj, BOOL * _Nonnull stop) {
        int64_t timestamp = [obj[@"timestamp"] longLongValue];
        if(now - timestamp > 5) {
            [expiredKeys addObject:key];
        }
    }];
    [self.typingDict removeObjectsForKeys:expiredKeys];
    
    if(self.typingDict.count) {
        [self showTyping];
    } else {
        [self stopShowTyping];
    }
}

- (void)stopShowTyping {
    if(self.showTypingTimer != nil) {
        [self.showTypingTimer invalidate];
        self.showTypingTimer = nil;
        if (self.conversation.type == Single_Type || self.conversation.type == SecretChat_Type) {
            self.targetUser = self.targetUser;
        } else if(self.conversation.type == Group_Type) {
            self.targetGroup = self.targetGroup;
        } else if(self.conversation.type == Channel_Type) {
            self.targetChannel = self.targetChannel;
        } else if(self.conversation.type == Group_Type) {
            self.targetGroup = self.targetGroup;
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
    if (!self.firstAppear) {
        [self.chatInputBar willAppear];
    }
    
    self.tabBarController.tabBar.hidden = YES;
    [self.collectionView reloadData];
    
    if (self.navigationController.viewControllers.count > 1) {          // 记录系统返回手势的代理
        _scrollBackDelegate = self.navigationController.interactivePopGestureRecognizer.delegate;          // 设置系统返回手势的代理为当前控制器
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
    
    if (self.conversation.type == Group_Type) {
        self.showAlias = ![[WFCCIMService sharedWFCIMService] isHiddenGroupMemberName:self.targetGroup.target];
    }
    
    if (self.firstAppear) {
        self.firstAppear = NO;
        [self scrollToBottom:NO];
    }
    [self updateTitle];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSString *newDraft = self.chatInputBar.draft;
    if (![self.orignalDraft isEqualToString:newDraft]) {
        self.orignalDraft = newDraft;
        [[WFCCIMService sharedWFCIMService] setConversation:self.conversation draft:newDraft];
    }
    // 设置系统返回手势的代理为我们刚进入控制器的时候记录的系统的返回手势代理
    self.navigationController.interactivePopGestureRecognizer.delegate = _scrollBackDelegate;
    
    [self.chatInputBar resetInputBarStatue];
}


- (void)sendMessage:(WFCCMessageContent *)content {
    //发送消息时，client会发出"kSendingMessageStatusUpdated“的通知，消息界面收到通知后加入到列表中。
    __weak typeof(self) ws = self;
    NSMutableArray *tousers = nil;
    if (self.privateChatUser) {
        tousers = [[NSMutableArray alloc] init];
        [tousers addObject:self.privateChatUser];
    }
    [[WFCCIMService sharedWFCIMService] send:self.conversation content:content toUsers:tousers expireDuration:0 success:^(long long messageUid, long long timestamp) {
        NSLog(@"send message success");
        if ([content isKindOfClass:[WFCCStickerMessageContent class]]) {
            [ws saveStickerRemoteUrl:(WFCCStickerMessageContent *)content];
        }
        if(![content isKindOfClass:[WFCCTypingMessageContent class]]) {
            [ws.chatInputBar resetTyping];
        }
    } error:^(int error_code) {
        if ([content isKindOfClass:[WFCCStickerMessageContent class]]) {
            [ws removeLocalStickerPreviewForContent:(WFCCStickerMessageContent *)content];
        }
        NSLog(@"send message fail(%d)", error_code);
    }];
    
}

    // voip: onReceiveCallOngoingNotifications removed

- (void)onReceiveMessages:(NSNotification *)notification {
    NSArray<WFCCMessage *> *messages = notification.object;
    [self appendMessages:messages newMessage:YES highlightId:0 forceButtom:NO];
    
    // voip: ongoingCalls removed
    
    BOOL isActivelyViewingConversation = self.view.window != nil &&
        UIApplication.sharedApplication.applicationState == UIApplicationStateActive;
    if (isActivelyViewingConversation) {
        [[WFCCIMService sharedWFCIMService] clearUnreadStatus:self.conversation];
    }
}

- (void)onRecallMessages:(NSNotification *)notification {
    long long messageUid = [notification.object longLongValue];
    if (self.conversation.type != Chatroom_Type) {
        WFCCMessage *msg = [[WFCCIMService sharedWFCIMService] getMessageByUid:messageUid];
        if (msg != nil) {
            for (int i = 0; i < self.modelList.count; i++) {
                AIOIUEHMessageModel *model = [self.modelList objectAtIndex:i];
                if (model.message.messageUid == messageUid) {
                    model.message = msg;
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
    long long messageUid = [notification.object longLongValue];
    for (int i = 0; i < self.modelList.count; i++) {
        AIOIUEHMessageModel *model = [self.modelList objectAtIndex:i];
        if (model.message.messageUid == messageUid) {
            [self.modelList removeObject:model];
            [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]]];
            break;
        }
    }
}

- (void)onMessageUpdated:(NSNotification *)notification {
    long messageId = [notification.object longValue];
    BOOL isUpdated = NO;
    for (AIOIUEHMessageModel *model in self.modelList) {
        if(model.message.messageId == messageId) {
            if(model.message.conversation.type != Chatroom_Type) {
                model.message = [[WFCCIMService sharedWFCIMService] getMessage:messageId];
            }
            isUpdated = YES;
            break;
        }
    }
    
    if(isUpdated) {
        [self.modelList sortUsingComparator:^NSComparisonResult(AIOIUEHMessageModel *obj1, AIOIUEHMessageModel *obj2) {
            if (obj1.message.serverTime > obj2.message.serverTime) {
                return NSOrderedDescending;
            } else if(obj1.message.serverTime == obj2.message.serverTime) {
                return NSOrderedSame;
            } else {
                return NSOrderedAscending;
            }
        }];
        [self.collectionView reloadData];
    }
}

- (void)onMessageDelivered:(NSNotification *)notification {
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
                    groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:model.message.conversation.target refresh:NO];
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

- (void)onMessageReaded:(NSNotification *)notification {
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
    
    if (refresh) {
        self.readDict = [[WFCCIMService sharedWFCIMService] getConversationRead:self.conversation];
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
                    groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:model.message.conversation.target refresh:NO];
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

- (void)onSendingMessage:(NSNotification *)notification {
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
    if([notification.object isEqual:self.conversation]) {
        [self reloadMessageList];
    }
}

- (void)onSettingUpdated:(NSNotification *)notification {
    WFCCConversationInfo *info = [[WFCCIMService sharedWFCIMService] getConversationInfo:self.conversation];
    NSString *orignalDraftText = [self.chatInputBar getDraftText:self.orignalDraft];
    NSString *draftText = [self.chatInputBar getDraftText:info.draft];
    if(![orignalDraftText isEqualToString:draftText]) {
        self.orignalDraft = info.draft;
        self.chatInputBar.draft = info.draft;
    }
}

- (void)onSecretChatStateChanged:(NSNotification *)notification {
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
    self.readDict = [[WFCCIMService sharedWFCIMService] getConversationRead:self.conversation];
    
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
    [self.mentionedButton setTitle:[NSString stringWithFormat:@"%d 条消息", self.mentionedMsgs.count] forState:UIControlStateNormal];
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
    [self.tzboeuUnreadButton setTitle:[NSString stringWithFormat:@"%d 条新消息", self.unreadMessageCount] forState:UIControlStateNormal];
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
    NSString *objName = [NSString stringWithFormat:@"%d", [model.message.content.class getContentType]];
    
    SMIOUEJMessageCellBase *cell = nil;
    if(![self.cellContentDict objectForKey:@([model.message.content.class getContentType])]) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:[NSString stringWithFormat:@"%d", [WFCCUnknownMessageContent getContentType]] forIndexPath:indexPath];
    } else {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:objName forIndexPath:indexPath];
    }
    
    cell.delegate = self;
    
    [[NSNotificationCenter defaultCenter] removeObserver:cell];
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

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    AIOIUEHMessageModel *model = self.modelList[indexPath.row];
    Class cellCls = self.cellContentDict[@([[model.message.content class] getContentType])];
    if (!cellCls) {
        cellCls = self.cellContentDict[@([[WFCCUnknownMessageContent class] getContentType])];
    }
    return [cellCls sizeForCell:model withViewWidth:self.collectionView.frame.size.width];
}

#pragma mark - MessageCellDelegate
- (void)didTapMessageCell:(SMIOUEJMessageCellBase *)cell withModel:(AIOIUEHMessageModel *)model {
    if ([model.message.content isKindOfClass:[WFCCImageMessageContent class]] || [model.message.content isKindOfClass:[WFCCVideoMessageContent class]]) {
        if(self.conversation.type == SecretChat_Type) {
            typeof(self) ws = self;
            __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.label.text = @"加载中";
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
                            hud.label.text = @"加载失败";
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
            } else {
                self.imageMsgs = [[WFCCIMService sharedWFCIMService] getMessages:self.conversation contentTypes:@[@(MESSAGE_CONTENT_TYPE_IMAGE), @(MESSAGE_CONTENT_TYPE_VIDEO)] from:0 count:100 withUser:self.privateChatUser];
            }
            
            int i;
            for (i = 0; i < self.imageMsgs.count; i++) {
                if ([self.imageMsgs objectAtIndex:i].messageId == model.message.messageId) {
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
            if([model.message.content isKindOfClass:[WFCCVideoMessageContent class]]) {
                browser.autoPlayOnAppear = YES;
            } else {
                browser.autoPlayOnAppear = NO;
            }
            
            [browser setCurrentPhotoIndex:i];
            [self.navigationController pushViewController:browser animated:YES];
        }
    } else if([model.message.content isKindOfClass:[WFCCSoundMessageContent class]]) {
        if (model.message.direction == MessageDirection_Receive && model.message.status != Message_Status_Played) {
            if(model.message.conversation.type != SecretChat_Type) {
                [[WFCCIMService sharedWFCIMService] setMediaMessagePlayed:model.message.messageId];
                model.message.status = Message_Status_Played;
                [self.collectionView reloadItemsAtIndexPaths:@[[self.collectionView indexPathForCell:cell]]];
            }
        }
        
        [self prepardToPlay:model];
    } else if([model.message.content isKindOfClass:[WFCCLocationMessageContent class]]) {
        WFCCLocationMessageContent *locContent = (WFCCLocationMessageContent *)model.message.content;
        WDCARLocationViewController *vc = [[WDCARLocationViewController alloc] initWithLocationPoint:[[WDCARLocationPoint alloc] initWithCoordinate:locContent.coordinate andTitle:locContent.title]];
        [self.navigationController pushViewController:vc animated:YES];
    } else if ([model.message.content isKindOfClass:[WFCCFileMessageContent class]]) {
        WFCCFileMessageContent *fileContent = (WFCCFileMessageContent *)model.message.content;
        
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
    } else if([model.message.content isKindOfClass:[WFCCConferenceInviteMessageContent class]]) {
        // channel feature removed
        WFCCCardMessageContent *card = (WFCCCardMessageContent *)model.message.content;
        
        if (card.type == CardType_User) {
            WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:card.targetId];

        } else if(card.type == CardType_Group) {
            DUVOHJNGroupInfoVC *vc2 = [[DUVOHJNGroupInfoVC alloc] init];
            vc2.groupId = card.targetId;
            vc2.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc2 animated:YES];
        } // CardType_Channel removed
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


- (void)didDoubleTapMessageCell:(SMIOUEJMessageCellBase *)cell withModel:(AIOIUEHMessageModel *)model {
    if ([model.message.content isKindOfClass:[WFCCTextMessageContent class]]) {
        WFCCTextMessageContent *txtMsgContent = (WFCCTextMessageContent *)model.message.content;
        [self.chatInputBar resetInputBarStatue];
        
        UIView *textContainer = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        textContainer.backgroundColor = self.view.backgroundColor;
        
        UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, [AIOIUEHUtilities wf_navigationFullHeight], [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - [AIOIUEHUtilities wf_navigationFullHeight] - [AIOIUEHUtilities wf_safeDistanceBottom])];
         textView.text = txtMsgContent.text;
        textView.textAlignment = NSTextAlignmentCenter;
        textView.font = [UIFont systemFontOfSize:28];
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

- (void)didTapMessagePortrait:(SMIOUEJMessageCellBase *)cell withModel:(AIOIUEHMessageModel *)model {
    if(self.conversation.type == Group_Type) {
        if (self.targetGroup.privateChat) {
            if (![self.targetGroup.owner isEqualToString:model.message.fromUser] && ![self.targetGroup.owner isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                WFCCGroupMember *gm = [[WFCCGroupDB sharedManager] getGroupMember:self.conversation.target memberId:[WFCCNetworkService sharedInstance].userId];
                if (gm.type != Member_Type_Manager) {
                    WFCCGroupMember *gm = [[WFCCGroupDB sharedManager] getGroupMember:self.conversation.target memberId:model.message.fromUser];
                    if (gm.type != Member_Type_Manager) {
                        [self.view makeToast:@"管理员关闭了群组私聊权限" duration:1 position:CSToastPositionCenter];
                        return;
                    }
                }
            }
        }
    } else if(self.conversation.type == Channel_Type && model.message.direction == MessageDirection_Receive) {
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
    if (self.conversation.type == Group_Type) {
        if (model.message.direction == MessageDirection_Receive) {
            WFCCUserInfo *sender = [[WFCCUserDB sharedManager] getUserInfo:model.message.fromUser inGroup:self.conversation.target];
            NSString *userName = sender.groupAlias.length ? sender.groupAlias : sender.displayName;
            [self.chatInputBar appendMention:model.message.fromUser name:userName];
        }
    } else if(self.conversation.type == Channel_Type) {
        WFCCChannelInfo *channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:self.conversation.target refresh:NO];
        if ([channelInfo.owner isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:nil];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"与订阅者私聊" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                if (model.message.direction == MessageDirection_Receive) {
                    WFCCChannelInfo *channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:self.conversation.target refresh:NO];
                    if ([channelInfo.owner isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                        AIOIUEHMessageListVC *mvc = [[AIOIUEHMessageListVC alloc] init];
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
        [[WFCCIMService sharedWFCIMService] deleteMessage:model.message.messageId];
        [self sendMessage:model.message.content];
    }
}

- (void)didSelectUrl:(SMIOUEJMessageCellBase *)cell withModel:(AIOIUEHMessageModel *)model withUrl:(NSString *)urlString {
    JUAHODJNKBrowserVC *bvc = [[JUAHODJNKBrowserVC alloc] init];
    bvc.url = urlString;
    [self.navigationController pushViewController:bvc animated:YES];
}

- (void)didSelectPhoneNumber:(SMIOUEJMessageCellBase *)cell withModel:(AIOIUEHMessageModel *)model withPhoneNumber:(NSString *)phoneNumber {
    if(self.chatInputBar.inputBarStatus == ChatInputBarKeyboardStatus || self.chatInputBar.inputBarStatus == ChatInputBarEmojiStatus || self.chatInputBar.inputBarStatus == ChatInputBarPluginStatus) {
        self.chatInputBar.inputBarStatus = ChatInputBarDefaultStatus;
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:WFCString(@"PhoneNumberHint"), phoneNumber] message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *callAction = [UIAlertAction actionWithTitle:@"呼叫" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"telprompt:%@", phoneNumber]];
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
        }];

    }];
    
    UIAlertAction *copyAction = [UIAlertAction actionWithTitle:@"复制号码" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
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
    } else if ([msg.content isKindOfClass:[WFCCImageMessageContent class]]) {
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
 
        } else if(card.type == CardType_Group) {
            DUVOHJNGroupInfoVC *vc2 = [[DUVOHJNGroupInfoVC alloc] init];
            vc2.groupId = card.targetId;
            vc2.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc2 animated:YES];
        } // CardType_Channel removed
    } else {
        //有些消息内容不能在当前页面显示，跳转到新的页面显示
//            if ([msg.content isKindOfClass:[WFCCSoundMessageContent class]])
//            if ([msg.content isKindOfClass:[WFCCStickerMessageContent class]])
//            if ([msg.content isKindOfClass:[WFCCVideoMessageContent class]])
        // AIOIUEHQuoteVC *vc = [[AIOIUEHQuoteVC alloc] init];
        // vc.messageUid = msg.messageUid;
        // [self.navigationController pushViewController:vc animated:YES];
        
    }
}
- (void)didTaptzboeuQuoteLabel:(SMIOUEJMessageCellBase *)cell withModel:(AIOIUEHMessageModel *)model {
    WFCCQuoteInfo *quoteInfo = [SMIOUEJMessageCell quoteInfoForModel:model];
    if (quoteInfo) {
            __block WFCCMessage *msg = [[WFCCIMService sharedWFCIMService] getMessageByUid:quoteInfo.messageUid];
            if ([msg.content isKindOfClass:[WFCCRecallMessageContent class]]) {
                [self.view makeToast:@"消息不存在了！"];
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
                            [ws.view makeToast:@"消息不存在了！"];
                            NSLog(@"msg not exist");
                            return;
                        } else {
                            [ws showQuote:quoteInfo ofMessage:message];
                        }
                    } error:^(int error_code) {
                        if(error_code == 253) {
                            [ws.view makeToast:@"消息不存在了！"];
                        } else {
                            [ws.view makeToast:@"网络错误"];
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
    [[[UIAlertView alloc] initWithTitle:@"警告" message:@"网络错误" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
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

- (void)didTouchSend:(NSString *)stringContent withMentionInfos:(NSMutableArray<WFCUMetionInfo *> *)mentionInfos withQuoteInfo:(WFCCQuoteInfo *)quoteInfo {
    if (stringContent.length == 0) {
        return;
    }
    
    WFCCTextMessageContent *txtContent = [[WFCCTextMessageContent alloc] init];
    txtContent.text = stringContent;
    NSMutableArray *mentionTargets = [[NSMutableArray alloc] init];
    for (WFCUMetionInfo *mentionInfo in mentionInfos) {
        if (mentionInfo.mentionType == 2) {
            txtContent.mentionedType = 2;
            mentionTargets = nil;
            break;
        } else if(mentionInfo.mentionType == 1) {
            txtContent.mentionedType = 1;
            [mentionTargets addObject:mentionInfo.target];
        }
    }
    if (txtContent.mentionedType == 1) {
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
    self.orignalDraft = self.chatInputBar.draft;
    [[WFCCIMService sharedWFCIMService] setConversation:self.conversation draft:self.orignalDraft];
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
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"警告" message:@"文件内容超大，无法发送！" preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:WFCString(@"知道了") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    
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
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:[NSString stringWithFormat:@"无法发送文件夹: %@", file.lastPathComponent] preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                
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
    UIMenuController *menu = [UIMenuController sharedMenuController];
    
    UIMenuItem *deleteItem = [[UIMenuItem alloc]initWithTitle:@"删除" action:@selector(performDelete:)];
    UIMenuItem *cancelItem = [[UIMenuItem alloc]initWithTitle:WFCString(@"Cancel") action:@selector(performCancel:)];
    UIMenuItem *copyItem = [[UIMenuItem alloc]initWithTitle:@"复制" action:@selector(performCopy:)];
    UIMenuItem *forwardItem = [[UIMenuItem alloc]initWithTitle:@"转发" action:@selector(performForward:)];
    UIMenuItem *recallItem = [[UIMenuItem alloc]initWithTitle:@"撤回" action:@selector(performRecall:)];
    UIMenuItem *complainItem = [[UIMenuItem alloc]initWithTitle:@"投诉" action:@selector(performComplain:)];
    UIMenuItem *multiSelectItem = [[UIMenuItem alloc]initWithTitle:@"多选" action:@selector(performMultiSelect:)];
    UIMenuItem *quoteItem = [[UIMenuItem alloc]initWithTitle:@"引用" action:@selector(performQuote:)];
    UIMenuItem *favoriteItem = [[UIMenuItem alloc]initWithTitle:@"收藏" action:@selector(performFavorite:)];
    
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
    if ([msg.content isKindOfClass:[WFCCTextMessageContent class]]) {
        [items addObject:copyItem];
    }
    
    if (baseCell.model.message.direction == MessageDirection_Send && baseCell.model.message.status == Message_Status_Sending && [baseCell.model.message.content isKindOfClass:[WFCCMediaMessageContent class]]) {
        [items addObject:cancelItem];
    }
    
    if (baseCell.model.message.direction == MessageDirection_Receive) {
        [items addObject:complainItem];
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
            // [msg.content isKindOfClass:[WFCCConferenceInviteMessageContent class]] ||  // removed: channel feature
            [msg.content isKindOfClass:[WFCCCompositeMessageContent class]] ||
            //        [msg.content isKindOfClass:[WFCCSoundMessageContent class]] || //语音消息禁止转发，出于安全原因考虑，微信就禁止转发。如果您能确保安全，可以把这行注释打开
            [msg.content isKindOfClass:[WFCCStickerMessageContent class]]) {
            [items addObject:forwardItem];
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
            WFCCGroupInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:self.conversation.target refresh:NO];
            if([groupInfo.owner isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                canRecall = YES;
            } else {
                __block BOOL isMyselfManager = false;
                __block BOOL isTargetManager = false;
                NSArray *memberList = [[WFCCGroupDB sharedManager] getGroupMembers:self.conversation.target];
                [memberList enumerateObjectsUsingBlock:^(WFCCGroupMember * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj.memberId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
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
    
    [menu setMenuItems:items];
    self.cell4Menu = baseCell;
    
    [menu setMenuVisible:YES];
}


-(BOOL)canBecomeFirstResponder {
    return YES;
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if(self.cell4Menu) {
        if (action == @selector(performDelete:) || action == @selector(performCancel:) || action == @selector(performCopy:) || action == @selector(performForward:) || action == @selector(performRecall:) || action == @selector(performComplain:) || action == @selector(performMultiSelect:) || action == @selector(performQuote:) || action == @selector(performFavorite:)) {
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

- (void)deleteMessage:(long)messageId {
    [[WFCCIMService sharedWFCIMService] deleteMessage:messageId];
    [self deleteMessageUI:messageId];
}

-(void)performDelete:(UIMenuController *)sender {
    WFCCMessage *message = self.cell4Menu.model.message;
    if([[WFCCIMService sharedWFCIMService] isCommercialServer] && self.conversation.type != Channel_Type) {
        __weak typeof(self)weakSelf = self;

        UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"确认删除" message:nil preferredStyle:UIAlertControllerStyleActionSheet];

        UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {

        }];
        
        UIAlertAction *actionLocalDelete = [UIAlertAction actionWithTitle:@"仅删除本地消息" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf deleteMessage:message.messageId];
        }];
        
        [actionSheet addAction:actionLocalDelete];
        
        bool superGroup = false;
        if(self.conversation.type == Group_Type) {
            superGroup = self.targetGroup.superGroup>0;
        }
        
        //超级群组不支持远端删除
        if(!superGroup) {
            UIAlertAction *actionRemoteDelete = [UIAlertAction actionWithTitle:@"删除服务器及其他端消息" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:weakSelf.view animated:YES];
                hud.label.text = @"删除中";
                [hud showAnimated:YES];
                [[WFCCIMService sharedWFCIMService] deleteRemoteMessage:message.messageUid success:^{
                    [weakSelf deleteMessageUI:message.messageId];
                    [hud hideAnimated:YES];
                } error:^(int error_code) {
                    hud.mode = MBProgressHUDModeText;
                    hud.label.text = @"删除失败";
                    [hud hideAnimated:YES afterDelay:1.f];
                }];
            }];
            [actionSheet addAction:actionRemoteDelete];
        }
        [actionSheet addAction:actionCancel];
        
        [self presentViewController:actionSheet animated:YES completion:nil];
    } else {
        [self deleteMessage:message.messageId];
    }
}

-(void)performCancel:(UIMenuController *)sender {
    if (self.cell4Menu) {
        if(![[WFCCIMService sharedWFCIMService] cancelSendingMessage:self.cell4Menu.model.message.messageId]) {
            [self.view makeToast:@"取消失败" duration:1 position:CSToastPositionCenter];
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
        FCNUOEYForwardVC *controller = [[FCNUOEYForwardVC alloc] init];
        controller.message = self.cell4Menu.model.message;
//        UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:controller];
//        [self.navigationController presentViewController:navi animated:YES completion:nil];
        [self.navigationController pushViewController:controller animated:YES];

    }
}

-(void)performRecall:(UIMenuItem *)sender {
    if (self.cell4Menu.model.message) {
        __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.label.text = @"撤回中...";
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
                    [ws.collectionView reloadItemsAtIndexPaths:@[[ws.collectionView indexPathForCell:cell]]];
                }
            });
        } error:^(int error_code) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"错误码===%d",error_code);
                hud.mode = MBProgressHUDModeText;
                hud.label.text = @"撤回失败";
                [hud hideAnimated:YES afterDelay:1.f];
            });
        }];
    }
}

- (void)performComplain:(UIMenuItem *)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"投诉" message:@"如果您发现有违反法律和道德的内容，或者您的合法权益受到侵犯，请截图之后发送给我们。我们会在24小时之内处理。处理办法包括不限于删除内容，对作者进行警告，冻结账号，甚至报警处理。举报请到\"设置->设置->举报\"联系我们！" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:WFCString(@"确定") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
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
            [self.view makeToast:@"暂不支持" duration:1 position:CSToastPositionCenter];
            return;
        }
        
        item.sender = self.cell4Menu.model.message.fromUser;
        item.conversation = self.cell4Menu.model.message.conversation;
        if (self.cell4Menu.model.message.conversation.type == Single_Type || self.cell4Menu.model.message.conversation.type == SecretChat_Type) {
            WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:self.cell4Menu.model.message.fromUser];
            item.origin = userInfo.displayName;
        } else if (self.cell4Menu.model.message.conversation.type == Group_Type) {
            WFCCGroupInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:self.cell4Menu.model.message.conversation.target refresh:NO];
            item.origin = groupInfo.displayName;
        } else if (self.cell4Menu.model.message.conversation.type == Channel_Type) {
            WFCCChannelInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:self.cell4Menu.model.message.conversation.target refresh:NO];
            item.origin = groupInfo.name;
        } else {
            WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:self.cell4Menu.model.message.fromUser];
            item.origin = userInfo.displayName;
        }
        
        
        __weak typeof(self)ws = self;
        [[AIOIUEHConfigManager globalManager].appServiceProvider addFavoriteItem:item success:^{
            NSLog(@"added");
            [ws.view makeToast:@"已收藏" duration:1 position:CSToastPositionCenter];
        } error:^(int error_code) {
            NSLog(@"add failure");
            [ws.view makeToast:@"网络错误" duration:1 position:CSToastPositionCenter];
        }];
    }
}

- (void)onMenuHidden:(id)sender {
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

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    WFCCMessage *msg = self.imageMsgs[index];
    if([msg.content isKindOfClass:[WFCCImageMessageContent class]]) {
        WFCCImageMessageContent *imgCnt = (WFCCImageMessageContent *)msg.content;
        MWPhoto *photo = [MWPhoto photoWithURL:[NSURL URLWithString:imgCnt.remoteUrl]];
        photo.message = msg;
        return photo;
    } else if([msg.content isKindOfClass:[WFCCVideoMessageContent class]]) {
        WFCCVideoMessageContent *videoCnt = (WFCCVideoMessageContent *)msg.content;
        MWPhoto *photo = [MWPhoto videoWithURL:[NSURL URLWithString:videoCnt.remoteUrl]];
        photo.message = msg;
        return photo;
    }
    return nil;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    WFCCMessage *msg = self.imageMsgs[index];
    UIImage *image = nil;
    BOOL video = NO;
    if([msg.content isKindOfClass:[WFCCImageMessageContent class]]) {
        WFCCImageMessageContent *imgCnt = (WFCCImageMessageContent *)msg.content;
        image = imgCnt.thumbnail;
    } else if([msg.content isKindOfClass:[WFCCVideoMessageContent class]]) {
        WFCCVideoMessageContent *videoCnt = (WFCCVideoMessageContent *)msg.content;
        image = videoCnt.thumbnail;
        video = YES;
    }
    MWPhoto *photo = [MWPhoto photoWithImage:image];
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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
