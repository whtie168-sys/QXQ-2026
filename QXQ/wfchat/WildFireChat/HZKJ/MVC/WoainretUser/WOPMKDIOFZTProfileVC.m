//
//  WOPMKDIOFZTProfileVC.m
//  WUHOIBDK
//
//  Created by Loooooo on 7/22/24.
//

#import "WOPMKDIOFZTProfileVC.h"
#import <MessageUI/MessageUI.h>
#import "WOPMKDIOFZTNormalVC.h"
#import "WOPMKDIOFZTSafetyVC.h"
#import "WOPMKDIOFZTUserinfoVC.h"
#import "WOPMKDIOFZTPrivacyVC.h"
#import "WOPMKDIOFZTNoticeVC.h"
#import "WOPMKDIOFZTFontsizeVC.h"
#import "WOPMKDIOFZTLangugeVC.h"
#import "WOPMKDIOFZTAboutVC.h"
#import "WOPMKDIOFZTNormalQrcodeVC.h"
#import "WOPMKDIOFZTTextModifyVC.h"
#import "WOPMKDIOFZTUserQrcodeVC.h"
#import "WOPMKDIOFZTAvatarVC.h"
#import "WOPMKDIOFZTAppearanceVC.h"
#import "WOPMKDIOFZTUserWalletVC.h"
#import "WOPMKDIOFZTCheckInVC.h"


@interface WOPMKDIOFZTProfileVC ()
{
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIImageView *waxiouvIconV;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvNameL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvIdL;
@property (weak, nonatomic) IBOutlet UIView *qrView;

@property (weak, nonatomic) IBOutlet UILabel *waxiouvSignL;

@property (weak, nonatomic) IBOutlet UIView *waxiouvMbV;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvNotiL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvChatL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvPrivacyL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvSecurityL;
@property (weak, nonatomic) IBOutlet UIView *waxiouvLanguageV;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *waxiouvLanguageHeigt;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvLanguageL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvSkinL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvFontL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvAboutL;

@property (strong, nonatomic) WFCCUserInfo *userInfo;
@property IBOutlet UILabel *mywalletL;
@property IBOutlet UILabel *mycheckInL;

@end

@implementation WOPMKDIOFZTProfileVC

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.subviews[0].alpha = 0.0;
    [self userdataUpdated];
    if ([NSUserDefaults.standardUserDefaults integerForKey:@"kIsReview"] == 1) {
        _waxiouvLanguageV.hidden = YES;
        _waxiouvLanguageHeigt.constant = 0.0;
    }else {
        _waxiouvLanguageV.hidden = NO;
        _waxiouvLanguageHeigt.constant = 60.0;
    }
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.subviews[0].alpha = 1.0;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [CommonHelper.main isChinese];
    _waxiouvIconV.layer.cornerRadius = 35.0;
    _qrView.layer.cornerRadius = 4.0;
    _waxiouvMbV.layer.cornerRadius = 30.0;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userdataUpdated) name:@"kUserDataUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userdataUpdated) name:kUserInfoUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userdataUpdated) name:kFriendListUpdated object:nil];

    [self updateADFLanguage];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateADFLanguage) name:kLanguageNoti object:nil];
}


- (void)updateADFLanguage {
    _waxiouvNotiL.text = LLLLLL(@"NotificationSetting");
    _waxiouvChatL.text = LLLLLL(@"ChatSetting");
    _waxiouvPrivacyL.text = LLLLLL(@"PrivacySetting");
    _waxiouvSecurityL.text = LLLLLL(@"SecuritySetting");
    _waxiouvLanguageL.text = LLLLLL(@"Language");
    _waxiouvSkinL.text = LLLLLL(@"Appearance");
    _waxiouvFontL.text = LLLLLL(@"FontSize");
    _waxiouvAboutL.text = LLLLLL(@"About");
    _mywalletL.text = LLLLLL(@"MyWallet");
    _mycheckInL.text = LLLLLL(@"MyCheckIn");

//    for (NSInteger i = 0; i < self.tabBarController.viewControllers.count; i ++) {
//        NSString *title = @[LLLLLL(@"Message"), LLLLLL(@"Contacts"), LLLLLL(@"Community"), LLLLLL(@"Call"), LLLLLL(@"Mine"), @"", @"", @""][i];
//        UINavigationController *navc = self.tabBarController.viewControllers[i];
//        navc.title = title;
//    }
    for (NSInteger i = 0; i < self.tabBarController.viewControllers.count; i ++) {
        NSString *title = @[LLLLLL(@"Message"), LLLLLL(@"Contacts"), LLLLLL(@"Community"), @"AI", LLLLLL(@"Mine"), @"", @"", @""][i];
        UINavigationController *navc = self.tabBarController.viewControllers[i];
        navc.title = title;
    }
}

- (void)userdataUpdated {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    [[AppService sharedAppService] getUserInfo:userId
                                       success:^(WFCCUserInfo * _Nonnull userInfo) {
        self.userInfo = userInfo;
        [[WFCCUserDB sharedManager] insertOrUpdateUserInfo:userInfo];
        [[AppCache sharedAppCache] saveMyInfo:userInfo];
    } error:^(int errCode, NSString * _Nonnull message) {
        
    }];
}

- (void)setUserInfo:(WFCCUserInfo *)userInfo {
    _userInfo = userInfo;
    [_waxiouvIconV sd_setImageWithURL:URL(userInfo.portrait) placeholderImage:[AIOIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                              context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}
];
    _waxiouvNameL.text = userInfo.displayName;
    _waxiouvIdL.text = userInfo.name;
    
    NSString *waxiouvSign = [UserExtraInfo mj_objectWithKeyValues:_userInfo.extra].sign;
    _waxiouvSignL.text = (waxiouvSign.length > 0 ? waxiouvSign : (_isChinese ? @"这个用户很懒，暂无签名~" : @"This user is lazy and has no signature"));
}

- (IBAction)waxiouvUserinfo:(UIButton *)sender {
    WOPMKDIOFZTUserinfoVC *vc = WOPMKDIOFZTUserinfoVC.new;
//    WOPMKDIOFZTAvatarVC *vc = WOPMKDIOFZTAvatarVC.new;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)waxiouvCopyId:(UIButton *)sender {
    if (_waxiouvIdL.text.length <= 0) {
        return;
    }
    UIPasteboard *pasteboard = UIPasteboard.generalPasteboard;
    pasteboard.string = _waxiouvIdL.text;
    
    [SVProgressHUD showSuccessWithStatus:LLLLLL(@"CopySuccessfully")];
    [SVProgressHUD dismissWithDelay:1.0];
}

- (IBAction)waxiouvQr:(UIButton *)sender {
    WOPMKDIOFZTUserQrcodeVC *vc = WOPMKDIOFZTUserQrcodeVC.new;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)waxiouvSign:(UIButton *)sender {
    WOPMKDIOFZTTextModifyVC *vc = WOPMKDIOFZTTextModifyVC.new;
    vc.hidesBottomBarWhenPushed = YES;
    vc.modifyType = Modify_Sign;
    vc.defaultValue = _waxiouvSignL.text;
    WS(weakself)
    [vc setOnModified:^(NSString * _Nonnull value) {
        weakself.waxiouvSignL.text = value;
    }];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)waxiouvItemAct:(UIButton *)sender {
    if (sender.tag == 0) { // 通知设置
        WOPMKDIOFZTNoticeVC *vc = WOPMKDIOFZTNoticeVC.new;
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }else if (sender.tag == 1) { // 聊天设置
        
    }else if (sender.tag == 2) { // 隐私设置
        WOPMKDIOFZTPrivacyVC *vc = WOPMKDIOFZTPrivacyVC.new;
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }else if (sender.tag == 3) { // 安全设置
        WOPMKDIOFZTSafetyVC *vc = WOPMKDIOFZTSafetyVC.new;
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }else if (sender.tag == 4) { // 语言
        WOPMKDIOFZTLangugeVC *vc = WOPMKDIOFZTLangugeVC.new;
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }else if (sender.tag == 5) { // 外观
        WOPMKDIOFZTAppearanceVC *vc = WOPMKDIOFZTAppearanceVC.new;
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }else if (sender.tag == 6) { // 字体
        WOPMKDIOFZTFontsizeVC *vc = WOPMKDIOFZTFontsizeVC.new;
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }else if (sender.tag == 7) { // 关于
        WOPMKDIOFZTAboutVC *vc = WOPMKDIOFZTAboutVC.new;
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }
    
//    WOPMKDIOFZTNormalVC *vc = WOPMKDIOFZTNormalVC.new; / 通用
//    vc.hidesBottomBarWhenPushed = YES;
//    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)walletA:(UIButton *)sender {
    WOPMKDIOFZTUserWalletVC *vc = WOPMKDIOFZTUserWalletVC.new;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)checkInA:(UIButton *)sender {
    WOPMKDIOFZTCheckInVC *vc = WOPMKDIOFZTCheckInVC.new;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
