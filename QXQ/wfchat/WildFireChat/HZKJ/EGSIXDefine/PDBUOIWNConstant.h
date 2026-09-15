//
//  PDBUOIWNConstant.h
//  QXQ
//
//  Created by Loooooo on 10/7/23.
//

#ifndef PDBUOIWNConstant_h
#define PDBUOIWNConstant_h

// VoIP feature removed
#define WFCU_SUPPORT_VOIP 0

//对讲功能开关，在ChatKit工程也有同样的一个开关，需要保持同步
//#define WFC_PTT

//朋友圈的开关
//#define WFC_MOMENTS


//关于启用callkit功能，请参考 https://docs.wildfirechat.cn/blogs/iOS如何启用CallKit.html
#define USE_CALL_KIT 0
//模拟器不支持callkit
#if TARGET_IPHONE_SIMULATOR
#define USE_CALL_KIT 0

#endif

//#define     WebsiteUrl     @"https://qqim.app"


#define     kRefreshCallHistory     @"RefreshCallHistory"

// 1215 新增
#define     kUserExtraInfoUpdated     @"kUserExtraInfoUpdated" // 用户扩展信息更新
#define     kBurnAfterReadingUpdated     @"kBurnAfterReadingUpdated" // 非群聊 阅后即焚相关信息更新 1221

#define     kGroupNotificationOperate     @"kGroupNotificationOperate" // 群通知相关操作  1227

#define     kAnnouncementTimestamp     @"kAnnouncementTimestamp" // 群公告发布时间
#define     kLOGIN_TYPE     @"LOGIN_TYPE" // 登录方式 0 手机号码    1 邮箱

#define     kMODITY_MOBILE_EMAIL_NOTI     @"MODITY_MOBILE_EMAIL_NOTI" // 修改手机号成功

#define     kCancel_Group_Announcement_Top     @"Cancel_Group_Announcement_Top" // 重新获取置顶消息列表

#define     kGroup_Announcement_Update     @"Group_Announcement_Update" // 用户发布新的群公告消息




#define kWebsiteUrlEnglish  @"WebsiteUrlEnglish"
#define kWebsiteUrlChinese  @"WebsiteUrlChinese"

// 系统通知相关的状态值 0730
#define kIsAllowNotification  @"IsAllowNotification" // 是否允许通知 默认打开 NO 是开启  YES 为关闭
#define kDesktopCornerMark  @"DesktopCornerMark" // 桌面角标 默认打开 NO 是开启  YES 为关闭
#define kSuspensionNotice  @"SuspensionNotice" // 悬浮通知 默认打开 NO 是开启  YES 为关闭 


// 外观 相应的状态值
// NO  纯净模式   YES 非纯净模式(可以自定义气泡颜色和背景颜色/图片)   默认为0
#define kAppearanceStatus  @"AppearanceStatus"
#define kAppearanceBubbleColor  @"AppearanceBubbleColor" // 对话气泡颜色--->7种  从1开始  int类型  默认为0
#define kAppearanceChatBackgroundImg  @"AppearanceChatBackground" // 聊天背景图片 ---> 4种  从1开始  int类型  默认为0
#define kAppearanceChatBackgroundImgAlpha  @"AppearanceChatBackgroundAlpha" // 聊天背景图片透明度 ---> n种  0.0～1.0   float类型 默认为0
#define kAppearanceChatBackgroundColor  @"AppearanceChatBackgroundColor" // 背景颜色 4种 从0开始 int类型  默认为0

#endif /* PDBUOIWNConstant_h */
