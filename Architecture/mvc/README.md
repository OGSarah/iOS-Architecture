<div align="center">
  <img src="Screenshots/AppIcon.png" width="300" style="border: 3px solid white; border-radius: 15px; vertical-align: middle; margin-right: 20px;">
  <h1 style="display: inline-block; vertical-align: middle;">GitHubBrowser-MVC</h1>
</div>

# MVC (Model-View-Controller)

The classic Apple flavored MVC pattern, sometimes called Cocoa MVC. Built with UIKit.
 
## MVC explained
- MVC splits the app in three roles: `Model`, `View`, and `Controller`.
- The `Model` holds the app's data and the logic for fetching, decoding, and validating it. It knows nothing about the UI.
- The `View` displays whatever data it is given. It has no knowledge of the network or business logic.
- The `Controller` sits between the two. It asks the model for data and updates the `View` when that data changes.
- On iOS, the `UIViewController` plays the role of the Controller and also manages part of the view hierarchy, which is different from the original desktop MVC pattern.
- Communication flows one direction at a time: the `Controller` talks to the `Model`, the Controller updates the `View`, and the `View` reports user actions back to the Controller through target-action or delation.
- The `Model` and `View` NEVER directly talk to each other.
- Apple's frameworks (UIKit, Storyboards, `IBOutlet`, `IBAction`) are built around this pattern, which is why it is the default starting point for most iOS apps.

## What this project does

A small GitHub repository browser:
 
- A list screen that fetches and displays a user's public repositories
- A detail screen showing repository stats (stars, forks, description, language)
- Pull to refresh and basic error handling with a retry option
- Unit tests around the model layer

## Project structure
 
```
Models/
  Repository.swift          the data and the logic to fetch it
Views/
  RepositoryCell.swift       the table view cell
  RepositoryFormatting.swift string formatting used by the views
Controllers/
  RepositoryListViewController.swift
  RepositoryDetailViewController.swift
Tests/
  RepositoryModelTests.swift
  RepositoryFormattingTests.swift
  StubURLProtocol.swift      a network stub used only by the tests
```
 
## How MVC is structured here
 
**Model**
`Repository` is a plain struct that also knows how to fetch and decode itself from the GitHub API. This is the traditional Cocoa approach: the model layer owns its own data access. It has no import of UIKit anywhere.
 
**View**
`RepositoryCell` and the formatting helpers. Views only display data they are handed through a `configure(with:)` method. They never reach into the model layer or the network on their own.
 
**Controller**
`RepositoryListViewController` and `RepositoryDetailViewController`. The list controller asks the model for data, updates the table view with a diffable data source, and handles loading and error states. The detail controller receives its model directly from the list controller when the user taps a row.
 
```
RepositoryListViewController
  -> calls Repository.fetchAll(forUsername:)
  -> receives [Repository]
  -> updates the table view
 
RepositoryDetailViewController
  -> receives a single Repository from the list controller
  -> populates its view with that data
```
 
## How delegates work
 
Delegation is how the View reports things back to the Controller without knowing anything about it. It shows up constantly in this project through UIKit's own delegate protocols, so it is worth calling out on its own.
 
- A delegate is just an object that another object hands work off to, through a protocol
- The View defines a protocol describing what it needs help with, for example `tableView(_:didSelectRowAt:)`
- The Controller conforms to that protocol and sets itself as the View's delegate
- The View calls methods on its delegate when something happens, but it never knows the delegate is a `UIViewController`, only that it conforms to the protocol
- This keeps the View reusable. `UITableView` has no idea what a `Repository` is, it just calls its delegate when a row is tapped
- Delegate properties are almost always marked `weak` to avoid a retain cycle, since the delegate (the Controller) usually already owns the object it is the delegate of (the View)
In this project, `RepositoryListViewController` conforms to `UITableViewDelegate` and sets itself as the table view's delegate in `setUpTableView()`. When a row is tapped, the table view calls `tableView(_:didSelectRowAt:)` on the controller, which is where the push to `RepositoryDetailViewController` happens:
 
```
tableView (View)
  -> user taps a row
  -> calls delegate?.tableView(_:didSelectRowAt:)
  -> RepositoryListViewController (Controller) handles the tap
  -> pushes RepositoryDetailViewController
```
 
This is the same mechanism used for `UITextFieldDelegate`, `UIScrollViewDelegate`, and most other UIKit callbacks. It is one of the main ways a Controller finds out what happened in its View without the View needing to know anything about the Controller.
 
 MVC gets a bad reputation because the controller ends up owning too much: networking, layout, navigation, formatting, and business logic all in one file. That is not a flaw in MVC itself, it is what happens when there is no discipline about what belongs in the controller.
 
This project avoids that as much as MVC allows by:
 
- Keeping data fetching on the model, not inline in the controller
- Keeping formatting logic in a separate type instead of written directly in the controller
- Keeping the controller's job limited to loading state, requesting data, and updating the view

Even with that discipline, the view controller is still both the "controller" and part of the view hierarchy on iOS. That dual role is the root cause of "Massive View Controller" and is difficult to avoid completely without moving to a pattern that separates those responsibilities into different types, such as MVVM or VIPER.
 
## When to use MVC
 
- Small screens with limited logic
- Prototypes or early stage apps where architecture overhead is not worth it yet
- Teams new to iOS who need the simplest mental model before adopting something more structured

## When to avoid it
 
- Screens with complex state or a lot of business logic
- Apps that need high unit test coverage on view behavior, since view controllers are hard to test in isolation
- Large teams where multiple people work in the same view controller file at once

## Testing notes
 
The model layer is fully unit tested using a stubbed `URLProtocol`, so the tests exercise the real fetch and decode logic without touching the network. The view controllers are not unit tested directly. This is a known limitation of MVC and is left as is on purpose, rather than worked around, since working around it usually means quietly turning the project into MVVM.
 
## Tradeoffs summary
 
| | |
|---|---|
| Setup speed | Fast |
| Learning curve | Low |
| Testability | Good for the model, poor for view controller logic |
| Scalability | Poor past a handful of screens |
| Apple tooling fit | Natural fit for UIKit, no extra abstraction needed |
