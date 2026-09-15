//
//  WOPMKDIOFZTClearChatVC.h
//  WUHOIBDK
//
//  Created by Ruby on 12/7/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "QABWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^ClearChatDataBlock)(void);

@interface WOPMKDIOFZTClearChatVC : QABWJEFDOCYMainVC

@property (nonatomic, assign) NSInteger type; // type = 5 或者 6

@property (nonatomic, copy) ClearChatDataBlock clearBlock;

@end

NS_ASSUME_NONNULL_END
