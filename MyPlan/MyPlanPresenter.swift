import Foundation

protocol MyPlanPresenterProtocol {
    var selectDay: Int { get set }
    var currentDay: Int { get set }
    var type: MyPlanEntity.DayProgressStatus { get set }
    var workoutSelected: MyPlanEntity.TypeWorkout? { get set }
    func getData()
    func updateDayData(selectDay: Int)
    func setupVideoURL(day: Int?, forceWorkout: BaseModels.Response.Workout?)
    func setupVideoURL(forceWorkout: BaseModels.Response.Workout?)
    func saveProgress()
    func changeDate()
    func rateWorkout(rate: Int, day: Int, workoutId: String, completion: @escaping (MyPlanEntity.RateAction, Bool) -> Void )
    func changeDifficulty(action: MyPlanEntity.RateAction)
    func showHints()
    func startHideWellDoneTimer()
    var currentPlanType: PlanType? { get }
    var wellDoneWorkoutId: String? { get set }
}

class MyPlanPresenter: MyPlanPresenterProtocol {
    
    private unowned let view: MyPlanViewControllerProtocol
    private let reachability = Reachability.shared
    private let myPlanAPI: MyPlanRequests
    
    var selectDay: Int = 0
    var currentDay: Int = 0
    var type: MyPlanEntity.DayProgressStatus = .notPassed
    var workoutSelected: MyPlanEntity.TypeWorkout?
    
    var week: [MyPlanEntity.Response.Day]?
    var workout: BaseModels.Response.Workout?
    var altWorkout: BaseModels.Response.Workout?
    var days = MyPlanEntity.ViewEntity.SectionEntity(items: [MyPlanEntity.ViewEntity.Day](), type: .dayWeek)
    var wellDoneWorkoutId: String?
    
    private var progress: MyPlanEntity.Response.ProgressArray?
    private var ratePopupForSelectedDayShown = true
    private var dataSynchronization = false
    private var shouldShowHintsOnInternetConnected = false
    
    private var currentPlanId: String? {
        didSet {
            if oldValue != currentPlanId {
                checkCurrentPlanType()
            }
        }
    }
    var currentPlanType: PlanType?

    required init(view: MyPlanViewControllerProtocol, myPlanAPI: MyPlanRequests = MyPlanRequests()) {
        self.view = view
        self.myPlanAPI = myPlanAPI
        
        NotificationCenter.default.addObserver(self, selector: #selector(onInternetReachabilityChanged), name: .internetReachabilityChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onIdleStateExit), name: .exitIdleState, object: nil)
    }
    
    func getData() {
        SubscriptionManager.shared.checkSubscription { [weak self] hasSubscription in
            guard let self = self else { return }
            
            if hasSubscription {
                self.getProgress { [weak self] in
                    self?.getMyPlan()
                }
//                self.setupEmptyViewEntity()
            } else {                
            }
        }
    }
    
    func updateDayData(selectDay: Int) {
        self.selectDay = selectDay
        self.ratePopupForSelectedDayShown = false
        self.wellDoneWorkoutId = nil
        getWorkouts()
    }
    
    func setupVideoURL(forceWorkout: BaseModels.Response.Workout? = nil) {
        setupVideoURL(day: nil, forceWorkout: forceWorkout)
    }
    
    func setupVideoURL(day: Int? = nil, forceWorkout: BaseModels.Response.Workout? = nil) {
        let selectedWorkout = forceWorkout ?? (workoutSelected == .workout ? workout : altWorkout)
        let url = selectedWorkout?.video?.link ?? ""
        var isCurrentDayOfPlan = false
        if let day = day, day <= currentDay {
            isCurrentDayOfPlan = true
        }
        
        view.showVideoPlayer(url: url, currentDay: day ?? currentDay, isCurrentDayOfPlan: isCurrentDayOfPlan, workout: selectedWorkout)
    }
    
    @objc private func onInternetReachabilityChanged() {
        if reachability.isConnected {
            if week == nil {
                getData()
            }
            if shouldShowHintsOnInternetConnected {
                view.showHints()
                shouldShowHintsOnInternetConnected = false
            }
        }
    }
    
    @objc private func onIdleStateExit() {
        if view.isVisible {
            dataSynchronization = true
            getData()
        }
    }
    
    // MARK: - Requests
    private func getMyPlan() {
        guard reachability.isConnected else { return }
        
        guard let id = LMConfiguration.shared.getUserID() else { return }
        
        myPlanAPI.getMyPlan(id: id) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                self.week = data.weekPlan
                
                self.currentDay = data.currentDay ?? 0
                if self.selectDay == 0 || data.planId != self.currentPlanId || !(self.week?.contains(where: { $0.day == self.selectDay }) ?? false) {
                    self.selectDay = self.currentDay
                }
                self.currentPlanId = data.planId

                self.getWorkouts()
                
                self.view.showBottomView(true)
            
            case .failure(let error):
                if LMConfiguration.shared.getQuizStatus() {
                    self.view.showError(error: error)
                } else {
                    self.setupEmptyViewEntity()
                }
            }
        }
    }
    
    private func getProgress(_ completion: (() -> Void)? ) {
        myPlanAPI.getMyProgress { [weak self] result in
            guard let self = self else { return }
            if case let .success(progress) = result {
                self.progress = progress
            }
            completion?()
        }
    }
    
    private func getWorkouts() {
        let workoutId = week?.first(where: {$0.day == selectDay})?.workout?.id ?? ""
        let altWorkoutId = week?.first(where: {$0.day == selectDay})?.altWorkout?.id ?? ""
        
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        self.getWorkout(id: workoutId) { [weak self] workout in
            guard let self = self else { return }
            
            dispatchGroup.leave()
            self.workout = workout
        }
        
        dispatchGroup.enter()
        self.getWorkout(id: altWorkoutId) { [weak self] workout in
            guard let self = self else { return }
            
            dispatchGroup.leave()
            self.altWorkout = workout
        }
        
        dispatchGroup.notify(queue: .global(), execute: { [weak self] in
            guard let self = self else { return }
            self.setupViewEntity()
        })
    }
    
    private func getWorkout(id: String, completion: ((_ workout: BaseModels.Response.Workout?) -> Void)?) {
        guard reachability.isConnected else { return }
        
        myPlanAPI.getWorkout(id: id) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                completion?(data)
            case .failure(let error):
                completion?(nil)
                self.view.showError(error: error)
            }
        }
    }
    
    func saveProgress() {
        let workoutId = workoutSelected == .workout ? workout?.id : altWorkout?.id
        let params = MyPlanEntity.Request.SaveProgress(day: selectDay, time: 1, workoutId: workoutId)
        
        myPlanAPI.saveProgress(params: params) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.getData()
            case .failure(let error):
                self.view.showError(error: error)
            }
        }
    }
    
    func changeDate() {
//        let params = MyPlanEntity.Request.ChangeDate(day: week?.first(where: {$0.day == selectDay})?.day) ???
        let params = MyPlanEntity.Request.ChangeDate(day: selectDay)
        
        currentDay = selectDay
        myPlanAPI.changeDate(params: params) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.getData()
            case .failure(let error):
                self.view.showError(error: error)
            }
        }
    }
    
    func rateWorkout(rate: Int, day: Int, workoutId: String, completion: @escaping (MyPlanEntity.RateAction, Bool) -> Void ) {
        myPlanAPI.rateWorkout(params: .init(userRate: rate, workoutId: workoutId, day: day)) { [weak self] result in
            if case let .success(data) = result {
                completion(data.action ?? .none, true)
            } else {
                completion(.none, false)
            }
        }
    }
    
    func changeDifficulty(action: MyPlanEntity.RateAction) {
        myPlanAPI.changeDifficulty(params: .init(action: action)) { result in
            if case .success(_) = result {
                self.getData()
            }
        }
    }
    
    private func checkCurrentPlanType() {
        guard let currentPlanId = currentPlanId else { return }
        
        myPlanAPI.getFullPlan(id: currentPlanId) { [weak self] result in
            if case let .success(plan) = result {
                self?.currentPlanType = plan.type
            } else {
                self?.currentPlanType = nil
            }
        }
    }
    
    func showHints() {
        if currentPlanType != nil {
            if reachability.isConnected {
                view.showHints()
            } else {
                shouldShowHintsOnInternetConnected = true
            }
        }
    }
    
    func startHideWellDoneTimer() {
        guard wellDoneWorkoutId != nil else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            if self?.wellDoneWorkoutId != nil {
                self?.wellDoneWorkoutId = nil
                self?.ratePopupForSelectedDayShown = true
                self?.setupViewEntity()
            }
        }
    }
    
    // MARK: - View
    
    private func setupEmptyViewEntity() {
        var items: [MyPlanEntity.ViewEntity.SectionEntity] = []
        
        let emptyTopEntity = getConfiguredEmptyTopData(title: StringValues.MyPlan.emptyTitle.localized)
        let answerQuestionsEntity = getConfiguredAnswerQuestionsData(title: "Hello, \(LMConfiguration.shared.getUserName() ?? "User")!")
        
        items.append(emptyTopEntity)
        items.append(answerQuestionsEntity)
        
        view.display(topViewEntity: nil, sections: items)
    }
    
    private func setupViewEntity() {
        var items: [MyPlanEntity.ViewEntity.SectionEntity] = []
        
        let daysEntity = getConfiguredDaysData()
       // let days = daysEntity.items as? [MyPlanEntity.ViewEntity.Day]
  
        guard let day = week?.first(where: {$0.day == selectDay}), let status = MyPlanEntity.DayProgressStatus(rawValue: day.status ?? "") else { return }
        
        switch status {
        case .notPassed, .skipped:
            let helloEntity = getConfiguredHelloEntity(title: "Hello, \(LMConfiguration.shared.getUserName() ?? "User")!", text1: "Here is your workout for today.", text2: "Find your best results with balanced workouts designed to motivate and help you achieve your goals.")
            
            let videoEntity = getConfiguredVideoData()
            let startEntity = getConfiguredButtonData(title: StringValues.MyPlan.startDay.localized + " \(selectDay)")
            
            items.append(helloEntity)
            items.append(daysEntity)
            items.append(videoEntity)
            items.append(startEntity)
        case .passed:
            if let wellDoneWorkoutId = wellDoneWorkoutId, workout?.id == wellDoneWorkoutId || altWorkout?.id == wellDoneWorkoutId {
                let dayNumberEntity = getConfiguredDayNumberData(title: StringValues.Base.day.localized + " \(selectDay)")
                let wellDoneEntity = getConfiguredWellDoneData()
                items.append(dayNumberEntity)
                items.append(daysEntity)
                items.append(wellDoneEntity)
            } else {
                let completedEntity = getConfiguredCompleteData()
                let infoEntity = getConfiguredInfoData()
                let difficultyEntity = getConfiguredDifficultyData()
                let itemEntity = getConfiguredItemData()
                
                items.append(completedEntity)
                items.append(daysEntity)
                items.append(infoEntity)
                items.append(difficultyEntity)
                items.append(itemEntity)
                
                // Not needed to show popup for now: https://lampalampateam.atlassian.net/browse/LEVL-1344
//                if let progressWorkout = progress?.completedWorkout(for: selectDay),
//                   let workoutId = progressWorkout.id,
//                   !ratePopupForSelectedDayShown,
//                   !dataSynchronization,
//                   progressWorkout.rate ?? 0 == 0 {
//                    ratePopupForSelectedDayShown = true
//                    view.showWorkoutRatePopUpIfNecessary(workoutPassed: true, needShowPopUp: true, workoutId: workoutId, day: selectDay, force: true) { [weak self] action, _ in
//                        self?.view.showChangeDifficultyPopUpIfNecessary(action: action, force: true)
//                        self?.getData()
//                    }
//                }
            }
        case .dayOff:
            let helloEntity = getConfiguredHelloEntity(title: "Hello, \(LMConfiguration.shared.getUserName() ?? "User")!", text1: StringValues.MyPlan.dayOffSubTitle.localized, text2: StringValues.MyPlan.dayOffDescription.localized)
            let imageEntity = getConfiguredImageData()
            
            items.append(helloEntity)
            items.append(daysEntity)
            items.append(imageEntity)
        }
        
        let date = day.completedDate?.dateString(format: .fullMonthFormat) ?? Date().dateString(format: .fullMonthFormat)
        let topViewEntity = MyPlanEntity.ViewEntity.TopViewEntity(date: date, isToday: status != .passed)
        
        dataSynchronization = false
        
        view.display(topViewEntity: topViewEntity, sections: items)
    }
    
    private func getConfiguredHelloEntity(title: String, text1: String, text2: String) -> MyPlanEntity.ViewEntity.SectionEntity {
        let row: MyPlanViewEntityProtocol = MyPlanEntity.ViewEntity.HelloEntity(title: title, text1: text1, text2: text2)
        let section: MyPlanEntity.ViewEntity.SectionEntity = MyPlanEntity.ViewEntity.SectionEntity(items: [row], type: .hello)
        return section
    }
    
    private func getConfiguredDaysData() -> MyPlanEntity.ViewEntity.SectionEntity {
        var section: MyPlanEntity.ViewEntity.SectionEntity = MyPlanEntity.ViewEntity.SectionEntity(type: .dayWeek)
        
        guard let week = week else { return section}
        
        for (index, day) in week.enumerated() {
            let isSelect = selectDay == day.day
            let isToday = day.currentDay ?? false
            let status = MyPlanEntity.DayProgressStatus(rawValue: day.status ?? "") ?? .notPassed
            let day = MyPlanEntity.ViewEntity.Day(number: day.day ?? index + 1, isSelect: isSelect, isToday: isToday, date: "", status: status)
            section.items.append(day)
        }
        
        return section
    }
    
    private func getConfiguredVideoData() -> MyPlanEntity.ViewEntity.SectionEntity {
        
        var equipmentString = ""
        for item in workout?.equipments ?? [] {
            equipmentString += equipmentString == "" ? item : ", \(item)"
        }
        
        var altEquipmentString = ""
        for item in altWorkout?.equipments ?? [] {
            altEquipmentString += altEquipmentString == "" ? item : ", \(item)"
        }
        
        let workoutRow: MyPlanViewEntityProtocol = MyPlanEntity.ViewEntity.VideoEntity(name: workout?.title ?? "", duration: workout?.video?.duration?.secondsToHoursMinutesSeconds() ?? "", previewImageURL: workout?.video?.thumbnail ?? "", videoURL: workout?.video?.link ?? "", equipment: equipmentString)
        let altWorkoutRow: MyPlanViewEntityProtocol = MyPlanEntity.ViewEntity.VideoEntity(name: altWorkout?.title ?? "", duration: altWorkout?.video?.duration?.secondsToHoursMinutesSeconds() ?? "", previewImageURL: altWorkout?.video?.thumbnail ?? "", videoURL: altWorkout?.video?.link ?? "", equipment: altEquipmentString)
        
        let section: MyPlanEntity.ViewEntity.SectionEntity = MyPlanEntity.ViewEntity.SectionEntity(items: [workoutRow, altWorkoutRow], type: .video)
        return section
    }
    
    private func getConfiguredButtonData(title: String) -> MyPlanEntity.ViewEntity.SectionEntity {
        let row: MyPlanViewEntityProtocol = MyPlanEntity.ViewEntity.ButtonEntity(title: title)
        let section: MyPlanEntity.ViewEntity.SectionEntity = MyPlanEntity.ViewEntity.SectionEntity(items: [row], type: .bottomButton)
        return section
    }
    
    private func getConfiguredInfoData() -> MyPlanEntity.ViewEntity.SectionEntity {
        var durationString = ""
        let selectDayIndex = selectDay > 0 ? selectDay - 1 : 0
        if let completedDay = week?.first(where: { $0.day == selectDay }) {
            let progressWorkout = progress?.completedWorkout(for: selectDay)
            if let duration = progressWorkout?.viewedTime {
                durationString = duration.secondsToHoursMinutesSeconds()
            }
        }
        let row: MyPlanViewEntityProtocol = MyPlanEntity.ViewEntity.InfoEntity(duration: durationString, countWorkouts: "\(1)", calories: "\(workout?.calories ?? 0)")
        let section: MyPlanEntity.ViewEntity.SectionEntity = MyPlanEntity.ViewEntity.SectionEntity(items: [row], type: .info)
        return section
    }
    
    private func getConfiguredItemData() -> MyPlanEntity.ViewEntity.SectionEntity {
        let progressCompletedWorkout = progress?.completedWorkout(for: selectDay)
        let workout = self.altWorkout?.id == progressCompletedWorkout?.id ? self.altWorkout : self.workout
        
        let row: MyPlanViewEntityProtocol = MyPlanEntity.ViewEntity.ItemEntity(title: workout?.title ?? "", progress: progressCompletedWorkout?.percent ?? 0, image: workout?.video?.thumbnail ?? "")
        let section: MyPlanEntity.ViewEntity.SectionEntity = MyPlanEntity.ViewEntity.SectionEntity(items: [row], type: .item)
        return section
    }
    
    private func getConfiguredCompleteData() -> MyPlanEntity.ViewEntity.SectionEntity {
        let row: MyPlanViewEntityProtocol = MyPlanEntity.ViewEntity.CompletedEntity()
        let section: MyPlanEntity.ViewEntity.SectionEntity = MyPlanEntity.ViewEntity.SectionEntity(items: [row], type: .completed)
        return section
    }
    
    private func getConfiguredDifficultyData() -> MyPlanEntity.ViewEntity.SectionEntity {
        let progressWorkout = progress?.completedWorkout(for: selectDay)

        let row: MyPlanViewEntityProtocol = MyPlanEntity.ViewEntity.DifficultyEntity(difficulty: progressWorkout?.rate)
        let section: MyPlanEntity.ViewEntity.SectionEntity = MyPlanEntity.ViewEntity.SectionEntity(items: [row], type: .difficulty)
        return section
    }
    
    private func getConfiguredImageData() -> MyPlanEntity.ViewEntity.SectionEntity {
        let row: MyPlanViewEntityProtocol = MyPlanEntity.ViewEntity.ImageEntity()
        let section: MyPlanEntity.ViewEntity.SectionEntity = MyPlanEntity.ViewEntity.SectionEntity(items: [row], type: .image)
        return section
    }
    
    private func getConfiguredEmptyTopData(title: String) -> MyPlanEntity.ViewEntity.SectionEntity {
        let row: MyPlanViewEntityProtocol = MyPlanEntity.ViewEntity.EmptyTopEntity(title: title, image: "")
        let section: MyPlanEntity.ViewEntity.SectionEntity = MyPlanEntity.ViewEntity.SectionEntity(items: [row], type: .emptyTop)
        return section
    }
    
    private func getConfiguredAnswerQuestionsData(title: String) -> MyPlanEntity.ViewEntity.SectionEntity {
        let row: MyPlanViewEntityProtocol = MyPlanEntity.ViewEntity.ButtonEntity(title: title)
        let section: MyPlanEntity.ViewEntity.SectionEntity = MyPlanEntity.ViewEntity.SectionEntity(items: [row], type: .answerQuestions)
        return section
    }
    
    private func getConfiguredWellDoneData() -> MyPlanEntity.ViewEntity.SectionEntity {
        let row: MyPlanViewEntityProtocol = MyPlanEntity.ViewEntity.WellDoneEntity()
        let section: MyPlanEntity.ViewEntity.SectionEntity = MyPlanEntity.ViewEntity.SectionEntity(items: [row], type: .wellDone)
        return section
    }
    
    private func getConfiguredDayNumberData(title: String) -> MyPlanEntity.ViewEntity.SectionEntity {
        let row: MyPlanViewEntityProtocol = MyPlanEntity.ViewEntity.DayNumberEntity(title: title)
        let section: MyPlanEntity.ViewEntity.SectionEntity = MyPlanEntity.ViewEntity.SectionEntity(items: [row], type: .dayNumber)
        return section
    }
}
