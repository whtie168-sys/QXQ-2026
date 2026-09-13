//
//  QZBGNRJYDIOZRetrievePswdVC.m
//  WUHOIBDK
//
//  Created by Ruby on 12/26/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "QZBGNRJYDIOZRetrievePswdVC.h"
#import "QZBGNRJYDIOZMobileEmailPswdVC.h"

@interface QZBGNRJYDIOZRetrievePswdVC ()

@property (weak, nonatomic) IBOutlet UILabel *qoynruPhoneBackL;
@property (weak, nonatomic) IBOutlet UILabel *qoynruEmailBackL;

@end

@implementation QZBGNRJYDIOZRetrievePswdVC

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([CommonHelper.main isChinese]) {
        self.navigationItem.title = @"找回密码";
    }else {
        self.navigationItem.title = @"Retrieve password";
        _qoynruPhoneBackL.text = @"Phone number retrieval";
        _qoynruEmailBackL.text = @"Email retrieval";
    }
}

- (IBAction)act:(UIButton *)sender {
    QZBGNRJYDIOZMobileEmailPswdVC *vc = QZBGNRJYDIOZMobileEmailPswdVC.new;
    vc.type = sender.tag;
    [self.navigationController pushViewController:vc animated:YES];
}


@end
