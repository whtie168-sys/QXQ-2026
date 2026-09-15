//
//  UNDJKWIOKDCommunityDetailVC.h
//  WUHOIBDK
//

#import "QABWJEFDOCYMainVC.h"

@class WFCCCommunity;

NS_ASSUME_NONNULL_BEGIN

@interface UNDJKWIOKDCommunityDetailVC : QABWJEFDOCYMainVC

@property (nonatomic, strong) WFCCCommunity *article;
@property (nonatomic, copy) NSString *currentUserId;
@property (nonatomic, copy) NSString *authorPortrait;
@property (nonatomic, copy, nullable) void(^articleDidUpdateBlock)(void);

@end

NS_ASSUME_NONNULL_END
