//
//  RUJBVOGHUYNewFriendVC.m
//  WUHOIBDK
//
//  Created by Loooooo on 11/2/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "RUJBVOGHUYNewFriendVC.h"
#import "EPIKNODWVContactsHeaderView.h"
#import "RUJBVOGHUYNewsFriendTVCell.h"

#import "RUJBVOGHUYNewsFriendInfoVC.h"


@interface RUJBVOGHUYNewFriendVC ()<UITableViewDataSource, UITableViewDelegate>
{
    BOOL _isChinese;
}
@property (nonatomic, strong)  UITableView              *tableView;
@property (nonatomic, strong) NSMutableArray<NSArray<WFCCFriendRequest *> *>            *dataList;
@property (nonatomic, strong) NSMutableArray *sectionTitles;

@property (weak, nonatomic) IBOutlet UIView *nullView;
@property (weak, nonatomic) IBOutlet UILabel *noDataL;
@property (weak, nonatomic) IBOutlet UILabel *nullL;

@end

@implementation RUJBVOGHUYNewFriendVC


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[WFCCIMService sharedWFCIMService] clearUnreadFriendRequestStatus];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [CommonHelper.main isChinese];
    
    self.navigationItem.title = LLLLLL(@"NewFriend");
    self.view.backgroundColor = UIColor.whiteColor;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"Clear") style:UIBarButtonItemStyleDone target:self action:@selector(onClearBarBtn:)];
    
    _nullL.text = (_isChinese?@"暂无数据":@"No data yet");
    
    _nullView.hidden = YES;
    _dataList = NSMutableArray.new;
    _sectionTitles = NSMutableArray.new;
        
    //设置代理
    _tableView.delegate   = self;
    _tableView.dataSource = self;
    _tableView.allowsSelection = YES;
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone; 
    [_tableView registerNib:[UINib nibWithNibName:@"RUJBVOGHUYNewsFriendTVCell" bundle:NSBundle.mainBundle] forCellReuseIdentifier:@"RUJBVOGHUYNewsFriendTVCell"];
    [_tableView registerNib:[UINib nibWithNibName:@"EPIKNODWVContactsHeaderView" bundle:NSBundle.mainBundle] forHeaderFooterViewReuseIdentifier:@"EPIKNODWVContactsHeaderView"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFriendRequestUpdated:) name:kFriendRequestUpdated object:nil];
    
    [self getRequestData];
}

//0 未处理。1 已同意。2 已拒绝
//@[@"待处理", @"已过期", @"已处理"]
- (void)getRequestData {
    [_dataList removeAllObjects];
    [_sectionTitles removeAllObjects];
    [self.tableView reloadData];

    NSMutableArray *aaa = NSMutableArray.new;
    NSMutableArray *bbb = NSMutableArray.new;
    NSMutableArray *ccc = NSMutableArray.new;
    
    [[AppService sharedAppService] friendReqList:^(NSArray<WFCCFriendRequest *> * _Nonnull friends) {
        for (WFCCFriendRequest *request in friends) {
            if (request.status == 0) {
                BOOL expired = NO;
                if (NSDate.date.timeIntervalSince1970*1000 - request.dt > 7 * 24 * 60 * 60 * 1000) {
                    expired = YES;
                }
                if (expired) {
                    [bbb addObject:request];
                }else {
                    [aaa addObject:request];
                }
            }else if (request.status == 1) {
                [ccc addObject:request];
            }else if (request.status == 2) {
                [ccc addObject:request];
            }
        }
        NSComparator sortByDtDesc = ^NSComparisonResult(WFCCFriendRequest *obj1, WFCCFriendRequest *obj2) {
            if (obj1.dt > obj2.dt) {
                return NSOrderedAscending;
            }
            if (obj1.dt < obj2.dt) {
                return NSOrderedDescending;
            }
            return NSOrderedSame;
        };
        [aaa sortUsingComparator:sortByDtDesc];
        [bbb sortUsingComparator:sortByDtDesc];
        [ccc sortUsingComparator:sortByDtDesc];
        if (aaa.count) {
            [self.dataList addObject:aaa];
            [self.sectionTitles addObject:(self->_isChinese?@"待处理":@"Wait for processing")];
        }
        if (bbb.count) {
            [self.dataList addObject:bbb];
            [self.sectionTitles addObject:LLLLLL(@"Expired")];
        }
        if (ccc.count) {
            [self.dataList addObject:ccc];
            [self.sectionTitles addObject:(self->_isChinese?@"已处理":@"Already processed")];
        }
        self.nullView.hidden = self.dataList.count;
        [self.tableView reloadData];

    } error:^(int error_code, NSString *message) {
        
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _dataList.count;
}
//table 返回的行数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_dataList.count <= 0) {
        return 0;
    }
    return _dataList[section].count;
}
//返回单元格内容
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RUJBVOGHUYNewsFriendTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RUJBVOGHUYNewsFriendTVCell" forIndexPath:indexPath];
    WFCCFriendRequest *friendRequest = self.dataList[indexPath.section][indexPath.row];
    cell.friendRequest = friendRequest;
    [cell setActblock:^{
        BOOL expired = NO;
        if (NSDate.date.timeIntervalSince1970*1000 - friendRequest.dt > 7 * 24 * 60 * 60 * 1000) {
            expired = YES;
        }
        
        //0 未处理。1 已同意。2 已拒绝
        //@[@"待处理", @"已过期", @"已处理"]
        if (friendRequest.status == 0) {
            if (!expired) { //expired
                [self accept:friendRequest];
            }
        }
        
    }];
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCCFriendRequest *request = self.dataList[indexPath.section][indexPath.row];
    if (request.status == 0) {
        BOOL expired = NO;
        if (NSDate.date.timeIntervalSince1970*1000 - request.dt > 7 * 24 * 60 * 60 * 1000) {
            expired = YES;
        }
        if (!expired) {
            RUJBVOGHUYNewsFriendInfoVC *vc = RUJBVOGHUYNewsFriendInfoVC.new;
            vc.request = self.dataList[indexPath.section][indexPath.row];
            WS(weakself)
            [vc setSuccessBlock:^{
                [weakself getRequestData];
            }];
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
    
}

- (void)accept:(WFCCFriendRequest *)friendRequest {
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"Loading");
    [hud showAnimated:YES];
    
    WS(weakself)
    [[AppService sharedAppService] friendReqAccept:friendRequest.reqId
                                           success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            hud.hidden = YES;
            [weakself.view makeToast:LLLLLL(@"SuccessfulOperation") duration:1.0 position:CSToastPositionCenter];
            [weakself getRequestData];
            [[NSNotificationCenter defaultCenter] postNotificationName:kFriendListUpdated object:nil];            
        });
    } error:^(int error_code, NSString * _Nonnull message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            hud.hidden = YES;
            if(error_code == 19) {
                [weakself.view makeToast:LLLLLL(@"Expired") duration:2 position:CSToastPositionCenter];
            } else {
                [weakself.view makeToast:LLLLLL(@"LoadFailure") duration:2 position:CSToastPositionCenter];
            }
        });
    }];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        WFCCFriendRequest *request = self.dataList[indexPath.section][indexPath.row];
        [[WFCCIMService sharedWFCIMService] deleteFriendRequest:request.target direction:request.direction];
        
        [self getRequestData];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 72.0;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.dataList.count == 0) {
        return 0.01;
    }
    return 32.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
// view上设置背景色无效。 请使用方法 willDisplayHeaderView
    EPIKNODWVContactsHeaderView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"EPIKNODWVContactsHeaderView"];
    view.raeuionjyTitleLabel.textColor = RGBA(0x919191);
    view.raeuionjyTitleLabel.font = PINGFANG_M(14.0);
    view.raeuionjyTitleLabel.text = _sectionTitles[section];
    return view;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    view.backgroundColor = UIColor.whiteColor;
}





- (void)onUserInfoUpdated:(NSNotification *)notification {
    NSArray<WFCCUserInfo *> *userInfoList = notification.userInfo[@"userInfoList"];
    for (NSInteger i = 0; i < _dataList.count; i ++) {
        NSArray *datas = _dataList[i];
        for (NSInteger j = 0; j < datas.count; j ++) {
            WFCCFriendRequest *request = datas[j];
            
            for (WFCCUserInfo *userInfo in userInfoList) {
                if([userInfo.userId isEqualToString:request.target]) {
                    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:j inSection:i]] withRowAnimation:UITableViewRowAnimationFade];
                }
            }
        }
    }
}

- (void)onFriendRequestUpdated:(NSNotification *)notification {
    [self getRequestData];
}

- (void)onAddBarBtn:(UIBarButtonItem *)sender {
    UIViewController *addFriendVC = [[JUAHODJNKAddFriendVC alloc] init];
    addFriendVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:addFriendVC animated:YES];
}

- (void)onClearBarBtn:(UIBarButtonItem *)sender {
    if (_dataList.count <= 0) {
        return;
    }
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:(_isChinese?@"您确定要清除数据吗？":@"Are you sure you want to clear your data?") message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    WS(weakself)
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {        
        [weakself clean];
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)clean {
    WS(weakself)
    [[AppService sharedAppService] friendReqClean:^{
        [weakself getRequestData];
    } error:^(int errCode, NSString * _Nonnull message) {
        
    }];
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _tableView        = nil;
    _dataList         = nil;
}

@end
