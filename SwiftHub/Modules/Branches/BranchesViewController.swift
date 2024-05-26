//
//  BranchesViewController.swift
//  SwiftHub
//
//  Created by Sygnoos9 on 4/6/19.
//  Copyright © 2019 Khoren Markosyan. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

private let reuseIdentifier = R.reuseIdentifier.branchCell.identifier

class BranchesViewController: TableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func makeUI() {
        super.makeUI()

        tableView.register(R.nib.branchCell)
    }

    override func bindViewModel() {
        super.bindViewModel()
        guard let viewModel = viewModel as? BranchesViewModel else { return }

        let refresh = Observable.of(Observable.just(()), headerRefreshTrigger).merge()
        let input = BranchesViewModel.Input(headerRefresh: refresh,
                                            footerRefresh: footerRefreshTrigger,
                                            selection: tableView.rx.modelSelected(BranchCellViewModel.self).asDriver())
        let output = viewModel.transform(input: input)

        output.navigationTitle.drive(onNext: { [weak self] (title) in
            self?.navigationTitle = title
        }).disposed(by: rx.disposeBag)

        // 将数据绑定到tableView上
        output.items.asDriver(onErrorJustReturn: [])
            .drive(
                // 使用RxCocoa的rx.items方法，将数据源和UITableView绑定
                tableView.rx.items(
                    // 指定cell的identifier和cell的类型
                    cellIdentifier: reuseIdentifier,
                    cellType: BranchCell.self
                )
            ) { tableView, viewModel, cell in
                // 在闭包中，绑定cell和对应的ViewModel
                cell.bind(to: viewModel)
            }
            // 使用disposeBag来管理RxSwift的资源释放
            .disposed(by: rx.disposeBag)

        viewModel.branchSelected.subscribe(onNext: { [weak self] (branch) in
            self?.navigator.pop(sender: self)
        }).disposed(by: rx.disposeBag)
    }
}
