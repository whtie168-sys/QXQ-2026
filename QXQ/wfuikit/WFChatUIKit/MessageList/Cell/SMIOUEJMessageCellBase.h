//
//  MessageCellBase.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AIOIUEHMessageModel.h"

@class SMIOUEJMessageCellBase;

@protocol SMIOUEJMessageCellDelegate <NSObject>
- (void)didTapMessageCell:(SMIOUEJMessageCellBase *)cell withModel:(AIOIUEHMessageModel *)model;
- (void)didTapMessagePortrait:(SMIOUEJMessageCellBase *)cell withModel:(AIOIUEHMessageModel *)model;
- (void)didLongPressMessageCell:(SMIOUEJMessageCellBase *)cell withModel:(AIOIUEHMessageModel *)model;
- (void)didLongPressMessagePortrait:(SMIOUEJMessageCellBase *)cell withModel:(AIOIUEHMessageModel *)model;
- (void)didTapResendBtn:(AIOIUEHMessageModel *)model;

- (void)didSelectUrl:(SMIOUEJMessageCellBase *)cell withModel:(AIOIUEHMessageModel *)model withUrl:(NSString *)urlString;
- (void)didSelectPhoneNumber:(SMIOUEJMessageCellBase *)cell withModel:(AIOIUEHMessageModel *)model withPhoneNumber:(NSString *)phoneNumber;
- (void)reeditRecalledMessage:(SMIOUEJMessageCellBase *)cell withModel:(AIOIUEHMessageModel *)model;

@optional
- (void)didTapReceiptView:(SMIOUEJMessageCellBase *)cell withModel:(AIOIUEHMessageModel *)model;
- (void)didDoubleTapMessageCell:(SMIOUEJMessageCellBase *)cell withModel:(AIOIUEHMessageModel *)model;
- (void)didTaptzboeuQuoteLabel:(SMIOUEJMessageCellBase *)cell withModel:(AIOIUEHMessageModel *)model;
- (void)didTapArticleCell:(SMIOUEJMessageCellBase *)cell withModel:(AIOIUEHMessageModel *)model withArticle:(WFCCArticle *)article;
@end

@interface SMIOUEJMessageCellBase : UICollectionViewCell
@property (nonatomic, strong)UILabel *timeLabel;
@property (nonatomic, strong)UIView *lastReadContainerView;
@property (nonatomic, strong)AIOIUEHMessageModel *model;
@property (nonatomic, weak)id<SMIOUEJMessageCellDelegate> delegate;
+ (CGSize)sizeForCell:(AIOIUEHMessageModel *)msgModel withViewWidth:(CGFloat)width;
+ (CGFloat)hightForHeaderArea:(AIOIUEHMessageModel *)msgModel;

- (void)onTaped:(id)sender;
- (void)onLongPressed:(id)sender;
@end
