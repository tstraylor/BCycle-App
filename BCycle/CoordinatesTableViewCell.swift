//
//  CoordinatesTableViewCell.swift
//  BCycle
//
//  Created by Thomas Traylor on 2/4/24.
//

import UIKit
import MapKit
import LocationFormatter

class CoordinatesTableViewCell: UITableViewCell {

    static let reuseId = "CoordinatesTableViewCell"
    
    var coordinates: CLLocationCoordinate2D? {
        get { return  currentCoordinates }
        set {
            currentCoordinates = newValue
            coordinateLabel.text = coordinateString(newValue)
        }
    }
    
    private var currentCoordinates: CLLocationCoordinate2D?
    
    private var coordinateLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: 17)
        return label
    }()
    
    private var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "Coordinates"
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
        coordinateLabel.text = nil
    }
}

private extension CoordinatesTableViewCell {
    
    func setupView() {
        
        [titleLabel, coordinateLabel].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        let titleLabelConstraints = [
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16.0),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12.0),
            contentView.trailingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 12.0)
        ]
        
        let coordinateLabelConstraints = [
            coordinateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8.0),
            coordinateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12.0),
            contentView.bottomAnchor.constraint(equalTo: coordinateLabel.bottomAnchor, constant: 16.0),
            contentView.trailingAnchor.constraint(greaterThanOrEqualTo: coordinateLabel.trailingAnchor, constant: 12.0)
        ]
        
        [titleLabelConstraints, coordinateLabelConstraints].forEach(NSLayoutConstraint.activate(_:))
        
    }
    
    func coordinateString(_ coordinate: CLLocationCoordinate2D?) -> String? {
        let formatter = LocationCoordinateFormatter()
        formatter.format = .decimalDegrees
        if let coordinate = coordinate {
            return formatter.string(from: coordinate)
        }
    
        let newCoordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        return formatter.string(from: newCoordinate)
       
    }
}
