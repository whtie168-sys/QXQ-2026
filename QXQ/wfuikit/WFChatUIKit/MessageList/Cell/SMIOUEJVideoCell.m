//
//  VideoCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/2.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "SMIOUEJVideoCell.h"
#import <WFChatClient/WFCChatClient.h>
#import "AIOIUEHImage.h"
#import <SDWebImage/SDWebImage.h>

@interface SMIOUEJVideoCell ()
@property(nonatomic, strong) UIImageView *shadowMaskView;
@property(nonatomic, strong) UILabel *captionLabel;
@end

@implementation SMIOUEJVideoCell

- (void)refreshLayoutForLoadedThumbnail:(UIImage *)image {
    if (!image) {
        return;
    }

    WFCCVideoMessageContent *videoContent = (WFCCVideoMessageContent *)self.model.message.content;
    if (!CGSizeEqualToSize(videoContent.size, CGSizeZero)) {
        return;
    }
    videoContent.size = image.size;

    UICollectionView *collectionView = nil;
    UIView *view = self;
    while (view) {
        if ([view isKindOfClass:UICollectionView.class]) {
            collectionView = (UICollectionView *)view;
            break;
        }
        view = view.superview;
    }
    if (!collectionView) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView performWithoutAnimation:^{
            [collectionView.collectionViewLayout invalidateLayout];
            [collectionView performBatchUpdates:nil completion:nil];
            [collectionView layoutIfNeeded];
        }];
    });
}

+ (CGSize)baseVideoSizeForModel:(AIOIUEHMessageModel *)msgModel withViewWidth:(CGFloat)width {
    WFCCVideoMessageContent *imgContent = (WFCCVideoMessageContent *)msgModel.message.content;
    
    CGSize size = imgContent.size;
    
//    if (size.height > width || size.width > width) {
//        float scale = MIN(width/size.height, width/size.width);
//        size = CGSizeMake(size.width * scale, size.height * scale);
//        isCustom = NO;
//    }

    // 该逻辑0126新增 主要是为视频缩略图压缩成120规格所定义
    if (size.height == 750 || size.width == 750) {
        if (size.height == 750) {
            size = CGSizeMake(size.width/750.0*120.0, 120.0);
        }else {
            size = CGSizeMake(120.0, size.height/750.0*120.0);
        }
    }else {
        if (size.height > width || size.width > width) {
            float scale = MIN(width/size.height, width/size.width);
            size = CGSizeMake(size.width * scale, size.height * scale);
        }
    }
    
    return size;
}

+ (CGSize)sizeForClientArea:(AIOIUEHMessageModel *)msgModel withViewWidth:(CGFloat)width {
    CGSize mediaSize = [self baseVideoSizeForModel:msgModel withViewWidth:width];
    NSString *caption = [SMIOUEJMediaMessageCell mediaCaptionForModel:msgModel];
    if (!caption.length) {
        return mediaSize;
    }

    WFCCVideoMessageContent *videoContent = (WFCCVideoMessageContent *)msgModel.message.content;
    CGSize sourceSize = CGSizeEqualToSize(videoContent.size, CGSizeZero) ? mediaSize : videoContent.size;
    CGSize displaySize = [SMIOUEJMediaMessageCell mediaDisplaySizeForSourceSize:sourceSize
                                                               constrainedWidth:width];
    CGFloat displayWidth = MIN(width, MAX(180.0, displaySize.width));
    CGSize captionSize = [SMIOUEJMediaMessageCell mediaCaptionSizeForModel:msgModel
                                                          constrainedWidth:displayWidth - 24.0];
    return CGSizeMake(displayWidth, displaySize.height + 8.0 + captionSize.height + 8.0);
}

- (void)setModel:(AIOIUEHMessageModel *)model {
    [super setModel:model];
    
    WFCCVideoMessageContent *imgContent = (WFCCVideoMessageContent *)model.message.content;
    NSString *caption = [SMIOUEJMediaMessageCell mediaCaptionForModel:model];
    if (caption.length) {
        CGSize clientSize = self.tzboeuContentArea.bounds.size;
        CGSize captionSize = [SMIOUEJMediaMessageCell mediaCaptionSizeForModel:model
                                                              constrainedWidth:clientSize.width - 24.0];
        CGSize sourceSize = CGSizeEqualToSize(imgContent.size, CGSizeZero) ? imgContent.thumbnail.size : imgContent.size;
        CGSize displaySize = [SMIOUEJMediaMessageCell mediaDisplaySizeForSourceSize:sourceSize
                                                                   constrainedWidth:clientSize.width];
        CGFloat horizontalInset = model.message.direction == MessageDirection_Send ? 8.0 : 16.0;
        CGFloat mediaX = horizontalInset + MAX(0, (clientSize.width - displaySize.width) / 2.0);
        self.tzboeuThumbnailView.frame = CGRectMake(mediaX, 6.0, displaySize.width, displaySize.height);
        self.captionLabel.hidden = NO;
        self.captionLabel.text = caption;
        UIColor *captionColor = [UIColor colorWithWhite:0.12 alpha:1.0];
        if (model.message.direction == MessageDirection_Receive) {
            if (@available(iOS 13.0, *)) {
                captionColor = UIColor.labelColor;
            }
        }
        self.captionLabel.textColor = captionColor;
        self.captionLabel.frame = CGRectMake(horizontalInset + 12.0,
                                             CGRectGetMaxY(self.tzboeuThumbnailView.frame) + 6.0,
                                             clientSize.width - 24.0,
                                             captionSize.height);
    } else {
        self.tzboeuThumbnailView.frame = self.tzboeuBubbleView.bounds;
        self.captionLabel.hidden = YES;
        self.captionLabel.text = nil;
    }
    
    self.tzboeuThumbnailView.contentMode = caption.length ? UIViewContentModeScaleAspectFit : UIViewContentModeScaleAspectFill;
    self.tzboeuThumbnailView.clipsToBounds = YES;
    
    if (imgContent.thumbnailUrl && imgContent.thumbnailUrl.length > 0) {
        // 构造 URL（注意要对 URL 编码）
        NSURL *url = [NSURL URLWithString:imgContent.thumbnailUrl];

        if (!url) {
            self.tzboeuThumbnailView.image = nil;
        } else {
            // 使用 AvoidAutoSetImage 避免闪烁
            [self.tzboeuThumbnailView sd_setImageWithURL:url
                                     placeholderImage:nil
                                              options:SDWebImageAvoidAutoSetImage | SDWebImageScaleDownLargeImages
                                              context:@{
                SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever),
                SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)
            }
                                             progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                
            } completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                if (image) {
                    [self refreshLayoutForLoadedThumbnail:image];
                    // 使用淡入动画只在非缓存加载时（避免闪烁）
                    if (cacheType == SDImageCacheTypeNone) {
                        self.tzboeuThumbnailView.alpha = 0.0;
                        self.tzboeuThumbnailView.image = image;
                        [UIView animateWithDuration:0.2 animations:^{
                            self.tzboeuThumbnailView.alpha = 1.0;
                        }];
                    } else {
                        // 缓存加载的图片，直接显示
                        self.tzboeuThumbnailView.image = image;
                    }
                } else {
                    // 失败时使用占位图
                    self.tzboeuThumbnailView.image = nil;
                }
            }];
        }
    } else {
        self.tzboeuThumbnailView.image = imgContent.thumbnail;
    }
//    NSURL *url = [NSURL URLWithString:imgContent.thumbnailUrl];
//    SDImageCache *cache = [SDImageCache sharedImageCache];
//    NSString *cacheKey = url.absoluteString;
//    UIImage *cachedImage = [cache imageFromCacheForKey:cacheKey];
//    if (cachedImage) {
//        // 有缓存，直接显示，避免闪烁
//        self.tzboeuThumbnailView.image = cachedImage;
//        // 这里依然可以后台刷新（可选）
//        [self.tzboeuThumbnailView sd_setImageWithURL:url
//                                  placeholderImage:nil
//                                           options:SDWebImageRetryFailed|SDWebImageLowPriority
//                                           context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever),
//                                                     SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
//    } else {
//        // 没有缓存：用占位图，必然有一次切换
//        [self.tzboeuThumbnailView sd_setImageWithURL:url
//                                  placeholderImage:nil
//                                           options:SDWebImageRetryFailed|SDWebImageLowPriority|SDWebImageScaleDownLargeImages
//                                           context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever),
//                                                     SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
//    }
    
    self.tzboeuVideoCoverView.frame = CGRectMake(CGRectGetMidX(self.tzboeuThumbnailView.frame) - 20.0,
                                                 CGRectGetMidY(self.tzboeuThumbnailView.frame) - 20.0,
                                                 40.0,
                                                 40.0);
    self.tzboeuVideoCoverView.image = [AIOIUEHImage imageNamed:@"video_msg_cover_w"];
    self.tzboeuVideoCoverView.hidden = NO;
    self.tzboeuVideoCoverView.alpha = 1.0;
    [self.tzboeuBubbleView bringSubviewToFront:self.tzboeuVideoCoverView];
}

- (UIImageView *)tzboeuThumbnailView {
    if (!_tzboeuThumbnailView) {
        _tzboeuThumbnailView = [[UIImageView alloc] init];
        [self.tzboeuBubbleView addSubview:_tzboeuThumbnailView];
    }
    return _tzboeuThumbnailView;
}

- (UIImageView *)tzboeuVideoCoverView {
    if (!_tzboeuVideoCoverView) {
        _tzboeuVideoCoverView = [[UIImageView alloc] init];
        _tzboeuVideoCoverView.backgroundColor = [UIColor clearColor];
        [self.tzboeuBubbleView addSubview:_tzboeuVideoCoverView];
    }
    return _tzboeuVideoCoverView;
}

- (UILabel *)captionLabel {
    if (!_captionLabel) {
        _captionLabel = [[UILabel alloc] init];
        _captionLabel.font = [UIFont systemFontOfSize:15.0];
        _captionLabel.numberOfLines = 0;
        _captionLabel.hidden = YES;
        [self.tzboeuBubbleView addSubview:_captionLabel];
    }
    return _captionLabel;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.tzboeuThumbnailView sd_cancelCurrentImageLoad];
    self.tzboeuThumbnailView.image = nil;
    self.captionLabel.text = nil;
    self.captionLabel.hidden = YES;
}

- (void)setMaskImage:(UIImage *)maskImage{
    [super setMaskImage:maskImage];
    if (_shadowMaskView) {
        [_shadowMaskView removeFromSuperview];
    }
    _shadowMaskView = [[UIImageView alloc] initWithImage:maskImage];
    
    CGRect frame = CGRectMake(self.tzboeuBubbleView.frame.origin.x - 1, self.tzboeuBubbleView.frame.origin.y - 1, self.tzboeuBubbleView.frame.size.width + 2, self.tzboeuBubbleView.frame.size.height + 2);
    _shadowMaskView.frame = frame;
    [self.contentView addSubview:_shadowMaskView];
    [self.contentView bringSubviewToFront:self.tzboeuBubbleView];
    
}

- (UIView *)getProgressParentView {
    return self.tzboeuThumbnailView;
}
@end
