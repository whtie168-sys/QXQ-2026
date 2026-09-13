//
//  WFCCIMService.mm
//  WFChatClient
//
//  Created by heavyrain on 2017/11/5.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "WFCCIMService.h"
#import "WFCCMediaMessageContent.h"
#import <objc/runtime.h>
#import "WFCCNetworkService.h"
#import "WFCCGroupSearchInfo.h"
#import "WFCCUnknownMessageContent.h"
#import "WFCCRecallMessageContent.h"
#import "WFCCMarkUnreadMessageContent.h"
#import "wav_amr.h"
#import "WFCCUserOnlineState.h"
#import "WFAFNetworking.h"
#import "WFCCRawMessageContent.h"
#import "WFCCTextMessageContent.h"
#import "WFCCImageMessageContent.h"
#import "WFCCFileMessageContent.h"
#import "WFCCNetworkService.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <ImageIO/ImageIO.h>
#import <objc/message.h>
#import "SRIMService.h"
#import "WFCCTypingMessageContent.h"
#import "WFCCConversationDB.h"
#import "WFCCMessageContentFactory.h"
#import "WFCCVideoMessageContent.h"
#import "WFCCFileMessageContent.h"
#import "WFCCStickerMessageContent.h"
#import "JSONHelper.h"
#import "Common.h"
#import "WFCCCardMessageContent.h"
#import "WFCCCardMessageContent.h"
#import "WFCCSoundMessageContent.h"
#import "WFCCCompositeMessageContent.h"
#import "WFCCUtilities.h"

NSString *kSendingMessageStatusUpdated = @"kSendingMessageStatusUpdated";
NSString *kUploadMediaMessageProgresse = @"kUploadMediaMessageProgresse";
NSString *kConnectionStatusChanged = @"kConnectionStatusChanged";
NSString *kReceiveMessages = @"kReceiveMessages";
NSString *kRecallMessages = @"kRecallMessages";
NSString *kDeleteMessages = @"kDeleteMessages";
NSString *kMessageDelivered = @"kMessageDelivered";
NSString *kMessageReaded = @"kMessageReaded";
NSString *kMessageUpdated = @"kMessageUpdated";

static void PostSendingFailureStatus(WFCCMessage *message, int errorCode) {
    if (!message.messageId) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kSendingMessageStatusUpdated
                                                            object:@(message.messageId)
                                                          userInfo:@{
                                                              @"status": @(Message_Status_Send_Failure),
                                                              @"message": message,
                                                              @"errorCode": @(errorCode)
                                                          }];
    });
}

static NSString *WFCCUserSettingStorageKey(UserSettingScope scope, NSString *key) {
    NSString *userId = [WFCCNetworkService sharedInstance].userId ?: @"";
    return [NSString stringWithFormat:@"WFCCUserSetting_%@_%ld_%@", userId, (long)scope, key ?: @""];
}

static NSString *WFCCUserSettingStoragePrefix(UserSettingScope scope) {
    NSString *userId = [WFCCNetworkService sharedInstance].userId ?: @"";
    return [NSString stringWithFormat:@"WFCCUserSetting_%@_%ld_", userId, (long)scope];
}

static NSMutableDictionary *WFCCExtraDictionaryForContent(WFCCMessageContent *content) {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    if (content.extra.length == 0) {
        return result;
    }

    id extraObject = [JSONHelper jsonObjectFromString:content.extra];
    if ([extraObject isKindOfClass:NSDictionary.class]) {
        [result addEntriesFromDictionary:(NSDictionary *)extraObject];
    }
    return result;
}

// 从待上传文件降采样，避免完整解码大图；尺寸使用像素，不受屏幕 scale 影响。
static NSData *WFCCCreateImageMessageThumbnail(NSString *localPath, CGSize *originalSize) {
    if (localPath.length == 0) {
        return nil;
    }
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:localPath],
                                                       (__bridge CFDictionaryRef)@{(id)kCGImageSourceShouldCache: @NO});
    if (!source) {
        return nil;
    }
    NSDictionary *properties = CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, 0, NULL));
    CGFloat width = [properties[(id)kCGImagePropertyPixelWidth] doubleValue];
    CGFloat height = [properties[(id)kCGImagePropertyPixelHeight] doubleValue];
    NSInteger orientation = [properties[(id)kCGImagePropertyOrientation] integerValue];
    if (width <= 0 || height <= 0) {
        CFRelease(source);
        return nil;
    }
    NSDictionary *options = @{
        (id)kCGImageSourceCreateThumbnailFromImageAlways: @YES,
        (id)kCGImageSourceCreateThumbnailWithTransform: @YES,
        (id)kCGImageSourceThumbnailMaxPixelSize: @(MIN(200, MAX(width, height)))
    };
    CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef)options);
    CFRelease(source);
    if (!thumbnail) {
        return nil;
    }
    NSMutableData *data = [NSMutableData data];
    CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)data,
                                                                        kUTTypeJPEG, 1, NULL);
    BOOL encoded = NO;
    if (destination) {
        CGImageDestinationAddImage(destination, thumbnail,
                                  (__bridge CFDictionaryRef)@{(id)kCGImageDestinationLossyCompressionQuality: @0.8});
        encoded = CGImageDestinationFinalize(destination);
        CFRelease(destination);
    }
    CGImageRelease(thumbnail);
    if (!encoded) {
        return nil;
    }
    if (originalSize) {
        // EXIF 5–8 的显示方向交换宽高，与生成的缩略图方向保持一致。
        *originalSize = (orientation >= 5 && orientation <= 8) ? CGSizeMake(height, width) : CGSizeMake(width, height);
    }
    return data;
}

static void WFCCFailMediaMessage(WFCCMessage *message, int errorCode, void(^errorBlock)(int)) {
    message.status = Message_Status_Send_Failure;
    [[WFCCIMService sharedWFCIMService] updateMessage:message.messageId status:Message_Status_Send_Failure];
    PostSendingFailureStatus(message, errorCode);
    if (errorBlock) {
        errorBlock(errorCode);
    }
}

@interface WFCCIMService ()
@property(nonatomic, strong)NSMutableDictionary<NSNumber *, Class> *MessageContentMaps;
@property(nonatomic, assign)BOOL defaultSilentWhenPCOnline;

@property(nonatomic, strong)NSMutableDictionary<NSString *, WFCCUserOnlineState*> *useOnlineCacheMap;
@property(nonatomic, strong)NSMutableDictionary<NSString *, WFCCUserOnlineStateModel*> *useOnlineCacheMap1;

@property(nonatomic, assign)BOOL rawMessage;

//UploadModel or UploadTask
@property(nonatomic, strong)NSMutableDictionary<NSNumber *, NSObject *> *uploadingModelMap;
@end

static WFCCIMService *sharedSingleton = nil;

@implementation WFCCIMService
+ (instancetype)main { // 0308新增
    static dispatch_once_t once;
    static WFCCIMService *instance;
    dispatch_once(&once, ^{
        instance = [[WFCCIMService alloc] init];
    });
    return instance;
}
- (BOOL)isChinese {
    NSInteger language = [NSUserDefaults.standardUserDefaults integerForKey:@"CurrentLanguage"];
    if (language == 0) { // 0 跟随系统   1 中文   2 英文
        return [self systemLanguage];
    }else if (language == 1) {
        return YES;
    }else {
        return NO;
    }
}
- (BOOL)systemLanguage {
    NSArray *languages = [NSUserDefaults.standardUserDefaults objectForKey:@"AppleLanguages"];
    NSString *currentLang = [languages objectAtIndex:0];
    if ([currentLang containsString:@"zh-Hans"] || [currentLang containsString:@"zh-Hant"]) {
        return YES;
    }else {
        return NO;
    }
}
+ (WFCCIMService *)sharedWFCIMService {
    if (sharedSingleton == nil) {
        @synchronized (self) {
            if (sharedSingleton == nil) {
                sharedSingleton = [[WFCCIMService alloc] init];
                sharedSingleton.MessageContentMaps = [[NSMutableDictionary alloc] init];
                sharedSingleton.defaultSilentWhenPCOnline = YES;
                sharedSingleton.useOnlineCacheMap = [[NSMutableDictionary alloc] init];
                sharedSingleton.uploadingModelMap = [[NSMutableDictionary alloc] init];
                sharedSingleton.useOnlineCacheMap1 = [[NSMutableDictionary alloc] init];
            }
        }
    }

    return sharedSingleton;
}

- (void)useRawMessage {
    self.rawMessage = YES;
}

- (UIImage *)defaultThumbnailImage {
    if(!_defaultThumbnailImage) {
        NSData *thumbData = [[NSData alloc] initWithBase64EncodedString:@"/9j/4AAQSkZJRgABAQAAkACQAAD/4QCARXhpZgAATU0AKgAAAAgABQESAAMAAAABAAEAAAEaAAUAAAABAAAASgEbAAUAAAABAAAAUgEoAAMAAAABAAIAAIdpAAQAAAABAAAAWgAAAAAAAACQAAAAAQAAAJAAAAABAAKgAgAEAAAAAQAAAGSgAwAEAAAAAQAAAGQAAAAA/+0AOFBob3Rvc2hvcCAzLjAAOEJJTQQEAAAAAAAAOEJJTQQlAAAAAAAQ1B2M2Y8AsgTpgAmY7PhCfv/iEaxJQ0NfUFJPRklMRQABAQAAEZxhcHBsAgAAAG1udHJHUkFZWFlaIAfcAAgAFwAPAC4AD2Fjc3BBUFBMAAAAAG5vbmUAAAAAAAAAAAAAAAAAAAAAAAD21gABAAAAANMtYXBwbAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABWRlc2MAAADAAAAAeWRzY20AAAE8AAAIGmNwcnQAAAlYAAAAI3d0cHQAAAl8AAAAFGtUUkMAAAmQAAAIDGRlc2MAAAAAAAAAH0dlbmVyaWMgR3JheSBHYW1tYSAyLjIgUHJvZmlsZQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABtbHVjAAAAAAAAAB8AAAAMc2tTSwAAAC4AAAGEZGFESwAAADoAAAGyY2FFUwAAADgAAAHsdmlWTgAAAEAAAAIkcHRCUgAAAEoAAAJkdWtVQQAAACwAAAKuZnJGVQAAAD4AAALaaHVIVQAAADQAAAMYemhUVwAAABoAAANMa29LUgAAACIAAANmbmJOTwAAADoAAAOIY3NDWgAAACgAAAPCaGVJTAAAACQAAAPqcm9STwAAACoAAAQOZGVERQAAAE4AAAQ4aXRJVAAAAE4AAASGc3ZTRQAAADgAAATUemhDTgAAABoAAAUMamFKUAAAACYAAAUmZWxHUgAAACoAAAVMcHRQTwAAAFIAAAV2bmxOTAAAAEAAAAXIZXNFUwAAAEwAAAYIdGhUSAAAADIAAAZUdHJUUgAAACQAAAaGZmlGSQAAAEYAAAaqaHJIUgAAAD4AAAbwcGxQTAAAAEoAAAcuYXJFRwAAACwAAAd4cnVSVQAAADoAAAekZW5VUwAAADwAAAfeAFYBYQBlAG8AYgBlAGMAbgDhACAAcwBpAHYA4QAgAGcAYQBtAGEAIAAyACwAMgBHAGUAbgBlAHIAaQBzAGsAIABnAHIA5QAgADIALAAyACAAZwBhAG0AbQBhAC0AcAByAG8AZgBpAGwARwBhAG0AbQBhACAAZABlACAAZwByAGkAcwBvAHMAIABnAGUAbgDoAHIAaQBjAGEAIAAyAC4AMgBDHqUAdQAgAGgA7ABuAGgAIABNAOAAdQAgAHgA4QBtACAAQwBoAHUAbgBnACAARwBhAG0AbQBhACAAMgAuADIAUABlAHIAZgBpAGwAIABHAGUAbgDpAHIAaQBjAG8AIABkAGEAIABHAGEAbQBhACAAZABlACAAQwBpAG4AegBhAHMAIAAyACwAMgQXBDAEMwQwBDsETAQ9BDAAIABHAHIAYQB5AC0EMwQwBDwEMAAgADIALgAyAFAAcgBvAGYAaQBsACAAZwDpAG4A6QByAGkAcQB1AGUAIABnAHIAaQBzACAAZwBhAG0AbQBhACAAMgAsADIAwQBsAHQAYQBsAOEAbgBvAHMAIABzAHoA/AByAGsAZQAgAGcAYQBtAG0AYQAgADIALgAykBp1KHBwlo5RSV6mADIALgAygnJfaWPPj/DHfLwYACDWjMDJACCsELnIACAAMgAuADIAINUEuFzTDMd8AEcAZQBuAGUAcgBpAHMAawAgAGcAcgDlACAAZwBhAG0AbQBhACAAMgAsADIALQBwAHIAbwBmAGkAbABPAGIAZQBjAG4A4QAgAWEAZQBkAOEAIABnAGEAbQBhACAAMgAuADIF0gXQBd4F1AAgBdAF5AXVBegAIAXbBdwF3AXZACAAMgAuADIARwBhAG0AYQAgAGcAcgBpACAAZwBlAG4AZQByAGkAYwEDACAAMgAsADIAQQBsAGwAZwBlAG0AZQBpAG4AZQBzACAARwByAGEAdQBzAHQAdQBmAGUAbgAtAFAAcgBvAGYAaQBsACAARwBhAG0AbQBhACAAMgAsADIAUAByAG8AZgBpAGwAbwAgAGcAcgBpAGcAaQBvACAAZwBlAG4AZQByAGkAYwBvACAAZABlAGwAbABhACAAZwBhAG0AbQBhACAAMgAsADIARwBlAG4AZQByAGkAcwBrACAAZwByAOUAIAAyACwAMgAgAGcAYQBtAG0AYQBwAHIAbwBmAGkAbGZukBpwcF6mfPtlcAAyAC4AMmPPj/Blh072TgCCLDCwMOwwpDCsMPMw3gAgADIALgAyACAw1zDtMNUwoTCkMOsDkwO1A70DuQO6A8wAIAOTA7oDwQO5ACADkwOsA7wDvAOxACAAMgAuADIAUABlAHIAZgBpAGwAIABnAGUAbgDpAHIAaQBjAG8AIABkAGUAIABjAGkAbgB6AGUAbgB0AG8AcwAgAGQAYQAgAEcAYQBtAG0AYQAgADIALAAyAEEAbABnAGUAbQBlAGUAbgAgAGcAcgBpAGoAcwAgAGcAYQBtAG0AYQAgADIALAAyAC0AcAByAG8AZgBpAGUAbABQAGUAcgBmAGkAbAAgAGcAZQBuAOkAcgBpAGMAbwAgAGQAZQAgAGcAYQBtAG0AYQAgAGQAZQAgAGcAcgBpAHMAZQBzACAAMgAsADIOIw4xDgcOKg41DkEOAQ4hDiEOMg5ADgEOIw4iDkwOFw4xDkgOJw5EDhsAIAAyAC4AMgBHAGUAbgBlAGwAIABHAHIAaQAgAEcAYQBtAGEAIAAyACwAMgBZAGwAZQBpAG4AZQBuACAAaABhAHIAbQBhAGEAbgAgAGcAYQBtAG0AYQAgADIALAAyACAALQBwAHIAbwBmAGkAaQBsAGkARwBlAG4AZQByAGkBDQBrAGkAIABHAHIAYQB5ACAARwBhAG0AbQBhACAAMgAuADIAIABwAHIAbwBmAGkAbABVAG4AaQB3AGUAcgBzAGEAbABuAHkAIABwAHIAbwBmAGkAbAAgAHMAegBhAHIAbwFbAGMAaQAgAGcAYQBtAG0AYQAgADIALAAyBjoGJwZFBicAIAAyAC4AMgAgBkQGSAZGACAGMQZFBicGLwZKACAGOQYnBkUEHgQxBEkEMARPACAEQQQ1BEAEMARPACAEMwQwBDwEPAQwACAAMgAsADIALQQ/BEAEPgREBDgEOwRMAEcAZQBuAGUAcgBpAGMAIABHAHIAYQB5ACAARwBhAG0AbQBhACAAMgAuADIAIABQAHIAbwBmAGkAbABlAAB0ZXh0AAAAAENvcHlyaWdodCBBcHBsZSBJbmMuLCAyMDEyAABYWVogAAAAAAAA81EAAQAAAAEWzGN1cnYAAAAAAAAEAAAAAAUACgAPABQAGQAeACMAKAAtADIANwA7AEAARQBKAE8AVABZAF4AYwBoAG0AcgB3AHwAgQCGAIsAkACVAJoAnwCkAKkArgCyALcAvADBAMYAywDQANUA2wDgAOUA6wDwAPYA+wEBAQcBDQETARkBHwElASsBMgE4AT4BRQFMAVIBWQFgAWcBbgF1AXwBgwGLAZIBmgGhAakBsQG5AcEByQHRAdkB4QHpAfIB+gIDAgwCFAIdAiYCLwI4AkECSwJUAl0CZwJxAnoChAKOApgCogKsArYCwQLLAtUC4ALrAvUDAAMLAxYDIQMtAzgDQwNPA1oDZgNyA34DigOWA6IDrgO6A8cD0wPgA+wD+QQGBBMEIAQtBDsESARVBGMEcQR+BIwEmgSoBLYExATTBOEE8AT+BQ0FHAUrBToFSQVYBWcFdwWGBZYFpgW1BcUF1QXlBfYGBgYWBicGNwZIBlkGagZ7BowGnQavBsAG0QbjBvUHBwcZBysHPQdPB2EHdAeGB5kHrAe/B9IH5Qf4CAsIHwgyCEYIWghuCIIIlgiqCL4I0gjnCPsJEAklCToJTwlkCXkJjwmkCboJzwnlCfsKEQonCj0KVApqCoEKmAquCsUK3ArzCwsLIgs5C1ELaQuAC5gLsAvIC+EL+QwSDCoMQwxcDHUMjgynDMAM2QzzDQ0NJg1ADVoNdA2ODakNww3eDfgOEw4uDkkOZA5/DpsOtg7SDu4PCQ8lD0EPXg96D5YPsw/PD+wQCRAmEEMQYRB+EJsQuRDXEPURExExEU8RbRGMEaoRyRHoEgcSJhJFEmQShBKjEsMS4xMDEyMTQxNjE4MTpBPFE+UUBhQnFEkUahSLFK0UzhTwFRIVNBVWFXgVmxW9FeAWAxYmFkkWbBaPFrIW1hb6Fx0XQRdlF4kXrhfSF/cYGxhAGGUYihivGNUY+hkgGUUZaxmRGbcZ3RoEGioaURp3Gp4axRrsGxQbOxtjG4obshvaHAIcKhxSHHscoxzMHPUdHh1HHXAdmR3DHeweFh5AHmoelB6+HukfEx8+H2kflB+/H+ogFSBBIGwgmCDEIPAhHCFIIXUhoSHOIfsiJyJVIoIiryLdIwojOCNmI5QjwiPwJB8kTSR8JKsk2iUJJTglaCWXJccl9yYnJlcmhya3JugnGCdJJ3onqyfcKA0oPyhxKKIo1CkGKTgpaymdKdAqAio1KmgqmyrPKwIrNitpK50r0SwFLDksbiyiLNctDC1BLXYtqy3hLhYuTC6CLrcu7i8kL1ovkS/HL/4wNTBsMKQw2zESMUoxgjG6MfIyKjJjMpsy1DMNM0YzfzO4M/E0KzRlNJ402DUTNU01hzXCNf02NzZyNq426TckN2A3nDfXOBQ4UDiMOMg5BTlCOX85vDn5OjY6dDqyOu87LTtrO6o76DwnPGU8pDzjPSI9YT2hPeA+ID5gPqA+4D8hP2E/oj/iQCNAZECmQOdBKUFqQaxB7kIwQnJCtUL3QzpDfUPARANER0SKRM5FEkVVRZpF3kYiRmdGq0bwRzVHe0fASAVIS0iRSNdJHUljSalJ8Eo3Sn1KxEsMS1NLmkviTCpMcky6TQJNSk2TTdxOJU5uTrdPAE9JT5NP3VAnUHFQu1EGUVBRm1HmUjFSfFLHUxNTX1OqU/ZUQlSPVNtVKFV1VcJWD1ZcVqlW91dEV5JX4FgvWH1Yy1kaWWlZuFoHWlZaplr1W0VblVvlXDVchlzWXSddeF3JXhpebF69Xw9fYV+zYAVgV2CqYPxhT2GiYfViSWKcYvBjQ2OXY+tkQGSUZOllPWWSZedmPWaSZuhnPWeTZ+loP2iWaOxpQ2maafFqSGqfavdrT2una/9sV2yvbQhtYG25bhJua27Ebx5veG/RcCtwhnDgcTpxlXHwcktypnMBc11zuHQUdHB0zHUodYV14XY+dpt2+HdWd7N4EXhueMx5KnmJeed6RnqlewR7Y3vCfCF8gXzhfUF9oX4BfmJ+wn8jf4R/5YBHgKiBCoFrgc2CMIKSgvSDV4O6hB2EgITjhUeFq4YOhnKG14c7h5+IBIhpiM6JM4mZif6KZIrKizCLlov8jGOMyo0xjZiN/45mjs6PNo+ekAaQbpDWkT+RqJIRknqS45NNk7aUIJSKlPSVX5XJljSWn5cKl3WX4JhMmLiZJJmQmfyaaJrVm0Kbr5wcnImc951kndKeQJ6unx2fi5/6oGmg2KFHobaiJqKWowajdqPmpFakx6U4pammGqaLpv2nbqfgqFKoxKk3qamqHKqPqwKrdavprFys0K1ErbiuLa6hrxavi7AAsHWw6rFgsdayS7LCszizrrQltJy1E7WKtgG2ebbwt2i34LhZuNG5SrnCuju6tbsuu6e8IbybvRW9j74KvoS+/796v/XAcMDswWfB48JfwtvDWMPUxFHEzsVLxcjGRsbDx0HHv8g9yLzJOsm5yjjKt8s2y7bMNcy1zTXNtc42zrbPN8+40DnQutE80b7SP9LB00TTxtRJ1MvVTtXR1lXW2Ndc1+DYZNjo2WzZ8dp22vvbgNwF3IrdEN2W3hzeot8p36/gNuC94UThzOJT4tvjY+Pr5HPk/OWE5g3mlucf56noMui86Ubp0Opb6uXrcOv77IbtEe2c7ijutO9A78zwWPDl8XLx//KM8xnzp/Q09ML1UPXe9m32+/eK+Bn4qPk4+cf6V/rn+3f8B/yY/Sn9uv5L/tz/bf///8AACwgAZABkAQERAP/EAB8AAAEFAQEBAQEBAAAAAAAAAAABAgMEBQYHCAkKC//EALUQAAIBAwMCBAMFBQQEAAABfQECAwAEEQUSITFBBhNRYQcicRQygZGhCCNCscEVUtHwJDNicoIJChYXGBkaJSYnKCkqNDU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6g4SFhoeIiYqSk5SVlpeYmZqio6Slpqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2drh4uPk5ebn6Onq8fLz9PX29/j5+v/bAEMABwcHBwcHDAcHDBEMDAwRFxEREREXHhcXFxcXHiQeHh4eHh4kJCQkJCQkJCsrKysrKzIyMjIyODg4ODg4ODg4OP/dAAQADf/aAAgBAQAAPwD6Roooooooooooor//0PpGiiiiiiiiiiiiv//R+kaKKKKKKKKKKKK//9L6Roooooooooooor//0/pGiiiud1zxPp3h2ezj1QPHFeSGMT4/dRtjgO38O7t+vFdCCCMiloooooor/9T6RooorifHd9DaaVbW93bpdW99dw2k0cnQpKSMg9iDgg+1eSt4K0Lwnrf2DxSk02l3j4tL4TSIImPSKYKwA9mwP57fSf8AhVXgzGRBOf8At4l/+LrzqHR9Ps7nw9q9np13pU82rLA8NzLI7FFBOcMehx6fmOa+jKKKKK//1fpGiiivMfircQ2miWF3cNtjh1O2d264VSSTx7Vjv41bVAR4t0ryPDeq/uraeXqPRphn5Q/VTxjGeetcveXGuaZFaeH7TXBH4euZmS31VPneMpnbA7ggABhjdxkd8ZAvaj4i1G71nw/4d8RxeVqtnqcTMyj91PEVYCVD0we47H8QPoCiiiiv/9b6RooorlPGPhdfFulJpjXBttkyTB9gk5TOAVPBHPeuU1L4f+JNXsJNM1HxNNLbygB0+zRqCAcgZBB7Vc0jwDe2NoNH1HVPt+leWYms3to0QqehDKQQwPOeueevNcfD4L1+w8Z6VY31zPd6TZuZrGXy1cxbOfKlfhlGOAckHjA9PeqKKKK//9f6Roooooooooooor//0PpGiiiiiiiiiiiiv//R+kaKKKKKKKKKKKK//9L6Roooooooooooor//0/pGiiiiiiiiiiiiv//Z" options:NSDataBase64DecodingIgnoreUnknownCharacters];
        _defaultThumbnailImage = [UIImage imageWithData:thumbData];
    }
    return _defaultThumbnailImage;
}

- (WFCCMessage *)send:(WFCCConversation *)conversation
              content:(WFCCMessageContent *)content
              success:(void(^)(long long messageUd, long long timestamp))successBlock
                error:(void(^)(int error_code))errorBlock {
    return [self sendMedia:conversation content:content expireDuration:0 success:successBlock progress:nil error:errorBlock];
}

- (WFCCMessage *)sendMedia:(WFCCConversation *)conversation
                   content:(WFCCMessageContent *)content
                   success:(void(^)(long long messageUid, long long timestamp))successBlock
                  progress:(void(^)(long uploaded, long total))progressBlock
                     error:(void(^)(int error_code))errorBlock {
    return [self sendMedia:conversation content:content expireDuration:0 success:successBlock progress:progressBlock error:errorBlock];
}

- (WFCCMessage *)send:(WFCCConversation *)conversation
              content:(WFCCMessageContent *)content
       expireDuration:(int)expireDuration
              success:(void(^)(long long messageUid, long long timestamp))successBlock
                error:(void(^)(int error_code))errorBlock {
    return [self sendMedia:conversation content:content expireDuration:expireDuration success:successBlock progress:nil error:errorBlock];
}

- (WFCCMessage *)send:(WFCCConversation *)conversation
              content:(WFCCMessageContent *)content
               toUsers:(NSArray<NSString *> *)toUsers
       expireDuration:(int)expireDuration
              success:(void(^)(long long messageUid, long long timestamp))successBlock
                error:(void(^)(int error_code))errorBlock {
    return [self sendMedia:conversation content:content toUsers:toUsers expireDuration:expireDuration success:successBlock progress:nil error:errorBlock];
}
- (WFCCMessage *)sendMedia:(WFCCConversation *)conversation
                   content:(WFCCMessageContent *)content
            expireDuration:(int)expireDuration
                   success:(void(^)(long long messageUid, long long timestamp))successBlock
                  progress:(void(^)(long uploaded, long total))progressBlock
                     error:(void(^)(int error_code))errorBlock {
    return [self sendMedia:conversation content:content toUsers:nil expireDuration:expireDuration success:successBlock progress:progressBlock error:errorBlock];
}

- (WFCCMessage *)sendMedia:(WFCCConversation *)conversation
                   content:(WFCCMessageContent *)content
                   toUsers:(NSArray<NSString *>*)toUsers
            expireDuration:(int)expireDuration
                   success:(void(^)(long long messageUid, long long timestamp))successBlock
                  progress:(void(^)(long uploaded, long total))progressBlock
                     error:(void(^)(int error_code))errorBlock {
    return [self sendMedia:conversation content:content toUsers:toUsers expireDuration:expireDuration success:successBlock progress:progressBlock mediaUploaded:nil error:errorBlock];
    
}
 
- (WFCCMessage *)sendMedia:(WFCCConversation *)conversation
                   content:(WFCCMessageContent *)content
                   toUsers:(NSArray<NSString *> *)toUsers
            expireDuration:(int)expireDuration
                   success:(void(^)(long long messageUid, long long timestamp))successBlock
                  progress:(void(^)(long uploaded, long total))progressBlock
             mediaUploaded:(void(^)(NSString *remoteUrl))mediaUploadedBlock
                     error:(void(^)(int error_code))errorBlock {
    
    void(^uploadedBlock)(NSString *remoteUrl) = mediaUploadedBlock;
    BOOL isSendCmd = NO;
    
    if([WFCCNetworkService sharedInstance].sendLogCommand.length) {
        if ([content isKindOfClass:WFCCTextMessageContent.class]) {
            WFCCTextMessageContent *txtCnt = (WFCCTextMessageContent *)content;
            isSendCmd = [txtCnt.text isEqualToString:[WFCCNetworkService sharedInstance].sendLogCommand];
        } else if ([content isKindOfClass:WFCCRawMessageContent.class]) {
            WFCCRawMessageContent *rawCnt = (WFCCRawMessageContent *)content;
            if(rawCnt.payload.contentType == MESSAGE_CONTENT_TYPE_TEXT) {
                isSendCmd = [rawCnt.payload.searchableContent isEqualToString:[WFCCNetworkService sharedInstance].sendLogCommand];
            }
        }
    }
    
    if (isSendCmd) {
        NSString *logPath = [WFCCNetworkService getLogFilesPath].lastObject;
        if (logPath.length) {
            content = [WFCCFileMessageContent fileMessageContentFromPath:logPath];
            uploadedBlock = ^(NSString *remoteUrl) {
                if(mediaUploadedBlock) {
                    mediaUploadedBlock(remoteUrl);
                }
                [self send:conversation content:[WFCCTextMessageContent contentWith:remoteUrl]  success:nil error:nil];
            };
        } else {
            NSLog(@"log not exist");
        }
    }
    
    WFCCMessage *message = [[WFCCMessage alloc] init];
    message.conversation = conversation;
    message.content = content;
    message.toUsers = toUsers;
    message.fromUser = [WFCCNetworkService sharedInstance].userId;
    message.serverTime = [[NSDate date] timeIntervalSince1970] * 1000;
    message.status = Message_Status_Sending;
    message.localExtra = content.extra;
    
    // 2. 先存入数据库，得到本地 messageId
    if (![content isKindOfClass:WFCCTypingMessageContent.class]) {
        long long localMsgId = [[WFCCMessageDB sharedManager] insertMessage:message];
        message.messageId = localMsgId;
        NSLog(@"******************发送消息前保存数据库 messageId: %lld",localMsgId);
    }
    int type = [[content class] getContentType];
    if ([content isKindOfClass:[WFCCMediaMessageContent class]]) {
        NSString *mimeType;

        WFCCMediaMessageContent *mediaContent = (WFCCMediaMessageContent *)content;
        //视频
        if (type == MESSAGE_CONTENT_TYPE_VIDEO) {
            mediaContent = (WFCCVideoMessageContent *)content;
            mimeType = @"video/mp4";
            mediaContent = (WFCCVideoMessageContent *)content;
            UIImage * thumbnail = ((WFCCVideoMessageContent *)mediaContent).thumbnail;
            NSData *imageData = UIImageJPEGRepresentation(thumbnail, 0.5);
//            NSString *base64String = [imageData base64EncodedStringWithOptions:0];
//            NSDictionary *extraDic = @{@"thumbnail": base64String, @"duration": [NSString stringWithFormat:@"%ld", ((WFCCVideoMessageContent *)mediaContent).duration]};
//            message.localExtra = [JSONHelper jsonStringFromObject:extraDic];
            
            //先上传缩略图
            [[SRIMService sharedSRIMService] uploadFile:@"video_thumbnail.png"
                                                   data:imageData
                                               mimeType:@"image/png"
                                                success:^(NSString * _Nonnull remoteUrl) {
                
                NSMutableDictionary *extraDic = WFCCExtraDictionaryForContent(mediaContent);
                extraDic[@"thumbnail"] = remoteUrl;
                extraDic[@"duration"] = [NSString stringWithFormat:@"%ld", ((WFCCVideoMessageContent *)mediaContent).duration*1000];
                extraDic[@"width"] = [NSString stringWithFormat:@"%f", thumbnail.size.width];
                extraDic[@"height"] = [NSString stringWithFormat:@"%f", thumbnail.size.height];
                message.localExtra = [JSONHelper jsonStringFromObject:extraDic];
                
                NSLog(@"******************视频缩略图上传成功获取到的 remoteUrl: %@",remoteUrl);

                ((WFCCVideoMessageContent *)mediaContent).thumbnailUrl = remoteUrl;
                ((WFCCVideoMessageContent *)mediaContent).size = thumbnail.size;

                // 更新数据库中的消息（加上 remoteUrl）
                [[WFCCIMService sharedWFCIMService] updateMessage:message.messageId content:mediaContent];

                
                //再上传视频
                [self sendMediaMessage:message
                               content:mediaContent
                                  type:type
                              mimeType:mimeType
                               success:successBlock
                              progress:progressBlock
                         mediaUploaded:mediaUploadedBlock
                                 error:errorBlock];

            } progress:^(long uploaded, long total) {
                
            } fail:^(int error_code, NSString * _Nonnull message) {
                
            }];
        } else {
            if (type == MESSAGE_CONTENT_TYPE_FILE) {
                mediaContent = (WFCCFileMessageContent *)content;
                NSDictionary *extraDic = @{@"file_name": ((WFCCFileMessageContent *)mediaContent).name, @"file_size": [NSString stringWithFormat:@"%ld", ((WFCCFileMessageContent *)mediaContent).size]};
                message.localExtra = [JSONHelper jsonStringFromObject:extraDic];

            } else if (type == MESSAGE_CONTENT_TYPE_IMAGE) {
                [self sendImageMessage:message
                              success:successBlock
                             progress:progressBlock
                        mediaUploaded:mediaUploadedBlock
                                error:errorBlock];
                return message;
            } else if (type == MESSAGE_CONTENT_TYPE_STICKER) {
                mimeType = @"image/png";
                mediaContent = (WFCCStickerMessageContent *)content;
                NSDictionary *extraDic = @{@"width": [NSString stringWithFormat:@"%f", ((WFCCStickerMessageContent *)mediaContent).size.width], @"height": [NSString stringWithFormat:@"%f", ((WFCCStickerMessageContent *)mediaContent).size.height]};
                message.localExtra = [JSONHelper jsonStringFromObject:extraDic];
            } else if (type == MESSAGE_CONTENT_TYPE_SOUND) {
                mimeType = @"audio/amr";
                mediaContent = (WFCCSoundMessageContent *)content;
                NSDictionary *extraDic = @{@"duration": [NSString stringWithFormat:@"%ld", ((WFCCSoundMessageContent *)mediaContent).duration]};
                message.localExtra = [JSONHelper jsonStringFromObject:extraDic];
            } else if (type == MESSAGE_CONTENT_TYPE_COMPOSITE_MESSAGE) {
                mimeType = @"application/json";
                mediaContent = (WFCCCompositeMessageContent *)content;
                WFCCMediaMessagePayload *payload = (WFCCMediaMessagePayload *)[mediaContent encode];
                if (payload.remoteMediaUrl.length > 0 && mediaContent.remoteUrl.length == 0) {
                    mediaContent.remoteUrl = payload.remoteMediaUrl;
                }
                if (payload.localMediaPath.length > 0 && mediaContent.localPath.length == 0) {
                    mediaContent.localPath = payload.localMediaPath;
                }
                if (mediaContent.localPath.length == 0 && payload.binaryContent.length > 0) {
                    NSString *directory = [WFCCUtilities getDocumentPathWithComponent:@"/COMPOSITE_MESSAGE"];
                    if (![[NSFileManager defaultManager] fileExistsAtPath:directory]) {
                        [[NSFileManager defaultManager] createDirectoryAtPath:directory
                                                  withIntermediateDirectories:YES
                                                                   attributes:nil
                                                                        error:nil];
                    }
                    NSString *path = [directory stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
                    if ([payload.binaryContent writeToFile:path atomically:YES]) {
                        mediaContent.localPath = path;
                    }
                }
                if (mediaContent.localPath.length > 0 || mediaContent.remoteUrl.length > 0) {
                    [[WFCCIMService sharedWFCIMService] updateMessage:message.messageId content:mediaContent];
                }
            }
            
            [self sendMediaMessage:message
                           content:mediaContent
                              type:type
                          mimeType:mimeType
                           success:successBlock
                          progress:progressBlock
                     mediaUploaded:mediaUploadedBlock
                             error:errorBlock];
        }
    } else {
        if (![content isKindOfClass:WFCCTypingMessageContent.class]) {
            
            //名片类型组装
            if ([content isKindOfClass:WFCCCardMessageContent.class]) {
                WFCCCardMessageContent *cardCon = (WFCCCardMessageContent *)content;
                NSDictionary *extraDic = @{@"type": [NSString stringWithFormat:@"%d", (int)cardCon.type],
                                           @"targetId": cardCon.targetId,
                                           @"cardUid": cardCon.targetId,
                                           @"name": cardCon.name,
                                           @"displayName": cardCon.displayName,
                                           @"fromUser": cardCon.fromUser,
                                           @"portrait": cardCon.portrait
                };
                message.localExtra = [JSONHelper jsonStringFromObject:extraDic];
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kSendingMessageStatusUpdated object:@(-1) userInfo:@{@"status":@(Message_Status_Sending), @"message":message, @"savedTime":@(message.serverTime)}];
            });

            
            NSString *messageStr;
            //文本
            if (type == 1) {
                WFCCTextMessageContent *textContent = (WFCCTextMessageContent *)content;
                //引用
                if (textContent.quoteInfo) {
                    NSDictionary *extraDic = @{@"ref": @{@"messageUid": [NSString stringWithFormat:@"%lld", textContent.quoteInfo.messageUid],
                                                         @"userId": textContent.quoteInfo.userId,
                                                         @"userDisplayName": textContent.quoteInfo.userDisplayName,
                                                         @"messageDigest": textContent.quoteInfo.messageDigest}};
                    message.localExtra = [JSONHelper jsonStringFromObject:extraDic];
                }
                
                WFCCMessagePayload *payload = [content encode];
                messageStr = payload.searchableContent;
            }
            [self sendHttpMessage:message
                          content:messageStr
                             type:type
                        remoteUrl:@""
                          success:^(long long messageUid, long long timestamp) {
                message.messageUid = messageUid;
                [[WFCCIMService sharedWFCIMService] updateMessage:message.messageId status:Message_Status_Sent];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kSendingMessageStatusUpdated object:@(message.messageId) userInfo:@{@"status":@(Message_Status_Sent), @"messageUid":@(messageUid), @"timestamp":@(timestamp), @"message":message}];
                });
                
                if (successBlock) {
                    successBlock(messageUid,timestamp);
                }                
            } failure:^(int code, NSString *msg) {
                message.status = Message_Status_Send_Failure;
                [[WFCCIMService sharedWFCIMService] updateMessage:message.messageId status:Message_Status_Send_Failure];
                PostSendingFailureStatus(message, code);
                if (errorBlock) {
                    errorBlock(code);
                }
            }];
        }
    }
    
    return message;
}

- (void)sendImageMessage:(WFCCMessage *)message
                 success:(void(^)(long long messageUid, long long timestamp))successBlock
                progress:(void(^)(long uploaded, long total))progressBlock
           mediaUploaded:(void(^)(NSString *remoteUrl))mediaUploadedBlock
                   error:(void(^)(int error_code))errorBlock {
    WFCCImageMessageContent *imageContent = (WFCCImageMessageContent *)message.content;
    NSMutableDictionary *extra = WFCCExtraDictionaryForContent(imageContent);
    id savedExtra = message.localExtra.length ? [JSONHelper jsonObjectFromString:message.localExtra] : nil;
    if ([savedExtra isKindOfClass:NSDictionary.class]) {
        // 重发时兼容历史记录中只保存在 localExtra 的备注、引用及缩略图。
        [(NSDictionary *)savedExtra enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
            if (!extra[key]) {
                extra[key] = value;
            }
        }];
    }

    void (^sendOriginalImage)(void) = ^{
        if (imageContent.size.width > 0 && imageContent.size.height > 0) {
            extra[@"width"] = @(imageContent.size.width);
            extra[@"height"] = @(imageContent.size.height);
        }
        imageContent.extra = [JSONHelper jsonStringFromObject:extra];
        message.localExtra = imageContent.extra;
        [self setMessage:message.messageId localExtra:message.localExtra];
        [self updateMessage:message.messageId content:imageContent];
        NSString *mimeType = imageContent.localPath.pathExtension.length > 0
            ? [self mimeTypeOfFile:imageContent.localPath] : @"application/octet-stream";
        [self sendMediaMessage:message
                       content:imageContent
                          type:MESSAGE_CONTENT_TYPE_IMAGE
                      mimeType:mimeType
                       success:successBlock
                      progress:progressBlock
                 mediaUploaded:mediaUploadedBlock
                         error:errorBlock];
    };

    NSString *thumbnailUrl = [extra[@"thumbnail"] isKindOfClass:NSString.class] ? extra[@"thumbnail"] : nil;
    // 转发复用已有远程文件；重发时复用已经上传成功的缩略图。
    if (imageContent.remoteUrl.length > 0 || thumbnailUrl.length > 0) {
        sendOriginalImage();
        return;
    }
    NSString *localPath = imageContent.localPath;
    if (localPath.length == 0) {
        WFCCFailMediaMessage(message, -4, errorBlock);
        return;
    }
    if (![[NSFileManager defaultManager] isReadableFileAtPath:localPath]) {
        WFCCFailMediaMessage(message, -5, errorBlock);
        return;
    }

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        CGSize originalSize = CGSizeZero;
        NSData *thumbnailData = WFCCCreateImageMessageThumbnail(localPath, &originalSize);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (thumbnailData.length == 0) {
                WFCCFailMediaMessage(message, -6, errorBlock);
                return;
            }
            imageContent.size = originalSize;
            NSString *thumbnailName = [NSString stringWithFormat:@"%@_thumbnail.jpg", NSUUID.UUID.UUIDString];
            [[SRIMService sharedSRIMService] uploadFile:thumbnailName
                                                  data:thumbnailData
                                              mimeType:@"image/jpeg"
                                               success:^(NSString *remoteUrl) {
                if (remoteUrl.length == 0) {
                    WFCCFailMediaMessage(message, -3, errorBlock);
                    return;
                }
                extra[@"thumbnail"] = remoteUrl;
                NSLog(@"******************图片缩略图上传成功获取到的 thumbnail: %@", remoteUrl);
                // 缩略图成功后，才上传原文件并发送消息。
                sendOriginalImage();
            } progress:^(long uploaded, long total) {
                // 与视频一致，发送进度由后续原文件上传阶段报告。
            } fail:^(int errorCode, NSString *errorMessage) {
                WFCCFailMediaMessage(message, errorCode, errorBlock);
            }];
        });
    });
}

- (WFCCMessage *)sendMediaMessage:(WFCCMessage *)message
                          content:(WFCCMediaMessageContent *)mediaContent
                             type:(int)type
                         mimeType:(NSString *)mimeType
                          success:(void(^)(long long messageUid, long long timestamp))successBlock
                         progress:(void(^)(long uploaded, long total))progressBlock
                    mediaUploaded:(void(^)(NSString *remoteUrl))mediaUploadedBlock
                            error:(void(^)(int error_code))errorBlock {
    __weak typeof(self)ws = self;
    NSString *pushSummary = [mediaContent digest:message] ?: @"";

    //转发的图片/视频
    if (mediaContent.remoteUrl.length > 0) {
        [ws sendHttpMessage:message
                    content:pushSummary
                       type:type
                  remoteUrl:mediaContent.remoteUrl
                    success:^(long long messageUid, long long timestamp) {
//                            message.status = Message_Status_Sent;
            message.messageUid = messageUid;
            [[WFCCIMService sharedWFCIMService] updateMessage:message.messageId status:Message_Status_Sent];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kSendingMessageStatusUpdated object:@(message.messageId) userInfo:@{@"status":@(Message_Status_Sent), @"messageUid":@(messageUid), @"timestamp":@(timestamp), @"message":message}];
            });

            
            if (successBlock) successBlock(messageUid, timestamp);
        } failure:^(int code, NSString *msg) {
            message.status = Message_Status_Send_Failure;
            [[WFCCIMService sharedWFCIMService] updateMessage:message.messageId status:Message_Status_Send_Failure];
            PostSendingFailureStatus(message, code);
            if (errorBlock) errorBlock(code);
        }];
    } else  {
        NSString *localPath = mediaContent.localPath;
        if (localPath.length == 0) {
            WFCCFailMediaMessage(message, -4, errorBlock); // 本地路径为空
            return message;
        }
        
        NSData *fileData = [NSData dataWithContentsOfFile:localPath];
        if (!fileData) {
            WFCCFailMediaMessage(message, -5, errorBlock); // 文件读取失败
            return message;
        }
        
        NSString *fileName = [localPath lastPathComponent];
        
        // 3. 上传文件
        [[SRIMService sharedSRIMService] uploadFile:fileName
                                               data:fileData
                                           mimeType:mimeType
                                            success:^(NSString *remoteUrl) {
                        // 上传成功，回填 remoteUrl
                        mediaContent.remoteUrl = remoteUrl;
                        
                        if (mediaUploadedBlock) {
                            mediaUploadedBlock(remoteUrl);
                        }
                        
                        NSLog(@"******************图片上传成功获取到的 remoteUrl: %@",remoteUrl);

                        // 更新数据库中的消息（加上 remoteUrl）
                        [[WFCCIMService sharedWFCIMService] updateMessage:message.messageId content:mediaContent];
                        // 4. 走 sendHttpMessage 发给服务端
    //                    WFCCMediaMessagePayload *payload = [mediaContent encode];
       
                        
                        [ws sendHttpMessage:message
                                    content:pushSummary
                                       type:type
                                  remoteUrl:remoteUrl
                                    success:^(long long messageUid, long long timestamp) {
    //                            message.status = Message_Status_Sent;
                            message.messageUid = messageUid;
                            [[WFCCIMService sharedWFCIMService] updateMessage:message.messageId status:Message_Status_Sent];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [[NSNotificationCenter defaultCenter] postNotificationName:kSendingMessageStatusUpdated object:@(message.messageId) userInfo:@{@"status":@(Message_Status_Sent), @"messageUid":@(messageUid), @"timestamp":@(timestamp), @"message":message}];
                            });

                            
                            if (successBlock) successBlock(messageUid, timestamp);
                        } failure:^(int code, NSString *msg) {
                            message.status = Message_Status_Send_Failure;
                            [[WFCCIMService sharedWFCIMService] updateMessage:message.messageId status:Message_Status_Send_Failure];
                            PostSendingFailureStatus(message, code);
                            if (errorBlock) errorBlock(code);
                        }];
            
        } progress:^(long uploaded, long total) {
            if (progressBlock) progressBlock(uploaded, total);
        } fail:^(int error_code, NSString *messageStr) {
            WFCCFailMediaMessage(message, error_code, errorBlock);
        }];
    }
    
    return message;
}

/*
 
 //消息体结构
 {
 "from": "user123",             // 发送人 ID（字符串）
 "to": "user456",               // 接收人 ID（字符串）
 "uid": "msg-001",              // 消息的唯一 ID（字符串）
 "type": 0,                     // 消息类型（int）：0=文本，1=图片，2=音频，3=文件
 "message": "Hello, world!",    // 消息文本内容（type 为 0 时使用）
 "mimeType": "text/plain",      // 文件的 MIME 类型（仅在发送文件时使用）
 "remoteUrl": "https://example.com/file.png", // 文件或媒体的远程地址
 "sendTime": 1716972000000,     // 客户端发送时间（时间戳，单位：毫秒）
 "extra": "{\"font\":\"bold\"}",// 扩展字段，通常为 JSON 字符串格式（可自定义扩展信息）
 "dropTime": 0,                 // 消息丢弃时间（默认为 0，如未设置）
 "direction": 0                 // 消息方向：0=私聊 1=群聊

 */

//"type": 0, // 消息类型（int）：0=未知消息类型，1=文本消息，2=语音消息，3=图片消息 4=位置消息 5=文件消息 6=视频消息 7=贴纸消息 8=链接消息 9=私密文本消息 10=名片消息
//11=复合消息 12=富文本通知消息 13=文章消息

/*
 {
   "to": "string",
   "type": 0,
   "message": "string",
   "mimeType": "string",
   "remoteUrl": "string",
   "extra": "string",
   "dropTime": 0,
   "ref": 0,
   "mentionedType": 0
 }
  */
- (void)sendHttpMessage:(WFCCMessage *)message
                content:(NSString *)content
                   type:(int)type
              remoteUrl:(NSString *)remoteUrl
                success:(void(^)(long long messageUid, long long timestamp))successBlock
                failure:(void(^)(int code, NSString *msg))failureBlock {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if (message.conversation.target) {
        [params setObject:message.conversation.target forKey:@"to"];
    }
    if (type) {
        [params setObject:@(type) forKey:@"type"];
    }
    if (content) {
        [params setObject:content forKey:@"message"];
    }
    if (message.conversation.line) {
        [params setObject:@(message.conversation.line) forKey:@"line"];
    }
    if (message.messageId) {
        [params setObject:@(message.messageId) forKey:@"ref"];
    }
    if (message.serverTime) {
        [params setObject:@(message.serverTime) forKey:@"dropTime"];
    }
    if (remoteUrl) {
        [params setObject:remoteUrl forKey:@"remoteUrl"];
    }
    if (message.localExtra.length != 0) {
        [params setObject:message.localExtra forKey:@"extra"];
    }
    
    NSLog(@"send message: %@",params);
    NSString *urlPath = @"/sendPrivateMessage";
    if (message.conversation.type == Group_Type) {
        urlPath = @"/sendGroupMessage";
    }
    [[SRIMService sharedSRIMService] postRequestWithPath:urlPath
                                                    data:params
                                                 success:^(NSDictionary * _Nonnull responseDict) {
        NSLog(@"message: %@",responseDict);
        long long messageUid = [responseDict[@"result"][@"messageId"] longLongValue];
        long long timestamp = [responseDict[@"result"][@"timestamp"] longLongValue];
        if (responseDict[@"code"]) {
            int code = [responseDict[@"code"] intValue];
            if (code != 0) {
                message.status = Message_Status_Send_Failure;
                [[WFCCIMService sharedWFCIMService] updateMessage:message.messageId status:Message_Status_Send_Failure];
                PostSendingFailureStatus(message, code);
                if (failureBlock) {
                    failureBlock(code,responseDict[@"message"]);
                }
                return;
            }
        }
        
        NSLog(@"******************http send message successful messageId: %ld",message.messageId);

        if (successBlock) successBlock(messageUid, timestamp);

    } failure:^(NSError * _Nonnull error) {
        message.status = Message_Status_Send_Failure;
        [[WFCCIMService sharedWFCIMService] updateMessage:message.messageId status:Message_Status_Send_Failure];
        PostSendingFailureStatus(message, (int)error.code);
        if (failureBlock) {
            failureBlock(error.code, error.localizedDescription);
        }
    }];
}

- (NSString *)mimeTypeOfFile:(NSString *)filePath {
    NSString *fileExtension = [filePath pathExtension];
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExtension, NULL);
    NSString *mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
    return mimeType.length?mimeType:@"application/octet-stream";;
}

- (void)uploadQiniuData:(NSData *)data url:(NSString *)url remoteUrl:(NSString *)remoteUrl success:(void(^)(NSString *remoteUrl))successBlock
               progress:(void(^)(long uploaded, long total))progressBlock
                  error:(void(^)(int error_code))errorBlock {
    NSArray *array = [url componentsSeparatedByString:@"?"];
    url = array[0];
    NSString *token = array[1];
    NSString *key = array[2];

    WFAFHTTPSessionManager *manage = [WFAFHTTPSessionManager manager];
    [manage.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    manage.requestSerializer = [WFAFHTTPRequestSerializer serializer];
    manage.responseSerializer = [WFAFHTTPResponseSerializer serializer];
    manage.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/javascript",@"text/plain", nil];

    __weak typeof(self)ws = self;
    long messageId = [[[NSDate alloc] init] timeIntervalSince1970];
    NSURLSessionDataTask *task = [manage POST:url parameters:nil constructingBodyWithBlock:^(id<WFAFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFormData:[key dataUsingEncoding:NSUTF8StringEncoding] name:@"key"];
        [formData appendPartWithFormData:[token dataUsingEncoding:NSUTF8StringEncoding] name:@"token"];
        [formData appendPartWithFormData:data name:@"file"];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        progressBlock((int)uploadProgress.completedUnitCount, (int)uploadProgress.totalUnitCount);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [ws.uploadingModelMap removeObjectForKey:@(messageId)];
        successBlock(remoteUrl);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [ws.uploadingModelMap removeObjectForKey:@(messageId)];
        NSLog(@"error %@", error.localizedDescription);
        errorBlock(-1);
    }];
    [self.uploadingModelMap setObject:task forKey:@(messageId)];
}

- (BOOL)sendSavedMessage:(WFCCMessage *)message
          expireDuration:(int)expireDuration
                 success:(void(^)(long long messageUid, long long timestamp))successBlock
                   error:(void(^)(int error_code))errorBlock {
    if (!message || [message.content isKindOfClass:WFCCTypingMessageContent.class]) {
        return NO;
    }

    if ([message.content isKindOfClass:WFCCImageMessageContent.class]) {
        message.status = Message_Status_Sending;
        [self updateMessage:message.messageId status:Message_Status_Sending];
        [self sendImageMessage:message success:^(long long messageUid, long long timestamp) {
            message.status = Message_Status_Sent;
            message.serverTime = timestamp;
            if (successBlock) {
                successBlock(messageUid, timestamp);
            }
        } progress:nil mediaUploaded:nil error:errorBlock];
        return YES;
    }
    
    int type = [[message.content class] getContentType];
    NSString *content = @"";
    NSString *remoteUrl = @"";
    WFCCMessagePayload *payload = [message.content encode];
    if ([message.content isKindOfClass:WFCCMediaMessageContent.class]) {
        WFCCMediaMessageContent *mediaContent = (WFCCMediaMessageContent *)message.content;
        remoteUrl = mediaContent.remoteUrl ?: @"";
        content = payload.searchableContent ?: @"";
    } else {
        content = payload.searchableContent ?: payload.content ?: @"";
    }
    
    [self sendHttpMessage:message
                  content:content
                     type:type
                remoteUrl:remoteUrl
                  success:^(long long messageUid, long long timestamp) {
        message.messageUid = messageUid;
        message.serverTime = timestamp;
        message.status = Message_Status_Sent;
        [[WFCCIMService sharedWFCIMService] updateMessage:message.messageId status:Message_Status_Sent];
        if (successBlock) {
            successBlock(messageUid, timestamp);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kSendingMessageStatusUpdated
                                                            object:@(message.messageId)
                                                          userInfo:@{@"status": @(Message_Status_Sent),
                                                                     @"messageUid": @(messageUid),
                                                                     @"timestamp": @(timestamp),
                                                                     @"message": message}];
    } failure:^(int code, NSString *msg) {
        message.status = Message_Status_Send_Failure;
        [[WFCCIMService sharedWFCIMService] updateMessage:message.messageId status:Message_Status_Send_Failure];
        if (errorBlock) {
            errorBlock(code);
        }
        PostSendingFailureStatus(message, code);
    }];
    return YES;
}

- (BOOL)cancelSendingMessage:(long)messageId {
    NSObject *upload = [self.uploadingModelMap objectForKey:@(messageId)];
    if([upload isKindOfClass:[NSURLSessionDataTask class]]) {
        [self.uploadingModelMap removeObjectForKey:@(messageId)];
        NSURLSessionDataTask *task = (NSURLSessionDataTask *)upload;
        [task cancel];
        return YES;
    }
    return NO;
}

- (void)recall:(WFCCMessage *)msg
       success:(void(^)(void))successBlock
         error:(void(^)(int error_code))errorBlock {
    if (msg == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"recall msg failure, message not exist");
            if(errorBlock) {
                errorBlock(-1);
            }
        });
        return;
    }
    NSString *path = @"/recallPrivateMessage";
    if (msg.conversation.type == Group_Type) {
        path = @"/recallGroupMessage";
    }
    [[SRIMService sharedSRIMService] postRequestWithPath:path
                                                    data:@{@"messageId":@(msg.messageUid),@"to":msg.conversation.target} success:^(NSDictionary * _Nonnull responseDict) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kRecallMessages object:@(msg.messageUid)];
        });
        [[WFCCMessageDB sharedManager] deleteMessage:msg.messageId];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kDeleteMessages object:@(msg.messageUid)];
        });

        successBlock();
    } failure:^(NSError * _Nonnull error) {
        errorBlock(error.code);
    }];
    
}
- (NSArray<WFCCConversationInfo *> *)getConversationInfos:(NSArray<NSNumber *> *)conversationTypes lines:(NSArray<NSNumber *> *)lines{
    return [[WFCCConversationDB sharedManager] getConversationInfos:conversationTypes lines:lines];
}

- (WFCCConversationInfo *)getConversationInfo:(WFCCConversation *)conversation {
    return [[WFCCConversationDB sharedManager] getConversationInfo:conversation];
}

- (NSArray<WFCCMessage *> *)getMessages:(WFCCConversation *)conversation contentTypes:(NSArray<NSNumber *> *)contentTypes from:(NSUInteger)fromIndex count:(NSInteger)count withUser:(NSString *)user {
    
    return [[WFCCConversationDB sharedManager] getMessages:conversation contentTypes:contentTypes from:fromIndex count:count withUser:user];
}

- (void)getMessagesV2:(WFCCConversation *)conversation
         contentTypes:(NSArray<NSNumber *> *)contentTypes
                 from:(NSUInteger)fromIndex
                count:(NSInteger)count
             withUser:(NSString *)user
              success:(void(^)(NSArray<WFCCMessage *> *messages))successBlock
                error:(void(^)(int error_code))errorBlock {
    
    if (!conversation) {
        if (errorBlock) errorBlock(-1);
        return;
    }

    __block NSArray *messageList;
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        NSMutableString *sql = [NSMutableString stringWithString:
            @"SELECT * FROM t_message WHERE conversationType=? AND target=?"];
        NSMutableArray *args = [NSMutableArray array];
        [args addObject:@(conversation.type)];
        [args addObject:conversation.target ?: @""];

        // withUser 过滤
        if (user.length > 0) {
            [sql appendString:@" AND fromUser=?"];
            [args addObject:user];
        }
        
        // 游标过滤（只取比 fromServerTime 更早的消息）
        if (fromIndex > 0) {
            [sql appendString:@" AND serverTime < ?"];
            [args addObject:@(fromIndex)];
        }

        // 排序和分页（只按照 serverTime ASC 排序）取最近的15条数据
        [sql appendString:@" ORDER BY serverTime DESC LIMIT ?"];
        [args addObject:@(labs(count))];

        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        NSMutableArray<WFCCMessage *> *messages = [NSMutableArray array];
        while ([rs next]) {
            WFCCMessage *msg = [[WFCCMessageDB sharedManager] buildMessageFromResultSet:rs];
            // contentTypes 过滤
            if (msg) {
                if (!contentTypes || contentTypes.count == 0) {
                    [messages addObject:msg];
                } else {
                    if ([contentTypes containsObject:[NSNumber numberWithInt:[[msg.content class] getContentType]]]) {
                        [messages addObject:msg];
                    }
                }
            }
        }
        [rs close];
        messageList = messages;
    }];
    
    if (successBlock) {
        successBlock(messageList);
    }
}


- (void)getMentionedMessages:(WFCCConversation *)conversation
                        from:(NSUInteger)fromIndex
                       count:(NSInteger)count
                     success:(void(^)(NSArray<WFCCMessage *> *messages))successBlock
                       error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        successBlock(@[]);
    }
}

- (NSArray<WFCCMessage *> *)getMessages:(WFCCConversation *)conversation
                           contentTypes:(NSArray<NSNumber *> *)contentTypes
                               fromTime:(NSUInteger)fromTime
                                  count:(NSInteger)count
                               withUser:(NSString *)user {
    
    return [[WFCCMessageDB sharedManager] getMessages:conversation contentTypes:contentTypes fromTime:fromTime count:count withUser:user];
}

- (void)getMessagesV2:(WFCCConversation *)conversation
         contentTypes:(NSArray<NSNumber *> *)contentTypes
             fromTime:(NSUInteger)fromTime
                count:(NSInteger)count
             withUser:(NSString *)user
              success:(void(^)(NSArray<WFCCMessage *> *messages))successBlock
                error:(void(^)(int error_code))errorBlock {
    NSArray *messages = [self getMessages:conversation contentTypes:contentTypes fromTime:fromTime count:count withUser:user];
    if (successBlock) {
        successBlock(messages ?: @[]);
    }
}
- (NSArray<WFCCMessage *> *)getMessages:(WFCCConversation *)conversation
                          messageStatus:(NSArray<NSNumber *> *)messageStatus
                                   from:(NSUInteger)fromIndex
                                  count:(NSInteger)count
                               withUser:(NSString *)user {
    
    return [[WFCCMessageDB sharedManager] getMessages:conversation messageStatus:messageStatus from:fromIndex count:count withUser:user];
}

- (void)getMessagesV2:(WFCCConversation *)conversation
        messageStatus:(NSArray<NSNumber *> *)messageStatus
                 from:(NSUInteger)fromIndex
                count:(NSInteger)count
             withUser:(NSString *)user
              success:(void(^)(NSArray<WFCCMessage *> *messages))successBlock
                error:(void(^)(int error_code))errorBlock {
    
    if (!conversation) {
        if (errorBlock) errorBlock(-1);
        return;
    }

    [[WFCCMessageDB sharedManager] getMessagesV2:conversation messageStatus:messageStatus from:fromIndex count:count withUser:user success:^(NSArray<WFCCMessage *> * _Nonnull messages) {
        successBlock(messages);
    } error:^(int error_code) {
        errorBlock(error_code);
    }];
}
- (NSArray<WFCCMessage *> *)getMessages:(NSArray<NSNumber *> *)conversationTypes
                                           lines:(NSArray<NSNumber *> *)lines
                                    contentTypes:(NSArray<NSNumber *> *)contentTypes
                                            from:(NSUInteger)fromIndex
                                           count:(NSInteger)count
                                        withUser:(NSString *)user {
    return [[WFCCMessageDB sharedManager] getMessages:conversationTypes lines:lines contentTypes:contentTypes from:fromIndex count:count withUser:user];
}

- (void)getMessagesV2:(NSArray<NSNumber *> *)conversationTypes
                lines:(NSArray<NSNumber *> *)lines
         contentTypes:(NSArray<NSNumber *> *)contentTypes
                 from:(NSUInteger)fromIndex
                count:(NSInteger)count
             withUser:(NSString *)user
              success:(void(^)(NSArray<WFCCMessage *> *messages))successBlock
                error:(void(^)(int error_code))errorBlock {
    NSArray *messages = [self getMessages:conversationTypes lines:lines contentTypes:contentTypes from:fromIndex count:count withUser:user];
    if (successBlock) {
        successBlock(messages ?: @[]);
    }
}

- (NSArray<WFCCMessage *> *)getMessages:(NSArray<NSNumber *> *)conversationTypes
                                           lines:(NSArray<NSNumber *> *)lines
                                   messageStatus:(NSArray<NSNumber *> *)messageStatus
                                            from:(NSUInteger)fromIndex
                                           count:(NSInteger)count
                                        withUser:(NSString *)user {
    return [[WFCCMessageDB sharedManager] getMessages:conversationTypes lines:lines messageStatus:messageStatus from:fromIndex count:count withUser:user];
}

- (void)getMessagesV2:(NSArray<NSNumber *> *)conversationTypes
                lines:(NSArray<NSNumber *> *)lines
        messageStatus:(NSArray<NSNumber *> *)messageStatus
                 from:(NSUInteger)fromIndex
                count:(NSInteger)count
             withUser:(NSString *)user
              success:(void(^)(NSArray<WFCCMessage *> *messages))successBlock
                error:(void(^)(int error_code))errorBlock {
    NSArray *messages = [self getMessages:conversationTypes lines:lines messageStatus:messageStatus from:fromIndex count:count withUser:user];
    if (successBlock) {
        successBlock(messages ?: @[]);
    }
}

- (NSArray<WFCCMessage *> *)getUserMessages:(NSString *)userId
                               conversation:(WFCCConversation *)conversation
                               contentTypes:(NSArray<NSNumber *> *)contentTypes
                                       from:(NSUInteger)fromIndex
                                      count:(NSInteger)count {
    return [[WFCCMessageDB sharedManager] getUserMessages:userId conversation:conversation contentTypes:contentTypes from:fromIndex count:count];
}

- (void)getUserMessagesV2:(NSString *)userId
             conversation:(WFCCConversation *)conversation
             contentTypes:(NSArray<NSNumber *> *)contentTypes
                     from:(NSUInteger)fromIndex
                    count:(NSInteger)count
                  success:(void(^)(NSArray<WFCCMessage *> *messages))successBlock
                    error:(void(^)(int error_code))errorBlock {
    NSArray *messages = [self getUserMessages:userId conversation:conversation contentTypes:contentTypes from:fromIndex count:count];
    if (successBlock) {
        successBlock(messages ?: @[]);
    }
}

- (NSArray<WFCCMessage *> *)getUserMessages:(NSString *)userId
                          conversationTypes:(NSArray<NSNumber *> *)conversationTypes
                                      lines:(NSArray<NSNumber *> *)lines
                               contentTypes:(NSArray<NSNumber *> *)contentTypes
                                       from:(NSUInteger)fromIndex
                                      count:(NSInteger)count {
    
    return [[WFCCMessageDB sharedManager] getUserMessages:userId conversationTypes:conversationTypes lines:lines contentTypes:contentTypes from:fromIndex count:count];
}

- (void)getUserMessagesV2:(NSString *)userId
        conversationTypes:(NSArray<NSNumber *> *)conversationTypes
                    lines:(NSArray<NSNumber *> *)lines
             contentTypes:(NSArray<NSNumber *> *)contentTypes
                     from:(NSUInteger)fromIndex
                    count:(NSInteger)count
                  success:(void(^)(NSArray<WFCCMessage *> *messages))successBlock
                    error:(void(^)(int error_code))errorBlock {
    NSArray *messages = [self getUserMessages:userId conversationTypes:conversationTypes lines:lines contentTypes:contentTypes from:fromIndex count:count];
    if (successBlock) {
        successBlock(messages ?: @[]);
    }
}

- (void)getRemoteMessages:(WFCCConversation *)conversation
                   before:(long long)beforeMessageUid
                    count:(NSUInteger)count
             contentTypes:(NSArray<NSNumber *> *)contentTypes
                  success:(void(^)(NSArray<WFCCMessage *> *messages))successBlock
                    error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        successBlock(@[]);
    }
}

- (void)getRemoteMessage:(long long)messageUid
                 success:(void(^)(WFCCMessage *message))successBlock
                   error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        successBlock([[WFCCMessageDB sharedManager] getDBMessageByUid:messageUid]);
    }
}

- (WFCCMessage *)getMessage:(long)messageId {
    return [[WFCCMessageDB sharedManager] getDBMessage:messageId];
}

- (WFCCMessage *)getMessageByUid:(long long)messageUid {
    return [[WFCCMessageDB sharedManager] getDBMessageByUid:messageUid];
}

- (WFCCUnreadCount *)getUnreadCount:(WFCCConversation *)conversation {
    return [[WFCCMessageDB sharedManager] getUnreadCount:conversation];
}

- (WFCCUnreadCount *)getUnreadCount:(NSArray<NSNumber *> *)conversationTypes lines:(NSArray<NSNumber *> *)lines {
    return [[WFCCMessageDB sharedManager] getUnreadCount:conversationTypes lines:lines];
}

- (void)clearUnreadStatus:(WFCCConversation *)conversation {
    return [[WFCCMessageDB sharedManager] clearUnreadStatus:conversation];
}

- (void)clearUnreadStatus:(NSArray<NSNumber *> *)conversationTypes
                    lines:(NSArray<NSNumber *> *)lines {
    [[WFCCMessageDB sharedManager] clearUnreadStatus:conversationTypes lines:lines];
}
- (void)clearAllUnreadStatus {
    [[WFCCMessageDB sharedManager] clearAllUnreadStatus];
}

- (void)clearMessageUnreadStatus:(long)messageId {
    [[WFCCMessageDB sharedManager] clearMessageUnreadStatus:messageId];
}

- (void)clearMessageUnreadStatusBefore:(long)messageId conversation:(WFCCConversation *)conversation {
    [[WFCCMessageDB sharedManager] clearMessageUnreadStatusBefore:messageId conversation:conversation];
}

- (BOOL)markAsUnRead:(WFCCConversation *)conversation syncToOtherClient:(BOOL)sync {
    return [[WFCCConversationDB sharedManager] markAsUnRead:conversation syncToOtherClient:sync];
}

- (void)setMediaMessagePlayed:(long)messageId {
    [[WFCCMessageDB sharedManager] setMediaMessagePlayed:messageId];
}

- (BOOL)setMessage:(long)messageId localExtra:(NSString *)extra {
    return [[WFCCMessageDB sharedManager] setMessage:messageId localExtra:extra];
}

- (NSMutableDictionary<NSString *, NSNumber *> *)getConversationRead:(WFCCConversation *)conversation {
    return [[WFCCConversationDB sharedManager] getConversationRead:conversation];
}

- (NSMutableDictionary<NSString *, NSNumber *> *)getMessageDelivery:(WFCCConversation *)conversation {
    return [[WFCCMessageDB sharedManager] getMessageDelivery:conversation];
}

- (BOOL)updateMessage:(long)messageId status:(WFCCMessageStatus)status {
    return [[WFCCMessageDB sharedManager] updateMessage:messageId status:status];
}

- (void)removeConversation:(WFCCConversation *)conversation clearMessage:(BOOL)clearMessage {
    [[WFCCConversationDB sharedManager] removeConversation:conversation clearMessage:clearMessage];
}

- (void)clearMessages:(WFCCConversation *)conversation {
    [[WFCCConversationDB sharedManager] clearMessages:conversation];
}

- (void)clearMessages:(WFCCConversation *)conversation before:(int64_t)before {
    [[WFCCConversationDB sharedManager] clearMessages:conversation before:before];
}

- (void)clearMessages:(NSString *)userId start:(int64_t)start end:(int64_t)end {
    [[WFCCMessageDB sharedManager] clearMessages:userId start:start end:end];
}

- (void)clearAllMessages:(BOOL)removeConversation {
    [[WFCCConversationDB sharedManager] clearAllMessages:removeConversation];
}

- (void)setConversation:(WFCCConversation *)conversation top:(int)top
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock {
    [self setUserSetting:UserSettingScope_Conversation_Top key:[NSString stringWithFormat:@"%zd-%d-%@", conversation.type, conversation.line, conversation.target] value:[NSString stringWithFormat:@"%d", top] success:successBlock error:errorBlock];
}

- (void)setConversation:(WFCCConversation *)conversation draft:(NSString *)draft {
    [[WFCCConversationDB sharedManager] setConversation:conversation draft:draft];
}

- (void)setConversation:(WFCCConversation *)conversation
              timestamp:(long long)timestamp {
    [[WFCCConversationDB sharedManager] setConversation:conversation timestamp:timestamp];
}

- (long)getFirstUnreadMessageId:(WFCCConversation *)conversation {
    return [[WFCCConversationDB sharedManager] getFirstUnreadMessageId:conversation];
}

- (void)clearRemoteConversationMessage:(WFCCConversation *)conversation
                               success:(void(^)(void))successBlock
                                 error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        successBlock();
    }
}

- (void)searchUser:(NSString *)keyword
        searchType:(WFCCSearchUserType)searchType
              page:(int)page
           success:(void(^)(NSArray<WFCCUserInfo *> *machedUsers))successBlock
             error:(void(^)(int errorCode))errorBlock {
    
    if(keyword.length == 0) {
        successBlock(@[]);
    }
    
    if (self.userSource) {
        [self.userSource searchUser:keyword searchType:searchType page:page success:successBlock error:errorBlock];
        return;
    }
    
    if (successBlock) {
        successBlock(@[]);
    }
}

- (void)getUserInfo:(NSString *)userId
            refresh:(BOOL)refresh
            success:(void(^)(WFCCUserInfo *userInfo))successBlock
              error:(void(^)(int errorCode))errorBlock {
    if (!userId.length) {
        return;
    }
    
    if ([self.userSource respondsToSelector:@selector(getUserInfo:refresh:success:error:)]) {
        [self.userSource getUserInfo:userId refresh:refresh success:successBlock error:errorBlock];
        return;
    }
        
    WFCCUserInfo *userInfo = [[WFCCUserDB sharedManager] getUserInfo:userId];
    if (!userInfo) {
        userInfo = [[WFCCUserInfo alloc] init];
        userInfo.userId = userId;
    }
    if (successBlock) {
        successBlock(userInfo);
    }
}

- (BOOL)isMyFriend:(NSString *)userId {
    if(!userId)
        return NO;
    
    return [[WFCCUserDB sharedManager] isMyFriend:userId];
}

- (NSArray<NSString *> *)getMyFriendList:(BOOL)refresh {
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    
    return [[WFCCUserDB sharedManager] getMyFriendList];
    return ret;
}

- (NSArray<WFCCFriend *> *)getFriendList:(BOOL)refresh {
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    for (NSString *userId in [[WFCCUserDB sharedManager] getMyFriendList]) {
        WFCCFriend *f = [[WFCCFriend alloc] init];
        f.userId = userId;
        [ret addObject:f];
    }
    return ret;
}

- (NSArray<WFCCUserInfo *> *)searchFriends:(NSString *)keyword {
    if(!keyword)
        return nil;
    NSMutableArray<WFCCUserInfo *> *ret = [[NSMutableArray alloc] init];
    for (WFCCUserInfo *userInfo in [[WFCCUserDB sharedManager] getAllFriendInfos]) {
        if ([userInfo.userId containsString:keyword] || [userInfo.displayName containsString:keyword] || [userInfo.name containsString:keyword]) {
            [ret addObject:userInfo];
        }
    }
  return ret;
}

- (NSArray<WFCCGroupSearchInfo *> *)searchGroups:(NSString *)keyword {
    if(!keyword)
        return nil;
    return @[];
}


- (void)loadFriendRequestFromRemote {
}

- (NSArray<WFCCFriendRequest *> *)getIncommingFriendRequest {
    return @[];
}

- (NSArray<WFCCFriendRequest *> *)getOutgoingFriendRequest {
    return @[];
}

- (NSArray<WFCCFriendRequest *> *)getAllFriendRequest {
    return @[];
}

- (WFCCFriendRequest *)getFriendRequest:(NSString *)userId direction:(int)direction {
    if(!userId)
        return nil;
    return nil;
}

- (BOOL)clearFriendRequest:(int)direction beforeTime:(int64_t)beforeTime {
    return YES;
}

- (BOOL)deleteFriendRequest:(NSString *)userId direction:(int)direction {
    if(!userId.length)
        return false;
    return YES;
}

- (void)clearUnreadFriendRequestStatus {
}

- (int)getUnreadFriendRequestStatus {
    return 0;
}

- (void)sendFriendRequest:(NSString *)userId
                   reason:(NSString *)reason
                    extra:(NSString *)extra
                  success:(void(^)())successBlock
                    error:(void(^)(int error_code))errorBlock {
    if(!userId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    if (successBlock) {
        successBlock();
    }
}


- (void)handleFriendRequest:(NSString *)userId
                     accept:(BOOL)accpet
                      extra:(NSString *)extra
                    success:(void(^)())successBlock
                      error:(void(^)(int error_code))errorBlock {
    if(!userId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    if (successBlock) {
        successBlock();
    }
}

- (void)deleteFriend:(NSString *)userId
             success:(void(^)())successBlock
               error:(void(^)(int error_code))errorBlock {
    if(!userId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    if (successBlock) {
        successBlock();
    }
}

- (NSString *)getFriendAlias:(NSString *)friendId {
    if(!friendId) {
        return nil;
    }
    
    return [self getUserSetting:(UserSettingScope)(UserSettingScope_Custom_Begin + 1) key:friendId];
}

- (void)setFriend:(NSString *)friendId
            alias:(NSString *)alias
          success:(void(^)(void))successBlock
            error:(void(^)(int error_code))errorBlock {
    if(!friendId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    [self setUserSetting:(UserSettingScope)(UserSettingScope_Custom_Begin + 1) key:friendId value:alias ?: @"" success:successBlock error:errorBlock];
}

- (NSString *)getFriendExtra:(NSString *)friendId {
    if(!friendId)
        return nil;
    return [self getUserSetting:(UserSettingScope)(UserSettingScope_Custom_Begin + 2) key:friendId];
}

- (BOOL)isBlackListed:(NSString *)userId {
    if(!userId)
        return NO;
    return [[WFCCUserDB sharedManager] isBlackListed:userId] || [[self getUserSetting:(UserSettingScope)(UserSettingScope_Custom_Begin + 3) key:userId] isEqualToString:@"1"];
}

- (NSArray<NSString *> *)getBlackList:(BOOL)refresh {
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    NSDictionary *settings = [self getUserSettings:(UserSettingScope)(UserSettingScope_Custom_Begin + 3)];
    [settings enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        if ([obj isEqualToString:@"1"]) {
            [ret addObject:key];
        }
    }];
    return ret;
}

- (void)setBlackList:(NSString *)userId
       isBlackListed:(BOOL)isBlackListed
             success:(void(^)(void))successBlock
               error:(void(^)(int error_code))errorBlock {
    if(!userId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    [self setUserSetting:(UserSettingScope)(UserSettingScope_Custom_Begin + 3) key:userId value:isBlackListed ? @"1" : @"0" success:successBlock error:errorBlock];
}
- (WFCCUserInfo *)getUserInfo:(NSString *)userId refresh:(BOOL)refresh {
    if (!userId) {
        return nil;
    }
    
    if ([self.userSource respondsToSelector:@selector(getUserInfo:refresh:)]) {
        return [self.userSource getUserInfo:userId refresh:refresh];
    }
    
    return [self getUserInfo:userId inGroup:nil refresh:refresh];
}

- (WFCCUserInfo *)getUserInfo:(NSString *)userId inGroup:(NSString *)groupId refresh:(BOOL)refresh {
    if (!userId) {
        return nil;
    }
    
    if ([self.userSource respondsToSelector:@selector(getUserInfo:inGroup:refresh:)]) {
        return [self.userSource getUserInfo:userId inGroup:groupId refresh:refresh];
    }
    
    WFCCUserInfo *userInfo = groupId.length ? [[WFCCUserDB sharedManager] getUserInfo:userId inGroup:groupId] : [[WFCCUserDB sharedManager] getUserInfo:userId];
    if (!userInfo) {
        userInfo = [[WFCCUserInfo alloc] init];
        userInfo.userId = userId;
    }
    return userInfo;
}

- (NSArray<WFCCUserInfo *> *)getUserInfos:(NSArray<NSString *> *)userIds inGroup:(NSString *)groupId {
    if ([userIds count] == 0) {
        return nil;
    }
    
    if ([self.userSource respondsToSelector:@selector(getUserInfos:inGroup:)]) {
        return [self.userSource getUserInfos:userIds inGroup:groupId];;
    }
    
    NSMutableArray<WFCCUserInfo *> *ret = [[NSMutableArray alloc] init];
    NSArray<WFCCUserInfo *> *infos = groupId.length ? [[WFCCUserDB sharedManager] getUserInfos:userIds inGroup:groupId] : [[WFCCUserDB sharedManager] getUserInfos:userIds];
    for (WFCCUserInfo *userInfo in infos) {
        if ([userInfo.name isEqualToString:@"FireRobot"] || [userInfo.userId isEqualToString:@"FireRobot"] || // 86 Messenger
            [userInfo.name isEqualToString:@"wfc_file_transfer"] || // 文件传输助手
            [userInfo.name isEqualToString:@"group_message"]) { // 群通知
            continue;
        } // PGWPAMAO
        if ([self isBlackListed:userInfo.userId]) {
            continue;
        }
        [ret addObject:userInfo];
    }
    return ret;
}

- (void)uploadMedia:(NSString *)fileName
          mediaData:(NSData *)mediaData
          mediaType:(WFCCMediaType)mediaType
            success:(void(^)(NSString *remoteUrl))successBlock
           progress:(void(^)(long uploaded, long total))progressBlock
              error:(void(^)(int error_code))errorBlock {
    NSString *mimeType = @"application/octet-stream";
    if (mediaType == Media_Type_IMAGE) {
        mimeType = @"image/png";
    } else if (mediaType == Media_Type_VOICE) {
        mimeType = @"audio/amr";
    } else if (mediaType == Media_Type_VIDEO) {
        mimeType = @"video/mp4";
    }
    [[SRIMService sharedSRIMService] uploadFile:fileName ?: @"file"
                                           data:mediaData
                                       mimeType:mimeType
                                        success:successBlock
                                       progress:progressBlock
                                           fail:^(int error_code, NSString *message) {
        if (errorBlock) {
            errorBlock(error_code);
        }
    }];
}

- (BOOL)syncUploadMedia:(NSString *)fileName
              mediaData:(NSData *)mediaData
              mediaType:(WFCCMediaType)mediaType
                success:(void(^)(NSString *remoteUrl))successBlock
            progress:(void(^)(long uploaded, long total))progressBlock
                  error:(void(^)(int error_code))errorBlock {
    NSCondition *condition = [[NSCondition alloc] init];
    __block BOOL success = NO;

    [condition lock];
    [[WFCCIMService sharedWFCIMService] uploadMedia:fileName mediaData:mediaData mediaType:mediaType success:^(NSString *remoteUrl) {
        successBlock(remoteUrl);
        
        success = YES;
        [condition lock];
        [condition signal];
        [condition unlock];
    } progress:^(long uploaded, long total) {
        progressBlock(uploaded, total);
    } error:^(int error_code) {
        errorBlock(error_code);
        success = NO;
        [condition lock];
        [condition signal];
        [condition unlock];
    }];
    
    [condition wait];
    [condition unlock];
    
    return success;
}

- (void)getUploadUrl:(NSString *)fileName
           mediaType:(WFCCMediaType)mediaType
         contentType:(NSString *)contentType
            success:(void(^)(NSString *uploadUrl, NSString *downloadUrl, NSString *backupUploadUrl, int type))successBlock
               error:(void(^)(int error_code))errorBlock {
    if (errorBlock) {
        errorBlock(-1);
    }
}

- (BOOL)isSupportBigFilesUpload {
    return NO;
}

-(void)modifyMyInfo:(NSDictionary<NSNumber */*ModifyMyInfoType*/, NSString *> *)values
            success:(void(^)())successBlock
              error:(void(^)(int error_code))errorBlock {
    if (self.userSource) {
        [self.userSource modifyMyInfo:values success:successBlock error:errorBlock];
        return;
    }
    
    if (errorBlock) {
        errorBlock(-1);
    }
}

- (BOOL)isGlobalSilent {
    NSString *strValue = [[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_Global_Silent key:@""];
    return [strValue isEqualToString:@"1"];
}

- (void)setGlobalSilent:(BOOL)silent
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock {
    [[WFCCIMService sharedWFCIMService] setUserSetting:UserSettingScope_Global_Silent key:@"" value:silent?@"1":@"0" success:^{
        if (successBlock) {
            successBlock();
        }
    } error:^(int error_code) {
        if (errorBlock) {
            errorBlock(error_code);
        }
    }];
}

- (BOOL)isVoipNotificationSilent {
    NSString *strValue = [[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_Voip_Silent key:@""];
    return [strValue isEqualToString:@"1"];
}

- (void)setVoipNotificationSilent:(BOOL)silent
                          success:(void(^)(void))successBlock
                            error:(void(^)(int error_code))errorBlock {
    [[WFCCIMService sharedWFCIMService] setUserSetting:UserSettingScope_Voip_Silent key:@"" value:silent?@"1":@"0" success:^{
        if (successBlock) {
            successBlock();
        }
    } error:^(int error_code) {
        if (errorBlock) {
            errorBlock(error_code);
        }
    }];
}
- (BOOL)isEnableSyncDraft {
    NSString *strValue = [[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_Disable_Sync_Draft key:@""];
    return ![strValue isEqualToString:@"1"];
}

- (void)setEnableSyncDraft:(BOOL)enable
                    success:(void(^)(void))successBlock
                      error:(void(^)(int error_code))errorBlock {
    [[WFCCIMService sharedWFCIMService] setUserSetting:UserSettingScope_Disable_Sync_Draft key:@"" value:enable?@"0":@"1" success:^{
        if (successBlock) {
            successBlock();
        }
    } error:^(int error_code) {
        if (errorBlock) {
            errorBlock(error_code);
        }
    }];
}

- (BOOL)isUserEnableReceipt {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    NSString *key = [NSString stringWithFormat:@"%@_%@",@"Receipt",userId];
    return  [[[NSUserDefaults standardUserDefaults] objectForKey:key] boolValue];
    
    NSString *strValue = [[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_DisableRecipt key:@""];
    return ![strValue isEqualToString:@"1"];
}

- (void)setUserEnableReceipt:(BOOL)enable
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock {
    [[WFCCIMService sharedWFCIMService] setUserSetting:UserSettingScope_DisableRecipt key:@"" value:enable?@"0":@"1" success:^{
        if (successBlock) {
            successBlock();
        }
    } error:^(int error_code) {
        if (errorBlock) {
            errorBlock(error_code);
        }
    }];
}

- (void)getNoDisturbingTimes:(void(^)(int startMins, int endMins))resultBlock
                       error:(void(^)(int error_code))errorBlock {
    NSString *strValue = [[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_No_Disturbing key:@""];
    if (strValue.length) {
        NSArray<NSString *> *arrs = [strValue componentsSeparatedByString:@"|"];
        if (arrs.count == 2) {
            int startMins = [arrs[0] intValue];
            int endMins = [arrs[1] intValue];
            resultBlock(startMins, endMins);
        } else {
            if(errorBlock) {
                errorBlock(-1);
            }
        }
    } else {
        if(errorBlock) {
            errorBlock(-1);
        }
    }
}

- (void)setNoDisturbingTimes:(int)startMins
                     endMins:(int)endMins
                     success:(void(^)(void))successBlock
                       error:(void(^)(int error_code))errorBlock {
    [[WFCCIMService sharedWFCIMService] setUserSetting:UserSettingScope_No_Disturbing key:@"" value:[NSString stringWithFormat:@"%d|%d", startMins, endMins] success:successBlock error:errorBlock];
}

- (void)clearNoDisturbingTimes:(void(^)(void))successBlock
                         error:(void(^)(int error_code))errorBlock {
    [[WFCCIMService sharedWFCIMService] setUserSetting:UserSettingScope_No_Disturbing key:@"" value:@"" success:successBlock error:errorBlock];
}

- (BOOL)isNoDisturbing {
    __block BOOL isNoDisturbing = NO;
    [self getNoDisturbingTimes:^(int startMins, int endMins) {
        NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *nowCmps = [calendar components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:[NSDate date]];
        int nowMins = (int)(nowCmps.hour * 60 + nowCmps.minute);
        if (endMins > startMins) {
            if (endMins > nowMins && nowMins > startMins) {
                isNoDisturbing = YES;
            }
        } else {
            if (endMins > nowMins || nowMins > startMins) {
                isNoDisturbing = YES;
            }
        }
        
    } error:^(int error_code) {
        
    }];
    return isNoDisturbing;
}

- (BOOL)isHiddenNotificationDetail {
    NSString *strValue = [[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_Hidden_Notification_Detail key:@""];
    return [strValue isEqualToString:@"1"];
}

- (void)setHiddenNotificationDetail:(BOOL)hidden
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock {
    [[WFCCIMService sharedWFCIMService] setUserSetting:UserSettingScope_Hidden_Notification_Detail key:@"" value:hidden?@"1":@"0" success:^{
        if (successBlock) {
            successBlock();
        }
    } error:^(int error_code) {
        if (errorBlock) {
            errorBlock(error_code);
        }
    }];
}

//UserSettingScope_Hidden_Notification_Detail = 4,
- (BOOL)isHiddenGroupMemberName:(NSString *)groupId {
    NSString *strValue = [[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_Group_Hide_Nickname key:groupId];
    return [strValue isEqualToString:@"1"];
}

- (void)setHiddenGroupMemberName:(BOOL)hidden
                           group:(NSString *)groupId
                            success:(void(^)(void))successBlock
                              error:(void(^)(int error_code))errorBlock {
    [[WFCCIMService sharedWFCIMService] setUserSetting:UserSettingScope_Group_Hide_Nickname key:groupId value:hidden?@"1":@"0" success:^{
        if (successBlock) {
            successBlock();
        }
    } error:^(int error_code) {
        if (errorBlock) {
            errorBlock(error_code);
        }
    }];
}

-(void)getMyGroups:(void(^)(NSArray<NSString *> *))successBlock
                error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        successBlock(@[]);
    }
}

- (void)getCommonGroups:(NSString *)userId
                success:(void(^)(NSArray<NSString *> *))successBlock
                  error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        successBlock(@[]);
    }
}

- (BOOL)deleteMessage:(long)messageId {
    WFCCMessage *msg = [[WFCCMessageDB sharedManager] getDBMessage:messageId];
    NSString *path = @"/deletePrivateMessage";
    if (msg.conversation.type == Group_Type) {
        path = @"/deleteGroupMessage";
    }
    if (msg.messageUid) {
        [[SRIMService sharedSRIMService] postRequestWithPath:path
                                                        data:@{@"messageId":@(msg.messageUid),@"to":msg.conversation.target}
                                                     success:^(NSDictionary * _Nonnull responseDict) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kDeleteMessages object:@(msg.messageUid)];
            });

        } failure:^(NSError * _Nonnull error) {
            
        }];
    }
    return [[WFCCMessageDB sharedManager] deleteMessage:messageId];
}

- (BOOL)batchDeleteMessages:(NSArray<NSNumber *> *)messageUids {
    
    
    return [[WFCCMessageDB sharedManager] batchDeleteMessages:messageUids];
}

- (void)deleteRemoteMessage:(long long)messageUid
                    success:(void(^)(void))successBlock
                      error:(void(^)(int error_code))errorBlock  {
    if (successBlock) {
        successBlock();
    }
}

- (void)updateRemoteMessage:(long long)messageUid
                    content:(WFCCMessageContent *)content
                 distribute:(BOOL)distribute
                updateLocal:(BOOL)updateLocal
                    success:(void(^)(void))successBlock
                      error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        successBlock();
    }
}

- (NSArray<WFCCConversationSearchInfo *> *)searchConversation:(NSString *)keyword inConversation:(NSArray<NSNumber *> *)conversationTypes lines:(NSArray<NSNumber *> *)lines {
    return [self searchConversation:keyword inConversation:conversationTypes lines:lines startTime:0 endTime:0 desc:YES limit:50 offset:0];
}

- (NSArray<WFCCConversationSearchInfo *> *)searchConversation:(NSString *)keyword inConversation:(NSArray<NSNumber *> *)conversationTypes lines:(NSArray<NSNumber *> *)lines startTime:(int64_t)startTime endTime:(int64_t)endTime desc:(BOOL)desc limit:(int)limit offset:(int)offset {
    return [[WFCCMessageDB sharedManager] searchConversation:keyword inConversation:conversationTypes lines:lines startTime:startTime endTime:endTime desc:desc limit:limit offset:offset];
}

- (NSArray<WFCCConversationSearchInfo *> *)searchConversation:(NSString *)keyword
                                               inConversation:(NSArray<NSNumber *> *)conversationTypes
                                                        lines:(NSArray<NSNumber *> *)lines
                                                     cntTypes:(NSArray<NSNumber *> *)cntTypes
                                                    startTime:(int64_t)startTime
                                                      endTime:(int64_t)endTime
                                                         desc:(BOOL)desc
                                                        limit:(int)limit
                                                       offset:(int)offset
                                             onlyMentionedMsg:(BOOL)onlyMentionedMsg {
    
    return [[WFCCMessageDB sharedManager] searchConversation:keyword inConversation:conversationTypes lines:lines cntTypes:cntTypes startTime:startTime endTime:endTime desc:desc limit:limit offset:offset onlyMentionedMsg:onlyMentionedMsg];
}

- (NSArray<WFCCMessage *> *)searchMessage:(WFCCConversation *)conversation
                                  keyword:(NSString *)keyword
                                    order:(BOOL)desc
                                    limit:(int)limit
                                   offset:(int)offset
                                 withUser:(NSString *)withUser {
    
    return [[WFCCMessageDB sharedManager] searchMessage:conversation keyword:keyword order:desc limit:limit offset:offset withUser:withUser];
}

- (NSArray<WFCCMessage *> *)searchMessage:(WFCCConversation *)conversation
                                  keyword:(NSString *)keyword
                             contentTypes:(NSArray<NSNumber *> *)contentTypes
                                    order:(BOOL)desc
                                    limit:(int)limit
                                   offset:(int)offset
                                 withUser:(NSString *)withUser {
    return [[WFCCMessageDB sharedManager] searchMessage:conversation keyword:keyword contentTypes:contentTypes order:desc limit:limit offset:offset withUser:withUser];
}

- (NSArray<WFCCMessage *> *)searchMessage:(WFCCConversation *)conversation
                                  keyword:(NSString *)keyword
                             contentTypes:(NSArray<NSNumber *> *)contentTypes
                                startTime:(int64_t)startTime
                                  endTime:(int64_t)endTime
                                    order:(BOOL)desc
                                    limit:(int)limit
                                   offset:(int)offset
                                 withUser:(NSString *)withUser {
    return [[WFCCMessageDB sharedManager] searchMessage:conversation keyword:keyword contentTypes:contentTypes startTime:startTime endTime:endTime order:desc limit:limit offset:offset withUser:withUser];
}

- (NSArray<WFCCMessage *> *)searchMentionedMessages:(WFCCConversation *)conversation
                                            keyword:(NSString *)keyword
                                              order:(BOOL)desc
                                              limit:(int)limit
                                             offset:(int)offset {
    return [[WFCCMessageDB sharedManager] searchMentionedMessages:conversation keyword:keyword order:desc limit:limit offset:offset];
}

- (NSArray<WFCCMessage *> *)searchMessage:(NSArray<NSNumber *> *)conversationTypes
                                    lines:(NSArray<NSNumber *> *)lines
                             contentTypes:(NSArray<NSNumber *> *)contentTypes
                                  keyword:(NSString *)keyword
                                     from:(NSUInteger)fromIndex
                                    count:(NSInteger)count
                                 withUser:(NSString *)withUser {
    
    return [[WFCCMessageDB sharedManager] searchMessage:conversationTypes lines:lines contentTypes:contentTypes keyword:keyword from:fromIndex count:count withUser:withUser];
}

- (NSArray<WFCCMessage *> *)searchMentionedMessage:(NSArray<NSNumber *> *)conversationTypes
                                             lines:(NSArray<NSNumber *> *)lines
                                           keyword:(NSString *)keyword
                                             order:(BOOL)desc
                                             limit:(int)limit
                                            offset:(int)offset {
    return [[WFCCMessageDB sharedManager] searchMentionedMessage:conversationTypes lines:lines keyword:keyword order:desc limit:limit offset:offset];
}

- (void)createGroup:(NSString *)groupId
               name:(NSString *)groupName
           portrait:(NSString *)groupPortrait
               type:(WFCCGroupType)type
         groupExtra:(NSString *)groupExtra
            members:(NSArray *)groupMembers
        memberExtra:(NSString *)memberExtra
        notifyLines:(NSArray<NSNumber *> *)notifyLines
      notifyContent:(WFCCMessageContent *)notifyContent
            success:(void(^)(NSString *groupId))successBlock
              error:(void(^)(int error_code))errorBlock {

    if (successBlock) {
        successBlock(groupId ?: @"");
    }
}

- (void)addMembers:(NSArray *)members
           toGroup:(NSString *)groupId
       memberExtra:(NSString *)memberExtra
       notifyLines:(NSArray<NSNumber *> *)notifyLines
     notifyContent:(WFCCMessageContent *)notifyContent
           success:(void(^)())successBlock
             error:(void(^)(int error_code))errorBlock {
    if(groupId.length == 0) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }

    if (successBlock) {
        successBlock();
    }
}

- (void)kickoffMembers:(NSArray *)members
             fromGroup:(NSString *)groupId
           notifyLines:(NSArray<NSNumber *> *)notifyLines
         notifyContent:(WFCCMessageContent *)notifyContent
               success:(void(^)())successBlock
                 error:(void(^)(int error_code))errorBlock {

    if(groupId.length == 0) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    
    if (successBlock) {
        successBlock();
    }
}

- (void)quitGroup:(NSString *)groupId
      notifyLines:(NSArray<NSNumber *> *)notifyLines
    notifyContent:(WFCCMessageContent *)notifyContent
          success:(void(^)())successBlock
            error:(void(^)(int error_code))errorBlock {

    if(groupId.length == 0) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    
    if (successBlock) {
        successBlock();
    }
}

- (void)dismissGroup:(NSString *)groupId
         notifyLines:(NSArray<NSNumber *> *)notifyLines
       notifyContent:(WFCCMessageContent *)notifyContent
             success:(void(^)())successBlock
               error:(void(^)(int error_code))errorBlock {

    if(groupId.length == 0) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    
    if (successBlock) {
        successBlock();
    }
}

- (void)modifyGroupInfo:(NSString *)groupId
                   type:(ModifyGroupInfoType)type
               newValue:(NSString *)newValue
            notifyLines:(NSArray<NSNumber *> *)notifyLines
          notifyContent:(WFCCMessageContent *)notifyContent
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock {
    
    if(groupId.length == 0) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    
    if (successBlock) {
        successBlock();
    }
}

- (void)modifyGroupAlias:(NSString *)groupId
                   alias:(NSString *)newAlias
             notifyLines:(NSArray<NSNumber *> *)notifyLines
           notifyContent:(WFCCMessageContent *)notifyContent
                 success:(void(^)())successBlock
                   error:(void(^)(int error_code))errorBlock {
    
    if(groupId.length == 0) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    
    if (successBlock) {
        successBlock();
    }
}

- (void)modifyGroupMemberAlias:(NSString *)groupId
                      memberId:(NSString *)memberId
                         alias:(NSString *)newAlias
                   notifyLines:(NSArray<NSNumber *> *)notifyLines
                 notifyContent:(WFCCMessageContent *)notifyContent
                       success:(void(^)(void))successBlock
                         error:(void(^)(int error_code))errorBlock {
    if(groupId.length == 0) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    
    if (successBlock) {
        successBlock();
    }
}

- (void)modifyGroupMemberExtra:(NSString *)groupId
                         extra:(NSString *)extra
                   notifyLines:(NSArray<NSNumber *> *)notifyLines
                 notifyContent:(WFCCMessageContent *)notifyContent
                       success:(void(^)(void))successBlock
                         error:(void(^)(int error_code))errorBlock {
    [self modifyGroupMemberExtra:groupId memberId:[WFCCNetworkService sharedInstance].userId extra:extra notifyLines:notifyLines notifyContent:notifyContent success:successBlock error:errorBlock];
}

- (void)modifyGroupMemberExtra:(NSString *)groupId
                      memberId:(NSString *)memberId
                         extra:(NSString *)extra
                   notifyLines:(NSArray<NSNumber *> *)notifyLines
                 notifyContent:(WFCCMessageContent *)notifyContent
                       success:(void(^)(void))successBlock
                         error:(void(^)(int error_code))errorBlock {
    if(groupId.length == 0) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    if (successBlock) {
        successBlock();
    }
}

- (NSArray<WFCCGroupMember *> *)getGroupMembers:(NSString *)groupId
                             forceUpdate:(BOOL)refresh {
    if(groupId.length == 0) {
        return nil;
    }
    NSMutableArray *output = [[NSMutableArray alloc] init];
    for(WFCCGroupMember *member in [[WFCCGroupDB sharedManager] getGroupMembers:groupId]) {
        if ([member.memberId isEqualToString:@"FireRobot"] || [member.memberId isEqualToString:@"wfc_file_transfer"]) {
            continue;
        }
        [output addObject:member];
    }
    return output;
}

- (NSArray<WFCCGroupMember *> *)getGroupMembers:(NSString *)groupId
                             type:(WFCCGroupMemberType)memberType {
    if(groupId.length == 0) {
        return nil;
    }
    NSMutableArray *output = [[NSMutableArray alloc] init];
    for(WFCCGroupMember *member in [[WFCCGroupDB sharedManager] getGroupMembers:groupId]) {
        if (member.type == memberType) {
            [output addObject:member];
        }
    }
    return output;
}

- (NSArray<WFCCGroupMember *> *)getGroupMembers:(NSString *)groupId
                                          count:(int)count {
    if(groupId.length == 0) {
        return nil;
    }
    NSArray *members = [[WFCCGroupDB sharedManager] getGroupMembers:groupId];
    NSMutableArray *output = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < members.count && i < count; i++) {
        [output addObject:members[i]];
    }
    return output;
}

- (void)getGroupMembers:(NSString *)groupId
                refresh:(BOOL)refresh
                success:(void(^)(NSString *groupId, NSArray<WFCCGroupMember *> *))successBlock
                  error:(void(^)(int errorCode))errorBlock {
    if(groupId.length == 0) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    if (successBlock) {
        successBlock(groupId, [[WFCCGroupDB sharedManager] getGroupMembers:groupId]);
    }
}

- (WFCCGroupMember *)getGroupMember:(NSString *)groupId
                           memberId:(NSString *)memberId {
    if (!groupId || !memberId) {
        return nil;
    }
    return [[WFCCGroupDB sharedManager] getGroupMember:groupId memberId:memberId];
}

- (void)transferGroup:(NSString *)groupId
                   to:(NSString *)newOwner
          notifyLines:(NSArray<NSNumber *> *)notifyLines
        notifyContent:(WFCCMessageContent *)notifyContent
              success:(void(^)())successBlock
                error:(void(^)(int error_code))errorBlock {
    if(groupId.length == 0) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    if (successBlock) {
        successBlock();
    }
}

- (void)setGroupManager:(NSString *)groupId
                  isSet:(BOOL)isSet
              memberIds:(NSArray<NSString *> *)memberIds
            notifyLines:(NSArray<NSNumber *> *)notifyLines
          notifyContent:(WFCCMessageContent *)notifyContent
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock {
    
    if(groupId.length == 0) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    
    if (successBlock) {
        successBlock();
    }
}
- (void)muteGroupMember:(NSString *)groupId
                     isSet:(BOOL)isSet
                 memberIds:(NSArray<NSString *> *)memberIds
               notifyLines:(NSArray<NSNumber *> *)notifyLines
             notifyContent:(WFCCMessageContent *)notifyContent
                   success:(void(^)(void))successBlock
                     error:(void(^)(int error_code))errorBlock {
    if(groupId.length == 0) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    
    if (successBlock) {
        successBlock();
    }
}

- (void)allowGroupMember:(NSString *)groupId
                     isSet:(BOOL)isSet
                 memberIds:(NSArray<NSString *> *)memberIds
               notifyLines:(NSArray<NSNumber *> *)notifyLines
             notifyContent:(WFCCMessageContent *)notifyContent
                   success:(void(^)(void))successBlock
                     error:(void(^)(int error_code))errorBlock {
    if(!groupId.length) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    
    if (successBlock) {
        successBlock();
    }
}

- (NSString *)getGroupRemark:(NSString *)groupId {
    return [self getUserSetting:UserSettingScope_Group_Remark key:groupId];
}

- (void)setGroup:(NSString *)groupId
          remark:(NSString *)remark
         success:(void(^)(void))successBlock
           error:(void(^)(int error_code))errorBlock {
    [self setUserSetting:UserSettingScope_Group_Remark key:groupId value:remark ?: @"" success:successBlock error:errorBlock];
}

- (NSArray<NSString *> *)getFavGroups {
    NSDictionary *favGroupDict = [[WFCCIMService sharedWFCIMService] getUserSettings:UserSettingScope_Favourite_Group];
    NSMutableArray *ids = [[NSMutableArray alloc] init];
    [favGroupDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isEqualToString:@"1"]) {
            [ids addObject:key];
        }
    }];
    return ids;
}

- (BOOL)isFavGroup:(NSString *)groupId {
    NSString *strValue = [[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_Favourite_Group key:groupId];
    if ([strValue isEqualToString:@"1"]) {
        return YES;
    }
    return NO;
}

- (void)setFavGroup:(NSString *)groupId fav:(BOOL)fav success:(void(^)(void))successBlock error:(void(^)(int errorCode))errorBlock {
    [[WFCCIMService sharedWFCIMService] setUserSetting:UserSettingScope_Favourite_Group key:groupId value:fav? @"1" : @"0" success:successBlock error:errorBlock];
}
- (WFCCGroupInfo *)getGroupInfo:(NSString *)groupId refresh:(BOOL)refresh {
    if (!groupId) {
        return nil;
    }
    if(![groupId isKindOfClass:NSString.class]) {
        return nil;
    }
    WFCCGroupInfo *group = [[WFCCGroupDB sharedManager] getGroupInfoFromDB:groupId];
    return group;
}

- (NSArray<WFCCGroupInfo *> *)getGroupInfos:(NSArray<NSString *> *)groupIds
                                    refresh:(BOOL)refresh {
    if (![groupIds count]) {
        return nil;
    }
    return [[WFCCGroupDB sharedManager] getGroupInfos:groupIds];
}

- (void)getGroupInfo:(NSString *)groupId
             refresh:(BOOL)refresh
             success:(void(^)(WFCCGroupInfo *groupInfo))successBlock
               error:(void(^)(int errorCode))errorBlock {
    if(!groupId.length) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    WFCCGroupInfo *group = [[WFCCGroupDB sharedManager] getGroupInfoFromDB:groupId];
    if (successBlock) {
        successBlock(group);
    }
}

- (NSString *)getUserSetting:(UserSettingScope)scope key:(NSString *)key {
    if (!key) {
        key = @"";
    }
    NSString *value = [[NSUserDefaults standardUserDefaults] stringForKey:WFCCUserSettingStorageKey(scope, key)];
    return value ?: @"";
}

- (NSDictionary<NSString *, NSString *> *)getUserSettings:(UserSettingScope)scope {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    NSString *prefix = WFCCUserSettingStoragePrefix(scope);
    NSDictionary *allSettings = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
    [allSettings enumerateKeysAndObjectsUsingBlock:^(NSString *storageKey, id obj, BOOL *stop) {
        if ([storageKey hasPrefix:prefix] && [obj isKindOfClass:NSString.class]) {
            NSString *key = [storageKey substringFromIndex:prefix.length];
            result[key] = obj;
        }
    }];
    return result;
}

- (void)setUserSetting:(UserSettingScope)scope key:(NSString *)key value:(NSString *)value
               success:(void(^)())successBlock
                 error:(void(^)(int error_code))errorBlock {
    if(!key) {
        key = @"";
    }
    if(!value) {
        value = @"";
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:WFCCUserSettingStorageKey(scope, key)];
    [defaults synchronize];
    if(successBlock) {
        successBlock();
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kSettingUpdated object:nil];
}

- (void)setConversation:(WFCCConversation *)conversation silent:(BOOL)silent
                success:(void(^)())successBlock
                  error:(void(^)(int error_code))errorBlock {
    [self setUserSetting:UserSettingScope_Conversation_Silent key:[NSString stringWithFormat:@"%zd-%d-%@", conversation.type, conversation.line, conversation.target] value:silent ? @"1" : @"0" success:successBlock error:errorBlock];
}

- (BOOL)isConversationSilent:(WFCCConversation *)conversation {
    return [@"1" isEqualToString:[self getUserSetting:UserSettingScope_Conversation_Silent key:[NSString stringWithFormat:@"%zd-%d-%@", conversation.type, conversation.line, conversation.target]]];
}

- (WFCCMessageContent *)messageContentFromPayload:(WFCCMessagePayload *)payload {
    if(self.rawMessage && (payload.contentType < 400 || payload.contentType >= 500)) {
        WFCCRawMessageContent *rawContent = [[WFCCRawMessageContent alloc] init];
        rawContent.payload = payload;
        return rawContent;
    }
    
    int contenttype = payload.contentType;
    Class contentClass = self.MessageContentMaps[@(contenttype)];
    if (contentClass != nil) {
        id messageInstance = [[contentClass alloc] init];
        
        if ([contentClass conformsToProtocol:@protocol(WFCCMessageContent)]) {
            if ([messageInstance respondsToSelector:@selector(decode:)]) {
                [messageInstance performSelector:@selector(decode:)
                                      withObject:payload];
            }
        }
        return messageInstance;
    }
    WFCCUnknownMessageContent *unknownMsg = [[WFCCUnknownMessageContent alloc] init];
    [unknownMsg decode:payload];
    return unknownMsg;
}

- (WFCCMessage *)insert:(WFCCConversation *)conversation
                 sender:(NSString *)sender
                content:(WFCCMessageContent *)content
                 status:(WFCCMessageStatus)status
                 notify:(BOOL)notify
                toUsers:(NSArray<NSString *> *)toUsers
             serverTime:(long long)serverTime {
    return [[WFCCConversationDB sharedManager] insert:conversation sender:sender content:content status:status notify:notify toUsers:toUsers serverTime:serverTime];
}

- (void)updateMessage:(long)messageId
              content:(WFCCMessageContent *)content {
    [[WFCCMessageDB sharedManager] updateMessage:messageId content:content];
}

- (void)updateMessage:(long)messageId
              content:(WFCCMessageContent *)content
            timestamp:(long long)timestamp {
    [[WFCCMessageDB sharedManager] updateMessage:messageId content:content timestamp:timestamp];
}

- (void)registerMessageContent:(Class)contentClass {
    int contenttype;
    if (class_getClassMethod(contentClass, @selector(getContentType))) {
        contenttype = [contentClass getContentType];
        if(self.MessageContentMaps[@(contenttype)] && ![contentClass isEqual:self.MessageContentMaps[@(contenttype)]]) {
            NSLog(@"****************************************");
            NSLog(@"Error, duplicate message content type %d", contenttype);
            NSLog(@"****************************************");
#if DEBUG
            @throw [[NSException alloc] initWithName:@"重复定义消息" reason:[NSString stringWithFormat:@"消息类型(%d)重复定义在消息(%@)和(%@)中", contenttype, NSStringFromClass(contentClass), NSStringFromClass(self.MessageContentMaps[@(contenttype)])] userInfo:nil];
#endif
        }
        self.MessageContentMaps[@(contenttype)] = contentClass;
        int contentflag = [contentClass getContentFlags];
        
        [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
            BOOL success = [db executeUpdate:
                            @"REPLACE INTO t_message_flag (content_type, content_flag) VALUES (?, ?)",
                            @(contenttype), @(contentflag)];
            if (!success) {
                NSLog(@"[DB] Failed to register message flag for type %d", contenttype);
            }
        }];
    } else {
        return;
    }
}

- (void)registerMessageFlag:(int)contentType flag:(int)contentFlag {
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        BOOL success = [db executeUpdate:
                        @"REPLACE INTO t_message_flag (content_type, content_flag) VALUES (?, ?)",
                        @(contentType), @(contentFlag)];
        if (!success) {
            NSLog(@"[DB] Failed to register message flag. type=%d flag=%d", contentType, contentFlag);
        }
    }];
}

- (void)joinChatroom:(NSString *)chatroomId
             success:(void(^)(void))successBlock
               error:(void(^)(int error_code))errorBlock {
    if(!chatroomId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    if (successBlock) {
        successBlock();
    }
}

- (void)quitChatroom:(NSString *)chatroomId
             success:(void(^)(void))successBlock
               error:(void(^)(int error_code))errorBlock {
    if(!chatroomId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    if (successBlock) {
        successBlock();
    }
}

- (void)getChatroomInfo:(NSString *)chatroomId
                upateDt:(long long)updateDt
                success:(void(^)(WFCCChatroomInfo *chatroomInfo))successBlock
                  error:(void(^)(int error_code))errorBlock {
    if(!chatroomId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    if (successBlock) {
        successBlock(nil);
    }
}

- (void)getChatroomMemberInfo:(NSString *)chatroomId
                     maxCount:(int)maxCount
                      success:(void(^)(WFCCChatroomMemberInfo *memberInfo))successBlock
                        error:(void(^)(int error_code))errorBlock {
    if (maxCount <= 0) {
        maxCount = 30;
    }
    if(!chatroomId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    if (successBlock) {
        successBlock(nil);
    }
}

- (NSString *)getJoinedChatroomId {
    return nil;
}

- (void)createChannel:(NSString *)channelName
             portrait:(NSString *)channelPortrait
                 desc:(NSString *)desc
                extra:(NSString *)extra
              success:(void(^)(WFCCChannelInfo *channelInfo))successBlock
                error:(void(^)(int error_code))errorBlock {
    if (!extra) {
        extra = @"";
    }
    if (errorBlock) {
        errorBlock(-1);
    }
}

- (void)destoryChannel:(NSString *)channelId
              success:(void(^)(void))successBlock
                error:(void(^)(int error_code))errorBlock {
    if(!channelId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    if (successBlock) {
        successBlock();
    }
}

- (WFCCChannelInfo *)getChannelInfo:(NSString *)channelId
                            refresh:(BOOL)refresh {
    if(!channelId) {
        return nil;
    }
    return nil;
}

- (void)modifyChannelInfo:(NSString *)channelId
                     type:(ModifyChannelInfoType)type
                 newValue:(NSString *)newValue
                  success:(void(^)(void))successBlock
                    error:(void(^)(int error_code))errorBlock {
    if(!channelId || !newValue) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    if (successBlock) {
        successBlock();
    }
}

- (void)searchChannel:(NSString *)keyword success:(void(^)(NSArray<WFCCChannelInfo *> *machedChannels))successBlock error:(void(^)(int errorCode))errorBlock {
    
    if(!keyword.length) {
        successBlock(@[]);
        return;
    }
    if (successBlock) {
        successBlock(@[]);
    }
}

- (BOOL)isListenedChannel:(NSString *)channelId {
    if([@"1" isEqualToString:[self getUserSetting:UserSettingScope_Listened_Channel key:channelId]]) {
        return YES;
    }
    return NO;
}

- (void)listenChannel:(NSString *)channelId listen:(BOOL)listen success:(void(^)(void))successBlock error:(void(^)(int errorCode))errorBlock {
    if(!channelId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    [self setUserSetting:UserSettingScope_Listened_Channel key:channelId value:listen ? @"1" : @"0" success:successBlock error:errorBlock];
}

- (NSArray<NSString *> *)getMyChannels {
    NSDictionary *myChannelDict = [[WFCCIMService sharedWFCIMService] getUserSettings:UserSettingScope_My_Channel];
    NSMutableArray *ids = [[NSMutableArray alloc] init];
    [myChannelDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isEqualToString:@"1"]) {
            [ids addObject:key];
        }
    }];
    return ids;
}
- (NSArray<NSString *> *)getListenedChannels {
    NSDictionary *myChannelDict = [[WFCCIMService sharedWFCIMService] getUserSettings:UserSettingScope_Listened_Channel];
    NSMutableArray *ids = [[NSMutableArray alloc] init];
    [myChannelDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isEqualToString:@"1"]) {
            [ids addObject:key];
        }
    }];
    return ids;
}

- (void)getRemoteListenedChannels:(void(^)(NSArray<NSString *> *))successBlock error:(void(^)(int errorCode))errorBlock {
    if (successBlock) {
        successBlock([self getListenedChannels]);
    }
}

- (void)createSecretChat:(NSString *)userId
                success:(void(^)(NSString *targetId, int line))successBlock
                  error:(void(^)(int error_code))errorBlock {
    if (errorBlock) {
        errorBlock(-1);
    }
}

- (void)destroySecretChat:(NSString *)targetId
                  success:(void(^)(void))successBlock
                    error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        successBlock();
    }
}

- (WFCCSecretChatInfo *)getSecretChatInfo:(NSString *)targetId {
    return nil;
}

- (NSData *)encodeSecretChat:(NSString *)targetId mediaData:(NSData *)data {
    return data;
}

- (NSData *)decodeSecretChat:(NSString *)targetId mediaData:(NSData *)encryptData {
    return encryptData;
}

- (void)setSecretChat:(NSString *)targetId burnTime:(int)millisecond {
}

- (NSArray<WFCCPCOnlineInfo *> *)getPCOnlineInfos {
    NSString *pcOnline = [self getUserSetting:UserSettingScope_PC_Online key:@"PC"];
    NSString *webOnline = [self getUserSetting:UserSettingScope_PC_Online key:@"Web"];
    NSString *wxOnline = [self getUserSetting:UserSettingScope_PC_Online key:@"WX"];
    NSString *padOnline = [self getUserSetting:UserSettingScope_PC_Online key:@"Pad"];
    
    NSMutableArray *output = [[NSMutableArray alloc] init];
    if (pcOnline.length) {
        [output addObject:[WFCCPCOnlineInfo infoFromStr:pcOnline withType:PC_Online]];
    }
    if (webOnline.length) {
        [output addObject:[WFCCPCOnlineInfo infoFromStr:webOnline withType:Web_Online]];
    }
    if (wxOnline.length) {
        [output addObject:[WFCCPCOnlineInfo infoFromStr:wxOnline withType:WX_Online]];
    }
    if (padOnline.length) {
        [output addObject:[WFCCPCOnlineInfo infoFromStr:padOnline withType:Pad_Online]];
    }
    return output;
}

- (void)kickoffPCClient:(NSString *)pcClientId
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock {
    if(!pcClientId) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    if (successBlock) {
        successBlock();
    }
}

- (BOOL)isMuteNotificationWhenPcOnline {
    NSString *strValue = [[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_Mute_When_PC_Online key:@""];
    if ([strValue isEqualToString:@"1"]) {
        return !self.defaultSilentWhenPCOnline;
    }
    return self.defaultSilentWhenPCOnline;
}

- (void)setDefaultSilentWhenPcOnline:(BOOL)defaultSilent {
    self.defaultSilentWhenPCOnline = defaultSilent;
}

- (void)muteNotificationWhenPcOnline:(BOOL)isMute
                             success:(void(^)(void))successBlock
                               error:(void(^)(int error_code))errorBlock {
    if(!self.defaultSilentWhenPCOnline) {
        isMute = !isMute;
    }
    [[WFCCIMService sharedWFCIMService] setUserSetting:UserSettingScope_Mute_When_PC_Online key:@"" value:isMute? @"0" : @"1" success:successBlock error:errorBlock];
}

- (void)getConversationFiles:(WFCCConversation *)conversation
                    fromUser:(NSString *)userId
            beforeMessageUid:(long long)messageUid
                       order:(WFCCFileRecordOrder)order
                       count:(int)count
                     success:(void(^)(NSArray<WFCCFileRecord *> *files))successBlock
                       error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        successBlock(@[]);
    }
}

- (void)getMyFiles:(long long)beforeMessageUid
             order:(WFCCFileRecordOrder)order
             count:(int)count
           success:(void(^)(NSArray<WFCCFileRecord *> *files))successBlock
             error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        successBlock(@[]);
    }
}

- (void)searchMyFiles:(NSString *)keyword
     beforeMessageUid:(long long)beforeMessageUid
                order:(WFCCFileRecordOrder)order
                count:(int)count
              success:(void(^)(NSArray<WFCCFileRecord *> *files))successBlock
                error:(void(^)(int error_code))errorBlock {
    if (!keyword.length) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    if (successBlock) {
        successBlock(@[]);
    }
}

- (void)deleteFileRecord:(long long)messageUid
                 success:(void(^)(void))successBlock
                   error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        successBlock();
    }
}
       
- (void)searchFiles:(NSString *)keyword
       conversation:(WFCCConversation *)conversation
           fromUser:(NSString *)userId
   beforeMessageUid:(long long)messageUid
              order:(WFCCFileRecordOrder)order
              count:(int)count
            success:(void(^)(NSArray<WFCCFileRecord *> *files))successBlock
              error:(void(^)(int error_code))errorBlock {
    if (!keyword.length) {
        if(errorBlock) {
            errorBlock(-1);
        }
        return;
    }
    if (successBlock) {
        successBlock(@[]);
    }
}

- (void)getAuthorizedMediaUrl:(long long)messageUid
                    mediaType:(WFCCMediaType)mediaType
                    mediaPath:(NSString *)mediaPath
                      success:(void(^)(NSString *authorizedUrl, NSString *backupAuthorizedUrl))successBlock
                        error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        successBlock(mediaPath, nil);
    }
}

- (void)getAuthCode:(NSString *)applicationId
               type:(int)type
               host:(NSString *)host
            success:(void(^)(NSString *authCode))successBlock
              error:(void(^)(int error_code))errorBlock {
    if (errorBlock) {
        errorBlock(-1);
    }
}

- (void)configApplication:(NSString *)applicationId
                     type:(int)type
                timestamp:(int64_t)timestamp
                    nonce:(NSString *)nonce
                signature:(NSString *)signature
            success:(void(^)(void))successBlock
                    error:(void(^)(int error_code))errorBlock {
    if (errorBlock) {
        errorBlock(-1);
    }
}

- (NSData *)getWavData:(NSString *)amrPath {
    if (![@"amr" isEqualToString:[amrPath pathExtension]]) {
        return [NSData dataWithContentsOfFile:amrPath];
    } else {
        NSMutableData *data = [[NSMutableData alloc] init];
        decode_amr([amrPath UTF8String], data);
        return data;
    }
}

- (NSString *)imageThumbPara {
    return nil;
}

- (long)insertMessage:(WFCCMessage *)message {
    return [[WFCCMessageDB sharedManager] insertMessage:message];
}

- (int)getMessageCount:(WFCCConversation *)conversation {
    return [[WFCCMessageDB sharedManager] getMessageCount:conversation];
}

- (BOOL)beginTransaction {
    __block BOOL success = NO;
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        success = [db beginTransaction];
    }];
    return success;
}

- (BOOL)commitTransaction {
    __block BOOL success = NO;
    [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
        success = [db commit];
    }];
    return success;
}

- (BOOL)rollbackTransaction {
    __block BOOL success = NO;
     [[WKDB sharedDB].dbQueue inDatabase:^(FMDatabase *db) {
         success = [db rollback];
     }];
     return success;
}

- (BOOL)isCommercialServer {
    return NO;
}

- (BOOL)isReceiptEnabled {
    return YES;
}

- (BOOL)isGlobalDisableSyncDraft {
    return NO;
}

- (WFCCUserOnlineState *)getUserOnlineState:(NSString *)userId {
    return self.useOnlineCacheMap[userId];
}

- (WFCCUserOnlineStateModel *)getUserOnlineState1:(NSString *)userId {
    return self.useOnlineCacheMap1[userId];
}

- (WFCCUserCustomState *)getMyCustomState {
    NSString *strValue = [[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_Custom_State key:@""];
    if(strValue.length) {
        NSRange range = [strValue rangeOfString:@"-"];
        if(range.location != NSNotFound) {
            WFCCUserCustomState *state = [[WFCCUserCustomState alloc] init];
            NSString *numStr = [strValue substringToIndex:range.length];
            NSString *text = [strValue substringFromIndex:range.length+1];
            state.state = [numStr intValue];
            state.text = text;
            return state;
        }
    }
    
    return nil;
}

- (void)setMyCustomState:(WFCCUserCustomState *)state
                 success:(void(^)(void))successBlock
                   error:(void(^)(int error_code))errorBlock {
    if (!state.text) {
        state.text = @"";
    }
    NSString *strValue = [NSString stringWithFormat:@"%d-%@", state.state, state.text];
    [self setUserSetting:UserSettingScope_Custom_State key:@"" value:strValue success:successBlock error:errorBlock];
}

- (BOOL)isEnableUserOnlineState {
    return YES;
}

- (BOOL)isEnableSecretChat {
    return NO;
}

- (BOOL)isUserEnableSecretChat {
    NSString *strValue = [[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_Disable_Secret_Chat key:@""];
    return ![strValue isEqualToString:@"1"];
}

- (void)setUserEnableSecretChat:(BOOL)enable
                    success:(void(^)(void))successBlock
                      error:(void(^)(int error_code))errorBlock {
    [[WFCCIMService sharedWFCIMService] setUserSetting:UserSettingScope_Disable_Secret_Chat key:@"" value:enable?@"0":@"1" success:successBlock error:errorBlock];
}

- (void)sendConferenceRequest:(long long)sessionId
                         room:(NSString *)roomId
                      request:(NSString *)request
                         data:(NSString *)data
                      success:(void(^)(NSString *authorizedUrl))successBlock
                        error:(void(^)(int error_code))errorBlock {
    [self sendConferenceRequest:sessionId room:roomId request:request data:data success:successBlock error:errorBlock];
}

- (void)sendConferenceRequest:(long long)sessionId
                         room:(NSString *)roomId
                      request:(NSString *)request
                     advanced:(BOOL)advanced
                         data:(NSString *)data
                      success:(void(^)(NSString *authorizedUrl))successBlock
                        error:(void(^)(int error_code))errorBlock {
    if (errorBlock) {
        errorBlock(-1);
    }
}

- (NSArray<NSString *> *)getFavUsers {
    NSDictionary *favUserDict = [[WFCCIMService sharedWFCIMService] getUserSettings:UserSettingScope_Favourite_User];
    NSMutableArray *ids = [[NSMutableArray alloc] init];
    [favUserDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isEqualToString:@"1"]) {
            [ids addObject:key];
        }
    }];
    return ids;
}

- (BOOL)isFavUser:(NSString *)userId {
    NSString *strValue = [[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_Favourite_User key:userId];
    if ([strValue isEqualToString:@"1"]) {
        return YES;
    }
    return NO;
}

- (void)setFavUser:(NSString *)userId fav:(BOOL)fav success:(void(^)(void))successBlock error:(void(^)(int errorCode))errorBlock {
    [[WFCCIMService sharedWFCIMService] setUserSetting:UserSettingScope_Favourite_User key:userId value:fav? @"1" : @"0" success:successBlock error:errorBlock];
}

- (void)requireLock:(NSString *)lockId
           duration:(NSUInteger)duration
            success:(void(^)(void))successBlock
              error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        successBlock();
    }
}

- (void)releaseLock:(NSString *)lockId
            success:(void(^)(void))successBlock
              error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        successBlock();
    }
}

- (void)putUseOnlineStates:(NSArray<WFCCUserOnlineState *> *)states {
    [states enumerateObjectsUsingBlock:^(WFCCUserOnlineState * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.useOnlineCacheMap setObject:obj forKey:obj.userId];
    }];
}

- (void)putUseOnlineStates1:(NSArray *)states {
    [states enumerateObjectsUsingBlock:^(WFCCUserOnlineStateModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.useOnlineCacheMap1 setObject:obj forKey:obj.uid];
    }];
}
@end
