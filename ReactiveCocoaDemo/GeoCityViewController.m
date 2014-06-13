//
//  GeoCityViewController
//  ReactiveCocoaDemo
//
//  Created by dajing on 14-6-5.
//  Copyright (c) 2014年 Anjuke. All rights reserved.
//

#import "GeoCityViewController.h"
#import "GeoCityViewModel.h"
#import "MyTableViewCell.h"
#import "AddCityViewController.h"
#import "City.h"

@interface GeoCityViewController ()<UITableViewDataSource, SaveDataCallBack>

@property (nonatomic, strong) GeoCityViewModel *viewModel;

@end

@implementation GeoCityViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // setup lots of bindings
    [self bindViewModel];
    
    // set uid to enable searchCommand
    self.uid = @"124242";
    
    // execute searchCommand
    [self.viewModel.searchCommand execute:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)bindViewModel {
    @weakify(self);

    // init viewModel
    self.viewModel = [GeoCityViewModel new];
    
    // bind self.uid to viewModel.uid
    RAC(self.viewModel, uid) = RACObserve(self, uid);

    // suscribe viewModel.entrustedProperties to refresh tableview
    [RACObserve(self.viewModel, cities) subscribeNext:^(id x) {
        @strongify(self);
        [self.entrustedTbl reloadData];
    }];
    
    // bind viewModel.searchCommand.executing to the invisible of loading indicator
    /* using   RAC([UIApplication sharedApplication], networkActivityIndicatorVisible) = self.viewModel.searchCommand.executing;
        will crash when u request data second time, dont know why, expect reason...
     */
    [[RACObserve(self.viewModel.searchCommand, executing) flattenMap:^RACStream *(id value) {
        return value;
    }] subscribeNext:^(id x) {
        @strongify(self);

        BOOL isLoading = [x boolValue];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = isLoading;
        self.btnAdd.enabled = !isLoading;
    }];
    
    // subscribe statusMessage to show the alert
    [[RACObserve(self.viewModel, statusMessage) filter:^BOOL(id value) {
        return value != nil;
    }]
     subscribeNext:^(NSString *msg) {
        UIAlertView *msgAlert = [[UIAlertView alloc] initWithTitle:msg message:msg delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [msgAlert show];
    }];
    
    // set tableview datasource to self, the cell render logic will be placed in this viewcontroller
    self.entrustedTbl.dataSource = self;
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.cities.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"identifierCell";

    MyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[MyTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    cell.city = self.viewModel.cities[indexPath.row];

    [cell configCell];
    
    return  cell;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    AddCityViewController *addController = (AddCityViewController *)[segue destinationViewController];
    
    [[[self rac_signalForSelector:@selector(didSaveDataCallback:) fromProtocol:@protocol(SaveDataCallBack)]
     deliverOn:[RACScheduler mainThreadScheduler]]
    subscribeNext:^(RACTuple *tuple) {
        City *newCity = tuple.first;
        [self.viewModel.cities addObject:newCity];
        // need to refresh the table, because the signal is release when pushing new controller
        [self.entrustedTbl reloadData];
    }];
    
    // Need to "reset" the cached values of respondsToSelector: of UIKit
    // due to the issue @giuhub https://github.com/ReactiveCocoa/ReactiveCocoa/issues/1121
    addController.delegate = self;
}

@end
