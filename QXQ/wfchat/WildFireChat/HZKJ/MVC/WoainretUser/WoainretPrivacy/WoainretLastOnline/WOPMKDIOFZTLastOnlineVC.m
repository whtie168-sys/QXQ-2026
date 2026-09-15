//
//  WOPMKDIOFZTLastOnlineVC.m
//  WUHOIBDK
//
//  Created by Ruby on 12/4/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "WOPMKDIOFZTLastOnlineVC.h"

@interface WOPMKDIOFZTLastOnlineVC ()

@property (weak, nonatomic) IBOutlet UIImageView *statusAView;
@property (weak, nonatomic) IBOutlet UIImageView *statusBView;
@property (weak, nonatomic) IBOutlet UIImageView *statusCView;


@property (weak, nonatomic) IBOutlet UILabel *descL;
@property (weak, nonatomic) IBOutlet UILabel *allPersonL;
@property (weak, nonatomic) IBOutlet UILabel *contactL;
@property (weak, nonatomic) IBOutlet UILabel *notShowL;

@end

@implementation WOPMKDIOFZTLastOnlineVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = LLLLLL(@"LastOnlineTime");
    
    if ([CommonHelper.main isChinese]) {
    }else {
        _descL.text = @"Who can see my last online time?";
        _allPersonL.text = @"All";
        _contactL.text = @"Address book only contacts";
        _notShowL.text = @"The online time is not displayed";
    }
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    [[UserService shared] getUserInfo:userId
                              refresh:YES
                              success:^(WFCCUserInfo * _Nonnull userInfo) {
        UserExtraInfo *extraInfo = [UserExtraInfo mj_objectWithKeyValues:userInfo.extra];
        self.showLastLoginTime = extraInfo.disableShowLastLoginTime;
        [self btnState];
    } error:^(int errorCode, NSString * _Nonnull message) {
        
    }];
}

- (IBAction)status:(UIButton *)sender {
    if (_showLastLoginTime == sender.tag) {
        return;
    }
    _showLastLoginTime = sender.tag;
    [self updateState];
}

- (void)updateState {
    WS(weakself)
    [[AppService sharedAppService] userExtra:@{@"disableShowLastLoginTime":@(_showLastLoginTime)}
                                     success:^{
        [weakself btnState];
        NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
        [[UserService shared] getUserInfo:userId success:^(WFCCUserInfo * _Nonnull userInfo) {
        
        } error:^(int errorCode, NSString * _Nonnull message) {
            
        }];
    } error:^(int errCode, NSString * _Nonnull message) {
        
    }];
}

- (void)btnState {
    _statusAView.hidden = !(_showLastLoginTime == 0);
    _statusBView.hidden = !(_showLastLoginTime == 1);
    _statusCView.hidden = !(_showLastLoginTime == 2);
}


@end
