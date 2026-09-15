//
//  WOPMKDIOFZTUserQrcodeVC.m
//  WUHOIBDK
//
//  Created by Loooooo on 7/22/24.
//

#import "WOPMKDIOFZTUserQrcodeVC.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface WOPMKDIOFZTUserQrcodeVC ()
{
    NSString *_qrStr;
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIView *waxiouvBgV;

@property (weak, nonatomic) IBOutlet UIImageView *waxiouvIconV;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvNameL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvIdL;

@property (weak, nonatomic) IBOutlet UIImageView *waxiouvQrImgV;
@property (weak, nonatomic) IBOutlet UIImageView *waxiouvQrIconV;

@property (weak, nonatomic) IBOutlet UILabel *waxiouvAddFirendL;
@property (weak, nonatomic) IBOutlet UIImageView *waxiouvLogoV;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvExpirationL;

@property (weak, nonatomic) IBOutlet UIButton *waxiouvRefreshBtn;

@property (weak, nonatomic) IBOutlet UILabel *waxiouvSkanL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvShareL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvDownloadL;

@property (nonatomic, strong) WFCCUserInfo *userInfo;

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@end

@implementation WOPMKDIOFZTUserQrcodeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [CommonHelper.main isChinese];
    self.navigationItem.title = _isChinese ? @"二维码" : @"QR code";
 
    _waxiouvIconV.layer.cornerRadius = 30.0;
    _waxiouvQrIconV.hidden = YES;
    _waxiouvQrIconV.layer.cornerRadius = 26.0;
    _waxiouvLogoV.layer.cornerRadius = 10.0;
    if (_isChinese) {
    }else {
        _waxiouvAddFirendL.text = @"Sweep\nAdd me as a friend";
        [_waxiouvRefreshBtn setTitle:@"Click to refresh" forState:UIControlStateNormal];
        
        _waxiouvSkanL.text = @"Sweep";
        _waxiouvShareL.text = @"Share it";
        _waxiouvDownloadL.text = @"Save picture";
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    self.userInfo = [[AppCache sharedAppCache] getMyInfo];
    [self waxiouvRefreshTime];
}

- (void)waxiouvRefreshTime {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    NSDateFormatter *waxiouvFormatter = NSDateFormatter.new;
    waxiouvFormatter.dateFormat = @"yyyy/MM/dd HH:mm";
    
    NSString *waxiouvExpiration = @"";
    NSDate *waxiouvDate = [NSDate.date dateByAddingTimeInterval:60*60];
    if (_isChinese) {
        waxiouvExpiration = UNString(@"有效期至%@", [waxiouvFormatter stringFromDate:waxiouvDate]);
    }else {
        waxiouvExpiration = UNString(@"Valid until %@", [waxiouvFormatter stringFromDate:waxiouvDate]);
    }
    if ([waxiouvExpiration isEqualToString:_waxiouvExpirationL.text]) {
        return;
    }
    _waxiouvExpirationL.text = waxiouvExpiration;
    
    NSInteger waxiouvTimeInterval = (NSInteger)[waxiouvDate timeIntervalSince1970];
    
    _qrStr = [NSString stringWithFormat:@"wildfirechat://user/%@####%ld", userId, waxiouvTimeInterval];
    WS(weakself)
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
//            UIImage *waxiouvQrImg = [LBXScanNative logolOrQRImage:self->_qrStr logolImage:weakself.waxiouvIconV.image];
            weakself.waxiouvQrIconV.hidden = NO;
            UIImage *waxiouvQrImg = [LBXScanNative logolOrQRImage:self->_qrStr logolImage:nil];
            weakself.waxiouvQrImgV.image = waxiouvQrImg;
        });
    });
}

- (void)setUserInfo:(WFCCUserInfo *)userInfo {
    _userInfo = userInfo;
    UIImage *placeholder = [UIImage imageNamed:@"PersonalChat"];
    __weak typeof(self) weakSelf = self;
    [_waxiouvIconV sd_setImageWithURL:URL(_userInfo.portrait)
                     placeholderImage:placeholder
                              options:SDWebImageScaleDownLargeImages
                            completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        (void)error;
        (void)cacheType;
        (void)imageURL;
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf.waxiouvQrIconV.image = image ?: placeholder;
    }];

    _waxiouvNameL.text = _userInfo.displayName;
    _waxiouvIdL.text = _userInfo.name;
}

- (IBAction)waxiouvScanShareDownloads:(UIButton *)sender {
    if (sender.tag == 0) {
        if (gQrCodeDelegate) { // 走的delegate方法
            [gQrCodeDelegate scanQrCode:self.navigationController];
        }
    }else {
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] init];
        indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
        indicator.center = self.view.center;
        _indicatorView = indicator;
        [[UIApplication sharedApplication].keyWindow addSubview:indicator];
        [indicator startAnimating];
        
        UIImage *image = [self shotShareImageFromView:self.waxiouvBgV];
        if (sender.tag == 1) {
            [_indicatorView removeFromSuperview];
            UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:@[image] applicationActivities:nil];
            [self presentViewController:avc animated:YES completion:nil];
        }else {
            UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
        }
    }
}



- (IBAction)waxiouvCopy:(UIButton *)sender {
    if (_waxiouvIdL.text.length <= 0) {
        return;
    }
    UIPasteboard *pasteboard = UIPasteboard.generalPasteboard;
    pasteboard.string = _waxiouvIdL.text;
    [SVProgressHUD showSuccessWithStatus:LLLLLL(@"CopySuccessfully")];
    [SVProgressHUD dismissWithDelay:1.0];
}

- (IBAction)waxiouvRefresh:(UIButton *)sender {
    [self waxiouvRefreshTime];
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

/** 1、截取屏幕上指定view的内容 */
- (UIImage *)shotShareImageFromView:(UIView *)view {
    //高清方法
    //第一个参数表示区域大小 第二个参数表示是否是非透明的。如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了
    CGSize size = CGSizeMake(view.layer.bounds.size.width, view.layer.bounds.size.height);
    UIGraphicsBeginImageContextWithOptions(size, YES, ([UIScreen mainScreen].scale));
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    [_indicatorView removeFromSuperview];

    if (error) {
        [SVProgressHUD showErrorWithStatus:LLLLLL(@"SaveFailure")];
        [SVProgressHUD dismissWithDelay:1.0];
    } else {
        [SVProgressHUD showSuccessWithStatus:LLLLLL(@"SaveSuccessfully")];
        [SVProgressHUD dismissWithDelay:1.0];
    }
}


@end
