//
//  LUDHIOWIVOrganizationPath.h
//  WFChatUIKit
//
//  Created by Rain on 2022/12/29.
//  Copyright © 2022 Wildfire Chat. All rights reserved.
//

#import <Foundation/Foundation.h>
@class LUDHIOWIVOrganization;
@class LUDHIOWIVEmployee;

NS_ASSUME_NONNULL_BEGIN

@interface LUDHIOWIVOrganizationEx : NSObject
@property (nonatomic, assign)NSInteger organizationId;
@property(nonatomic, strong)LUDHIOWIVOrganization *organization;
@property(nonatomic, strong)NSArray<LUDHIOWIVOrganization *> *subOrganizations;
@property(nonatomic, strong)NSArray<LUDHIOWIVEmployee *> *employees;
@end

NS_ASSUME_NONNULL_END
