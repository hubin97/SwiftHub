//
//  ViewModelType.swift
//  SwiftHub
//
//  Created by Khoren Markosyan on 6/30/18.
//  Copyright © 2018 Khoren Markosyan. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import ObjectMapper

// ViewModelType 协议定义了一个transform方法，用于将输入转换为输出
protocol ViewModelType {
    associatedtype Input
    associatedtype Output

    func transform(input: Input) -> Output
}

// ViewModel 类，用于处理网络请求和错误处理
class ViewModel: NSObject {

    // 用于执行网络请求的提供者
    let provider: SwiftHubAPI

    // 当前页数，默认为1
    var page = 1

    // 加载状态指示器，表示页面加载状态、顶部加载状态和底部加载状态
    let loading = ActivityIndicator()
    let headerLoading = ActivityIndicator()
    let footerLoading = ActivityIndicator()

    // 错误跟踪器，用于跟踪页面中的错误
    let error = ErrorTracker()

    // 服务器返回的错误
    let serverError = PublishSubject<Error>()
    
    // 经过解析的错误
    let parsedError = PublishSubject<ApiError>()

    // 初始化方法
    init(provider: SwiftHubAPI) {
        self.provider = provider
        super.init()

        // 订阅服务器返回的错误，解析为ApiError并发送到parsedError
        serverError.asObservable().map { (error) -> ApiError? in
            do {
                let errorResponse = error as? MoyaError
                if let body = try errorResponse?.response?.mapJSON() as? [String: Any],
                    let errorResponse = Mapper<ErrorResponse>().map(JSON: body) {
                    return ApiError.serverError(response: errorResponse)
                }
            } catch {
                print(error)
            }
            return nil
        }.filterNil().bind(to: parsedError).disposed(by: rx.disposeBag)

        // 订阅parsedError，输出日志
        parsedError.subscribe(onNext: { (error) in
            logError("\(error)")
        }).disposed(by: rx.disposeBag)
    }

    // 析构函数，输出日志和检查资源计数
    deinit {
        logDebug("\(type(of: self)): Deinited")
        logResourcesCount()
    }
}
