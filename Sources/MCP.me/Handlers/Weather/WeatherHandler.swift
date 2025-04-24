//
//  Weather.swift
//  DemoMCP
//
//  Created by Steven Prichard on 2025-04-07.
//

import SwiftMCP
import Foundation

@MCPServer(name: "US Weather")
package actor WeatherHandler {
    let weatherClient = WeatherAPI()

    /// Provides the current weather forecast for a provided latitude and longitude
    /// Example: Mesa, Arizona - Latitude: 33.415184, Longitude: -111.831474
    /// - Parameters:
    ///   - latitude: A double representing a geographic coordinate that specifies a location's north-south position on Earth
    ///   - longitude: A double representing a geographic coordinate that specifies a location's east-west position on Earth
    /// - Returns: Returns the forecast for the provided latitude & longitude
    @MCPTool
    func forecast(latitude: Double, longitude: Double) async -> String {
        do {
            return try await weatherClient.getForecast(latitude: latitude, longitude: longitude)
        } catch {
            fputs("ERROR: \(error.localizedDescription)", stderr)
            return "Unable to get forecast"
        }
    }
}

