<div align="center">
  <img src="Screenshots/AppIcon.png" width="300" style="border: 3px solid white; border-radius: 15px; vertical-align: middle; margin-right: 20px;">
  <h1 style="display: inline-block; vertical-align: middle;">AuroraWatch-MVVM</h1>
</div>

# MVVM (Model-View-ViewModel)
 
The Model-View-ViewModel pattern as it is actually written in modern SwiftUI, using `@Observable` and structured concurrency. Built as an independent watchOS app.
 
## MVVM explained
 
- MVVM splits the app in three roles: `Model`, `View`, and `ViewModel`.
- The `Model` holds the app's data and the rules that data obeys. It knows nothing about the UI and nothing about the screen it will end up on.
- The `View` is a declarative description of the UI for a given state. It owns no logic beyond layout and reading state.
- The `ViewModel` sits between the two. It owns the state of one screen, talks to the model layer, and exposes properties the view can render directly with no branching or computation left to do.
- The key difference from MVC: the `ViewModel` has no reference to the `View`. In MVC the controller reaches out and mutates the view. In MVVM the view model only mutates its own properties, and the view re-renders itself because it was observing those properties.
- That inversion is the whole point. Because nothing in the view model refers to a view, a view model can be created, driven, and asserted against in a plain test with no window, no host controller, and no rendering.
- Communication flows one direction at a time: the `View` calls a method on the `ViewModel`, the `ViewModel` asks the `Model` for data, the `ViewModel` updates its own state, and the observation system re-invalidates the `View`.
- The `Model` and the `View` NEVER directly talk to each other, same as MVC.
- SwiftUI's Observation framework (`@Observable`, `@State`, `@Bindable`) is built around this pattern, which is why MVVM is the default starting point for most SwiftUI apps the way MVC is for UIKit.
