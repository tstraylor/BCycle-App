//
//  AddressTableViewCell.swift
//  BCycle
//
//  Created by Thomas Traylor on 1/28/24.
//

import UIKit
import MapKit

class AddressTableViewCell: UITableViewCell {
    
    static let reuseId = "DetailTableViewCell"
    
    var streetLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: 17)
        label.text = "123 Main St"
        return label
    }()
    
    var cityStateZipLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: 17)
        label.text = "Denver, CO 80204"
        return label
    }()

    private var addressLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "Address"
        label.font = .systemFont(ofSize: 17)
        return label
    }()
    
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
        setup(placemark: .none)
        setup(station: .none)
    }
    
    func setup(placemark: CLPlacemark?) {
        if let placemark = placemark {
            
            if let subThoroughfare = placemark.subThoroughfare, let thoroughfare = placemark.thoroughfare {
                streetLabel.text = "\(subThoroughfare) \(thoroughfare)"
            }
            else {
                streetLabel.text = " "
            }
            
            if let locality = placemark.locality, let administrativeArea = placemark.administrativeArea,
               let postalCode = placemark.postalCode {
                cityStateZipLabel.text = "\(locality), \(administrativeArea) \(postalCode)"
            }
            else {
                cityStateZipLabel.text = " "
            }
            
        }
        else {
            streetLabel.text = nil
            cityStateZipLabel.text = nil
        }
    }
    
    func setup(station: Station?) {
        if let street = station?.street, let city = station?.city,
            let state = station?.state, let zip = station?.zip {
            streetLabel.text = street
            cityStateZipLabel.text = "\(city), \(state) \(zip)"
        }
        else {
            streetLabel.text = nil
            cityStateZipLabel.text = nil
        }
    }
}

private extension AddressTableViewCell {
    func setupView() {
        
        [addressLabel, streetLabel, cityStateZipLabel].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        let addressLabelConstraints = [
            addressLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16.0),
            addressLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12.0),
            contentView.trailingAnchor.constraint(greaterThanOrEqualTo: addressLabel.trailingAnchor, constant: 12.0)
        ]
        
        let streetLabelConstraints = [
            streetLabel.topAnchor.constraint(equalTo: addressLabel.bottomAnchor, constant: 8.0),
            streetLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12.0),
            contentView.trailingAnchor.constraint(greaterThanOrEqualTo: streetLabel.trailingAnchor, constant: 12.0)
        ]
        
        let cityStateZipLabelConstraints = [
            cityStateZipLabel.topAnchor.constraint(equalTo: streetLabel.bottomAnchor, constant: 8.0),
            cityStateZipLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12.0),
            contentView.bottomAnchor.constraint(equalTo: cityStateZipLabel.bottomAnchor, constant: 12.0),
            contentView.trailingAnchor.constraint(greaterThanOrEqualTo: cityStateZipLabel.trailingAnchor, constant: 12.0)
        ]

        [addressLabelConstraints, streetLabelConstraints, cityStateZipLabelConstraints].forEach(NSLayoutConstraint.activate(_:))
    }
}
