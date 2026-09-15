//
//  LUDHIOWIVOrganization.m
//  WFChatUIKit
//
//  Created by Rain on 2022/12/25.
//  Copyright © 2022 WildfireChat. All rights reserved.
//

#import "LUDHIOWIVOrganization.h"

@implementation LUDHIOWIVOrganization
+ (LUDHIOWIVOrganization *)fromDict:(NSDictionary *)dict {
    LUDHIOWIVOrganization *eszqscOrg = [[LUDHIOWIVOrganization alloc] init];
    eszqscOrg.organizationId = [dict[@"id"] intValue];
    eszqscOrg.parentId = [dict[@"parentId"] intValue];
    eszqscOrg.managerId = dict[@"managerId"];
    eszqscOrg.name = dict[@"name"];
    eszqscOrg.desc = dict[@"desc"];
    eszqscOrg.portraitUrl = dict[@"portraitUrl"];
    eszqscOrg.tel = dict[@"tel"];
    eszqscOrg.office = dict[@"office"];
    eszqscOrg.groupId = dict[@"groupId"];
    eszqscOrg.memberCount = [dict[@"memberCount"] intValue];
    eszqscOrg.sort = [dict[@"sort"] intValue];
    eszqscOrg.updateDt = [dict[@"updateDt"] longLongValue];
    eszqscOrg.createDt = [dict[@"createDt"] longLongValue];
    return eszqscOrg;
}

- (NSDictionary *)toDict {
    NSMutableDictionary *eszqscDict = [[NSMutableDictionary alloc] init];
    eszqscDict[@"id"] = @(self.organizationId);
    eszqscDict[@"parentId"] = @(self.parentId);
    eszqscDict[@"managerId"] = self.managerId;
    eszqscDict[@"name"] = self.name;
    eszqscDict[@"desc"] = self.desc;
    eszqscDict[@"portraitUrl"] = self.portraitUrl;
    eszqscDict[@"tel"] = self.tel;
    eszqscDict[@"office"] = self.office;
    eszqscDict[@"groupId"] = self.groupId;
    eszqscDict[@"memberCount"] = @(self.memberCount);
    eszqscDict[@"sort"] = @(self.sort);
    eszqscDict[@"updateDt"] = @(self.updateDt);
    eszqscDict[@"createDt"] = @(self.createDt);
    return eszqscDict;
}
@end
