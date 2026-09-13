//
//  WFCUAppService.h
//  WFChatUIKit
//
//  Created by Heavyrain Lee on 2019/10/22.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class LUDHIOWIVOrganization;
@class LUDHIOWIVEmployee;
@class LUDHIOWIVOrgRelationship;
@class LUDHIOWIVOrganizationEx;
@class LUDHIOWIVEmployeeEx;

@protocol LUDHIOWIVOrgServiceProvider <NSObject>
- (void)getRelationship:(NSString *)employeeId
                success:(void(^)(NSArray<LUDHIOWIVOrgRelationship *> *))successBlock
                  error:(void(^)(int error_code))errorBlock;

- (void)getRootOrganization:(void(^)(NSArray<LUDHIOWIVOrganization *> *))successBlock
                  error:(void(^)(int error_code))errorBlock;

- (void)getOrganizationEx:(NSInteger)organizationId
                    success:(void(^)(LUDHIOWIVOrganizationEx *path))successBlock
                  error:(void(^)(int error_code))errorBlock;

- (void)getOrganizations:(NSArray<NSNumber *> *)organizationIds
                 success:(void(^)(NSArray<LUDHIOWIVOrganization *> *organizations))successBlock
                   error:(void(^)(int error_code))errorBlock;

- (void)getBatchOrgEmployees:(NSArray<NSNumber *> *)orgIds
                success:(void(^)(NSArray<NSString *> *employeeIds))successBlock
                  error:(void(^)(int error_code))errorBlock;

- (void)getOrgEmployees:(NSInteger)orgId
                success:(void(^)(NSArray<NSString *> *employeeIds))successBlock
                  error:(void(^)(int error_code))errorBlock;

- (void)getEmployee:(NSString *)employeeId
            success:(void(^)(LUDHIOWIVEmployee *employee))successBlock
              error:(void(^)(int error_code))errorBlock;


- (void)getEmployeeEx:(NSString *)employeeId
              success:(void(^)(LUDHIOWIVEmployeeEx *employeeEx))successBlock
                error:(void(^)(int error_code))errorBlock;

- (void)searchEmployee:(NSInteger)organizationId
               keyword:(NSString *)keyword
               success:(void(^)(NSArray<LUDHIOWIVEmployee *> *employees))successBlock
                 error:(void(^)(int error_code))errorBlock;
@end

NS_ASSUME_NONNULL_END
