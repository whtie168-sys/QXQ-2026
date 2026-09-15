//
//  WOPMKDIOFZTNumberVC.m
//  WUHOIBDK
//
//  Created by Ruby on 12/5/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "WOPMKDIOFZTNumberVC.h"

#import "WOPMKDIOFZTLockVC.h"
#import "WOPMKDIOFZTClearChatVC.h"

#import "QZBGNRJYDIOZLoginVC.h"

@interface WOPMKDIOFZTNumberVC ()
{
    NSArray<UIButton *> *_pswBtns;
    
    NSInteger _group; // 当前第几组
    
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIView *bgView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UIButton *pswAButton;
@property (weak, nonatomic) IBOutlet UIButton *pswBButton;
@property (weak, nonatomic) IBOutlet UIButton *pswCButton;
@property (weak, nonatomic) IBOutlet UIButton *pswDButton;

@property (weak, nonatomic) IBOutlet UIButton *number1Btn;
@property (weak, nonatomic) IBOutlet UIButton *number2Btn;
@property (weak, nonatomic) IBOutlet UIButton *number3Btn;
@property (weak, nonatomic) IBOutlet UIButton *number4Btn;
@property (weak, nonatomic) IBOutlet UIButton *number5Btn;
@property (weak, nonatomic) IBOutlet UIButton *number6Btn;
@property (weak, nonatomic) IBOutlet UIButton *number7Btn;
@property (weak, nonatomic) IBOutlet UIButton *number8Btn;
@property (weak, nonatomic) IBOutlet UIButton *number9Btn;
@property (weak, nonatomic) IBOutlet UIButton *number0Btn;

@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@property (weak, nonatomic) IBOutlet UIButton *resetButton;

@property (weak, nonatomic) IBOutlet UIButton *forgetButton;

@property (nonatomic, strong) NSMutableArray *firstDatas;
@property (nonatomic, strong) NSMutableArray *secondDatas;
@property (nonatomic, assign) NSInteger currentIndex; // 当前应该输入的第几个

@property (nonatomic, assign) BOOL isReset; // 修改数字密码专属 (当数字验证通过之后·该值为YES)

@end

@implementation WOPMKDIOFZTNumberVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [CommonHelper.main isChinese];
    
    _forgetButton.hidden = YES;
    [self naviTitle];
    
    _group = 0;
    _currentIndex = -1;
    _deleteButton.hidden = YES;
    _resetButton.hidden = YES;
    
    [_resetButton setTitle:(_isChinese ? @"重新设置" : @"Reset") forState:UIControlStateNormal];
    [_forgetButton setTitle:(_isChinese ? @"重新设置" : @"Forgot password") forState:UIControlStateNormal];
    
    _isReset = NO;
    _firstDatas = NSMutableArray.new;
    _secondDatas = NSMutableArray.new;
    
    _pswBtns = @[_pswAButton, _pswBButton, _pswCButton, _pswDButton];
    for (UIButton *btn in @[_number1Btn, _number2Btn, _number3Btn, _number4Btn,
                            _number5Btn, _number6Btn, _number7Btn, _number8Btn,
                            _number9Btn, _number0Btn]) {
        btn.layer.cornerRadius = 35.0;
    }
}

- (void)naviTitle {
    if (self.type == 0) {
        self.navigationItem.title = _isChinese ? @"设置数字密码" : @"Set a digital password";
        self.titleLabel.text = _isChinese ? @"输入数字密码" : @"Enter digital code";
    }else if (self.type == 1) {
        self.navigationItem.title = _isChinese ? @"验证数字密码" : @"Verify the digital password";
        self.titleLabel.text = _isChinese ? @"验证数字密码" : @"Verify the digital password";
    }else if (self.type == 2) {
        self.navigationItem.title = _isChinese ? @"验证数字密码" : @"Verify the digital password";
        self.titleLabel.text = _isChinese ? @"验证数字密码" : @"Verify the digital password";
    }else if (self.type == 3) {
        self.navigationItem.title = _isChinese ? @"设置数字密码" : @"Set a digital password";
        self.titleLabel.text = _isChinese ? @"输入数字密码" : @"Enter digital code";
    }else if (self.type == 4 || self.type == 5 || self.type ==6) {
        self.navigationItem.title = @"";
        self.titleLabel.text = _isChinese ? @"验证数字密码" : @"Verify the digital password";
        UIButton *rightBtn = [self itemTitle:(_isChinese ? @"切换账号" : @"Switch account") action:@selector(switchAccount)];
        rightBtn.frame = CGRectMake(0.0, 0.0, 60.0, 30.0);
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightBtn];
        _forgetButton.hidden = NO;
        if (self.type == 5 || self.type == 6) {
            self.navigationItem.hidesBackButton = YES;
        }
    }
    self.titleLabel.textColor = RGBA(0x222222);
}

- (IBAction)number:(UIButton *)sender {
    WS(weakself)
    if (self.type == 0) {
        [self doubleSetup:sender.tag success:^(NSString *number) {
            [AppService.sharedAppService requestUrl:@"/device_lock/update_device_number" params:@{@"newNumber":number} success:^(NSDictionary * _Nonnull dict) {
                [PIUODJNLockStatusManager.main getLockStatusData:^(BOOL lockStatus) {
                    [weakself reset:nil];
                    if (weakself.pswBlock) {
                        weakself.pswBlock(number);
                    }
                    [self.navigationController popViewControllerAnimated:YES];
                }];
            } error:^(int errCode, NSString * _Nonnull message) {
                [weakself reset:nil];
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
        }];
    }else if (self.type == 1) { // 验证数字密码。输入1次 跟服务器的值进行对比
        [self singleVerification:sender.tag success:^{
            [AppService.sharedAppService requestUrl:@"/device_lock/set_status" params:@{@"status":@(0)} success:^(NSDictionary * _Nonnull dict) {
                [weakself reset:nil];
                if (weakself.pswBlock) {
                    weakself.pswBlock(@"");
                }
                [PIUODJNLockStatusManager.main reWriteLockInfo:@(0) ForKey:@"status"];
                [self.navigationController popViewControllerAnimated:YES];
            } error:^(int errCode, NSString * _Nonnull message) {
                [weakself reset:nil];
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
        }];
    }else if (self.type == 2) { // 修改数字密码。首先先验证数字密码，再实现2次设置
        if (_isReset == NO) {
            [self singleVerification:sender.tag success:^{
                [weakself reset:nil];
                weakself.isReset = YES;
            }];
        }else {
            [self doubleSetup:sender.tag success:^(NSString *number) {
                [AppService.sharedAppService requestUrl:@"/device_lock/update_device_number" params:@{@"oldNumber":PIUODJNLockStatusManager.main.lockStatus.number, @"newNumber":number} success:^(NSDictionary * _Nonnull dict) {
                    [weakself reset:nil];
                    if (weakself.pswBlock) {
                        weakself.pswBlock(number);
                    }
                    [PIUODJNLockStatusManager.main reWriteLockInfo:number ForKey:@"number"];
                    [self.navigationController popViewControllerAnimated:YES];
                } error:^(int errCode, NSString * _Nonnull message) {
                    [weakself reset:nil];
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
            }];
        }
    }else if (self.type == 3) { // 忘记数字密码，设置数字密码，输入2次
        [self doubleSetup:sender.tag success:^(NSString *number) {
            [AppService.sharedAppService requestUrl:@"/device_lock/reset_device_number" params:@{@"code":weakself.code, @"newNumber":number} success:^(NSDictionary * _Nonnull dict) {
                [weakself reset:nil];
                [PIUODJNLockStatusManager.main reWriteLockInfo:number ForKey:@"number"];
                if (weakself.pswBlock) {
                    weakself.pswBlock(number);
                }
                for (UIViewController *vc in self.navigationController.viewControllers) {
                    if ([vc isKindOfClass:WOPMKDIOFZTLockVC.class]) {
                        [self.navigationController popToViewController:vc animated:YES];
                        break;
                    }
                }
            } error:^(int errCode, NSString * _Nonnull message) {
                [weakself reset:nil];
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
        }];
    }else if (self.type == 4 || self.type == 5) { // window启动时判断是否开启了安全锁，如果开启了(需要验证数字密码方可进入)
        [self singleVerification:sender.tag success:^{
            if (weakself.pswBlock) {
                weakself.pswBlock(@"OK");
            }
            [weakself reset:nil];
        }];
    }else if (self.type == 6) { // 进入后台时间大于设置的时间，弹出安全锁进行验证。。跟4 和 5一样，些许不同
        [self singleVerification:sender.tag success:^{
            if (weakself.pswBlock) {
                weakself.pswBlock(@"OK");
            }
            [self.navigationController popViewControllerAnimated:NO];
            [weakself reset:nil];
        }];
    }
    
    
    
}
#pragma mark - 验证数字密码。输入1次 跟服务器的值进行对比

- (void)singleVerification:(NSInteger)num success:(void(^)(void))successBlock {
    WS(weakself)
    [_firstDatas addObject:@(num)];
    if (_firstDatas.count >= 4) { // 可以跟服务器的值进行对比、如果是正确的、就直接返回
        self.currentIndex = 3;
        self.bgView.userInteractionEnabled = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            weakself.bgView.userInteractionEnabled = YES;
            self.currentIndex = -1;
            
            NSString *first = [weakself.firstDatas componentsJoinedByString:@""];
            if (![PIUODJNLockStatusManager.main.lockStatus.number isEqualToString:first]) {
                [weakself.firstDatas removeAllObjects];
                weakself.titleLabel.text = (self->_isChinese ? @"密码错误，请重新输入..." : @"Password is wrong, please re-enter...");
                weakself.titleLabel.textColor = UIColor.systemRedColor;
                [weakself shakeLabel:weakself.titleLabel];
                return;
            }
            // 验证通过、
            if (successBlock) {
                successBlock();
            }
        });
    }else {
        self.currentIndex = _firstDatas.count - 1;
    }
}


#pragma mark - 输入两次密码 进行对比两次是否相同

- (void)doubleSetup:(NSInteger)num success:(void(^)(NSString *number))successBlock {
    WS(weakself)
    if (_secondDatas.count >= 4) {
        return;
    }
    if (_group == 0) {
        [_firstDatas addObject:@(num)];
        if (_firstDatas.count >= 4) {
            _group = 1; // first已经存了4个数字、可以存下一组密码了
            self.currentIndex = 3;
            self.bgView.userInteractionEnabled = NO;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                weakself.bgView.userInteractionEnabled = YES;
                weakself.currentIndex = -1;
                weakself.titleLabel.text = self->_isChinese ? @"再次输入" : @"Enter it again";
            });
        }else {
            self.currentIndex = _firstDatas.count - 1;
        }
    }else {
        if (_resetButton.hidden) {
            _resetButton.hidden = NO;
        }
        [_secondDatas addObject:@(num)];
        if (_secondDatas.count >= 4) {
            self.currentIndex = 3;
            self.bgView.userInteractionEnabled = NO;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                weakself.bgView.userInteractionEnabled = YES;
                weakself.currentIndex = -1;
                
                NSString *first = [weakself.firstDatas componentsJoinedByString:@""];
                NSString *second = [weakself.secondDatas componentsJoinedByString:@""];
                if (![first isEqualToString:second]) {
                    self->_group = 1;
                    [weakself.secondDatas removeAllObjects];
                    weakself.titleLabel.text = (self->_isChinese ? @"与首次输入不一致，请重新输入" : @"Inconsistent with the first input, please re-enter");
                    weakself.titleLabel.textColor = UIColor.systemRedColor;
                    [weakself shakeLabel:weakself.titleLabel];
                    return;
                }
                // 两次输入的密码相同。可以请求接口将数字密码传给服务器
                if (successBlock) {
                    successBlock(first);
                }
            });
        }else {
            self.currentIndex = _secondDatas.count - 1;
        }
    }
}


- (void)shakeLabel:(UILabel *)label {
    [label.layer removeAllAnimations];
    
    CAKeyframeAnimation *kfa = [[CAKeyframeAnimation alloc] init];
    kfa.keyPath = @"transform.translation.x";
    kfa.values = @[@(-16.0), @(0.0), @(16.0), @(0.0), @(-16.0), @(0.0), @(16.0), @(0.0)];
    kfa.duration = 0.1;
    kfa.repeatCount = 2.0;
    [label.layer addAnimation:kfa forKey:@"shake"];
}


- (void)setCurrentIndex:(NSInteger)currentIndex {
    _currentIndex = currentIndex;
    
    if (_currentIndex == -1) {
        for (UIButton *btn in _pswBtns) {
            btn.selected = NO;
        }
        _deleteButton.hidden = YES;
    }else {
        _pswBtns[_currentIndex].selected = YES;
        _deleteButton.hidden = NO;
    }
}

- (IBAction)delete:(UIButton *)sender {
    if (_group == 0) {
        if (_currentIndex >= 0) {
            _pswBtns[_currentIndex].selected = NO;
            [_firstDatas removeLastObject];
            _currentIndex = _currentIndex - 1;
        }
    }else {
        if (_currentIndex >= 0) {
            _pswBtns[_currentIndex].selected = NO;
            [_secondDatas removeLastObject];
            _currentIndex = _currentIndex - 1;
        }
    }
    if (_currentIndex < 0) {
        _deleteButton.hidden = YES;
    }
}

- (void)setIsReset:(BOOL)isReset {
    _isReset = isReset;
    if (_isReset) {
        self.navigationItem.title = _isChinese ? @"设置数字密码" : @"Set a digital password";
        self.titleLabel.text = _isChinese ? @"输入数字密码" : @"Enter digital code";
    }
}

- (IBAction)reset:(UIButton *)sender {
    _group = 0;
    self.currentIndex = -1;
    [self naviTitle];
    [_firstDatas removeAllObjects];
    [_secondDatas removeAllObjects];
    _isReset = NO;
    
    _resetButton.hidden = YES;
}




#pragma mark - 以下方法仅type=4 或者 5时 或者 6 才会触发

- (void)switchAccount { // 切换账号
    if (self.type == 4) {
        if (self.pswBlock) {
            self.pswBlock(@"ACCOUNT");
        }
    }else if (self.type == 5) {
        [self.navigationController popViewControllerAnimated:NO];
    }else if (self.type == 6) { // 进登录界面
        [self.navigationController popViewControllerAnimated:NO];
        if (self.pswBlock) {
            self.pswBlock(@"ACCOUNT");
        }
    }
}

- (IBAction)forget:(UIButton *)sender { // 忘记数字密码
    WOPMKDIOFZTClearChatVC *vc = WOPMKDIOFZTClearChatVC.new;
    vc.type = self.type;
    WS(weakself)
    [vc setClearBlock:^{ // type 5 不会走这儿
        if (weakself.pswBlock) {
            weakself.pswBlock(@"FORGET");
        }
    }];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
