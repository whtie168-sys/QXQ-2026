//
//  WOPMKDIOFZTGetCodeVC.m
//  WUHOIBDK
//
//  Created by Ruby on 12/7/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "WOPMKDIOFZTGetCodeVC.h"

#import "WOPMKDIOFZTNumberVC.h"

@interface WOPMKDIOFZTGetCodeVC ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;

@property (weak, nonatomic) IBOutlet UIView *aBgView;

@property (weak, nonatomic) IBOutlet UITextField *qoynruCodeTF;

@property (weak, nonatomic) IBOutlet UIButton *qoynruSendcodeButton;
@property (weak, nonatomic) IBOutlet UIButton *okButton;


@property (weak, nonatomic) IBOutlet UILabel *yanMingL;

@end

@implementation WOPMKDIOFZTGetCodeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    WFCCUserInfo *userInfo =[[AppCache sharedAppCache] getMyInfo];
    if (userInfo.mobile.length > 0) {
        NSArray *phones = [userInfo.mobile componentsSeparatedByString:@" "];
        NSString *mobile = phones.lastObject;
        NSMutableString *star = NSMutableString.new;
        for (NSInteger i = 0; i < mobile.length-7; i ++) {
            [star appendString:@"*"];
        }
        _phoneLabel.text = [NSString stringWithFormat:@"%@ %@",userInfo.area, [mobile stringByReplacingCharactersInRange:NSMakeRange(3, mobile.length - 7) withString:UNString(@" %@ ", star)]];
    } else if (userInfo.email.length > 0) {
        NSArray *emails = [userInfo.email componentsSeparatedByString:@"@"];
        NSString *emailFront = emails.firstObject; // 类似于->Loooooo
        if (emailFront.length <= 4) {
            if (emailFront.length <= 2) {
                _phoneLabel.text = userInfo.email;
            }else {
                _phoneLabel.text = [NSString stringWithFormat:@"%@**%@@%@",[emailFront substringToIndex:1], [emailFront substringFromIndex:(emailFront.length-1)], emails.lastObject];
            }
        }else {
            _phoneLabel.text = [NSString stringWithFormat:@"%@****%@@%@",[emailFront substringToIndex:2], [emailFront substringFromIndex:(emailFront.length-2)], emails.lastObject];
        }
    }

    _aBgView.layer.cornerRadius = 10.0;
    _okButton.layer.cornerRadius = 12.0;
    _okButton.userInteractionEnabled = NO;
    
    _qoynruCodeTF.delegate = self;
    [_qoynruCodeTF addTarget:self action:@selector(textField:) forControlEvents:UIControlEventEditingChanged];
    
    [self updateADFLanguage];
}
- (void)updateADFLanguage {
    
    if ([CommonHelper.main isChinese]) {
        self.navigationItem.title = @"忘记数字密码";
    }else {
        self.navigationItem.title = @"Forgot digital password";
        _yanMingL.text = @"For account security, we need to verify your identity.";
        
        _qoynruCodeTF.placeholder = LLLLLL(@"VerificationCode");
        [_qoynruSendcodeButton setTitle:LLLLLL(@"ObtainCode") forState:UIControlStateNormal];
        [_okButton setTitle:LLLLLL(@"OK") forState:UIControlStateNormal];
    }
}

- (IBAction)ok:(UIButton *)sender {
    [self.view endEditing:YES];
    if (_qoynruCodeTF.text.length <= 0) {
        [SVProgressHUD showErrorWithStatus:_qoynruCodeTF.placeholder];
        [SVProgressHUD dismissWithDelay:1.0];
        return ;
    }
    WOPMKDIOFZTNumberVC *vc = WOPMKDIOFZTNumberVC.new;
    vc.code = _qoynruCodeTF.text;
    vc.type = 3;
    [self.navigationController pushViewController:vc animated:YES];
    
//    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//    hud.label.text = @"验证中...";
//    [hud showAnimated:YES];
//    
//    __weak typeof(self)ws = self;
//    [[AppService sharedAppService] resetPassword:@"" code:_qoynruCodeTF.text newPassword:@"" success:^{
//        [hud hideAnimated:YES];
//        
//        
//    } error:^(int errCode, NSString * _Nonnull message) {
//        [hud hideAnimated:YES];
//        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//        hud.mode = MBProgressHUDModeText;
//        hud.label.text = message;
//        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
//        [hud hideAnimated:YES afterDelay:1.f];
//    }];
}

- (IBAction)sendCode:(UIButton *)sender {
    [self.view endEditing:YES];
    int type = 1;
    WFCCUserInfo *userInfo =[[AppCache sharedAppCache] getMyInfo];
    if (userInfo.mobile.length > 0) {
        type = 0;
    }
    [CommonHelper.main send_reset_device_code_button:sender type:type];
}

- (void)textField:(UITextField *)textField {
    if (_qoynruCodeTF.text.length >= 4) {
        if (_okButton.userInteractionEnabled) {
            return;
        }
        _okButton.userInteractionEnabled = YES;
        _okButton.backgroundColor = MAINCOLOR;
    }else {
        if (!_okButton.userInteractionEnabled) {
            return;
        }
        _okButton.userInteractionEnabled = NO;
        _okButton.backgroundColor = RGBA(0xD5D6DA);
    }
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSInteger length = textField.text.length - range.length + string.length;
    if (_qoynruCodeTF == textField) {
        return (length <= 6);
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.view endEditing:YES];
    return YES;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

@end
