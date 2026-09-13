//
//  WOPMKDIOFZTAppearanceVC.m
//  WUHOIBDK
//
//  Created by Loooooo on 8/15/24.
//

#import "WOPMKDIOFZTAppearanceVC.h"
#import "WOPMKDIOFZTChatBackgroundSetVC.h"

@interface WOPMKDIOFZTAppearanceVC ()<UICollectionViewDelegate, UICollectionViewDataSource>
{
    float _waxiouvAlpha;
    NSInteger _waxiouvBgColorIndex;
    
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UISwitch *waxiouvStatusSw;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvStatusL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvStatusDescL;

@property (weak, nonatomic) IBOutlet UIView *waxiouvBgV;

@property (weak, nonatomic) IBOutlet UIView *waxiouvChatBgV;
@property (weak, nonatomic) IBOutlet UIImageView *waxiouvBgImgV;
@property (weak, nonatomic) IBOutlet UIImageView *waxiouvBubbleColorImgV;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvTextAL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvTextBL;

@property (weak, nonatomic) IBOutlet UILabel *waxiouvBubbleColorFL;

@property (nonatomic, assign) NSInteger waxiouvBubbleColorIndex; // kAppearanceBubbleColor 气泡颜色的索引
@property (weak, nonatomic) IBOutlet UICollectionView *waxiouvCV;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *waxiouvLayout;

@property (weak, nonatomic) IBOutlet UILabel *waxiouvChatBgFL;
@property (nonatomic, assign) NSInteger waxiouvChatBgImgIndex; // kAppearanceChatBackgroundImg 聊天背景图片索引
@property (weak, nonatomic) IBOutlet UIButton *waxiouvChatBg0Btn;
@property (weak, nonatomic) IBOutlet UIButton *waxiouvChatBgABtn;
@property (weak, nonatomic) IBOutlet UIButton *waxiouvChatBgBBtn;
@property (weak, nonatomic) IBOutlet UIButton *waxiouvChatBgCBtn;
@property (weak, nonatomic) IBOutlet UIButton *waxiouvChatBgDBtn;

@end

@implementation WOPMKDIOFZTAppearanceVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = LLLLLL(@"Appearance");
//    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[self itemImage:@"waxiouvBack" action:@selector(waxiouvBack)]];
    _isChinese = [CommonHelper.main isChinese];
    
    _waxiouvBgColorIndex = -1;
    
    _waxiouvChatBgV.layer.cornerRadius = 15.0;
    _waxiouvChatBgV.layer.borderWidth = 0.67;
    _waxiouvChatBgV.layer.borderColor = RGBA(0xF6F6F6).CGColor;
    
    _waxiouvStatusSw.on = ![NSUserDefaults.standardUserDefaults boolForKey:kAppearanceStatus];
    _waxiouvBgV.hidden = _waxiouvStatusSw.on;
    if (!_waxiouvStatusSw.on) {
        [self waxiouvSaveItem];
    }
    
    self.waxiouvChatBgImgIndex = [NSUserDefaults.standardUserDefaults integerForKey:kAppearanceChatBackgroundImg];
    
    self.waxiouvBubbleColorIndex = [NSUserDefaults.standardUserDefaults integerForKey:kAppearanceBubbleColor];
    _waxiouvLayout.sectionInset = UIEdgeInsetsMake(0.0, 20.0, 0.0, 20.0);
    _waxiouvLayout.itemSize = CGSizeMake(40.0, 40.0);
    _waxiouvLayout.minimumInteritemSpacing = ( WIDTH-40.0-40*7.0-0.1)/6.0;
    _waxiouvLayout.minimumLineSpacing = 0.0;
    _waxiouvCV.delegate = self;
    _waxiouvCV.dataSource = self;
    [_waxiouvCV registerNib:[UINib nibWithNibName:@"WOPMKDIOFZTBubbleColorCVCell" bundle:nil] forCellWithReuseIdentifier:@"WOPMKDIOFZTBubbleColorCVCell"];
    
    _waxiouvAlpha = [NSUserDefaults.standardUserDefaults floatForKey:kAppearanceChatBackgroundImgAlpha];
    _waxiouvBgColorIndex = [NSUserDefaults.standardUserDefaults integerForKey:kAppearanceChatBackgroundColor];
    _waxiouvBgImgV.backgroundColor = [ChatBgImgColors[_waxiouvBgColorIndex] alpha:_waxiouvAlpha];
    
    if (_isChinese) {
    }else {
        _waxiouvStatusL.text = @"Pure mode";
        _waxiouvStatusDescL.text = @"No appearance is displayed after opening";
        _waxiouvTextAL.text = @"Chat style";
        _waxiouvTextBL.text = @"Chat bubble style";
        _waxiouvBubbleColorFL.text = @"Dialog bubble color";
        _waxiouvChatBgFL.text = @"Chat background";
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self waxiouvBack];
}

- (void)waxiouvBack {
    if ([self waxiouvDataIsUpdate] == NO) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:(_isChinese?@"温馨提示":@"Warm Tips") message:(_isChinese?@"您已修改设置，是否保存后返回？":@"You have modified the Settings, whether to save and return?") preferredStyle:UIAlertControllerStyleAlert];
    WS(weakself)
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:(_isChinese?@"暂不":@"Not yet") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [weakself.navigationController popViewControllerAnimated:YES];
    }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:(_isChinese?@"保存并返回":@"Save and return") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakself waxiouvSaved];
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (BOOL)waxiouvDataIsUpdate {
    NSInteger waxiouvBubbleColor = [NSUserDefaults.standardUserDefaults integerForKey:kAppearanceBubbleColor];
    NSInteger waxiouvChatBgImg = [NSUserDefaults.standardUserDefaults integerForKey:kAppearanceChatBackgroundImg];
    float waxiouvAlpha = [NSUserDefaults.standardUserDefaults floatForKey:kAppearanceChatBackgroundImgAlpha];
    NSInteger waxiouvBgColor = [NSUserDefaults.standardUserDefaults integerForKey:kAppearanceChatBackgroundColor];
    if (waxiouvBubbleColor == self.waxiouvBubbleColorIndex && waxiouvChatBgImg == self.waxiouvChatBgImgIndex && waxiouvAlpha == _waxiouvAlpha && waxiouvBgColor == _waxiouvBgColorIndex) {
        return NO;
    }
    return YES;
}

- (void)waxiouvSave {
    if ([self waxiouvDataIsUpdate] == NO) {
        [self.view makeToast:(_isChinese?@"您没有修改设置，不需要保存...":@"You have not modified the Settings, do not need to save...") duration:1.0 position:CSToastPositionCenter];
        return;
    }
    if (_waxiouvBgColorIndex == -1) {
        [self.view makeToast:(_isChinese?@"请设置聊天背景参数":@"Please set the chat background parameters") duration:1.0 position:CSToastPositionCenter];
        return;
    }
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:(_isChinese?@"您确定要保存吗？":@"Are you sure you want to save it?") message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    WS(weakself)
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakself waxiouvSaved];
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)waxiouvSaved {
    [NSUserDefaults.standardUserDefaults setInteger:self.waxiouvBubbleColorIndex forKey:kAppearanceBubbleColor];
    [NSUserDefaults.standardUserDefaults setInteger:self.waxiouvChatBgImgIndex forKey:kAppearanceChatBackgroundImg];
    [NSUserDefaults.standardUserDefaults setFloat:_waxiouvAlpha forKey:kAppearanceChatBackgroundImgAlpha];
    [NSUserDefaults.standardUserDefaults setInteger:_waxiouvBgColorIndex forKey:kAppearanceChatBackgroundColor];
    [NSUserDefaults.standardUserDefaults synchronize];
    
    [self.view makeToast:LLLLLL(@"SaveSuccessfully") duration:1.0 position:CSToastPositionCenter];
    WS(weakself)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakself.navigationController popViewControllerAnimated:YES];
    });
}



- (IBAction)waxiouvStatus:(UISwitch *)sender { // 纯净模式开关
    _waxiouvBgV.hidden = sender.on;
    if (!sender.on) {
        [self waxiouvSaveItem];
    }else {
        self.navigationItem.rightBarButtonItem = nil;
    }
    [NSUserDefaults.standardUserDefaults setBool:!sender.on forKey:kAppearanceStatus];
    [NSUserDefaults.standardUserDefaults synchronize];
}
- (void)waxiouvSaveItem {
    UIButton *waxiouvSaveBtn = [self itemTitle:LLLLLL(@"Save") action:@selector(waxiouvSave)];
    [waxiouvSaveBtn setTitleColor:MAINCOLOR forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:waxiouvSaveBtn];
}

- (IBAction)waxiouvChatBgMore:(UIButton *)sender { // 设置聊天背景
//    if (_waxiouvChatBgImgIndex <= 0) {
//        [self.view makeToast:(_isChinese?@"请先选择背景图片":@"Please select the background image first") duration:1.0 position:CSToastPositionCenter];
//        return;
//    }
    WOPMKDIOFZTChatBackgroundSetVC *vc = WOPMKDIOFZTChatBackgroundSetVC.new;
    vc.waxiouvBubbleColorIndex = _waxiouvBubbleColorIndex;
    vc.waxiouvChatBgImgIndex = _waxiouvChatBgImgIndex;
    vc.waxiouvAlpha = _waxiouvAlpha;
    vc.waxiouvBgColorIndex = _waxiouvBgColorIndex;
    WS(weakself)
    [vc setChatBackgroundSet:^(float waxiouvAlpha, NSInteger waxiouvBgColorIndex) {
        self->_waxiouvAlpha = waxiouvAlpha;
        self->_waxiouvBgColorIndex = waxiouvBgColorIndex;
        weakself.waxiouvBgImgV.backgroundColor = [ChatBgImgColors[waxiouvBgColorIndex] alpha:waxiouvAlpha];
    }];
    [self.navigationController pushViewController:vc animated:YES];
}


#pragma mark - 聊天背景图片

- (void)setwaxiouvChatBgImgIndex:(NSInteger)waxiouvChatBgImgIndex {
    _waxiouvChatBgImgIndex = waxiouvChatBgImgIndex;
    for (UIButton *waxiouvChatBgBtn in @[_waxiouvChatBg0Btn, _waxiouvChatBgABtn, _waxiouvChatBgBBtn, _waxiouvChatBgCBtn, _waxiouvChatBgDBtn]) {
        waxiouvChatBgBtn.selected = (_waxiouvChatBgImgIndex == waxiouvChatBgBtn.tag);
    }
    if (_waxiouvChatBgImgIndex <= 0) {
        _waxiouvBgImgV.image = UIImage.new;
        return;
    }
    _waxiouvBgImgV.image = IMAGENAME((UNString(@"erovaeChatBgImg%ld", _waxiouvChatBgImgIndex)));
}

- (IBAction)waxiouvChatBg:(UIButton *)sender { // 聊天背景图片->切换
    if (_waxiouvChatBgImgIndex == sender.tag) {
        return;
    }
    self.waxiouvChatBgImgIndex = sender.tag;
//    [NSUserDefaults.standardUserDefaults setInteger:self.waxiouvChatBgImgIndex forKey:kAppearanceChatBackgroundImg];
//    [NSUserDefaults.standardUserDefaults synchronize];
}

#pragma mark - UICollectionViewDelegate, UICollectionViewDataSource

- (void)setwaxiouvBubbleColorIndex:(NSInteger)waxiouvBubbleColorIndex {
    _waxiouvBubbleColorIndex = waxiouvBubbleColorIndex;
    [_waxiouvCV reloadData];
    if (_waxiouvBubbleColorIndex < 0) {
        return;
    }
    _waxiouvBubbleColorImgV.image = IMAGENAME((UNString(@"sent_msg_background%ld", _waxiouvBubbleColorIndex)));
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return BubbleColors.count;
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WOPMKDIOFZTBubbleColorCVCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"WOPMKDIOFZTBubbleColorCVCell" forIndexPath:indexPath];
    cell.erovaeBgV.backgroundColor = BubbleColors[indexPath.row];
    cell.erovaeSelectV.hidden = (indexPath.row != (_waxiouvBubbleColorIndex - 1));
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_waxiouvBubbleColorIndex == indexPath.row + 1) {
        return;
    }
    self.waxiouvBubbleColorIndex = indexPath.row + 1;
//    [NSUserDefaults.standardUserDefaults setInteger:self.waxiouvBubbleColorIndex forKey:kAppearanceBubbleColor];
//    [NSUserDefaults.standardUserDefaults synchronize];
}

@end




@interface WOPMKDIOFZTBubbleColorCVCell ()

@end

@implementation WOPMKDIOFZTBubbleColorCVCell

- (void)awakeFromNib {
    [super awakeFromNib];
    _erovaeSelectV.hidden = YES;
    _erovaeBgV.layer.cornerRadius = 15.0;
}

@end
