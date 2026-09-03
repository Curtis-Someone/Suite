import Foundation
import SwiftData

/// Open-Meteo (free, no key). Geocodes the destination, fetches the daily
/// forecast for the trip dates, caches it as `WeatherDay` rows on the trip.
/// Basic conditions only — smart packing suggestions are Pro (batch 10).
enum WeatherService {

    /// Fetches + caches if the trip has a destination, dates within Open-Meteo's
    /// 16-day forecast window, and no fresh cache (< 6h old).
    static func refresh(for trip: Trip, in context: ModelContext) async {
        guard !trip.destinationCountryCode.isEmpty else { return }
        if let newest = trip.weatherDays.map(\.fetchedAt).max(),
           Date.now.timeIntervalSince(newest) < 6 * 3600 { return }

        let place = trip.destinationCity.isEmpty ? trip.destinationCountry : trip.destinationCity
        guard let coord = try? await geocode(place, countryCode: trip.destinationCountryCode),
              let days = try? await forecast(coord: coord, from: trip.startDate, to: trip.endDate)
        else { return }

        for day in trip.weatherDays { context.delete(day) }
        for d in days {
            let wd = WeatherDay(date: d.date, highTemp: d.high, lowTemp: d.low,
                                precipitationChance: d.precip, conditionCode: d.code, trip: trip)
            context.insert(wd)
        }
        try? context.save()
    }

    /// Lucide asset name for an Open-Meteo WMO weather code.
    static func iconName(for code: Int) -> String {
        switch code {
        case 0:            return "sun"
        case 1, 2:         return "cloud-sun-rain"
        case 3:            return "cloud"
        case 45, 48:       return "cloud"
        case 51...67, 80...82: return "cloud-rain"
        case 71...77, 85, 86:  return "cloud-snow"
        case 95...99:      return "cloud-rain"
        default:           return "cloud"
        }
    }

    // MARK: - API

    private struct Coord { let lat: Double; let lon: Double }
    private struct DayForecast { let date: Date; let high: Double; let low: Double; let precip: Double; let code: Int }

    private static func geocode(_ name: String, countryCode: String) async throws -> Coord? {
        var comps = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        comps.queryItems = [.init(name: "name", value: name), .init(name: "count", value: "10")]
        let (data, _) = try await URLSession.shared.data(from: comps.url!)
        struct Response: Decodable {
            struct Result: Decodable { let latitude: Double; let longitude: Double; let country_code: String? }
            let results: [Result]?
        }
        let results = (try JSONDecoder().decode(Response.self, from: data)).results ?? []
        let match = results.first { $0.country_code?.uppercased() == countryCode.uppercased() } ?? results.first
        return match.map { Coord(lat: $0.latitude, lon: $0.longitude) }
    }

    private static func forecast(coord: Coord, from: Date, to: Date) async throws -> [DayForecast] {
        // Open-Meteo forecasts ~16 days out. Clamp to what's available.
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let maxDate = cal.date(byAdding: .day, value: 15, to: today)!
        let start = max(from, today), end = min(to, maxDate)
        guard start <= end else { return [] }

        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"; df.timeZone = .init(identifier: "UTC")
        var comps = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        comps.queryItems = [
            .init(name: "latitude", value: String(coord.lat)),
            .init(name: "longitude", value: String(coord.lon)),
            .init(name: "daily", value: "temperature_2m_max,temperature_2m_min,precipitation_probability_max,weathercode"),
            .init(name: "timezone", value: "UTC"),
            .init(name: "start_date", value: df.string(from: start)),
            .init(name: "end_date", value: df.string(from: end)),
        ]
        let (data, _) = try await URLSession.shared.data(from: comps.url!)
        struct Response: Decodable {
            struct Daily: Decodable {
                let time: [String]
                let temperature_2m_max: [Double]
                let temperature_2m_min: [Double]
                let precipitation_probability_max: [Double?]
                let weathercode: [Int]
            }
            let daily: Daily
        }
        let daily = (try JSONDecoder().decode(Response.self, from: data)).daily
        return daily.time.indices.map { i in
            DayForecast(
                date: df.date(from: daily.time[i]) ?? from,
                high: daily.temperature_2m_max[i],
                low: daily.temperature_2m_min[i],
                precip: (daily.precipitation_probability_max[i] ?? 0) / 100,
                code: daily.weathercode[i]
            )
        }
    }
}
