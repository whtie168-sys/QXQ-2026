//
//  RUJBVOGHUYContactsVC.m
//  WUHOIBDK
//
//  Created by Loooooo on 11/1/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "RUJBVOGHUYContactsVC.h"
#import "RUJBVOGHUYContactsTVCell.h"

#import "PIUODJNMessageAddPopView.h"

#import "EPIKNODWVAddFriendVC.h"
#import "EPIKNODWVSelectContactVC.h"

#import "RUJBVOGHUYNewFriendVC.h"
#import "RUJBVOGHUYMemberInfoVC.h"
#import "RUJBVOGHUYGroupVC.h"
#import "ContactTagViewController.h"


@interface RUJBVOGHUYContactsVC ()<UITableViewDataSource, UISearchControllerDelegate, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating>
{
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong)NSMutableArray<WFCCUserInfo *> *dataArray;
@property (nonatomic, strong)NSMutableArray<NSString *> *selectedContacts;

@property (nonatomic, strong) NSMutableArray<WFCCUserInfo *> *searchList;
@property (nonatomic, strong)  UISearchController       *searchController;

@property(nonatomic, strong) NSMutableDictionary *resultDic;

@property(nonatomic, strong) NSDictionary *allFriendSectionDic;
@property(nonatomic, strong) NSArray *allKeys;

@property(nonatomic, assign)BOOL sorting;
@property(nonatomic, assign)BOOL needSort;
@property(nonatomic, strong)UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) UIView *topBgView;
@property (nonatomic, strong) UILabel *titleLabel;

@end

static NSMutableDictionary *hanziStringDict = nil;
static NSString *wfcstar = @"☆";

@implementation RUJBVOGHUYContactsVC

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)updateADFLanguage:(NSNotification *)noti {
    _isChinese = [CommonHelper.main isChinese];
    
    _titleLabel.text = LLLLLL(@"Contacts");
    [self.searchController.searchBar setPlaceholder:LLLLLL(@"Search")];
    
    if (noti != nil) {
        [_tableView reloadData];
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateADFLanguage:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateADFLanguage:) name:kLanguageNoti object:nil];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tableView.tableHeaderView = nil;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
//    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.sectionIndexColor = [UIColor colorWithHexString:@"0x4e4e4e"];
    [self.tableView registerNib:[UINib nibWithNibName:@"RUJBVOGHUYContactsTVCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"RUJBVOGHUYContactsTVCell"];
    if (self.selectContact) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"Cancel") style:UIBarButtonItemStyleDone target:self action:@selector(onLeftBarBtn:)];
        
        if(self.multiSelect) {
            self.selectedContacts = [[NSMutableArray alloc] init];
            [self updateRightBarBtn];
        }
    } else {
//      self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[AIOIUEHImage imageNamed:@"nav_add_friend"] style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[self itemImage:@"eubnxowAddM" action:@selector(eubnxowAdd)]];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onContactsUpdated:) name:kFriendListUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRootOrganizationUpdated:) name:kRootOrganizationUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMyOrganizationUpdated:) name:kMyOrganizationUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onOrganizationUpdated:) name:kOrganizationUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserExtraInfoUpdated:) name:kUserExtraInfoUpdated object:nil];
    
    _searchList = [NSMutableArray array];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.delegate = self;
    self.searchController.dimsBackgroundDuringPresentation = YES;
    
    if (@available(iOS 13, *)) {
        self.searchController.searchBar.searchBarStyle = UISearchBarStyleDefault;
        UIImage* searchBarBg = [UIImage imageWithColor:RGBA(0xF6F6F6) size:CGSizeMake(self.view.frame.size.width - 15 * 2, 36) cornerRadius:10];
        [self.searchController.searchBar setSearchFieldBackgroundImage:searchBarBg forState:UIControlStateNormal];
    } else {
        [self.searchController.searchBar setValue:LLLLLL(@"Cancel") forKey:@"_cancelButtonText"];
    }
    if (@available(iOS 9.1, *)) {
        self.searchController.obscuresBackgroundDuringPresentation = NO;
    }
    [self.searchController.searchBar setPlaceholder:LLLLLL(@"Search")];

    if (self.tabBarController.selectedIndex == 1) {
        _searchController.searchBar.backgroundImage = UIImage.new;
        _searchController.searchBar.backgroundColor = UIColor.whiteColor;

        self.tableView.tableHeaderView = [self tableHeaderView:LLLLLL(@"Contacts") searchBar:_searchController.searchBar];
        self.tableView.tableHeaderView.backgroundColor = UIColor.whiteColor;
    }else {
        if (@available(iOS 11.0, *)) {
            self.navigationItem.searchController = _searchController;
            _searchController.hidesNavigationBarDuringPresentation = YES;
        } else {
            _searchController.searchBar.backgroundImage = UIImage.new;
            _searchController.searchBar.backgroundColor = UIColor.whiteColor;

            self.tableView.tableHeaderView = _searchController.searchBar;
            self.tableView.tableHeaderView.backgroundColor = UIColor.whiteColor;
        }
    }
    // 这句话可以解决 self.tableView.tableHeaderView = _searchController.searchBar 导致的搜索栏下滑灰色的问题
    self.tableView.backgroundView = UIView.new;
//    if (@available(iOS 11.0, *)) {
//        self.navigationItem.searchController = _searchController;
//        _searchController.hidesNavigationBarDuringPresentation = YES;
//    } else {
//        _searchController.searchBar.backgroundImage = UIImage.new;
//        _searchController.searchBar.backgroundColor = UIColor.whiteColor;
//
//        self.tableView.tableHeaderView = _searchController.searchBar;
//        self.tableView.tableHeaderView = [self tableHeaderView:@"通讯录" searchBar:_searchController.searchBar];
//        self.tableView.tableHeaderView.backgroundColor = UIColor.whiteColor;
//    }
    self.definesPresentationContext = YES;
    [self.view bringSubviewToFront:self.activityIndicator];
    
    [self.tableView reloadData];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    });
    
    
//    self.dataArray = [[NSMutableArray alloc] init];
//    if (self.selectContact) {
//        [self loadContact:NO];
//    } else {
//        [self loadContact:YES];
//        [self updateBadgeNumber];
//    }
}

- (void)onUserExtraInfoUpdated:(NSNotification *)noti {
//    NSArray<WFCCGroupInfo *> *groupInfoList = notification.userInfo[@"groupInfoList"];
    
}

- (void)eubnxowAdd {
    PIUODJNMessageAddPopView *popView = [[PIUODJNMessageAddPopView alloc] init];
    WS(weakself)
    [popView setTypeBlock:^(NSInteger index) {
        if (index == 0) { // 添加好友
            EPIKNODWVAddFriendVC *vc = EPIKNODWVAddFriendVC.new;
            vc.hidesBottomBarWhenPushed = YES;
            [weakself.navigationController pushViewController:vc animated:YES];
        }else if (index == 1) { // 创建群聊
            EPIKNODWVSelectContactVC *vc = EPIKNODWVSelectContactVC.new;
            vc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }else { // 扫一扫
            if (gQrCodeDelegate) { // 走的delegate方法
                [gQrCodeDelegate scanQrCode:self.navigationController];
            }
        }
    }];
    [popView show];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self.tableView reloadData];
        }
    }
}
    
- (void)updateRightBarBtn {
    if(self.selectedContacts.count == 0) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LLLLLL(@"AlertButton") style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
        self.navigationItem.rightBarButtonItem.enabled = NO;
    } else {
        if (self.multiSelect && self.maxSelectCount > 1) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"%@(%d/%d)", LLLLLL(@"AlertButton"),  (int)self.selectedContacts.count, self.maxSelectCount] style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
        } else {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"%@(%d)", LLLLLL(@"AlertButton"),  (int)self.selectedContacts.count] style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
        }
    }
}

- (void)onRightBarBtn:(UIBarButtonItem *)sender {
  if (self.selectContact) {
    if (self.selectedContacts) {
        [self left:^{
            self.selectResult(self.selectedContacts);
        }];
    }
  } else {
    UIViewController *addFriendVC = [[JUAHODJNKAddFriendVC alloc] init];
    addFriendVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:addFriendVC animated:YES];
  }
}

- (void)onLeftBarBtn:(UIBarButtonItem *)sender {
    if (self.cancelSelect) {
        self.cancelSelect();
    }
    [self left:nil];
}

- (void)left:(void (^)(void))completion {
    if (self.isPushed) {
        [self.navigationController popViewControllerAnimated:YES];
        if(completion) {
            completion();
        }
    } else {
        [self.navigationController dismissViewControllerAnimated:YES completion:completion];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.dataArray = [[NSMutableArray alloc] init];
    if (self.selectContact) {
        [self loadContact:NO];
    } else {
        [self loadContact:YES];
    }
    
    [self updateBadgeNumber];
}

- (void)loadContact:(BOOL)forceLoadFromRemote {
    [self.dataArray removeAllObjects];
    NSArray *userIdList;
    if (self.candidateUsers.count) {
        userIdList = self.candidateUsers;
        [[UserService shared] getUserInfos:userIdList
                                   inGroup:self.groupId
                                   refresh:NO
                                   success:^(NSArray<WFCCUserInfo *> * _Nonnull users) {
            self.dataArray = [NSMutableArray arrayWithArray:users];
            self.needSort = YES;
        } error:^(int errorCode, NSString * _Nonnull message) {
            
        }];
    } else {
        [[UserService shared] getMyFriendList:forceLoadFromRemote
                                      success:^(NSArray<WFCCUserInfo *> * _Nonnull users, BOOL isCache) {
            self.dataArray = [NSMutableArray arrayWithArray:users];
            self.needSort = YES;
            if (!isCache) {
                [self queryOtherDevices];
            }
        } error:^(int errorCode, NSString * _Nonnull message) {
            
        }];
//        userIdList = [[WFCCIMService sharedWFCIMService] getMyFriendList:forceLoadFromRemote];
//        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"wfc_uikit_had_pc_session"]) {
//            if (![userIdList containsObject:[AIOIUEHConfigManager globalManager].fileTransferId]) {
//                NSMutableArray *ma = [userIdList mutableCopy];
//                [ma addObject:[AIOIUEHConfigManager globalManager].fileTransferId];
//                userIdList = [ma copy];
//            }
//        }
    }
    


//    self.dataArray = [[[WFCCIMService sharedWFCIMService] getUserInfos:userIdList inGroup:self.groupId] mutableCopy];
////    for (WFCCUserInfo *userinfo in self.dataArray) {
////        NSLog(@"toJsonObj===%@",userinfo.toJsonObj);
////    }
//    self.needSort = YES;
}

- (void)setNeedSort:(BOOL)needSort {
    _needSort = needSort;
    if (needSort && !self.sorting) {
        _needSort = NO;
        NSArray *safeDataArray = [self.dataArray copy]; // 创建副本防止修改
        NSArray *safeSearchArray = [self.searchList copy]; // 创建副本防止修改
        if (self.searchController.active) {
            [self sortAndRefreshWithList:safeSearchArray];
        } else {
            [self sortAndRefreshWithList:safeDataArray];
        }
    }
}

- (void)onUserInfoUpdated:(NSNotification *)notification {
    BOOL needRefresh = NO;
    NSArray<WFCCUserInfo *> *userInfoList = notification.userInfo[@"userInfoList"];
    for (WFCCUserInfo *userInfo in userInfoList) {
        for (WFCCUserInfo *ui in self.dataArray) {
            if ([ui.userId isEqualToString:userInfo.userId]) {
                needRefresh = YES;
                [ui cloneFrom:userInfo];
            }
        }
    }
    
    if(needRefresh) {
        self.needSort = needRefresh;
    }
}

- (void)queryOtherDevices {
    NSMutableArray *ids = [NSMutableArray new];
    for (WFCCUserInfo *user in self.dataArray) {
        [ids addObject:user.userId];
    }
    [[AppService sharedAppService] queryOtherDevices:ids
                                             success:^(NSArray<WFCCUserOnlineStateModel *> * _Nonnull onlineState) {
        [[WFCCIMService sharedWFCIMService] putUseOnlineStates1:onlineState];
        [self.tableView reloadData];
    } error:^(int errCode, NSString * _Nonnull message) {
        
    }];
}

- (void)onContactsUpdated:(NSNotification *)notification {
    [self loadContact:YES];
    [self updateBadgeNumber];
}

- (void)onRootOrganizationUpdated:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (void)onMyOrganizationUpdated:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (void)onOrganizationUpdated:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (void)sortAndRefreshWithList:(NSArray *)friendList {
    self.sorting = YES;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self.resultDic = [RUJBVOGHUYContactsVC sortedArrayWithPinYinDic:friendList];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.allFriendSectionDic = self.resultDic[@"infoDic"];
            self.allKeys = self.resultDic[@"allKeys"];
//          if (!self.selectContact && !self.searchController.active) {
            if (!self.searchController.active) {
                UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 48)];
                countLabel.textAlignment = NSTextAlignmentCenter;
                
                countLabel.text = [NSString stringWithFormat:@"%ld %@",self.dataArray.count, LLLLLL(@"NumberOfContacts")];
                countLabel.font = [UIFont systemFontOfSize:14];
                countLabel.textColor = [UIColor grayColor];
                
                self.tableView.tableFooterView = countLabel;
            }else {
                self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
            }
            
            [self.tableView reloadData];
            self.sorting = NO;
            if (self.needSort) {
                self.needSort = self.needSort;
            }
            [self.activityIndicator stopAnimating];
            self.activityIndicator.hidden = YES;
        });
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onFriendRequestUpdated:(id)sender {
    [self updateBadgeNumber];
}

//- (void)onClearAllUnread:(NSNotification *)notification {
//    if ([notification.object intValue] == 1) {
//        [[WFCCIMService sharedWFCIMService] clearUnreadFriendRequestStatus];
//        [self updateBadgeNumber];
//    }
//}

- (void)updateBadgeNumber {
    __block int count = 0;
                
    [[AppService sharedAppService] friendReqList:^(NSArray<WFCCFriendRequest *> * _Nonnull friends) {
        for(WFCCFriendRequest *friendRequest in friends) {
            BOOL expired = NO;
            if (NSDate.date.timeIntervalSince1970*1000 - friendRequest.dt > 7 * 24 * 60 * 60 * 1000) {
                expired = YES;
            }
            //0 未处理。1 已同意。2 已拒绝
            //@[@"待处理", @"已过期", @"已处理"]
            if (friendRequest.status == 0 && !expired) {
                count++;
            }
        }
        [self.tabBarController.tabBar showBadgeOnItemIndex:1 badgeValue:count];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kNewFriendRequest" object:@(count)];
    } error:^(int errCode, NSString * _Nonnull message) {
        
    }];
//    int count = [[WFCCIMService sharedWFCIMService] getUnreadFriendRequestStatus];
//    [self.tabBarController.tabBar showBadgeOnItemIndex:1 badgeValue:count];
}


#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *dataSource;

    if (self.searchController.active || self.selectContact) {
        if ((self.showCreateChannel || self.showMentionAll) && !self.searchController.active) {
            if (section == 0) {
                return 1;
            }
            dataSource = self.allFriendSectionDic[self.allKeys[section-1]];
        } else {
            dataSource = self.allFriendSectionDic[self.allKeys[section]];
        }
        return dataSource.count;
    } else {
        if (section == 0) {
            return 3 + [LUDHIOWIVOrganizationCache sharedCache].rootOrganizationIds.count + [LUDHIOWIVOrganizationCache sharedCache].bottomOrganizationIds.count;
        } else {
            dataSource = self.allFriendSectionDic[self.allKeys[section - 1]];
            return dataSource.count;
        }
    }
}

#define REUSEIDENTIFY @"resueCell"
- (HNWOUIDContactTVCell *)dequeueOrAllocContactCell:(UITableView *)tableView {
    HNWOUIDContactTVCell *contactCell = [tableView dequeueReusableCellWithIdentifier:REUSEIDENTIFY];
    if (contactCell == nil) {
        contactCell = [[HNWOUIDContactTVCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:REUSEIDENTIFY];
        contactCell.separatorInset = UIEdgeInsetsMake(0, 80.0, 0, 0);
    }
    return contactCell;
}
#define FAVGROUP_REUSEIDENTIFY @"favGroupCell"
- (HNWOUIDContactTVCell *)dequeueOrAllocFavGroupCell:(UITableView *)tableView {
    HNWOUIDContactTVCell *contactCell = [tableView dequeueReusableCellWithIdentifier:FAVGROUP_REUSEIDENTIFY];
    if (contactCell == nil) {
        contactCell = [[HNWOUIDContactTVCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:FAVGROUP_REUSEIDENTIFY];
        contactCell.separatorInset = UIEdgeInsetsMake(0, 80.0, 0, 0);
    }
    return contactCell;
}
#define CHANNEL_REUSEIDENTIFY @"channelCell"
- (HNWOUIDContactTVCell *)dequeueOrAllocChannelCell:(UITableView *)tableView {
    HNWOUIDContactTVCell *contactCell = [tableView dequeueReusableCellWithIdentifier:CHANNEL_REUSEIDENTIFY];
    if (contactCell == nil) {
        contactCell = [[HNWOUIDContactTVCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CHANNEL_REUSEIDENTIFY];
        contactCell.separatorInset = UIEdgeInsetsMake(0, 80.0, 0, 0);
    }
    return contactCell;
}
#define NEWFRIEND_REUSEIDENTIFY @"newFriendCell"
- (HNWOUIDNewFriendTVCell *)dequeueOrAllocNewFriendCell:(UITableView *)tableView {
    HNWOUIDNewFriendTVCell *contactCell = [tableView dequeueReusableCellWithIdentifier:NEWFRIEND_REUSEIDENTIFY];
    if (contactCell == nil) {
        contactCell = [[HNWOUIDNewFriendTVCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NEWFRIEND_REUSEIDENTIFY];
        contactCell.separatorInset = UIEdgeInsetsMake(0, 80.0, 0, 0);
    }
    return contactCell;
}
#define SELECT_REUSEIDENTIFY @"resueSelectCell"
- (HNWOUIDContactSelectTVCell *)dequeueOrAllocSelectContactCell:(UITableView *)tableView {
    HNWOUIDContactSelectTVCell *selectCell = [tableView dequeueReusableCellWithIdentifier:SELECT_REUSEIDENTIFY];
    if (selectCell == nil) {
        selectCell = [[HNWOUIDContactSelectTVCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SELECT_REUSEIDENTIFY];
        selectCell.selectionStyle = UITableViewCellSelectionStyleNone;
        selectCell.separatorInset = UIEdgeInsetsMake(0, 102, 0, 0);
    }
    return selectCell;
}
#define ORGANIZATION_REUSEIDENTIFY @"organizationCell"
- (HNWOUIDContactTVCell *)dequeueOrAllocOrganizationCell:(UITableView *)tableView {
    HNWOUIDContactTVCell *contactCell = [tableView dequeueReusableCellWithIdentifier:ORGANIZATION_REUSEIDENTIFY];
    if (contactCell == nil) {
        contactCell = [[HNWOUIDContactTVCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ORGANIZATION_REUSEIDENTIFY];
        contactCell.separatorInset = UIEdgeInsetsMake(0, 80.0, 0, 0);
    }
    return contactCell;
}
// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    NSArray *dataSource;
    if (self.searchController.active || self.selectContact) {
        if ((self.showCreateChannel || self.showMentionAll) && !self.searchController.active) {
            if (indexPath.section == 0) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"new_channel"];
                if (self.showCreateChannel) {
                    cell.textLabel.text = LLLLLL(@"CreateChannel");
                } else {
                    cell.textLabel.text = LLLLLL(@"@All");
                }
                cell.separatorInset = UIEdgeInsetsMake(0, 80.0, 0, 0);
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                return cell;
            }
            dataSource = self.allFriendSectionDic[self.allKeys[indexPath.section-1]];
        } else {
            dataSource = self.allFriendSectionDic[self.allKeys[indexPath.section]];
        }
    } else {
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                HNWOUIDNewFriendTVCell *contactCell = [self dequeueOrAllocNewFriendCell:tableView];
                
                contactCell.tzboeuNameLabel.text = LLLLLL(@"NewFriend");
                contactCell.trewqPortraitView.image = IMAGENAME(@"添加用户");
                [contactCell refresh];
                contactCell.separatorInset = UIEdgeInsetsMake(0, 80.0, 0, 0);
                
                contactCell.tzboeuNameLabel.textColor = [AIOIUEHConfigManager globalManager].textColor;
                contactCell.selectionStyle = UITableViewCellSelectionStyleNone;
                return contactCell;
            } else if (indexPath.row == 1) {
                HNWOUIDContactTVCell *contactCell = [self dequeueOrAllocFavGroupCell:tableView];
                contactCell.separatorInset = UIEdgeInsetsMake(0, 80.0, 0, 0);
                contactCell.tzboeuNameLabel.text = LLLLLL(@"GroupChat");
                contactCell.trewqPortraitView.image = IMAGENAME(@"IM聊天");
                contactCell.tzboeuNameLabel.textColor = [AIOIUEHConfigManager globalManager].textColor;
                contactCell.tzboeuOnlineView.hidden = YES;
                contactCell.selectionStyle = UITableViewCellSelectionStyleNone;
                return contactCell;
            } else if (indexPath.row == 2) {
                HNWOUIDContactTVCell *contactCell = [self dequeueOrAllocFavGroupCell:tableView];
                contactCell.separatorInset = UIEdgeInsetsMake(0, 80.0, 0, 0);
                contactCell.tzboeuNameLabel.text = LLLLLL(@"Biaoqian");
                contactCell.trewqPortraitView.image = IMAGENAME(@"标签");
                contactCell.tzboeuNameLabel.textColor = [AIOIUEHConfigManager globalManager].textColor;
                contactCell.tzboeuOnlineView.hidden = YES;
                contactCell.selectionStyle = UITableViewCellSelectionStyleNone;
                return contactCell;
            }
        } else {
            dataSource = self.allFriendSectionDic[self.allKeys[indexPath.section - 1]];
        }
    }

    
    if (self.selectContact) {
        if (self.multiSelect && !self.withoutCheckBox) {
            HNWOUIDContactSelectTVCell *selectCell = [self dequeueOrAllocSelectContactCell:tableView];
            WFCCUserInfo *userInfo = dataSource[indexPath.row];
            [selectCell showtzboeuFriendUid:userInfo.userId];
            selectCell.multiSelect = self.multiSelect;
            
            if ([self.selectedContacts containsObject:userInfo.userId]) {
                selectCell.checked = 1;
            } else {
                selectCell.checked = 0;
            }
            
            if ([self.disableUsers containsObject:userInfo.userId]) {
                selectCell.disabled = YES;
                if (self.disableUsersSelected) {
                    selectCell.checked = 1;
                }else {
//                    selectCell.checked = NO;
                    selectCell.checked = 2;
                }
            }else {
                selectCell.disabled = NO;
            }
            
            selectCell.tzboeuNameLabel.textColor = [AIOIUEHConfigManager globalManager].textColor;
            cell = selectCell;
        } else {
            HNWOUIDContactTVCell *selectCell = [self dequeueOrAllocContactCell:tableView];
            
            WFCCUserInfo *userInfo = dataSource[indexPath.row];
            [selectCell setUserId:userInfo.userId groupId:self.groupId];
            
            selectCell.tzboeuNameLabel.textColor = [AIOIUEHConfigManager globalManager].textColor;
            cell = selectCell;
        }
    } else {
        if (indexPath.section == 0 && !self.searchController.active) {
            if (indexPath.row == 0) {
              HNWOUIDNewFriendTVCell *contactCell = [self dequeueOrAllocNewFriendCell:tableView];
              [contactCell refresh];
                contactCell.isHiddenLine = NO;
                contactCell.tzboeuNameLabel.text = LLLLLL(@"NewFriend");
                contactCell.trewqPortraitView.image = IMAGENAME(@"添加用户");
              contactCell.tzboeuNameLabel.textColor = [AIOIUEHConfigManager globalManager].textColor;
              cell = contactCell;
            } else if (indexPath.row == 1){
              HNWOUIDContactTVCell *contactCell = [self dequeueOrAllocFavGroupCell:tableView];
                contactCell.isHiddenLine = NO;
                contactCell.tzboeuNameLabel.text = LLLLLL(@"GroupChat");
                contactCell.trewqPortraitView.image = IMAGENAME(@"IM聊天");
              contactCell.tzboeuNameLabel.textColor = [AIOIUEHConfigManager globalManager].textColor;
              cell = contactCell;
            } else if (indexPath.row == 2) {
                HNWOUIDContactTVCell *contactCell = [self dequeueOrAllocFavGroupCell:tableView];
                contactCell.separatorInset = UIEdgeInsetsMake(0, 80.0, 0, 0);
                contactCell.tzboeuNameLabel.text = LLLLLL(@"Biaoqian");
                contactCell.trewqPortraitView.image = IMAGENAME(@"标签");
                contactCell.tzboeuNameLabel.textColor = [AIOIUEHConfigManager globalManager].textColor;
                contactCell.tzboeuOnlineView.hidden = YES;
                contactCell.selectionStyle = UITableViewCellSelectionStyleNone;
                return contactCell;
            }
        } else { // 通讯录详情
//            HNWOUIDContactTVCell *contactCell = [self dequeueOrAllocContactCell:tableView];
//            WFCCUserInfo *userInfo = dataSource[indexPath.row];
//            [contactCell setUserId:userInfo.userId groupId:self.groupId];
//            contactCell.tzboeuNameLabel.textColor = [AIOIUEHConfigManager globalManager].textColor;
//            cell = contactCell;
            
            RUJBVOGHUYContactsTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RUJBVOGHUYContactsTVCell" forIndexPath:indexPath];
            if (indexPath.row < dataSource.count) {
                WFCCUserInfo *userInfo = dataSource[indexPath.row];
                [cell updateUserInfo:userInfo];
            }
            return cell;
        }
    }
    if (cell == nil) {
        NSLog(@"error");
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            return 70.0;
        }
        if (indexPath.row == 3) {
            return 0.0;
        }
    }
    return 70.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray *dataSource;
    if (self.searchController.active || self.selectContact) {
        if ((self.showCreateChannel || self.showMentionAll) && !self.searchController.active) {
            if (indexPath.section == 0) {
                if (self.showCreateChannel) {
                    [self left:^{
                        if (self.createChannel) {
                            self.createChannel();
                        }
                    }];
                } else {
                    [self left:^{
                        if (self.mentionAll) {
                            self.mentionAll();
                        }
                    }];
                }
                
                return;
            }
            dataSource = self.allFriendSectionDic[self.allKeys[indexPath.section-1]];
        } else {
            dataSource = self.allFriendSectionDic[self.allKeys[indexPath.section]];
        }
    } else {
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                RUJBVOGHUYNewFriendVC *vc = RUJBVOGHUYNewFriendVC.new;
                vc.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:vc animated:YES];
            } else if(indexPath.row == 1) { // 我的群组
                RUJBVOGHUYGroupVC *groupVC = [[RUJBVOGHUYGroupVC alloc] init];;
                groupVC.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:groupVC animated:YES];
            } else if (indexPath.row == 2) {
                ContactTagViewController *tagVC = [[ContactTagViewController alloc] init];;
                tagVC.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:tagVC animated:YES];
            } else if(indexPath.row == 3) {
                // channel feature removed
            } else {
                NSInteger index = indexPath.row - 4;
                if(index < [LUDHIOWIVOrganizationCache sharedCache].rootOrganizationIds.count) {
                    int orgId = [[LUDHIOWIVOrganizationCache sharedCache].rootOrganizationIds[index] intValue];
                    LUDHIOWIVOrganizationViewController *orgVC = [[LUDHIOWIVOrganizationViewController alloc] init];
                    orgVC.organizationIds = @[@(orgId)];
                    orgVC.hidesBottomBarWhenPushed = YES;
                    orgVC.isPushed = YES;
                    [self.navigationController pushViewController:orgVC animated:YES];
                } else {
                    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
                    index -= [LUDHIOWIVOrganizationCache sharedCache].rootOrganizationIds.count;
                    int orgId = [[LUDHIOWIVOrganizationCache sharedCache].bottomOrganizationIds[index] intValue];
                    NSArray<LUDHIOWIVOrgRelationship *> *rs = [[LUDHIOWIVOrganizationCache sharedCache] getRelationship:userId refresh:NO];
                    __block NSInteger index = orgId;
                    NSMutableArray *ids = [[NSMutableArray alloc] init];
                    while (index) {
                        [ids insertObject:@(index) atIndex:0];
                        __block BOOL has = NO;
                        [rs enumerateObjectsUsingBlock:^(LUDHIOWIVOrgRelationship * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            if(obj.organizationId == index) {
                                index = obj.parentOrganizationId;
                                *stop = YES;
                                has = YES;
                            }
                        }];
                        if(!has) {
                            break;
                        }
                    }
                    LUDHIOWIVOrganizationViewController *orgVC = [[LUDHIOWIVOrganizationViewController alloc] init];
                    orgVC.organizationIds = ids;
                    orgVC.hidesBottomBarWhenPushed = YES;
                    orgVC.isPushed = YES;
                    [self.navigationController pushViewController:orgVC animated:YES];
                }
            }
            return;
        } else {
            dataSource = self.allFriendSectionDic[self.allKeys[indexPath.section - 1]];
        }
    }
    
    if (self.selectContact) {
        WFCCUserInfo *userInfo = dataSource[indexPath.row];
        if (self.multiSelect) {
            if ([self.disableUsers containsObject:userInfo.userId]) {
                return;
            }
            
            if ([self.selectedContacts containsObject:userInfo.userId]) {
                [self.selectedContacts removeObject:userInfo.userId];
                [tableView reloadData];
            } else {
                if (self.maxSelectCount > 0 && self.selectedContacts.count >= self.maxSelectCount) {
                    [self.view makeToast:(_isChinese?@"不能超过最大限制":@"Cannot exceed the maximum limit")];
                    return;
                }
                
                [self.selectedContacts addObject:userInfo.userId];
                [tableView reloadData];
            }
            [self updateRightBarBtn];
        } else {
            self.selectResult([NSArray arrayWithObjects:userInfo.userId, nil]);
            [self left:nil];
        }
    } else {
        WFCCUserInfo *friend = dataSource[indexPath.row];
        
        RUJBVOGHUYMemberInfoVC *vc = RUJBVOGHUYMemberInfoVC.new;
        vc.hidesBottomBarWhenPushed = YES;
        vc.userId = friend.userId;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (@available(iOS 11.0, *)) {
        if (self.selectContact) {
            if ((self.showCreateChannel || self.showMentionAll) && !self.searchController.active) {
                NSMutableArray *indexs = [self.allKeys mutableCopy];
                [indexs insertObject:@"" atIndex:0];
                return indexs;
            }
            return self.allKeys;
        }
        if (self.searchController.active) {
            return self.allKeys;
        }
        NSMutableArray *indexs = [self.allKeys mutableCopy];
        [indexs insertObject:@"" atIndex:0];
        return indexs;
    } else {
        return nil;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.selectContact) {
        if ((self.showCreateChannel || self.showMentionAll) && !self.searchController.active) {
            return self.allKeys.count + 1;
        }
        return self.allKeys.count;
    }
    if (self.searchController.active) {
        return self.allKeys.count;
    }
    return 1 + self.allKeys.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.selectContact || self.searchController.active) {
        if ((self.showCreateChannel || self.showMentionAll) && !self.searchController.active) {
            if (section == 0) {
                return 0;
            }
        }
    } else {
        if(section == 0)
            return 0;
    }
    return 32.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *title;
    if (self.selectContact || self.searchController.active) {
        if ((self.showCreateChannel || self.showMentionAll) && !self.searchController.active) {
            if (section == 0) {
                return nil;
            }
            title = self.allKeys[section-1];
        } else {
            title = self.allKeys[(section-1) < 0 ? 0: (section-1)];
        }
    } else {
        if (section == 0) {
            return nil;
        } else {
            title = self.allKeys[section - 1];
        }
    }
    if (title == nil || title.length == 0) {
        return nil;
    }
// view上设置背景色无效。 请使用方法 willDisplayHeaderView
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20.0, 0, self.view.frame.size.width, 30)];
    label.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:13];
    label.textColor = RGBA(0x333333);
    label.textAlignment = NSTextAlignmentLeft;
    if ([title isEqualToString:wfcstar]) {
        title = LLLLLL(@"StarFriends");
    }
    label.text = [NSString stringWithFormat:@"%@", title];
    [view addSubview:label];
    return view;
}

- (UIActivityIndicatorView *)activityIndicator {
    if (!_activityIndicator) {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activityIndicator.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
        [self.view addSubview:_activityIndicator];
        [_activityIndicator startAnimating];
        [self.view bringSubviewToFront:_activityIndicator];
    }
    return _activityIndicator;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
  if (self.selectContact) {
    return index;
  }
  if (self.searchController.active) {
    return index;
  }
  return index;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    view.backgroundColor = UIColor.whiteColor;
//    view.backgroundColor = AIOIUEHConfigManager.globalManager.backgroudColor;
}



- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.searchController.active) {
        [self.searchController.searchBar resignFirstResponder];
    }
}
#pragma mark - UISearchControllerDelegate
- (void)didPresentSearchController:(UISearchController *)searchController {
    _titleLabel.hidden = YES;
    self.tabBarController.tabBar.hidden = YES;
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    CGRect topBgViewFrame = _topBgView.frame;
    topBgViewFrame.size.height = _searchController.searchBar.frame.size.height;
    _topBgView.frame = topBgViewFrame;
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    _titleLabel.hidden = NO;
    self.tabBarController.tabBar.hidden = NO;
    self.extendedLayoutIncludesOpaqueBars = NO;
}

- (void)didDismissSearchController:(UISearchController *)searchController {
    self.needSort = YES;
    
    CGRect topBgViewFrame = _topBgView.frame;
    topBgViewFrame.size.height = 106.0;
    _topBgView.frame = topBgViewFrame;
    [self.tableView reloadData];
}

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    if (searchController.active) {
        NSString *searchString = [self.searchController.searchBar text];
        
        // 1. 获取当前的输入模式
        if (@available(iOS 13.0, *)) {
            UITextInputMode *currentInputMode = searchController.searchBar.searchTextField.textInputMode;
            NSString *keyboardLanguage = currentInputMode.primaryLanguage;
            // 2. 判断是否是中文键盘（可能是 zh-Hans、zh-Hant 等）
            BOOL isChineseKeyboard = [keyboardLanguage hasPrefix:@"zh"];

            // 3. 获取 markedTextRange
            UITextRange *markedRange = searchController.searchBar.searchTextField.markedTextRange;
            // 4. 只有当【使用中文键盘】且【没有拼音未上屏】时才触发搜索
            if (isChineseKeyboard && markedRange != nil) {
                return;
            }
        } else {
            // Fallback on earlier versions
        }

        if (self.searchList!= nil) {
            [self.searchList removeAllObjects];
            if(searchString.length) {
                QOEUAPinyinUtility *pu = [[QOEUAPinyinUtility alloc] init];
                BOOL isChinese = [pu isChinese:searchString];
                for (WFCCUserInfo *friend in self.dataArray) {
                    if ([friend.displayName.lowercaseString containsString:searchString.lowercaseString] || [friend.alias.lowercaseString containsString:searchString.lowercaseString] || [friend.finalName.lowercaseString containsString:searchString.lowercaseString]) {
                        [self.searchList addObject:friend];
                    } else if(!isChinese) {
                        if([pu isMatch:friend.displayName ofPinYin:searchString] ||
                           [pu isMatch:friend.alias ofPinYin:searchString] ||
                           [pu isMatch:friend.finalName ofPinYin:searchString]) {
                            [self.searchList addObject:friend];
                        }
                    }
                }
            }
        }
        self.needSort = YES;
    }
}

+ (NSMutableDictionary *)sortedArrayWithPinYinDic:(NSArray *)userList {
    if (!userList)
        return nil;
    NSArray *_keys = @[
                       wfcstar,
                       @"A",
                       @"B",
                       @"C",
                       @"D",
                       @"E",
                       @"F",
                       @"G",
                       @"H",
                       @"I",
                       @"J",
                       @"K",
                       @"L",
                       @"M",
                       @"N",
                       @"O",
                       @"P",
                       @"Q",
                       @"R",
                       @"S",
                       @"T",
                       @"U",
                       @"V",
                       @"W",
                       @"X",
                       @"Y",
                       @"Z",
                       @"#"
                       ];
    
    NSMutableDictionary *infoDic = [NSMutableDictionary new];
    NSMutableArray *_tempOtherArr = [NSMutableArray new];
    BOOL isReturn = NO;
    NSMutableDictionary *firstLetterDict = [[NSMutableDictionary alloc] init];
    
    NSArray<NSString *> *favUsers = [[WFCCIMService sharedWFCIMService] getFavUsers];
    
    NSMutableArray *favArrays = [[NSMutableArray alloc] init];
    for (NSString *favUser in favUsers) {
        for (WFCCUserInfo *userInfo in userList) {
            if ([userInfo.userId isEqualToString:favUser]) {
                [favArrays addObject:userInfo];
                break;
            }
        }
        
    }
    if (favArrays.count) {
        [infoDic setObject:favArrays forKey:wfcstar];
    }
    
    
    for (NSString *key in _keys) {
        if ([key isEqualToString:wfcstar]) {
            continue;
        }
        if ([_tempOtherArr count]) {
            isReturn = YES;
        }
        NSMutableArray *tempArr = [NSMutableArray new];
        for (id user in userList) {
            NSString *firstLetter;

            WFCCUserInfo *userInfo = (WFCCUserInfo*)user;
            NSString *userName = userInfo.displayName;
            if (userInfo.groupAlias.length) {
                userName = userInfo.groupAlias;
            }
            if (userInfo.alias.length) {
                userName = userInfo.alias;
            }
            if (userInfo.finalName.length) {
                userName = userInfo.finalName;
            }
            if (userName.length == 0) {
                userInfo.displayName = [NSString stringWithFormat:@"<%@>", userInfo.userId];
                userName = userInfo.displayName;
            }
            
            firstLetter = [firstLetterDict objectForKey:userName];
            if (!firstLetter) {
                firstLetter = [self getFirstUpperLetter:userName];
                [firstLetterDict setObject:firstLetter forKey:userName];
            }
            
            
            if ([firstLetter isEqualToString:key]) {
                [tempArr addObject:user];
            }
            
            if (isReturn)
                continue;
            char c = [firstLetter characterAtIndex:0];
            if (isalpha(c) == 0) {
                [_tempOtherArr addObject:user];
            }
        }
        if (![tempArr count])
            continue;
        [infoDic setObject:tempArr forKey:key];
    }
    if ([_tempOtherArr count])
        [infoDic setObject:_tempOtherArr forKey:@"#"];
    
    NSArray *keys = [[infoDic allKeys]
                     sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                         
                         return [obj1 compare:obj2 options:NSNumericSearch];
                     }];
    NSMutableArray *allKeys = [[NSMutableArray alloc] initWithArray:keys];
    if ([allKeys containsObject:@"#"]) {
        [allKeys removeObject:@"#"];
        [allKeys insertObject:@"#" atIndex:allKeys.count];
    }
    if ([allKeys containsObject:wfcstar]) {
        [allKeys removeObject:wfcstar];
        [allKeys insertObject:wfcstar atIndex:0];
    }
    NSMutableDictionary *resultDic = [NSMutableDictionary new];
    [resultDic setObject:infoDic forKey:@"infoDic"];
    [resultDic setObject:allKeys forKey:@"allKeys"];
    [infoDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSMutableArray *_tempOtherArr = (NSMutableArray *)obj;
        [_tempOtherArr sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            WFCCUserInfo *user1 = (WFCCUserInfo *)obj1;
            WFCCUserInfo *user2 = (WFCCUserInfo *)obj2;
            NSString *user1Pinyin = [RUJBVOGHUYContactsVC hanZiToPinYinWithString:user1.finalName];
            NSString *user2Pinyin = [RUJBVOGHUYContactsVC hanZiToPinYinWithString:user2.finalName];
            return [user1Pinyin compare:user2Pinyin];
        }];
    }];
    return resultDic;
}

+ (NSString *)getFirstUpperLetter:(NSString *)hanzi {
    NSString *pinyin = [self hanZiToPinYinWithString:hanzi];
    NSString *firstUpperLetter = [[pinyin substringToIndex:1] uppercaseString];
    if ([firstUpperLetter compare:@"A"] != NSOrderedAscending &&
        [firstUpperLetter compare:@"Z"] != NSOrderedDescending) {
        return firstUpperLetter;
    } else {
        return @"#";
    }
}

+ (NSString *)hanZiToPinYinWithString:(NSString *)hanZi {
    if (!hanZi) {
        return nil;
    }
    if (!hanziStringDict) {
        hanziStringDict = [[NSMutableDictionary alloc] init];
    }
    
    NSString *pinYinResult = [hanziStringDict objectForKey:hanZi];
    if (pinYinResult) {
        return pinYinResult;
    }
    pinYinResult = [NSString string];
    for (int j = 0; j < hanZi.length; j++) {
        NSString *singlePinyinLetter = nil;
        if ([self isChinese:[hanZi substringWithRange:NSMakeRange(j, 1)]]) {
            singlePinyinLetter = [[NSString
                                   stringWithFormat:@"%c", pinyinFirstLetter([hanZi characterAtIndex:j])]
                                  uppercaseString];
        }else{
            singlePinyinLetter = [hanZi substringWithRange:NSMakeRange(j, 1)];
        }
        
        pinYinResult = [pinYinResult stringByAppendingString:singlePinyinLetter];
    }
    [hanziStringDict setObject:pinYinResult forKey:hanZi];
    return pinYinResult;
}

+ (BOOL)isChinese:(NSString *)text
{
    NSString *match = @"(^[\u4e00-\u9fa5]+$)";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF matches %@", match];
    return [predicate evaluateWithObject:text];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (UIView *)tableHeaderView:(NSString *)title searchBar:(UISearchBar *)searchBar {
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, WIDTH, 106.0)];
    bgView.backgroundColor = UIColor.whiteColor;
    _topBgView = bgView;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0, 12.0, WIDTH - 40.0, 35.0)];
    titleLabel.backgroundColor = UIColor.clearColor;
    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.textColor = RGBA(0x222222);
    titleLabel.font = PINGFANG_M(23.0);
    titleLabel.text = title;
    [bgView addSubview:titleLabel];
    _titleLabel = titleLabel;
    
    UIView *bg2View = [[UIView alloc] initWithFrame:CGRectMake(0.0, CGRectGetMaxY(titleLabel.frame)+3.0, WIDTH, searchBar.frame.size.height)];
    bg2View.backgroundColor = UIColor.clearColor;
    [bgView addSubview:bg2View];
    
    [bg2View addSubview:searchBar];
    
    return bgView;
}

@end
