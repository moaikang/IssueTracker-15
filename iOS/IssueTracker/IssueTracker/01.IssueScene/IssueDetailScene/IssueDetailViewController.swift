//
//  IssueDetailViewController-tmp.swift
//  IssueTracker
//
//  Created by sihyung you on 2020/11/05.
//  Copyright © 2020 IssueTracker-15. All rights reserved.
//

import UIKit

class IssueDetailViewController: UIViewController {
    static let identifier = "IssueDetailViewController"
    
    @IBOutlet weak var collectionView: UICollectionView!
    private var bottomSheetView: BottomSheetView?
    private var issueDetailViewModel: IssueDetailViewModelProtocol
    
    let contentBlurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .dark)
        let blurredEffectView = UIVisualEffectView(effect: blurEffect)
        blurredEffectView.translatesAutoresizingMaskIntoConstraints = false
        blurredEffectView.alpha = 0
        return blurredEffectView
    }()
    
    let navBarBlurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .dark)
        let blurredEffectView = UIVisualEffectView(effect: blurEffect)
        blurredEffectView.translatesAutoresizingMaskIntoConstraints = false
        blurredEffectView.alpha = 0
        return blurredEffectView
    }()
    
    private var currentIndexPath: IndexPath? {
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.frame.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.minY)
        if let currentIndexPath = collectionView.indexPathForItem(at: visiblePoint) {
            return currentIndexPath
        } else {
            return IndexPath(item: -1, section: 0)
        }
    }
    
    init(nibName: String, bundle: Bundle?, viewModel: IssueDetailViewModelProtocol) {
        self.issueDetailViewModel = viewModel
        super.init(nibName: nibName, bundle: bundle)
        
        self.issueDetailViewModel.didFetch = { [weak self] in
            self?.collectionView.reloadData()
            self?.bottomSheetView?.reloadData()
        }
    }
    
    required init?(coder: NSCoder) {
        issueDetailViewModel = IssueDetailViewModel(id: 1, issueProvider: nil, labelProvier: nil, milestoneProvider: nil)
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBarBlur()
        setupContentBlur()
        configureEditButton()
        issueDetailViewModel.needFetchDetails()
        configureCollectionView()
        configureBottomSheetView()
        navigationItem.title = "이슈 상세"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.largeTitleDisplayMode = .never
        self.tabBarController?.tabBar.isHidden = true
        let height = UIScreen.main.bounds.height
        let width  = UIScreen.main.bounds.width
        bottomSheetView?.frame = CGRect(x: 0, y: height * 0.9, width: width, height: height)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    private func setupNavBarBlur() {
        let navBarHeight = navigationController?.navigationBar.frame.height ?? 50
        self.navigationController?.navigationBar.addSubview(navBarBlurView)
        
        NSLayoutConstraint.activate([
            navBarBlurView.topAnchor.constraint(equalTo: (self.navigationController?.navigationBar.topAnchor)!, constant: -1 * navBarHeight),
            navBarBlurView.leadingAnchor.constraint(equalTo: (self.navigationController?.navigationBar.leadingAnchor)!),
            navBarBlurView.trailingAnchor.constraint(equalTo: (self.navigationController?.navigationBar.trailingAnchor)!),
            navBarBlurView.bottomAnchor.constraint(equalTo: (self.navigationController?.navigationBar.bottomAnchor)!)
        ])
    }
    
    private func setupContentBlur() {
        self.view.addSubview(contentBlurView)
        
        NSLayoutConstraint.activate([
            contentBlurView.topAnchor.constraint(equalTo: self.view.topAnchor),
            contentBlurView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            contentBlurView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            contentBlurView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
    
    private func configureEditButton() {
        let editButton = UIBarButtonItem(title: "Edit", style: .done, target: self, action: #selector(editButtonTapped))
        self.navigationItem.rightBarButtonItem = editButton
    }
    
    @objc func editButtonTapped() {
        let previousData: PreviousData = PreviousData(title: issueDetailViewModel.title,
                                                      description: issueDetailViewModel.description ?? "",
                                                      issueNumber: String(issueDetailViewModel.issueNumber))
        
        AddNewIssueViewController.present(at: self, addType: .editIssue, previousData: previousData) { [weak self] (content) in
            let editedTitle = content[0]
            let editedDescription = content[1]
            self?.issueDetailViewModel.editIssue(title: editedTitle, description: editedDescription)
        }
    }
    
    private func configureCollectionView() {
        setupCollectionViewLayout()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.registerHeader(type: IssueDetailHeaderView.self)
        collectionView.registerCell(type: IssueDetailCellView.self)
    }
    
    private func configureBottomSheetView() {
        guard let bottomSheetView = BottomSheetView.createView() else { return }
        bottomSheetView.configure(issueDetailViewModel: issueDetailViewModel)
        bottomSheetView.delegate = self
        
        self.bottomSheetView = bottomSheetView
        self.view.addSubview(bottomSheetView)
    }
    
    private func setupCollectionViewLayout() {
        let flowLayout = UICollectionViewFlowLayout()
        let width = self.view.frame.size.width
        let headerHeight = UIScreen.main.bounds.height * 0.2
        
        flowLayout.estimatedItemSize = CGSize(width: width, height: headerHeight)
        flowLayout.sectionInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        flowLayout.headerReferenceSize = CGSize(width: UIScreen.main.bounds.width, height: headerHeight)
        
        collectionView.collectionViewLayout = flowLayout
    }
}

// MARK: - UICollectionViewDataSource implementation

extension IssueDetailViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return issueDetailViewModel.comments.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell: IssueDetailCellView = collectionView.dequeueCell(at: indexPath) else { return UICollectionViewCell() }
        cell.configure(with: issueDetailViewModel.comments[indexPath.row])
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let header: IssueDetailHeaderView = collectionView.dequeueHeader(at: indexPath) else { return UICollectionReusableView() }
        
        header.configure(with: issueDetailViewModel.headerViewModel)
        return header
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
}

// MARK: - UICollectionViewDelegateFlowLayout Implementation

extension IssueDetailViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let indexPath = IndexPath(row: 0, section: section)
        
        if let headerView = self.collectionView(collectionView, viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionHeader, at: indexPath) as? IssueDetailHeaderView {
            
            let size = CGSize(width: collectionView.frame.width, height: UIView.layoutFittingCompressedSize.height)
            return headerView.systemLayoutSizeFitting(size, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        }
        
        return CGSize(width: self.view.frame.width, height: CGFloat(100))
    }
    
}

// MARK: - BottomSheetViewDelegate Implementatioin

extension IssueDetailViewController: BottomSheetViewDelegate {
    
    func heightChanged(with newHeight: CGFloat) {
        let newAlpha = newHeight / 1000
        DispatchQueue.main.async { [weak self] in
            self?.contentBlurView.alpha = (newAlpha - 0.5) * -1
            self?.navBarBlurView.alpha = (newAlpha - 0.5) * -1
        }
    }
    
    func categoryHeaderTapped(type: DetailSelectionType) {
        let maximumSelection = type == .milestone ? 1 : 0
        let dataSource = issueDetailViewModel.detailSelectionItemDataSource(of: type)
        let viewModel = DetailSelectionViewModel(detailCondition: type, viewModelDataSource: dataSource, maxSelection: maximumSelection)
        let vc = DetailSelectionViewController.createViewController(with: viewModel)
        vc.onSelectionComplete = { selectedItems in
            self.issueDetailViewModel.detailItemSelected(type: type, selectedItems: selectedItems)
        }
        present(vc, animated: true)
    }
    
    func upButtonTapped() {
        guard let currentIndexPath = self.currentIndexPath else { return }
        
        if currentIndexPath.item == 0 {
            UIView.animate(withDuration: 0.5, animations: {
                self.collectionView.contentOffset = CGPoint.zero
            })
        } else if currentIndexPath.item != -1 {
            self.collectionView.scrollToItem(at: IndexPath(item: currentIndexPath.item - 1, section: 0), at: .top, animated: true)
        }
    }
    
    func downButtonTapped() {
        guard let currentIndexPath = self.currentIndexPath else { return }
        
        if currentIndexPath.item < self.issueDetailViewModel.comments.count - 1 {
            self.collectionView.scrollToItem(at: IndexPath(item: currentIndexPath.item + 1, section: 0), at: .top, animated: true)
        }
    }
    
    func stateToggleButtonTapped() {
        issueDetailViewModel.toggleIssueState()
    }
    
    func addCommentButtonTapped() {
        AddNewIssueViewController.present(at: self, addType: .newComment, previousData: nil, onDismiss: { [weak self] (content) in
            self?.issueDetailViewModel.addComment(content: content[0])
        })
    }
    
}

// MARK: - Create ViewController

extension IssueDetailViewController {
    static let nibName = "IssueDetailViewController"
    
    static func createViewController(issueDetailViewModel: IssueDetailViewModel) -> IssueDetailViewController {
        let vc = IssueDetailViewController(nibName: nibName, bundle: Bundle.main, viewModel: issueDetailViewModel)
        return vc
    }
}
