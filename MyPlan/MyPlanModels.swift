import Foundation

protocol MyPlanViewEntityProtocol {
    var title: String { get }
}

extension MyPlanViewEntityProtocol {
    var title: String {
        return ""
    }
}

enum MyPlanEntity {
    
    struct Request {
        struct SaveProgress: Codable {
            var day: Int?
            var time: Int?
            var workoutId: String?
        }
        
        struct SaveProgressV2: Codable {
            var day: Int?
            var partIndex: Int?
            var workoutId: String?
            var completeDifficult: String
            var nextDifficult: String
        }
        
        struct DeletePart: Codable {
            var day: Int
            var partIndex: Int
            var workoutId: String
        }
        
        struct ChangeDate: Codable {
            var day: Int?
        }
        
        struct RateWorkout: Codable {
            var userRate: Int
            var workoutId: String
            var day: Int
        }
        
        struct ChangeDifficulty: Codable {
            let action: RateAction
        }
    }
    
    struct Response {

        struct MyPlanResponse: BaseModelProtocol {
            var currentDay: Int?
            var currentWeek: Int?
            var weekPlan: [Day]?
            var planId: String?
            var message: String?
            var error: String?
        }
        
        struct FullPlanResponse: BaseModelProtocol {
            var message: String?
            var error: String?
            var type: PlanType?
        }
        
        struct Day: Codable {
            var day: Int?
            var status: String?
            var currentDay: Bool?
            var workout: DayWorkout?
            var altWorkout: DayWorkout?
            var completedDate: String?
        }
        
        struct DayWorkout: Codable {
            var id: String?
            var status: String?
            var percent: Int?
            var rate: Int?
            var viewedTime: Int?
            
            var progressStatus: DayProgressStatus? {
                DayProgressStatus(rawValue: status ?? "")
            }
        }
        
        struct SaveProgress: BaseModelProtocol {
            var message: String?
            var error: String?
            var status: String?
            var passedWorkout: Int?
            var nextPart: NextPart
            var isPopupShow: Bool
            
            var passed: Bool {
                return status?.lowercased() == "passed"
            }
        }
        
        struct DeletePart: BaseModelProtocol {
            var message: String?
            var error: String?
            var isPopupShow: Bool
        }
        
        struct NextPart: Codable {
            var available: Bool
            var index: Int?
            var node: BaseModels.Response.VideoNodeDifficulty?
        }
        
        struct ChangeDate: BaseModelProtocol {
            var message: String?
            var error: String?
        }
        
        struct ChangeDifficulty: BaseModelProtocol {
            var message: String?
            var error: String?
        }
        
        struct RateWorkout: BaseModelProtocol {
            var message: String?
            var error: String?
            
            var action: RateAction?
        }
        
        struct Progress: Codable {
            let id: String
            var days: [Day]?

            enum CodingKeys: String, CodingKey {
                case id = "_id"
                case days
            }
        }
        
        typealias ProgressArray = [Progress]
        
    }
    
    struct ViewEntity {
        
        struct TopViewEntity {
            var date: String
            var isToday: Bool
        }
        
        struct SectionEntity {
            var items: [MyPlanViewEntityProtocol] = []
            var type: SectionsType
        }
        
        struct TopEntity: MyPlanViewEntityProtocol {
            var title: String
            var subTitle: String
        }
        
        struct Day: MyPlanViewEntityProtocol {
            var number: Int
            var isSelect: Bool
            var isToday: Bool
            var date: String
            var status: DayProgressStatus
        }
        
        struct HelloEntity: MyPlanViewEntityProtocol {
            var title: String
            var text1: String
            var text2: String
        }
        
        struct VideoEntity: MyPlanViewEntityProtocol {
            var name: String
            var duration: String
            var previewImageURL: String
            var videoURL: String
            var equipment: String
        }
        
        struct EquipmentEntity: MyPlanViewEntityProtocol {
            var title: String
        }
        
        struct ButtonEntity: MyPlanViewEntityProtocol {
            var title: String
        }
        
        struct CompletedEntity: MyPlanViewEntityProtocol {

        }
        
        struct InfoEntity: MyPlanViewEntityProtocol {
            var duration: String
            var countWorkouts: String
            var calories: String
        }
        
        struct DifficultyEntity: MyPlanViewEntityProtocol {
            var difficulty: Int?
        }
        
        struct ItemEntity: MyPlanViewEntityProtocol {
            var title: String
            var progress: Int
            var image: String
        }
        
        struct ImageEntity: MyPlanViewEntityProtocol {

        }
        
        struct EmptyTopEntity: MyPlanViewEntityProtocol {
            var title: String
            var image: String
        }
        
        struct AnswerQuestionsEntity: MyPlanViewEntityProtocol {
            var title: String
        }
        
        struct WellDoneEntity: MyPlanViewEntityProtocol {}
        
        struct DayNumberEntity: MyPlanViewEntityProtocol {
            var title: String
        }
        
        enum SectionsType {
            case hello
            case dayWeek
            case video
            case bottomButton
            case image
            case difficulty
            case item
            case completed
            case info
            case emptyTop
            case answerQuestions
            case wellDone
            case dayNumber
        }
    }
    
    // MARK: - enums
    enum TypeCollection: Int {
        case day
        case completed
        case dayOff
    }
    
    enum TypeWorkout: Int {
        case workout
        case alternative
    }
    
    enum DayProgressStatus: String, Codable {
        case passed = "PASSED"
        case notPassed = "NO_PASSED"
        case skipped = "SKIPPED"
        case dayOff = "DAY_OF"
    }
    
    enum RateAction: String, Codable {
        case none = "NONE"
        case increase = "SHOW_INCREASE"
        case decrease = "SHOW_DECREASE"
        case autoIncrease = "INCREASE"
        case autoDecrease = "DECREASE"
    }
}


extension MyPlanEntity.Response.ProgressArray: BaseModelProtocol {
    var message: String? {
        get { return nil }
        set { }
    }
    
    var error: String? {
        get { return nil }
        set { }
    }
}

enum PlanType: String, Codable {
    case challenge = "CHALLENGE"
    case myPlan = "MY_PLAN"
    case quiz
}

extension MyPlanEntity.Response.ProgressArray {
    func workout(with id: String?) -> MyPlanEntity.Response.DayWorkout? {
        guard id != nil else { return nil }
        for progress in self {
            for day in progress.days ?? [] {
                if day.workout?.id == id {
                    return day.workout
                }
                if day.altWorkout?.id == id {
                    return day.altWorkout
                }
            }
        }
        return nil
    }
    
    func completedWorkout(for day: Int) -> MyPlanEntity.Response.DayWorkout? {
        for progress in self {
            if let day = progress.days?.first(where: { $0.day == day }) {
                if day.workout?.progressStatus == .passed {
                    return day.workout
                }
                if day.altWorkout?.progressStatus == .passed {
                    return day.altWorkout
                }
            }
        }
        return nil
    }
}
