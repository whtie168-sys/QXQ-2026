//
//  FriendRequestViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/7.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "DUVOHJNFriendRequestVC.h"
#import <WFChatClient/WFCChatClient.h>
#import <SDWebImage/SDWebImage.h>
#import "DUVOHJNFriendRequestTVCell.h"
#import "MBProgressHUD.h"
#import "JUAHODJNKAddFriendVC.h"
#import "UIView+Toast.h"
#import "AIOIUEHConfigManager.h"

@interface DUVOHJNFriendRequestVC () <UITableViewDataSource, UITableViewDelegate, DUVOHJNFriendRequestTVCellDelegate>
@property (nonatomic, strong)  UITableView              *tableView;
@property (nonatomic, strong) NSArray<WFCCFriendRequest *>            *dataList;
@end

@implementation DUVOHJNFriendRequestVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initSearchUIAndData];
  
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFriendRequestUpdated:) name:kFriendRequestUpdated object:nil];
    
    
    [[WFCCIMService sharedWFCIMService] clearUnreadFriendRequestStatus];
}

- (void)onUserInfoUpdated:(NSNotification *)notification {
    NSArray<WFCCUserInfo *> *userInfoList = notification.userInfo[@"userInfoList"];
    for (int i = 0; i < self.dataList.count; ++i) {
        WFCCFriendRequest *request = self.dataList[i];
        for (WFCCUserInfo *userInfo in userInfoList) {
            if([userInfo.userId isEqualToString:request.target]) {
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            }
        }
    }
}

- (void)onFriendRequestUpdated:(NSNotification *)notification {
    self.dataList   = [[WFCCIMService sharedWFCIMService] getIncommingFriendRequest];
    [self.tableView reloadData];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[WFCCIMService sharedWFCIMService] clearUnreadFriendRequestStatus];
}

- (void)initSearchUIAndData {
    self.view.backgroundColor = [AIOIUEHConfigManager globalManager].backgroudColor;
    self.navigationItem.title = WFCString(@"NewFriend");
    
    //初始化数据源
    [[WFCCIMService sharedWFCIMService] loadFriendRequestFromRemote];
    _dataList   = [[WFCCIMService sharedWFCIMService] getIncommingFriendRequest];
    
    CGFloat screenWidth = self.view.frame.size.width;
    CGFloat screenHeight = self.view.frame.size.height;
    _tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    
    //设置代理
    _tableView.delegate   = self;
    _tableView.dataSource = self;
    _tableView.allowsSelection = YES;
    _tableView.backgroundColor = [AIOIUEHConfigManager globalManager].backgroudColor;
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    [self.view addSubview:_tableView];
  
    self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithTitle:WFCString(@"Clear") style:UIBarButtonItemStyleDone target:self action:@selector(onClearBarBtn:)], [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Add") style:UIBarButtonItemStyleDone target:self action:@selector(onAddBarBtn:)]];
}

- (void)onAddBarBtn:(UIBarButtonItem *)sender {
    UIViewController *addFriendVC = [[JUAHODJNKAddFriendVC alloc] init];
    addFriendVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:addFriendVC animated:YES];
}

- (void)onClearBarBtn:(UIBarButtonItem *)sender {
    [[WFCCIMService sharedWFCIMService] clearFriendRequest:1 beforeTime:0];
    _dataList   = [[WFCCIMService sharedWFCIMService] getIncommingFriendRequest];
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tabBarController.tabBar.hidden = YES;
}

#pragma mark - UITableViewDataSource

//table 返回的行数
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
      return [self.dataList count];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}
//返回单元格内容
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *requestFlag = @"request_cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:requestFlag];
  
  if (cell == nil) {
    cell = [[DUVOHJNFriendRequestTVCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:requestFlag];
  }
  
  
  DUVOHJNFriendRequestTVCell *frCell = (DUVOHJNFriendRequestTVCell *)cell;
  frCell.delegate = self;
  WFCCFriendRequest *request = self.dataList[indexPath.row];
  frCell.friendRequest = request;
  
  cell.userInteractionEnabled = YES;
  return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        WFCCFriendRequest *request = self.dataList[indexPath.row];
        [[WFCCIMService sharedWFCIMService] deleteFriendRequest:request.target direction:request.direction];
        _dataList   = [[WFCCIMService sharedWFCIMService] getIncommingFriendRequest];
        [self.tableView reloadData];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}
#pragma mark - FriendRequestTableViewCellDelegate
- (void)onAcceptBtn:(NSString *)targetUserId {
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = WFCString(@"Updating");
    [hud showAnimated:YES];
    
    __weak typeof(self) ws = self;
    [[WFCCIMService sharedWFCIMService] handleFriendRequest:targetUserId accept:YES extra:nil success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            hud.hidden = YES;
            [ws.view makeToast:WFCString(@"UpdateDone")
                      duration:2
                      position:CSToastPositionCenter];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [[WFCCIMService sharedWFCIMService] loadFriendRequestFromRemote];
                dispatch_async(dispatch_get_main_queue(), ^{
                    ws.dataList   = [[WFCCIMService sharedWFCIMService] getIncommingFriendRequest];
                    for (WFCCFriendRequest *request in ws.dataList) {
                        if ([request.target isEqualToString:targetUserId]) {
                            request.status = 1;
                            break;
                        }
                    }
                    [ws.tableView reloadData];
                });
            });
        });
    } error:^(int error_code) {
        dispatch_async(dispatch_get_main_queue(), ^{
            hud.hidden = YES;
            if(error_code == 19) {
                [ws.view makeToast:WFCString(@"Expired")
                          duration:2
                          position:CSToastPositionCenter];
            } else {
                [ws.view makeToast:WFCString(@"UpdateFailure")
                          duration:2
                          position:CSToastPositionCenter];
            }
        });
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _tableView        = nil;
    _dataList         = nil;
}
@end
