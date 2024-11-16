//
//  StationInformationViewController.swift
//  BCycle
//
//  Created by Thomas Traylor on 1/27/24.
//

import UIKit
import MapKit
import CoreLocation

protocol StationInformationViewControllerDelegate: AnyObject {
    func stationInformationViewController(_ viewController: StationInformationViewController, didDeselect annotation: StationAnnotation)
}

class StationInformationViewController: UIViewController {

    var stationAnnotation: StationAnnotation? = nil {
        didSet {
            station = stationAnnotation?.station
        }
    }
    
    var userLocation: CLLocation?
    
    weak var delegate: StationInformationViewControllerDelegate?
    
    private var station: Station?
    private var cancelButton: UIBarButtonItem!
    
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
        navigationController?.navigationItem.largeTitleDisplayMode = .inline
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.tintColor = .white
        let offset = UIOffset(horizontal: -CGFloat.greatestFiniteMagnitude, vertical: 0)
        navigationController?.navigationBar.standardAppearance.titlePositionAdjustment = offset
        navigationController?.navigationBar.scrollEdgeAppearance?.titlePositionAdjustment = offset
        navigationController?.navigationBar.compactAppearance?.titlePositionAdjustment = offset
        setNeedsStatusBarAppearanceUpdate()
        navigationItem.setRightBarButton(cancelButton, animated: true)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(AddressTableViewCell.self, forCellReuseIdentifier: AddressTableViewCell.reuseId)
        tableView.register(DistanceTableViewCell.self, forCellReuseIdentifier: DistanceTableViewCell.reuseId)
        tableView.register(CoordinatesTableViewCell.self, forCellReuseIdentifier: CoordinatesTableViewCell.reuseId)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let stationAnnotation {
            delegate?.stationInformationViewController(self, didDeselect: stationAnnotation)
        }
    }
}

private extension StationInformationViewController {
    // MARK: - Actions
    @objc func cancelStation(_ barButtonItem: UIBarButtonItem) {
        dismiss(animated: true)
    }
}

extension StationInformationViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        else if section == 1 {
            return 2
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let view = DistanceTableViewCell()
            view.setup(station, userLocation: userLocation)
            return view
        case 1:
            if indexPath.row == 0 {
                let view = AddressTableViewCell()
                view.setup(station: station)
                return view
            }
            else if indexPath.row == 1 {
                let view = CoordinatesTableViewCell()
                view.coordinates = CLLocationCoordinate2D(latitude: station?.latitude ?? 0, longitude: station?.longitude ?? 0)
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

extension StationInformationViewController: UITableViewDelegate {
    
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
                headerView.textLabel?.text = "Distance"
            case 1:
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
            return "Distance"
        case 1:
            return "Details"
        default:
            return nil
        }
    }
}

