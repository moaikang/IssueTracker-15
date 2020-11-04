//
//  IssueFilterViewModel.swift
//  IssueTracker
//
//  Created by 김신우 on 2020/11/04.
//  Copyright © 2020 IssueTracker-15. All rights reserved.
//

import Foundation

protocol IssueFilterViewModelProtocol: AnyObject {
    func generalConditionSelected(at type: Condition)
    func detailConditionSelected(at type: DetailCondition, id: Int?)
    func condition(of type: Condition) -> Bool
    func detailCondition(of type: DetailCondition) -> ConditionCellViewModel?
    func detailConditionDataSource(of type: DetailCondition) -> [[ConditionCellViewModel]]
}

enum Condition: Int, CaseIterable {
    case issueOpened = 0
    case issueFromMe = 1
    case issueAssignedToMe = 2
    case issueCommentedByMe = 3
    case issueClosed = 4
}

enum DetailCondition: Int, CaseIterable {
    case writer = 0
    case label = 1
    case milestone = 2
    case assignee = 3
}

class IssueFilterViewModel: IssueFilterViewModelProtocol {
    
    private weak var labelProvider: LabelProvidable?
    private weak var milestoneProvider: MilestoneProvidable?
    private weak var issueProvider: IssueProvidable?
    
    // TODO: UserInfoProvider
    private var mockUserInfo = [
        ConditionCellViewModel(title: "SHIVVVPP", element: "2020-08-11T00:00:00.000Z"),
        ConditionCellViewModel(title: "유시형", element: "2020-08-11T00:00:00.000Z"),
        ConditionCellViewModel(title: "namda-on", element: "2020-08-11T00:00:00.000Z"),
        ConditionCellViewModel(title: "moaikang", element: "2020-08-11T00:00:00.000Z"),
        ConditionCellViewModel(title: "maong0927", element: "2020-08-11T00:00:00.000Z")
       ]
    
    private(set) var generalConditions = [Bool](repeating: false, count: Condition.allCases.count)
    // [id] -> [-1] = all
    private(set) var detailConditions = [Int](repeating: -1, count: DetailCondition.allCases.count)
    
    init(labelProvider: LabelProvidable, milestoneProvider: MilestoneProvidable, issueProvider: IssueProvidable) {
        self.labelProvider = labelProvider
        self.milestoneProvider = milestoneProvider
        self.issueProvider = issueProvider
    }
    
    func generalConditionSelected(at type: Condition) {
        generalConditions[type.rawValue] = !generalConditions[type.rawValue]
    }
    
    func detailConditionSelected(at type: DetailCondition, id: Int?) {
        detailConditions[type.rawValue] = id ?? -1
    }
    
    func condition(of type: Condition) -> Bool {
        return generalConditions[type.rawValue]
    }
    
    func detailCondition(of type: DetailCondition) -> ConditionCellViewModel? {
        let id = detailConditions[type.rawValue]
        if id == -1 { return nil }
        
        switch type {
        case .assignee, .writer:
            return mockUserInfo.first(where: {$0.id == id})
        case .label:
            guard let label = labelProvider?.labels.first(where: {$0.id == id}) else { return nil }
            return ConditionCellViewModel(label: label)
        case .milestone:
            guard let milestone = milestoneProvider?.milestons.first(where: {$0.id == id}) else { return nil }
            return ConditionCellViewModel(milestone: milestone)
        }
    }
    
    func detailConditionDataSource(of type: DetailCondition) -> [[ConditionCellViewModel]] {
        var viewModels: [[ConditionCellViewModel]] = [[], []]
        switch type {
        case .assignee, .writer:
            // TODO: UserInfoProvider 구현
            viewModels = [ [], mockUserInfo  ]
        case .label:
            labelProvider?.labels.forEach {
                let viewModel = ConditionCellViewModel(label: $0)
                if $0.id == detailConditions[type.rawValue] {
                    viewModels[0].append(viewModel)
                } else {
                    viewModels[1].append(viewModel)
                }
            }
        case .milestone:
            milestoneProvider?.milestons.forEach {
                let viewModel = ConditionCellViewModel(milestone: $0)
                if $0.id == detailConditions[type.rawValue] {
                    viewModels[0].append(viewModel)
                } else {
                    viewModels[1].append(viewModel)
                }
            }
        }
        return viewModels
    }
    
}
