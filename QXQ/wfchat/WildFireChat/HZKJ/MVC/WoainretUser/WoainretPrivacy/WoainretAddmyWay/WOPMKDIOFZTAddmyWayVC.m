//
//  WOPMKDIOFZTAddmyWayVC.m
//  WUHOIBDK
//
//  Created by Ruby on 1/30/24.
//

#import "WOPMKDIOFZTAddmyWayVC.h"

@interface WOPMKDIOFZTAddmyWayVC ()

@property (weak, nonatomic) IBOutlet UISwitch *mobileSW;

@property (weak, nonatomic) IBOutlet UISwitch *idSW;

@property (nonatomic, strong) WFCCUserInfo *userInfo;


@property (weak, nonatomic) IBOutlet UILabel *descL;
@property (weak, nonatomic) IBOutlet UILabel *phoneL;

@end

@implementation WOPMKDIOFZTAddmyWayVC

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([CommonHelper.main isChinese]) {
        self.navigationItem.title = @"添加我的方式";
    }else {
        self.navigationItem.title = @"Add my way";
        _descL.text = @"    You can find me in the following ways";
    }
    _phoneL.text = LLLLLL(@"MobileNumbers");
    
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    self.userInfo = [[AppCache sharedAppCache] getMyInfo];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
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
- (void)setUserInfo:(WFCCUserInfo *)userInfo {
    _userInfo = userInfo;
    UserExtraInfo *extraInfo = [UserExtraInfo mj_objectWithKeyValues:_userInfo.extra];
    
    _mobileSW.on = (extraInfo.openMobileSearch == 1);
    
    _idSW.on = (extraInfo.openAccountSearch == 1);
}

- (IBAction)actionSW:(UISwitch *)sender {
    if ([sender isEqual:_mobileSW]) {
        [self requestStateSW:sender params:@{@"openMobileSearch":@(sender.on ? 1 : 0)}];
    }else if ([sender isEqual:_idSW]) {
        [self requestStateSW:sender params:@{@"openAccountSearch":@(sender.on ? 1 : 0)}];
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
