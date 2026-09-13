//
//  WOPMKDIOFZTDestroyVC.m
//  WUHOIBDK
//
//  Created by Ruby on 1/22/24.
//

#import "WOPMKDIOFZTDestroyVC.h"
#import "OrgService.h"
#import "KeyChainTool.h"


@interface WOPMKDIOFZTDestroyVC ()
{
    NSInteger _type; // 登录方式 0 手机号  1 邮箱
    
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UILabel *descLLL;

@property (weak, nonatomic) IBOutlet UILabel *codeL;
@property (weak, nonatomic) IBOutlet UITextField *qoynruCodeTF;

@property (weak, nonatomic) IBOutlet UIButton *sendButton;

@property (weak, nonatomic) IBOutlet UIButton *destroyButton;

@end

@implementation WOPMKDIOFZTDestroyVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _sendButton.layer.cornerRadius = 5.0;
    _sendButton.layer.borderWidth = 1.0;
    _sendButton.layer.borderColor = RGBA(0x2c2c2c).CGColor;
    _destroyButton.layer.cornerRadius = 20.0;
    
    _type = [NSUserDefaults.standardUserDefaults integerForKey:kLOGIN_TYPE];
    
    _isChinese = [CommonHelper.main isChinese];
    [self updateADFLanguage];
}
- (void)updateADFLanguage {
    self.navigationItem.title = LLLLLL(@"DestroyAccount");
    _qoynruCodeTF.placeholder = LLLLLL(@"VerificationCode");
    [_sendButton setTitle:LLLLLL(@"ObtainCode") forState:UIControlStateNormal];
    if (_isChinese) {
        
    }else {
        _descLLL.text = @"Dear, really want to cruel to leave us 😭😭😭!";
        _codeL.text = @"Code";
        
        [_destroyButton setTitle:@"Destruction of account" forState:UIControlStateNormal];
    }
}

- (IBAction)destroy:(UIButton *)sender {
    [self.view endEditing:YES];
    if (_qoynruCodeTF.text.length <= 0) {
        [SVProgressHUD showErrorWithStatus:_qoynruCodeTF.placeholder];
        [SVProgressHUD dismissWithDelay:1.0];
        return ;
    }
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"OperationInProgress");
    [hud showAnimated:YES];
    
    WS(weakself)
    WFCCUserInfo *user = [[AppCache sharedAppCache]getMyInfo];
    int platform = Platform_iOS;
    if (_type == 0) {
        [AppService.sharedAppService requestUrlNoLogin:@"/destroy" params:@{@"mobile":user.mobile, @"area":user.area, @"code": _qoynruCodeTF.text, @"clientId":[[SRIMNetworkService sharedInstance] getClientId], @"platform":@(platform), @"deviceUId":[KeyChainTool readData:kUUIDStringValue], @"deviceType":UIDevice.currentDevice.name} success:^(NSDictionary * _Nonnull dict) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedName"];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedToken"];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedUserId"];
                [[AppService sharedAppService] clearAppServiceAuthInfos];
                [[OrgService sharedOrgService] clearOrgServiceAuthInfos];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                //服务器已经删除所有信息了，这里都传NO。不能传YES，如果传YES协议栈会需要跟IM服务进行交互。
                [[WFCCNetworkService sharedInstance] disconnect:NO clearSession:NO];
                [[SRIMNetworkService sharedInstance] disconnect:YES clearSession:NO];
                
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"lastLoadRemoteMessageTs"];
            });
        } error:^(int errCode, NSString * _Nonnull message) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"login error with code %d, message %@", errCode, message);
                [hud hideAnimated:YES];
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
                [weakself.view makeToast:text duration:1.0 position:CSToastPositionCenter];
            });
        }];

    } else {
        [AppService.sharedAppService requestUrlNoLogin:@"/destroyWithEmail" params:@{@"email":user.email, @"code": _qoynruCodeTF.text, @"clientId":[[SRIMNetworkService sharedInstance] getClientId], @"platform":@(platform), @"deviceUId":[KeyChainTool readData:kUUIDStringValue], @"deviceType":UIDevice.currentDevice.name} success:^(NSDictionary * _Nonnull dict) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedName"];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedToken"];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedUserId"];
                [[AppService sharedAppService] clearAppServiceAuthInfos];
                [[OrgService sharedOrgService] clearOrgServiceAuthInfos];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                //服务器已经删除所有信息了，这里都传NO。不能传YES，如果传YES协议栈会需要跟IM服务进行交互。
                [[WFCCNetworkService sharedInstance] disconnect:NO clearSession:NO];
                [[SRIMNetworkService sharedInstance] disconnect:YES clearSession:NO];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"lastLoadRemoteMessageTs"];
            });
        } error:^(int errCode, NSString * _Nonnull message) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"login error with code %d, message %@", errCode, message);
                [hud hideAnimated:YES];
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
                [weakself.view makeToast:text duration:1.0 position:CSToastPositionCenter];
            });
        }];

    }
//    [AppService.sharedAppService destroyAccount:@{@"type":@(_type), @"code":_qoynruCodeTF.text} success:^{
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedName"];
//            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedToken"];
//            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedUserId"];
//            [[AppService sharedAppService] clearAppServiceAuthInfos];
//            [[OrgService sharedOrgService] clearOrgServiceAuthInfos];
//            [[NSUserDefaults standardUserDefaults] synchronize];
//            
//            //服务器已经删除所有信息了，这里都传NO。不能传YES，如果传YES协议栈会需要跟IM服务进行交互。
//            [[WFCCNetworkService sharedInstance] disconnect:NO clearSession:NO];
//            [[SRIMNetworkService sharedInstance] disconnect:YES clearSession:NO];
//        });
//    } error:^(int errorCode, NSString * _Nonnull message) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            NSLog(@"login error with code %d, message %@", errorCode, message);
//            [hud hideAnimated:YES];
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
//            [weakself.view makeToast:text duration:1.0 position:CSToastPositionCenter];
//        });
//    }];
}

- (IBAction)send:(UIButton *)sender {
    [self.view endEditing:YES];
    _qoynruCodeTF.text = @"";
    sender.userInteractionEnabled = NO;
    [sender setTitle:(_isChinese ? @"短信发送中" : @"Sending...") forState:UIControlStateNormal];
    WS(weakself)
    WFCCUserInfo *user = [[AppCache sharedAppCache]getMyInfo];
    if (_type == 0) {
        [SVProgressHUD show];
//        [[AppService sharedAppService] sendLoginCode:@{@"mobile":user.mobile, @"area":user.area} success:^{
//            [SVProgressHUD dismiss];
//            [weakself.view makeToast:LLLLLL(@"SentSuccessfully") duration:1.0 position:CSToastPositionCenter];
//            [CommonHelper.main handleTimer:sender];
//            
//        } error:^(NSString * _Nonnull message) {
//            [SVProgressHUD dismiss];
//            sender.userInteractionEnabled = YES;
//            [sender setTitle:LLLLLL(@"ObtainCode") forState:UIControlStateNormal];
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
//            [weakself.view makeToast:text duration:1.0 position:CSToastPositionCenter];
//        }];
        
        [[AppService sharedAppService] sendMobileCodeWithScene:@{@"scene":@"3"}
                                                       success:^{
            [SVProgressHUD dismiss];
            [weakself.view makeToast:LLLLLL(@"SentSuccessfully") duration:1.0 position:CSToastPositionCenter];
            [CommonHelper.main handleTimer:sender];
            
        } error:^(int errCode, NSString * _Nonnull message) {
            [SVProgressHUD dismiss];
            sender.userInteractionEnabled = YES;
            [sender setTitle:LLLLLL(@"ObtainCode") forState:UIControlStateNormal];
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
            [weakself.view makeToast:text duration:1.0 position:CSToastPositionCenter];
        }];

    } else {
        [SVProgressHUD show];
//        [AppService.sharedAppService requestUrlNoLogin:@"/sendEmailCode" params:@{@"email":user.email} success:^(NSDictionary * _Nonnull dict) {
//            [SVProgressHUD dismiss];
//            [weakself.view makeToast:LLLLLL(@"SentSuccessfully") duration:1.0 position:CSToastPositionCenter];
//            [CommonHelper.main handleTimer:sender];
//            
//        } error:^(int errCode, NSString * _Nonnull message) {
//            [SVProgressHUD dismiss];
//            sender.userInteractionEnabled = YES;
//            [sender setTitle:LLLLLL(@"ObtainCode") forState:UIControlStateNormal];
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
//            [weakself.view makeToast:text duration:1.0 position:CSToastPositionCenter];
//        }];
        
        [AppService.sharedAppService sendEmailCodeWithScene:@{@"scene":@"3"}
                                                    success:^ {
            [SVProgressHUD dismiss];
            [weakself.view makeToast:LLLLLL(@"SentSuccessfully") duration:1.0 position:CSToastPositionCenter];
            [CommonHelper.main handleTimer:sender];
            
        } error:^(int errCode, NSString * _Nonnull message) {
            [SVProgressHUD dismiss];
            sender.userInteractionEnabled = YES;
            [sender setTitle:LLLLLL(@"ObtainCode") forState:UIControlStateNormal];
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
            [weakself.view makeToast:text duration:1.0 position:CSToastPositionCenter];
        }];
    }
//    [AppService.sharedAppService sendDestroyAccountCode:@{@"type":@(_type)} success:^{
//        [weakself.view makeToast:LLLLLL(@"SentSuccessfully") duration:1.0 position:CSToastPositionCenter];
//        [CommonHelper.main handleTimer:sender];
//    } error:^(int errorCode, NSString * _Nonnull message) {
//        sender.userInteractionEnabled = YES;
//        [sender setTitle:LLLLLL(@"ObtainCode") forState:UIControlStateNormal];
//        NSString *text = @"";
//        if (self->_isChinese) {
//            text = message;
//        }else {
//            if ([message containsString:@"失败"]) {
//                text = @"Failure...";
//            }else if ([message containsString:@"错误"]) {
//                text = @"Error...";
//            }else {
//                text = @"Error...";
//            }
//        }
//        [weakself.view makeToast:text duration:1.0 position:CSToastPositionCenter];
//    }];
}



- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}


@end
