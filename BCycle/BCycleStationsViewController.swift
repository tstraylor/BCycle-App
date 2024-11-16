//
//  BCycleStationsViewController.swift
//  BCycle
//
//  Created by Thomas Traylor on 1/1/24.
//

import UIKit
import MapKit
import CoreLocation

@MainActor
class BCycleStationsViewController: UIViewController {
    
    private let MetersPerMile: Double = 1609.344
    private var currentPlacemark: CLPlacemark?
    private var currentLocation: CLLocation?
    private var locationManager: CLLocationManager = CLLocationManager()
    private var userInteractionCausedRegionChange: Bool = false
    
    private var mapView: MKMapView = {
        return MKMapView(frame: .zero)
    }()
    
    override func loadView() {
        view = UIView(frame: .zero)
        view.backgroundColor = .systemBackground
        
        view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            view.bottomAnchor.constraint(equalTo: mapView.bottomAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: mapView.trailingAnchor)
        ])
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.systemRed]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.systemRed]
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.compactAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        navigationController?.navigationBar.compactScrollEdgeAppearance = navBarAppearance
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.tintColor = .white
        
        setNeedsStatusBarAppearanceUpdate()
        title = "BCycle"
        
        let addButton = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(addStation(_:)))
        addButton.tintColor = .systemRed
        navigationItem.setRightBarButton(addButton, animated: true)
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.isPitchEnabled = true
        mapView.isZoomEnabled = true
        mapView.isRotateEnabled = true
        mapView.register(
            StationAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: StationAnnotationView.reuseId) // MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.register(
            StationClusterAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(dropAPinForNewStation(_:)))
        mapView.addGestureRecognizer(longPressGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let results = CLLocationManager.locationServicesEnabled()
            DispatchQueue.main.async {
                if results {
                    switch self.locationManager.authorizationStatus {
                    case .notDetermined:
                        self.locationManager.requestWhenInUseAuthorization()
                    case .restricted, .denied:
                        // show message
                        self.locationManager.stopUpdatingLocation()
                        self.locationManagerError()
                    case .authorizedWhenInUse, .authorizedAlways:
                        /// app is authorized
                        self.locationManager.requestLocation()
                    default:
                        self.locationManager.requestWhenInUseAuthorization()
                        break
                    }
                }
                else {
                    self.locationManagerError()
                }
            }
        }
    }
}

private extension BCycleStationsViewController {
    
    func locationManagerError() {
        DispatchQueue.main.async {
            let msg = "Unable to get the current location.  Using Denver, CO."
            let alert = UIAlertController(title: "Location Error",
                                          message: msg,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                self.currentLocation = CLLocation(latitude: 39.758202, longitude: -105.001359)
                self.mapView.setCenter(self.currentLocation!.coordinate, animated: true)
                // create the initial search area
                let searchRegion: MKCoordinateRegion = self.createSearchRegionForLocation(self.currentLocation!.coordinate,
                                                                                          distance: 0.5)
                self.mapView.setRegion(searchRegion, animated: true)
                self.addAnnotationsForRegion(searchRegion)
                if let currentLocation = self.currentLocation {
                    CLGeocoder().reverseGeocodeLocation(currentLocation) { clPlacmarks, _ in
                        if let placemarks = clPlacmarks, let placemark = placemarks.first {
                            self.currentPlacemark = placemark
                        }
                    }
                }
            }))
            self.present(alert, animated: true)
        }
    }
    
    func addAnnotationsForRegion(_ region: MKCoordinateRegion) {
        Task {
            do {
                let bcycleApiService: BCycleApiService = BCycleApiService()
                let stations = try await bcycleApiService.getStationsInRegion(region)
                DispatchQueue.main.async {
                    for annotation in self.mapView.annotations {
                        if let station = annotation as? StationAnnotation {
                            self.mapView.removeAnnotation(station)
                        }
                        if let cluster = annotation as? MKClusterAnnotation {
                            self.mapView.removeAnnotation(cluster)
                        }
                    }
                    
                    let stationAnnotations: [StationAnnotation] = stations.map({ StationAnnotation(station: $0) })
                    self.mapView.addAnnotations(stationAnnotations)
                    self.mapView.reloadInputViews()
                }
            }
            catch {
                DispatchQueue.main.async {
                    let alertController = UIAlertController(
                        title: NSLocalizedString("No BCycle stations found.", comment: "No BCycle stations found."),
                        message: "We were unable to locate BCycle stations in your area.",
                        preferredStyle: .alert
                    )
                    
                    let continueAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    
                    alertController.addAction(continueAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    func createRectForRegion(_ region: MKCoordinateRegion) -> MKMapRect {
        
        let a = MKMapPoint(CLLocationCoordinate2DMake(region.center.latitude + region.span.latitudeDelta / 2.0,
                                                      region.center.longitude - region.span.longitudeDelta / 2.0))
        let b = MKMapPoint(CLLocationCoordinate2DMake(region.center.latitude - region.span.latitudeDelta / 2.0,
                                                      region.center.longitude + region.span.longitudeDelta / 2.0))
        
        return MKMapRect(x: min(a.x,b.x), y: min(a.y,b.y), width: abs(a.x-b.x), height: abs(a.y-b.y))
    }
    
    func createSearchRegionForLocation(_ coordinate: CLLocationCoordinate2D, distance: CLLocationDistance) -> MKCoordinateRegion {
        
        let latInMeters: CLLocationDirection = distance * MetersPerMile
        let longInMeters: CLLocationDirection = distance * MetersPerMile
        let region: MKCoordinateRegion = MKCoordinateRegion(center: coordinate,
                                                            latitudinalMeters: latInMeters,
                                                            longitudinalMeters: longInMeters)
        
        return region
    }
    
    func createViewableRegionForLocation(_ coordinate: CLLocationCoordinate2D, distance: CLLocationDistance) -> MKCoordinateRegion {
        let latInMeters: CLLocationDirection = distance * MetersPerMile
        let longInMeters: CLLocationDirection = distance * MetersPerMile
        return MKCoordinateRegion(center: coordinate, latitudinalMeters: latInMeters, longitudinalMeters: longInMeters)
    }
    
    
    // MARK: - Actions
    @objc func addStation(_ barButtonItem: UIBarButtonItem) {
        let viewController = AddStationViewController()
        viewController.placemark = currentPlacemark
        viewController.delegate = self
        let nav = UINavigationController(rootViewController: viewController)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.selectedDetentIdentifier = .large
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        present(nav, animated: true)
    }
    
    @objc func dropAPinForNewStation(_ sender: UILongPressGestureRecognizer) {
        if sender.state != UIGestureRecognizer.State.ended {
            let touchLocation = sender.location(in: self.mapView)
            let locationCoordinate = self.mapView.convert(touchLocation, toCoordinateFrom: self.mapView)
            print("Latitude: \(locationCoordinate.latitude), Longitude: \(locationCoordinate.longitude)")
            let newBcycleLocation = MKPointAnnotation()
            newBcycleLocation.coordinate = locationCoordinate
            newBcycleLocation.title = "Dropped Pin"
            newBcycleLocation.subtitle = "Latitude: \(locationCoordinate.latitude), Longitude: \(locationCoordinate.longitude)"
            self.mapView.addAnnotation(newBcycleLocation)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension BCycleStationsViewController : @preconcurrency CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            // show message
            manager.stopUpdatingLocation()
            locationManagerError()
        case .authorizedWhenInUse, .authorizedAlways:
            /// app is authorized
            manager.requestLocation()
        default:
            locationManagerError()
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error: \(error.localizedDescription)")
        if let clerror = error as? CLError, clerror.code != .locationUnknown {
            locationManager.stopUpdatingLocation()
            mapView.centerCoordinate = CLLocationCoordinate2DMake(39.758202, -105.001359)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
        
        if let currentLocation = currentLocation {
            locationManager.stopUpdatingLocation()
            CLGeocoder().reverseGeocodeLocation(currentLocation) { clPlacmarks, _ in
                if let placemarks = clPlacmarks, let placemark = placemarks.first {
                    self.currentPlacemark = placemark
                }
            }
        }
        
        if let coordinate = self.currentLocation?.coordinate {
            DispatchQueue.main.async {
                self.mapView.setCenter(coordinate, animated: true)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("location manager did change authorization status")
    }
}

// MARK: - MKMapViewDelegate
extension BCycleStationsViewController : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        currentLocation = userLocation.location
        if let coordiante = userLocation.location?.coordinate {
            mapView.setCenter(coordiante, animated: true)
        }
        
        let region: MKCoordinateRegion = createViewableRegionForLocation(userLocation.coordinate, distance: 0.5)
        mapView.setRegion(region, animated: true)
        if !userInteractionCausedRegionChange {
            addAnnotationsForRegion(region)
        }
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        if let view = mapView.subviews.first, let gestureRecognizers = view.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if recognizer.state == .began || recognizer.state == .ended || recognizer.state == .changed {
                    userInteractionCausedRegionChange = true
                    break
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if userInteractionCausedRegionChange {
            userInteractionCausedRegionChange = false
            addAnnotationsForRegion(mapView.region)
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        guard !(view.annotation is MKUserLocation) else { return }
        
        var newViewController: UIViewController?
        
        if view.annotation is StationAnnotation {
            let stationAnnotation = view.annotation as! StationAnnotation
            let viewController = StationInformationViewController()
            viewController.title = stationAnnotation.station.name ?? "BCycle Location"
            viewController.stationAnnotation = stationAnnotation
            viewController.userLocation = currentLocation
            viewController.delegate = self
            newViewController = viewController
        }
        else if view.annotation is MKPointAnnotation {
            let viewController = DroppedPinViewController()
            viewController.title = "Dropped Pin"
            viewController.pinLocation = view.annotation?.coordinate
            viewController.annotation = view.annotation
            viewController.delegate = self
            newViewController = viewController
        }
        
        guard let newViewController = newViewController else { return }
        let nav = UINavigationController(rootViewController: newViewController)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.selectedDetentIdentifier = .medium
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        
        // Display the annotation information
        present(nav, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        
        guard let annotation = annotation as? StationAnnotation else { return nil }
        
        guard let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: StationAnnotationView.reuseId) as? StationAnnotationView else {
            return StationAnnotationView(annotation: annotation, reuseIdentifier: StationAnnotationView.reuseId)
        }
        annotationView.annotation = annotation
        annotationView.clusteringIdentifier = StationAnnotationView.clusteringId
        return annotationView
    }
    
}

// MARK: - AddStationViewControllerDelegate
extension BCycleStationsViewController: @preconcurrency AddStationViewControllerDelegate {
    
    func addStationViewController(_ controller: AddStationViewController, didAddStationAt placemark: CLPlacemark) {
        addAnnotationsForRegion(mapView.region)
    }
}

// MARK: - DropPinViewControllerDelegate
extension BCycleStationsViewController: @preconcurrency DropPinViewControllerDelegate {
    
    func droppedPinViewController(_ controller: DroppedPinViewController, remove annotation: any MKAnnotation) {
        self.mapView.removeAnnotation(annotation)
        addAnnotationsForRegion(mapView.region)
    }
    
    func droppedPinViewController(_ controller: DroppedPinViewController, didDeselect annotation: any MKAnnotation) {
        self.mapView.deselectAnnotation(annotation, animated: true)
    }
}

// MARK: - StationInformationViewControllerDelegate
extension BCycleStationsViewController: @preconcurrency StationInformationViewControllerDelegate {
    
    func stationInformationViewController(_ viewController: StationInformationViewController, didDeselect annotation: StationAnnotation) {
        self.mapView.deselectAnnotation(annotation, animated: true)
    }
    
}
