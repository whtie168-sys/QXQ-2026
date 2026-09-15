//
//  WOPMKDIOFZTPrivacyVC.m
//  WUHOIBDK
//
//  Created by Ruby on 11/15/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "WOPMKDIOFZTPrivacyVC.h"

#import "WOPMKDIOFZTLastOnlineVC.h"
#import "WOPMKDIOFZTAddmyWayVC.h"
#import "MyBlackListViewController.h"

@interface WOPMKDIOFZTPrivacyVC ()
{
    BOOL _isUpdate;
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UISwitch *addChatSW;
@property (weak, nonatomic) IBOutlet UISwitch *addGroupSW;
@property (weak, nonatomic) IBOutlet UISwitch *showMobileSW;

@property (weak, nonatomic) IBOutlet UISwitch *enterStatusSW;
@property (weak, nonatomic) IBOutlet UISwitch *receiptSW;

@property (nonatomic, strong) WFCCUserInfo *userInfo;
@property (nonatomic, strong) UserExtraInfo *extraInfo;


@property (weak, nonatomic) IBOutlet UILabel *addWayL;
@property (weak, nonatomic) IBOutlet UILabel *addFriendL;
@property (weak, nonatomic) IBOutlet UILabel *inviteL;
@property (weak, nonatomic) IBOutlet UILabel *showPhoneL;

@property (weak, nonatomic) IBOutlet UILabel *lastOnlineL;
@property (weak, nonatomic) IBOutlet UILabel *showEnterStateL;
@property (weak, nonatomic) IBOutlet UILabel *readedL;
@property (weak, nonatomic) IBOutlet UILabel *readedDescL;

@property (weak, nonatomic) IBOutlet UILabel *blackListL;


@end

@implementation WOPMKDIOFZTPrivacyVC


- (void)didMoveToParentViewController:(UIViewController*)parent {
    [super didMoveToParentViewController:parent];
    if (_isUpdate) {
        NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
        self.userInfo = [[AppCache sharedAppCache] getMyInfo];
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [CommonHelper.main isChinese];
    _isUpdate = NO;
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    self.userInfo = [[AppCache sharedAppCache] getMyInfo];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    
    [self updateADFLanguage];
}
- (void)updateADFLanguage {
    self.navigationItem.title = LLLLLL(@"PrivacySetting");
    _blackListL.text = LLLLLL(@"Blacklist");
    
    if (_isChinese) {
    }else {
        _addWayL.text = @"Add My Way";
        _addFriendL.text = @"Add me need to verify";
        _inviteL.text = @"Join me in the group need to verify";
        _showPhoneL.text = @"Show phone numbers to friends";
        
        _lastOnlineL.text = @"Last online time";
        _showEnterStateL.text = @"Display input status";
        _readedL.text = @"Read recei";
        _readedDescL.text = @"If you choose to turn off read receipts, you will not be able to see the reading status of others, and this option will not affect the read receipts of group conversations.";
    }
}

- (void)setUserInfo:(WFCCUserInfo *)userInfo {
    _userInfo = userInfo;
    _extraInfo = [UserExtraInfo mj_objectWithKeyValues:_userInfo.extra];
//    NSLog(@"userInfo2===%@",_userInfo.mj_JSONObject);
    
    _addChatSW.on = (_extraInfo.disableAutoAddFriend == 1);
    _addGroupSW.on = (_extraInfo.disableJoinToGroup == 1);
    _showMobileSW.on = (_extraInfo.disableShowPhone == 1);
    
    _enterStatusSW.on = (_extraInfo.disableShowInputState == 1);
    _receiptSW.on = [WFCCIMService.sharedWFCIMService isUserEnableReceipt];
}
- (void)onUserInfoUpdated:(NSNotification *)notification {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    NSArray<WFCCUserInfo *> *userInfoList = notification.userInfo[@"userInfoList"];
    for (WFCCUserInfo *userInfo in userInfoList) {
        if ([userId isEqualToString:userInfo.userId]) {
            self.userInfo = userInfo;
            break;
        }
    }
}

- (IBAction)lastOnlineDate:(UIButton *)sender {
    WOPMKDIOFZTLastOnlineVC *vc = WOPMKDIOFZTLastOnlineVC.new;
    vc.showLastLoginTime = _extraInfo.disableShowLastLoginTime;
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)addMyWay:(UIButton *)sender {
    WOPMKDIOFZTAddmyWayVC *vc = WOPMKDIOFZTAddmyWayVC.new;
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)blacklist:(UIButton *)sender {
    MyBlackListViewController *vc = MyBlackListViewController.new;
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)receipt:(UISwitch *)sender {
    _isUpdate = YES;
    if ([sender isEqual:_addChatSW]) {
        [self requestStateSW:sender params:@{@"disableAutoAddFriend":@(sender.on ? 1 : 0)}];
    }else if ([sender isEqual:_addGroupSW]) {
        [self requestStateSW:sender params:@{@"disableJoinToGroup":@(sender.on ? 1 : 0)}];
    }else if ([sender isEqual:_showMobileSW]) {
        [self requestStateSW:sender params:@{@"disableShowPhone":@(sender.on ? 1 : 0)}];
    }else if ([sender isEqual:_enterStatusSW]) {
        [self requestStateSW:sender params:@{@"disableShowInputState":@(sender.on ? 1 : 0)}];
    }else if ([sender isEqual:_receiptSW]) {
        _isUpdate = NO;
        NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
        NSString *key = [NSString stringWithFormat:@"%@_%@",@"Receipt",userId];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%d",sender.on] forKey:key];
//        [WFCCIMService.sharedWFCIMService setUserEnableReceipt:sender.on success:^{
//        } error:^(int error_code) {
//            sender.on = !sender.on;
//        }];
    }
}

- (void)requestStateSW:(UISwitch *)sw params:(NSDictionary *)params {
    [AppService.sharedAppService userExtra:params success:^ {
    } error:^(int errCode, NSString * _Nonnull message) {
//        if (sw) {
//            sw.on = !sw.on;
//        }
    }];
}

@end
