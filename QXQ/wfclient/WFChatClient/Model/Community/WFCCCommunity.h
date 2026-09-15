//
//  WFCCCommunity.h
//  WFChatClient
//
//  Created by wtb on 2026/4/16.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MJExtension.h"

NS_ASSUME_NONNULL_BEGIN

@interface WFCCCommunityContent : NSObject

@property(nonatomic, strong)NSString *imageUrl;  //图
@property(nonatomic, strong)NSString *text;  //文

@end

//文章详情
@interface WFCCCommunity : NSObject

@property(nonatomic, strong)NSString *articleId; //文章id
@property(nonatomic, strong)NSString *title;     //文章标题
@property(nonatomic, strong)NSString *summary;   //文简介
@property(nonatomic, strong)NSString *cover;     //封面
@property(nonatomic, strong)NSString *linkUrl;   //文章链接
@property(nonatomic, strong)NSString *linkText;  //链接名称
@property(nonatomic, strong)NSString *authorUid;  //作者userid
@property(nonatomic, strong)NSString *authorName; //作者名称
@property(nonatomic, strong)NSString *readCount;  //阅读数
@property(nonatomic, strong)NSString *updateTime;
@property(nonatomic, strong)NSString *createTime;

@property(nonatomic, strong)NSArray <WFCCCommunityContent *>*contents;
@end


//文章列表
@interface WFCCCommunityList : NSObject

@property(nonatomic)int totalElements;
@property(nonatomic)int totalPages;
@property(nonatomic)int page;
@property(nonatomic)int size;
@property(nonatomic, strong)NSArray <WFCCCommunityContent *>*content;
@end


NS_ASSUME_NONNULL_END
