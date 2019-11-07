//
//  ViewController.swift
//  MyLocation
//
//  Created by Bold Lion on 5.11.19.
//  Copyright © 2019 Bold Lion. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class UserLocation: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    let locationManager = CLLocationManager()
    let regionMeters: Double = 1000
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkDeviceLocationServices()
    }
    
   private func checkDeviceLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            // set up Location Manager
            initLocationManager()
            checkAppLocationAuthorisation()
        }
        else {
            // Location Services is disabled device wide
            showAlert(title: "Oops!", msg: "You need to enable Location Services in Settings > Privacy")
        }
    }
    
   private func initLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

   private func checkAppLocationAuthorisation() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            break
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            moveToUserLocation()
            locationManager.startUpdatingLocation()
            break
        case .denied:
            showAlert(title: "Oops!", msg: "You need to allow permission in the Settings > MyLocation > Location")
        case .restricted:
            showAlert(title: "Oops", msg: "This device has a restricted access.")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            break
        }
    }
    
    func moveToUserLocation() {
        guard let location2D = locationManager.location?.coordinate else { return }
        let region = MKCoordinateRegion(center: location2D, latitudinalMeters: regionMeters, longitudinalMeters: regionMeters)
        mapView.setRegion(region, animated: true)
    }

}

extension UserLocation: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, latitudinalMeters: regionMeters, longitudinalMeters: regionMeters)
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // When authorisation changes
        checkAppLocationAuthorisation()
    }
}
