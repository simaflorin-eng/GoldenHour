//
//  GoldenHourTests.swift
//  GoldenHourTests
//
//  Created by Florin Sima on 15.03.2026.
//

import XCTest
@testable import GoldenHour

final class GoldenHourTests: XCTestCase {
    @MainActor
    func testDailyScheduleKeepsAfternoonUntilThirtyMinutesBeforeSunset() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let wake = calendar.date(from: DateComponents(year: 2026, month: 3, day: 18, hour: 7, minute: 49))!
        let sunset = calendar.date(from: DateComponents(year: 2026, month: 3, day: 18, hour: 19, minute: 49))!

        let schedule = HealthKitManager.makeDailySchedule(wake: wake, sunset: sunset)

        XCTAssertEqual(schedule.caffeineCutoff, calendar.date(from: DateComponents(year: 2026, month: 3, day: 18, hour: 15, minute: 49))!)
        XCTAssertEqual(schedule.afternoonStart, schedule.caffeineCutoff)
        XCTAssertEqual(schedule.afternoonEnd, calendar.date(from: DateComponents(year: 2026, month: 3, day: 18, hour: 19, minute: 19))!)
        XCTAssertEqual(schedule.sunsetStart, schedule.afternoonEnd)
        XCTAssertEqual(schedule.sunsetEnd, sunset)
    }

    @MainActor
    func testDailyScheduleCollapsesAfternoonWhenCaffeineCutoffIsInsideSunsetWindow() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let wake = calendar.date(from: DateComponents(year: 2026, month: 3, day: 18, hour: 11, minute: 49))!
        let sunset = calendar.date(from: DateComponents(year: 2026, month: 3, day: 18, hour: 19, minute: 49))!

        let schedule = HealthKitManager.makeDailySchedule(wake: wake, sunset: sunset)

        XCTAssertEqual(schedule.caffeineCutoff, calendar.date(from: DateComponents(year: 2026, month: 3, day: 18, hour: 19, minute: 49))!)
        XCTAssertEqual(schedule.afternoonStart, schedule.afternoonEnd)
        XCTAssertEqual(schedule.sunsetStart, schedule.sunsetEnd)
    }
}
