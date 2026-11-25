import SwiftUI

struct FestivalPhoto {
    let asset: String
    let credit: String
    let source: String
    let license: String
    let licenseURL: String

    static let catalog: [String: FestivalPhoto] = [
        "outside-lands": FestivalPhoto(asset: "festival-outside-lands", credit: "Steve", source: "https://commons.wikimedia.org/wiki/File:Outside_Lands_festival_crowd.jpg", license: "CC BY-SA 2.0", licenseURL: "https://creativecommons.org/licenses/by-sa/2.0"),
        "outside-lands-2027": FestivalPhoto(asset: "festival-outside-lands-2027", credit: "Alejandro De La Cruz", source: "https://commons.wikimedia.org/wiki/File:Windmills-_Outside_Lands.jpg", license: "CC BY 2.0", licenseURL: "https://creativecommons.org/licenses/by/2.0"),
        "lollapalooza": FestivalPhoto(asset: "festival-lollapalooza", credit: "Lacrossewi", source: "https://commons.wikimedia.org/wiki/File:Lollapalooza_Chicago_Skyline.jpg", license: "CC BY-SA 4.0", licenseURL: "https://creativecommons.org/licenses/by-sa/4.0"),
        "coachella": FestivalPhoto(asset: "festival-coachella", credit: "David Jones from Isle of Wight, United Kingdom", source: "https://commons.wikimedia.org/wiki/File:Coachella_2015_ferris_wheel_from_field.jpg", license: "CC BY 2.0", licenseURL: "https://creativecommons.org/licenses/by/2.0"),
        "coachella-2027": FestivalPhoto(asset: "festival-coachella-2027", credit: "Vision360media", source: "https://commons.wikimedia.org/wiki/File:Choura_Events_builds_Outdoor_tent_rental_for_large_music_festivals_and_Coachella.jpg", license: "CC BY-SA 4.0", licenseURL: "https://creativecommons.org/licenses/by-sa/4.0"),
        "bonnaroo": FestivalPhoto(asset: "festival-bonnaroo", credit: "Stab At Sleep from F L O R I D A, United States", source: "https://commons.wikimedia.org/wiki/File:Bonnaroo_What_Stage_(4704763599).jpg", license: "CC BY-SA 2.0", licenseURL: "https://creativecommons.org/licenses/by-sa/2.0")
    ]
}

enum FestivalRecommendation {
    // Demo recommendations accompany the existing sample friend activity.
    static func reason(for festival: WLFestival) -> String? {
        switch festival.id {
        case "outside-lands", "outside-lands-2027":
            "The wooded stages, local food, and room to wander between sets."
        case "lollapalooza":
            "A deep lineup in the middle of Chicago, with no camping required."
        case "coachella", "coachella-2027":
            "Big live productions and electronic sets after the desert cools down."
        case "bonnaroo":
            "Late-night sets and a campsite that becomes part of the weekend."
        default:
            nil
        }
    }
}

struct FestivalPhotoCredit: View {
    let photo: FestivalPhoto
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Archive photography").font(.subheadline.weight(.semibold))
            Text("From a previous edition; cropped to fit.")
                .font(.caption).foregroundStyle(JournalStyle.muted)
            if let source = URL(string: photo.source), let license = URL(string: photo.licenseURL) {
                Link("Photo: \(photo.credit)", destination: source)
                Link(photo.license, destination: license)
            }
        }.font(.caption)
    }
}
