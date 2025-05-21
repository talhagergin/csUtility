// DataSeeder.swift (veya AppModelContainer.swift içinde, actor dışında)
import Foundation
import SwiftData // ModelContext ve Modeller için

// JSON'dan lineup verilerini okumak için kullanılacak struct (Bu zaten vardı)
struct SeedLineup: Decodable {
    let id: String?
    let title: String
    let youtubeURL: String
    let mapName: String
    let utilityTypeRawValue: String
    let category: String?
    let uploadedDate: Date
    let uploaderID: String?
}

// JSON'dan takım sıralama verilerini okumak için struct'lar (Bunlar da vardı)
struct SeedPlayerInfo: Decodable {
    let id: String?
    let playerName: String
    let countryCode: String
}

struct SeedTeamRanking: Decodable {
    let id: String?
    let rank: Int
    let teamName: String
    let points: Int
    let logoName: String?
    let rankChange: Int?
    let lastUpdated: Date
    let players: [PlayerInfo] // PlayerInfo zaten Codable, direkt kullanabiliriz
}


// Ana veri yükleme fonksiyonu (Bu da vardı ve doğruydu)
@MainActor
func seedInitialData(modelContext: ModelContext) {
    // 1. Başlangıç Lineup Verilerini Yükleme
    let lineupSeedFlag = "didSeedInitialLineups_v1.1" // Versiyonu güncelleyebiliriz
    if !UserDefaults.standard.bool(forKey: lineupSeedFlag) {
        print("Attempting to seed initial lineups...")
        loadLineupsFromJSON(context: modelContext) // BURADA ÇAĞRILIYOR
        UserDefaults.standard.set(true, forKey: lineupSeedFlag)
        print("Initial lineups seeding process finished.")
    } else {
        print("Initial lineups already seeded or lineup seeding flag is set.")
    }

    // 2. Başlangıç Sıralama Verilerini Yükleme
    let rankingSeedFlag = "didSeedInitialRankings_v1.1" // Versiyonu güncelleyebiliriz
    if !UserDefaults.standard.bool(forKey: rankingSeedFlag) {
        print("Attempting to seed initial rankings...")
        loadRankingsFromJSON(context: modelContext)
        UserDefaults.standard.set(true, forKey: rankingSeedFlag)
        print("Initial rankings seeding process finished.")
    } else {
        print("Initial rankings already seeded or ranking seeding flag is set.")
    }
}


// --- YENİ ve GÜNCEL loadLineupsFromJSON FONKSİYONU ---
@MainActor
private func loadLineupsFromJSON(context: ModelContext) {
    guard let url = Bundle.main.url(forResource: "lineups", withExtension: "json") else {
        print("ERROR: lineups.json not found in bundle.")
        return
    }

    do {
        let data = try Data(contentsOf: url)
        
        let decoder = JSONDecoder()
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime] // JSON'daki "YYYY-MM-DDTHH:MM:SSZ" formatına uygun

        // Özel tarih decode stratejisi (daha sağlam)
        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            // Fallback veya hata (Bu kısmı bir önceki mesajda detaylandırmıştık)
            fatalError("FATAL ERROR: Could not parse date string '\(dateString)' from lineups.json. Check format.")
        })
        
        let seedLineupsArray = try decoder.decode([SeedLineup].self, from: data)
        var countAdded = 0

        for seedItem in seedLineupsArray {
            let lineupUUID: UUID
            if let idString = seedItem.id, !idString.isEmpty, let uuid = UUID(uuidString: idString) {
                lineupUUID = uuid
            } else {
                lineupUUID = UUID() // JSON'da ID yoksa veya geçersizse yeni ID
                if let idStr = seedItem.id, !idStr.isEmpty { // Eğer ID vardı ama geçersizdi ise uyar
                     print("Warning: Invalid UUID string '\(idStr)' in lineups.json for title '\(seedItem.title)'. Generating new UUID.")
                }
            }

            // ID ile varlık kontrolü
            let existingVideoDescriptor = FetchDescriptor<LineupVideo>(predicate: #Predicate { $0.id == lineupUUID })
            
            if try context.fetchCount(existingVideoDescriptor) == 0 {
                // Enum'ları rawValue'lardan oluştur
                guard let map = CSMap(rawValue: seedItem.mapName) else {
                    print("ERROR: Invalid mapName '\(seedItem.mapName)' in lineups.json for title '\(seedItem.title)'. Skipping.")
                    continue
                }
                guard let utility = UtilityType(rawValue: seedItem.utilityTypeRawValue) else {
                    print("ERROR: Invalid utilityTypeRawValue '\(seedItem.utilityTypeRawValue)' in lineups.json for title '\(seedItem.title)'. Skipping.")
                    continue
                }
                
                var categoryStringValue: String? = nil
                if let categoryFromJson = seedItem.category, !categoryFromJson.isEmpty {
                    // LineupCategory enum'ına çevirmeyi deneyelim, eğer yoksa direkt string olarak saklayalım
                    // Veya sadece enum'da olanları kabul edip, olmayanlar için uyarı verip nil/Genel atayalım
                    if LineupCategory(rawValue: categoryFromJson) != nil {
                        categoryStringValue = categoryFromJson // Enum'da varsa rawValue'sunu kullan
                    } else {
                        print("Warning: Category '\(categoryFromJson)' from lineups.json for title '\(seedItem.title)' is not in LineupCategory enum. Storing as string or consider adding to enum. Defaulting to 'Genel' or nil if desired.")
                        categoryStringValue = LineupCategory.general.rawValue // Veya direkt seedItem.category olarak sakla
                    }
                } else {
                     // JSON'da kategori yoksa veya boşsa LineupCategory.general.rawValue atanabilir.
                     // LineupVideo init'i category: String? aldığı için nil de olabilir.
                     categoryStringValue = LineupCategory.general.rawValue
                }

                let newLineup = LineupVideo(
                    id: lineupUUID,
                    title: seedItem.title,
                    youtubeURL: seedItem.youtubeURL,
                    mapName: map.rawValue,      // Doğru: CSMap enum'dan rawValue
                    utilityType: utility,     // Doğru: LineupVideo init'i UtilityType alıyor
                    category: categoryStringValue, // Doğru: LineupVideo init'i String? alıyor
                    uploadedDate: seedItem.uploadedDate,
                    uploaderID: seedItem.uploaderID ?? "app_seed"
                )
                context.insert(newLineup)
                countAdded += 1
            }
        }
        
        if countAdded > 0 {
            print("Successfully added \(countAdded) new lineups from lineups.json.")
        } else if !seedLineupsArray.isEmpty {
            print("All lineups from lineups.json already exist in the database.")
        } else {
            print("No lineups found in lineups.json to process.")
        }

    } catch {
        print("ERROR loading or parsing lineups.json: \(error.localizedDescription)")
        if let decodingError = error as? DecodingError {
            handleDecodingError(decodingError) // Bu yardımcı fonksiyon tanımlı olmalı
        }
    }
}


// --- TAKIM SIRALAMALARI İÇİN FONKSİYON (Bu zaten vardı ve doğruydu) ---
@MainActor
private func loadRankingsFromJSON(context: ModelContext) {
    guard let url = Bundle.main.url(forResource: "rankings", withExtension: "json") else {
        print("Error: rankings.json not found in bundle.")
        return
    }

    do {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        
        // --- DÜZELTME BURADA ---
        // ISO8601DateFormatter'ı custom strategy ile kullanacağız
        let isoDateFormatter = ISO8601DateFormatter()
        // JSON'daki tarih formatınıza uygun seçenekleri belirleyin
        // Örneğin: "2025-05-19T10:00:00Z"
        isoDateFormatter.formatOptions = [.withInternetDateTime]
        // Eğer milisaniye varsa: isoDateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = isoDateFormatter.date(from: dateString) {
                return date
            }
            // Fallback veya hata yönetimi
            // Alternatif bir DateFormatter da deneyebilirsiniz veya direkt hata fırlatabilirsiniz
            // Örneğin, eğer bazen "Z" olmadan tarihler geliyorsa:
            let alternativeFormatter = DateFormatter()
            alternativeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss" // "Z" olmadan
            alternativeFormatter.timeZone = TimeZone(secondsFromGMT: 0) // Eğer gelen tarih UTC ise
            if let date = alternativeFormatter.date(from: dateString) {
                 print("Warning: Used alternative date parsing for '\(dateString)' in rankings.json.")
                 return date
            }
            
            fatalError("FATAL ERROR: Could not parse date string '\(dateString)' from rankings.json. Check format and DateFormatters.")
        })
        // --- DÜZELTME SONU ---

        let seedRankingsArray = try decoder.decode([SeedTeamRanking].self, from: data)
        var countAdded = 0

        for seedItem in seedRankingsArray {
            let teamUUID: UUID
            if let idString = seedItem.id, !idString.isEmpty, let uuid = UUID(uuidString: idString) {
                teamUUID = uuid
            } else {
                teamUUID = UUID()
                 if let idStr = seedItem.id, !idStr.isEmpty {
                     print("Warning: Invalid UUID string '\(idStr)' in rankings.json for team '\(seedItem.teamName)'. Generating new UUID.")
                }
            }

            let existingTeamDescriptor = FetchDescriptor<TeamRanking>(predicate: #Predicate { $0.id == teamUUID })
            if try context.fetchCount(existingTeamDescriptor) == 0 {
                let newTeamRanking = TeamRanking(
                    id: teamUUID,
                    rank: seedItem.rank,
                    teamName: seedItem.teamName,
                    points: seedItem.points,
                    players: seedItem.players,
                    logoName: seedItem.logoName,
                    rankChange: seedItem.rankChange,
                    lastUpdated: seedItem.lastUpdated
                )
                context.insert(newTeamRanking)
                countAdded += 1
            }
        }
        if countAdded > 0 {
            print("Successfully added \(countAdded) new team rankings from rankings.json.")
        } else if !seedRankingsArray.isEmpty {
            print("All team rankings from rankings.json already exist in the database.")
        } else {
            print("No team rankings found in rankings.json to process.")
        }

    } catch {
        print("ERROR loading or parsing rankings.json: \(error.localizedDescription)")
        if let decodingError = error as? DecodingError {
            handleDecodingError(decodingError) // Bu fonksiyon tanımlı olmalı
        }
    }
}

// Hata ayıklama için yardımcı fonksiyon (Bu da vardı)
private func handleDecodingError(_ error: DecodingError) {
    switch error {
    case .typeMismatch(let type, let context):
        print("Type mismatch for type \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)")
    case .valueNotFound(let type, let context):
        print("Value not found for type \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)")
    case .keyNotFound(let key, let context):
        print("Key not found: \(key.stringValue) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)")
    case .dataCorrupted(let context):
        print("Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)")
    @unknown default:
        print("Unknown decoding error: \(error.localizedDescription)")
    }
}
