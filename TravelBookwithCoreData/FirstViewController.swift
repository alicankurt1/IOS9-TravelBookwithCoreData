//
//  FirstViewController.swift
//  TravelBookwithCoreData
//
//  Created by Alican Kurt on 12.08.2021.
//

import UIKit
import CoreData

class FirstViewController: UIViewController , UITableViewDelegate, UITableViewDataSource{

    @IBOutlet weak var placesTableView: UITableView!
    var placeNameArray = [String]()
    var uuidArray = [UUID]()
    var choosenPlaceId : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        placesTableView.delegate = self
        placesTableView.dataSource = self
        
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButtonClick))
        
        getData()
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newPlace"), object: nil)
        
    }
    
    
    @objc func getData(){
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        request.returnsObjectsAsFaults = false
        
        do {
            let results =  try context.fetch(request)
            if results.count > 0{
                self.placeNameArray.removeAll(keepingCapacity: false)
                self.uuidArray.removeAll(keepingCapacity: false)
                
                for result in results as! [NSManagedObject]{
                    if let placeName = result.value(forKey: "name") as? String, let id = result.value(forKey: "id") as? UUID{
                        placeNameArray.append(placeName)
                        uuidArray.append(id)
                    }
                    
                    
                }
                placesTableView.reloadData()
            }
            
            
        } catch  {
            print("Get Data Error")
        }
        
        
        
    }
    
    
    
    @objc func addButtonClick(){
        choosenPlaceId = nil
        performSegue(withIdentifier: "toMapVC", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return uuidArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = placeNameArray[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        choosenPlaceId = uuidArray[indexPath.row]
        performSegue(withIdentifier: "toMapVC", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMapVC"{
            let destinationVC = segue.destination as! ViewController
            destinationVC.choosenPlaceId = self.choosenPlaceId            
        }
    }
    
    

}
