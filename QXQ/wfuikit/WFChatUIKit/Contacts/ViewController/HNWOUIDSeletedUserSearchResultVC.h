//
//  HNWOUIDSeletedUserSearchResultVC.h
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/4.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HNWOUIDSelectModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface HNWOUIDSeletedUserSearchResultVC : UIViewController
@property (nonatomic, assign)NSInteger organizationId;
@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, assign)BOOL needSection;
@property (nonatomic, strong)NSDictionary *sectionDictionary;
@property (nonatomic, strong)NSArray *sectionKeys;
@property (nonatomic, strong)NSMutableArray <HNWOUIDSelectModel *> *dataSource;
@property (nonatomic, strong)NSMutableArray <HNWOUIDSelectModel *> *selectedUsers;
@property (nonatomic, copy) void(^ selectedUserBlock) (HNWOUIDSelectModel *user);

@end

NS_ASSUME_NONNULL_END
