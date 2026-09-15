//
//  ConversationSearchTableViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/8/29.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "DUVOHJNConversationSearchTableVC.h"

#import "AIOIUEHMessageListVC.h"

#import <SDWebImage/SDWebImage.h>
#import "AIOIUEHUtilities.h"
#import "UITabBar+badge.h"
#import "KxMenu.h"
#import "UIImage+ERCategory.h"
#import "MBProgressHUD.h"

#import "DUVOHJNConversationSearchTVCell.h"
#import "AIOIUEHConfigManager.h"
#import "AIOIUEHImage.h"

@interface DUVOHJNConversationSearchTableVC () <UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong)NSMutableArray<WFCCMessage* > *messages;
@property (nonatomic, strong)  UISearchController       *searchController;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *searchViewContainer;
@end

@implementation DUVOHJNConversationSearchTableVC
- (void)initSearchUIAndTableView {
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    
    if (@available(iOS 9.1, *)) {
        self.searchController.obscuresBackgroundDuringPresentation = NO;
    }
    
    if (@available(iOS 13, *)) {
        self.searchController.searchBar.searchBarStyle = UISearchBarStyleDefault;
        self.searchController.searchBar.searchTextField.backgroundColor = [AIOIUEHConfigManager globalManager].naviBackgroudColor;
        UIImage* searchBarBg = [UIImage imageWithColor:RGBCOLOR(246.0, 246.0, 246.0) size:CGSizeMake(self.view.frame.size.width - 8 * 2, 36) cornerRadius:4];
        [self.searchController.searchBar setSearchFieldBackgroundImage:searchBarBg forState:UIControlStateNormal];
    } else {
        [self.searchController.searchBar setValue:WFCString(@"Cancel") forKey:@"_cancelButtonText"];
    }
    
    self.searchController.searchBar.placeholder = WFCString(@"Search");
    
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = _searchController;
        self.navigationItem.hidesSearchBarWhenScrolling = NO;
        _searchController.hidesNavigationBarDuringPresentation = YES;
    } else {
        self.tableView.tableHeaderView = _searchController.searchBar;
    }
    
    self.definesPresentationContext = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.messages = [[NSMutableArray alloc] init];
    [self initSearchUIAndTableView];

    self.extendedLayoutIncludesOpaqueBars = YES;
    [self.searchController.searchBar setText:self.keyword];
    self.searchController.active = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    DUVOHJNConversationSearchTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[DUVOHJNConversationSearchTVCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    WFCCMessage *msg = [self.messages objectAtIndex:indexPath.row];
    cell.keyword = self.keyword;
    cell.message = msg;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 68;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 40)];
    UIImageView *trewqPortraitView = [[UIImageView alloc] initWithFrame:CGRectMake(4, 4, 32, 32)];
    trewqPortraitView.layer.cornerRadius = 16.f;
    trewqPortraitView.layer.masksToBounds = YES;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(40, 0, self.tableView.frame.size.width, 40)];
    
    label.font = [UIFont boldSystemFontOfSize:18];
    label.textColor = [UIColor blackColor];
    label.textAlignment = NSTextAlignmentLeft;
    header.backgroundColor = [AIOIUEHConfigManager globalManager].backgroudColor;
    if (self.conversation.type == Single_Type) {
        WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:self.conversation.target];
        [trewqPortraitView sd_setImageWithURL:[NSURL URLWithString:[userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[AIOIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                                      context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
        label.text = [NSString stringWithFormat:@"\"%@\"的聊天记录", userInfo.displayName];
    } else if (self.conversation.type == Group_Type) {
        WFCCGroupInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:self.conversation.target refresh:NO];
        [trewqPortraitView sd_setImageWithURL:[NSURL URLWithString:[groupInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[AIOIUEHImage imageNamed:@"GroupChatRound"] options:SDWebImageScaleDownLargeImages
                                      context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
        label.text = [NSString stringWithFormat:@"\"%@\"的聊天记录", groupInfo.displayName];
    } else if(self.conversation.type == Channel_Type) {
        WFCCChannelInfo *channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:self.conversation.target refresh:NO];
        [trewqPortraitView sd_setImageWithURL:[NSURL URLWithString:[channelInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[AIOIUEHImage imageNamed:@"GroupChatRound"] options:SDWebImageScaleDownLargeImages
                                      context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
        label.text = [NSString stringWithFormat:@"\"%@\"的聊天记录", channelInfo.name];
    } else if(self.conversation.type == SecretChat_Type) {
        NSString *userId = [[WFCCIMService sharedWFCIMService] getSecretChatInfo:self.conversation.target].userId;
        
        WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:userId];
        [trewqPortraitView sd_setImageWithURL:[NSURL URLWithString:[userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[AIOIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                                      context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
        label.text = [NSString stringWithFormat:@"\"%@\"的聊天记录", userInfo.displayName];
    }
    
    [header addSubview:label];
    [header addSubview:trewqPortraitView];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AIOIUEHMessageListVC *mvc = [[AIOIUEHMessageListVC alloc] init];
    
    mvc.conversation = self.messages[indexPath.row].conversation;
    mvc.highlightMessageId = self.messages[indexPath.row].messageId;
    mvc.highlightText = self.keyword;
    mvc.multiSelecting = self.messageSelecting;
    mvc.selectedMessageIds = self.selectedMessageIds;
    [self.navigationController pushViewController:mvc animated:YES];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.searchController.active) {
        [self.searchController.searchBar resignFirstResponder];
    }
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
    _searchController = nil;
}

#pragma mark - UISearchControllerDelegate
-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = [self.searchController.searchBar text];
    if (searchString.length) {
        self.messages = [[[WFCCIMService sharedWFCIMService] searchMessage:self.conversation keyword:searchString order:YES limit:100 offset:0 withUser:nil] mutableCopy];
        self.keyword = searchString;
    } else {
        [self.messages removeAllObjects];
    }
    
    //刷新表格
    [self.tableView reloadData];
}
@end
