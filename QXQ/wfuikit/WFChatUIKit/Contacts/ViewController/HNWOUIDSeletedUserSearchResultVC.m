//
//  HNWOUIDSeletedUserSearchResultVC.m
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/4.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "HNWOUIDSeletedUserSearchResultVC.h"
#import "HNWOUIDSelectedUserTVCell.h"
#import "HNWOUIDUserSectionKeySupport.h"
#import "UIFont+YH.h"
#import "UIColor+YH.h"
#import "AIOIUEHConfigManager.h"
#import "QOEUAPinyinUtility.h"
#import "LUDHIOWIVEmployee.h"


@interface HNWOUIDSeletedUserSearchResultVC ()<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
@property (nonatomic, strong)UISearchBar *searchBar;
@property (nonatomic, strong)NSArray *results;
@end

@implementation HNWOUIDSeletedUserSearchResultVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.results = [NSMutableArray new];
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width - 16 * 2,44)];
    self.searchBar.backgroundColor = [UIColor clearColor];
    self.searchBar.placeholder = @"Search";
    
    self.view.backgroundColor = [AIOIUEHConfigManager globalManager].backgroudColor;
    self.tableView.backgroundColor = [AIOIUEHConfigManager globalManager].backgroudColor;

    for (UIView *sView in self.searchBar.subviews[0].subviews) {
        if([sView isKindOfClass:NSClassFromString(@"UISearchBarBackground")]){
            [sView removeFromSuperview];
        }
    }
    self.searchBar.delegate = self;
    [self.searchBar becomeFirstResponder];
    self.searchBar.showsCancelButton = YES;
    self.navigationItem.titleView = self.searchBar;
    [self.view addSubview:self.tableView];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchString {
    if(self.organizationId) {
        if(searchString.length) {
            __weak typeof(self)ws = self;
            [[AIOIUEHConfigManager globalManager].orgServiceProvider searchEmployee:self.organizationId keyword:searchString success:^(NSArray<LUDHIOWIVEmployee *> * _Nonnull employees) {
                NSMutableArray *arr = [[NSMutableArray alloc] init];
                [employees enumerateObjectsUsingBlock:^(LUDHIOWIVEmployee * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    __block HNWOUIDSelectModel *model = [[HNWOUIDSelectModel alloc] init];
                    model.selectedStatus = Unchecked;
                    model.employee = obj;
                    [ws.selectedUsers enumerateObjectsUsingBlock:^(HNWOUIDSelectModel * _Nonnull obj2, NSUInteger idx, BOOL * _Nonnull stop) {
                        if(obj2.employee.employeeId == obj.employeeId) {
                            model = obj2;
                            *stop = YES;
                        }
                    }];
                    [arr addObject:model];
                }];
                
                ws.results = arr;
                [ws.tableView reloadData];
            } error:^(int error_code) {
                
            }];
        } else {
            self.results = @[];
        }
    } else {
        // 1. 获取当前的输入模式
        if (@available(iOS 13.0, *)) {
            UITextInputMode *currentInputMode = searchBar.searchTextField.textInputMode;
            NSString *keyboardLanguage = currentInputMode.primaryLanguage;
            // 2. 判断是否是中文键盘（可能是 zh-Hans、zh-Hant 等）
            BOOL isChineseKeyboard = [keyboardLanguage hasPrefix:@"zh"];

            // 3. 获取 markedTextRange
            UITextRange *markedRange = searchBar.searchTextField.markedTextRange;
            // 4. 只有当【使用中文键盘】且【没有拼音未上屏】时才触发搜索
            if (isChineseKeyboard && markedRange != nil) {
                return;
            }
        } else {
            // Fallback on earlier versions
        }
        
        NSMutableArray <HNWOUIDSelectModel *>*searchList = [NSMutableArray new];
        QOEUAPinyinUtility *pu = [[QOEUAPinyinUtility alloc] init];
        BOOL isChinese = [pu isChinese:searchString];
        for (HNWOUIDSelectModel *friend in self.dataSource) {
            if ([friend.userInfo.displayName.lowercaseString containsString:searchString.lowercaseString] || [friend.userInfo.alias.lowercaseString containsString:searchString.lowercaseString]) {
                [searchList addObject:friend];
            } else if(!isChinese) {
                if([pu isMatch:friend.userInfo.displayName ofPinYin:searchString] || [pu isMatch:friend.userInfo.alias ofPinYin:searchString]) {
                    [searchList addObject:friend];
                }
            }
        }
        
        self.results = searchList;
        [self sortAndRefreshWithList:searchList];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.navigationController dismissViewControllerAnimated:NO completion:nil];
}

- (void)sortAndRefreshWithList:(NSArray *)friendList {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableDictionary *resultDic = [HNWOUIDUserSectionKeySupport userSectionKeys:friendList];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.sectionDictionary = resultDic[@"infoDic"];
            self.sectionKeys = resultDic[@"allKeys"];
            [self.tableView reloadData];
        });
    });
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.needSection && !self.organizationId) {
        return self.sectionKeys.count;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.needSection && !self.organizationId) {
        NSString *key = self.sectionKeys[section];
        NSArray *users = self.sectionDictionary[key];
        return users.count;
    } else {
        return self.results.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HNWOUIDSelectedUserTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"selectedUserT"];
    
    if (self.needSection && !self.organizationId) {
        NSString *key = self.sectionKeys[indexPath.section];
        NSArray *users = self.sectionDictionary[key];
        cell.selectedObject = users[indexPath.row];
    } else {
        cell.selectedObject = self.results[indexPath.row];
    }

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (self.needSection && !self.organizationId) {
        cell.separatorInset = UIEdgeInsetsMake(0, 60, 0, 0);
    } else {
        cell.separatorInset = UIEdgeInsetsMake(0, 16, 0, 16);
//        cell.backgroundColor = [UIColor colorWithHexString:@"0x1f2026"];
//        cell.tzboeuNameLabel.textColor = [UIColor whiteColor];
    }
  
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.needSection && !self.organizationId) {
        return 30;
    } else {
        return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (self.needSection && !self.organizationId) {
        NSString *title = self.sectionKeys[section];
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
        view.backgroundColor = [UIColor colorWithHexString:@"0xededed"];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, self.view.frame.size.width, 30)];
        label.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:13];
        label.textColor = [UIColor colorWithHexString:@"0x828282"];
        label.textAlignment = NSTextAlignmentLeft;
        label.text = [NSString stringWithFormat:@"%@", title];
        [view addSubview:label];
        return view;
    } else {
        return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    HNWOUIDSelectModel *user = nil;
    if (!self.needSection || self.organizationId) {
        user = self.results[indexPath.row];
        self.selectedUserBlock(user);
     }  else {
        NSString *key = self.sectionKeys[indexPath.section];
        NSArray *users = self.sectionDictionary[key];
        user = users[indexPath.row];
        self.selectedUserBlock(user);
    }
    
    [self.tableView reloadData];
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        if (@available(iOS 15, *)) {
            _tableView.sectionHeaderTopPadding = 0;
        }
        [_tableView registerClass:[HNWOUIDSelectedUserTVCell class] forCellReuseIdentifier:@"selectedUserT"];
        _tableView.tableFooterView = [UIView new];
    }
    return _tableView;
}
@end
