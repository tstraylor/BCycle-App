//
//  DistanceTableViewCell.swift
//  BCycle
//
//  Created by Thomas Traylor on 2/3/24.
//

import UIKit
import MapKit

class DistanceTableViewCell: UITableViewCell {

    static let reuseId = "DistanceTableViewCell"
    
    private var walkImageView: UIImageView = {
        let image = UIImage(systemName: "figure.walk")
        image?.withTintColor(.red)
        let view = UIImageView(image: image)
        return view
    }()
    
    private var distanceLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: 17)
        label.text = "0.00 miles"
        return label
    }()
    
    private let MetersPerMile: Double = 1609.344
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    init() {
        super.init(style: .default, reuseIdentifier: "DetailTableViewCell")
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        MainActor.assumeIsolated {
            setupView()
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        setup(.none, userLocation: .none)
    }
    
    func setup(_ station: Station?, userLocation: CLLocation?) {
        if let userCoordinate = userLocation?.coordinate, let latitude = station?.latitude, let longitude = station?.longitude {
            Task {
                let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let distance = await calculateDistance(start: userCoordinate, end: coordinates)
                DispatchQueue.main.async {
                    self.distanceLabel.text = String(format: "%.2f mi away", (distance/self.MetersPerMile))
                    self.distanceLabel.isHidden = false
                }
            }
        }
        else {
            self.distanceLabel.isHidden = true
            self.distanceLabel.text = String(format: "%.2f mi away", (0.0))
        }
    }

}

private extension DistanceTableViewCell {

    func setupView() {
        
        [walkImageView, distanceLabel].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        let walkImageViewConstraints = [
            walkImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16.0),
            walkImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12.0),
            contentView.bottomAnchor.constraint(equalTo: walkImageView.bottomAnchor, constant: 16.0),
        ]
        let distanceLabelConstraints = [
            distanceLabel.centerYAnchor.constraint(equalTo: walkImageView.centerYAnchor),
            distanceLabel.leadingAnchor.constraint(equalTo: walkImageView.trailingAnchor, constant: 12.0),
            contentView.trailingAnchor.constraint(greaterThanOrEqualTo: distanceLabel.trailingAnchor, constant: 12.0)
        ]
        
        [walkImageViewConstraints, distanceLabelConstraints].forEach(NSLayoutConstraint.activate(_:))
        distanceLabel.isHidden = true
    }
    
    func calculateDistance(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) async -> Double {
        
        let startMapItem = MKMapItem(placemark: MKPlacemark(coordinate: start))
        let endMapItem = MKMapItem(placemark: MKPlacemark(coordinate: end))
        let request = MKDirections.Request()
        request.source = startMapItem
        request.destination = endMapItem
        request.transportType = .walking
        let directions = MKDirections(request: request)
        return await withCheckedContinuation { continuation in
            directions.calculate { response, error in
                if let response = response, let route = response.routes.first {
                    continuation.resume(returning: route.distance)
                }
                else {
                    continuation.resume(returning: 0.0)
                }
            }
        }
    }
}
