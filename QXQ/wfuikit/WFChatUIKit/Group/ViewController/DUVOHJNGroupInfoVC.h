//
//  GroupInfoViewController.h
//  WUHOIBDK
//
//  Created by heavyrain lee on 2019/3/3.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LUDHIOWIVEnum.h"
NS_ASSUME_NONNULL_BEGIN

@interface DUVOHJNGroupInfoVC : UIViewController
@property(nonatomic, strong)NSString *groupId;

@property (nonatomic, assign)WFCUGroupMemberSourceType sourceType;
@property (nonatomic, strong)NSString *sourceTargetId;
@end

NS_ASSUME_NONNULL_END
