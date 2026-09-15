//
//  PIUODJNUpdatedVersionPopView.h
//  WUHOIBDK
//
//  Created by Ruby on 1/5/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PIUODJNUpdatedVersionPopView : UIView

@property (nonatomic, assign) BOOL isForce;
- (void)showVersion:(NSString *)version info:(NSString *)info download:(NSString *)download;

@end

NS_ASSUME_NONNULL_END
