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
    
    @State private var mapRegion: MKCoordinateRegion?
    
    private var startAutocompleteDelegate = AutocompleteDelegate(completions: .constant([]))
    private var endAutocompleteDelegate = AutocompleteDelegate(completions: .constant([]))
    
    let completer = MKLocalSearchCompleter()
    
    var body: some View {
        
        ZStack(alignment: .bottom) {
            
            MapView(routePolyline: $routePolyline, mapItems: $mapItems, region: $mapRegion)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                TextField("Start location", text: $startLocation, onEditingChanged: { isEditing in
                        isStartFieldActive = isEditing
                        isEndFieldActive = !isEditing
                    })
                .onChange(of: startLocation) {
                    updateAucompleteResults(for: $startCompletions, with: startLocation)
                    updateMapRegionBasedOnLocations()
                }
                .padding(.top)
                .padding(.horizontal)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
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
                    .padding(.horizontal)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                TextField("End location", text: $endLocation, onEditingChanged: { isEditing in
                    isEndFieldActive = isEditing
                    isStartFieldActive = false
                })
                .onChange(of: endLocation) {
                    updateAucompleteResults(for: $endCompletions, with: endLocation)
                    updateMapRegionBasedOnLocations()
                }
                .padding(.horizontal)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
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
                    .padding(.horizontal)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                Button(action: searchForRoute) {
                    Text("Get route")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.vertical)
            }
            .background(Color.gray.opacity(0.5))  // Add a background with some opacity for better visibility
            .cornerRadius(12) // Optional, for rounded corners on the container
            .padding(.horizontal)
            .ignoresSafeArea()
        }
    }
    
    func updateAucompleteResults(for completions: Binding<[MKLocalSearchCompletion]>, with query: String) {
        print("updating autocomplete")
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
            
            if let response = response, let route = response.routes.first {
                DispatchQueue.main.async {
                    self.directions = response
                    self.routePolyline = route.polyline
                }
            }
        }
    }
    
    func updateMapRegionBasedOnLocations() {
        if let startItem = mapItems.first {
            // If only start location is available
            let region = MKCoordinateRegion(center: startItem.placemark.coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)
            self.mapRegion = region
        }
    }
}

class AutocompleteDelegate: NSObject, MKLocalSearchCompleterDelegate {
    @Binding var completions: [MKLocalSearchCompletion]

    init(completions: Binding<[MKLocalSearchCompletion]>) {
        _completions = completions
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.completions = completer.results
            print("Completions updated: \(self.completions.map { $0.title })")
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Autocomplete failed with error: \(error)")
    }
}

#Preview {
    ContentView()
}
