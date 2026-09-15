//
//  EPIKNODWVCustomerServiceVC.m
//  WUHOIBDK
//
//  Created by Loooooo on 2/29/24.
//

#import "EPIKNODWVCustomerServiceVC.h"

@interface EPIKNODWVCustomerServiceVC ()

@property (weak, nonatomic) IBOutlet UILabel *openL;

@end

@implementation EPIKNODWVCustomerServiceVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = LLLLLL(@"CustomerService");
    
    if ([CommonHelper.main isChinese]) {
    }else {
        _openL.text = @"This feature will be available soon";
    }
}


@end
