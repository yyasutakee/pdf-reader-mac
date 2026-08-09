---
trigger: always_on
---

# Clean Code: One Logical Block, One Line

## The Rule

> **Every logical block must be expressible in a single line.**
> If a logical block spans multiple lines, extract it into a named function.

A function's body should read like a **table of contents** — each line names *what* is happening, never *how*. The *how* lives inside the extracted function.

---

## Why This Matters

- A reader can understand the high-level flow **without reading every detail**
- Each extracted function has a **name that reveals its intent** — better than any comment
- Deeply nested, multi-line logic blocks become **impossible to introduce** — the rule prevents them by design
- Functions stay **short, focused, and testable in isolation**

---

## The Pattern

```swift
// GOOD — each line is one logical idea, named clearly
func calculateCurrentStreak(from vocabularyItems: [VocabularyItem]) -> Int {
    let activeDays: Set<Date> = buildActiveDaysSet(from: vocabularyItems)
    guard let streakStartDay: Date = findStreakStartDay(in: activeDays) else { return 0 }
    return countConsecutiveDays(endingOn: streakStartDay, in: activeDays)
}
```

```swift
// BAD — the reader must parse low-level detail to understand the intent
func calculateCurrentStreak(from vocabularyItems: [VocabularyItem]) -> Int {
    let calendar = Calendar.current
    let activeDays = Set(vocabularyItems.map { calendar.startOfDay(for: $0.createdDate) })
    guard !activeDays.isEmpty else { return 0 }
    let today = calendar.startOfDay(for: Date())
    var checkDay: Date
    if activeDays.contains(today) {
        checkDay = today
    } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
              activeDays.contains(yesterday) {
        checkDay = yesterday
    } else {
        return 0
    }
    var streak = 0
    while activeDays.contains(checkDay) {
        streak += 1
        guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDay) else { break }
        checkDay = prev
    }
    return streak
}
```

Both produce the same result. But only the first one can be understood in seconds.

---

## Examples

### Example 1 — Filtering and Mapping

```swift
// BAD
func getExpiredProductNames(from products: [Product]) -> [String] {
    var expiredProductNames: [String] = []
    for product in products {
        if product.expirationDate < Date() {
            expiredProductNames.append(product.name)
        }
    }
    return expiredProductNames
}

// GOOD
func getExpiredProductNames(from products: [Product]) -> [String] {
    return filterExpiredProducts(from: products).map { $0.name }
}

private func filterExpiredProducts(from products: [Product]) -> [Product] {
    return products.filter { isProductExpired($0) }
}

private func isProductExpired(_ product: Product) -> Bool {
    return product.expirationDate < Date()
}
```

---

### Example 2 — Validation Logic

```swift
// BAD
func canSubmitOrder(cart: Cart, user: User) -> Bool {
    if cart.items.isEmpty { return false }
    if cart.items.contains(where: { $0.stock == 0 }) { return false }
    if !user.hasVerifiedEmail { return false }
    if user.paymentMethods.isEmpty { return false }
    return true
}

// GOOD
func canSubmitOrder(cart: Cart, user: User) -> Bool {
    return isCartReady(cart) && isUserReadyToCheckout(user)
}

private func isCartReady(_ cart: Cart) -> Bool {
    return !cart.items.isEmpty && allItemsAreInStock(cart.items)
}

private func allItemsAreInStock(_ cartItems: [CartItem]) -> Bool {
    return !cartItems.contains(where: { $0.stock == 0 })
}

private func isUserReadyToCheckout(_ user: User) -> Bool {
    return user.hasVerifiedEmail && !user.paymentMethods.isEmpty
}
```

---

### Example 3 — SwiftUI View Body

```swift
// BAD
var body: some View {
    VStack {
        HStack {
            Image(systemName: "flame.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.orange)
            Text("\(streakCount)")
                .font(.system(size: 13, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(Color.orange)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.orange.opacity(0.12))
        .clipShape(Capsule())
    }
}

// GOOD
var body: some View {
    VStack {
        streakBadge
    }
}

private var streakBadge: some View {
    streakBadgeLabel
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.orange.opacity(0.12))
        .clipShape(Capsule())
}

private var streakBadgeLabel: some View {
    HStack {
        streakFlameIcon
        streakCountText
    }
}
```

---

## The Mental Check

Before finishing any function, ask yourself:

> *"Can a new reader understand what this function does by reading only its body — without reading any of the functions it calls?"*

If the answer is **yes**, the function is at the right level of abstraction.
If the answer is **no**, a line is doing too much — extract it.

---

## Summary

| Situation | Action |
|---|---|
| A block of code spans multiple lines | Extract into a named function |
| A line needs a comment to be understood | The comment IS the function name — extract it |
| A condition is complex (`if a && b && !c`) | Extract into a named boolean function |
| A loop body is more than one line | Extract the loop body into a named function |
| A SwiftUI view body is long | Extract sections into named `private var` computed properties |

