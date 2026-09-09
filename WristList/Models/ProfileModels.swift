//
//  ProfileModels.swift
//  WristList
//

import Foundation

struct ProfileMetrics: Hashable {
    let festivalsRanked: Int
    let citiesVisited: Int
    let averageRating: Double
    let savedFestivals: Int
    let wantToAttend: Int

    static let empty = ProfileMetrics(
        festivalsRanked: 0,
        citiesVisited: 0,
        averageRating: 0,
        savedFestivals: 0,
        wantToAttend: 0
    )
}

struct TasteSignal: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let systemImage: String
    let palette: FestivalPalette
}

struct CityFestivalStat: Identifiable, Hashable {
    let id: String
    let city: String
    let count: Int
    let topFestivalName: String
    let palette: FestivalPalette
}

struct FriendFestivalMatch: Identifiable, Hashable {
    let id: String
    let name: String
    let initials: String
    let matchPercent: Int
    let sharedFavorites: String
    let palette: FestivalPalette
}
