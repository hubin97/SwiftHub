//
//  HomeTabBarViewModel.swift
//  SwiftHub
//
//  Created by Khoren Markosyan on 7/11/18.
//  Copyright © 2018 Khoren Markosyan. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import WhatsNewKit

// HomeTabBarViewModel 类，用于管理主页底部标签栏的逻辑
class HomeTabBarViewModel: ViewModel, ViewModelType {

    // 输入结构体，包含一个触发显示新功能提示的可观察序列
    struct Input {
        let whatsNewTrigger: Observable<Void>
    }

    // 输出结构体，包含底部标签栏的项目数组和显示新功能提示的信号
    struct Output {
        let tabBarItems: Driver<[HomeTabBarItem]>
        let openWhatsNew: Driver<WhatsNewBlock>
    }

    // 用户是否已经授权登录
    let authorized: Bool
    
    // 新功能提示管理器
    let whatsNewManager: WhatsNewManager

    // 初始化方法
    init(authorized: Bool, provider: SwiftHubAPI) {
        self.authorized = authorized
        whatsNewManager = WhatsNewManager.shared
        super.init(provider: provider)
    }

    // 将输入信号转换为输出信号
    func transform(input: Input) -> Output {

        // 根据用户授权情况决定底部标签栏的项目数组
        let tabBarItems = Observable.just(authorized).map { (authorized) -> [HomeTabBarItem] in
            if authorized {
                return [.news, .search, .notifications, .settings]
            } else {
                return [.search, .login, .settings]
            }
        }.asDriver(onErrorJustReturn: [])

        // 获取新功能提示并在触发时发送信号
        let whatsNew = whatsNewManager.whatsNew()
        let whatsNewItems = input.whatsNewTrigger.take(1).map { _ in whatsNew }

        // 返回输出信号
        return Output(tabBarItems: tabBarItems,
                      openWhatsNew: whatsNewItems.asDriverOnErrorJustComplete())
    }

    // 根据底部标签栏项目返回对应的ViewModel
    func viewModel(for tabBarItem: HomeTabBarItem) -> ViewModel {
        switch tabBarItem {
        case .search:
            return SearchViewModel(provider: provider)
        case .news:
            let user = User.currentUser()!
            return EventsViewModel(mode: .user(user: user), provider: provider)
        case .notifications:
            return NotificationsViewModel(mode: .mine, provider: provider)
        case .settings:
            return SettingsViewModel(provider: provider)
        case .login:
            return LoginViewModel(provider: provider)
        }
    }
}

