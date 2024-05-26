//
//  UserCellViewModel.swift
//  SwiftHub
//
//  Created by Khoren Markosyan on 6/30/18.
//  Copyright © 2018 Khoren Markosyan. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import BonMot

class UserCellViewModel: DefaultTableViewCellViewModel {

    // 当前用户是否已关注该用户
    let following = BehaviorRelay<Bool>(value: false)
    
    // 是否隐藏关注按钮
    let hidesFollowButton = BehaviorRelay<Bool>(value: true)

    // 用户对象
    let user: User

    init(with user: User) {
        self.user = user
        super.init()

        // 设置用户名
        title.accept(user.login)

        // 设置用户详情：贡献次数或姓名
        detail.accept("\((user.contributions != nil) ? "\(user.contributions ?? 0) commits" : (user.name ?? ""))")

        // 设置带样式的用户详情
        attributedDetail.accept(user.attributetDetail())

        // 设置用户头像 URL
        imageUrl.accept(user.avatarUrl)

        // 设置徽章图片
        badge.accept(R.image.icon_cell_badge_user()?.template)
        badgeColor.accept(UIColor.Material.green900)

        // 设置当前用户是否已关注该用户
        following.accept(user.viewerIsFollowing ?? false)

        // 根据登录状态和用户是否可被关注来决定是否隐藏关注按钮
        loggedIn.map({ loggedIn -> Bool in
            if !loggedIn { return true }
            if let viewerCanFollow = user.viewerCanFollow { return !viewerCanFollow }
            return true
        }).bind(to: hidesFollowButton).disposed(by: rx.disposeBag)
    }
}

extension UserCellViewModel {
    // 重载等于操作符，用于比较两个 UserCellViewModel 是否相等
    static func == (lhs: UserCellViewModel, rhs: UserCellViewModel) -> Bool {
        return lhs.user == rhs.user
    }
}

extension User {
    // 生成带样式的用户详情文本
    func attributetDetail() -> NSAttributedString? {
        var texts: [NSAttributedString] = []
        
        // 添加仓库数目文本
        if let repositoriesString = repositoriesCount?.string.styled(with: .color(UIColor.text())) {
            let repositoriesImage = R.image.icon_cell_badge_repository()?.filled(withColor: UIColor.text()).scaled(toHeight: 15)?.styled(with: .baselineOffset(-3)) ?? NSAttributedString()
            texts.append(NSAttributedString.composed(of: [
                repositoriesImage, Special.space, repositoriesString, Special.space, Special.tab
            ]))
        }

        // 添加粉丝数目文本
        if let followersString = followers?.kFormatted().styled(with: .color(UIColor.text())) {
            let followersImage = R.image.icon_cell_badge_collaborator()?.filled(withColor: UIColor.text()).scaled(toHeight: 15)?.styled(with: .baselineOffset(-3)) ?? NSAttributedString()
            texts.append(NSAttributedString.composed(of: [
                followersImage, Special.space, followersString
            ]))
        }
        
        return NSAttributedString.composed(of: texts)
    }
}
