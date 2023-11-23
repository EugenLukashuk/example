import UIKit

class MyPlanBaseCompositionLayout {
    
    enum SectionsOrientationType {
        case horizontal
        case vertical
    }
    
    func getSection(itemSize: NSCollectionLayoutSize,
                    groupSize: NSCollectionLayoutSize,
                    sectionInsets: NSDirectionalEdgeInsets,
                    orientation: SectionsOrientationType) -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        var group: NSCollectionLayoutGroup
        
        var scrollingBehavior: UICollectionLayoutSectionOrthogonalScrollingBehavior = .groupPaging
        
        switch orientation {
        case .horizontal:
            scrollingBehavior = .groupPaging
            group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        case .vertical:
            scrollingBehavior = .none
            group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        }

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = scrollingBehavior
        section.contentInsets = sectionInsets
        
        return section
    }
}
