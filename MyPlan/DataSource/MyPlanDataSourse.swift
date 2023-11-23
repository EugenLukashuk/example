import UIKit

protocol MyPlanCellDataProtocol {
    func display(item: MyPlanViewEntityProtocol)
}

class MyPlanCollectionViewDataSource: NSObject, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var sections: [MyPlanEntity.ViewEntity.SectionEntity] = []
    
    var dayAction: ((_ index: Int) -> Void)?
    var answerQuestionsHandler: (() -> Void)?
    var displayHintsHandler: ((UICollectionViewCell, CGFloat) -> Void)?
    var workoutsHeader: (() -> Void)?
    var challengesHeader: (() -> Void)?
    var playVideoHandler: (() -> Void)?
    var videoSelect: ((_ index: Int) -> Void)?
    
    private var frames: [CGRect] = []
    private var firstDayCell: UICollectionViewCell = UICollectionViewCell()
    var firstVideoCell: UICollectionViewCell = UICollectionViewCell()
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = sections[indexPath.section]
        let rowItem = section.items[indexPath.row]
        var cell: UICollectionViewCell & MyPlanCellDataProtocol
        
        switch section.type {
        case .hello:
            let helloCell = collectionView.dequeue(MyPlanHelloCollectionViewCell.self, indexPath)
            helloCell.workoutsHeader = workoutsHeader
            cell = helloCell
        case .dayWeek:
            let dayCell = collectionView.dequeue(MyPlanDayCollectionViewCell.self, indexPath)
            dayCell.action = { [weak self] day in
                guard let self = self else { return }
                self.dayAction?(day)
            }
            
            cell = dayCell
        case .video:
            let videoCell = collectionView.dequeue(MyPlanVideoCollectionViewCell.self, indexPath)
            videoCell.actionHandler = { [weak self] videoURL in
                guard let self = self else { return }
                self.playVideoHandler?()
            }
            cell = videoCell
        case .bottomButton:
            let buttonCell = collectionView.dequeue(BottomButtonCollectionViewCell.self, indexPath)
            buttonCell.action = self.playVideoHandler
            cell = buttonCell
        case .completed:
            let completedCell = collectionView.dequeue(MyPlanCompletedCollectionViewCell.self, indexPath)
            
            completedCell.action = { [weak self] in
                guard let self = self else { return }
                self.dayAction?(indexPath.row)
            }
            
            cell = completedCell
        case .info:
            cell = collectionView.dequeue(MyPlanCompletedInfoCollectionViewCell.self, indexPath)
        case .difficulty:
            cell = collectionView.dequeue(MyPlanCompletedDifficultyCollectionViewCell.self, indexPath)
        case .item:
            cell = collectionView.dequeue(CompletedItemCollectionViewCell.self, indexPath)
        case .image:
            cell = collectionView.dequeue(FullImageCollectionViewCell.self, indexPath)
        case .emptyTop:
            let emptyTopCell = collectionView.dequeue(MyPlanEmptyTopCollectionViewCell.self, indexPath)
            emptyTopCell.action = challengesHeader
            cell = emptyTopCell
        case .answerQuestions:
            let emptyBottomButtonCell = collectionView.dequeue(MyPlanAnswerQuestionsCollectionViewCell.self, indexPath)
            emptyBottomButtonCell.action = answerQuestionsHandler
            emptyBottomButtonCell.challengesHeader = challengesHeader
            cell = emptyBottomButtonCell
        case .wellDone:
            let wellDoneCell = collectionView.dequeue(MyPlanWellDoneCollectionViewCell.self, indexPath)
            wellDoneCell.workoutsHeader = workoutsHeader
            cell = wellDoneCell
        case .dayNumber:
            cell = collectionView.dequeue(MyPlanDayNumberCollectionViewCell.self, indexPath)
        }
        
        cell.display(item: rowItem)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        
        if section.type == .video {
            videoSelect?(indexPath.row)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if cell is MyPlanDayCollectionViewCell {
            frames.append(cell.frame)
            
            if indexPath.item == 0 {
                firstDayCell = cell
            }
            
            if let frame = frames.first {
                let width = frame.width * CGFloat(collectionView.numberOfItems(inSection: indexPath.section))
                displayHintsHandler?(firstDayCell, width)
            }
            
//            if collectionView.numberOfItems(inSection: indexPath.section) == frames.count {
//                let width = frames.reduce(0, {$0 + $1.width})
//                displayHintsHandler?(firstDayCell, width)
//            }
        } else if cell is MyPlanVideoCollectionViewCell {
            if indexPath.item == 0 {
                firstVideoCell = cell
            }
        }
    }
}
