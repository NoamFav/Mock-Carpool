//
//  ContentView.swift
//  Mock-Carpool
//
//  Created by Boss on 06/09/2024.
//

import SwiftUI
import MapKit

struct ContentView: View {
    
    @State private var startLocation: String = ""
    @State private var endLocation: String = ""
    @State private var startCompletions: [MKLocalSearchCompletion] = []
    @State private var endCompletions: [MKLocalSearchCompletion] = []
    
    @State private var isStartFieldActive: Bool = false
    @State private var isEndFieldActive: Bool = false
    
    @State private var mapItems: [MKMapItem] = []
    @State private var directions: MKDirections.Response?
    @State private var routePolyline: MKPolyline?
    
    private var startAutocompleteDelegate = AutocompleteDelegate(completions: .constant([]))
    private var endAutocompleteDelegate = AutocompleteDelegate(completions: .constant([]))
    
    let completer = MKLocalSearchCompleter()
    
    var body: some View {
        VStack {
            TextField("Start location", text: $startLocation, onEditingChanged: { isEditing in
                isStartFieldActive = isEditing
                isEndFieldActive = false
                updateAucompleteResults(for: $startCompletions, with: startLocation)
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
            .keyboardType(.default)
            
            if isStartFieldActive && !startCompletions.isEmpty {
                List(startCompletions, id: \.self) { completion in
                    Text(completion.title)
                        .onTapGesture {
                            self.startLocation = completion.title
                            self.isStartFieldActive = false
                            startCompletions.removeAll()
                        }
                }
                .frame(maxHeight: 200)
            }
            
            TextField("End location", text: $endLocation, onEditingChanged: { isEditing in
                isEndFieldActive = isEditing
                isStartFieldActive = false
                updateAucompleteResults(for: $endCompletions, with: endLocation)
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
            .keyboardType(.default)
            
            if isEndFieldActive && !endCompletions.isEmpty {
                List(endCompletions, id: \.self) { completion in
                    Text(completion.title)
                        .onTapGesture {
                            self.endLocation = completion.title
                            self.isEndFieldActive = false
                            endCompletions.removeAll()
                        }
                }
                .frame(maxHeight: 200)
            }
            
            Button(action: searchForRoute) {
                Text("Get route")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            MapView(routePolyline: $routePolyline, mapItems: $mapItems)
                .edgesIgnoringSafeArea(.all)
        }
        .padding()
    }
    
    func updateAucompleteResults(for completions: Binding<[MKLocalSearchCompletion]>, with query: String) {
        completer.queryFragment = query
        completer.resultTypes = .address
        completer.delegate = isStartFieldActive ? startAutocompleteDelegate : endAutocompleteDelegate
    }
    
    func searchForRoute() {
        let startRequest = MKLocalSearch.Request()
        startRequest.naturalLanguageQuery = startLocation
        
        let endRequest = MKLocalSearch.Request()
        endRequest.naturalLanguageQuery = endLocation
        
        let startSearch = MKLocalSearch(request: startRequest)
        let endSearch = MKLocalSearch(request: endRequest)
        
        startSearch.start { startResponse, error in
            if let startItem = startResponse?.mapItems.first {
                endSearch.start { endResponse, error in
                    if let endItem = endResponse?.mapItems.first {
                        self.mapItems = [startItem, endItem]
                        calculateRoute(from: startItem, to: endItem)
                    }
                }
            }
        }
    }
    
    func calculateRoute(from start: MKMapItem, to end: MKMapItem) {
        let directionRequest = MKDirections.Request()
        directionRequest.source = start
        directionRequest.destination = end
        directionRequest.transportType = .automobile // You can change this to walking, transit, etc.
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { response, error in
            if let error = error {
                print("Error calculating directions: \(error.localizedDescription)")
                return
            }
            
            if let response = response {
                DispatchQueue.main.async {
                    self.directions = response
                }
            }
        }
    }
}

struct MapView: UIViewRepresentable {
    @Binding var routePolyline: MKPolyline?
    @Binding var mapItems: [MKMapItem]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator // Set the delegate
        mapView.showsUserLocation = true
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays) // Remove old overlays
        if let polyline = routePolyline {
            mapView.addOverlay(polyline) // Add the route polyline
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

class AutocompleteDelegate: NSObject, MKLocalSearchCompleterDelegate {
    @Binding var completions: [MKLocalSearchCompletion]
    
    init(completions: Binding<[MKLocalSearchCompletion]>) {
        _completions = completions    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results
    }
}

#Preview {
    ContentView()
}
