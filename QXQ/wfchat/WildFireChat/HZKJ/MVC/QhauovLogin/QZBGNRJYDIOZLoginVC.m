//
//  QZBGNRJYDIOZLoginVC.m
//  WUHOIBDK
//
//  Created by Ruby on 12/22/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "QZBGNRJYDIOZLoginVC.h"
#import "KeyChainTool.h"


#import "QABWJEFDOCYTabBarVC.h"
#import "QZBGNRJYDIOZRetrievePswdVC.h"
#import "WOPMKDIOFZTNumberVC.h"
#import "QZBGNRJYDIOZRegisterVC.h"
#import "QZBGNRJYDIOZAreacodeVC.h"
#import "EPIKNODWVCustomerServiceVC.h"
#import "YUBWOIJWDMessageVC.h"
#import <WFChatClient/SRIMNetworkService.h>
#import <WFChatClient/WKDB.h>
#import <WFChatClient/WFCCMessageDB.h>
#import <WFChatClient/WFCCConversationDB.h>



@interface QZBGNRJYDIOZLoginVC ()<UITextFieldDelegate, UIScrollViewDelegate, XWCountryCodeControllerDelegate>
{
    NSInteger _eogcsaioxType; // 手机 or 邮箱
    
    NSString *_qoynruArea_name; // 手机区号
    CGFloat _area_view_width; // 手机区号的宽度
    
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UIButton *qoynruLoginTypeAButton;
@property (weak, nonatomic) IBOutlet UIButton *qoynruLoginTypeBButton;
@property (weak, nonatomic) IBOutlet UIImageView *qoynruLoginTypeBgView;


@property (weak, nonatomic) IBOutlet UITextField *qoynruAccountTF;
@property (weak, nonatomic) IBOutlet UITextField *qoynruPasswordTF;
@property (weak, nonatomic) IBOutlet UIButton *qoynruSendcodeButton;

@property (weak, nonatomic) IBOutlet UIView *qoynruAreaView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *qoynruAreaViewWidth;
@property (weak, nonatomic) IBOutlet UILabel *qoynruAreaLabel;

@property (weak, nonatomic) IBOutlet UIImageView *qoynruAccountImgView;
@property (weak, nonatomic) IBOutlet UILabel *qoynruAccountLabel;
@property (weak, nonatomic) IBOutlet UIImageView *qoynruAasswordImgView;
@property (weak, nonatomic) IBOutlet UILabel *qoynruPasswordLabel;

@property (weak, nonatomic) IBOutlet UIButton *qoynruForgetPswButton;

@property (weak, nonatomic) IBOutlet UIButton *qoynruLoginButton;

// 登录方式  密码登录 or 验证码登录
@property (weak, nonatomic) IBOutlet UIButton *qoynruWayButton;


// 需要转语言的view
@property (weak, nonatomic) IBOutlet UILabel *qoynruNoAmountL;
@property (weak, nonatomic) IBOutlet UILabel *qoynruGoRegisterL;
@property (weak, nonatomic) IBOutlet UIButton *qoynruCustomerBtn;

@property (weak, nonatomic) IBOutlet UIButton *qoynruEyeBtn;


@end

@implementation QZBGNRJYDIOZLoginVC

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    self.navigationController.navigationBar.subviews[0].alpha = 0.0;
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
    self.navigationController.navigationBar.subviews[0].alpha = 1.0;
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if(self.isKickedOff) {
        self.isKickedOff = NO;
        [CommonHelper.main loyout];
        UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:(_isChinese ? @"您的账号已在其他手机登录" : @"Your account has been logged in on another phone.") preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:LLLLLL(@"iGotIt") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];
        [actionSheet addAction:actionCancel];
        [self presentViewController:actionSheet animated:YES completion:nil];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [CommonHelper.main isChinese];
    _eogcsaioxType = 1;
    _qoynruLoginTypeBgView.image = IMAGENAME((UNString(@"LoginType%ld", _eogcsaioxType)));
    
    _qoynruArea_name = @"+86";
    _area_view_width = 55.0;
    _qoynruAreaViewWidth.constant = _area_view_width;
    _qoynruSendcodeButton.hidden = YES;
    
    _scrollView.delegate = self;
    [_scrollView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close)]];
    
    _qoynruAccountTF.delegate = self;
    _qoynruPasswordTF.delegate = self;
    _qoynruPasswordTF.returnKeyType = UIReturnKeyDone;
    [_qoynruAccountTF addTarget:self action:@selector(eogcsaioxTextField:) forControlEvents:UIControlEventEditingChanged];
    [_qoynruPasswordTF addTarget:self action:@selector(eogcsaioxTextField:) forControlEvents:UIControlEventEditingChanged];
    
    [self preferredStatusBarStyle];
    
    _qoynruLoginButton.userInteractionEnabled = NO;
//    _qoynruLoginButton.selected = YES;
//    _qoynruLoginButton.userInteractionEnabled = YES;
    
    _qoynruLoginTypeAButton.titleLabel.font = PINGFANG_M(20);
    _qoynruWayButton.selected = YES; // 默认情况下：手机号+验证码
    [self qoynruType];
    
    [self updateADFLanguage];
}
- (void)updateADFLanguage {
    [_qoynruLoginTypeAButton setTitle:LLLLLL(@"Tel") forState:UIControlStateNormal];
    [_qoynruLoginTypeBButton setTitle:LLLLLL(@"E-mail") forState:UIControlStateNormal];
    
    [_qoynruForgetPswButton setTitle:[NSString stringWithFormat:@"%@?",LLLLLL(@"ForgotPassword")] forState:UIControlStateNormal];
    
    [_qoynruLoginButton setTitle:LLLLLL(@"SignIn") forState:UIControlStateNormal];
    
    [_qoynruWayButton setTitle:LLLLLL(@"PasswordLogin") forState:UIControlStateNormal];
    [_qoynruWayButton setTitle:LLLLLL(@"CodeLogin") forState:UIControlStateSelected];
    
    _qoynruNoAmountL.text = (_isChinese ? @"还没账户？" : @"No account? ");
    _qoynruGoRegisterL.text = (_isChinese ? @"去注册" : @"Sign up");
    
    [_qoynruCustomerBtn setTitle:LLLLLL(@"CustomerService") forState:UIControlStateNormal];
}

- (IBAction)eogcsaioxLogin:(UIButton *)sender {
    [self.view endEditing:YES];
//    _qoynruAccountTF.text = @"18508248863"; // +1 8147311174
//    _qoynruPasswordTF.text = @"123456";

    if ([self isValid]) {
        return;
    }
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = _isChinese ? @"登录中..." : @"Logging in...";
    [hud showAnimated:YES];
    
    ConnectionStatus status = [WFCCNetworkService.sharedInstance currentConnectionStatus];
    if (status >= 0) { // 说明进了客服的界面、证明该im已被连接、需要断开连接才能再次进行连接 3秒
        [WFCCNetworkService.sharedInstance disconnect:YES clearSession:NO];
        [[SRIMNetworkService sharedInstance] disconnect:YES clearSession:NO];
        WS(weakself) // 链接客服后、立马进行账号登录、未到3秒、也不会奔溃  奇怪、、、
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakself login:hud];
        });
    }else {
        [self login:hud];
    }
}
- (void)login:(MBProgressHUD *)hud {
    WS(weakself)
    void(^errorBlock)(int errCode, NSString *message) = ^(int errCode, NSString *message) {
      dispatch_async(dispatch_get_main_queue(), ^{
          [hud hideAnimated:YES];
        
          NSString *text = @"";
          if (self->_isChinese) {
              text = message;
          }else {
              if ([message containsString:@"验证码错误"]) {
                  text = @"Verification code error";
              }else if ([message containsString:@"错误"]) {
                  text = @"Error...";
              }else if ([message containsString:@"封禁"]) {
                  text = @"The user is blocked...";
              }
              else {
                  text = @"Error...";
              }
          }
          [weakself.view makeToast:text duration:1.2 position:CSToastPositionCenter];
      });
    };
    void(^successBlock)(NSString *userId, NSString *token,NSString *websocketToken, BOOL newUser, NSString *resetCode) = ^(NSString *userId, NSString *token,NSString *websocketToken, BOOL newUser, NSString *resetCode) {
        [hud hideAnimated:YES];
//        [[NSUserDefaults standardUserDefaults] setObject:weakself.qoynruAccountTF.text forKey:@"savedName"];
        [[NSUserDefaults standardUserDefaults] setObject:token forKey:@"savedToken"];
        [[NSUserDefaults standardUserDefaults] setObject:userId forKey:@"savedUserId"];
        [[NSUserDefaults standardUserDefaults] setObject:websocketToken forKey:@"savedwebsocketToken"];
        [[NSUserDefaults standardUserDefaults] setInteger:self->_eogcsaioxType forKey:kLOGIN_TYPE]; // 登录方式 0 手机号码    1 邮箱
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[SRIMNetworkService sharedInstance] connect:userId token:websocketToken];
        
        [[AppService sharedAppService] userBindIos:@{@"deviceToken": [WFCCNetworkService sharedInstance].pushToken,@"topic":[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]}
                                           success:^{
            
        } error:^(int errCode, NSString * _Nonnull message) {
            
        }];

        
        [[AppService sharedAppService] getUserInfo:userId success:^(WFCCUserInfo * _Nonnull userInfo) {
            [[AppCache sharedAppCache] saveMyInfo:userInfo];
            // 切换数据库
            if([[WKDB sharedDB] needSwitchDB:userInfo.userId]) {
                [[WKDB sharedDB] switchDB:userInfo.userId];
                [[WFCCMessageDB sharedManager] setupDB];
                [[WFCCConversationDB sharedManager] setupDB];
                [[WFCCGroupDB sharedManager] setupDB];
                [[WFCCUserDB sharedManager] setupDB];
            }
            [WFCCNetworkService sharedInstance].userId = userId;
            [[WFCCUserDB sharedManager] insertOrUpdateUserInfo:userInfo];
            [[GroupService shared] loadAllGroups];
            [[UserService shared] loadAllFriend];
            
            
            LockStatus *lock = PIUODJNLockStatusManager.main.lockStatus;
            if (lock.status == 1) {
                [PIUODJNLockStatusManager.main reWriteLockInfo:@(0) ForKey:@"backgroundTime"];
                WOPMKDIOFZTNumberVC *vc = WOPMKDIOFZTNumberVC.new;
                vc.type = 5; // 5 跟 4一样的。只是有一点区别
                WS(weakself)
                [vc setPswBlock:^(NSString * _Nonnull psw) {
                    if ([psw isEqualToString:@"OK"]) {
                        [weakself enterMainVc];
                    }else if ([psw isEqualToString:@"ACCOUNT"]) { // 切换账号  这儿不会回调
                        
                    }else if ([psw isEqualToString:@"FORGET"]) { // 成功清除聊天数据  不会走这儿
                        
                    }
                }];
                [self.navigationController pushViewController:vc animated:NO];
            }else {
                [weakself enterMainVc];
            }
            [PIUODJNLockStatusManager.main getLockStatusData:^(BOOL isSuccess) {
            }]; // 获取安全锁相关配置
            
        } error:^(int errCode, NSString * _Nonnull message) {
        
        }];
                
    };
    
    if (_eogcsaioxType == 0) { // 手机 -> 密码登录 and 通过手机号码获取验证码登录
        if (_qoynruWayButton.selected) { // 密码登录
            [[AppService sharedAppService] loginWithMobile:_qoynruAccountTF.text password:_qoynruPasswordTF.text area:_qoynruArea_name success:^(NSString *userId, NSString *token, NSString *websocketToken, BOOL newUser) {
                successBlock(userId, token, websocketToken, newUser, nil);
            } error:errorBlock];
        } else { // 手机->验证码登录
            [[AppService sharedAppService] loginWithMobile:_qoynruAccountTF.text verifyCode:_qoynruPasswordTF.text area:_qoynruArea_name success:successBlock error:errorBlock];
        }
    }else {
        if (_qoynruWayButton.selected) { // 邮箱->密码登录
        } else { // 邮箱->验证码登录
        }
        [AppService.sharedAppService loginWithEmail:_qoynruAccountTF.text pswCode:_qoynruPasswordTF.text type:(_qoynruWayButton.selected ? 0 : 1) success:successBlock error:errorBlock];
    }
}

- (void)enterMainVc {
    NSString *userId = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedUserId"];
    NSString *savedwebsocketToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedwebsocketToken"];
    //需要注意token跟clientId是强依赖的，一定要调用getClientId获取到clientId，然后用这个clientId获取token，这样connect才能成功，如果随便使用一个clientId获取到的token将无法链接成功。
//    [[WFCCNetworkService sharedInstance] connect:userId token:token];
    [[SRIMNetworkService sharedInstance] connect:userId token:savedwebsocketToken];
    
    NSInteger isClear = [NSUserDefaults.standardUserDefaults integerForKey:UNString(@"isEnableClear%@", userId)];
    if (isClear == 100) {
        [WFCCIMService.sharedWFCIMService clearAllMessages:YES];
        // 清除聊天会话后、将该值设置为0
        [NSUserDefaults.standardUserDefaults setInteger:0 forKey:UNString(@"isEnableClear%@", userId)];
        [NSUserDefaults.standardUserDefaults synchronize];
    }
    
    QABWJEFDOCYTabBarVC *tabBarVC = [QABWJEFDOCYTabBarVC new];
    [UIApplication sharedApplication].delegate.window.rootViewController =  tabBarVC;
    // hasPassword = 0 未设置登录密码   1 已设置登录密码
    NSInteger hasPassword = [[NSUserDefaults standardUserDefaults] integerForKey:@"kHasPassword"];
    if (hasPassword == 0) { //
        if ([tabBarVC.childViewControllers.firstObject isKindOfClass:[UINavigationController class]]) {
        }
    }
}



// 发送验证码
- (IBAction)eogcsaioxSendCode:(UIButton *)sender {
    [self.view endEditing:YES];
    _qoynruPasswordTF.text = @"";
    if (_eogcsaioxType == 0) { // 手机
        [CommonHelper.main sendArea:_qoynruArea_name phone:_qoynruAccountTF.text button:sender];
    }else {
        [CommonHelper.main sendEmailCode:_qoynruAccountTF.text button:sender];
    }
}

- (IBAction)pswOrCodeLogin:(UIButton *)sender {
    [self.view endEditing:YES];
    sender.selected = !sender.selected;
    _qoynruPasswordTF.text = @"";
    [self qoynruType];
}
- (IBAction)loginType:(UIButton *)sender {
    [self.view endEditing:YES];
    if (_eogcsaioxType == sender.tag) {
        return;
    }
    _eogcsaioxType = sender.tag;
    _qoynruAccountTF.text = @"";
    _qoynruPasswordTF.text = @"";
    
    self.qoynruLoginTypeAButton.selected = (sender.tag == 0);
    self.qoynruLoginTypeBButton.selected = (sender.tag == 1);
    _qoynruLoginTypeBgView.image = IMAGENAME((UNString(@"LoginType%ld", _eogcsaioxType)));
    [self qoynruType];
}
- (void)qoynruType {
    if (!_qoynruWayButton.selected) { // _qoynruWayButton.selected 是反的     YES 代表当前是密码登录  而非验证码登录
        _qoynruPasswordTF.secureTextEntry = NO;
        _qoynruPasswordTF.placeholder = LLLLLL(@"VerificationCode");
        _qoynruPasswordTF.keyboardType = UIKeyboardTypeNumberPad;
        _qoynruSendcodeButton.hidden = NO;
        _qoynruAasswordImgView.image = IMAGENAME(@"eogcsaioxCode2");
        _qoynruPasswordLabel.text = LLLLLL(@"Code");
        _qoynruForgetPswButton.hidden = YES;
        
        [_qoynruSendcodeButton setTitle:LLLLLL(@"ObtainCode") forState:UIControlStateNormal];
        [_qoynruSendcodeButton setTitleColor:MAINCOLOR forState:UIControlStateNormal];
        _qoynruEyeBtn.hidden = YES;
    }else { // 密码登录
        _qoynruPasswordTF.secureTextEntry = !_qoynruEyeBtn.selected;
        _qoynruPasswordTF.placeholder = LLLLLL(@"Password");
        _qoynruPasswordTF.keyboardType = UIKeyboardTypeDefault;
        _qoynruSendcodeButton.hidden = YES;
        _qoynruAasswordImgView.image = IMAGENAME(@"eogcsaioxPsw");
        _qoynruPasswordLabel.text = LLLLLL(@"Password");
        _qoynruForgetPswButton.hidden = NO;
        _qoynruEyeBtn.hidden = NO;
    }
    
    if (_eogcsaioxType == 0) { // 手机
        _qoynruAccountLabel.text = LLLLLL(@"MobileNumber");
        _qoynruAreaView.hidden = NO;
        _qoynruAreaViewWidth.constant = _area_view_width;
        _qoynruAccountTF.placeholder = LLLLLL(@"MobileNumber");
        _qoynruAccountTF.keyboardType = UIKeyboardTypeNumberPad;
        _qoynruAreaLabel.text = _qoynruArea_name;
        _qoynruAccountImgView.image = IMAGENAME(@"phoneIcon");
        self.qoynruLoginTypeAButton.titleLabel.font = PINGFANG_M(20);
        self.qoynruLoginTypeBButton.titleLabel.font = PINGFANG_R(15);
    }else { // 邮箱
        _qoynruAccountLabel.text = LLLLLL(@"Email");
        _qoynruAreaView.hidden = YES;
        _qoynruAreaViewWidth.constant = 0.0;
        _qoynruAccountTF.placeholder = LLLLLL(@"Email");
        _qoynruAccountTF.keyboardType = UIKeyboardTypeEmailAddress;
        _qoynruAreaLabel.text = @"";
        _qoynruAccountImgView.image = IMAGENAME(@"eogcsaioxEmail");
        self.qoynruLoginTypeAButton.titleLabel.font = PINGFANG_R(15);
        self.qoynruLoginTypeBButton.titleLabel.font = PINGFANG_M(20);
    }
}
- (IBAction)eye:(UIButton *)sender {
    [self.view endEditing:YES];
    sender.selected = !sender.selected;
    _qoynruPasswordTF.secureTextEntry = !sender.selected;
}

- (IBAction)registerForgetPsw:(UIButton *)sender {
    [self.view endEditing:YES];
    if (sender.tag == 0) {
        QZBGNRJYDIOZRegisterVC *vc = QZBGNRJYDIOZRegisterVC.new;
        [self.navigationController pushViewController:vc animated:YES];
        return;
    }
    QZBGNRJYDIOZRetrievePswdVC *vc = QZBGNRJYDIOZRetrievePswdVC.new;
    [self.navigationController pushViewController:vc animated:YES];
}

// 手机号码的区号
- (IBAction)phoneArea:(UIButton *)sender {
    [self.view endEditing:YES];
    QZBGNRJYDIOZAreacodeVC *vc = QZBGNRJYDIOZAreacodeVC.new;
    vc.hidesBottomBarWhenPushed = YES;
    vc.deleagete = self;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)returnCountryName:(NSString *)countryName code:(NSString *)code {
    _qoynruAccountTF.text = @"";
    _qoynruArea_name = UNString(@"+%@", code);
    _qoynruAreaLabel.text = _qoynruArea_name;
    
    CGSize size = [AIOIUEHUtilities getTextDrawingSize:_qoynruArea_name font:[UIFont pingFangSCWithWeight:FontWeightStyleMedium size:15.0] constrainedSize:CGSizeMake(WIDTH, 8000)];
    _area_view_width = size.width + 27.0;
    _qoynruAreaViewWidth.constant = _area_view_width;
}


- (BOOL)isValid {
    if (_qoynruAccountTF.text.length <= 0) {
        [SVProgressHUD showErrorWithStatus:_qoynruAccountTF.placeholder];
        [SVProgressHUD dismissWithDelay:1.0];
        return YES;
    }
//    if (![_qoynruAccountTF.text checkPhoneNum]) {
//        [SVProgressHUD showErrorWithStatus:@"手机号码格式有误"];
//        [SVProgressHUD dismissWithDelay:1.0];
//        return YES;
//    }
    if (_qoynruPasswordTF.text.length < 4) {
        [SVProgressHUD showErrorWithStatus:_qoynruPasswordTF.placeholder];
        [SVProgressHUD dismissWithDelay:1.0];
        return YES;
    }
//    if (![_eogcsaioxqoynruPasswordTF.text checkPassword]) {
//        [SVProgressHUD showErrorWithStatus:@"请输入6-16位数字、字母组合"];
//        [SVProgressHUD dismissWithDelay:1.0];
//        return YES;
//    }
    return NO;
}


- (void)eogcsaioxTextField:(UITextField *)textField {
    BOOL account = (_eogcsaioxType == 0 ? _qoynruAccountTF.text.length >= 6 : _qoynruAccountTF.text.length >= 6);
    BOOL pswd = (!_qoynruWayButton.selected ? _qoynruPasswordTF.text.length >= 4 : _qoynruPasswordTF.text.length >= 6);
    if (account && pswd) {
        if (_qoynruLoginButton.userInteractionEnabled) {
            return;
        }
        _qoynruLoginButton.userInteractionEnabled = YES;
        [_qoynruLoginButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [_qoynruLoginButton setBackgroundImage:IMAGENAME(@"eogcsaioxBtnS")  forState:UIControlStateNormal];
    }else {
        if (!_qoynruLoginButton.userInteractionEnabled) {
            return;
        }
        _qoynruLoginButton.userInteractionEnabled = NO;
        [_qoynruLoginButton setTitleColor:MAINCOLOR forState:UIControlStateNormal];
        [_qoynruLoginButton setBackgroundImage:IMAGENAME(@"eogcsaioxBtnN")  forState:UIControlStateNormal];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSInteger length = textField.text.length - range.length + string.length;
    if (_qoynruAccountTF == textField) {
        if (_eogcsaioxType == 0) {
            if ([_qoynruArea_name isEqualToString:@"+86"]) {
                return (length <= 11);
            }
            return (length <= 15);
        }
        return (length <= 50);
    }
    if (_qoynruPasswordTF == textField) {
        if (!_qoynruWayButton.selected) { // 密码登录
            return (length <= 6);
        }
        return (length <= 16);
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.view endEditing:YES];
    return YES;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.view endEditing:true];
}

- (void)eogcsaioxClose {
    [self.view endEditing:true];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)close {
    [self.view endEditing:true];
}



// 客服
- (IBAction)customerService:(UIButton *)sender {
    ConnectionStatus status = [WFCCNetworkService.sharedInstance currentConnectionStatus];
    if (status >= 0) { // 已连接
        [self enterMessageVC];
        return;
    }
    
    NSString *userId = [KeyChainTool readData:@"kCustomerService_UserId"];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"Loading");
    [hud showAnimated:YES];
    
    NSMutableDictionary *params = NSMutableDictionary.new;
    params[@"clientId"] = SRIMNetworkService.sharedInstance.getClientId;
    params[@"platform"] = @(Platform_iOS);
    
    if (userId.length > 0) {
        params[@"userId"] = userId; // 0cgqmws2k
    }
    params[@"deviceUId"] = [KeyChainTool readData:kUUIDStringValue];
    params[@"deviceType"] = UIDevice.currentDevice.name;
    WS(weakself)
    [AppService.sharedAppService requestUrl:@"/register_temp" params:params success:^(NSDictionary * _Nonnull dict) {
        [hud hideAnimated:YES];
        NSDictionary *resultDic = dict[@"result"];
        NSString *userId = resultDic[@"userId"];
        NSString *token = resultDic[@"token"];
        if (userId.length > 0 && token.length > 0) {
            [KeyChainTool saveData:userId withIdentifier:@"kCustomerService_UserId"];
            
            [WFCCNetworkService.sharedInstance connect:userId token:token];
            [weakself enterMessageVC];
        }
    } error:^(int errCode, NSString * _Nonnull message) {
        [hud hideAnimated:YES];
    }];
}
- (void)enterMessageVC {
    YUBWOIJWDMessageVC *mvc = YUBWOIJWDMessageVC.new;
    mvc.hidesBottomBarWhenPushed = YES;
    mvc.conversation = [WFCCConversation conversationWithType:Single_Type target:@"customer_service" line:0];
    [self.navigationController pushViewController:mvc animated:YES];
}


- (void)dealloc {
    NSLog(@"%@ --- dealloc",NSStringFromClass(self.class));
}

@end
