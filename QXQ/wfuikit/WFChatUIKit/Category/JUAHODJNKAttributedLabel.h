//
//  UILabel+LinkUrl.h
//  WUHOIBDK
//
//  Created by heavyrain.lee on 2018/5/15.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol JUAHODJNKAttributedLabelDelegate <NSObject>
@optional
- (void)didSelectUrl:(NSString *)urlString;
- (void)didSelectPhoneNumber:(NSString *)phoneNumberString;
@end

@interface JUAHODJNKAttributedLabel : UILabel
@property(nonatomic, weak)id<JUAHODJNKAttributedLabelDelegate> attributedLabelDelegate;
- (void)setText:(NSString *)text;
@end
