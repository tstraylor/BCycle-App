//
//  StationAnnotationView.swift
//  BCycle
//
//  Created by Thomas Traylor on 10/6/24.
//

import Foundation
import MapKit

class StationAnnotationView: MKMarkerAnnotationView {
    
    static let reuseId: String = "StationAnnotationView"
    static let clusteringId = "BCycle_Station_Cluster"
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = StationAnnotationView.clusteringId
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForDisplay() {
        super.prepareForDisplay()
        displayPriority = .defaultHigh
        markerTintColor = .systemRed
        glyphImage = UIImage(systemName: "bicycle")
    }
    
}
