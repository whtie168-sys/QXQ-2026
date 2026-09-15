//
//  WFCSelectedUserInfo.h
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/5.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <WFChatClient/WFCCUserInfo.h>
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SelectedStatusType) {
    Disable_Checked,
    Unchecked,
    Checked,
    Disable_Unchecked
};
@class LUDHIOWIVOrganization;
@class LUDHIOWIVEmployee;
@interface HNWOUIDSelectModel : NSObject
@property(nonatomic, strong)WFCCUserInfo *userInfo;
@property(nonatomic, strong)LUDHIOWIVOrganization *organization;
@property(nonatomic, strong)LUDHIOWIVEmployee *employee;
@property (nonatomic, assign)SelectedStatusType selectedStatus;
@property(nonatomic, strong)NSMutableArray<NSNumber *> *paths;
@end

NS_ASSUME_NONNULL_END
