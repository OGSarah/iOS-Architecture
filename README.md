# iOS Architecture & Design Patterns

A collection of small, focused Xcode projects demonstrating architecture patterns and design patterns used in production iOS apps. 

Each folder is a standalone project you can open, run, and study on its own.

## Repository structure

```
ios-architecture-patterns/
  Architecture/
    mvc/
    mvvm/
    mvvm-c/
    mvp/
    viper/
    clean-swift-vip/
    redux-tca/
  Design-patterns/
      Behavioral/
        command/
        coordinator/
        observer/
        state-machine/
        strategy/
      Creational/
        builder/
        dependency-injection/
        factory/
        singleton/
      Structural/
        adapter/
        decorator/
        facade/
        repository/
  Concurrency/
    actors/
    async-await/
    combine/
  Modularization/
    feature-flags/
    swift-package-modules/
  Navigating and Routing with SwiftUI/
    Centralized Navigation/
    Combined Tab and Stack/
    Deep Linking/
    Dynamic Navigation/
    NavigationLink/
  Testing/
    snapshot-testing/
    ui-testing/
  README.md
```

## What each project includes

Every example follows the same baseline so comparisons are fair:

- A small but realistic feature, usually a list screen, a detail screen, and a network call
- Unit tests for the core logic
- A short README explaining the pattern, when to use it, and its tradeoffs
- No third party dependencies unless the pattern specifically calls for one (for example, a Redux style project may use a lightweight state container library)

## Architecture patterns covered

| Pattern | Folder | Best suited for |
|---|---|---|
| MVC | `architecture/mvc` | Small screens, quick prototypes |
| MVVM | `architecture/mvvm` | SwiftUI apps, testable view logic |
| MVVM-C | `architecture/mvvm-c` | MVVM plus decoupled navigation |
| MVP | `architecture/mvp` | UIKit apps needing strict separation |
| VIPER | `architecture/viper` | Large teams, strict module boundaries |
| Clean Swift (VIP) | `architecture/clean-swift-vip` | Enterprise apps, heavy business logic |
| Redux / TCA style | `architecture/redux-tca` | Complex state, predictable data flow |

## Design patterns covered

Grouped using the classic creational, structural, and behavioral categories, plus an iOS specific concurrency section since async/await and Combine come up constantly in real codebases.

Some projects use SwiftUI, others use UIKit, and a few show both side by side for comparison. Each project README states which UI framework it uses.

## How to use this repository

1. Pick a pattern from the table above or browse the folders directly
2. Open the `.xcodeproj` or `.xcworkspace` inside that folder
3. Read the local README first, it covers the reasoning before you read code
4. Run the tests to see how the pattern affects testability

## License

Released under the [MIT License](LICENSE). © 2026 SarahUniverse
