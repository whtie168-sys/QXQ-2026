//
//  WFCSelectedUserInfo.m
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/5.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "HNWOUIDSelectModel.h"
#import "LUDHIOWIVOrganization.h"
#import "LUDHIOWIVEmployee.h"


@implementation HNWOUIDSelectModel
- (instancetype)init {
    self = [super init];
    if (self) {
        self.selectedStatus = Unchecked;
    }
    return self;
}
@end
