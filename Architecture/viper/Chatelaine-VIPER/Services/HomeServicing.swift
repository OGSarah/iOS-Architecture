//
//  HomeServicing.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// The full set of store capabilities the module builders wire together.
///
/// Builders depend on this composition rather than on the concrete `HomeStore`, which is what lets a
/// DEBUG build substitute a `ScriptedHomeStore` for UI tests without any module knowing the
/// difference. Interactors and routers still depend only on the narrow protocol they need.
@MainActor
protocol HomeServicing: HomeStoreProviding, CharacteristicWriting, NotificationPolicy, TriggerReading, TriggerWriting {}

extension HomeStore: HomeServicing {}
