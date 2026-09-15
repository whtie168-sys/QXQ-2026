//
//  RUJBVOGHUYNewsFriendInfoVC.h
//  QXQ
//
//  Created by Loooooo on 10/22/23.
//

#import "QABWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^AddFriendSuccessBlock)(void);

@interface RUJBVOGHUYNewsFriendInfoVC : QABWJEFDOCYMainVC

@property (nonatomic, strong) WFCCFriendRequest *request;

@property (nonatomic, copy) AddFriendSuccessBlock successBlock;

@end

NS_ASSUME_NONNULL_END
