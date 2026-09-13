//
//  LUDHIOWIVFilesVC.m
//  WFChatUIKit
//
//  Created by dali on 2020/8/2.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "LUDHIOWIVFilesVC.h"
#import <WFChatClient/WFCChatClient.h>
#import "LUDHIOWIVFileRecordTVCell.h"
#import "JUAHODJNKBrowserVC.h"
#import "AIOIUEHConfigManager.h"
#import "UIImage+ERCategory.h"

@interface LUDHIOWIVFilesVC () <UITableViewDelegate, UITableViewDataSource, UISearchControllerDelegate, UISearchResultsUpdating>
{
    BOOL _isChinese;
}
@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, strong)UIActivityIndicatorView *activityView;

@property (nonatomic, strong)UISearchController *searchController;
@property(nonatomic, strong)NSMutableArray<WFCCFileRecord *> *searchedRecords;

@property(nonatomic, strong)NSMutableArray<WFCCFileRecord *> *fileRecords;
@property(nonatomic, assign)BOOL hasMore;
@property(nonatomic, assign)BOOL searchMore;
@property(nonatomic, assign)BOOL isLoading;
@property(nonatomic, strong)NSString *keyword;
@end

@implementation LUDHIOWIVFilesVC

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.topItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationController.navigationBar.shadowImage = UIImage.new;
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [WFCCIMService.main isChinese];
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.delegate = self;
    self.searchController.dimsBackgroundDuringPresentation = YES;
    if (@available(iOS 13, *)) {
        self.searchController.searchBar.searchBarStyle = UISearchBarStyleDefault;
        self.searchController.searchBar.searchTextField.backgroundColor = [AIOIUEHConfigManager globalManager].naviBackgroudColor;
        UIImage* searchBarBg = [UIImage imageWithColor:RGBCOLOR(240.0, 240.0, 240.0) size:CGSizeMake(self.view.frame.size.width - 8 * 2, 36) cornerRadius:4];
        [self.searchController.searchBar setSearchFieldBackgroundImage:searchBarBg forState:UIControlStateNormal];
    } else {
        [self.searchController.searchBar setValue:(_isChinese?@"取消":@"Cancel") forKey:@"_cancelButtonText"];
    }
    
    
    if (@available(iOS 9.1, *)) {
        self.searchController.obscuresBackgroundDuringPresentation = NO;
    }
    self.searchController.searchBar.placeholder = (_isChinese?@"搜索":@"Search");
    self.definesPresentationContext = YES;
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
//    if (@available(iOS 11.0, *)) {
//        self.navigationItem.searchController = _searchController;
//    } else {
        _searchController.searchBar.backgroundImage = UIImage.new;
        _searchController.searchBar.backgroundColor = UIColor.whiteColor;
        self.tableView.tableHeaderView = _searchController.searchBar;
//    }
    // 这句话可以解决 self.tableView.tableHeaderView = _searchController.searchBar 导致的搜索栏下滑灰色的问题
    self.tableView.backgroundView = UIView.new;
    
    [self.view addSubview:self.tableView];
    
    
    self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityView.center = self.view.center;
    [self.view addSubview:self.activityView];
    
    if (self.myFiles) {
        self.title = (_isChinese?@"我的文件":@"MyFiles");
    } else if(self.userFiles) {
        WFCCUserInfo *user = [[WFCCUserDB sharedManager] getUserInfo:self.userId];
        if (user.finalName.length > 0) {
            self.title = [NSString stringWithFormat:(_isChinese?@"%@ 的文件":@"%@ `s files"), user.finalName];
        } else if (user.alias.length) {
            self.title = [NSString stringWithFormat:(_isChinese?@"%@ 的文件":@"%@ `s files"), user.alias];
        } else if (user.displayName.length) {
            self.title = [NSString stringWithFormat:(_isChinese?@"%@ 的文件":@"%@ `s files"), user.displayName];
        } else {
            self.title = (_isChinese?@"文件":@"Files");
        }
    } else if(self.conversation) {
        self.title = (_isChinese?@"会话文件":@"Conversation files");
    } else {
        self.title = (_isChinese?@"所有文件":@"All files");
    }

    self.hasMore = YES;
    self.fileRecords = [[NSMutableArray alloc] init];
    [self loadMoreData];
}

- (void)loadMoreData {
    if (!self.hasMore) {
        return;
    }
    if(self.isLoading) {
        return;
    }
    
    __weak typeof(self)ws = self;
    long long lastId = 0;
    if (self.fileRecords.count) {
        lastId = self.fileRecords.lastObject.messageUid;
    }
    self.activityView.hidden = NO;
    [self.activityView startAnimating];
    self.isLoading = YES;
    
    [self loadData:lastId count:20 success:^(NSArray<WFCCFileRecord *> *files) {
        [ws.fileRecords addObjectsFromArray:files];
        [ws.tableView reloadData];
        ws.activityView.hidden = YES;
        [ws.activityView stopAnimating];
        ws.isLoading = NO;
        if (files.count < 20) {
            self.hasMore = NO;
        }
    } error:^(int error_code) {
        NSLog(@"load fire record error %d", error_code);
        ws.activityView.hidden = YES;
        [ws.activityView stopAnimating];
        ws.isLoading = NO;
    }];
}

- (void)setIsLoading:(BOOL)isLoading {
    _isLoading = isLoading;
    [self updateTableViewFooter];
}

- (void)setHasMore:(BOOL)hasMore {
    _hasMore = hasMore;
    [self updateTableViewFooter];
}

- (void)updateTableViewFooter {
    if(!_hasMore) {
        UIView *footView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 21)];
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
//        line.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.f];
        line.backgroundColor = [UIColor clearColor];
        [footView addSubview:line];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, self.view.frame.size.width, 16)];
        label.text = (_isChinese?@"已经加载完了":@"No more data");
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:12];
        label.textColor = [UIColor grayColor];
        [footView addSubview:label];
        self.tableView.tableFooterView = footView;
    } else if(_isLoading) {
        UIView *footView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 20)];
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [footView addSubview:activityView];
        activityView.center = footView.center;
        self.tableView.tableFooterView = footView;
    } else {
        self.tableView.tableFooterView = nil;
    }
}
- (void)loadData:(long long)startPos count:(int)count success:(void(^)(NSArray<WFCCFileRecord *> *files))successBlock
           error:(void(^)(int error_code))errorBlock {
    if (self.myFiles) {
        [[WFCCIMService sharedWFCIMService] getMyFiles:startPos order:FileRecordOrder_TIME_DESC count:count success:successBlock error:errorBlock];
    } else if(self.userFiles) {
        [[WFCCIMService sharedWFCIMService] getConversationFiles:nil fromUser:self.userId beforeMessageUid:startPos order:FileRecordOrder_TIME_DESC count:count success:successBlock error:errorBlock];
    } else {
        [[WFCCIMService sharedWFCIMService] getConversationFiles:self.conversation fromUser:nil beforeMessageUid:startPos order:FileRecordOrder_TIME_DESC count:count success:successBlock error:errorBlock];
    }
}


- (void)searchMoreData {
    if (!self.searchMore) {
        return;
    }
    
    __weak typeof(self)ws = self;
    long long lastId = 0;
    if (self.searchedRecords.count) {
        lastId = self.searchedRecords.lastObject.messageUid;
    }
    self.activityView.hidden = NO;
    
    [self searchData:lastId count:20 success:^(NSArray<WFCCFileRecord *> *files) {
        [ws.searchedRecords addObjectsFromArray:files];
        [ws.tableView reloadData];
        ws.activityView.hidden = YES;
        if (files.count < 20) {
            self.searchMore = NO;
        }
    } error:^(int error_code) {
        NSLog(@"load fire record error %d", error_code);
        ws.activityView.hidden = YES;
    }];
}

- (void)searchData:(long long)startPos count:(int)count success:(void(^)(NSArray<WFCCFileRecord *> *files))successBlock
           error:(void(^)(int error_code))errorBlock {
    if (self.myFiles) {
        [[WFCCIMService sharedWFCIMService] searchMyFiles:self.keyword beforeMessageUid:startPos order:FileRecordOrder_TIME_DESC count:count success:successBlock error:errorBlock];
    } else if(self.userFiles) {
        [[WFCCIMService sharedWFCIMService] searchFiles:self.keyword conversation:nil fromUser:self.userId beforeMessageUid:startPos order:FileRecordOrder_TIME_DESC count:count success:successBlock error:errorBlock];
    } else {
        [[WFCCIMService sharedWFCIMService] searchFiles:self.keyword conversation:self.conversation fromUser:nil beforeMessageUid:startPos order:FileRecordOrder_TIME_DESC count:count success:successBlock error:errorBlock];
    }
}


- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (ceil(targetContentOffset->y)+1 >= ceil(scrollView.contentSize.height - scrollView.bounds.size.height)) {
        if (!self.searchController.active && self.hasMore) {
            [self loadMoreData];
        }
        
        if (self.searchController.active && self.searchMore) {
            [self searchMoreData];
        }
    }
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    LUDHIOWIVFileRecordTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[LUDHIOWIVFileRecordTVCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    
    WFCCFileRecord *record;
    if (self.searchController.active) {
        record = self.searchedRecords[indexPath.row];
    } else {
        record = self.fileRecords[indexPath.row];
    }
    
    cell.fileRecord = record;
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.searchController.active) {
        return self.searchedRecords.count;
    }
    return self.fileRecords.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCCFileRecord *record;
    if (self.searchController.active) {
        record = self.searchedRecords[indexPath.row];
    } else {
        record = self.fileRecords[indexPath.row];
    }
    
    return [LUDHIOWIVFileRecordTVCell sizeOfRecord:record withCellWidth:self.view.bounds.size.width];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCCFileRecord *record;
    if (self.searchController.active) {
        record = self.searchedRecords[indexPath.row];
    } else {
        record = self.fileRecords[indexPath.row];
    }
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    if ([record.userId isEqualToString:userId]) {
        return YES;
    } else if(record.conversation.type == Group_Type) {
        WFCCGroupInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:record.conversation.target refresh:NO];
        if ([groupInfo.owner isEqualToString:userId]) {
            return YES;
        }
        WFCCGroupMember *member = [[WFCCGroupDB sharedManager] getGroupMember:record.conversation.target memberId:userId];
        if (member.type != Member_Type_Manager) {
            return NO;
        }
        
        WFCCGroupMember *senderMember = [[WFCCGroupDB sharedManager] getGroupMember:record.conversation.target memberId:record.userId];
        if (senderMember.type != Member_Type_Manager && senderMember.type != Member_Type_Owner) {
            return YES;
        }
    }
    
    return NO;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        WFCCFileRecord *record;
        if (self.searchController.active) {
            record = self.searchedRecords[indexPath.row];
        } else {
            record = self.fileRecords[indexPath.row];
        }
        
        __weak typeof(self) ws = self;
        [[WFCCIMService sharedWFCIMService] deleteFileRecord:record.messageUid success:^{
            [ws.fileRecords removeObject:record];
            [ws.tableView reloadData];
        } error:^(int error_code) {
            
        }];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCCFileRecord *record;
    if (self.searchController.active) {
        record = self.searchedRecords[indexPath.row];
    } else {
        record = self.fileRecords[indexPath.row];
    }
    
    __weak typeof(self)ws = self;
    [[WFCCIMService sharedWFCIMService] getAuthorizedMediaUrl:record.messageUid mediaType:Media_Type_FILE mediaPath:record.url success:^(NSString *authorizedUrl, NSString *backupUrl) {
        JUAHODJNKBrowserVC *bvc = [[JUAHODJNKBrowserVC alloc] init];
        bvc.url = authorizedUrl;
        [ws.navigationController pushViewController:bvc animated:YES];
    } error:^(int error_code) {
        JUAHODJNKBrowserVC *bvc = [[JUAHODJNKBrowserVC alloc] init];
        bvc.url = record.url;
        [ws.navigationController pushViewController:bvc animated:YES];
    }];
}


#pragma mark - UISearchControllerDelegate
- (void)didPresentSearchController:(UISearchController *)searchController {
    self.searchController.view.frame = self.view.bounds;
    self.tabBarController.tabBar.hidden = YES;
    self.extendedLayoutIncludesOpaqueBars = YES;
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    self.tabBarController.tabBar.hidden = NO;
    self.extendedLayoutIncludesOpaqueBars = NO;
}

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = [self.searchController.searchBar text];
    self.searchedRecords = [[NSMutableArray alloc] init];
    self.searchMore = YES;
    self.keyword = searchString;
    if (searchString.length) {
        [self searchMoreData];
    }
    
    [self.tableView reloadData];
}

@end
