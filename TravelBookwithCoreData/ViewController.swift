//
//  ViewController.swift
//  TravelBookwithCoreData
//
//  Created by Alican Kurt on 11.08.2021.
//

import UIKit
import MapKit
import CoreLocation
import CoreData


class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var locationManager = CLLocationManager()
    @IBOutlet weak var placeNameText: UITextField!
    @IBOutlet weak var commentText: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    var touchedCoordinates = CLLocationCoordinate2D()
    var choosenPlaceId : UUID?
    var placeName = ""
    var comment = ""
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        mapView.delegate = self
        locationManager.delegate = self
        // Find User Location
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // Take location while using app
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // Long Press Gesture Recognizer
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(choosenLocation(gestureRecognizer:)))
        longPressGestureRecognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(longPressGestureRecognizer)
        
        if choosenPlaceId != nil{
            saveButton.isHidden = true
            
            let idString = choosenPlaceId?.uuidString
            let results = getDataWithId(choosenPlaceId: idString!)
            if results.count > 0 {
                
                for result in results as! [NSManagedObject]{
                    if let placeName = result.value(forKey: "name") as? String, let comment = result.value(forKey: "comment") as? String, let latitude = result.value(forKey: "latitude") as? Double, let longitude = result.value(forKey: "longitude") as? Double{
                        let annotation = MKPointAnnotation()
                        annotation.title = placeName
                        annotation.subtitle = comment
                        self.placeName = placeName
                        self.comment = comment
                        touchedCoordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        annotation.coordinate = touchedCoordinates
                        
                        mapView.addAnnotation(annotation)
                        placeNameText.text = placeName
                        commentText.text = comment
                        
                        // Stop Update and Focus camera choosen place
                        locationManager.stopUpdatingLocation()
                        let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                        let region = MKCoordinateRegion(center: touchedCoordinates, span: span)
                        mapView.setRegion(region, animated: true)
                        
                        
                    }
                }
                
                            
            }
            
        }
        
        
        
    
        
        
        
    }
    
    
    func getDataWithId(choosenPlaceId : String) -> [Any]{
        var results = [Any]()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        fetchRequest.predicate = NSPredicate(format: "id = %@", choosenPlaceId)
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            results = try context.fetch(fetchRequest)
        } catch {
            print("getDataWithId Error")
        }
        return results
        
    }
    
    
    
    @objc func choosenLocation(gestureRecognizer:UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began{
            
            // Geting location Coordinate from touched point
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            
            // Adding new annotation
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = placeNameText.text
            annotation.subtitle = commentText.text
            self.mapView.addAnnotation(annotation)
            
            
        }
    }

    // Taking current location and update continously
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if choosenPlaceId == nil{
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: false)
        }
        
    }
    
    // Customize Map Pin // "viewforannotation"
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Dont show User Location
        
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        } else {
            pinView?.annotation = annotation
        }
        
        
        return pinView
    }
    
    
    // Go To Navigation "calloutaccessorycontrollerTapped"
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if choosenPlaceId != nil{
            
            let requestLocation = CLLocation(latitude: touchedCoordinates.latitude, longitude: touchedCoordinates.longitude)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                // closure
                if placemarks != nil {
                    let newPlacemark = MKPlacemark(placemark: placemarks![0])
                    let item = MKMapItem(placemark: newPlacemark)
                    item.name = self.placeName
                    
                    let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                    item.openInMaps(launchOptions: launchOptions)
                }
            }
        }
    }
    
    
    
    
    @IBAction func saveButtonClick(_ sender: Any) {
        
        if placeNameText.text == "" || commentText.text == ""{
            showAlert(title: "Empty Area", message: "Please do not pass empty Place Name or Comment!")
        }else if touchedCoordinates.latitude == 0.0 {
            showAlert(title: "Choosing Place", message: "Please choose a place in Map!")
        }else{
            // Insert Database to new Place
            insertDatabase()
        }
         
    }
    
    
    func insertDatabase(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        newPlace.setValue(UUID(), forKey: "id")
        newPlace.setValue(placeNameText.text, forKey: "name")
        newPlace.setValue(commentText.text, forKey: "comment")
        newPlace.setValue(touchedCoordinates.latitude, forKey: "latitude")
        newPlace.setValue(touchedCoordinates.longitude, forKey: "longitude")
        
        
        do {
            try context.save()
            print("success")
        } catch  {
            print("error")
        }
        
        // after the save go to backward page
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        navigationController?.popViewController(animated: true)
        
    }
    
    
    func showAlert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        let okButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler:   nil)
        alert.addAction(okButton)
        self.present(alert, animated: true, completion: nil)
    }
    

}

