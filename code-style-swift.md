---
trigger: always_on
---

# Coding Standards

## Descriptive Naming (Clean Code Principles)
- **Intent-Revealing**: Names must reveal their intent. If a name requires a comment to explain it, the name is inadequate. Use names that answer: *Why was it created? What is its role?* (e.g., use `elapsedTimeInSeconds` instead of `elapsed`).
- **Meaningful Distinctions**: Never use generic suffixes like `1`, `2`, or `Temp`. Use names that distinguish the role of the object (e.g., use `sourceAccount` and `destinationAccount` instead of `accountA` and `accountB`).
- **Searchability & Grep-ability**: Names must be easy to find across the entire project. Longer, highly unique names are preferred over short, ambiguous ones.
- **No Mental Mapping**: Avoid single-letter variables like `i`, `j`, `k`, or `idx` in loops. The reader should never have to "map" a name to its true meaning in their head while reading logic.
- **Zero Abbreviations**: Explicitly avoid **all** abbreviations. Use `identifier` instead of `id`, `configuration` instead of `config`, and `parameter` instead of `param`.
- **Method Naming**: Methods should be named using "Verb-Noun" pairs (e.g., `calculateTotalProfit()`) rather than vague single words (e.g., `execute()`).


## Function naming
- **Parameter labeling**: Argument labels must ALWAYS match parameter names. Never use two-name parameters (e.g., `func someFunction(label parameter: Type)` is forbidden).
- **Descriptive parameters**: Parameter names MUST be highly descriptive so anyone can understand the intent without context.
- **No abbreviations**: Always use full, descriptive names. Never use abbreviations (e.g., use `identifier` instead of `id`, `configuration` instead of `config`).

## Project Structure
The project follows a **5-layer architecture**. Each layer must have its own dedicated folder:

- **Views** — Views and UI components, organized into feature-based subfolders. Each distinct feature or screen gets its own subfolder named after the feature. A `Shared/` subfolder holds reusable components used across multiple features.
  - Example (weather app): `CurrentWeather/`, `WeeklyForecast/`, `HourlyTemperature/`, `Shared/`
  - Example (e-commerce app): `ProductList/`, `ProductDetail/`, `Cart/`, `Checkout/`, `Shared/`
  - Example (social app): `Feed/`, `Profile/`, `Messaging/`, `Shared/`
- **State** — Store, app state, and state management
- **Services** — External integrations (location, network, authentication, etc.)
- **Persistence** — Storage and data serialization
- **Models** — Pure data structs/value types with no behavior

Rules:
- Each new file must be placed in the folder that matches its layer.
- No layer should be skipped or merged with another.
- Presentation must always use feature-based subfolders — never a flat list of views.
- Shared UI components that are not feature-specific belong in `Presentation/Shared/`.
- Models must be pure value types with no storage or networking logic.
- Persistence is strictly separated from Models.

## Single Responsibility Principle
- **One purpose per file**: Each file should contain exactly one primary type (struct, class, enum) that serves a single, well-defined purpose.
- **Extract shared components**: If a component is used by multiple features, extract it into its own file under the appropriate `Shared/` folder. Never define a shared component inside a feature-specific file.
- **Split when concerns diverge**: If a file contains multiple types that serve different roles (e.g., a view and an unrelated helper), split them into separate files named after their responsibility.

## Architecture: XXXStore
- Application state must reside in a `XXXState` struct, managed by a `XXXStore`, store is responsible for one domain logic, i.e. if it is weather app, it can be a WeatherStore. If there are multiple domain concern, we make multiple stores.
- The `XXXStore` must inherit from the generic `Store<State>` base class. This enforces that the `state` property is **read-only** even within the `XXXStore` methods.
- Any changes to the state MUST be made via the `setState` method. Direct assignment to properties of `state` is strictly forbidden and should be caught by the compiler.
- Do not use complex `enum` dispatching for actions. Instead, use clear, descriptively named **methods** in the `XXXStore` to represent user intents and system events (e.g., `saveCredential(...)`, `logout()`).
- Views should access only the specific parts of the `store.state` they need to remain as clean as possible.

The code of Store

import SwiftUI
import Combine

/// A generic base class for a single source of truth state store.
/// It enforces read-only access to the state and provides a controlled mutation mechanism.
class Store<State>: ObservableObject {
    /// The current state of the application.
    /// This is read-only from the outside to enforce explicit mutation via methods.
    private(set) var state: State
    
    /// Initializes the store with an initial state.
    /// - Parameter initialState: The starting state of the store.
    init(initialState: State) {
        self.state = initialState
    }
    
    /// Updates the state using the provided mutation closure.
    /// This is the ONLY way to modify the state.
    /// - Parameter mutation: A closure that receives a reference to the current state for modification.
    func setState(_ mutation: (inout State) -> Void) {
        // Since state is a value type (struct), we can modify it directly in an inout closure.
        // We trigger manual notification to bypass the compiler crash associated with @Published in generic classes.
        objectWillChange.send()
        mutation(&state)
    }
    
    deinit {}
}

## Variables and Constants
- **Explicit Type Annotations**: Always provide explicit type annotations for every variable and constant definition (`let` and `var`), even when the type is obvious or can be inferred by the compiler.
    - Example: `let identifier: UUID = UUID()` (Correct)
    - Example: `let identifier = UUID()` (Forbidden)
    - Example: `var books: [Book] = []` (Correct)
    - Example: `var books = [Book]()` (Forbidden)

