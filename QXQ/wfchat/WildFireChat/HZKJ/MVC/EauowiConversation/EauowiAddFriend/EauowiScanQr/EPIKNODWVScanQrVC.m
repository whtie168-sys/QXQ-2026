//
//  EPIKNODWVScanQrVC.m
//  WUHOIBDK
//
//  Created by Ruby on 11/30/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "EPIKNODWVScanQrVC.h"

#import "WOPMKDIOFZTNormalQrcodeVC.h"
#import "WOPMKDIOFZTUserQrcodeVC.h"


@interface EPIKNODWVScanQrVC ()
{
    BOOL _isChinese;
}
@property (nonatomic, strong) LBXScanVideoZoomView *zoomView;

@end

@implementation EPIKNODWVScanQrVC

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.subviews[0].alpha = 0.0;
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.subviews[0].alpha = 1.0;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    _isChinese = [CommonHelper.main isChinese];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:IMAGENAME(@"view_close") style:UIBarButtonItemStyleDone target:self action:@selector(view_close)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"Album") style:UIBarButtonItemStyleDone target:self action:@selector(openPhoto)];

//    UIButton *rightButton = [self itemImage:@"" action:@selector(openPhoto)];
//    rightButton.titleLabel.font = PINGFANG_M(16.0);
//    [rightButton setTitle:LLLLLL(@"Album") forState:UIControlStateNormal];
//    [rightButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightButton];
//    
//    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100.0, 30.0)];
//    titleLabel.text = LLLLLL(@"Scanning");
//    titleLabel.textColor = UIColor.whiteColor;
//    titleLabel.font = PINGFANG_M(18.0);
//    titleLabel.textAlignment = NSTextAlignmentCenter;
//    self.navigationItem.titleView = titleLabel;
    self.title = LLLLLL(@"Scanning");

    
    //设置扫码后需要扫码图像
    self.isNeedScanImage = YES;
    
    self.style.colorAngle = RGBA(0x82DF67);
    self.style.anmiationStyle = LBXScanViewAnimationStyle_LineMove;
}
- (UIButton *)itemImage:(NSString *)img action:(SEL)action {
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    rightButton.frame = CGRectMake(0, 0, 30.0, 30.0);
    rightButton.backgroundColor = UIColor.clearColor;
    [rightButton setImage:IMAGENAME(img) forState:UIControlStateNormal];
    [rightButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    rightButton.adjustsImageWhenHighlighted = NO;
    return rightButton;
}
- (void)view_close {
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self drawBottomItems];
    [self drawTitle];
    [self.view bringSubviewToFront:_topTitle];
}

//绘制扫描区域
- (void)drawTitle {
    if (!_topTitle) {
        self.topTitle = [[UILabel alloc] init];
        _topTitle.frame = CGRectMake(0.0, NavigationHeight + 52.0, WIDTH, 60);
        
        //3.5inch iphone
        if ([UIScreen mainScreen].bounds.size.height <= 568) {
            _topTitle.center = CGPointMake(CGRectGetWidth(self.view.frame)/2, 38);
            _topTitle.font = [UIFont systemFontOfSize:14];
        }
        
        _topTitle.textAlignment = NSTextAlignmentCenter;
        _topTitle.numberOfLines = 0;
        _topTitle.text = (_isChinese?@"请将镜头对准地址二维码进行扫描":@"Please align the lens with the address QR code for scanning");
        _topTitle.textColor = [UIColor whiteColor];
        [self.view addSubview:_topTitle];
    }
}

- (void)cameraInitOver {
    if (self.isVideoZoom) {
        [self zoomView];
    }
}

- (LBXScanVideoZoomView*)zoomView {
    if (!_zoomView) {
      
        CGRect frame = self.view.frame;
        
        int XRetangleLeft = self.style.xScanRetangleOffset;
        
        CGSize sizeRetangle = CGSizeMake(frame.size.width - XRetangleLeft*2, frame.size.width - XRetangleLeft*2);
        
        if (self.style.whRatio != 1) {
            CGFloat w = sizeRetangle.width;
            CGFloat h = w / self.style.whRatio;
            
            NSInteger hInt = (NSInteger)h;
            h  = hInt;
            
            sizeRetangle = CGSizeMake(w, h);
        }
        
        CGFloat videoMaxScale = [self.scanObj getVideoMaxScale];
        
        //扫码区域Y轴最小坐标
        CGFloat YMinRetangle = frame.size.height / 2.0 - sizeRetangle.height/2.0 - self.style.centerUpOffset;
        CGFloat YMaxRetangle = YMinRetangle + sizeRetangle.height;
        
        CGFloat zoomw = sizeRetangle.width + 40;
        _zoomView = [[LBXScanVideoZoomView alloc]initWithFrame:CGRectMake((CGRectGetWidth(self.view.frame)-zoomw)/2, YMaxRetangle + 40, zoomw, 18)];
        
        [_zoomView setMaximunValue:videoMaxScale/4];
        
        
        __weak __typeof(self) weakSelf = self;
        _zoomView.block= ^(float value) {
            [weakSelf.scanObj setVideoScale:value];
        };
        [self.view addSubview:_zoomView];
                
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tap)];
        [self.view addGestureRecognizer:tap];
    }
    return _zoomView;
}

- (void)tap {
    _zoomView.hidden = !_zoomView.hidden;
}

- (void)drawBottomItems {
    if (_bottomItemsView) {
        return;
    }
    
    self.bottomItemsView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.view.bounds)-132 - [AIOIUEHUtilities wf_safeDistanceBottom],
                                                                      CGRectGetWidth(self.view.frame), 100)];
    _bottomItemsView.backgroundColor = UIColor.clearColor;
    
    [self.view addSubview:_bottomItemsView];
    
    CGSize size = CGSizeMake(65, 87);
    self.btnFlash = [[UIButton alloc]init];
    _btnFlash.bounds = CGRectMake(0, 0, size.width, size.height); // 闪光灯
    _btnFlash.center = CGPointMake(CGRectGetWidth(_bottomItemsView.frame)/2, CGRectGetHeight(_bottomItemsView.frame)/2);
    _btnFlash.center = CGPointMake(CGRectGetWidth(_bottomItemsView.frame)/4, CGRectGetHeight(_bottomItemsView.frame)/2);
    [_btnFlash setImage:[UIImage imageNamed:(_isChinese?@"qrcode_scan_btn_flash_nor":@"qrcode_scan_btn_flash_nor_E")] forState:UIControlStateNormal];
    [_btnFlash addTarget:self action:@selector(openOrCloseFlash) forControlEvents:UIControlEventTouchUpInside];
    
//    self.btnPhoto = [[UIButton alloc]init];
//    _btnPhoto.bounds = _btnFlash.bounds;  // 相册
//    _btnPhoto.center = CGPointMake(CGRectGetWidth(_bottomItemsView.frame)/4, CGRectGetHeight(_bottomItemsView.frame)/2);
//    [_btnPhoto setImage:[UIImage imageNamed:@"qrcode_scan_btn_photo_nor"] forState:UIControlStateNormal];
//    [_btnPhoto setImage:[UIImage imageNamed:@"qrcode_scan_btn_photo_down"] forState:UIControlStateHighlighted];
//    [_btnPhoto addTarget:self action:@selector(openPhoto) forControlEvents:UIControlEventTouchUpInside];
    
    self.btnMyQR = [[UIButton alloc]init];
    _btnMyQR.bounds = _btnFlash.bounds; // 我的二维码
    _btnMyQR.center = CGPointMake(CGRectGetWidth(_bottomItemsView.frame) * 3/4, CGRectGetHeight(_bottomItemsView.frame)/2);
    [_btnMyQR setImage:[UIImage imageNamed:(_isChinese?@"qrcode_scan_btn_myqrcode_nor":@"qrcode_scan_btn_myqrcode_nor_E")] forState:UIControlStateNormal];
    [_btnMyQR setImage:[UIImage imageNamed:(_isChinese?@"qrcode_scan_btn_myqrcode_down":@"qrcode_scan_btn_myqrcode_down_E")] forState:UIControlStateHighlighted];
    [_btnMyQR addTarget:self action:@selector(myQRCode) forControlEvents:UIControlEventTouchUpInside];
    
    [_bottomItemsView addSubview:_btnFlash];
//    [_bottomItemsView addSubview:_btnPhoto];
    [_bottomItemsView addSubview:_btnMyQR];
}

- (void)showError:(NSString*)str {
    [LBXAlertAction showAlertWithTitle:LLLLLL(@"Tips") msg:str buttonsStatement:@[LLLLLL(@"iGotIt")] chooseBlock:nil];
}

- (void)scanResultWithArray:(NSArray<LBXScanResult*>*)array {
    if (array.count < 1) {
        [self popAlertMsgWithScanResult:nil];
     
        return;
    }
    
    //经测试，可以同时识别2个二维码，不能同时识别二维码和条形码
    for (LBXScanResult *result in array) {
        NSLog(@"scanResult:%@",result.strScanned);
    }
    
    LBXScanResult *scanResult = array[0];
    
    NSString *strResult = scanResult.strScanned;
    
    self.scanImage = scanResult.imgScanned;
    
    if (!strResult) {
        [self popAlertMsgWithScanResult:nil];
        return;
    }
    
    //震动提醒
   // [LBXScanWrapper systemVibrate];
    //声音提醒
    //[LBXScanWrapper systemSound];
    
    [self showNextVCWithScanResult:scanResult];
}

- (void)popAlertMsgWithScanResult:(NSString*)strResult {
    if (!strResult) {
        strResult = _isChinese?@"识别失败":@"Recognition failure";
    }
    
    __weak __typeof(self) weakSelf = self;
    [LBXAlertAction showAlertWithTitle:(_isChinese?@"扫码内容":@"Scanning content") msg:strResult buttonsStatement:@[LLLLLL(@"iGotIt")] chooseBlock:^(NSInteger buttonIdx) {
        [weakSelf reStartDevice];
    }];
}

- (void)showNextVCWithScanResult:(LBXScanResult*)strResult {
    [self.navigationController popViewControllerAnimated:NO];
    self.scanResult(strResult.strScanned);
}


#pragma mark -底部功能项
//打开相册
- (void)openPhoto {
    __weak __typeof(self) weakSelf = self;
    [LBXPermission authorizeWithType:LBXPermissionType_Photos completion:^(BOOL granted, BOOL firstTime) {
        if (granted) {
            [weakSelf openLocalPhoto:NO];
        }else if (!firstTime){
            [LBXPermissionSetting showAlertToDislayPrivacySettingWithTitle:LLLLLL(@"Tips") msg:(self->_isChinese?@"没有相册权限，是否前往设置":@"No album permissions, whether to go to Settings.") cancel:LLLLLL(@"Cancel") setting:LLLLLL(@"Settings")];
        }
    }];
}

//开关闪光灯
- (void)openOrCloseFlash {
    [super openOrCloseFlash];
   
    if (self.isOpenFlash) {
        [_btnFlash setImage:[UIImage imageNamed:(_isChinese?@"qrcode_scan_btn_flash_down":@"qrcode_scan_btn_flash_down_E")] forState:UIControlStateNormal];
    }
    else
        [_btnFlash setImage:[UIImage imageNamed:(_isChinese?@"qrcode_scan_btn_flash_nor":@"qrcode_scan_btn_flash_nor_E")] forState:UIControlStateNormal];
}


#pragma mark -底部功能项


- (void)myQRCode {
    WOPMKDIOFZTUserQrcodeVC *vc = WOPMKDIOFZTUserQrcodeVC.new;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
    
//    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
//    WOPMKDIOFZTNormalQrcodeVC *vc = WOPMKDIOFZTNormalQrcodeVC.new;
//    vc.qrType = QRType_User;
//    vc.target = userId;;
//    [self.navigationController pushViewController:vc animated:YES];
}

@end
