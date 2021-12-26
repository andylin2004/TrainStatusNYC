//
//  memes.swift
//  service-alerts-swiftui
//
//  Created by Andy Lin on 2/20/21.
//

import SwiftUI

struct ListView: View {
    @State var entry: Dictionary<String, [Int64]>
    @State var parent: String
    
    let timezoneOffset =  TimeZone.current.secondsFromGMT()
    
    var body: some View {
        List(){
            ForEach(entry.keys.sorted(by: <), id:\.self){ thing in
                NavigationLink(destination: List(){
                    ForEach(entry[thing] ?? [], id:\.self){ time in
                        Text( Date(timeIntervalSince1970:  TimeInterval(Int(time) + timezoneOffset)).description)
                    }
                }
                .navigationTitle(thing)
                ){
                    Text(thing)
                }
            }
        }
        .navigationTitle(parent)
    }
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView(entry: ["oof":[69,70]], parent: "1")
    }
}
