//
//  PropertyManagermentViewController.h
//  ReactiveCocoaDemo
//
//  Created by dajing on 14-6-5.
//  Copyright (c) 2014年 Anjuke. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PropertyManagermentViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *entrustedTbl;
@property (nonatomic, strong) NSString *uid;

@end