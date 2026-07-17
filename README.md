# iOS Architecture & Design Patterns

A collection of small, focused Xcode projects demonstrating architecture patterns and design patterns used in production iOS apps.

Each folder is a standalone project you can open, run, and study on its own.

## What each project includes

Every project is built to the same standard, but not to the same shape. Early
examples share a common feature (a list, a detail screen, a network call) so the
architectures can be compared directly. Later ones deliberately break that mold.
Some are visionOS or watchOS only, some have no network layer at all, some are
built around a framework chosen specifically because the pattern has something
to say about it. 

What every project does share:

- A real feature with real constraints, not a to-do list.
- Unit tests for the core logic, and no test that touches the live network.
- A short README explaining the pattern, when to use it, and its tradeoffs.
- No third party dependencies unless the pattern specifically calls for one (for
  example, a Redux style project may use a lightweight state container library).
- A stated platform and UI framework, since those choices are part of the tradeoff.

## Project index

Every pattern and topic in the repository structure above, in one place. Items with a link are built. Everything else is planned and will be linked as it's added.

### Architecture

| Pattern | Description | Project |
|---|---|---|
| MVC | An iOS GitHub repository browser in UIKit: a list of a user's public repos backed by a diffable data source, a detail screen with stars, forks, language, and a relative updated line, pull to refresh, and an error alert with retry. | [GitHubBrowser-MVC](Architecture/mvc) |
| MVVM | An independent watchOS aurora forecast app on NOAA SWPC data: three days of Kp windows color coded by storm level, a detail screen per window, and a complication sharing the app's model layer. | [AuroraWatch-MVVM](Architecture/mvvm) |
| MVVM-C | A visionOS spatial Nine Men's Morris game on TabletopKit and RealityKit: a setup window, a board volume with all three game phases and mill capture, and an immersive space placing the board in three historical excavation sites. | [StoneMill-MVVMC](Architecture/mvvm-c) |
| MVP | An iOS 27 Document App using UIKit...Add more later | [ChangeRinger-MVP](Architecture/mvp) |
| VIPER | Splits a screen into View, Interactor, Presenter, Entity, and Router | Not yet added |
| Clean Swift (VIP) | Clean Architecture adapted for iOS with a unidirectional VIP cycle | Not yet added |
| Redux / TCA style | Centralized, predictable state management for complex screens | Not yet added |

### Concurrency

| Topic | Description | Project |
|---|---|---|
| Async/await | Structured concurrency for networking and background work | Not yet added |
| Combine | Reactive streams for handling asynchronous events over time | Not yet added |
| Actors | Data race safe state isolation using Swift's actor model | Not yet added |

### Design patterns

**Creational**

| Pattern | Description | Project |
|---|---|---|
| Factory | Delegates object creation to a dedicated type instead of calling the initializer directly | Not yet added |
| Builder | Constructs a complex object step by step | Not yet added |
| Singleton | Restricts a type to a single shared instance | Not yet added |
| Dependency injection | Supplies a type's dependencies from outside instead of creating them internally | Not yet added |

**Structural**

| Pattern | Description | Project |
|---|---|---|
| Adapter | Converts one interface into another that the rest of the app expects | Not yet added |
| Facade | Provides a simple interface over a more complex subsystem | Not yet added |
| Decorator | Adds behavior to an object without modifying its original type | Not yet added |
| Repository | Abstracts data access behind a single, consistent interface | Not yet added |

**Behavioral**

| Pattern | Description | Project |
|---|---|---|
| Observer | Notifies interested objects when state changes | Not yet added |
| Strategy | Swaps an algorithm's implementation at runtime behind a shared interface | Not yet added |
| Coordinator | Extracts navigation logic out of view controllers into a dedicated object | Not yet added |
| State machine | Models a screen or flow as a fixed set of states and transitions | Not yet added |
| Command | Wraps a request or action as an object that can be queued or undone | Not yet added |

### Modularization

| Topic | Description | Project |
|---|---|---|
| Swift Package modules | Splitting an app into local Swift Packages for build speed and boundaries | Not yet added |
| Feature flags | Toggling features on and off without shipping a new build | Not yet added |

### Navigating and routing with SwiftUI

| Topic | Description | Project |
|---|---|---|
| NavigationLink | The default, view driven way to push screens in SwiftUI | Not yet added |
| Dynamic navigation | Driving navigation from state instead of hardcoded links | Not yet added |
| Centralized navigation | A single router or path object owning navigation for a flow | Not yet added |
| Combined tab and stack | Managing navigation stacks nested inside tabs | Not yet added |
| Deep linking | Routing a URL or notification straight to a specific screen | Not yet added |

### Protocols

| Topic | Description | Project |
|---|---|---|
| Protocol-oriented programming | Building shared behavior with protocols and extensions instead of inheritance | Not yet added |

### Testing

| Topic | Description | Project |
|---|---|---|
| Snapshot testing | Catching unintended UI changes by comparing rendered views against a reference image | Not yet added |
| UI testing | End to end testing through `XCUIApplication` | Not yet added |

## Design patterns covered

Grouped using the classic creational, structural, and behavioral categories, plus an iOS specific concurrency section since async/await and Combine come up constantly in real codebases.

Some projects use SwiftUI, others use UIKit, and a few show both side by side for comparison. Each project README states which UI framework it uses.

## How to use this repository

1. Pick a pattern from the project index above or browse the folders directly
2. Open the `.xcodeproj` or `.xcworkspace` inside that folder
3. Read the local README first, it covers the reasoning before you read code
4. Run the tests to see how the pattern affects testability

## License

Released under the [MIT License](LICENSE). © 2026 SarahUniverse
