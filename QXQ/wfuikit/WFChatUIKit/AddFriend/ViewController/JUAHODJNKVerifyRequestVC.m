//
//  JUAHODJNKVerifyRequestVC.m
//  WFChatUIKit
//
//  Created by WF Chat on 2018/11/4.
//  Copyright © 2018 WF Chat. All rights reserved.
//

#import "JUAHODJNKVerifyRequestVC.h"
#import <WFChatClient/WFCChatClient.h>
#import "MBProgressHUD.h"
#import "AIOIUEHConfigManager.h"
#import "AIOIUEHUtilities.h"

@interface JUAHODJNKVerifyRequestVC ()
@property(nonatomic, strong)UITextField *verifyField;
@end

@implementation JUAHODJNKVerifyRequestVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    CGRect clientArea = self.view.bounds;
    UILabel *hintLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 8 + [AIOIUEHUtilities wf_navigationFullHeight], clientArea.size.width - 16, 16)];
    hintLabel.text = WFCString(@"AddFriendReasonHint");
    hintLabel.font = [UIFont systemFontOfSize:12];
    hintLabel.textColor = [UIColor grayColor];
    [self.view addSubview:hintLabel];
    self.view.backgroundColor = [AIOIUEHConfigManager globalManager].backgroudColor;
    
    self.verifyField = [[UITextField alloc] initWithFrame:CGRectMake(0, 32 + [AIOIUEHUtilities wf_navigationFullHeight], clientArea.size.width, 32)];
    WFCCUserInfo *me = [[WFCCUserDB sharedManager] getUserInfo:[WFCCNetworkService sharedInstance].userId];
    self.verifyField.font = [UIFont systemFontOfSize:16];
    if(me.displayName){
        self.verifyField.text = [NSString stringWithFormat:WFCString(@"DefaultAddFriendReason"), me.displayName];
    }else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if(!self.verifyField.text) {
                WFCCUserInfo *me = [[WFCCUserDB sharedManager] getUserInfo:[WFCCNetworkService sharedInstance].userId];
                if (me.displayName) {
                    self.verifyField.text = [NSString stringWithFormat:WFCString(@"DefaultAddFriendReason"), me.displayName];
                } else {
                    self.verifyField.text = WFCString(@"DefaultAddFriendReason");
                }
            }
        });
    }
    self.verifyField.borderStyle = UITextBorderStyleRoundedRect;
    self.verifyField.clearButtonMode = UITextFieldViewModeAlways;
    
    
    [self.view addSubview:self.verifyField];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Send") style:UIBarButtonItemStyleDone target:self action:@selector(onSend:)];
}


- (void)onSend:(id)sender {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = WFCString(@"Sending");
    [hud showAnimated:YES];
    
    NSString *extraStr = nil;
//    if(self.sourceType) {
//        NSMutableDictionary *sourceDict = [[NSMutableDictionary alloc] init];
//        [sourceDict setValue:@(self.sourceType) forKey:@"t"/*type*/];
//        [sourceDict setValue:self.sourceTargetId forKey:@"i"/*targetId*/];
//        NSDictionary *extraDict = @{@"s"/*source*/:sourceDict};
//        
//        NSData *extraData = [NSJSONSerialization dataWithJSONObject:extraDict
//                                                                               options:kNilOptions
//                                                                                 error:nil];
//        extraStr = [[NSString alloc] initWithData:extraData encoding:NSUTF8StringEncoding];
//    }
    
    __weak typeof(self) ws = self;
    [[WFCCIMService sharedWFCIMService] sendFriendRequest:self.userId reason:self.verifyField.text extra:extraStr success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.label.text = WFCString(@"Sent");
            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [hud hideAnimated:YES afterDelay:1.f];
            [ws.navigationController popViewControllerAnimated:YES];
        });
    } error:^(int error_code) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            if(error_code == 16) {
                hud.label.text = WFCString(@"AlreadySentFriendRequest");
            } else if(error_code == 18) {
                hud.label.text = WFCString(@"FriendRequestRejected");
            } else {
                hud.label.text = WFCString(@"SendFailure");
            }
            
            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [hud hideAnimated:YES afterDelay:1.f];
        });
    }];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
