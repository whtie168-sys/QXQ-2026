//
//  SRIMService.m
//  WFChatClient
//
//  Created by wtb on 2025/8/14.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "SRIMService.h"
#import "SRIMNetworkService.h"

@implementation SRIMService

+ (instancetype)sharedSRIMService {
    static SRIMService *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s=[SRIMService new]; });
    return s;
}

- (instancetype)init {
    if (self=[super init]) {
//        _net=[SRIMNetworkService sharedInstance];
//        _store=[NSMutableArray array];
//        _onlineCache=[NSCache new];
//        [_net addReceiveMessageFilter:self];
    }
    return self;
}

#pragma mark - Send
- (void)sendPrivateText:(NSString *)text to:(NSString *)userId {
//    SRIMConversation *c=[SRIMConversation new]; c.type=SRIMConversationTypeSingle; c.target=userId;
//    SRIMMessage *m=[SRIMMessage new]; m.conversation=c; m.content=text; m.from=_net.userId;
//    [_net sendJSON:[m toJSON]];
//    [self cacheLocal:m];
    
}

- (void)sendGroupText:(NSString *)text toGroup:(NSString *)groupId {
//    SRIMConversation *c=[SRIMConversation new]; c.type=SRIMConversationTypeGroup; c.target=groupId;
//    SRIMMessage *m=[SRIMMessage new]; m.conversation=c; m.content=text; m.from=_net.userId;
//    [_net sendJSON:[m toJSON]];
//    [self cacheLocal:m];
}

//通知发送
- (void)sendNotifyMessage:(NSDictionary *)params
                  success:(void(^)(NSDictionary *responseDict))successBlock
                  failure:(void(^)(NSError *error))errorBlock {
    [self postRequestWithPath:@"/sendNotifyMessage" data:params success:successBlock failure:errorBlock];
}

- (void)postRequestWithPath:(NSString *)path
                       data:(NSDictionary *)data
                    success:(void(^)(NSDictionary *responseDict))successBlock
                    failure:(void(^)(NSError *error))errorBlock {
    
    // 拼接 URL
    NSString *urlString = [NSString stringWithFormat:@"%@%@", @"https://api.qqim1.app", path];
//    NSString *urlString = [NSString stringWithFormat:@"%@%@", @"https://api-qxq.im2026test.shop", path];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    // 创建 request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    
    // 设置请求头
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[SRIMNetworkService sharedInstance].getClientId
   forHTTPHeaderField:@"x-device-id"];
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedToken"];
    if (token) {
        [request setValue:token forHTTPHeaderField:@"x-auth-token"];
    }
    
    // 设置请求体 (JSON)
    if (data) {
        NSError *jsonError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&jsonError];
        if (!jsonError) {
            request.HTTPBody = jsonData;
        } else {
            if (errorBlock) {
                errorBlock(jsonError);
            }
            return;
        }
    }
    
    // 创建 session
    NSURLSession *session = [NSURLSession sharedSession];
    
    // 发起请求
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData * _Nullable responseData,
                                                                NSURLResponse * _Nullable response,
                                                                NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (errorBlock) {
                    errorBlock(error);
                }
            });
            return;
        }
        
        if (responseData) {
            NSError *jsonError = nil;
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:responseData
                                                                     options:0
                                                                       error:&jsonError];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (jsonError) {
                    if (errorBlock) {
                        errorBlock(jsonError);
                    }
                } else {
                    if (successBlock) {
                        NSLog(@"url: %@\n params: %@",request.URL.absoluteString, data);
                        successBlock(jsonDict);
                    }
                }
            });
        }
    }];
    
    [task resume];
}

//文件上传
- (void)uploadFile:(NSString *)fileName
              data:(NSData *)data
          mimeType:(NSString *)mimeType
           success:(void(^)(NSString *remoteUrl))successBlock
          progress:(void(^)(long uploaded, long total))progressBlock
              fail:(void(^)(int error_code, NSString *message))errorBlock {
    
    // 1. 生成上传地址
    NSURL *url = [NSURL URLWithString:@"https://api.qqim1.app/generateUploadFile/json"];
//    NSURL *url = [NSURL URLWithString:@"https://api-qxq.im2026test.shop/generateUploadFile/json"];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSDictionary *param = @{@"fileName": fileName ?: @""};
    NSData *body = [NSJSONSerialization dataWithJSONObject:param options:0 error:nil];
    request.HTTPBody = body;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                           completionHandler:^(NSData * _Nullable dataResp,
                                                               NSURLResponse * _Nullable response,
                                                               NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (errorBlock) errorBlock(-1, error.localizedDescription);
            });
            return;
        }
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:dataResp options:0 error:nil];
        if (![dict isKindOfClass:[NSDictionary class]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (errorBlock) errorBlock(-2, @"返回数据无效");
            });
            return;
        }
        
        if ([dict[@"code"] intValue] != 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"] ?: @"生成上传地址失败");
            });
            return;
        }
        
        NSDictionary *result = dict[@"result"];
        NSString *uploadUrl = result[@"uploadUrl"];
        NSString *remoteUrl = result[@"requestUrl"];
        
        if(uploadUrl.length == 0 || remoteUrl.length == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (errorBlock) errorBlock(-3, @"uploadUrl 或 remoteUrl 无效");
            });
            return;
        }
        
        // 2. 上传文件
        NSMutableURLRequest *uploadRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:uploadUrl]];
        uploadRequest.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        [uploadRequest setHTTPMethod:@"PUT"];
//        [uploadRequest setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
//        [uploadRequest setValue:@"image/png" forHTTPHeaderField:@"Content-Type"];
        if (mimeType) {
            [uploadRequest setValue:mimeType forHTTPHeaderField:@"Content-Type"];
        } else {
            [uploadRequest setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
        }

        NSURLSessionConfiguration *uploadConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        NSURLSession *uploadSession = [NSURLSession sessionWithConfiguration:uploadConfig
                                                                    delegate:nil
                                                               delegateQueue:[NSOperationQueue mainQueue]];
        
        NSURLSessionUploadTask *uploadTask = [uploadSession uploadTaskWithRequest:uploadRequest
                                                                         fromData:data
                                                                completionHandler:^(NSData * _Nullable respData,
                                                                                    NSURLResponse * _Nullable resp,
                                                                                    NSError * _Nullable uploadError) {
            if(uploadError) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (errorBlock) errorBlock(-500, uploadError.localizedDescription);
                });
                return;
            }
            
            NSInteger statusCode = ((NSHTTPURLResponse *)resp).statusCode;
            if(statusCode != 200) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (errorBlock) errorBlock((int)statusCode, @"上传失败");
                });
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if(successBlock) successBlock(remoteUrl);
            });
        }];
        [uploadTask resume];
    }];
    
    [task resume];
}


@end
