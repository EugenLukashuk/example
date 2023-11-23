import UIKit

class MyPlanDayCompositionLayout: MyPlanBaseCompositionLayout {
    
    func createScreenLayout(sections: [MyPlanEntity.ViewEntity.SectionEntity]) -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionNumber, _) -> NSCollectionLayoutSection? in
            let type = sections[sectionNumber].type

            switch type {
            case .hello: do {
                let preferredHeight: CGFloat
                if let item = sections[sectionNumber].items.first {
                    preferredHeight = MyPlanHelloCollectionViewCell.preferredHeightFor(item: item)
                } else {
                    preferredHeight = 152
                }
                return self.getSection(itemSize: .init(widthDimension: .fractionalWidth(1),
                                                       heightDimension: .estimated(preferredHeight)),
                                       groupSize: .init(widthDimension: .fractionalWidth(1),
                                                        heightDimension: .estimated(preferredHeight)),
                                       sectionInsets: NSDirectionalEdgeInsets(top: 24, leading: 0, bottom: 18, trailing: 0),
                                       orientation: .vertical)
            }
            case .dayNumber:
                return self.getSection(itemSize: .init(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .fractionalHeight(1)),
                                  groupSize: .init(widthDimension: .fractionalWidth(1),
                                                   heightDimension: .absolute(127)),
                                  sectionInsets: NSDirectionalEdgeInsets(top: 24, leading: 0, bottom: 18, trailing: 0),
                                  orientation: .vertical)
            case .dayWeek:
                return self.getSection(itemSize: .init(widthDimension: .estimated(50),
                                                  heightDimension: .estimated(70)),
                                  groupSize: .init(widthDimension: .fractionalWidth(1),
                                                   heightDimension: .estimated(70)),
                                  sectionInsets: NSDirectionalEdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30),
                                  orientation: .horizontal)
            case .video:
                return self.getSection(itemSize: .init(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .estimated(200)),
                                  groupSize: .init(widthDimension: .fractionalWidth(1),
                                                   heightDimension: .estimated(200)),
                                  sectionInsets: NSDirectionalEdgeInsets(top: 18, leading: 0, bottom: 0, trailing: 0),
                                  orientation: .horizontal)
            case .bottomButton:
                return self.getSection(itemSize: .init(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .estimated(100)),
                                  groupSize: .init(widthDimension: .fractionalWidth(1),
                                                   heightDimension: .estimated(100)),
                                  sectionInsets: NSDirectionalEdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0),
                                  orientation: .vertical)
            case .completed:
                return self.getSection(itemSize: .init(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .fractionalHeight(1)),
                                  groupSize: .init(widthDimension: .fractionalWidth(1),
                                                   heightDimension: .absolute(127)),
                                  sectionInsets: NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 42, trailing: 0),
                                  orientation: .vertical)
            case .info:
                return self.getSection(itemSize: .init(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .fractionalHeight(1)),
                                  groupSize: .init(widthDimension: .fractionalWidth(1),
                                                   heightDimension: .absolute(92)),
                                  sectionInsets: NSDirectionalEdgeInsets(top: 30, leading: 0, bottom: 26, trailing: 0),
                                  orientation: .vertical)
            case .difficulty:
                return self.getSection(itemSize: .init(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .fractionalHeight(1)),
                                  groupSize: .init(widthDimension: .fractionalWidth(1),
                                                    heightDimension: .estimated(68)),
                                  sectionInsets: .zero,
                                  orientation: .vertical)
            case .item:
                return self.getSection(itemSize: .init(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .fractionalHeight(1)),
                                  groupSize: .init(widthDimension: .fractionalWidth(1),
                                                   heightDimension: .absolute(87)),
                                  sectionInsets: NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 0),
                                  orientation: .vertical)
            case .image:
                return self.getSection(itemSize: .init(widthDimension: .absolute(Screen.width - 60),
                                                  heightDimension: .fractionalHeight(1)),
                                       groupSize: .init(widthDimension: .absolute(Screen.width - 60),
                                                   heightDimension: .absolute(188)),
                                  sectionInsets: NSDirectionalEdgeInsets(top: 18, leading: 30, bottom: 20, trailing: 30),
                                  orientation: .vertical)
            case .emptyTop:
                return self.getSection(itemSize: .init(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .fractionalHeight(1)),
                                  groupSize: .init(widthDimension: .fractionalWidth(1),
                                                   heightDimension: .absolute(Screen.width)),
                                  sectionInsets: .zero,
                                  orientation: .vertical)
            case .answerQuestions:
                return self.getSection(itemSize: .init(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .estimated(127)),
                                  groupSize: .init(widthDimension: .fractionalWidth(1),
                                                   heightDimension: .fractionalWidth(1)),
                                  sectionInsets: NSDirectionalEdgeInsets(top: 24, leading: 0, bottom: 18, trailing: 0),
                                  orientation: .vertical)
            case .wellDone:
                return self.getSection(itemSize: .init(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .estimated(200)),
                                  groupSize: .init(widthDimension: .fractionalWidth(1),
                                                    heightDimension: .estimated(200)),
                                  sectionInsets: .zero,
                                  orientation: .vertical)
            }
        }
        
        return layout
    }
}
