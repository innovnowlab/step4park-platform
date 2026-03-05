import Foundation
import MapKit
import CoreLocation

/// Modern Map search result (iOS 18 → iOS 26)
/// iOS 26 deprecates `MKMapItem.placemark`; use `location` + `address` instead.
struct PlaceResult: Identifiable, Hashable {
    let id: UUID
    let item: MKMapItem

    init(id: UUID = UUID(), item: MKMapItem) {
        self.id = id
        self.item = item
    }

    var title: String { item.name ?? "Sans nom" }

    var subtitle: String {
        if #available(iOS 26.0, *) {
            return item.address?.shortAddress ?? item.address?.fullAddress ?? ""
        } else {
            return item.placemark.title ?? ""
        }
    }

    /// Coordinate can be nil (MapKit may not resolve a location for every result).
    var coordinate: CLLocationCoordinate2D? {
        if #available(iOS 26.0, *) {
            return item.location.coordinate
        } else {
            return item.placemark.coordinate
        }
    }
}
