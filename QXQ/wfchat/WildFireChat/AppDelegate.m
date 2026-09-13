//
//  AppDelegate.m
//  WUHOIBDK
//
//  Created by WF Chat on 2017/11/5.
//  Copyright © 2024 WildFireChat. All rights reserved.
//


// VoIP feature removed

#import "AppDelegate.h"
#import <Contacts/Contacts.h>
#import <WFChatClient/WFCChatClient.h>
#import "QZBGNRJYDIOZLoginVC.h"
#import "WFCConfig.h"
#import "QABWJEFDOCYTabBarVC.h"
//#import <WFChatUIKit/WFChatUIKit.h>
#import <UserNotifications/UserNotifications.h>
#import "PCLoginConfirmViewController.h"
#import "AppService.h"
#import "UIColor+YH.h"
#import "SharedConversation.h"
#import "SharePredefine.h"
#ifdef WFC_PTT
#import <PttClient/WFPttClient.h>
#endif

#import "OrgService.h"


#import "MBProgressHUD.h"

#import "WOPMKDIOFZTNormalQrcodeVC.h"
#import "EPIKNODWVScanQrVC.h"

#import "WOPMKDIOFZTNumberVC.h" // 1207
#import "RUJBVOGHUYMemberInfoVC.h"
#import "RUJBVOGHUYFriendInfoVC.h"
#import "YUBWOIJWDGroupInfoQrVC.h"

#import <objc/message.h>
#import "ProxyManager.h"

#import "KeyChainTool.h"
#import "Countly.h"
#import "SDWebImage/SDWebImage.h"
#import <WFChatClient/SRIMNetworkService.h>
#import <WFChatClient/WFCCConversationDB.h>
#import <WFChatClient/WFCCMessageDB.h>
#import <WFChatClient/WKDB.h>
#import "ConversationDeleteManager.h"

@interface AppDelegate () <ConnectionStatusDelegate, ConnectToServerDelegate, ReceiveMessageDelegate,SRIMConnectionStatusDelegate,
SRIMConnectToServerDelegate,SRIMReceiveMessageDelegate,
UNUserNotificationCenterDelegate, QrCodeDelegate
#ifdef WFC_PTT
,WFPttDelegate
#endif
>{
    BOOL _isChinese;
}
@property(nonatomic, strong) AVAudioPlayer *audioPlayer;
@property(nonatomic, strong) UILocalNotification *localCallNotification;

@property(nonatomic, assign) BOOL firstConnected;
@property(nonatomic, assign) BOOL syncingPendingRequests;
@property(nonatomic, assign) NSTimeInterval lastPendingRequestSyncTime;
@end

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#if DEBUG
    if([IM_SERVER_HOST rangeOfString:@"http"].location != NSNotFound || [IM_SERVER_HOST rangeOfString:@":"].location != NSNotFound) {
        NSLog(@"IM_SERVER_HOST只能填写IP或者域名，不能带HTTP头或者端口！！！");
        exit(-1);
    }
#endif
    _isChinese = [CommonHelper.main isChinese];
    [WFCCNetworkService sharedInstance].sendLogCommand = Send_Log_Command;
    [WFCCNetworkService startLog];
//    [[WFCCNetworkService sharedInstance] useSM4];
//    [WFCCNetworkService sharedInstance].connectionStatusDelegate = self;
    [WFCCNetworkService sharedInstance].connectToServerDelegate = self;
    [WFCCNetworkService sharedInstance].receiveMessageDelegate = self;
    [[WFCCNetworkService sharedInstance] setServerAddress:IM_SERVER_HOST];
    [[WFCCNetworkService sharedInstance] setBackupAddressStrategy:0];
    [WFCCNetworkService sharedInstance].defaultPortraitProvider = [AppService sharedAppService];
    
    [SRIMNetworkService sharedInstance].connectionStatusDelegate = self;
    [SRIMNetworkService sharedInstance].connectToServerDelegate = self;
    [SRIMNetworkService sharedInstance].receiveMessageDelegate = self;

//    [[WFCCNetworkService sharedInstance] setProxyInfo:nil ip:@"192.168.1.80" port:1080 username:nil password:nil];
//    [[WFCCNetworkService sharedInstance] setBackupAddress:@"192.168.1.120" port:80];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFriendRequestUpdated:) name:kFriendRequestUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRecallMessageNotif:) name:kRecallMessages object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRecallMessage:) name:kDeleteMessages object:nil];

    
    //当PC/Web在线时手机端是否静音，默认静音。如果修改为默认不静音，需要打开下面函数。
    //另外需要IM服务配置server.mobile_default_silent_when_pc_online为false。必须保持与服务器同步。
    //[[WFCCIMService sharedWFCIMService] setDefaultSilentWhenPcOnline:NO];

    [AIOIUEHConfigManager globalManager].appServiceProvider = [AppService sharedAppService];
    [AIOIUEHConfigManager globalManager].fileTransferId = FILE_TRANSFER_ID;
    [AIOIUEHConfigManager globalManager].orgServiceProvider = [OrgService sharedOrgService];
#ifdef WFC_PTT
    //初始化对讲SDK
    [WFPttClient sharedClient].delegate = self;
    BOOL keepBackgroundAlive = [[NSUserDefaults standardUserDefaults] boolForKey:@"WFC_PTT_BACKGROUND_KEEPALIVE"];
    if(keepBackgroundAlive) {
        [[WFPttClient sharedClient] setPlaySilent:@(YES)];
    }
    BOOL pttEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"WFC_PTT_ENABLED"];
    [WFPttClient sharedClient].enablePtt = pttEnabled;
#endif //WFC_PTT
        
    [self setupNavBar];
    self.window.backgroundColor = [UIColor whiteColor];
    
    setQrCodeDelegate(self);
    
    UIRemoteNotificationTypeSound;
    if (@available(iOS 10.0, *)) {
        //第一步：获取推送通知中心
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert|UNAuthorizationOptionSound|UNAuthorizationOptionBadge)
                              completionHandler:^(BOOL granted, NSError * _Nullable error) {
                                  if (!error) {
                                      NSLog(@"succeeded!");
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          [application registerForRemoteNotifications];
                                      });
                                  }
                              }];
    } else {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings
                                                settingsForTypes:(UIUserNotificationTypeBadge |
                                                                  UIUserNotificationTypeSound |
                                                                  UIUserNotificationTypeAlert)
                                                categories:nil];
        [application registerUserNotificationSettings:settings];
    }
    
    /**
     C7132C3F-1744-42C0-B8CA-50ACFC3F91AB    iPhone 15 Plus
     BE5E8DFD-F5E5-4E29-9AB7-C9068B967543   iPhone 15
     
     */
    // 我的-安全设置-设备  登录/注册时上报给服务端
    NSString *saveUUID = (NSString *)[KeyChainTool readData:kUUIDStringValue];
    if (saveUUID == nil || saveUUID.length <= 0) { // 说明未保存该数据
        NSString *UUID = [UIDevice.currentDevice.identifierForVendor UUIDString];
        [KeyChainTool saveData:UUID withIdentifier:kUUIDStringValue];
    }
    
    
    if (PIUODJNLockStatusManager.main.lockStatus.status == 1) { // 如果设置了安全锁
        [PIUODJNLockStatusManager.main reWriteLockInfo:@(0) ForKey:@"backgroundTime"];
        WOPMKDIOFZTNumberVC *vc = WOPMKDIOFZTNumberVC.new;
        vc.type = 4;
        WS(weakself)
        [vc setPswBlock:^(NSString * _Nonnull psw) {
            if ([psw isEqualToString:@"OK"]) {
                [weakself enterProject];
            }else if ([psw isEqualToString:@"ACCOUNT"]) { // 切换账号
                [weakself enterLogin];
            }else if ([psw isEqualToString:@"FORGET"]) { // 成功清除聊天数据后的回调
                [weakself enterLogin];
            }
        }];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        self.window.rootViewController = nav;
    }else {
        [self enterProject];
    }
    
//    NSString *savedToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedToken"];
//    NSString *savedUserId = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedUserId"];
//    if (savedToken.length > 0 && savedUserId.length > 0) {
//        //需要注意token跟clientId是强依赖的，一定要调用getClientId获取到clientId，然后用这个clientId获取token，这样connect才能成功，如果随便使用一个clientId获取到的token将无法链接成功。另外不能多次connect，如果需要切换用户请先disconnect，然后3秒钟之后再connect（如果是用户手动登录可以不用等，因为用户操作很难3秒完成，如果程序自动切换请等3秒）。
//        [[WFCCNetworkService sharedInstance] connect:savedUserId token:savedToken];
//        self.window.rootViewController = [QABWJEFDOCYTabBarVC new];
//    } else {
//        QZBGNRJYDIOZLoginVC *loginVC = [[QZBGNRJYDIOZLoginVC alloc] init];
//
//        //是否优先密码登录
//        loginVC.isPwdLogin = Prefer_Password_Login;
//        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
//        self.window.rootViewController = nav;
//    }
    
    
//    [self requestAuthorizationForAddressBook];
    [CommonHelper.main updateAppSuccess:^(BOOL isUpdate) {
    }];
    
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear]; // 0206 不允许用户与后台对象交互
    if ([NSUserDefaults.standardUserDefaults integerForKey:@"kFontSize"] <= 0) {
        [NSUserDefaults.standardUserDefaults setInteger:14 forKey:@"kFontSize"];
        [NSUserDefaults.standardUserDefaults synchronize];
        [[WFCCIMService sharedWFCIMService] setEnableSyncDraft:NO success:^{
        }error:^(int error_code) {
        }];
    }

    /** 推送通知 故障报告 自动视图跟踪
        CLYPushNotifications
        CLYCrashReporting
        CLYAutoViewTracking */
    CountlyConfig *config = CountlyConfig.new;
    config.appKey = @"75b6c7c0285637e00bebcfe185d5d9765e25445e";
    config.host = @"http://ec2-54-254-43-61.ap-southeast-1.compute.amazonaws.com:9090"; // http://api.866chat.com:9090
    config.enableAutomaticViewTracking = true;
    config.features = @[CLYPushNotifications, CLYCrashReporting];
    [Countly.sharedInstance startWithConfig:config];
    [Countly.sharedInstance askForNotificationPermission];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clearImageCache)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
    return YES;
}

- (void)clearImageCache {
    [[SDImageCache sharedImageCache] clearMemory]; // 清空内存缓存
}

- (void)enterProject {
    NSString *savedwebsocketToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedwebsocketToken"];
    NSString *savedUserId = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedUserId"];
    
    if (savedwebsocketToken.length > 0 && savedUserId.length > 0) {
        
#if TARGET_IPHONE_SIMULATOR//模拟器

#elif TARGET_OS_IPHONE//真机
    NSString *proxy = [ProxyManager.main getProxyStatus];
    if (proxy.length > 0 || proxy != nil) {
        UIAlertController * alertController = [UIAlertController alertControllerWithTitle:(_isChinese?@"网络异常，请检查是否开启代理":@"The network is abnormal. Check whether the proxy is enabled") message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alertController addAction:cancelAction];
        [UIApplication.sharedApplication.delegate.window.rootViewController presentViewController:alertController animated:YES completion:nil];
        return ;
    }
#endif
        
        //需要注意token跟clientId是强依赖的，一定要调用getClientId获取到clientId，然后用这个clientId获取token，这样connect才能成功，如果随便使用一个clientId获取到的token将无法链接成功。另外不能多次connect，如果需要切换用户请先disconnect，然后3秒钟之后再connect（如果是用户手动登录可以不用等，因为用户操作很难3秒完成，如果程序自动切换请等3秒）。
//        [[WFCCNetworkService sharedInstance] connect:savedUserId token:savedToken];
        
        // 切换数据库
        if([[WKDB sharedDB] needSwitchDB:savedUserId]) {
            [[WKDB sharedDB] switchDB:savedUserId];
            [[WFCCMessageDB sharedManager] setupDB];
            [[WFCCConversationDB sharedManager] setupDB];
            [[WFCCGroupDB sharedManager] setupDB];
            [[WFCCUserDB sharedManager] setupDB];
        }
        [WFCCNetworkService sharedInstance].userId = savedUserId;
        [[SRIMNetworkService sharedInstance] connect:savedUserId token:savedwebsocketToken];
        self.window.rootViewController = [QABWJEFDOCYTabBarVC new];
        
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"lastLoadRemoteMessageTs"];
        [self enterLogin];
    }
}
- (void)enterLogin {
    QZBGNRJYDIOZLoginVC *loginVC = [[QZBGNRJYDIOZLoginVC alloc] init];
    //是否优先密码登录
    loginVC.isPwdLogin = Prefer_Password_Login;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
    self.window.rootViewController = nav;
}

// 程序进入后台
- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self updateBadgeNumber];
    [self prepardDataForShareExtension];
}
// 程序回到app
- (void)applicationWillEnterForeground:(UIApplication *)application {
    
}

- (void)requestAuthorizationForAddressBook {
    CNAuthorizationStatus authorizationStatus = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    if (authorizationStatus == CNAuthorizationStatusNotDetermined) {
        [CNContactStore.new requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (granted) {
                [CommonHelper.main getMyAddressBook];
            }else {
                NSLog(@"授权失败===error=%@", error);
            }
        }];
    }else {
        [CommonHelper.main getMyAddressBook];
    }
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    // register to receive notifications
    [application registerForRemoteNotifications];
}

//会议需要支持方向旋转
-(UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    if([NSStringFromClass([window.rootViewController class]) isEqualToString:@"KUHIOJNRVConferenceVC"]) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
    }
    return UIInterfaceOrientationMaskPortrait;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    if ([deviceToken isKindOfClass:[NSData class]]) {
        const unsigned *tokenBytes = [deviceToken bytes];
        NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                              ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                              ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                              ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
        [WFCCNetworkService sharedInstance].pushToken = hexToken;
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"savedToken"]) {
            [[AppService sharedAppService] userBindIos:@{@"deviceToken": hexToken,@"topic":[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]}
                                               success:^{
                
            } error:^(int errCode, NSString * _Nonnull message) {
                
            }];
        }
    } else {
        NSString *token = [[[[deviceToken description] stringByReplacingOccurrencesOfString:@"<"
                                                                                 withString:@""]
                            stringByReplacingOccurrencesOfString:@">"
                            withString:@""]
                           stringByReplacingOccurrencesOfString:@" "
                           withString:@""];
        [WFCCNetworkService sharedInstance].pushToken = token;
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"savedToken"]) {
            [[AppService sharedAppService] userBindIos:@{@"deviceToken": token,@"topic":[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]}
                                               success:^{
                
            } error:^(int errCode, NSString * _Nonnull message) {
                
            }];
        }
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}



- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [WFCCNetworkService stopLog];
}

- (void)prepardDataForShareExtension {
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:WFC_SHARE_APP_GROUP_ID];//此处id要与开发者中心创建时一致
        
    //1. 保存app cookies
    NSString *authToken = [[AppService sharedAppService] getAppServiceAuthToken];
    if(authToken.length) {
        [sharedDefaults setObject:authToken forKey:WFC_SHARE_APPSERVICE_AUTH_TOKEN];
    } else {
        NSData *cookiesdata = [[AppService sharedAppService] getAppServiceCookies];
        if([cookiesdata length]) {
            NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookiesdata];
            NSHTTPCookie *cookie;
            for (cookie in cookies) {
                [[NSHTTPCookieStorage sharedCookieStorageForGroupContainerIdentifier:WFC_SHARE_APP_GROUP_ID] setCookie:cookie];
            }
        } else {
            NSArray *cookies = [[NSHTTPCookieStorage sharedCookieStorageForGroupContainerIdentifier:WFC_SHARE_APP_GROUP_ID] cookiesForURL:[NSURL URLWithString:APP_SERVER_ADDRESS]];
            for (NSHTTPCookie *cookie in cookies) {
                [[NSHTTPCookieStorage sharedCookieStorageForGroupContainerIdentifier:WFC_SHARE_APP_GROUP_ID] deleteCookie:cookie];
            }
        }
    }
    
    //2. 保存会话列表
    NSArray<WFCCConversationInfo*> *infos = [[WFCCIMService sharedWFCIMService] getConversationInfos:@[@(Single_Type), @(Group_Type), @(Channel_Type)] lines:@[@(0)]];
    NSMutableArray<SharedConversation *> *sharedConvs = [[NSMutableArray alloc] init];
    NSMutableArray<NSString *> *needComposedGroupIds = [[NSMutableArray alloc] init];
    //最多保存200个会话，再多就没有意义
    for (int i = 0; i < MIN(infos.count, 200); ++i) {
        WFCCConversationInfo *info = infos[i];
        SharedConversation *sc = [SharedConversation from:(int)info.conversation.type target:info.conversation.target line:info.conversation.line];
        if (info.conversation.type == Single_Type) {
            WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:info.conversation.target];
            if (!userInfo) {
                continue;
            }
            sc.title = userInfo.alias.length ? userInfo.alias : userInfo.displayName;
            sc.portraitUrl = userInfo.portrait;
        } else if (info.conversation.type == Group_Type) {
            WFCCGroupInfo *groupInfo = [[WFCCGroupDB sharedManager] getGroupInfoFromDB:info.conversation.target];
            if (!groupInfo) {
                continue;
            }
            sc.title = groupInfo.displayName;
            sc.portraitUrl = groupInfo.portrait;
            if (!groupInfo.portrait.length) {
                [needComposedGroupIds addObject:info.conversation.target];
            }
        } else if (info.conversation.type == Channel_Type) {
            WFCCChannelInfo *ci = [[WFCCIMService sharedWFCIMService] getChannelInfo:info.conversation.target refresh:NO];
            if (!ci) {
                continue;
            }
            sc.title = ci.name;
            sc.portraitUrl = ci.portrait;
        }
        [sharedConvs addObject:sc];
    }
    [sharedDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:sharedConvs] forKey:WFC_SHARE_BACKUPED_CONVERSATION_LIST];
    
    //3. 保存群拼接头像
    //获取分组的共享目录
    NSURL *groupURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:WFC_SHARE_APP_GROUP_ID];//此处id要与开发者中心创建时一致
    NSURL *portraitURL = [groupURL URLByAppendingPathComponent:WFC_SHARE_BACKUPED_GROUP_GRID_PORTRAIT_PATH];
    BOOL isDir = NO;
    if(![[NSFileManager defaultManager] fileExistsAtPath:portraitURL.path isDirectory:&isDir]) {
        NSError *error = nil;
        if(![[NSFileManager defaultManager] createDirectoryAtPath:portraitURL.path withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Error, cannot create group portrait folder for share extension");
            return;
        }
    } else {
        if(!isDir) {
            NSLog(@"Error, cannot create group portrait folder for share extension");
            return;
        }
    }
    int syncPortraitCount = 0;
    for (NSString *groupId in needComposedGroupIds) {
        //获取已经拼接好的头像，如果没有拼接会返回为空
        NSString *file = [WFCCUtilities getGroupGridPortrait:groupId width:80 generateIfNotExist:NO defaultUserPortrait:^UIImage *(NSString *userId) {
            return nil;
        }];
        
        if (file.length) {
            NSURL *fileURL = [portraitURL URLByAppendingPathComponent:groupId];
            
            BOOL needSync = NO;
            if([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
                NSDictionary* extensionPortraitAttribs = [[NSFileManager defaultManager] attributesOfItemAtPath:fileURL.path error:nil];
                NSDate *extensionPortraitDate = [extensionPortraitAttribs objectForKey:NSFileCreationDate];
                
                NSDictionary* containerPortraitAttribs = [[NSFileManager defaultManager] attributesOfItemAtPath:file error:nil];
                NSDate *containerPortraitDate = [containerPortraitAttribs objectForKey:NSFileCreationDate];
                needSync = extensionPortraitDate.timeIntervalSince1970 < containerPortraitDate.timeIntervalSince1970;
            } else {
                needSync = YES;
            }
            
            if(needSync) {
                syncPortraitCount++;
                NSData *data = [NSData dataWithContentsOfFile:file];
                [data writeToURL:fileURL atomically:YES];
                //群组头像每次同步30个，太多影响性能
                if(syncPortraitCount > 30) {
                    break;
                }
            }
        }
    }
}

- (void)onFriendRequestUpdated:(NSNotification *)notification {
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        NSArray<NSString *> *newRequests = notification.object;
        
        if (!newRequests.count) {
            return;
        }
        
        UILocalNotification *localNote = [[UILocalNotification alloc] init];
        if (@available(iOS 8.2, *)) {
            localNote.alertTitle = (_isChinese?@"收到好友邀请":@"Receive a Friend invitation");
        }
        
        if (newRequests.count == 1) {
            [[UserService shared] getUserInfo:newRequests[0] refresh:NO success:^(WFCCUserInfo * _Nonnull userInfo) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    WFCCFriendRequest *request = [[WFCCIMService sharedWFCIMService] getFriendRequest:newRequests[0] direction:1];
                    localNote.alertBody = [NSString stringWithFormat:@"%@:%@", (userInfo.alias.length > 0 ? userInfo.alias : userInfo.displayName), request.reason];
                    [[UIApplication sharedApplication] scheduleLocalNotification:localNote];
                });

            } error:^(int errorCode, NSString * _Nonnull message) {
                
            }];
        } else if(newRequests.count > 1) {
            if (_isChinese) {
                localNote.alertBody = [NSString stringWithFormat:@"您收到 %ld 条好友请求", newRequests.count];
            }else {
                localNote.alertBody = [NSString stringWithFormat:@"You received %ld friend requests", newRequests.count];
            }
            [[UIApplication sharedApplication] scheduleLocalNotification:localNote];
        }
    }
}

- (NSString *)pendingRequestSignatureKey {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    if (userId.length == 0) {
        userId = @"unknown";
    }
    return [NSString stringWithFormat:@"kPendingGroupRequestSignature_%@", userId];
}

- (WFCCConversation *)groupNotificationConversation {
    WFCCConversation *conversation = [[WFCCConversation alloc] init];
    conversation.type = Single_Type;
    conversation.line = 0;
    conversation.target = @"group_message";
    return conversation;
}

- (void)syncPendingRequestLists {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    if (userId.length == 0 || self.syncingPendingRequests) {
        return;
    }

    NSTimeInterval now = [NSDate date].timeIntervalSince1970;
    if (now - self.lastPendingRequestSyncTime < 3) {
        return;
    }
    self.lastPendingRequestSyncTime = now;
    self.syncingPendingRequests = YES;

    __block NSInteger pendingCount = 2;
    __weak typeof(self) weakSelf = self;
    void (^finishOne)(void) = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        pendingCount--;
        if (pendingCount <= 0) {
            strongSelf.syncingPendingRequests = NO;
        }
    };

    [[AppService sharedAppService] friendReqList:^(NSArray<WFCCFriendRequest *> * _Nonnull friends) {
        int count = 0;
        for (WFCCFriendRequest *friendRequest in friends) {
            BOOL expired = NSDate.date.timeIntervalSince1970 * 1000 - friendRequest.dt > 7 * 24 * 60 * 60 * 1000;
            if (friendRequest.status == 0 && !expired) {
                count++;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kNewFriendRequest" object:@(count)];
            finishOne();
        });
    } error:^(int errCode, NSString * _Nonnull message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            finishOne();
        });
    }];

    [[AppService sharedAppService] groupWaitAcceptList:^(NSArray<WaitAcceptList *> * _Nonnull groups) {
        [weakSelf updateGroupNotificationConversationWithWaitAcceptList:groups];
        dispatch_async(dispatch_get_main_queue(), ^{
            finishOne();
        });
    } error:^(int errCode, NSString * _Nonnull message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            finishOne();
        });
    }];
}

- (void)updateGroupNotificationConversationWithWaitAcceptList:(NSArray<WaitAcceptList *> *)groups {
    NSMutableArray<WaitAcceptList *> *pendingGroups = [NSMutableArray array];
    WaitAcceptList *latest = nil;
    for (WaitAcceptList *item in groups) {
        if (item.accept != 0) {
            continue;
        }
        [pendingGroups addObject:item];
        if (!latest || item.updateTime > latest.updateTime) {
            latest = item;
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        WFCCConversation *conversation = [self groupNotificationConversation];
        NSString *signatureKey = [self pendingRequestSignatureKey];
        if (pendingGroups.count == 0) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:signatureKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [[WFCCIMService sharedWFCIMService] clearUnreadStatus:conversation];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"WSRefrshGroup" object:nil];
            return;
        }

        NSString *latestId = latest.id.length > 0 ? latest.id : @"";
        NSString *signature = [NSString stringWithFormat:@"%lu_%@_%lld", (unsigned long)pendingGroups.count, latestId, latest.updateTime];
        NSString *lastSignature = [[NSUserDefaults standardUserDefaults] stringForKey:signatureKey];
        WFCCConversationInfo *conversationInfo = [[WFCCConversationDB sharedManager] getConversationInfo:conversation];
        if ([signature isEqualToString:lastSignature] && conversationInfo.lastMessage) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"WSRefrshGroup" object:nil];
            return;
        }

        WFCCMessage *message = [[WFCCMessage alloc] init];
        message.fromUser = @"group_message";
        message.serverTime = latest.updateTime > 0 ? latest.updateTime : [[NSDate date] timeIntervalSince1970] * 1000;
        message.messageUid = message.serverTime;
        message.status = Message_Status_Sent;
        message.direction = MessageDirection_Receive;
        message.conversation = conversation;

        WFCCTextMessageContent *content = [[WFCCTextMessageContent alloc] init];
        content.text = pendingGroups.count > 1 ?
        [NSString stringWithFormat:(_isChinese ? @"您有%lu条群邀请待处理" : @"You have %lu pending group invitations"), (unsigned long)pendingGroups.count] :
        (_isChinese ? @"您有一条群邀请待处理" : @"You have a pending group invitation");
        message.content = content;

        [[WFCCMessageDB sharedManager] storeMessageAndUpdateConversation:message];
        [[NSUserDefaults standardUserDefaults] setObject:signature forKey:signatureKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"WSRefrshGroup" object:nil];
    });
}

- (BOOL)shouldMuteNotification {
    BOOL isNoDisturbing = [[WFCCIMService sharedWFCIMService] isNoDisturbing];
    
    
    //免打扰
    if (isNoDisturbing) {
        return YES;
    }
    
    //全局静音
    if ([[WFCCIMService sharedWFCIMService] isGlobalSilent]) {
        return YES;
    }
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
//    [[AppService sharedAppService] getUserInfo:userId
//                                       success:^(WFCCUserInfo * _Nonnull userInfo) {
//        if (userInfo.userExtra.sound == 0) {
//            return;
//        }
//    } error:^(int errCode, NSString * _Nonnull message) {
//        
//    }];
    WFCCUserInfo *userInfo = [[AppCache sharedAppCache] getMyInfo];
    if ([UserExtraInfo mj_objectWithKeyValues:userInfo.extra].sound == 0) { // 0130 添加
        return YES;
    }
    
    BOOL pcOnline = [[WFCCIMService sharedWFCIMService] getPCOnlineInfos].count > 0;
    BOOL muteWhenPcOnline = [[WFCCIMService sharedWFCIMService] isMuteNotificationWhenPcOnline];
    
    if(pcOnline && muteWhenPcOnline) {
        return YES;
    }
    
    return NO;
}

- (void)onReceiveMessage:(NSArray<WFCCMessage *> *)messages hasMore:(BOOL)hasMore {
    NSInteger count = [self updateBadgeNumber];
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        if([self shouldMuteNotification]) {
            return;
        }
        
        for (WFCCMessage *msg in messages) {
            [self notificationForMessage:msg badgeCount:count];
        }
        
    } else if([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        WFCCPCLoginRequestMessageContent *pcLoginRequest;
        for (WFCCMessage *msg in messages) {
            if (([[NSDate date] timeIntervalSince1970] - (msg.serverTime - [WFCCNetworkService sharedInstance].serverDeltaTime)/1000) < 60) {
                if ([msg.content isKindOfClass:[WFCCPCLoginRequestMessageContent class]]) {
                    pcLoginRequest = (WFCCPCLoginRequestMessageContent *)msg.content;
                }
            }
        }
        if (pcLoginRequest) {
            __block UINavigationController *nav;
            if ([self.window.rootViewController isKindOfClass:[UINavigationController class]]) {
                nav = (UINavigationController *)self.window.rootViewController;
            } else if ([self.window.rootViewController isKindOfClass:[UITabBarController class]]) {
                UITabBarController *tab = (UITabBarController *)self.window.rootViewController;
                [tab.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj isKindOfClass:[UINavigationController class]]) {
                        nav = obj;
                        *stop = YES;
                    }
                }];
            }
            
            if (nav) {
                PCLoginConfirmViewController *vc2 = [[PCLoginConfirmViewController alloc] init];
                vc2.sessionId = pcLoginRequest.sessionId;
                vc2.platform = pcLoginRequest.platform;
                vc2.modalPresentationStyle = UIModalPresentationFullScreen;
                [self.window.rootViewController presentViewController:vc2 animated:YES completion:nil];
            } else {
                NSLog(@"怎么样才能模态弹出PC登录确认画面呢？");
            }
            
        }
    }
}

- (void)applyApplicationBadgeNumber:(NSInteger)count {
    NSInteger safeCount = MAX(0, count);
    dispatch_block_t updateBlock = ^{
        if (@available(iOS 16.0, *)) {
            [[UNUserNotificationCenter currentNotificationCenter] setBadgeCount:safeCount
                                                           withCompletionHandler:^(NSError * _Nullable error) {
                if (error) {
                    NSLog(@"更新桌面角标失败: %@", error);
                }
            }];
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [UIApplication sharedApplication].applicationIconBadgeNumber = safeCount;
#pragma clang diagnostic pop
        }
    };

    if (NSThread.isMainThread) {
        updateBlock();
    } else {
        dispatch_async(dispatch_get_main_queue(), updateBlock);
    }
}

// 该方法是收到消息后的推送推送 applicationIconBadgeNumber
- (void)notificationForMessage:(WFCCMessage *)msg badgeCount:(NSInteger)count {
    //当在后台活跃时收到新消息，需要弹出本地通知。有一种可能时客户端已经收到远程推送，然后由于voip/backgroud fetch在后台拉活了应用，此时会收到接收下来消息，因此需要避免重复通知
    if (([[NSDate date] timeIntervalSince1970] - (msg.serverTime - [WFCCNetworkService sharedInstance].serverDeltaTime)/1000) > 3) {
        return;
    }
    
    if (msg.direction == MessageDirection_Send) {
        return;
    }
    
    // NO 是开启  YES 为关闭 0730
    if ([NSUserDefaults.standardUserDefaults boolForKey:kIsAllowNotification] == YES ||
        [NSUserDefaults.standardUserDefaults boolForKey:kSuspensionNotice] == YES) {
        return; // 有其中一个为关闭状态，则不允许通知 0730
    }
    
    int flag = (int)[msg.content.class performSelector:@selector(getContentFlags)];
    WFCCConversationInfo *info = [[WFCCIMService sharedWFCIMService] getConversationInfo:msg.conversation];
    if(((flag & 0x03) || [msg.content isKindOfClass:[WFCCRecallMessageContent class]]) && !info.isSilent && ![msg.content isKindOfClass:[WFCCCallStartMessageContent class]]) {

      UILocalNotification *localNote = [[UILocalNotification alloc] init];
        if([[WFCCIMService sharedWFCIMService] isHiddenNotificationDetail] && ![msg.content isKindOfClass:[WFCCRecallMessageContent class]]) {
            localNote.alertBody = (_isChinese?@"您收到了新消息":@"You have received a new message");
        } else {
            localNote.alertBody = [msg digest];
        }
        if(msg.conversation.type == SecretChat_Type) {
            localNote.alertBody = (_isChinese?@"您收到了新的密聊消息":@"You have received a new secret chat message");
        }
      if (msg.conversation.type == Single_Type) {
          WFCCUserInfo *sender = [[WFCCUserDB sharedManager] getUserInfo:msg.conversation.target];
        if (sender.displayName) {
            if (@available(iOS 8.2, *)) {
                localNote.alertTitle = sender.displayName;
            } else {
                // Fallback on earlier versions
            }
        }
      } else if(msg.conversation.type == Group_Type) {
          WFCCGroupInfo *group = [[WFCCGroupDB sharedManager] getGroupInfoFromDB:msg.conversation.target];
          WFCCUserInfo *sender = [[WFCCUserDB sharedManager] getUserInfo:msg.fromUser];
          if (sender.displayName && group.displayName) {
              if (@available(iOS 8.2, *)) {
                  localNote.alertTitle = [NSString stringWithFormat:@"%@@%@:", sender.displayName, group.displayName];
              } else {
                  // Fallback on earlier versions
              }
          }else if (sender.displayName) {
              if (@available(iOS 8.2, *)) {
                  localNote.alertTitle = sender.displayName;
              } else {
                  // Fallback on earlier versions
              }
          }
          if (msg.status == Message_Status_Mentioned || msg.status == Message_Status_AllMentioned) {
              if (sender.displayName) {
                  if (_isChinese) {
                      localNote.alertBody = [NSString stringWithFormat:@"%@在群里@了你", sender.displayName];
                  }else {
                      localNote.alertBody = [NSString stringWithFormat:@"%@ @ in the group of you", sender.displayName];
                  }
              } else {
                  if (_isChinese) {
                      localNote.alertBody = @"有人在群里@了你";
                  }else {
                      localNote.alertBody = @"Someone in the group @you";
                  }
              }
                  
          }
      } else if (msg.conversation.type == SecretChat_Type) {
          NSString *userId = [[WFCCIMService sharedWFCIMService] getSecretChatInfo:msg.conversation.target].userId;
          WFCCUserInfo *sender = [[WFCCUserDB sharedManager] getUserInfo:userId];
          if (sender.displayName) {
              if (@available(iOS 8.2, *)) {
                  localNote.alertTitle = sender.displayName;
              } else {
                  // Fallback on earlier versions
              }
          }
      } else if(msg.conversation.type == Channel_Type) {
          WFCCChannelInfo *channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:msg.conversation.target refresh:NO];
          localNote.alertTitle = channelInfo.name;
      }
        if ([NSUserDefaults.standardUserDefaults boolForKey:kDesktopCornerMark] == YES) { // NO 是开启  YES 为关闭 0730 关闭了角标
            localNote.applicationIconBadgeNumber = 0;
        }else {
            localNote.applicationIconBadgeNumber = count;
        }
        localNote.userInfo = @{@"conversationType" : @(msg.conversation.type), @"conversationTarget" : msg.conversation.target, @"conversationLine" : @(msg.conversation.line), @"messageUid":@(msg.messageUid) };
    
      
        dispatch_async(dispatch_get_main_queue(), ^{
          [[UIApplication sharedApplication] scheduleLocalNotification:localNote];
        });
    }
}
// delegate 未读数量
- (NSInteger)updateBadgeNumber {
    // NO 是开启  YES 为关闭 0730
    if ([NSUserDefaults.standardUserDefaults boolForKey:kIsAllowNotification] == YES ||
        [NSUserDefaults.standardUserDefaults boolForKey:kDesktopCornerMark] == YES) { // 有其中一个为关闭状态，则不显示桌面角标0730
        
        [self applyApplicationBadgeNumber:0];
        return 0;
    }
    NSArray<WFCCConversationInfo *> *conversations = [[WFCCIMService sharedWFCIMService] getConversationInfos:@[@(Single_Type), @(Group_Type), @(Channel_Type), @(SecretChat_Type), @(Chatroom_Type), @(Things_Type)] lines:@[@(0)]];
    int count = 0;
    for (WFCCConversationInfo *info in conversations) {
        if ([[ConversationDeleteManager shared] shouldDeleteScheduleWithTarget:info.conversation.target]) {
            continue;
        }
        count += info.unreadCount.unread;
    }
    [self applyApplicationBadgeNumber:count];
    return count;
}

- (void)onRecallMessageNotif:(NSNotification *)notif {
    [self onRecallMessage:[[notif object] longLongValue]];
}

- (void)onRecallMessage:(long long)messageUid {
    [self cancelNotification:messageUid];
    NSInteger count = [self updateBadgeNumber];
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        if([self shouldMuteNotification]) {
            return;
        }
        WFCCMessage *msg = [[WFCCIMService sharedWFCIMService] getMessageByUid:messageUid];
        if(msg) {
            [self notificationForMessage:msg badgeCount:count];
        }
    }
}

- (void)onDeleteMessageNotif:(NSNotification *)notif {
    [self onDeleteMessage:[[notif object] longLongValue]];
}

- (void)onDeleteMessage:(long long)messageUid {
    [self cancelNotification:messageUid];
    [self updateBadgeNumber];
}

- (BOOL)cancelNotification:(long long)messageUid {
    __block BOOL canceled = NO;
    [[[UIApplication sharedApplication] scheduledLocalNotifications] enumerateObjectsUsingBlock:^(UILocalNotification * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj.userInfo[@"messageUid"] longLongValue] == messageUid) {
            [[UIApplication sharedApplication] cancelLocalNotification:obj];
            *stop = YES;
            canceled = YES;
        }
    }];
    return YES;
}

- (void)jumpToLoginViewController:(BOOL)isKickedOff {
    QZBGNRJYDIOZLoginVC *loginVC = [[QZBGNRJYDIOZLoginVC alloc] init];
    loginVC.isKickedOff = isKickedOff;
    loginVC.isPwdLogin = YES;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
    self.window.rootViewController = nav;
}

- (void)onConnectionStatusChanged:(ConnectionStatus)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (status == kConnectionStatusRejected || status == kConnectionStatusTokenIncorrect ||
            status == kConnectionStatusSecretKeyMismatch || status == kConnectionStatusKickedoff) {
            if(status == kConnectionStatusKickedoff) {
                [self jumpToLoginViewController:YES];
            }
            
            [[WFCCNetworkService sharedInstance] disconnect:YES clearSession:NO];
            [[SRIMNetworkService sharedInstance] disconnect:YES clearSession:NO];

            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedToken"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedUserId"];
            [[AppService sharedAppService] clearAppServiceAuthInfos];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
//            [KeyChainTool saveData:UNString(@"%.03lf", [NSDate.date timeIntervalSince1970]) withIdentifier:@"kCustomerService_TimeInterval"];
        } else if (status == kConnectionStatusLogout) {
            BOOL alreadyShowLoginVC = NO;
            if([self.window.rootViewController isKindOfClass:UINavigationController.class]) {
                UINavigationController *nav = (UINavigationController *)self.window.rootViewController;
                if(nav.viewControllers.count == 1 && [nav.viewControllers[0] isKindOfClass:QZBGNRJYDIOZLoginVC.class]) {
                    alreadyShowLoginVC = YES;
                }
            }
            
            if(!alreadyShowLoginVC) {
                [self jumpToLoginViewController:NO];
            }
            
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedToken"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedUserId"];
            [[AppService sharedAppService] clearAppServiceAuthInfos];
            [[OrgService sharedOrgService] clearOrgServiceAuthInfos];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            self.firstConnected = NO;
        } else if(status == kConnectionStatusConnected) {
            // 每次 WebSocket 连接成功都补拉一次，不能依赖会话列表页面是否已创建。
            [[AppService sharedAppService] loadRemoteMessage:^(NSArray<WFCCConversationInfo *> *groups) {
            } error:^(int errCode, NSString *message) {
                NSLog(@"load remote message failed, code: %d, message: %@", errCode, message);
            }];
            [self syncPendingRequestLists];
            if(!self.firstConnected) {
                self.firstConnected = YES;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self prepardDataForShareExtension];
                });
                
                [[OrgService sharedOrgService] login:^{
                    NSLog(@"on org service login success");
                    [[LUDHIOWIVOrganizationCache sharedCache] loadMyOrganizationInfos];
                } error:^(int errCode) {
                    NSLog(@"on org service login failure");
                }];
            }
        } else if(status == kConnectionStatusNotLicensed) {
            NSLog(@"专业版IM服务没有授权或者授权过期！！！");
            [self.window.rootViewController.view makeToast:(self->_isChinese?@"专业版IM服务没有授权或者授权过期！！！":@"Pro IM service is not authorized or expired!!") duration:3 position:CSToastPositionCenter];
        } else if(status == kConnectionStatusTimeInconsistent) {
            NSLog(@"服务器和客户端时间相差太大！！！");
            [self.window.rootViewController.view makeToast:(self->_isChinese?@"服务器和客户端时间相差太大！！！":@"Server and client time difference is too big!!") duration:3 position:CSToastPositionCenter];
        }
    });
}

- (void)onConnectToServer:(NSString *)host ip:(NSString *)ip port:(int)port {
    NSLog(@"connect to server %@,%@,%d", host, ip, port);
}

- (void)setupNavBar {
    [AIOIUEHConfigManager.globalManager setSelectedTheme:ThemeType_White];
//    [[AIOIUEHConfigManager globalManager] setupNavBar];
    [self setupNaviTabbar];
}
/**
 * navi  tabber  setup
 */
- (void)setupNaviTabbar {
    [UINavigationBar.appearance setTintColor:UIColor.blackColor];
    [UINavigationBar.appearance setBarTintColor:UIColor.whiteColor];
    [UINavigationBar.appearance setTitleTextAttributes:@{NSForegroundColorAttributeName:UIColor.blackColor}];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
    [UITabBar appearance].backgroundColor = UIColor.whiteColor;
//    [UITabBar appearance].backgroundImage = UIImage.new;
//    [UITabBar appearance].translucent = NO;
    if (@available(iOS 13.0, *)) {
        self.window.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
        UINavigationBarAppearance *navBar = [[UINavigationBarAppearance alloc] init];
        navBar.backgroundColor = UIColor.whiteColor;
        navBar.shadowColor = UIColor.clearColor;
        [navBar setTitleTextAttributes:@{NSForegroundColorAttributeName:UIColor.blackColor}];
        UINavigationBar.appearance.standardAppearance = navBar;
        UINavigationBar.appearance.scrollEdgeAppearance = navBar;
    }
    
    [[UINavigationBar appearance] setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setShadowImage:[[UIImage alloc] init]];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [self handleUrl:[url absoluteString] withNav:application.delegate.window.rootViewController.navigationController];
}
//NSInteger waxiouvTimeInterval = (NSInteger)[[NSDate.date dateByAddingTimeInterval:7*24*60*60] timeIntervalSince1970];
//_qrStr = [NSString stringWithFormat:@"%ld####wildfirechat://user/%@", waxiouvTimeInterval, WFCCNetworkService.sharedInstance.userId];
- (BOOL)handleUrl:(NSString *)str withNav:(UINavigationController *)navigator {
    NSLog(@"扫码结束后==%@", str); // wildfirechat://user/9ygqmws2k
    if ([str rangeOfString:@"wildfirechat://user" options:NSCaseInsensitiveSearch].location == 0) {
//    if ([str rangeOfString:@"wildfirechat://user"].location != NSNotFound) {
        // wildfirechat://user/(用户id)####(时间戳/有效期)
        NSArray *results = [str componentsSeparatedByString:@"####"];
        if (results.count <= 1) {
            [SVProgressHUD showErrorWithStatus:(_isChinese?@"该二维码已过期，请重新生成":@"The QR code has expired. Please re-create it")];
            [SVProgressHUD dismissWithDelay:1.0];
            return YES;
        }
        if (results.count == 2) {
            NSInteger waxiouvTimeInterval = [results.lastObject integerValue];
            NSInteger currentTimeInterval = [NSDate.date timeIntervalSince1970];
            if (currentTimeInterval > waxiouvTimeInterval) {
                [SVProgressHUD showErrorWithStatus:(_isChinese?@"该二维码已过期，请重新生成":@"The QR code has expired. Please re-create it")];
                [SVProgressHUD dismissWithDelay:1.0];
                return YES;
            }
        }
        NSURLComponents *components = [NSURLComponents componentsWithString:results.firstObject];
        NSString *fromUserId;
        for (NSURLQueryItem *item in components.queryItems) {
            if([@"from" isEqualToString:item.name]) {
                fromUserId = item.value;
                break;
            }
        }
        NSString *userId = components.path.lastPathComponent;
        if (userId.length <= 0) {
            [SVProgressHUD showErrorWithStatus:(_isChinese?@"该二维码存在问题":@"There are problems with the QR code")];
            [SVProgressHUD dismissWithDelay:1.0];
            return YES;
        }
        BOOL isMyFriend = [[WFCCIMService sharedWFCIMService] isMyFriend:userId]; // 本人与本人不是好友关系
        if (isMyFriend) { // 是好友关系
            RUJBVOGHUYMemberInfoVC *vc = RUJBVOGHUYMemberInfoVC.new;
            vc.hidesBottomBarWhenPushed = YES;
            vc.userId = userId;
            [navigator pushViewController:vc animated:YES];
        }else { // 本人或者 非好友关系
            RUJBVOGHUYFriendInfoVC *vc = RUJBVOGHUYFriendInfoVC.new;
            vc.hidesBottomBarWhenPushed = YES;
            vc.userId = userId;
            [navigator pushViewController:vc animated:YES];
        }
        
        return YES;
    } else if ([str rangeOfString:@"wildfirechat://group" options:NSCaseInsensitiveSearch].location == 0) {
        //wildfirechat://group/groupId?from=fromUserId
        NSURLComponents *components = [NSURLComponents componentsWithString:str];
        NSString *fromUserId;
        for (NSURLQueryItem *item in components.queryItems) {
            if([@"from" isEqualToString:item.name]) {
                fromUserId = item.value;
                break;
            }
        }
        NSString *groupId = components.path.lastPathComponent;
        
        YUBWOIJWDGroupInfoQrVC *vc = YUBWOIJWDGroupInfoQrVC.new;
        vc.groupId = groupId;
        vc.sourceType = GroupMemberSource_QrCode;
        vc.hidesBottomBarWhenPushed = YES;
        [navigator pushViewController:vc animated:YES];
        return YES;
    } else if ([str rangeOfString:@"wildfirechat://pcsession" options:NSCaseInsensitiveSearch].location == 0) {
//        str = @"wildfirechat://pcsession/mysessionid?platform=3";
        NSURL *URL = [NSURL URLWithString:str];
        
        NSString *sessionId = [URL lastPathComponent];
        NSMutableDictionary *params = [[NSMutableDictionary alloc]initWithCapacity:2];
        NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:str];
        [urlComponents.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [params setObject:obj.value forKey:obj.name];
        }];
        int platform = [params[@"platform"] intValue];
        
        
        PCLoginConfirmViewController *vc2 = [[PCLoginConfirmViewController alloc] init];
        vc2.sessionId = sessionId;
        vc2.platform = platform;
        vc2.modalPresentationStyle = UIModalPresentationFullScreen;
        [navigator presentViewController:vc2 animated:YES completion:nil];
        return YES;
    }else if ([str rangeOfString:@"wildfirechat://group" options:NSCaseInsensitiveSearch].location == 0) {
    }else { // str = @"https://www.jianshu.com/p/662e73cb16ed"
        
    }
    
    return NO;
}
- (MBProgressHUD *)startProgress:(NSString *)text inView:(UIView *)view {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.label.text = text;
    [hud showAnimated:YES];
    return hud;
}

- (MBProgressHUD *)stopProgress:(MBProgressHUD *)hud inView:(UIView *)view finishText:(NSString *)text {
    [hud hideAnimated:YES];
    if(text) {
        hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = text;
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud hideAnimated:YES afterDelay:1.f];
    }
    return hud;
}


#pragma mark - UNUserNotificationCenterDelegate
//将要推送
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler API_AVAILABLE(ios(10.0)){
    NSLog(@"----------willPresentNotification");
    completionHandler(UNNotificationPresentationOptionBadge);
}
//已经完成推送
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler API_AVAILABLE(ios(10.0)){
    NSLog(@"============didReceiveNotificationResponse");
    NSString *categoryID = response.notification.request.content.categoryIdentifier;
    if ([categoryID isEqualToString:@"categoryIdentifier"]) {
        if ([response.actionIdentifier isEqualToString:@"enterApp"]) {
            if (@available(iOS 10.0, *)) {
                
            } else {
                // Fallback on earlier versions
            }
        }else{
            NSLog(@"No======");
        }
    }
    completionHandler();
}


#pragma mark - QrCodeDelegate
- (void)showQrCodeViewController:(UINavigationController *)navigator type:(int)type target:(NSString *)target {
//    CreateBarCodeViewController *vc = [CreateBarCodeViewController new];
//    vc.qrType = type;
//    vc.target = target;
//    [navigator pushViewController:vc animated:YES];
    WOPMKDIOFZTNormalQrcodeVC *vc = WOPMKDIOFZTNormalQrcodeVC.new;
    vc.qrType = type;
    vc.target = target;
    [navigator pushViewController:vc animated:YES];
}

- (void)scanQrCode:(UINavigationController *)navigator {
    EPIKNODWVScanQrVC *vc = [EPIKNODWVScanQrVC new];
    vc.libraryType = SLT_Native;
    vc.scanCodeType = SCT_QRCode;
    
    vc.style = [StyleDIY qqStyle];
    
    //镜头拉远拉近功能
    vc.isVideoZoom = YES;
    
    vc.hidesBottomBarWhenPushed = YES;
    __weak typeof(self)ws = self;
    vc.scanResult = ^(NSString *str) {
        [ws handleUrl:str withNav:navigator];
    };
    
    [navigator pushViewController:vc animated:YES];
}

#ifdef WFC_PTT
- (void)playPttRing:(NSString *)ring {
    NSURL *url = [[NSBundle mainBundle] URLForResource:ring withExtension:@"m4a"];
    NSError *error = nil;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    if (!error) {
        self.audioPlayer.numberOfLoops = 0;
        self.audioPlayer.volume = 1.0;
        [self.audioPlayer prepareToPlay];
        [self.audioPlayer play];
    }
}

#pragma - mark WFPttDelegate
- (void)didConversation:(WFCCConversation *)conversation startTalkingUser:(NSString *)userId {
    [self playPttRing:@"ptt_begin"];
}

- (void)didConversation:(WFCCConversation *)conversation endTalkingUser:(NSString *)userId {
    [self playPttRing:@"ptt_end"];
}
- (void)didConversation:(WFCCConversation *)conversation amplitudeUpdate:(int)amplitude ofUser:(NSString *)userId {
    NSLog(@"on ptt user %@ speak %d", userId, amplitude);
}
#endif
@end
