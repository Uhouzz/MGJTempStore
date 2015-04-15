## MGJTempStore 是什么

MGJTempStore 是一个用于临时存储数据的 Objective-C 存储类库

## 使用场景

### 缓存统计信息

我们开发 App 时，一般都会在客户端埋一些监测点，比如「进入某个页面」，或「点击某个按钮」等，这些操作会进行地比较频繁，并且对实时性没有很高的要求，所以没有必要立即向 Server 端发送数据，这时就可以使用这个小工具来临时存储这些数据，等到时机成熟（比如文件 Size 大于 1K，或者更新时间 > 60 秒等）时再发送，还可以减少服务端的压力。发送失败也没有关系，这些数据依旧在，下次再取时还是可以拿到。

### 缓存没有网络下的请求

为了提升用户体验，有时我们希望在没有网络的情况下，也可以「假装」操作成功，只是数据是在客户端返回。这时就可以把这些请求先存到本地，等到网络连上时再去统一发送。

### 缓存日志

为了方便排查故障或统计客户端的运行情况，可能会在客户端记录一些日志，这时也可以用这个工具来实现。

## Demo

![](http://ww3.sinaimg.cn/large/afe37136gw1er66up7a78g20as0j87wh.gif)

## 使用

```objc
MGJTempStore *store = [[MGJTempStore alloc] initWithPath:@"tmp.txt"];
[store appendData:@"foobar"]; // 1
[store consumeDataWithHandler:^(NSString *content, MGJTempStoreConsumeSuccessBlock successBlock, MGJTempStoreConsumeFailureBlock failureBlock) {
//	failureBlock(); // 2
//	successBlock(); // 3
	});
}];
```

1. 写入数据，目前只接受 `NSString`
2. 拿到数据后，如果消费失败，则调用这个 Block，数据会被重新放回去
3. 如果消费成功，就调用这个 Block，数据会被清除
