//
//  ViewController.swift
//  WeatherApp
//
//  Created by Angela Yu on 23/08/2015.
//  Copyright (c) 2015 London App Brewery. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire
import SwiftyJSON

class WeatherViewController: UIViewController, CLLocationManagerDelegate, ChangeCityDelegate {
    
    //Constants
    let WEATHER_URL = "http://api.openweathermap.org/data/2.5/weather"
    let APP_ID = "de5adb85ae8f91a429b4acd44f7415d2"
    var isCelcius : Bool = true
    var isError : Bool = false
    
    //TODO: Declare instance variables here
    let locationManager = CLLocationManager()
    let weatherDataModel = WeatherDataModel()
    var timer = Timer()
    
    //Pre-linked IBOutlets
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var weatherDescription: UILabel!
    @IBOutlet weak var currentTimeLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
    
        //TODO:Set up the location manager here.
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // Set up clock
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.liveTimer) , userInfo: nil, repeats: true)
    }

    @IBAction func switched(_ sender: UISwitch) {
        
        if !isError {
            if sender.isOn {
                changeToCelcius()
                isCelcius = true
            }
                
            else {
                changeToFahrenheit()
                isCelcius = false
            }
        }
    }
    
    
    //MARK: - Networking
    /***************************************************************/
    
    //Write the getWeatherData method here:
    
    func getWeatherData(url : String, parameters : [String: String]) {

        Alamofire.request(url, method: .get, parameters: parameters).responseJSON {
            response in
            if response.result.isSuccess {
                print("Success! Got the weather data")
                
                let weatherJSON : JSON = JSON(response.result.value!)
                self.updateWeatherData(json: weatherJSON)
            }
            else {
               print("Error \(response.result.error!)")
               self.cityLabel.text = "Connection Issues"
            }
        }
    }
    

    //MARK: - JSON Parsing
    /***************************************************************/
   
    
    //Write the updateWeatherData method here:
    
    func updateWeatherData(json : JSON) {
  
        if let tempResult = json["main"]["temp"].double {
 
            weatherDataModel.temperatureInCelcius = Int(tempResult - 273.15)
        
            weatherDataModel.temperatureInFahrenheit = Int((tempResult - 273.15)*(9/5) + 32)
            
            weatherDataModel.city = json["name"].stringValue
            
            weatherDataModel.country = json["sys"]["country"].stringValue
            
            weatherDataModel.description = json["weather"][0]["description"].stringValue
            
            weatherDataModel.condition = json["weather"][0]["id"].intValue
      
            weatherDataModel.weatherIconName = weatherDataModel.updateWeatherIcon(condition: weatherDataModel.condition)
            
            updateUIWithWeatherData()
            isError = false
        }
        
        else {
            cityLabel.text = "Weather Unavailable"
            updateUIForError()
            isError = true
        }
    }
    
    
    //MARK: - UI Updates
    /***************************************************************/
    
    
    //Write the updateUIWithWeatherData method here:
 
    func updateUIWithWeatherData() {

        cityLabel.text = weatherDataModel.city + ", " + weatherDataModel.country
        
        if isCelcius {
            changeToCelcius()
        }
            
        else {
            changeToFahrenheit()
        }
        
        weatherIcon.image = UIImage(named: weatherDataModel.weatherIconName)
        weatherDescription.text = weatherDataModel.description
    }

    
    //MARK: - Location Manager Delegate Methods
    /***************************************************************/
    
    
    //Write the didUpdateLocations method here:
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[locations.count - 1]
        if location.horizontalAccuracy > 0 {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            
            let latitude = String(location.coordinate.latitude)
            let longitude = String(location.coordinate.longitude)
            let params : [String : String] = ["lat" : latitude,
                                              "lon" : longitude,
                                              "appid" : APP_ID]
          
            getWeatherData(url: WEATHER_URL, parameters: params)
            isError = false
        }
    }
    
    //Write the didFailWithError method here:
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
        cityLabel.text = "Location Unavailable"
        updateUIForError()
        isError = true
    }
    
    //MARK: - Change City Delegate methods
    /***************************************************************/
    
    
    //Write the userEnteredANewCityName Delegate method here:
    
    func userEnteredANewCityName(city: String) {
        
        let params : [String : String] = ["q" : city, "appid" : APP_ID]
        getWeatherData(url: WEATHER_URL, parameters: params)
    }
    
    //Write the PrepareForSegue Method here
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "changeCityName" {
            
            let destinationVC = segue.destination as! ChangeCityViewController
            destinationVC.delegate = self
        }
    }
  
    func changeToCelcius() {
        temperatureLabel.text = String(weatherDataModel.temperatureInCelcius) + "℃"
    }
    
    func changeToFahrenheit() {
        temperatureLabel.text = String(weatherDataModel.temperatureInFahrenheit) + "℉"
    }
    
    func updateUIForError() {
        weatherIcon.image = UIImage(named: "errorImage")
        temperatureLabel.text = ""
        weatherDescription.text = ""
    }
    
    @objc func liveTimer() {
        currentTimeLabel.text = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium) + "\n" + DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none)
    }
}


