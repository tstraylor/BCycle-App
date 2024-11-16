//
//  DroppedPinViewController.swift
//  BCycle
//
//  Created by Thomas Traylor on 2/4/24.
//

import UIKit
import MapKit

protocol DropPinViewControllerDelegate: AnyObject {
    func droppedPinViewController(_ controller: DroppedPinViewController, remove annotation: MKAnnotation)
    func droppedPinViewController(_ controller: DroppedPinViewController, didDeselect annotation: MKAnnotation)
}

@MainActor
class DroppedPinViewController: UIViewController {

    var annotation: MKAnnotation?
    
    var pinLocation: CLLocationCoordinate2D?
    
    var userLocation: CLLocation?
    
    weak var delegate: DropPinViewControllerDelegate?
    
    private var placemark: CLPlacemark?
    private var cancelButton: UIBarButtonItem!
    private var menuButton: UIBarButtonItem!
    
    private var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .insetGrouped)
        return view
    }()
    
    override func loadView() {
        view = UIView(frame: .zero)
        view.backgroundColor = .systemBackground
        
        cancelButton = UIBarButtonItem(image: UIImage(systemName: "x.circle"),
                                       style: .plain,
                                       target: self,
                                       action: #selector(cancelStation(_:)))
        cancelButton.tintColor = .systemRed
        
        let menuItems: [UIAction] = [
            UIAction(title: "Add BCycle Station", image: UIImage(systemName: "plus"), handler: { (_) in
                self.addStation()
            }),
            UIAction(title: "Remove", image: UIImage(systemName: "trash"), attributes: .destructive, handler: { (_) in
                self.removePinDrop()
            })
        ]

        let pullDownMenu = UIMenu(image: nil, identifier: nil, children: menuItems)
        
        menuButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), menu: pullDownMenu)
    
        menuButton.tintColor = .systemRed
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: tableView.trailingAnchor)
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
        let offset = UIOffset(horizontal: -CGFloat.greatestFiniteMagnitude, vertical: 0)
        navigationController?.navigationBar.standardAppearance.titlePositionAdjustment = offset
        navigationController?.navigationBar.scrollEdgeAppearance?.titlePositionAdjustment = offset
        navigationController?.navigationBar.compactAppearance?.titlePositionAdjustment = offset
        setNeedsStatusBarAppearanceUpdate()
        
        navigationItem.setRightBarButtonItems([cancelButton,menuButton], animated: true)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(AddressTableViewCell.self, forCellReuseIdentifier: AddressTableViewCell.reuseId)
        tableView.register(CoordinatesTableViewCell.self, forCellReuseIdentifier: CoordinatesTableViewCell.reuseId)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task {
            if let coordinates = annotation?.coordinate {
                let currentLocation = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
                placemark = await getPlacemark(currentLocation)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let annotation {
            delegate?.droppedPinViewController(self, didDeselect: annotation)
        }
    }
}

private extension DroppedPinViewController {
    
    /// Get CLPlacemark from the current location.
    /// - Parameters:
    ///     - currentLocation: The current location (CLLocation).
    /// - Returns: A CLPlacemark representing the current location.
    ///
    private func getPlacemark(_ currentLocation: CLLocation) async -> CLPlacemark? {
        return await withCheckedContinuation { continuation in
            CLGeocoder().reverseGeocodeLocation(currentLocation) { clPlacmarks, _ in
                if let placemarks = clPlacmarks, let placemark = placemarks.first {
                    continuation.resume(returning: placemark)
                }
                else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    /// Dismiss the current view controller.
    @objc func cancelStation(_ barButtonItem: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    /// Add the current pin drop location as a BCycle station location.
    ///
    func addStation() {
        let viewController = AddStationViewController()
        viewController.placemark = placemark
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
    
    /// Remove the current Pin Drop being displayed.
    ///
    func removePinDrop() {
        if let annotation {
            delegate?.droppedPinViewController(self, remove: annotation)
            self.annotation = nil
        }
        dismiss(animated: true)
    }
}

extension DroppedPinViewController: @preconcurrency AddStationViewControllerDelegate {
    func addStationViewController(_ controller: AddStationViewController, didAddStationAt placemark: CLPlacemark) {
        if let annotation {
            if annotation.coordinate.latitude == placemark.location!.coordinate.latitude
                && annotation.coordinate.longitude == placemark.location!.coordinate.longitude {
                delegate?.droppedPinViewController(self, remove: annotation)
                self.annotation = nil
                DispatchQueue.main.async {
                    self.dismiss(animated: true)
                }
            }
        }
    }
}

extension DroppedPinViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return 2
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                let view = AddressTableViewCell()
                view.setup(placemark: placemark)
                return view
            }
            else if indexPath.row == 1 {
                let view = CoordinatesTableViewCell()
                view.coordinates = pinLocation
                return view
            }
            else {
                return UITableViewCell()
            }
        default:
            return UITableViewCell()
        }
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
}

extension DroppedPinViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            switch section {
            case 0:
                headerView.textLabel?.text = "Details"
            default:
                headerView.textLabel?.text = nil
            }
            headerView.textLabel?.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .headline).pointSize, weight: .bold)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Details"
        default:
            return nil
        }
    }
}
