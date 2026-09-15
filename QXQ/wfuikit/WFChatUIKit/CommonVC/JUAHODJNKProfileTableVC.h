//
//  JUAHODJNKProfileTableVC.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/22.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LUDHIOWIVEnum.h"

@class WFCCUserInfo;
@class WFCCConversation;
@interface JUAHODJNKProfileTableVC : UIViewController
@property (nonatomic, strong)NSString *userId;
@property (nonatomic, strong)WFCCConversation *fromConversation;

@property (nonatomic, assign) BOOL isManager;

@property (nonatomic, assign)WFCUFriendSourceType sourceType;
@property (nonatomic, strong)NSString *sourceTargetId;
@end
