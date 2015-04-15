//
//  DemoDetailViewController.m
//  MGJRequestManagerDemo
//
//  Created by limboy on 3/20/15.
//  Copyright (c) 2015 juangua. All rights reserved.
//

#import "DemoDetailViewController.h"
#import "DemoListViewController.h"
#import "MGJTempStore.h"

@interface DemoDetailViewController ()
@property (nonatomic) UITextView *resultTextView;
@property (nonatomic) SEL selectedSelector;
@property (nonatomic) MGJTempStore *store;
@end

@implementation DemoDetailViewController

+ (void)load
{
    DemoDetailViewController *detailViewController = [[DemoDetailViewController alloc] init];
    [DemoListViewController registerWithTitle:@"插入多条数据并消费成功" handler:^UIViewController *{
        detailViewController.selectedSelector = @selector(demoAppendData);
        return detailViewController;
    }];
    
    [DemoListViewController registerWithTitle:@"消费数据失败" handler:^UIViewController *{
        detailViewController.selectedSelector = @selector(consumeDataSuccess);
        return detailViewController;
    }];
    
    [DemoListViewController registerWithTitle:@"当数据大于一定量时再处理" handler:^UIViewController *{
        detailViewController.selectedSelector = @selector(consumeDataUntilSize);
        return detailViewController;
    }];
    
    [DemoListViewController registerWithTitle:@"获取文件最后修改时间" handler:^UIViewController *{
        detailViewController.selectedSelector = @selector(lastModifiedTime);
        return detailViewController;
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:239.f/255 green:239.f/255 blue:244.f/255 alpha:1];
    self.store = [[MGJTempStore alloc] initWithFilePath:@"temp"];
    [self.view addSubview:self.resultTextView];
    // Do any additional setup after loading the view.
}

- (void)appendLog:(NSString *)log
{
    NSString *currentLog = self.resultTextView.text;
    if (currentLog.length) {
        currentLog = [currentLog stringByAppendingString:[NSString stringWithFormat:@"\n----------\n%@", log]];
    } else {
        currentLog = log;
    }
    self.resultTextView.text = currentLog;
    [self.resultTextView sizeThatFits:CGSizeMake(self.view.frame.size.width, CGFLOAT_MAX)];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.store clearData];
    [self.store addObserver:self forKeyPath:@"fileSize" options:NSKeyValueObservingOptionNew context:nil];
    [self.resultTextView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
    [self performSelector:self.selectedSelector withObject:nil afterDelay:0];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.resultTextView removeObserver:self forKeyPath:@"contentSize"];
    [self.store removeObserver:self forKeyPath:@"fileSize"];
    self.resultTextView.text = @"";
}

- (UITextView *)resultTextView
{
    if (!_resultTextView) {
        NSInteger padding = 20;
        NSInteger viewWith = self.view.frame.size.width;
        NSInteger viewHeight = self.view.frame.size.height - 64;
        _resultTextView = [[UITextView alloc] initWithFrame:CGRectMake(padding, padding + 64, viewWith - padding * 2, viewHeight - padding * 2)];
        _resultTextView.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:1].CGColor;
        _resultTextView.layer.borderWidth = 1;
        _resultTextView.editable = NO;
        _resultTextView.contentInset = UIEdgeInsetsMake(-64, 0, 0, 0);
        _resultTextView.font = [UIFont systemFontOfSize:14];
        _resultTextView.textColor = [UIColor colorWithWhite:0.2 alpha:1];
        _resultTextView.contentOffset = CGPointZero;
    }
    return _resultTextView;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"contentSize"]) {
        NSInteger contentHeight = self.resultTextView.contentSize.height;
        NSInteger textViewHeight = self.resultTextView.frame.size.height;
        [self.resultTextView setContentOffset:CGPointMake(0, MAX(contentHeight - textViewHeight, 0)) animated:YES];
    }
    else if ([keyPath isEqualToString:@"fileSize"]) {
        if (self.store.fileSize > 1024) {
            [self appendLog:@"数据达到了 1K，可以使用了"];
        }
    }
}

#pragma mark -

- (void)demoAppendData
{
    [self appendLog:@"append data foo"];
    [self.store appendData:@"foo"];
    [self appendLog:@"append data bar"];
    [self.store appendData:@"bar"];
    [self.store consumeDataWithHandler:^(NSString *content, MGJTempStoreConsumeSuccessBlock successBlock, MGJTempStoreConsumeFailureBlock failureBlock) {
        [self appendLog:[NSString stringWithFormat:@"got content:%@", content]];
        successBlock();
    }];
}

- (void)consumeDataSuccess
{
    [self appendLog:@"写入数据: foobar"];
    [self.store appendData:@"foobar"];
    [self.store consumeDataWithHandler:^(NSString *content, MGJTempStoreConsumeSuccessBlock successBlock, MGJTempStoreConsumeFailureBlock failureBlock) {
        // 假设向服务器发送数据失败
        [self appendLog:[NSString stringWithFormat:@"拿到数据: %@", content]];
        failureBlock();
        [self appendLog:@"发送数据给服务器失败，数据自动放回"];
        // 这时数据会被重新放回去
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.store consumeDataWithHandler:^(NSString *content, MGJTempStoreConsumeSuccessBlock successBlock, MGJTempStoreConsumeFailureBlock failureBlock) {
                [self appendLog:[NSString stringWithFormat:@"再次获取数据: %@", content]];
                successBlock();
            }];
        });
    }];
}

- (void)consumeDataUntilSize
{
    [self appendLog:@"写入 1K 的数据"];
    
    NSString *stringToBeWritten = @"the quick brown fox jumps over the lazy dog\n";
    for (int i = 0; i < 25; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(i * 0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.store appendData:stringToBeWritten];
            [self appendLog:[NSString stringWithFormat:@"当前数据大小: %f", self.store.fileSize]];
        });
    }
    
}

- (void)lastModifiedTime
{
    [self appendLog:@"写入第一行数据"];
    [self.store appendData:@"第一行数据"];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self appendLog:[NSString stringWithFormat:@"%.3f 秒钟前更新", self.store.timeIntervalSinceLastModified]];
        [self.store appendData:@"第二行数据"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self appendLog:[NSString stringWithFormat:@"%.3f 秒钟前更新", self.store.timeIntervalSinceLastModified]];
        });
    });
}

@end