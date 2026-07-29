//
//  OnboardingViewModel.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// The pages and button titles the onboarding flow renders.
struct OnboardingViewModel: Equatable {

    struct Page: Equatable, Identifiable {
        let id: Int
        let title: String
        let body: String
        let systemImage: String
    }

    let pages: [Page]
    /// The continue button title on any page but the last.
    let continueTitle: String
    /// The continue button title on the last page.
    let lastPageTitle: String
    let skipTitle: String
}
