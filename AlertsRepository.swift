import Foundation
import HTTPClient
import ApiClient

protocol AlertsRepository: BaseRepository {
    var alerts: [Alert] { get }
    func removeData()
}

protocol Alert {
    var id: Int { get }
    var name: String { get }
    var advisoryEnd: Int { get }
    var advisoryStart: Int { get }
    var severity: Int { get }
}

class AppAlertsRepository: AlertsRepository {
    private(set) var loading: Bool = false
    var alerts = [Alert]()
    var locationService: LocationService

    private let endpoint: ApiAlertsEndpoint
    private var observers = [RepositorySmartSubsription]()
    private let queue = DispatchQueue(label: "AppApiAlertsEndpointObserversQueue", attributes: .concurrent)

    init(endpoint: ApiAlertsEndpoint, locationService: LocationService) {
        self.endpoint = endpoint
        self.locationService = locationService
    }

    func reloadData() {
        load()
    }

    func loadDataIfNeeded() {
        load()
    }

    func cancelDataLoading() {
        endpoint.cancelDataLoading()
    }

    func removeData() {
        alerts.removeAll()
    }

    func subscribeForChanges(observer: AnyObject, callback: @escaping RepositoryUpdateCallback) {
        queue.async(flags: .barrier) { [self] in
            observers.append(RepositorySmartSubsription(observer, callback))
        }
    }

    private func load() {
        guard loading == false else { return }

        let isPermissionGranted = locationService.isLocationPermissionGranted()
        let location = isPermissionGranted ? locationService.fullLocation : locationService.location
        guard location.isEmpty == false else { return }

        loading = true
        let parameters = RequestParameters(location: location)
        endpoint.alerts(for: parameters) { [weak self] response in
            self?.loading = false
            switch response {
            case .success(let alerts):
                self?.onUpdated(alerts)
            case .failure(let error):
                self?.handleError(error)
            }
        }
    }

    private func onUpdated(_ alerts: [Api.Alert]) {
        self.alerts = alerts
        notifyResults(success: true)
    }

    private func handleError(_ error: Api.RepositoryError) {
        print(error.debugDescription)
        notifyResults(success: false)
    }

    private func notifyResults(success: Bool) {
        queue.async(flags: .barrier) { [self] in
            observers = observers.filter { $0.observer != nil }
            observers.forEach { $0.callback(success) }
        }
    }
}

private struct RequestParameters: ApiAlertsRequestParameters {
    let location: String
}

extension Api.Alert: Alert {}
