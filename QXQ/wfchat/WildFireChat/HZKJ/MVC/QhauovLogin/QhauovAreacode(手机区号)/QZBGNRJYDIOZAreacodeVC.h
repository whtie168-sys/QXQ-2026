//
//  QZBGNRJYDIOZAreacodeVC.h
//  WUHOIBDK
//
//  Created by Ruby on 12/29/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "QABWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^returnCountryCodeBlock) (NSString *countryName, NSString *code);

@protocol XWCountryCodeControllerDelegate <NSObject>

@optional

/**
 Delegate 回调所选国家代码
 
 @param countryName 所选国家
 @param code 所选国家代码
 */
- (void)returnCountryName:(NSString *)countryName code:(NSString *)code;

@end

@interface QZBGNRJYDIOZAreacodeVC : QABWJEFDOCYMainVC

@property (nonatomic, weak) id<XWCountryCodeControllerDelegate> deleagete;

@property (nonatomic, copy) returnCountryCodeBlock returnCountryCodeBlock;

@end

NS_ASSUME_NONNULL_END
