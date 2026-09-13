//
//  WOPMKDIOFZTChatBackgroundSetVC.h
//  WUHOIBDK
//
//  Created by Loooooo on 8/12/24.
//

#import "QABWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface WOPMKDIOFZTChatBackgroundSetVC : QABWJEFDOCYMainVC

@property(nonatomic, copy)void (^chatBackgroundSet)(float waxiouvAlpha, NSInteger waxiouvBgColorIndex);

@property (nonatomic, assign) NSInteger waxiouvBubbleColorIndex; // kAppearanceBubbleColor 气泡颜色的索引
@property (nonatomic, assign) NSInteger waxiouvChatBgImgIndex; // kAppearanceChatBackgroundImg 聊天背景图片索引

@property (nonatomic, assign) float waxiouvAlpha;
@property (nonatomic, assign) NSInteger waxiouvBgColorIndex;
@end

NS_ASSUME_NONNULL_END
