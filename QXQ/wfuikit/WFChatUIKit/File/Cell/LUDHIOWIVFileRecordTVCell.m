//
//  FileRecordTableViewCell.m
//  WFChatUIKit
//
//  Created by dali on 2020/10/29.
//  Copyright © 2020 Wildfirechat. All rights reserved.
//

#import "LUDHIOWIVFileRecordTVCell.h"
#import <WFChatClient/WFCChatClient.h>
#import "AIOIUEHUtilities.h"


@interface LUDHIOWIVFileRecordTVCell ()
@property(nonatomic, strong)UIImageView *iconView;
@property(nonatomic, strong)UILabel *tzboeuNameLabel;
@property(nonatomic, strong)UILabel *tzboeuAsdfgInfoLabel;
@end

@implementation LUDHIOWIVFileRecordTVCell

+ (CGFloat)sizeOfRecord:(WFCCFileRecord *)record withCellWidth:(CGFloat)width {
    CGSize size1 = [AIOIUEHUtilities getTextDrawingSize:record.name font:[UIFont systemFontOfSize:18] constrainedSize:CGSizeMake(width - 74, 48)];
    
    NSString *info = [NSString stringWithFormat:@"%@ 来自%@ %@", [AIOIUEHUtilities formatTimeLabel:record.timestamp], [[WFCCUserDB sharedManager] getUserInfo:record.userId inGroup:record.conversation.type == Group_Type ? record.conversation.target : nil].displayName, [AIOIUEHUtilities formatSizeLable:record.size]];
    
    
    CGSize size2 = [AIOIUEHUtilities getTextDrawingSize:info font:[UIFont systemFontOfSize:14] constrainedSize:CGSizeMake(width - 74, 40)];
    
    return 8 + size1.height + 8 + size2.height + 8;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
}

- (void)setFileIcon:(NSString *)fileName {
    NSString *ext = [[fileName pathExtension] lowercaseString];
    self.iconView.image = [AIOIUEHUtilities imageForExt:ext];
}

- (void)setFileRecord:(WFCCFileRecord *)fileRecord {
    _fileRecord = fileRecord;
    
    [self setFileIcon:fileRecord.name];
    self.tzboeuNameLabel.text = self.fileRecord.name;
    CGSize size = [AIOIUEHUtilities getTextDrawingSize:self.fileRecord.name font:[UIFont systemFontOfSize:18] constrainedSize:CGSizeMake([UIScreen mainScreen].bounds.size.width - 74, 48)];
    self.tzboeuNameLabel.frame = CGRectMake(66, 8, size.width, size.height);
    
    NSString *sender = [[WFCCUserDB sharedManager] getUserInfo:fileRecord.userId inGroup:fileRecord.conversation.type == Group_Type ? fileRecord.conversation.target : nil].displayName;
    if(!sender.length) {
        sender = fileRecord.userId;
    }
    
    NSString *info = [NSString stringWithFormat:@"%@ 来自", [AIOIUEHUtilities formatTimeLabel:fileRecord.timestamp]];
    
    NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:info];
    [attStr appendAttributedString:[[NSAttributedString alloc] initWithString:sender attributes:@{NSForegroundColorAttributeName : [UIColor blueColor]}]];
    [attStr appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", [AIOIUEHUtilities formatSizeLable:fileRecord.size]]]];
    
    self.tzboeuAsdfgInfoLabel.attributedText = attStr;
    
    size = [AIOIUEHUtilities getTextDrawingSize:attStr.string font:[UIFont systemFontOfSize:14] constrainedSize:CGSizeMake(self.bounds.size.width - 74, 40)];
    self.tzboeuAsdfgInfoLabel.frame = CGRectMake(66, self.tzboeuNameLabel.frame.origin.y + self.tzboeuNameLabel.frame.size.height + 8, size.width, size.height);
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    
}

- (UIImageView *)iconView {
    if (!_iconView) {
        _iconView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 8, 50, 50)];
        [self.contentView addSubview:_iconView];
    }
    return _iconView;;
}

- (UILabel *)tzboeuNameLabel {
    if (!_tzboeuNameLabel) {
        _tzboeuNameLabel = [[UILabel alloc] init];
        _tzboeuNameLabel.font = [UIFont systemFontOfSize:18];
        _tzboeuNameLabel.numberOfLines = 0;
        [self.contentView addSubview:_tzboeuNameLabel];
    }
    return _tzboeuNameLabel;
}

- (UILabel *)tzboeuAsdfgInfoLabel {
    if (!_tzboeuAsdfgInfoLabel) {
        _tzboeuAsdfgInfoLabel = [[UILabel alloc] init];
        _tzboeuAsdfgInfoLabel.font = [UIFont systemFontOfSize:14];
        _tzboeuAsdfgInfoLabel.numberOfLines = 0;
        _tzboeuAsdfgInfoLabel.textColor = [UIColor grayColor];
        [self.contentView addSubview:_tzboeuAsdfgInfoLabel];
    }
    return _tzboeuAsdfgInfoLabel;
}
@end
