//
//  AIViewController.m
//  WildFireChat
//
//  Created by wtb on 2026/4/10.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import "AIViewController.h"
#import <WebKit/WebKit.h>
#import "AppService.h"

@interface AIViewController ()
@property(nonatomic, strong) WKWebView *webView;
@end

@implementation AIViewController

- (void)showErrorMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LLLLLL(@"AI_Tips")
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"AI_OK") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.title = @"AI";
    self.view.backgroundColor = UIColor.whiteColor;
    
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.webView];
    
    __weak typeof(self) weakSelf = self;
    [[AppService sharedAppService] aiUrl:^(NSString * _Nonnull url) {
        if (url.length == 0) {
            [weakSelf showErrorMessage:LLLLLL(@"AI_UrlEmpty")];
            return;
        }
        
        NSURL *requestURL = [NSURL URLWithString:url];
        if (!requestURL) {
            [weakSelf showErrorMessage:LLLLLL(@"AI_UrlInvalid")];
            return;
        }
        
        [weakSelf.webView loadRequest:[NSURLRequest requestWithURL:requestURL]];
    } error:^(int errCode, NSString * _Nonnull message) {
        [weakSelf showErrorMessage:message.length ? message : LLLLLL(@"AI_UrlLoadFailed")];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
}



@end
