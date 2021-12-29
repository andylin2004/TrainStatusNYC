//
//  ContentView.swift
//  service-alerts-swiftui
//
//  Created by Andy Lin on 2/18/21.
//

import SwiftUI
import WidgetKit


struct ContentView: View {
    @AppStorage("routesWithIssues", store: UserDefaults(suiteName: "group.com.andylin.service-alerts-swiftui"))
    var routesWithIssuesSaved: Data = Data()
    
    @State var thingToLoad: [TransitRealtime_FeedEntity]?
    @State var realTime: Dictionary<String, Dictionary<String, [Int64]>>?
    @State var stationPairs: Dictionary<String, String>? = [:]
    
    @State var selectedView = 0
    
    @ViewBuilder
    var body: some View {
        TabView(selection: $selectedView){
            NavigationView{
                List{
                    ForEach(thingToLoad ?? [], id: \.self){ thing in
                        let routes = thing.alert.informedEntity
                        VStack{
                            HStack{
                                ForEach(routes, id: \.self){ line in
                                    RouteShape(route: line.routeID, color: routeColors[line.routeID] ?? "#000000", size: 50)
                                }
                            }
                            Text(thing.alert.headerText.translation.first?.text.replacingOccurrences(of: "<br>", with: "\n").replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil).replacingOccurrences(of: "&#x2022;", with: "•").replacingOccurrences(of: "&nbsp;", with: "").replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression) ?? "")
                            Text(thing.alert.descriptionText.translation.first?.text.replacingOccurrences(of: "<br>", with: "\n").replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil).replacingOccurrences(of: "&#x2022;", with: "•").replacingOccurrences(of: "&nbsp;", with: "").replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression) ?? "")
                        }
                    }
                    .toolbar{
                        ToolbarItem(placement: .automatic){
                            Button(action: {serviceChangePull()}, label: {
                                Image(systemName: "arrow.clockwise")
                            })
                        }
                    }
                }
                .navigationBarTitle("Service Changes")
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .onAppear(perform: serviceChangePull)
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            .tag(0)
            
            NavigationView{
                let sortedKeys = realTime?.keys.sorted(by: <)
                List(){
                    ForEach(sortedKeys ?? [], id:\.self){ route in
                        let temp = realTime?[route]
                        NavigationLink(
                            destination:
                                ListView(entry: temp ?? ["":[0]], parent: route)
                            ){
                            Text(route)
                            }
                    }
                }
                .toolbar{
                    ToolbarItem(placement: .automatic){
                        Button(action: {countdownData()}, label: {
                            Image(systemName: "arrow.clockwise")
                        })
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationBarTitle("Countdown Clock")
                Text("Swipe right or press back to see countdown clock options")
                    .font(.title)
            }
            .onAppear(perform: {
                countdownData()
            })
            .tabItem {
                Image(systemName: "clock.fill")
                Text("Countdown Clock")
            }
            .tag(1)
        }
    }
    
    func serviceChangePull(){
        var routesWithIssuesUnsaved: [String] = []

        var request = URLRequest(url: URL(string: "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/camsys%2Fsubway-alerts")!)
        request.setValue("GrsrRlz7fL3vzMEU1iCmw9MulvuaWGGU78JKcIos", forHTTPHeaderField: "x-api-key")
            
            print(request)
            
            URLSession.shared.dataTask(with: request) { (data, _, _) in
                // custom type
                
                guard let response = try? TransitRealtime_FeedMessage(serializedData: data!) else {
                    // error
                    return
                }
//                    print(response)
//                    thingToLoad = response.entity
                
                guard let receivedFromJSON = try? TransitRealtime_FeedMessage(jsonUTF8Data: response.jsonUTF8Data()) else{
                    return
                }
                print(receivedFromJSON)
                thingToLoad = receivedFromJSON.entity
                var thing = 0
                for _ in 0..<thingToLoad!.endIndex{
                    let testString = thingToLoad?[thing].alert.headerText.translation.first?.text
                    if testString == "Weekday Service" || testString == "Weekend Service" || testString!.hasPrefix("Elevator outage")  {
                        thingToLoad?.remove(at: thing)
                        continue
                    }
                    if thing == thingToLoad?.count{
                        break
                    }
                    var dataPt = 0
                    for _ in 0..<thingToLoad![thing].alert.informedEntity.endIndex{
                        if thingToLoad![thing].alert.informedEntity[dataPt].routeID.count == 0 && thingToLoad![thing].alert.informedEntity.first?.routeID.count == 0{
                            thingToLoad![thing].alert.informedEntity[dataPt].routeID = thingToLoad![thing].alert.informedEntity[dataPt].trip.routeID.description
                        }
                        let route = thingToLoad![thing].alert.informedEntity[dataPt].routeID
                        if route.count != 1 && route != "GS" && route != "FS" && route != "SI"{
                            thingToLoad![thing].alert.informedEntity.remove(at: dataPt)
                            continue
                        }
                        switch route {
                        case "FS":
                            thingToLoad![thing].alert.informedEntity[dataPt].routeID = "SF"
                        case "GS":
                            thingToLoad![thing].alert.informedEntity[dataPt].routeID = "S"
                        case "SI":
                            thingToLoad![thing].alert.informedEntity[dataPt].routeID = "SIR"
                        default: break
                        }
                        routesWithIssuesUnsaved.append(thingToLoad![thing].alert.informedEntity[dataPt].routeID.description)
                        dataPt += 1
                        if dataPt == thingToLoad![thing].alert.informedEntity.count{
                            break
                        }
                    }
                    thing += 1
                }
                save(routesWithIssuesUnsaved)
            }.resume()
        WidgetCenter.shared.reloadTimelines(ofKind: "service_change_overall_widget")
    }
    
    func countdownData(){
        let data = readDataFromCSV(fileName: "Stations", fileType: "csv")
        for station in csv(data: data!){
            stationPairs!.updateValue(station[5], forKey: station[2])
        }
        
        var sortData: Dictionary<String, Dictionary<String, [Int64]>> = [:]
        let sources = ["https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-7", "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs", "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-si", "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-l", "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-nqrw", "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-jz", "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-g", "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-bdfm", "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-ace"]
        
        for source in sources{
            var request = URLRequest(url: URL(string: source)!)
                    request.setValue("GrsrRlz7fL3vzMEU1iCmw9MulvuaWGGU78JKcIos", forHTTPHeaderField: "x-api-key")
                
//                print(request)
                
                URLSession.shared.dataTask(with: request) { (data, _, _) in
                    // custom type
                    
                    guard let response = try? TransitRealtime_FeedMessage(serializedData: data!) else {
                        // error
                        return
                    }
//                    print(response)
                    
                    guard let receivedFromJSON = try? TransitRealtime_FeedMessage(jsonUTF8Data: response.jsonUTF8Data()) else{
                        return
                    }
//                    print(receivedFromJSON.entity)
                    for stop in receivedFromJSON.entity{
                        if sortData.index(forKey: stop.tripUpdate.trip.routeID) == nil{
                            sortData[stop.tripUpdate.trip.routeID] = [:]
                        }
                        for info in stop.tripUpdate.stopTimeUpdate{
                            var stopID = info.stopID
                            stopID.removeLast()
                            print(stationPairs?[stopID])
                            if sortData[stop.tripUpdate.trip.routeID]?.index(forKey: stationPairs?[stopID] ?? info.stopID) == nil{
                                sortData[stop.tripUpdate.trip.routeID]?[stationPairs?[stopID] ?? info.stopID] = []
                            }
                            
                            sortData[stop.tripUpdate.trip.routeID]?[stationPairs?[stopID] ?? info.stopID]?.append(info.arrival.time == 0 ? info.departure.time : info.arrival.time)
                        }
                    }
                    sortData.removeValue(forKey: "")
                    sortData.updateValue(sortData["FS"] ?? ["":[]], forKey: "SF")
                    sortData.removeValue(forKey: "FS")
                    sortData.updateValue(sortData["GS"] ?? ["":[]], forKey: "S")
                    sortData.removeValue(forKey: "GS")
                    realTime = sortData
                }.resume()
        }
        
    }
    
    func save(_ routesWithIssues: [String]){
        guard let routesWithIssuesSaved = try? JSONEncoder().encode(routesWithIssues) else {return}
        self.routesWithIssuesSaved = routesWithIssuesSaved
        print("saved \(routesWithIssues.description)")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
