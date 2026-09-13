//
//  MyBlackListViewController.m
//  WildFireChat
//
//  Created by wtb on 2025/8/20.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "MyBlackListViewController.h"
#import <SDWebImage/SDWebImage.h>

@interface MyBlackListViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong)  UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataArr;

@end

@implementation MyBlackListViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.topItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationController.navigationBar.shadowImage = UIImage.new;
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LocalizedString(@"Blacklist");
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
//    self.dataArr = [[[WFCCIMService sharedWFCIMService] getBlackList:YES] mutableCopy];
    [self.tableView reloadData];
    [self.view addSubview:self.tableView];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [_tableView registerClass:MyBlackListCell.class forCellReuseIdentifier:@"MyBlackListCell"];
    
    [self getData];
}

- (void)getData {
    [[AppService sharedAppService] friendBlackList:^(NSArray<WFCCUserInfo *> * _Nonnull friends) {
        self.dataArr = [NSMutableArray arrayWithArray:friends];
        [self.tableView reloadData];
    } error:^(int errCode, NSString * _Nonnull message) {
        
    }];
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        WFCCUserInfo *userInfo = self.dataArr[indexPath.row];
        NSString *userId = userInfo.userId;
        __weak typeof(self) ws = self;
        
        [[AppService sharedAppService] friendBlackCancel:userId
                                                 success:^{
            [ws getData];
        } error:^(int errCode, NSString * _Nonnull message) {
            
        }];
//        [[WFCCIMService sharedWFCIMService] setBlackList:userId isBlackListed:NO success:^{
//            [ws.dataArr removeObject:userId];
//            [ws.tableView reloadData];
//        } error:^(int error_code) {
//            
//        }];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"移除黑名单";
}
#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MyBlackListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyBlackListCell" forIndexPath:indexPath];
    WFCCUserInfo *userInfo = self.dataArr[indexPath.row];

//    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:[self.dataArr objectAtIndex:indexPath.row] refresh:NO];
    
    [cell.iconView sd_setImageWithURL:[NSURL URLWithString:[userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[AIOIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                              context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    cell.tzboeuNameLabel.text = (userInfo.alias.length > 0 ? userInfo.alias : userInfo.displayName);
    if (userInfo.finalName.length > 0) {
        cell.tzboeuNameLabel.text = userInfo.finalName;
    }
    return cell;
}

@end


@implementation MyBlackListCell

- (void)awakeFromNib {
    [super awakeFromNib];

}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        [self.contentView addSubview:self.iconView];
        [self.contentView addSubview:self.tzboeuNameLabel];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(70.0, 59.5, UIScreen.mainScreen.bounds.size.width-70.0, 0.5)];
        lineView.backgroundColor = RGBCOLOR(224, 224, 224);
        [self.contentView addSubview:lineView];
    }
    return self;
}

- (UIImageView *)iconView {
    if (!_iconView) {
        _iconView = [[UIImageView alloc] initWithFrame:CGRectMake(20.0,10.0, 40.0, 40.0)];
        _iconView.contentMode = UIViewContentModeScaleAspectFill;
        _iconView.layer.cornerRadius = 20.0;
        _iconView.layer.masksToBounds = YES;
    }return _iconView;
}

- (UILabel *)tzboeuNameLabel {
    if (!_tzboeuNameLabel) {
        _tzboeuNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(70.0, 15.0, UIScreen.mainScreen.bounds.size.width - 80.0, 30.0)];
        _tzboeuNameLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:15.0];
        _tzboeuNameLabel.textAlignment = NSTextAlignmentLeft;
        _tzboeuNameLabel.textColor = UIColor.blackColor;
    }return _tzboeuNameLabel;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.iconView sd_cancelCurrentImageLoad];
    self.iconView.image = nil;
}

@end
