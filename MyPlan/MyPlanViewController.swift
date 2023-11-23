import UIKit

protocol MyPlanViewControllerProtocol: UIViewController {
    func display(topViewEntity: MyPlanEntity.ViewEntity.TopViewEntity?, sections: [MyPlanEntity.ViewEntity.SectionEntity])
    func showVideoPlayer(url: String, currentDay: Int, isCurrentDayOfPlan: Bool, workout: BaseModels.Response.Workout?)
    func showError(error: Error)
    func setupBlockScreen(flag: Bool)
    func showHints()
    func showWorkoutRatePopUpIfNecessary(workoutPassed: Bool, needShowPopUp: Bool, workoutId: String, day: Int, force: Bool, completion: ((MyPlanEntity.RateAction, Bool) -> Void)? )
    func showChangeDifficultyPopUpIfNecessary(action: MyPlanEntity.RateAction, force: Bool)
    func showBottomView(_ show: Bool)
    func tryStartWorkout(_ workout: BaseModels.Response.Workout, day: Int)
}

class MyPlanViewController: UIViewController {
    // MARK: - IBOutlets
    @IBOutlet private weak var topView: UIView!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var isTodayLabel: UILabel!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var bottomView: UIView!
    @IBOutlet private weak var bottomViewTitle: UILabel!
    
    @IBOutlet private weak var topViewHeight: NSLayoutConstraint!
    @IBOutlet private weak var bottomViewHeight: NSLayoutConstraint!
    
    private var dayOffCell: UICollectionViewCell = UICollectionViewCell()
    private var dayOffCellWidth: CGFloat = 0
    
    // MARK: - Properties
    private let reachability = Reachability.shared
    
    private var dataSource = MyPlanCollectionViewDataSource()
    private var collectionViewLayout: MyPlanDayCompositionLayout = MyPlanDayCompositionLayout()
    
    private var shouldShowRatePopUp = false
    private var rateWorkout: (workoutId: String, day: Int)?
    
    private var hintsPresenter: HintsPresenterProtocol?
    private var presenter: MyPlanPresenterProtocol!
    
    private var sseClient: SSEClient?
    private var lastSSEAction: MyPlanEntity.RateAction?
    
    private var isActiveView: Bool = false
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter = MyPlanPresenter(view: self)
        
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reachability.startListening()
        presenter.getData()
        isActiveView = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isActiveView = false
    }
        
    // MARK: - UI
    private func setupViews() {
        setupBottonView()
        setupCollectionView()
        setupDataSource()
    }
    
    private func setupBottonView() {
        bottomView.viewCorner(MyPlanConstants.VCConstants.bottomViewCornerRadius)
        bottomViewTitle.text = StringValues.MyPlan.viewPlan.localized
        bottomViewHeight.constant = (self.tabBarController?.tabBar.frame.height ?? 49.0) + Screen.safeAreaBottom + MyPlanConstants.VCConstants.bottomViewHeight
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapViewPlan))
        bottomView.addGestureRecognizer(tap)
        
        guard LMConfiguration.shared.getQuizStatus() else { return }
        bottomView.isHidden = false
    }
    
    private func setupDataSource() {
        dataSource.dayAction = { [weak self] index in
            guard let self = self else { return }
            self.presenter.updateDayData(selectDay: index)
        }
        
        dataSource.displayHintsHandler = { [weak self] cell, width in
            guard let self = self else { return }
            if LMConfiguration.shared.wereHintsShown() {
                self.dayOffCell = cell
                self.dayOffCellWidth = width
                self.presenter.showHints()
            }
        }
        
        dataSource.answerQuestionsHandler = { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async { [weak self] in
                guard let _ = self else { return }
                let vc = QuestionsViewController.fromStoryboard
                let navigationController = UINavigationController(rootViewController: vc)
                navigationController.navigationBar.isHidden = true
                UIApplication.shared.windows.first?.rootViewController = navigationController
                UIApplication.shared.windows.first?.makeKeyAndVisible()
            }
        }
        
        dataSource.workoutsHeader = { [weak self] in
            guard let _ = self else { return }
            if let app = UIApplication.shared.delegate as? AppDelegate,
               let navigationVC = app.window?.rootViewController as? UINavigationController,
               let tabBarController = navigationVC.viewControllers[0] as? UITabBarController {
                tabBarController.selectedIndex = 1
            }
        }
        
        dataSource.challengesHeader = { [weak self] in
            guard let _ = self else { return }
            if let app = UIApplication.shared.delegate as? AppDelegate,
               let navigationVC = app.window?.rootViewController as? UINavigationController,
               let tabBarController = navigationVC.viewControllers[0] as? UITabBarController {
                tabBarController.selectedIndex = 2
            }
        }
        
        dataSource.playVideoHandler = { [weak self] in            
            guard let self = self else { return }
            if self.presenter.selectDay > self.presenter.currentDay {
                if LMConfiguration.shared.getAutomaticallyUpdatePlan() {
                    self.presenter.changeDate()
                    self.presenter.setupVideoURL(day: self.presenter.selectDay, forceWorkout: nil)
                } else if LMConfiguration.shared.getAutomaticallyPlayVideoForAnyDay() {
                    self.presenter.setupVideoURL(forceWorkout: nil)
                } else {
                    self.showUpdatePlanPopUp()
                }
            } else {
                self.presenter.setupVideoURL(day: self.presenter.selectDay, forceWorkout: nil)
            }
        }
        
        dataSource.videoSelect = { [weak self] index in
            guard let self = self else { return }
            self.presenter.workoutSelected = MyPlanEntity.TypeWorkout(rawValue: index)
        }
    }
    
    private func setupCollectionView() {
        registerCells()
        
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.delegate = dataSource
        collectionView.dataSource = dataSource
    }
    
    private func registerCells() {
        collectionView.register(MyPlanTopCollectionViewCell.self)
        collectionView.register(MyPlanHelloCollectionViewCell.self)
        collectionView.register(MyPlanDayCollectionViewCell.self)
        collectionView.register(MyPlanVideoCollectionViewCell.self)
        collectionView.register(MyPlanEquipmentCollectionViewCell.self)
        collectionView.register(BottomButtonCollectionViewCell.self)
        collectionView.register(MyPlanCompletedCollectionViewCell.self)
        collectionView.register(MyPlanCompletedInfoCollectionViewCell.self)
        collectionView.register(MyPlanCompletedDifficultyCollectionViewCell.self)
        collectionView.register(CompletedItemCollectionViewCell.self)
        collectionView.register(FullImageCollectionViewCell.self)
        collectionView.register(MyPlanEmptyTopCollectionViewCell.self)
        collectionView.register(MyPlanAnswerQuestionsCollectionViewCell.self)
        collectionView.register(MyPlanWellDoneCollectionViewCell.self)
        collectionView.register(MyPlanDayNumberCollectionViewCell.self)
    }
    
    private func setupTopView(entity: MyPlanEntity.ViewEntity.TopViewEntity?) {
        
        guard let entity = entity else {
            topViewHeight.constant = 0
            return
        }
        
        topViewHeight.constant = 120
        dateLabel.text = entity.date
        isTodayLabel.isHidden = !entity.isToday
    }
    
    // MARK: - Other logic
    func showWorkoutRatePopUpIfNecessary(workoutPassed: Bool, needShowPopUp: Bool, workoutId: String, day: Int, force: Bool = false, completion: ((MyPlanEntity.RateAction, Bool) -> Void)? ) {
        
        if !force {
            guard needShowPopUp, workoutPassed else {
                completion?(.none, false)
                return
            }
            
            guard presenter.currentPlanType == .myPlan else {
                completion?(.none, false)
                return
            }
            
//            guard dataSource.sections.contains(where: { $0.type == .wellDone }) else {
//                shouldShowRatePopUp = true
//                rateWorkout = (workoutId, day)
//                return
//            }
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.shouldShowRatePopUp = false
            
            let vc = WorkoutRatePopUpViewController.fromStoryboard
            
            vc.confirmRateAction = { [weak self] rate in
                guard let self = self else { return }
                self.presenter.rateWorkout(rate: rate, day: day, workoutId: workoutId, completion: { action, requestSuccessfull in
                    completion?(action, requestSuccessfull)
                    if requestSuccessfull {
                        self.presenter.getData()
                    }
                })
            }
            vc.notNowAction = {
                completion?(.none, false)
            }
            
            self.presentVC(vc, animated: true, presentationStyle: .overFullScreen)
        }
    }
    
    func showChangeDifficultyPopUpIfNecessary(action: MyPlanEntity.RateAction, force: Bool = false) {
        
        var action = action
        action = lastSSEAction ?? action
        
        guard action != .none else {
            presenter.startHideWellDoneTimer()
            return
        }
        
        guard presenter.currentPlanType == .myPlan else {
            presenter.startHideWellDoneTimer()
            return
        }
        
//        if !force {
//            guard dataSource.sections.contains(where: { $0.type == .wellDone }) else {
//                presenter.startHideWellDoneTimer()
//                return
//            }
//        }
        
        if action == .autoDecrease || action == .autoIncrease {
            presenter.changeDifficulty(action: action == .autoIncrease ? .increase : .decrease)
            presenter.startHideWellDoneTimer()
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let infoPopConfigurator = InfoPopUpConfigurator(
                title: "",
                subTitle: action == .increase ? StringValues.ChangeDifficultyPopUp.Description.increase.localized : StringValues.ChangeDifficultyPopUp.Description.decrease.localized,
                rightButtonTitle: StringValues.Base.yes.localized,
                leftButtonTitle: StringValues.Base.no.localized)
            
            let vc = InfoPopUpViewController.fromStoryboard
            vc.configureData = infoPopConfigurator
            
            vc.rightButtonHandler = { [weak self] in
                self?.presenter.changeDifficulty(action: action)
                self?.presenter.startHideWellDoneTimer()
            }
            
            vc.leftButtonHandler = { [weak self] in
                self?.presenter.startHideWellDoneTimer()
            }
            
            self.presentVC(vc, animated: true, presentationStyle: .overFullScreen)
        }
    }
    
    private func showUpdatePlanPopUp(day: Int? = nil, forceWorkout: BaseModels.Response.Workout? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let vc = UpdatePlanPopUpViewController.fromStoryboard
            vc.currentDay = self.presenter.currentDay
            vc.updateAction = { [weak self] dontAskAgain in
                guard let self = self else { return }
                LMConfiguration.shared.saveAutomaticallyUpdatePlan(dontAskAgain)
                if let day = day {
                    self.presenter.selectDay = day
                }
                self.presenter.changeDate()
                self.presenter.setupVideoURL(day: self.presenter.selectDay, forceWorkout: forceWorkout)
            }
            vc.continueAction = { [weak self] dontAskAgain in
                guard let self = self else { return }
                LMConfiguration.shared.saveAutomaticallyPlayVideoForAnyDay(dontAskAgain)
                self.presenter.setupVideoURL(forceWorkout: nil)
            }
            if let presentedVC = self.presentedViewController {
                presentedVC.presentVC(vc, animated: true, presentationStyle: .overFullScreen)
            } else {
                self.presentVC(vc, animated: true, presentationStyle: .overFullScreen)
            }
        }
    }
    
    private func showWatchNotFinisedPopUpIfNecessary(sseStarted: Bool, completion: (() -> Void)? ) {
        
        guard sseStarted else {
            completion?()
            return
        }
        
        let infoPopConfigurator = InfoPopUpConfigurator(
            title: "",
            subTitle: StringValues.DontForgetDisconnectWatchPopUp.description.localized,
            rightButtonTitle: StringValues.Base.finish.localized,
            leftButtonTitle: nil)
        
        let vc = InfoPopUpViewController.fromStoryboard
        vc.configureData = infoPopConfigurator
        
        vc.rightButtonHandler = {
            completion?()
        }
        
        presentVC(vc, animated: true, presentationStyle: .overFullScreen)
    }
    
    // MARK: - @objc
    @objc func tapViewPlan() {
        let vc = ViewPlanViewController.fromStoryboard
        vc.myPlanVC = self
        
        self.presentVC(vc, animated: true, presentationStyle: .popover)
    }
}

extension MyPlanViewController: MyPlanViewControllerProtocol {
    
    func display(topViewEntity: MyPlanEntity.ViewEntity.TopViewEntity?, sections: [MyPlanEntity.ViewEntity.SectionEntity]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.setupTopView(entity: topViewEntity)
            
            self.dataSource.sections = sections
            if sections.contains(where: { $0.type == .wellDone }) {
                self.collectionView.collectionViewLayout.invalidateLayout()
            }
            self.collectionView.collectionViewLayout = self.collectionViewLayout.createScreenLayout(sections: sections)
            
            self.collectionView.reloadData()
            self.collectionView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
            
            if self.shouldShowRatePopUp, let rateWorkout = self.rateWorkout {
                self.showWorkoutRatePopUpIfNecessary(workoutPassed: true, needShowPopUp: true, workoutId: rateWorkout.workoutId, day: rateWorkout.day) { [weak self] action, _ in
                        self?.showChangeDifficultyPopUpIfNecessary(action: action)
                }
            } else {
                self.presenter.startHideWellDoneTimer()
            }
        }
    }
    
    func showVideoPlayer(url: String, currentDay: Int, isCurrentDayOfPlan: Bool, workout: BaseModels.Response.Workout?) {
        DispatchQueue.main.async {
            if let presentedVC = self.presentedViewController {
                presentedVC.dismiss(animated: true) { [weak self] in
                    self?.doShowVideoPlayer(url: url, currentDay: currentDay, isCurrentDayOfPlan: isCurrentDayOfPlan, workout: workout)
                }
            } else {
                self.doShowVideoPlayer(url: url, currentDay: currentDay, isCurrentDayOfPlan: isCurrentDayOfPlan, workout: workout)
            }
        }
    }
    
    func doShowVideoPlayer(url: String, currentDay: Int, isCurrentDayOfPlan: Bool, workout: BaseModels.Response.Workout?) {
        
        sseClient?.stop()
        sseClient = nil
        
        let vc = VideoPlayerViewController.fromStoryboard
        vc.videoStringURL = url
        vc.dayNumber = currentDay
        vc.isCurrentDayOfPlan = isCurrentDayOfPlan
        vc.workout = workout
        vc.closeHandler = { [weak self] sseStarted, workoutPassed, needShowPopUp, sseClient, sseAction in
            
            self?.lastSSEAction = sseAction
                                     
            self?.showWorkoutRatePopUpIfNecessary(workoutPassed: workoutPassed, needShowPopUp: needShowPopUp, workoutId: workout?.id ?? "", day: currentDay, completion: { action, _ in
                self?.showChangeDifficultyPopUpIfNecessary(action: action)
                
                if sseStarted {
                    self?.sseClient = sseClient
                    sseClient.delegate = self
                }
            })
        }
        
        vc.workoutCompletedHandler = { [weak self] completedWorkoutId in
            self?.presenter.wellDoneWorkoutId = completedWorkoutId
        }
        
        if isCurrentDayOfPlan {
            vc.disableSeekBar()
        }
        
        self.presentVC(vc, animated: true, presentationStyle: .fullScreen)
    }
    
    func showHints() {
        let vc = HintsViewController.fromStoryboard
        vc.modalTransitionStyle = .crossDissolve
        
        guard let tabBar = self.tabBarController?.tabBar,
              let view = tabBar.items?[1].value(forKey: "view") as? UIView,
              self.tabBarController?.selectedIndex == 0 else { return }
        let tabBarFrame = tabBar.frame
        let workoutsTabFrame = view.frame
        
        let dayOffCellPoint = collectionView.convert(dayOffCell.frame.origin, to: self.view)
        let videoCellFramePoint = collectionView.convert(self.dataSource.firstVideoCell.frame.origin, to: self.view)
        
        let dataModel = HintsCalculationModel(
            viewPlanFrame: self.bottomView.frame,
            workoutsTabFrame: workoutsTabFrame,
            tabBarFrame: tabBarFrame,
            videoCellFrame: self.dataSource.firstVideoCell.frame,
            dayOffCellWidth: dayOffCellWidth,
            dayOffCellFrame: dayOffCell.frame,
            dayOffCellPoint: dayOffCellPoint,
            videoCellFramePoint: videoCellFramePoint
        )
        
        hintsPresenter = HintsPresenter(
            view: vc,
            calculationModel: dataModel
        )
       
        hintsPresenter?.getNextHint(completion: { [weak self] in
            guard let self = self else { return }
            if self.hintsPresenter?.currentHints?.hasEnabledHint ?? false {
                if self.isActiveView {
                    self.hintsPresenter?.displayHint()
                    self.presentVC(vc, animated: true, presentationStyle: .overCurrentContext)
                }
            } else {
                LMConfiguration.shared.setUserSignedUp(false)
            }
        })
    }
    
    func showError(error: Error) {
        showAlert(with: error, message: nil, title: StringValues.Base.errorAlertTitle)
    }
    
    func setupBlockScreen(flag: Bool) {
        blockScreenViewStart(flag: flag)
    }
    
    func showBottomView(_ show: Bool) {
        DispatchQueue.main.async {
            self.bottomView.isHidden = !show
        }
    }
    
    func tryStartWorkout(_ workout: BaseModels.Response.Workout, day: Int) {
        if day > self.presenter.currentDay {
            if LMConfiguration.shared.getAutomaticallyUpdatePlan() {
                self.presenter.selectDay = day
                self.presenter.changeDate()
                self.presenter.setupVideoURL(day: self.presenter.selectDay, forceWorkout: workout)
            } else if LMConfiguration.shared.getAutomaticallyPlayVideoForAnyDay() {
                self.presenter.setupVideoURL(forceWorkout: workout)
            } else {
                self.showUpdatePlanPopUp(day: day, forceWorkout: workout)
            }
        } else {
            self.presenter.setupVideoURL(day: self.presenter.selectDay, forceWorkout: workout)
        }
    }
}

extension MyPlanViewController: SSEClientDelegate {
    func sseClientClosed(_ client: SSEClient) {}
    
    func sseClient(_ client: SSEClient, didReceiveMessage message: String) {
                
        if self.presentedViewController == nil && !shouldShowRatePopUp { // no another popup is shown
            self.sseClient?.stop()
            self.sseClient = nil
            DispatchQueue.main.async {
                self.showWatchNotFinisedPopUpIfNecessary(sseStarted: true, completion: nil)
            }
        }
    }
}
