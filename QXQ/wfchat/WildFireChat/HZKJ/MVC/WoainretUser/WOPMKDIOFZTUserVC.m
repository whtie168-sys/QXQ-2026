//
//  WOPMKDIOFZTUserVC.m
//  WUHOIBDK
//
//  Created by Ruby on 11/7/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "WOPMKDIOFZTUserVC.h"
#import <AVKit/AVKit.h>
#import <MessageUI/MessageUI.h>
#import "WOPMKDIOFZTNormalVC.h"
#import "WOPMKDIOFZTSafetyVC.h"
#import "WOPMKDIOFZTUserinfoVC.h"
#import "WOPMKDIOFZTPrivacyVC.h"
#import "WOPMKDIOFZTNoticeVC.h"
#import "WOPMKDIOFZTUserWalletVC.h"

@interface WOPMKDIOFZTUserVC ()<MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *tzboeuNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *idLabel;

@property (weak, nonatomic) IBOutlet UIView *qrView;

@property (weak, nonatomic) IBOutlet UIView *mbView;

@property (strong, nonatomic) WFCCUserInfo *userInfo;


@property (weak, nonatomic) IBOutlet UILabel *notificationL;
@property (weak, nonatomic) IBOutlet UILabel *chatL;
@property (weak, nonatomic) IBOutlet UILabel *privacyL;
@property (weak, nonatomic) IBOutlet UILabel *securityL;
@property (weak, nonatomic) IBOutlet UILabel *universalL;

@property IBOutlet UILabel *mywalletL;

@end

@implementation WOPMKDIOFZTUserVC

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.subviews[0].alpha = 0.0;
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.subviews[0].alpha = 1.0;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    _iconView.layer.cornerRadius = 30.0;
    _qrView.layer.cornerRadius = 4.0;
    _mbView.layer.cornerRadius = 30.0;
    
    [self userdataUpdated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userdataUpdated) name:@"kUserDataUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userdataUpdated) name:kUserInfoUpdated object:nil];
    
    [self updateADFLanguage];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateADFLanguage) name:kLanguageNoti object:nil];
}
- (void)updateADFLanguage {
    _notificationL.text = LLLLLL(@"NotificationSetting");
    _chatL.text = LLLLLL(@"ChatSetting");
    _privacyL.text = LLLLLL(@"PrivacySetting");
    _securityL.text = LLLLLL(@"SecuritySetting");
    _universalL.text = LLLLLL(@"Universal");
    _mywalletL.text = LLLLLL(@"MyWallet");
    
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
//    NSLog(@"toJsonObj===%@",self.userInfo.toJsonObj);
}
- (void)setUserInfo:(WFCCUserInfo *)userInfo {
    _userInfo = userInfo;
//    NSLog(@"toJsonObj===%@",_userInfo.toJsonObj);
    [_iconView sd_setImageWithURL:URL(userInfo.portrait) placeholderImage:[AIOIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                          context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    _tzboeuNameLabel.text = userInfo.displayName;
    _idLabel.text = userInfo.name;
}

- (IBAction)copyId:(UIButton *)sender {
    if (_idLabel.text.length <= 0) {
        return;
    }
    UIPasteboard *pasteboard = UIPasteboard.generalPasteboard;
    pasteboard.string = _idLabel.text;
    
    [SVProgressHUD showSuccessWithStatus:LLLLLL(@"CopySuccessfully")];
    [SVProgressHUD dismissWithDelay:1.0];
}

- (IBAction)userinfo:(UIButton *)sender {
    WOPMKDIOFZTUserinfoVC *vc = WOPMKDIOFZTUserinfoVC.new;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}


- (IBAction)tongZhi_setup:(UIButton *)sender {
    WOPMKDIOFZTNoticeVC *vc = WOPMKDIOFZTNoticeVC.new;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}
- (IBAction)chatSetup:(UIButton *)sender {
    
}
- (IBAction)privacy_setup:(UIButton *)sender {
    WOPMKDIOFZTPrivacyVC *vc = WOPMKDIOFZTPrivacyVC.new;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)secure_setup:(UIButton *)sender {
    WOPMKDIOFZTSafetyVC *vc = WOPMKDIOFZTSafetyVC.new;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)normal_setup:(UIButton *)sender {
    WOPMKDIOFZTNormalVC *vc = WOPMKDIOFZTNormalVC.new;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)walletA:(UIButton *)sender {
    [self.navigationController pushViewController:[WOPMKDIOFZTUserWalletVC new] animated:YES];
}
@end
