//
//  LUDHIOWIVChannelProfileVC.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/22.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "LUDHIOWIVChannelProfileVC.h"
#import <SDWebImage/SDWebImage.h>
#import <WFChatClient/WFCChatClient.h>
#import "AIOIUEHMessageListVC.h"
#import "MBProgressHUD.h"
#import "UIView+Toast.h"
#import "AIOIUEHUtilities.h"
#import "AIOIUEHImage.h"

@interface LUDHIOWIVChannelProfileVC () <UIActionSheetDelegate>
@property (nonatomic, strong)UIImageView *channelPortrait;
@property (nonatomic, strong)UILabel *channelName;
@property (nonatomic, strong)UILabel *channelDesc;
@end

@implementation LUDHIOWIVChannelProfileVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"..." style:UIBarButtonItemStyleDone target:self action:@selector(onRightBtn:)];
    
    
    CGFloat portraitWidth = 80;
    CGFloat top = [AIOIUEHUtilities wf_navigationFullHeight] + 40;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    
    self.channelPortrait = [[UIImageView alloc] initWithFrame:CGRectMake((screenWidth - portraitWidth)/2, top, portraitWidth, portraitWidth)];
    [self.channelPortrait sd_setImageWithURL:[NSURL URLWithString:[self.channelInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[AIOIUEHImage imageNamed:@"channel_default_portrait"] options:SDWebImageScaleDownLargeImages
                                     context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    
    top += portraitWidth;
    top += 20;
    self.channelName = [[UILabel alloc] initWithFrame:CGRectMake(40, top, screenWidth - 40 - 40, 18)];
    self.channelName.font = [UIFont systemFontOfSize:18];
    self.channelName.textAlignment = NSTextAlignmentCenter;
    self.channelName.text = self.channelInfo.name;
    
    
    top += 18;
    top += 20;
    
    NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:self.channelInfo.desc];
    UIFont *font = [UIFont systemFontOfSize:14];
    [attributeString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, self.channelInfo.desc.length)];
    NSStringDrawingOptions options = NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading;
    CGRect rect = [attributeString boundingRectWithSize:CGSizeMake(screenWidth - 80, CGFLOAT_MAX) options:options context:nil];
    
    self.channelDesc = [[UILabel alloc] initWithFrame:CGRectMake(40, top, screenWidth - 80, rect.size.height)];
    self.channelDesc.font = [UIFont systemFontOfSize:14];
    self.channelDesc.textAlignment = NSTextAlignmentCenter;
    self.channelDesc.text = self.channelInfo.desc;
    self.channelDesc.numberOfLines = 0;
    [self.channelDesc sizeToFit];
    
    
    top += rect.size.height;
    top += 20;
    
    [self.view addSubview:self.channelPortrait];
    [self.view addSubview:self.channelName];
    [self.view addSubview:self.channelDesc];
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    
    if(![userId isEqualToString:self.channelInfo.owner]) {
        UIButton *btn;
        if ([[WFCCIMService sharedWFCIMService] isListenedChannel:self.channelInfo.channelId]) {
            btn = [[UIButton alloc] initWithFrame:CGRectMake(20, self.view.frame.size.height - [AIOIUEHUtilities wf_safeDistanceBottom] - 40 - 16, screenWidth - 40, 40)];
            [btn setTitle:WFCString(@"SendMessage") forState:UIControlStateNormal];
            [btn setBackgroundColor:[UIColor greenColor]];
            [btn addTarget:self action:@selector(onSendMessageBtn:) forControlEvents:UIControlEventTouchDown];
        } else  {
            btn = [[UIButton alloc] initWithFrame:CGRectMake(20, self.view.frame.size.height - [AIOIUEHUtilities wf_safeDistanceBottom] - 40 - 16, screenWidth - 40, 40)];
            [btn setTitle:WFCString(@"SubscribeChannel") forState:UIControlStateNormal];
            [btn setBackgroundColor:[UIColor greenColor]];
            [btn addTarget:self action:@selector(onSubscribeBtn:) forControlEvents:UIControlEventTouchDown];
        }

        btn.layer.cornerRadius = 5.f;
        btn.layer.masksToBounds = YES;
        [self.view addSubview:btn];
    } else {
        self.channelPortrait.userInteractionEnabled = YES;
        [self.channelPortrait addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(modifyChannelPortrait)]];
        
        self.channelName.userInteractionEnabled = YES;
        [self.channelName addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(modifyChannelName)]];
        
        self.channelDesc.userInteractionEnabled = YES;
        [self.channelDesc addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(modifyChannelDesc)]];
    }
}

- (void)onRightBtn:(id)sender {
    NSString *title;
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    if ([self.channelInfo.owner isEqualToString:userId]) {
        title = WFCString(@"DestroyChannel");
    } else if ([[WFCCIMService sharedWFCIMService] isListenedChannel:self.channelInfo.channelId]) {
        title = WFCString(@"UnscribeChannel");
    } else {
        title = WFCString(@"SubscribeChannel");
    }
    
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:WFCString(@"Cancel") destructiveButtonTitle:title otherButtonTitles:nil, nil];
    [actionSheet showInView:self.view];
}

- (void)onSendMessageBtn:(id)sender {
    AIOIUEHMessageListVC *mvc = [[AIOIUEHMessageListVC alloc] init];
    mvc.conversation = [WFCCConversation conversationWithType:Channel_Type target:self.channelInfo.channelId line:0];
    for (UIViewController *vc in self.navigationController.viewControllers) {
        if ([vc isKindOfClass:[AIOIUEHMessageListVC class]]) {
            [self.navigationController popToViewController:vc animated:YES];
            return;
        }
    }
    [self.navigationController pushViewController:mvc animated:YES];
}

- (void)onSubscribeBtn:(id)sender {
    __weak typeof(self) ws = self;
    [[WFCCIMService sharedWFCIMService] listenChannel:self.channelInfo.channelId listen:YES success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [ws.navigationController popViewControllerAnimated:YES];
        });
    } error:^(int errorCode) {
        
    }];
}

- (void)modifyChannelPortrait {
    UIActionSheet *actionSheet =
    [[UIActionSheet alloc] initWithTitle:WFCString(@"ChangePortrait")
                                delegate:self
                       cancelButtonTitle:WFCString(@"Cancel")
                  destructiveButtonTitle:WFCString(@"TakePhotos")
                       otherButtonTitles:WFCString(@"Album"), nil];
    [actionSheet showInView:self.view];
    actionSheet.tag = 1;
}

- (void)modifyChannelName {
}

- (void)modifyChannelDesc {

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -  UIActionSheetDelegate <NSObject>
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(actionSheet.tag == 0) {
        if(buttonIndex == 0) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.label.text = WFCString(@"Updating");
            [hud showAnimated:YES];
            NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
            if ([self.channelInfo.owner isEqualToString:userId]) {
                [[WFCCIMService sharedWFCIMService] destoryChannel:self.channelInfo.channelId success:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [hud hideAnimated:YES];
                        
                        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                        hud.mode = MBProgressHUDModeText;
                        hud.label.text = WFCString(@"UpdateDone");
                        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                        [hud hideAnimated:YES afterDelay:1.f];
                    });
                } error:^(int error_code) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [hud hideAnimated:YES];
                        
                        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                        hud.mode = MBProgressHUDModeText;
                        hud.label.text = WFCString(@"UpdateFailure");
                        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                        [hud hideAnimated:YES afterDelay:1.f];
                    });
                }];
            } else {
                BOOL isListen = ![[WFCCIMService sharedWFCIMService] isListenedChannel:self.channelInfo.channelId];
                [[WFCCIMService sharedWFCIMService] listenChannel:self.channelInfo.channelId listen:isListen success:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [hud hideAnimated:YES];
                        
                        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                        hud.mode = MBProgressHUDModeText;
                        hud.label.text = WFCString(@"UpdateDone");
                        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                        [hud hideAnimated:YES afterDelay:1.f];
                    });
                } error:^(int errorCode) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [hud hideAnimated:YES];
                        
                        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                        hud.mode = MBProgressHUDModeText;
                        hud.label.text = WFCString(@"UpdateFailure");
                        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                        [hud hideAnimated:YES afterDelay:1.f];
                    });
                }];
            }
        }
    } else if(actionSheet.tag == 1) {
        if(buttonIndex == 0) {
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.allowsEditing = YES;
            picker.delegate = self;
            if ([UIImagePickerController
                 isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            } else {
                NSLog(@"无法连接相机");
                picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            }
            [self presentViewController:picker animated:YES completion:nil];
            
        } else if (buttonIndex == 1) {
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.allowsEditing = YES;
            picker.delegate = self;
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            [self presentViewController:picker animated:YES completion:nil];
        }
    }
}


#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [UIApplication sharedApplication].statusBarHidden = NO;
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    if ([mediaType isEqual:@"public.image"]) {
        UIImage *originImage =
        [info objectForKey:UIImagePickerControllerEditedImage];
        //获取截取区域的图像
        UIImage *captureImage = [AIOIUEHUtilities thumbnailWithImage:originImage maxSize:CGSizeMake(60, 60)];
        [self uploadPortrait:captureImage];
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)uploadPortrait:(UIImage *)portraitImage {
    NSData *portraitData = UIImageJPEGRepresentation(portraitImage, 0.70);
    __weak typeof(self) ws = self;
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = WFCString(@"PhotoUploading");
    [hud showAnimated:YES];
    
    [[WFCCIMService sharedWFCIMService] uploadMedia:nil mediaData:portraitData mediaType:Media_Type_PORTRAIT success:^(NSString *remoteUrl) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:NO];
            if (remoteUrl.length) {
                [[WFCCIMService sharedWFCIMService] modifyChannelInfo:ws.channelInfo.channelId type:Modify_Channel_Portrait newValue:remoteUrl success:^{
                    ;
                } error:^(int error_code) {
                    [ws.view makeToast:WFCString(@"ModifyPortraitFailure")
                              duration:2
                              position:CSToastPositionCenter];
                }];
            }
        });
    }
                                           progress:^(long uploaded, long total) {
                                               
                                           }
                                              error:^(int error_code) {
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      [hud hideAnimated:NO];
                                                      hud = [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
                                                      hud.mode = MBProgressHUDModeText;
                                                      hud.label.text = WFCString(@"UploadFailure");
                                                      hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                                                      [hud hideAnimated:YES afterDelay:1.f];
                                                  });
                                              }];
}

@end
