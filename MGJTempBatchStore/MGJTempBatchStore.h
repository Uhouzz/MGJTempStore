//
//  MGJTempBatchStore.h
//  MGJAnalytics
//
//  Created by limboy on 12/2/14.
//  Copyright (c) 2014 mogujie. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  数据使用成功时，需要被调用的 block
 */
typedef void (^MGJTempBatchStoreConsumeSuccessBlock)();

/**
 *  数据使用失败时，需要被调用的 block
 */
typedef void (^MGJTempBatchStoreConsumeFailureBlock)();

/**
 *  临时存储多条数据的内容
 */
@interface MGJTempBatchStore : NSObject

/**
 *  当前文件的 size (byte)
 */
@property (nonatomic, readonly, assign) float fileSize;

/**
 *  当前时间和文件创建时间的间隔，单位为秒
 */
@property (nonatomic, readonly, assign) NSTimeInterval timeIntervalSinceCreated;

/**
 *  当前存储的内容
 */
@property (nonatomic, readonly, copy) NSString *dataString;

/**
 *  初始化方法，传一个文件路径过来，相对路径即可，会放到 Documents 目录下
 *
 *  @param filePath 文件路径，如果包含 / ，会自动创建目录
 *
 *  @return self
 */
- (instancetype)initWithFilePath:(NSString *)filePath;

/**
 *  从尾部添加数据
 *
 *  @param data 要添加的数据
 */
- (void)appendData:(NSString *)data;

/**
 *  移除所有数据
 */
- (void)clearData;

/**
 *  使用已经积累的数据
 *
 *  @param handler 第一个参数是当前文件中保存的内容，当使用成功时执行一下 successBlock，使用失败时执行以下 failureBlock
 */
- (void)consumeDataWithHandler:(void (^)(NSString *content, MGJTempBatchStoreConsumeSuccessBlock successBlock, MGJTempBatchStoreConsumeFailureBlock failureBlock))handler;

@end
