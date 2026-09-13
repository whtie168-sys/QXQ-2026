//
//  EPIKNODWVGroupNotificationVC.m
//  WUHOIBDK
//
//  Created by Ruby on 12/25/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "EPIKNODWVGroupNotificationVC.h"
#import "EPIKNODWVGroupNotiAcceptVC.h"
#import "EPIKNODWVGroupNotiAcceptBBVC.h"

@interface EPIKNODWVGroupNotificationVC ()<UITableViewDelegate, UITableViewDataSource>
{
    BOOL _isChinese;
}
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<WaitAcceptList *>            *dataList;

@end

@implementation EPIKNODWVGroupNotificationVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = LLLLLL(@"GroupNotifications");
    UIButton *rightItem = [self itemImage:@"xaicosgoeMore" action:@selector(more)];
    rightItem.frame = CGRectMake(0.0, 0.0, 32.0, 32.0);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightItem];
    
    _isChinese = [CommonHelper.main isChinese];
    _dataList = NSMutableArray.new;
    
    [self requestData];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 0.0, WIDTH, HEIGHT) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.rowHeight = 82;
    _tableView.showsVerticalScrollIndicator = NO;
    _tableView.showsHorizontalScrollIndicator = NO;
    _tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectZero];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [_tableView registerNib:[UINib nibWithNibName:@"EPIKNODWVGroupNotificationTVCell" bundle:NSBundle.mainBundle] forCellReuseIdentifier:@"EPIKNODWVGroupNotificationTVCell"];
    [self.view addSubview:_tableView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestData) name:kGroupNotificationOperate object:nil];
}

- (void)requestData {
    [self.dataList removeAllObjects];
    [SVProgressHUD showWithStatus:nil];
    WS(weakself)
    [[AppService sharedAppService] groupWaitAcceptList:^(NSArray<WaitAcceptList *> * _Nonnull groups) {
        [SVProgressHUD dismiss];
        weakself.dataList = [NSMutableArray arrayWithArray:groups];
        [weakself.tableView reloadData];

    } error:^(int errCode, NSString * _Nonnull message) {
        [SVProgressHUD dismiss];
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
//table 返回的行数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dataList.count;
}
//返回单元格内容
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EPIKNODWVGroupNotificationTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EPIKNODWVGroupNotificationTVCell" forIndexPath:indexPath];
    cell.separatorInset = UIEdgeInsetsMake(0, 82.0, 0, 0);
    cell.acceptList =  _dataList[indexPath.row];
    
    cell.inviteButton.tag = indexPath.row;
    [cell.inviteButton addTarget:self action:@selector(invite:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    WaitAcceptList *acceptList = _dataList[indexPath.row];
    if (acceptList.accept != 0) { // 0 待审核、1 已同意、2 被拒绝、3 该群组已解散
        return;
    }
    if (acceptList == nil || acceptList.id.length == 0) {
        [self.view makeToast:(_isChinese?@"等待数据加载...":@"Please wait for the data to load") duration:1.0 position:CSToastPositionCenter];
        return;
    }
    if (acceptList.type == 0) { // 申请(icon/name 个人用户的信息)
        EPIKNODWVGroupNotiAcceptBBVC *vc = EPIKNODWVGroupNotiAcceptBBVC.new;
        vc.acceptList = acceptList;
        [self.navigationController pushViewController:vc animated:YES];
    }else {
        EPIKNODWVGroupNotiAcceptVC *vc = EPIKNODWVGroupNotiAcceptVC.new;
        vc.acceptList = acceptList;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)invite:(UIButton *)sender {
    WaitAcceptList *acceptList = _dataList[sender.tag];
    if (acceptList.accept != 0) {
        return;
    }
    if (acceptList.id.length == 0) {
        return;
    }
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"Loading");
    [hud showAnimated:YES];
    
    WS(weakself)
    NSDictionary *params = @{@"id":acceptList.id, @"accept":@(1)};
    sender.userInteractionEnabled = NO;
    [AppService.sharedAppService groupAccept:params success:^{
        [hud hideAnimated:YES];
        [weakself requestData];
    } error:^(int errCode, NSString * _Nonnull message) {
        [hud hideAnimated:YES];
        sender.userInteractionEnabled = YES;
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
        [weakself.view makeToast:text duration:1.5 position:CSToastPositionCenter];
    }];
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self deleteAccept:@[_dataList[indexPath.row].id]];
    }
}

- (void)deleteAccept:(NSArray *)ids {
    WS(weakself)
    [AppService.sharedAppService requestUrl:@"/group/accept/delete" params:ids success:^(NSDictionary * _Nonnull dict) {
        [weakself requestData];
    } error:^(int errCode, NSString * _Nonnull message) {
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
        [weakself.view makeToast:text duration:1.5 position:CSToastPositionCenter];
    }];
}

- (void)more {
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    WS(weakself)
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:(_isChinese?@"清空群通知":@"Clear group notification") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        if (weakself.dataList.count) {
            [weakself deleteAccept:@[]];
        }
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}



@end


@interface EPIKNODWVGroupNotificationTVCell ()
{
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *tzboeuNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;
@property (weak, nonatomic) IBOutlet UILabel *descBLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@end

@implementation EPIKNODWVGroupNotificationTVCell

- (void)awakeFromNib {
    [super awakeFromNib];
    _iconView.layer.cornerRadius = 26.0;
    _inviteButton.layer.cornerRadius = 12.0;
    _isChinese = [CommonHelper.main isChinese];
}

- (void)setAcceptList:(WaitAcceptList *)acceptList {
    _acceptList = acceptList;
    
    _descLabel.text = acceptList.remark;
    _timeLabel.text = [UNString(@"%lld", acceptList.updateTime) timeIntervalDateFormat:@"MM-dd HH:mm"];
    
    // 0 申请加入   1 被邀请加入
    if (acceptList.type == 0) { // 申请(icon/name 个人用户的信息)
        WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:acceptList.requestUserId];
        [self.iconView sd_setImageWithURL:URL(userInfo.portrait) placeholderImage:[AIOIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                                  context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
        self.tzboeuNameLabel.text = (userInfo.alias.length > 0 ? userInfo.alias : userInfo.displayName);
        if (userInfo.finalName.length > 0) {
            self.tzboeuNameLabel.text = userInfo.finalName;
        }
        
        if (acceptList.inviteUserId.length) {
            WFCCUserInfo *inviteInfo = [[WFCCUserDB sharedManager] getUserInfo:acceptList.inviteUserId];
            WFCCUserInfo *requestInfo = [[WFCCUserDB sharedManager] getUserInfo:acceptList.requestUserId];
            // 如果为邀请 requestUser 是邀请人 checkUser是被邀请人
            NSString *inviteStr = (inviteInfo.finalName.length > 0 ? inviteInfo.finalName : inviteInfo.displayName);
            NSString *requestStr = (requestInfo.finalName.length > 0 ? requestInfo.finalName : requestInfo.displayName);
            if (inviteStr.length <= 0) {
                inviteStr = _acceptList.inviteUser;
            }
            if (requestStr.length <= 0) {
                requestStr = _acceptList.requestUser;
            }
            if (_isChinese) {
                _descBLabel.text = [NSString stringWithFormat:@"%@ 邀请 %@ 加入群聊",inviteStr, requestStr];
            }else {
                _descBLabel.text = [NSString stringWithFormat:@"%@ invites %@ to join a group chat",inviteStr, requestStr];
            }
        }else {
            _descBLabel.text = @"";
        }
    }else {
        WFCCGroupInfo *groupInfo = [WFCCIMService.sharedWFCIMService getGroupInfo:acceptList.groupId refresh:NO];
        [self.iconView sd_setImageWithURL:URL(groupInfo.portrait) placeholderImage:[AIOIUEHImage imageNamed:@"groupIcon"] options:SDWebImageScaleDownLargeImages
                                  context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
        self.tzboeuNameLabel.text = groupInfo.displayName.length ? groupInfo.displayName : acceptList.group;
        
        _descBLabel.text = @"";
    }
    
    if (acceptList.accept == 0) { // 0 待审核、1 已同意、2 被拒绝、3 该群组已解散
        _inviteButton.hidden = NO;
        _inviteButton.selected = NO;
        _inviteButton.backgroundColor = MAINCOLOR;
        _inviteButton.titleLabel.font = PINGFANG_M(18);
        [_inviteButton setTitle:@"✓" forState:UIControlStateNormal];
    }else if (acceptList.accept == 3) { // 该群组已解散
        _descBLabel.text = @"";
        _inviteButton.hidden = YES;
        _descLabel.text = (_isChinese?@"该群聊已解散":@"The group chat is disbanded");
    }else {
        _inviteButton.hidden = NO;
        _inviteButton.selected = YES;
        _inviteButton.backgroundColor = RGBA(0xF6F6F6);
        _inviteButton.titleLabel.font = PINGFANG_R(11);
        [_inviteButton setTitle:(acceptList.accept == 1 ? LLLLLL(@"Agreed") : LLLLLL(@"Rejected")) forState:UIControlStateNormal];
    }
}

@end
