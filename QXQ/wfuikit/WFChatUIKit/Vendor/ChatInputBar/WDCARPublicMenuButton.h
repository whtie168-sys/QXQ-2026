//
//  WDCARPublicMenuButton.h
//  WFChatUIKit
//
//  Created by Rain on 2022/8/11.
//  Copyright © 2022 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFChatClient/WFCChatClient.h>

NS_ASSUME_NONNULL_BEGIN
@class WDCARPublicMenuButton;
@protocol WDCARPublicMenuButtonDelegate <NSObject>
- (void)didTapButton:(WDCARPublicMenuButton *)button menu:(WFCCChannelMenu *)channelMenu;
@end

@interface WDCARPublicMenuButton : UIButton
@property (nonatomic, strong)id<WDCARPublicMenuButtonDelegate> delegate;
- (void)setChannelMenu:(WFCCChannelMenu *)channelMenu isSubMenu:(BOOL)isSubMenu;


@property(nonatomic, assign)BOOL expended;
@property(nonatomic, strong)WFCCChannelMenu *channelMenu;
@end

NS_ASSUME_NONNULL_END
