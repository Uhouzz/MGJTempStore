//
//  MGJTempBatchStore.m
//  MGJAnalytics
//
//  Created by limboy on 12/2/14.
//  Copyright (c) 2014 mogujie. All rights reserved.
//

#import "MGJTempBatchStore.h"

@interface MGJTempBatchStore ()
@property (nonatomic, copy, readwrite) NSString *filePath;

/**
 *  当文件内容正在被使用时，会将当前文件重命名，这个就是重命名后的文件路径
 */
@property (nonatomic, copy) NSString *consumingFilePath;

/**
 *  DocumentPath
 */
@property (nonatomic, copy) NSString *baseDirectory;
@property (nonatomic) NSFileManager *fileManager;
@property (nonatomic, readwrite, copy) NSString *dataString;
@property (nonatomic, readwrite, assign) float fileSize;
@end

@implementation MGJTempBatchStore

#pragma mark - Public

- (instancetype)init
{
    return [self initWithFilePath:@""];
}

- (instancetype)initWithFilePath:(NSString *)filePath
{
    NSAssert(filePath, @"文件路径不能为空");
    
    if (self = [super init]) {
        self.baseDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        self.fileManager = [NSFileManager defaultManager];
        [self generateDirectoryForFilePath:filePath];
        self.filePath = [self.baseDirectory stringByAppendingPathComponent:filePath];
        self.consumingFilePath = [self.filePath stringByAppendingPathExtension:@"consuming"];
        if (![self.fileManager fileExistsAtPath:self.filePath]) {
            [self.fileManager createFileAtPath:self.filePath contents:nil attributes:nil];
        }
    }
    return self;
}

- (void)appendData:(NSString *)data
{
    NSFileHandle *fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:self.filePath];
    [fileHandler seekToEndOfFile];
    [fileHandler writeData:[data dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandler closeFile];
    self.fileSize = [[self.fileManager attributesOfItemAtPath:self.filePath error:nil] fileSize];
}

- (void)clearData
{
    [self.fileManager createFileAtPath:self.filePath contents:nil attributes:nil];
}

- (void)consumeDataWithHandler:(void (^)(NSString *, MGJTempBatchStoreConsumeSuccessBlock, MGJTempBatchStoreConsumeFailureBlock))handler
{
    NSData *fileData = [self.fileManager contentsAtPath:self.filePath];
    NSString *fileString = [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
    
    // 重命名当前文件为临时文件用于消费
    [self.fileManager moveItemAtPath:self.filePath toPath:self.consumingFilePath error:NULL];
    // 同时新建一个之前的文件，用于存储在消费过程中又产生的新内容
    [self.fileManager createFileAtPath:self.filePath contents:nil attributes:nil];
    
    void (^successHandler)() = ^{
        // 如果数据消费成功，那么中间状态的文件就可删掉了
        [self.fileManager removeItemAtPath:self.consumingFilePath error:NULL];
    };
    
    void (^failureHandler)() = ^{
        // 如果数据消费失败，把中间状态的文件内容再放回去
        // 先获取之前的内容，合并后再写入
        // TODO 这块或许还有更高效的实现
        NSMutableData *combinedFileData = [NSMutableData dataWithData:[self.fileManager contentsAtPath:self.filePath]];
        [combinedFileData appendData:fileData];
        NSFileHandle *fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:self.filePath];
        [fileHandler seekToFileOffset:0];
        [fileHandler writeData:combinedFileData];
        [fileHandler closeFile];
        [self.fileManager removeItemAtPath:self.consumingFilePath error:NULL];
    };
    
    handler(fileString, successHandler, failureHandler);
}

- (NSTimeInterval)timeIntervalSinceLastModified
{
    NSDate *creationDate = [[self.fileManager attributesOfItemAtPath:self.filePath error:nil] fileModificationDate];
    return [[NSDate date] timeIntervalSinceDate:creationDate];
}

- (NSString *)dataString
{
    NSData *fileData = [self.fileManager contentsAtPath:self.filePath];
    return [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
}

#pragma mark - Utils

- (void)generateDirectoryForFilePath:(NSString *)filePath
{
    if ([filePath rangeOfString:@"/"].location != NSNotFound) {
        NSString *directoryPath = [self.baseDirectory stringByAppendingPathComponent:[filePath stringByDeletingLastPathComponent]];
        NSError *createError;
        [self.fileManager createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:&createError];
        if (createError) {
            NSLog(@"<MGJTempBatchStore> Create Directory For File Path error :%@", createError);
        }
    }
}

@end
