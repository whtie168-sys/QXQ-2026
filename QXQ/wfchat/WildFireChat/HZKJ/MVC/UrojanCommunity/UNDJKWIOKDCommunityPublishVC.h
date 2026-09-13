//
//  UNDJKWIOKDCommunityPublishVC.h
//  WUHOIBDK
//

#import "QABWJEFDOCYMainVC.h"
@class WFCCCommunity;

NS_ASSUME_NONNULL_BEGIN

@interface UNDJKWIOKDCommunityPublishVC : QABWJEFDOCYMainVC

@property (nonatomic, copy, nullable) void(^publishSuccessBlock)(void);
@property (nonatomic, strong, nullable) WFCCCommunity *articleToEdit;

@end

NS_ASSUME_NONNULL_END
