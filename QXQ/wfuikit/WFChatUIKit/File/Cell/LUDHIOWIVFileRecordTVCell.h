//
//  FileRecordTableViewCell.h
//  WFChatUIKit
//
//  Created by dali on 2020/10/29.
//  Copyright © 2020 Wildfirechat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class WFCCFileRecord;
@interface LUDHIOWIVFileRecordTVCell : UITableViewCell
@property(nonatomic, strong)WFCCFileRecord *fileRecord;

+ (CGFloat)sizeOfRecord:(WFCCFileRecord *)record withCellWidth:(CGFloat)width;
@end

NS_ASSUME_NONNULL_END
