//
//  UsersViewModel.swift
//  SwiftHub
//
//  Created by Khoren Markosyan on 7/20/18.
//  Copyright © 2018 Khoren Markosyan. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import RxDataSources

// 用户视图模式的枚举类型
enum UsersMode {
    case followers(user: User)       // 查看用户的粉丝
    case following(user: User)       // 查看用户关注的人
    case watchers(repository: Repository)   // 查看仓库的观察者
    case stars(repository: Repository)      // 查看仓库的星标用户
    case contributors(repository: Repository) // 查看仓库的贡献者
}

// 用户视图模型类，继承自 ViewModel 和 ViewModelType
class UsersViewModel: ViewModel, ViewModelType {

    // 输入结构体，定义了各种输入事件
    struct Input {
        let headerRefresh: Observable<Void>      // 头部刷新事件
        let footerRefresh: Observable<Void>      // 底部刷新事件
        let keywordTrigger: Driver<String>       // 关键字触发事件
        let textDidBeginEditing: Driver<Void>    // 开始编辑文本事件
        let selection: Driver<UserCellViewModel> // 选择用户事件
    }

    // 输出结构体，定义了各种输出结果
    struct Output {
        let navigationTitle: Driver<String>      // 导航栏标题
        let items: BehaviorRelay<[UserCellViewModel]> // 用户项
        let imageUrl: Driver<URL?>               // 图片 URL
        let textDidBeginEditing: Driver<Void>    // 开始编辑文本事件
        let dismissKeyboard: Driver<Void>        // 关闭键盘事件
        let userSelected: Driver<UserViewModel>  // 选中的用户
    }

    // 当前的用户视图模式
    let mode: BehaviorRelay<UsersMode>

    // 初始化方法，传入用户视图模式和网络提供者
    init(mode: UsersMode, provider: SwiftHubAPI) {
        self.mode = BehaviorRelay(value: mode)
        super.init(provider: provider)
    }

    // 转换方法，将输入转换为输出
    func transform(input: Input) -> Output {
        let elements = BehaviorRelay<[UserCellViewModel]>(value: []) // 存储用户项的行为中继器
        let dismissKeyboard = input.selection.mapToVoid()           // 选择用户事件映射为关闭键盘事件

        // 处理头部刷新事件
        input.headerRefresh.flatMapLatest({ [weak self] () -> Observable<[UserCellViewModel]> in
            guard let self = self else { return Observable.just([]) }
            self.page = 1
            return self.request() // 请求数据
                .trackActivity(self.headerLoading) // 跟踪加载状态
        }).subscribe(onNext: { (items) in
            elements.accept(items) // 接收新的用户项
        }).disposed(by: rx.disposeBag)

        // 处理底部刷新事件
        input.footerRefresh.flatMapLatest({ [weak self] () -> Observable<[UserCellViewModel]> in
            guard let self = self else { return Observable.just([]) }
            self.page += 1
            return self.request() // 请求数据
                .trackActivity(self.footerLoading) // 跟踪加载状态
        }).subscribe(onNext: { (items) in
            elements.accept(elements.value + items) // 添加新的用户项到现有列表中
        }).disposed(by: rx.disposeBag)

        let textDidBeginEditing = input.textDidBeginEditing // 开始编辑文本事件

        // 映射选择的用户视图模型
        let userDetails = input.selection.map({ (cellViewModel) -> UserViewModel in
            let user = cellViewModel.user
            let viewModel = UserViewModel(user: user, provider: self.provider)
            return viewModel
        })

        // 根据模式设置导航栏标题
        let navigationTitle = mode.map({ (mode) -> String in
            switch mode {
            case .followers: return R.string.localizable.usersFollowersNavigationTitle.key.localized()
            case .following: return R.string.localizable.usersFollowingNavigationTitle.key.localized()
            case .watchers: return R.string.localizable.usersWatchersNavigationTitle.key.localized()
            case .stars: return R.string.localizable.usersStargazersNavigationTitle.key.localized()
            case .contributors: return R.string.localizable.usersContributorsNavigationTitle.key.localized()
            }
        }).asDriver(onErrorJustReturn: "")

        // 根据模式设置图片 URL
        let imageUrl = mode.map({ (mode) -> URL? in
            switch mode {
            case .followers(let user),
                 .following(let user):
                return user.avatarUrl?.url
            case .watchers(let repository),
                 .stars(let repository),
                 .contributors(let repository):
                return repository.owner?.avatarUrl?.url
            }
        }).asDriver(onErrorJustReturn: nil)

        return Output(navigationTitle: navigationTitle,
                      items: elements,
                      imageUrl: imageUrl,
                      textDidBeginEditing: textDidBeginEditing,
                      dismissKeyboard: dismissKeyboard,
                      userSelected: userDetails)
    }

    // 请求数据方法，根据当前模式请求不同的数据
    func request() -> Observable<[UserCellViewModel]> {
        var request: Single<[User]>
        switch self.mode.value {
        case .followers(let user):
            request = provider.userFollowers(username: user.login ?? "", page: page)
        case .following(let user):
            request = provider.userFollowing(username: user.login ?? "", page: page)
        case .watchers(let repository):
            request = provider.watchers(fullname: repository.fullname ?? "", page: page)
        case .stars(let repository):
            request = provider.stargazers(fullname: repository.fullname ?? "", page: page)
        case .contributors(let repository):
            request = provider.contributors(fullname: repository.fullname ?? "", page: page)
        }
        return request
            .trackActivity(loading) // 跟踪加载状态
            .trackError(error) // 跟踪错误状态
            .map { $0.map { UserCellViewModel(with: $0) } } // 将用户对象映射为用户视图模型
    }
}
