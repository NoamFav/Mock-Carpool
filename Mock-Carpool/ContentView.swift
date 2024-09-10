//
//  ContentView.swift
//  Mock-Carpool
//
//  Created by Boss on 06/09/2024.
//

import SwiftUI
import MapKit

struct ContentView: View {
    
    // MARK: - State Variables
    @State private var startLocation: String = ""
    @State private var endLocation: String = ""
    
    @State private var isStartFieldActive: Bool = false
    @State private var isEndFieldActive: Bool = false
    
    @State private var mapItems: [MKMapItem] = []
    @State private var directions: MKDirections.Response?
    @State private var routePolyline: MKPolyline?
    
    @State private var mapRegion: MKCoordinateRegion?
    
    @State private var isRouteSearching: Bool = false
    
    @State private var routeDistance: String = ""
    @State private var routeTravelTime: String = ""
    
    // MARK: - View Body
    var body: some View {
        ZStack(alignment: .bottom) {
            
            // Background Gradient
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.4), Color.purple.opacity(0.7)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            // Map view with safe area ignored
            MapView(routePolyline: $routePolyline, mapItems: $mapItems, region: $mapRegion)
                .ignoresSafeArea()
            
            // UI Elements stacked vertically
            VStack(spacing: 16) {
                // Start Location TextField
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.red)
                        .padding()
                        .background(Color(white: 0.15))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.6), lineWidth: 1)
                        )
                    
                    TextField("Start location", text: $startLocation)
                        .padding()
                        .background(Color(white: 0.15))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.6), lineWidth: 1)
                        )
                }
                .padding(.horizontal)
                .padding(.top)
                
                // End Location TextField with better contrast
                HStack {
                    Image(systemName: "flag.fill")
                        .foregroundColor(.green)
                        .padding()
                        .background(Color(white: 0.15))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.6), lineWidth: 1)
                        )
                    
                    TextField("End location", text: $endLocation)
                        .padding()
                        .background(Color(white: 0.15))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.6), lineWidth: 1)
                        )
                }
                .padding(.horizontal)
                
                // Get Route Button with animation
                HStack {
                    Button(action: {
                        isRouteSearching = true
                        searchForRoute()
                    }) {
                        ZStack {
                            // Background Layer
                            if isRouteSearching {
                                Color.gray
                            } else {
                                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing)
                            }
                            
                            // Button Content (Icon/Text)
                            Text(Image(systemName: "location.fill"))
                                .fontWeight(.bold)
                                .padding()
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                                .scaleEffect(isRouteSearching ? 1.1 : 1.0)
                                .animation(.easeInOut, value: isRouteSearching)
                        }
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                        .shadow(color: .gray, radius: 5, x: 0, y: 5)
                    }
                    
                    if !routeDistance.isEmpty && !routeTravelTime.isEmpty {
                        VStack {
                            Text("Distance: \(routeDistance)")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Travel Time: \(routeTravelTime)")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.8))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom)
            }
            .background(Color.gray.opacity(0.9))
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(.horizontal)
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Helper Functions
    
    /// Initiates a search for the route between start and end locations.
    func searchForRoute() {
        let startRequest = MKLocalSearch.Request()
        startRequest.naturalLanguageQuery = startLocation
        
        let endRequest = MKLocalSearch.Request()
        endRequest.naturalLanguageQuery = endLocation
        
        let startSearch = MKLocalSearch(request: startRequest)
        let endSearch = MKLocalSearch(request: endRequest)
        
        // Search for start location
        startSearch.start { startResponse, error in
            if let startItem = startResponse?.mapItems.first {
                // Search for end location
                endSearch.start { endResponse, error in
                    if let endItem = endResponse?.mapItems.first {
                        self.mapItems = [startItem, endItem]
                        calculateRoute(from: startItem, to: endItem)
                        isRouteSearching = false
                    }
                }
            } else {
                isRouteSearching = false
            }
        }
    }
    
    /// Calculates the route between two MKMapItems.
    /// - Parameters:
    ///   - start: Starting MKMapItem.
    ///   - end: Destination MKMapItem.
    func calculateRoute(from start: MKMapItem, to end: MKMapItem) {
        let directionRequest = MKDirections.Request()
        directionRequest.source = start
        directionRequest.destination = end
        directionRequest.transportType = .automobile
        
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
                    
                    let distanceInKilometers = route.distance / 1000
                    let duration = route.expectedTravelTime / 60
                    
                    self.routeDistance = String(format: "%.2f km", distanceInKilometers)
                    
                    if duration > 60 {
                        let durationInHour = Int(duration) / 60  // Integer division to get hours
                        let durationInMinutes = Int(duration) % 60  // Modulo to get remaining minutes
                        self.routeTravelTime = String(format: "%d h %d min", durationInHour, durationInMinutes)
                    } else {
                        self.routeTravelTime = String(format: "%d min", Int(duration))
                    }
                }
            }
        }
    }
    
    /// Updates the map region based on start and end locations.
    func updateMapRegionBasedOnLocations() {
        if let startItem = mapItems.first {
            let region = MKCoordinateRegion(
                center: startItem.placemark.coordinate,
                latitudinalMeters: 5000,
                longitudinalMeters: 5000
            )
            self.mapRegion = region
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
