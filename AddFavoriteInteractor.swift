import UIKit
import BaseKit

protocol AddFavoriteInteractor: ModularSubModule {
    var delegate: SearchPlacesDelegate? { get set }
    func setupWith(_ viewModel: AddFavoriteModel)
}

class AddFavoriteInteractorModule {
    @NavigationHandler private var navigation
    private let repository: AddFavoriteScreenRepository
    private var viewModel: AddFavoriteModel?
    private var favoritePlace: BDPlace
    weak var delegate: SearchPlacesDelegate?

    init(repository: AddFavoriteScreenRepository,
         favoritePlace: BDPlace) {
        self.repository = repository
        self.favoritePlace = favoritePlace
        setup()
    }

    private func setup() {
        repository.setLocation(favoritePlace.location)
        repository.subscribeForChanges(observer: self) { [weak self] success in
            self?.observationsUpdated(success)
        }
    }

    private func handleError() {
        DispatchQueue.main.async {
            self.navigation.dismiss(animated: false)
            self.navigation.showError(state: .badRequest)
        }
    }

    private func observationsUpdated(_ success: Bool) {
        if success, let observer = repository.observations.first {
            viewModel?.updateWith(favoritePlace: favoritePlace, data: observer)
        } else {
            self.handleError()
        }
    }
}

extension AddFavoriteInteractorModule: ModularLifeCycleSubModule {
    func viewWillAppear() {
        repository.loadDataIfNeeded()
    }

    func viewDidAppear() {
        viewModel?.updateWith(isBackgroundHidden: false, animated: true)
    }

    func viewWillDisappear() {
        viewModel?.updateWith(isBackgroundHidden: true, animated: false)
    }

    func viewDidDisappear() {}
}

extension AddFavoriteInteractorModule: AddFavoriteInteractor {
    func setupWith(_ viewModel: AddFavoriteModel) {
        self.viewModel = viewModel
        self.viewModel?.delegate = delegate
    }
}
