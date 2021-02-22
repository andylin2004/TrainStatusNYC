//
//  RouteShape.swift
//  service-alerts-swiftui
//
//  Created by Andy Lin on 2/19/21.
//

import SwiftUI

struct RouteShape: View {
    let route: String
    let color: String
    let size: CGFloat
    var body: some View {
        Text(route)
            .fontWeight(.bold)
            .font(.system(size: (route == "SIR" && size <= 20) ? size*0.5 : size*0.6))
            .frame(width: size, height: size)
            .background(Color(UIColor(hex: color+"FF") ?? UIColor.black))
            .foregroundColor(.white)
            .clipShape(Circle())
    }
}

struct RouteShape_Previews: PreviewProvider {
    static var previews: some View {
        RouteShape(route: "E", color: "#FF6319", size: 20)
    }
}

extension UIColor {
    public convenience init?(hex: String) {
        let r, g, b, a: CGFloat

        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255

                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }

        return nil
    }
}
