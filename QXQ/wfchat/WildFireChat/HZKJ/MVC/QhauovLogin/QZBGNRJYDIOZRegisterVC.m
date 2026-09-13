//
//  QZBGNRJYDIOZRegisterVC.m
//  WUHOIBDK
//
//  Created by Ruby on 12/25/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "QZBGNRJYDIOZRegisterVC.h"
#import "KeyChainTool.h"

#import "QZBGNRJYDIOZProtocolVC.h"
#import "QZBGNRJYDIOZAreacodeVC.h"
#import "QABWJEFDOCYTabBarVC.h"

#import "YUBWOIJWDMessageVC.h"
#import "RegisterSetAvatarVC.h"
#import <WFChatClient/SRIMNetworkService.h>

@interface QZBGNRJYDIOZRegisterVC ()<UITextFieldDelegate, UIScrollViewDelegate, XWCountryCodeControllerDelegate>
{
    NSInteger _eogcsaioxType; // 手机 or 邮箱
    
    NSString *_qoynruArea_name; // 手机区号
    CGFloat _area_view_width; // 手机区号的宽度
    
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UIImageView *boxBgView;

@property (weak, nonatomic) IBOutlet UIButton *qoynruRegisterTypeAButton;
@property (weak, nonatomic) IBOutlet UIButton *qoynruRegisterTypeBButton;

@property (weak, nonatomic) IBOutlet UITextField *qoynruAccountTF;
@property (weak, nonatomic) IBOutlet UITextField *qoynruCodeTF;
@property (weak, nonatomic) IBOutlet UIImageView *qoynruAccountImgView;
@property (weak, nonatomic) IBOutlet UILabel *qoynruAccountLabel;
@property (weak, nonatomic) IBOutlet UILabel *qoynruCodeLabel;
@property (weak, nonatomic) IBOutlet UIButton *qoynruSendcodeButton;

@property (weak, nonatomic) IBOutlet UIView *qoynruAreaView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *qoynruAreaViewWidth;
@property (weak, nonatomic) IBOutlet UILabel *qoynruAreaLabel;

@property (weak, nonatomic) IBOutlet UIButton *qoynruRegisterButton;

@property (weak, nonatomic) IBOutlet UILabel *qoynruHaveAmountL;
@property (weak, nonatomic) IBOutlet UILabel *qoynruGoLoginL;

@property (weak, nonatomic) IBOutlet UIButton *qoynruProtocolButton;
@property (weak, nonatomic) IBOutlet UILabel *andL;
@property (weak, nonatomic) IBOutlet UIButton *qoynruUserProtocolBtn;
@property (weak, nonatomic) IBOutlet UIButton *qoynruPrivacyProtocolBtn;

@property (weak, nonatomic) IBOutlet UIButton *qoynruCustomerBtn;

@end

@implementation QZBGNRJYDIOZRegisterVC

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
- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [CommonHelper.main isChinese];
    
    _qoynruArea_name = @"+86";
    _area_view_width = 55.0;
    _qoynruAreaViewWidth.constant = _area_view_width;
    
    _scrollView.delegate = self;
    [_scrollView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close)]];

    _qoynruAccountTF.delegate = self;
    _qoynruCodeTF.delegate = self;
    [_qoynruAccountTF addTarget:self action:@selector(registerTextField:) forControlEvents:UIControlEventEditingChanged];
    [_qoynruCodeTF addTarget:self action:@selector(registerTextField:) forControlEvents:UIControlEventEditingChanged];
    
    [self preferredStatusBarStyle];
    
    _qoynruRegisterButton.userInteractionEnabled = NO;
    
    _qoynruRegisterTypeAButton.titleLabel.font = PINGFANG_M(20);
    [self qoynruType];
    
    [self updateADFLanguage];
}
- (void)updateADFLanguage {
    [_qoynruRegisterTypeAButton setTitle:LLLLLL(@"Tel") forState:UIControlStateNormal];
    [_qoynruRegisterTypeBButton setTitle:LLLLLL(@"E-mail") forState:UIControlStateNormal];
    
    _qoynruCodeTF.placeholder = (_isChinese ? @"请输入验证码" : @"Verification code");
    _qoynruAccountLabel.text = LLLLLL(@"MobileNumber");
    _qoynruCodeLabel.text = LLLLLL(@"Code");
    
    [_qoynruSendcodeButton setTitle:LLLLLL(@"ObtainCode") forState:UIControlStateNormal];
    [_qoynruRegisterButton setTitle:LLLLLL(@"SignUp") forState:UIControlStateNormal];
    
    _qoynruHaveAmountL.text = _isChinese ? @"已有账户？" : @"Already have an account? ";
    _qoynruGoLoginL.text = _isChinese ? @"去登录" : @"To log in";
    
    [_qoynruProtocolButton setTitle:(_isChinese ? @"我已阅读并同意": @"I have read and agreed to the") forState:UIControlStateNormal];
    _andL.text = (_isChinese ? @"和" : @"and");
    [_qoynruUserProtocolBtn setTitle:UNString(@"《%@》", LLLLLL(@"UserAgreement")) forState:UIControlStateNormal];
    [_qoynruPrivacyProtocolBtn setTitle:UNString(@"《%@》", LLLLLL(@"PrivacyPolicy")) forState:UIControlStateNormal];
    
    [_qoynruCustomerBtn setTitle:LLLLLL(@"CustomerService") forState:UIControlStateNormal];
}

- (IBAction)registerAccount:(UIButton *)sender {
    [self.view endEditing:YES];
    if ([self isValid]) {
        return;
    }
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = _isChinese ? @"注册中..." : @"Under registration...";
    [hud showAnimated:YES];
    
//    ConnectionStatus status = [WFCCNetworkService.sharedInstance currentConnectionStatus];
//    if (status >= 0) { // 说明进了客服的界面、证明该im已被连接、需要断开连接才能再次进行连接 3秒
//        [WFCCNetworkService.sharedInstance disconnect:YES clearSession:NO];
//        [[SRIMNetworkService sharedInstance] disconnect:YES clearSession:NO];
//        WS(weakself) // 链接客服后、立马进行账号登录、未到3秒、也不会奔溃  奇怪、、、
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [weakself registerAcc:hud];
//        });
//    }else {
        [self registerAcc:hud];
//    }
}
- (void)registerAcc:(MBProgressHUD *)hud {
    NSString *url = @"";
    NSMutableDictionary *params = NSMutableDictionary.new;
    params[@"clientId"] = SRIMNetworkService.sharedInstance.getClientId;
    params[@"platform"] = @(Platform_iOS);
    
    params[@"deviceUId"] = [KeyChainTool readData:kUUIDStringValue];
    params[@"deviceType"] = UIDevice.currentDevice.name;
    
    if (_eogcsaioxType == 0) { // 手机号码注册
        url = @"/register";
        params[@"area"] = _qoynruArea_name;
        params[@"mobile"] = _qoynruAccountTF.text;
    }else {
        url = @"/registerWithEmail";
        params[@"email"] = _qoynruAccountTF.text;
    }
    params[@"code"] = _qoynruCodeTF.text;
    
    WS(weakself)
    [AppService.sharedAppService requestUrl:url params:params success:^(NSDictionary * _Nonnull dict) {
        [hud hideAnimated:YES];
        [SVProgressHUD showSuccessWithStatus:(self->_isChinese ? @"注册成功..." : @"Registered successfully...")];
        [SVProgressHUD dismissWithDelay:1.0];
        
        [weakself registerAccountSuccess:dict];
    } error:^(int errCode, NSString * _Nonnull message) {
        [hud hideAnimated:YES];
        NSString *text = @"";
        if (self->_isChinese) {
            text = message;
        }else {
            if ([message containsString:@"验证码错误"]) {
                text = @"Verification code error";
            }else if ([message containsString:@"错误"]) {
                text = @"Error...";
            }else {
                text = @"Error...";
            }
        }
        [weakself.view makeToast:text duration:1.0 position:CSToastPositionCenter];
    }];
}

- (void)registerAccountSuccess:(NSDictionary *)dict {
    NSString *userId = dict[@"result"][@"userCode"];//dict[@"result"][@"userId"];
    NSString *token = dict[@"result"][@"accessToken"];
    NSString *websocketToken = dict[@"result"][@"websocketToken"];
    NSString *hasPassword = dict[@"result"][@"hasPassword"];
    [[NSUserDefaults standardUserDefaults] setObject:token forKey:@"savedToken"];
    [[NSUserDefaults standardUserDefaults] setObject:userId forKey:@"savedUserId"];
    [[NSUserDefaults standardUserDefaults] setObject:websocketToken forKey:@"savedwebsocketToken"];
    [[NSUserDefaults standardUserDefaults] setInteger:hasPassword.integerValue forKey:@"kHasPassword"];
    [[NSUserDefaults standardUserDefaults] setInteger:_eogcsaioxType forKey:kLOGIN_TYPE]; // 登录方式 0 手机号码    1 邮箱
    [[NSUserDefaults standardUserDefaults] synchronize];
    
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
                
        [PIUODJNLockStatusManager.main getLockStatusData:^(BOOL isSuccess) {
        }]; // 获取安全锁相关配置
        
    } error:^(int errCode, NSString * _Nonnull message) {
    
    }];

    
    [[AppService sharedAppService] userBindIos:@{@"deviceToken": [WFCCNetworkService sharedInstance].pushToken,@"topic":[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]}
                                       success:^{
        
    } error:^(int errCode, NSString * _Nonnull message) {
        
    }];

    
    //需要注意token跟clientId是强依赖的，一定要调用getClientId获取到clientId，然后用这个clientId获取token，这样connect才能成功，如果随便使用一个clientId获取到的token将无法链接成功。
//    [[WFCCNetworkService sharedInstance] connect:userId token:token];
    [[SRIMNetworkService sharedInstance] connect:userId token:websocketToken];
    
//    QABWJEFDOCYTabBarVC *tabBarVC = QABWJEFDOCYTabBarVC.new;
//    [UIApplication sharedApplication].delegate.window.rootViewController =  tabBarVC;
    
    [self setAvatar];
}

- (void)setAvatar {
    [self.navigationController pushViewController:[RegisterSetAvatarVC new] animated:YES];
}
/**
 code = 0; -> 注册成功返回的字段
 message = success;
 result =     {
     deviceLockStatus = 0;
     hasEmail = 0;
     hasMobile = 1;
     hasPassword = 0;
     portrait = "";
     register = 0;
     resetCode = 437730;
     token = "KHJ/C+oSM2MIkYkRzlcbDvf2a1jIM76yFypzR5YbH6094R3lkTMTMBxhELMRzer9yUWCJmo/2WtOreU/mnhKyi/gnXIAbEVpza7XujS39arPja3xM0crTDRt53S/rNxzyDzhBsyAJNY3XZztJU1XAF5V1dFFID3H7tJcxdezVRA=";
     userId = 7lgqmws2k;
     userName = 6KUDZDF7;
 };
 
 code = 0; -> 登录返回的数据
 message = success;
 result =     {
     deviceLockStatus = 0;
     hasEmail = 0;
     hasMobile = 1;
     hasPassword = 0;
     portrait = "";
     register = 0;
     resetCode = 173321;
     token = "mVnd76afDwmVRNA6lDyaSFRtjQLvNKOOQthAaENzIHvQpGgacEpesPbhD/tIBcvR6Ef2B4eVEg5rFmluATrDQEbOmlOkDdCv1C034KbsXCUiLwLyj4CQ26SwI574oq+sWBCJTsZOkCDiHZJsphNkm09fLxdVn45SnaEUFMWPVCw=";
     userId = 7lgqmws2k;
     userName = 6KUDZDF7;
 };
 */


// 发送验证码
- (IBAction)eogcsaioxSendCode:(UIButton *)sender {
    [self.view endEditing:YES];
    if (_qoynruAccountTF.text.length <= 0) {
        [SVProgressHUD showErrorWithStatus:_qoynruAccountTF.placeholder];
        [SVProgressHUD dismissWithDelay:1.0];
        return ;
    }
    sender.userInteractionEnabled = NO;
    if (_eogcsaioxType == 0) { // 手机号码获取验证码
        [SVProgressHUD show];
//        [AppService.sharedAppService requestUrlNoLogin:@"/sendMobileCode" params:@{@"area":_qoynruArea_name, @"mobile":_qoynruAccountTF.text} success:^(NSDictionary * _Nonnull dict) {
//            [SVProgressHUD dismiss];
//            sender.userInteractionEnabled = NO;
//            [self.view makeToast:LLLLLL(@"SentSuccessfully") duration:1.0 position:CSToastPositionCenter];
//            
//            [CommonHelper.main handleTimer:sender];
//        } error:^(int errCode, NSString * _Nonnull message) {
//            [SVProgressHUD dismiss];
//            sender.userInteractionEnabled = YES;
//            NSString *text = @"";
//            if (self->_isChinese) {
//                text = message;
//            }else {
//                if ([message containsString:@"失败"]) {
//                    text = @"Failure...";
//                }else if ([message containsString:@"错误"]) {
//                    text = @"Error...";
//                }else {
//                    text = @"Error...";
//                }
//            }
//            [self.view makeToast:text duration:1.0 position:CSToastPositionCenter];
//        }];
        
        [AppService.sharedAppService sendRegisterMobileCode:@{@"area":_qoynruArea_name,
                                                              @"mobile":_qoynruAccountTF.text,
                                                              @"opt":@"0"}
                                                    success:^ {
            [SVProgressHUD dismiss];
            sender.userInteractionEnabled = NO;
            [self.view makeToast:LLLLLL(@"SentSuccessfully") duration:1.0 position:CSToastPositionCenter];
            
            [CommonHelper.main handleTimer:sender];
        } error:^(int errCode, NSString * _Nonnull message) {
            [SVProgressHUD dismiss];
            sender.userInteractionEnabled = YES;
            NSString *text = @"";
            if (self->_isChinese) {
                text = message;
            }else {
                if ([message containsString:@"失败"]) {
                    text = @"Failure...";
                }else if ([message containsString:@"错误"]) {
                    text = @"Error...";
                }else {
                    text = @"Error...";
                }
            }
            [self.view makeToast:text duration:1.0 position:CSToastPositionCenter];
        }];

        
    }else {
        [SVProgressHUD show];
//        [AppService.sharedAppService requestUrlNoLogin:@"/sendEmailCode" params:@{@"email":_qoynruAccountTF.text} success:^(NSDictionary * _Nonnull dict) {
//            [SVProgressHUD dismiss];
//            sender.userInteractionEnabled = NO;
//            [self.view makeToast:LLLLLL(@"SentSuccessfully") duration:1.0 position:CSToastPositionCenter];
//            
//            [CommonHelper.main handleTimer:sender];
//        } error:^(int errCode, NSString * _Nonnull message) {
//            [SVProgressHUD dismiss];
//            sender.userInteractionEnabled = YES;
//            NSString *text = @"";
//            if (self->_isChinese) {
//                text = message;
//            }else {
//                if ([message containsString:@"失败"]) {
//                    text = @"Failure...";
//                }else if ([message containsString:@"错误"]) {
//                    text = @"Error...";
//                }else {
//                    text = @"Error...";
//                }
//            }
//            [self.view makeToast:text duration:1.0 position:CSToastPositionCenter];
//        }];
        
        [AppService.sharedAppService sendRegisterEmailCode:@{@"email":_qoynruAccountTF.text,
                                                             @"opt":@"0"}
                                                   success:^ {
            [SVProgressHUD dismiss];
            sender.userInteractionEnabled = NO;
            [self.view makeToast:LLLLLL(@"SentSuccessfully") duration:1.0 position:CSToastPositionCenter];
            
            [CommonHelper.main handleTimer:sender];
        } error:^(int errCode, NSString * _Nonnull message) {
            [SVProgressHUD dismiss];
            sender.userInteractionEnabled = YES;
            NSString *text = @"";
            if (self->_isChinese) {
                text = message;
            }else {
                if ([message containsString:@"失败"]) {
                    text = @"Failure...";
                }else if ([message containsString:@"错误"]) {
                    text = @"Error...";
                }else {
                    text = @"Error...";
                }
            }
            [self.view makeToast:text duration:1.0 position:CSToastPositionCenter];
        }];

    }
    _qoynruCodeTF.text = @"";
}

- (IBAction)loginType:(UIButton *)sender {
    [self.view endEditing:YES];
    if (_eogcsaioxType == sender.tag) {
        return;
    }
    _eogcsaioxType = sender.tag;
    [self qoynruType];
}
- (void)qoynruType {
    if (_eogcsaioxType == 0) {
        _boxBgView.image = IMAGENAME(@"LoginType0");
        _qoynruAccountLabel.text = LLLLLL(@"MobileNumber");
        _qoynruAccountTF.placeholder = LLLLLL(@"MobileNumbers");
        _qoynruAccountTF.keyboardType = UIKeyboardTypeNumberPad;
        _qoynruAreaView.hidden = NO;
        _qoynruAreaLabel.text = _qoynruArea_name;
        _qoynruAreaViewWidth.constant = _area_view_width;
        _qoynruAccountImgView.image = IMAGENAME(@"phoneIcon");
        _qoynruRegisterTypeAButton.titleLabel.font = PINGFANG_M(20);
        _qoynruRegisterTypeBButton.titleLabel.font = PINGFANG_R(15);
    }else {
        _boxBgView.image = IMAGENAME(@"LoginType1");
        _qoynruAccountLabel.text = LLLLLL(@"Email");
        _qoynruAccountTF.placeholder = LLLLLL(@"Email");
        _qoynruAccountTF.keyboardType = UIKeyboardTypeEmailAddress;
        _qoynruAreaView.hidden = YES;
        _qoynruAreaLabel.text = @"";
        _qoynruAreaViewWidth.constant = 0.0;
        _qoynruAccountImgView.image = IMAGENAME(@"eogcsaioxEmail");
        _qoynruRegisterTypeAButton.titleLabel.font = PINGFANG_R(15);
        _qoynruRegisterTypeBButton.titleLabel.font = PINGFANG_M(20);
    }
    _qoynruRegisterTypeAButton.selected = (_eogcsaioxType == 0);
    _qoynruRegisterTypeBButton.selected = (_eogcsaioxType == 1);
    _qoynruAccountTF.text = @"";
    _qoynruCodeTF.text = @"";
    [_qoynruSendcodeButton setTitle:LLLLLL(@"ObtainCode") forState:UIControlStateNormal];
    [_qoynruSendcodeButton setTitleColor:MAINCOLOR forState:UIControlStateNormal];
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


- (IBAction)login:(UIButton *)sender {
    [self.view endEditing:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)eogcsaioxProtocol:(UIButton *)sender {
    [self.view endEditing:YES];
    sender.selected = !sender.selected;
}

- (IBAction)protocolDetails:(UIButton *)sender {
    [self.view endEditing:YES];
    QZBGNRJYDIOZProtocolVC *vc = QZBGNRJYDIOZProtocolVC.new;
    vc.eogcsaioxType = sender.tag;
    [self.navigationController pushViewController:vc animated:YES];
}

- (BOOL)isValid {
    if (_qoynruAccountTF.text.length <= 0) {
        [SVProgressHUD showErrorWithStatus:_qoynruAccountTF.placeholder];
        [SVProgressHUD dismissWithDelay:1.0];
        return YES;
    }
    if (_eogcsaioxType == 0) {
//        if (![_qoynruAccountTF.text checkPhoneNum]) {
//            [SVProgressHUD showErrorWithStatus:@"手机号码格式有误"];
//            [SVProgressHUD dismissWithDelay:1.0];
//            return YES;
//        }
        if (_qoynruAccountTF.text.length < 6) {
            [SVProgressHUD showErrorWithStatus:(_isChinese ? @"手机号码格式有误" : @"The mobile number format is incorrect")];
            [SVProgressHUD dismissWithDelay:1.0];
            return YES;
        }
    }
    if (_qoynruCodeTF.text.length < 4) {
        [SVProgressHUD showErrorWithStatus:_qoynruCodeTF.placeholder];
        [SVProgressHUD dismissWithDelay:1.0];
        return YES;
    }
    if (!_qoynruProtocolButton.selected) {
        [SVProgressHUD showErrorWithStatus:(_isChinese ? @"请您阅读协议" : @"Please read the agreement")];
        [SVProgressHUD dismissWithDelay:1.0];
        return YES;
    }
    return NO;
}


- (void)registerTextField:(UITextField *)textField {
    BOOL account = (_eogcsaioxType == 0 ? ([_qoynruArea_name isEqualToString:@"+86"] ? _qoynruAccountTF.text.length >= 11 : _qoynruAccountTF.text.length >= 6) : _qoynruAccountTF.text.length >= 6);
    if (account && (_qoynruCodeTF.text.length >= 4)) {
        if (_qoynruRegisterButton.userInteractionEnabled) {
            return;
        }
        _qoynruRegisterButton.userInteractionEnabled = YES;
        [_qoynruRegisterButton setBackgroundImage:IMAGENAME(@"eogcsaioxBtnS")  forState:UIControlStateNormal];
        [_qoynruRegisterButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    }else {
        if (!_qoynruRegisterButton.userInteractionEnabled) {
            return;
        }
        _qoynruRegisterButton.userInteractionEnabled = NO;
        [_qoynruRegisterButton setBackgroundImage:IMAGENAME(@"eogcsaioxBtnN")  forState:UIControlStateNormal];
        [_qoynruRegisterButton setTitleColor:MAINCOLOR forState:UIControlStateNormal];
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
        }else {
            return (length <= 50);
        }
    }
    if (_qoynruCodeTF == textField) {
        return (length <= 6);
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
        params[@"userId"] = userId;
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
