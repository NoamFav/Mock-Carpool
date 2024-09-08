//
//  MapView.swift
//  Mock-Carpool
//
//  Created by Boss on 08/09/2024.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var routePolyline: MKPolyline?
    @Binding var mapItems: [MKMapItem]
    @Binding var region: MKCoordinateRegion?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator // Set the delegate
        mapView.showsUserLocation = true
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        if let region = region {
            mapView.setRegion(region, animated: true)
        }
        
        mapView.removeOverlays(mapView.overlays) // Remove old overlays

        if let polyline = routePolyline {
            mapView.addOverlay(polyline) // Add the route polyline

            let rect = polyline.boundingMapRect
            mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: true)

        }

        // Update annotations similarly as before
        mapView.removeAnnotations(mapView.annotations)
        let annotations = mapItems.map { item -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.coordinate = item.placemark.coordinate
            annotation.title = item.name
            return annotation
        }
        mapView.addAnnotations(annotations)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 4.0
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}
