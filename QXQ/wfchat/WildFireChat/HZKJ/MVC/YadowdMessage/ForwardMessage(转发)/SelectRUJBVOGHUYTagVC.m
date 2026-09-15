//
//  SelectRUJBVOGHUYTagVC.m
//  WildFireChat
//
//  Created by OpenAI on 2026/04/02.
//

#import "SelectRUJBVOGHUYTagVC.h"

#import "TagTableViewCell.h"
#import "AppService.h"
#import "MBProgressHUD.h"
#import "SVProgressHUD.h"

@interface SelectRUJBVOGHUYTagVC () <UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchControllerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSMutableArray<WFCCUserTag *> *tags;
@property (nonatomic, strong) NSMutableArray<WFCCUserTag *> *filteredTags;
@property (nonatomic, strong) NSMutableArray<WFCCUserTag *> *selectedTags;
@property (nonatomic, strong) UIScrollView *headView;

@end

@implementation SelectRUJBVOGHUYTagVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.navigationItem.title = LLLLLL(@"Biaoqian_import_tag_picker_title");

    self.tags = [NSMutableArray array];
    self.filteredTags = [NSMutableArray array];
    self.selectedTags = [NSMutableArray array];

    [self setupTableView];
    [self setupSearchController];
    [self setRightNavi];
    [self refreshList];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = UIColor.whiteColor;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView registerClass:[TagTableViewCell class] forCellReuseIdentifier:@"TagTableViewCell"];
    [self.view addSubview:self.tableView];
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    self.headView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 70)];
    self.tableView.tableHeaderView = self.headView;
}

- (void)setupSearchController {
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.delegate = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    [self.searchController.searchBar setPlaceholder:LLLLLL(@"Search")];

    if (@available(iOS 13, *)) {
        UIImage *searchBarBg = [UIImage imageWithColor:RGBA(0xF6F6F6) size:CGSizeMake(WIDTH - 15 * 2, 36) cornerRadius:10];
        [self.searchController.searchBar setSearchFieldBackgroundImage:searchBarBg forState:UIControlStateNormal];
    }

    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = self.searchController;
        self.navigationItem.hidesSearchBarWhenScrolling = NO;
        self.searchController.hidesNavigationBarDuringPresentation = YES;
    } else {
        self.tableView.tableHeaderView = self.searchController.searchBar;
    }
    self.definesPresentationContext = YES;
}

- (void)refreshList {
    __weak typeof(self) weakSelf = self;
    [[AppService sharedAppService] friendTagList:^(NSArray<WFCCUserTag *> * _Nonnull tags) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.tags removeAllObjects];
        [strongSelf.tags addObjectsFromArray:tags ?: @[]];
        [strongSelf reloadFilteredTagsWithKeyword:strongSelf.searchController.searchBar.text ?: @""];
    } error:^(int errCode, NSString * _Nonnull message) {
    }];
}

- (void)reloadFilteredTagsWithKeyword:(NSString *)keyword {
    [self.filteredTags removeAllObjects];
    NSString *lowerKeyword = keyword.lowercaseString;
    if (lowerKeyword.length == 0) {
        [self.filteredTags addObjectsFromArray:self.tags];
    } else {
        for (WFCCUserTag *tag in self.tags) {
            if ([tag.name.lowercaseString containsString:lowerKeyword]) {
                [self.filteredTags addObject:tag];
            }
        }
    }
    [self.tableView reloadData];
}

- (void)setRightNavi {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"%@(%lu)", LLLLLL(@"AlertButton"), (unsigned long)self.selectedTags.count] style:UIBarButtonItemStyleDone target:self action:@selector(sendAct)];
}

- (void)refreshSelectedHeader {
    [self.headView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    for (NSInteger i = 0; i < self.selectedTags.count; i++) {
        WFCCUserTag *tag = self.selectedTags[i];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(18 + 58 * i, 15, 48, 40)];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
        label.textColor = [UIColor colorWithWhite:0.15 alpha:1.0];
        label.layer.cornerRadius = 20;
        label.layer.masksToBounds = YES;
        label.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1.0];
        label.text = tag.name.length > 2 ? [tag.name substringToIndex:2] : tag.name;
        [self.headView addSubview:label];
    }
    self.headView.contentSize = CGSizeMake(18 + 58 * self.selectedTags.count, 0);
    [self setRightNavi];
}

- (void)sendAct {
    if (self.selectedTags.count == 0) {
        [self.view makeToast:LLLLLL(@"Biaoqian_import_tag_picker_title")];
        return;
    }

    [SVProgressHUD show];
    dispatch_group_t group = dispatch_group_create();
    NSMutableSet<NSString *> *toUserSet = [NSMutableSet set];
    __block int requestErrorCode = 0;
    __block NSString *requestErrorMessage = nil;

    for (WFCCUserTag *tag in self.selectedTags) {
        if (tag.id.length == 0) {
            continue;
        }
        dispatch_group_enter(group);
        [[AppService sharedAppService] friendTagMembersList:@{@"tagId" : tag.id} success:^(NSArray<WFCCUserInfo *> * _Nonnull friends) {
            for (WFCCUserInfo *userInfo in friends) {
                if (userInfo.userId.length > 0) {
                    [toUserSet addObject:userInfo.userId];
                }
            }
            dispatch_group_leave(group);
        } error:^(int errCode, NSString * _Nonnull message) {
            requestErrorCode = errCode;
            requestErrorMessage = message;
            dispatch_group_leave(group);
        }];
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (requestErrorCode != 0) {
            [SVProgressHUD dismiss];
            [self.view makeToast:(requestErrorMessage.length ? requestErrorMessage : LLLLLL(@"ForwardFailure")) duration:1 position:CSToastPositionCenter];
            return;
        }

        NSArray<NSString *> *toUsers = toUserSet.allObjects;
        if (toUsers.count == 0) {
            [SVProgressHUD dismiss];
            [self.view makeToast:LLLLLL(@"Biaoqian_detail_empty") duration:1 position:CSToastPositionCenter];
            return;
        }

        NSMutableArray *messageIds = [NSMutableArray array];
        if (self.message) {
            [messageIds addObject:[NSString stringWithFormat:@"%lld", self.message.messageUid]];
        } else {
            for (WFCCMessage *msg in self.messages) {
                [messageIds addObject:[NSString stringWithFormat:@"%lld", msg.messageUid]];
            }
        }

        [[AppService sharedAppService] forwardMessage:@{@"messageIds": messageIds, @"toUsers": toUsers} success:^{
            [SVProgressHUD dismiss];
            [SVProgressHUD showSuccessWithStatus:LLLLLL(@"ForwardSuccess")];
            [self.navigationController popViewControllerAnimated:YES];
        } error:^(int errCode, NSString * _Nonnull message) {
            [SVProgressHUD dismiss];
            [SVProgressHUD showSuccessWithStatus:LLLLLL(@"ForwardFailure")];
        }];
    });
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredTags.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TagTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TagTableViewCell" forIndexPath:indexPath];
    WFCCUserTag *tag = self.filteredTags[indexPath.row];
    NSString *countText = tag.memberCount.length > 0 ? [NSString stringWithFormat:@"(%@)", tag.memberCount] : @"";
    [cell configWithTitle:tag.name ?: @"" countText:countText membersText:@""];
    cell.accessoryType = [self.selectedTags containsObject:tag] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    WFCCUserTag *tag = self.filteredTags[indexPath.row];
    if ([self.selectedTags containsObject:tag]) {
        [self.selectedTags removeObject:tag];
    } else {
        [self.selectedTags addObject:tag];
    }
    [self refreshSelectedHeader];
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    [self reloadFilteredTagsWithKeyword:searchController.searchBar.text ?: @""];
}

@end
