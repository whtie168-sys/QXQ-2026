//
//  YUBWOIJWDConversationSearchVC.h
//  WUHOIBDK
//
//  Created by Ruby on 12/19/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "QABWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface YUBWOIJWDConversationSearchVC : QABWJEFDOCYMainVC

@property(nonatomic, strong)WFCCConversation *conversation;
@property(nonatomic, strong)NSString *keyword;

@property(nonatomic, assign)BOOL messageSelecting;
@property(nonatomic, strong)NSMutableArray *selectedMessageIds;

@end

NS_ASSUME_NONNULL_END
