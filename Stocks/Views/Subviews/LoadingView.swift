//
//  LoadingView.swift
//  Stocks
//
//  Courtesy of Simon Ng:
//  https://www.appcoda.com/swiftui-animation-basics-building-a-loading-indicator/

import Foundation
import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack {
            Spacer()
            ZStack {
//                Text("Loading")
//                    .font(.system(.body, design: .rounded))
//                    .bold()
//                    .offset(x: 0, y: -25)
//                    .opacity(isAnimating ? 1.0 : 0.5)
//                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color(.systemGray5), lineWidth: 3)
                    .frame(width: 250, height: 3)
                
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.green, lineWidth: 3)
                    .frame(width: 30, height: 3)
                    .offset(x: isAnimating ? 110 : -110, y: 0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
            }
            Spacer()
        }
        
        .onAppear {
            withAnimation {
                isAnimating.toggle()
            }
        }
    }
}
