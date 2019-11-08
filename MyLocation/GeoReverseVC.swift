//
//  GeoReverseVC.swift
//  MyLocation
//
//  Created by Bold Lion on 7.11.19.
//  Copyright © 2019 Bold Lion. All rights reserved.
//

import UIKit
import MapKit

class GeoReverseVC: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var directionsButton: UIButton!
    @IBOutlet weak var locationLabel: UILabel!
    let locationManager = CLLocationManager()
    var previousLocation: CLLocation?
    var directionsArr = [MKDirections]()

    override func viewDidLoad() {
        super.viewDidLoad()
        setDirectionsButtonUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkDeviceLocationService()
    }
    
    private func setDirectionsButtonUI() {
        directionsButton.backgroundColor = .white
        directionsButton.tintColor = .blue
        directionsButton.layer.borderColor = UIColor.blue.cgColor
        directionsButton.layer.borderWidth = 1
        directionsButton.layer.cornerRadius = 5
    }
    
    func getDirections() {
        guard let location = locationManager.location?.coordinate else {
            showAlert(title: "Uh-oh!", msg: "We dont have your current addess")
            return
        }
        
        let request = setDirectionsRequest(from: location)
        let directions = MKDirections(request: request)
        replaceOldMapViewDirections(withNew: directions)
        
        directions.calculate { [unowned self] (response, error) in
            if error != nil {
                self.showAlert(title: "Oops!", msg: error!.localizedDescription)
                return
            }
            guard let response = response else {
                self.showAlert(title: "Oops!", msg: "Response not available right now.")
                return
            }
            
            for route in response.routes {
                // NOTE: To get directions step by step - each step contains a SINGLE direction
                // let steps = route.steps
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    func setDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request {
        let destinationCoordinate = centerLocation(for: mapView).coordinate
        let startingLocation = MKPlacemark(coordinate: coordinate)
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        return request
    }
    
    @IBAction func directionsTapped(_ sender: UIButton) {
        getDirections()
    }
    
    private func checkDeviceLocationService() {
        if CLLocationManager.locationServicesEnabled() {
            initLocationManager()
            checkAuthorisationStatus()
        }
        else {
            showAlert(title: "Oops!", msg: "You need to enable Location Services in Settings > Privacy > Location")
        }
    }
    
    func initLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func checkAuthorisationStatus() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            break
        case .authorizedWhenInUse:
            trackUserLocation()
        case .denied:
            showAlert(title: "Oops!", msg: "You need to allow permission in the Settings > MyLocation > Location")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            showAlert(title: "Oops", msg: "This device has a restricted access.")
        default:
            break
        }
    }
    
    private func trackUserLocation() {
        mapView.showsUserLocation = true
        centerUserToLocation()
        locationManager.startUpdatingLocation()
        previousLocation = centerLocation(for: mapView)
    }
    
    private func centerUserToLocation() {
        guard let location = locationManager.location?.coordinate else { return }
        let region = MKCoordinateRegion(center: location, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: true)
    }
    
    private func centerLocation(for mapView: MKMapView) -> CLLocation {
        let longiture = mapView.centerCoordinate.longitude
        let latitude = mapView.centerCoordinate.latitude
        
        return CLLocation(latitude: latitude, longitude: longiture)
    }
    
    private func replaceOldMapViewDirections(withNew directions: MKDirections) {
        mapView.removeOverlays(mapView.overlays)
        directionsArr.append(directions)
        let _ = directionsArr.map { $0.cancel() }
    }
    
}


extension GeoReverseVC: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkAuthorisationStatus()
    }
}

extension GeoReverseVC: MKMapViewDelegate {
   
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = centerLocation(for: mapView)
        let geoCoder = CLGeocoder()
        
        guard let prevLocation = previousLocation else { return }
        guard center.distance(from: prevLocation) > 75 else { return }
        previousLocation = center
        
        geoCoder.reverseGeocodeLocation(center) { [unowned self] (placemarks, error) in
            if let err = error {
                self.showAlert(title: "Uh-oh!", msg: err.localizedDescription)
            }
            guard let placemark = placemarks?.first else {
                self.showAlert(title: "Something went wrong", msg: "No data")
                return
            }
            
            let streetNum = placemark.subThoroughfare ?? ""
            let nameOfStreet = placemark.thoroughfare ?? ""
            
            DispatchQueue.main.async { [unowned self] in
                self.locationLabel.text = "\(streetNum) \(nameOfStreet)"
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .red
        return renderer
    }
}
