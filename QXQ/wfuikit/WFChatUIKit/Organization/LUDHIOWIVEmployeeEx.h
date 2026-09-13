//
//  LUDHIOWIVEmployeeEx.h
//  WFChatUIKit
//
//  Created by Rain on 2022/12/29.
//  Copyright © 2022 Wildfire Chat. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LUDHIOWIVEmployee;
@class LUDHIOWIVOrgRelationship;
NS_ASSUME_NONNULL_BEGIN

@interface LUDHIOWIVEmployeeEx : NSObject
@property(nonatomic, strong)NSString *employeeId;
@property(nonatomic, strong)LUDHIOWIVEmployee *employee;
@property(nonatomic, strong)NSArray<LUDHIOWIVOrgRelationship *> *relationships;
@end

NS_ASSUME_NONNULL_END
