//
//  ContentView.swift
//  Pannotate-iOS
//
//  Created by DavidWoo on 4/24/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasCompletedAuthWelcome") private var hasCompletedAuthWelcome = false
    @AppStorage("authMode") private var authModeRawValue = AuthMode.guest.rawValue

    var body: some View {
        Group {
            if hasCompletedOnboarding && hasCompletedAuthWelcome == false {
                AuthWelcomeView { mode in
                    authModeRawValue = mode.rawValue
                    hasCompletedAuthWelcome = true
                }
            } else {
                RootTabView()
                    .fullScreenCover(isPresented: onboardingPresentationBinding) {
                        OnboardingGuideView {
                            hasCompletedOnboarding = true
                        }
                    }
            }
        }
    }

    private var onboardingPresentationBinding: Binding<Bool> {
        Binding {
            hasCompletedOnboarding == false
        } set: { isPresented in
            if isPresented == false {
                hasCompletedOnboarding = true
            }
        }
    }
}

#Preview {
    ContentView()
}
