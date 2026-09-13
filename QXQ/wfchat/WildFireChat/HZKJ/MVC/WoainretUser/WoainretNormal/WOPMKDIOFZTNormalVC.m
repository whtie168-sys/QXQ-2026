//
//  WOPMKDIOFZTNormalVC.m
//  WUHOIBDK
//
//  Created by Ruby on 11/7/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "WOPMKDIOFZTNormalVC.h"
#import "OrgService.h"
#import "WOPMKDIOFZTDestroyVC.h"

#import "WOPMKDIOFZTFeedbackVC.h"
#import "WOPMKDIOFZTAboutVC.h"
#import "WOPMKDIOFZTWebviewVC.h"
#import "WOPMKDIOFZTLangugeVC.h"
#import "WOPMKDIOFZTFontsizeVC.h"

@interface WOPMKDIOFZTNormalVC ()

@property (weak, nonatomic) IBOutlet UILabel *languageLabel;
@property (weak, nonatomic) IBOutlet UILabel *httpLabel;

@property (weak, nonatomic) IBOutlet UILabel *fontSizeL;
@property (weak, nonatomic) IBOutlet UILabel *languageL;
@property (weak, nonatomic) IBOutlet UILabel *httpsL;
@property (weak, nonatomic) IBOutlet UILabel *userHelpL;
@property (weak, nonatomic) IBOutlet UILabel *feedbackL;
@property (weak, nonatomic) IBOutlet UILabel *aboutL;
@property (weak, nonatomic) IBOutlet UILabel *clearL;
@property (weak, nonatomic) IBOutlet UILabel *logoutL;
@end

@implementation WOPMKDIOFZTNormalVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateADFLanguage];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateADFLanguage) name:kLanguageNoti object:nil];
}
- (void)updateADFLanguage {
    self.navigationItem.title = LLLLLL(@"Universal");
    _languageLabel.text = (LANGUAGE == 0 ? LLLLLL(@"FollowingSystemLanguage") : (LANGUAGE == 1 ? @"简体中文" : @"English"));
    
    NSString *websiteUrl = [NSUserDefaults.standardUserDefaults objectForKey:([CommonHelper.main isChinese] ? kWebsiteUrlChinese : kWebsiteUrlEnglish)];
    if (websiteUrl.length > 0) {
        _httpLabel.text = websiteUrl;
    }else {
        _httpLabel.text = LLLLLL(@"OFFICIAL_WEBSITE");
    }
    
    _fontSizeL.text = LLLLLL(@"FontSize");
    _languageL.text = LLLLLL(@"Language");
    _httpsL.text = LLLLLL(@"OfficialWebsite");
    _userHelpL.text = LLLLLL(@"UseHelp");
    _feedbackL.text = LLLLLL(@"Feedback");
    _aboutL.text = LLLLLL(@"About");
    _clearL.text = LLLLLL(@"ClearCache");
    _logoutL.text = LLLLLL(@"Logout");
}

- (IBAction)fontSize:(UIButton *)sender {
    WOPMKDIOFZTFontsizeVC *vc = WOPMKDIOFZTFontsizeVC.new;
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)language:(UIButton *)sender {
    WOPMKDIOFZTLangugeVC *vc = WOPMKDIOFZTLangugeVC.new;
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)http:(UIButton *)sender {
    WOPMKDIOFZTWebviewVC *vc = WOPMKDIOFZTWebviewVC.new;
    vc.type = 0;
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)userHelper:(UIButton *)sender {
    WOPMKDIOFZTWebviewVC *vc = WOPMKDIOFZTWebviewVC.new;
    vc.type = 1;
    [self.navigationController pushViewController:vc animated:YES];
}


- (IBAction)feedback:(UIButton *)sender {
    WOPMKDIOFZTFeedbackVC *vc = WOPMKDIOFZTFeedbackVC.new;
    [self.navigationController pushViewController:vc animated:YES];
}


- (IBAction)about:(UIButton *)sender {
    WOPMKDIOFZTAboutVC *vc = WOPMKDIOFZTAboutVC.new;
    [self.navigationController pushViewController:vc animated:YES];
}


- (IBAction)dataClear:(UIButton *)sender {
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:LLLLLL(@"ClearCache") message:([CommonHelper.main isChinese] ? @"该操作会将缓存数据全部清除，且无法恢复，是否继续？" : @"This operation will clear all cached data and cannot be restored. Do you want to continue?") preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    WS(weakself)
    UIAlertAction *actionClear = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:weakself.view animated:YES];
        hud.label.text = LLLLLL(@"OperationInProgress");
        [hud showAnimated:YES];
        WS(weakself)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [WFCCIMService.sharedWFCIMService clearAllMessages:YES];
            [hud hideAnimated:YES];
            [weakself.view makeToast:LLLLLL(@"SuccessfulOperation") duration:1.0 position:CSToastPositionCenter];
        });
    }];
    [actionSheet addAction:actionCancel];
    [actionSheet addAction:actionClear];
    [self presentViewController:actionSheet animated:YES completion:nil];
}


// 退出登录
- (IBAction)logout:(UIButton *)sender {
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:LLLLLL(@"Quit") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *actionLogout = [UIAlertAction actionWithTitle:LLLLLL(@"Logout") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedName"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedToken"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedUserId"];
        [[AppService sharedAppService] clearAppServiceAuthInfos];
        [[OrgService sharedOrgService] clearOrgServiceAuthInfos];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [CommonHelper.main loyout];
        //退出后就不需要推送了，第一个参数为YES
        //如果希望再次登录时能够保留历史记录，第二个参数为NO。如果需要清除掉本地历史记录第二个参数用YES
        [[WFCCNetworkService sharedInstance] disconnect:YES clearSession:NO];
        [[SRIMNetworkService sharedInstance] disconnect:YES clearSession:NO];
    }];
    
    UIAlertAction *actionDestroy = [UIAlertAction actionWithTitle:LLLLLL(@"DestroyAccount") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        WOPMKDIOFZTDestroyVC *destroyVC = [[WOPMKDIOFZTDestroyVC alloc] init];
        [self.navigationController pushViewController:destroyVC animated:YES];
    }];
    
    //把action添加到actionSheet里
    [actionSheet addAction:actionLogout];
    [actionSheet addAction:actionDestroy];
    [actionSheet addAction:actionCancel];
    
    //相当于之前的[actionSheet show];
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

@end
