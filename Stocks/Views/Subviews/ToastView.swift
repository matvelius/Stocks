//
//  ToastView.swift
//  Stocks
//
//  Courtesy of Ondrej Kvasnovsky's "How to build a simple toast message view in SwiftUI" article:
//  https://ondrej-kvasnovsky.medium.com/how-to-build-a-simple-toast-message-view-in-swiftui-b2e982340bd
//  (with tiny modifications from me)

import SwiftUI

struct ToastView: View {
    var style: ToastStyle
    var message: String
    var width = CGFloat.infinity
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
            
            Text(message)
                .fontWeight(.medium)
                .foregroundColor(Color.white)
            .padding(11)
        }
        .padding()
        .frame(minWidth: 0, maxWidth: width)
        .frame(maxHeight: 120)
        .cornerRadius(11)
        .padding(.horizontal, 16)
    }
}

struct ToastModifier: ViewModifier {
    
    @Binding var toast: Toast?
    @State private var workItem: DispatchWorkItem?
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                ZStack {
                    mainToastView()
                        .offset(y: 32)
                }.animation(.spring(), value: toast)
            )
            .onChange(of: toast, { _, _ in
                showToast()
            })
    }
    
    @ViewBuilder func mainToastView() -> some View {
        if let toast = toast {
            VStack {
                ToastView(style: toast.style,
                          message: toast.message,
                          width: toast.width)
                Spacer()
            }
            .padding()
        }
    }
    
    private func showToast() {
        guard let toast = toast else { return }
        
        UIImpactFeedbackGenerator(style: .light)
            .impactOccurred()
        
        if toast.duration > 0 {
            workItem?.cancel()
            
            let task = DispatchWorkItem {
                dismissToast()
            }
            
            workItem = task
            DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration, execute: task)
        }
    }
    
    private func dismissToast() {
        withAnimation {
            toast = nil
        }
        
        workItem?.cancel()
        workItem = nil
    }
}

extension View {
    
    func toastView(toast: Binding<Toast?>) -> some View {
        self.modifier(ToastModifier(toast: toast))
    }
}

struct Toast: Equatable {
    var style: ToastStyle
    var message: String
    var duration: Double = 5
    var width: Double = .infinity
}

enum ToastStyle {
    case error
    case warning
    case success
    case info
}

extension ToastStyle {
    var themeColor: Color {
        switch self {
        case .error: return Color.red
        case .warning: return Color.orange
        case .info: return Color.blue
        case .success: return Color.green
        }
    }
    
    var iconFileName: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
}

#Preview {
    ToastView(style: .error, message: "You've exceeded the maximum requests per minute, please wait or upgrade your subscription to continue.")
}
