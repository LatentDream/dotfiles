---
name: code-like-bob
description: >
  Applies Uncle Bob's Clean Code method-extraction principles to C# code.
  Use this skill whenever writing new C# code, modifying existing C# methods,
  or reviewing C# pull requests for readability. Triggers on phrases like
  "clean code", "code like Bob", "uncle bob style", "Bobify", "extract methods",
  or any request to improve C# code readability through better structure.
  Also use when the user invokes /code-like-bob directly. If you are writing
  or modifying C# code and the user has this skill active, apply these
  principles by default.
---

# Code Like Bob

Write C# that reads like well-written prose. A reader should understand what a
method does by reading its body as a sequence of clearly-named steps — without
needing to look inside any of them. Implementation details live in extracted
helper methods whose names explain their purpose.

## Core Principles

### 1. The Stepdown Rule

A method's body should read top-down like a short story: each line is a
clearly-named action at the same level of abstraction. If you have to scroll
or squint to understand what a method does, it needs extraction.

```csharp
// This reads like a plan:
public void ProcessOrder(Order order)
{
    ValidateOrder(order);
    ApplyDiscounts(order);
    CalculateShipping(order);
    ChargePayment(order);
    SendConfirmation(order);
}
```

The reader knows exactly what happens without seeing a single `if`, `for`, or
`try/catch` at this level.

### 2. Extract Method — Even If Called Once

A private method called exactly once is not waste. It is a named explanation.
The goal is not reuse — it is readability. When you find yourself writing a
block of code that does a distinct sub-task, extract it and give it a name
that tells the reader *what* it accomplishes, not *how*.

**Before:**
```csharp
public void InitializePlayer(PlayerData data)
{
    // Set up health
    _health = data.BaseHealth;
    _health += _equipment.GetHealthBonus();
    _health = Mathf.Clamp(_health, 0, _maxHealth);

    // Set up inventory
    _inventory.Clear();
    foreach (var item in data.StartingItems)
        _inventory.Add(ItemFactory.Create(item));

    // Set up position
    transform.position = data.SpawnPoint;
    transform.rotation = Quaternion.identity;
}
```

**After:**
```csharp
public void InitializePlayer(PlayerData data)
{
    InitializeHealth(data);
    InitializeInventory(data);
    PlaceAtSpawnPoint(data);
}
```

Notice the comments disappeared — they became method names.

### 3. One Level of Abstraction Per Method

Do not mix high-level orchestration with low-level mechanics. If a method calls
`SendEmail()` on one line and manually parses a byte array on the next, those
are two different abstraction levels and the low-level work should be extracted.

A good heuristic: if you can describe what a line does in business terms
("validate the order") it belongs at the high level. If you need implementation
terms ("check the regex pattern against the input string") it belongs in an
extracted method.

### 4. Names Over Comments

If you are about to write a comment that explains *what* a block of code does,
that comment is the method name you should extract instead. Comments that
explain *what* are signposts pointing to a missing method. Comments that
explain *why* (business rules, workarounds, gotchas) are fine — they add
context that no method name can capture.

```csharp
// Bad — the comment is doing the method name's job:
// Calculate the discounted price based on membership tier
var discount = membership.Tier switch { ... };
var price = basePrice * (1 - discount);

// Good — the comment became a method name:
var price = CalculateDiscountedPrice(basePrice, membership);
```

### 5. Small Methods

Aim for methods under 20 lines. This is a guideline, not a hard ceiling — a
25-line method that reads clearly is better than five 5-line methods with
cryptic names. But when a method grows long, look for natural seams where you
can extract a step.

Long parameter lists are also a smell. If an extracted method needs many
arguments, that often means the data wants to be a small object or struct.

### 6. Small Classes with Clear Roles

Apply the same reasoning at the class level: a class should have one reason
to change. When a class accumulates multiple responsibilities — parsing input,
applying business rules, managing state, formatting output — split it into
collaborating classes that each own one concern.

**Before:**
```csharp
class CatalogCsvParser
{
    // 700 lines: CSV tokenizing, column mapping, type conversion,
    // multi-row aggregation, conflict detection, serialization, escaping
}
```

**After:**
```csharp
class CatalogCsvParser           // orchestrates parse + serialize
{
    readonly CsvTokenizer m_Tokenizer;
    readonly CsvReflectionMapper m_Mapper;
    readonly RowAggregator m_Aggregator;
}

class CsvTokenizer               // RFC 4180 line/field splitting
class CsvReflectionMapper        // [CsvColumn] → PropertyInfo cache
class RowAggregator              // multi-row grouping + conflict detection
```

Each class is small enough to understand in one sitting. The orchestrator's
methods read as named steps over its collaborators.

A good heuristic: if you need a comment block or `#region` to separate
sections within a class, those sections likely want to be their own types.

## How to Apply

### When Writing New Code

Apply these principles as you write. Structure public methods as high-level
step sequences. Push details into private helpers. Name every extracted method
so its purpose is obvious without reading its body.

### When Modifying Existing Code

Apply these principles **only to methods you are already changing**. If you
modify `Foo()` and it has a 40-line body mixing abstraction levels, refactor
`Foo()`. If `Bar()` next to it is equally messy but you are not touching it,
leave it alone. The scope of Clean Code changes matches the scope of
functional changes.

### When Reviewing Code (Review Mode)

If invoked as part of a code review or PR review (the user asks you to review,
audit, or Bobify a diff), **flag issues instead of rewriting**. For each
finding:

1. Identify the method and what principle it violates
2. Explain briefly why it matters for readability
3. Suggest the refactoring — show the extracted method signature(s) and the
   cleaned-up caller, but frame it as a suggestion

Example review comment:

> **`PlayerManager.HandleDamage()` (line 42-78)** — This method mixes
> damage calculation, death checking, UI updates, and sound effects at the
> same abstraction level. Consider extracting:
> ```csharp
> private void HandleDamage(DamageInfo info)
> {
>     var finalDamage = CalculateFinalDamage(info);
>     ApplyDamage(finalDamage);
>     UpdateDamageUI(finalDamage);
>     PlayDamageEffects(info);
> }
> ```

## Judgment Calls

These principles improve readability, but applying them mechanically can make
things worse. Use your judgment:

- **Do not extract trivial one-liners.** `SetPosition(data.SpawnPoint)` that
  just wraps `transform.position = data.SpawnPoint` adds indirection without
  adding clarity. Extract when the name adds understanding beyond what the
  code already says.

- **Do not extract when the method name is just a synonym for the code.**
  If a method's name is a generic verb + the type it returns (`BuildPayload`,
  `CreateConfig`, `GetData`), you probably haven't found a meaningful
  abstraction — you've just moved code behind a door. The reader still has
  to open that door to understand what's happening.

  ```csharp
  // Over-extraction — "BuildPayload" just restates "new Payload { ... }":
  m_CommonAnalytics.Send(BuildPayload(kvp.Key, kvp.Value.Count, exception));

  CommonEventPayload BuildPayload(string providerName, int itemCount, Exception exception)
  {
      return new CommonEventPayload
      {
          action = EventNameDeploy,
          context = providerName,
          count = itemCount,
          exception = exception?.GetType().ToString()
      };
  }

  // Better — the object initializer is the detail, and it's clear enough inline:
  m_CommonAnalytics.Send(new CommonEventPayload
  {
      action = EventNameDeploy,
      context = kvp.Key,
      count = kvp.Value.Count,
      exception = exception?.GetType().ToString()
  });
  ```

- **Deduplication is a valid reason to extract, even without abstraction.**
  When multiple methods repeat the same block, extracting a shared helper
  eliminates drift — but name it for what it *does*, not what it *builds*.

  ```csharp
  // Three identical send blocks → one shared method, named for its action:
  void SendWindowEvent(string action, string itemPath)
  {
      m_CommonAnalytics.Send(new CommonEventPayload
      {
          action = action,
          context = new ItemPathParams(itemPath).itemName
      });
  }
  ```

  `SendWindowEvent` names a concept. `BuildPayload` is tautological.

- **Do not fragment cohesive logic.** Two lines that are tightly coupled and
  read clearly together are better left together than split into a method
  that forces the reader to jump around.

- **Match the team's style.** If the surrounding codebase uses a different
  organizational pattern, lean toward consistency over dogma — but still
  apply the principles within modified methods.

- **Do not extract every type to its own class.** A small nested struct, a
  private enum, or a 10-line helper class that only the parent uses can stay
  nested. Extract to a top-level class when the type has its own tests, its
  own consumers, or enough complexity to warrant reading independently.
  A `ProductBadge` record with two properties doesn't need its own file.
  A `RowAggregator` with conflict detection logic does.

- **Depth vs. width.** If extraction creates a call chain five levels deep
  where each method just calls one other method, you have gone too far.
  The goal is that each level is easy to understand, not that each level
  has exactly one line.
