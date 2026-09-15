//
//  YUBWOIJWDGroupIconVC.m
//  WUHOIBDK
//
//  Created by Ruby on 12/12/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "YUBWOIJWDGroupIconVC.h"

#import "WOPMKDIOFZTTextModifyVC.h"


@interface YUBWOIJWDGroupIconVC ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *groupIconView;
@property (weak, nonatomic) IBOutlet UILabel *grouptzboeuNameLabel;

@property (nonatomic, strong) WFCCGroupInfo *groupInfo;

@property (weak, nonatomic) IBOutlet UILabel *yzdoajGroupIconL;
@property (weak, nonatomic) IBOutlet UILabel *yzdoajGroupNameL;

@end

@implementation YUBWOIJWDGroupIconVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = LLLLLL(@"ModifyGroupData");
    
    _groupIconView.layer.cornerRadius = 20.0;
    
    _groupInfo = [[WFCCGroupDB sharedManager] getGroupInfoFromDB:_conversation.target];
    
    _grouptzboeuNameLabel.text = (_groupInfo.displayName.length > 0 ? _groupInfo.displayName : _groupInfo.remark);
    [_groupIconView sd_setImageWithURL:URL(_groupInfo.portrait) placeholderImage:IMAGENAME(@"groupIcon") options:SDWebImageScaleDownLargeImages
                               context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    
    _yzdoajGroupIconL.text = LLLLLL(@"GroupAvatar");
    _yzdoajGroupNameL.text = LLLLLL(@"GroupName");
}

- (IBAction)groupName:(UIButton *)sender {
    WOPMKDIOFZTTextModifyVC *vc = WOPMKDIOFZTTextModifyVC.new;
    vc.modifyType = 102;
    vc.defaultValue = _grouptzboeuNameLabel.text;
    vc.groupId = _conversation.target;
    WS(weakself)
    [vc setOnModified:^(NSString * _Nonnull value) {
        weakself.grouptzboeuNameLabel.text = value;
    }];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)groupIcon:(UIButton *)sender {
    WS(weakself)
    [CommonHelper.main showImagePikerWithimageBlock:^(UIImage * _Nonnull image) {
        [weakself uploadPortrait:image];
    }];
}
- (void)uploadPortrait:(UIImage *)portraitImage {
    NSData *portraitData = UIImageJPEGRepresentation(portraitImage, 0.7);
    __weak typeof(self) ws = self;
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"Uploading");
    [hud showAnimated:YES];
    
    [[SRIMService sharedSRIMService] uploadFile:[NSString stringWithFormat:@"group_%@.png",_groupInfo.target]
                                           data:portraitData
                                       mimeType:@"image/png"
                                        success:^(NSString * _Nonnull remoteUrl) {
        
        [[AppService sharedAppService] groupUpdate:@{@"gid": ws.groupInfo.target, @"portrait":remoteUrl} success:^{
            [hud hideAnimated:YES];
            ws.groupInfo.portrait = remoteUrl;
            [[WFCCGroupDB sharedManager] insertOrUpdateGroupInfo:ws.groupInfo];
            [[NSNotificationCenter defaultCenter] postNotificationName:kGroupInfoUpdated object:nil];
            [ws.groupIconView sd_setImageWithURL:URL(remoteUrl) placeholderImage:IMAGENAME(@"groupIcon") options:SDWebImageScaleDownLargeImages
                                       context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];

        } error:^(int errCode, NSString * _Nonnull message) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];
                hud = [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
                hud.mode = MBProgressHUDModeText;
                hud.label.text = LLLLLL(@"UploadFailure");
                hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                [hud hideAnimated:YES afterDelay:1.f];
            });
        }];
        
    } progress:^(long uploaded, long total) {
        
    } fail:^(int error_code, NSString * _Nonnull message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            hud = [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.label.text = LLLLLL(@"UploadFailure");
            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [hud hideAnimated:YES afterDelay:1.f];
        });
    }];
    
//    [[WFCCIMService sharedWFCIMService] uploadMedia:nil mediaData:portraitData mediaType:Media_Type_PORTRAIT success:^(NSString *remoteUrl) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [[WFCCIMService sharedWFCIMService] modifyGroupInfo:ws.conversation.target type:Modify_Group_Portrait newValue:remoteUrl notifyLines:@[@(0)] notifyContent:nil success:^{
//                [hud hideAnimated:YES];
//                
//                ws.groupIconView.image = portraitImage;
//            } error:^(int error_code) {
//            }];
//        });
//    } progress:^(long uploaded, long total) {
//        
//    } error:^(int error_code) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [hud hideAnimated:YES];
//            hud = [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
//            hud.mode = MBProgressHUDModeText;
//            hud.label.text = LLLLLL(@"UploadFailure");
//            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
//            [hud hideAnimated:YES afterDelay:1.f];
//        });
//    }];
}

@end
