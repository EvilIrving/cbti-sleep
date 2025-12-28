# iOS UX Design Guide

## Core Principles

> **Clarity, Deference, Fluidity** (Apple HIG)

---

## 1. Time Input

### Component

**`UIDatePicker`** in `.timeInterval` mode or **Custom Wheel Picker**

### Interactions

- **Scroll to select**: Vertical swipe on wheel components
- **Quick adjust**: `+15m`, `+30m`, `-15m` buttons below picker
- **Smart default**: Pre-fill with last used time

### Layout

```
┌─────────────────────────────────────┐
│            Bedtime                  │
│            10:30 PM                 │
│    ┌───┐   ┌───┐                   │
│    │ ▲ │   │ ▼ │   Hour            │
│    └───┘   └─────────────────────┐ │
│    ┌───┐   ┌───┐                 │ │
│    │ ▲ │   │ ▼ │   Minute        │ │
│    └───┘   └─────────────────────┘ │
├─────────────────────────────────────┤
│   [-15m]  [+15m]  [+30m]  [+1h]    │
└─────────────────────────────────────┘

✓ Place picker in sheet or inline
✓ Show duration hint below (e.g., "8h recommended")
```

### Sleep-Specific

- Auto-calculate sleep duration when bedtime > wake time
- Show cross-day indicator when applicable

---

## 2. Selection

### Components

- **`.menu`**: Contextual actions
- **`.confirmationDialog`**: Binary choices
- **Picker / Stepper**: Numeric selections

### Interactions

- **Tap to present**: Full-screen sheet or popover
- **Recent first**: Sort by usage frequency

### Layout

```
Sleep Goal
┌─────────────────────────────────────┐
│                                     │
│    6   7   8   9   10   11   12     │
│    ○   ●   ●   ○   ○    ○    ○     │
│          hours                      │
│                                     │
├─────────────────────────────────────┤
│  Range: 4 - 12 hours                │
└─────────────────────────────────────┘

✓ Use Picker for 3-12 numeric options
✓ Direct tap to select, auto-save
```

---

## 3. Numeric Input

### Components

- **`.stepper`**: `-` / `+` buttons
- **Slider**: With value label
- **TextField**: With keyboard

### Interactions

- **Stepper tap**: Increment/decrement by step value
- **Slider drag**: Continuous adjustment
- **Keyboard tap**: Direct numeric entry

### Layout

```
┌─────────────────────────────────────┐
│          Sleep Duration             │
│              7.5 hours              │
│                                     │
│    ┌─────┐                          │
│    │  -  │    ───────────●────────  │
│    └─────┘               7.5        │
│    ┌─────┐         4         12     │
│    │  +  │                          │
│    └─────┘                          │
├─────────────────────────────────────┤
│  Range: 4 - 12 hours                │
└─────────────────────────────────────┘

✓ SF Symbols: `minus`, `plus`, `capsule.fill`
✓ Show min/max labels below slider
✓ Stepper for discrete values (0.5h)
```

---

## 4. Form Editing

### Components

- **`.sheet`**: Modal form presentation
- **NavigationStack**: Push to detail view

### Interactions

- **Tap to expand**: Present sheet or navigate
- **Auto-save**: On dismiss, no save button needed
- **Discard**: Swipe down to dismiss

### Flow

```
View Mode                    Edit Mode
┌─────────────────────┐   ┌─────────────────────┐
│  Bedtime            │   │  Bedtime            │
│  ▸ 10:30 PM        ───▶│  10:30 PM          │
│                     │   │  ┌───┐   ┌───┐    │
│                     │   │  │ ▲ │   │ ▼ │    │
│                     │   │  └───┘   └───┘    │
│                     │   │                     │
│                     │   │      Cancel  Save   │
└─────────────────────┘   └─────────────────────┘
        ↓ swipe down to dismiss
```

### Guidelines

- **Edit in sheet**: For 1-3 fields
- **Navigate**: For 4+ fields
- **No save button**: Auto-save on dismiss
- **Confirm discard**: If unsaved changes exist

---

## 5. Date Selection

### Component

**`UIDatePicker`** with `.graphical` or `.compact` style

### Interactions

- **Tap date**: Open date picker
- **Quick nav**: Today / Yesterday / This Week
- **Swipe month**: Horizontal swipe on calendar

### Layout

```
┌─────────────────────────────────────┐
│  <    December 2024    >           │
│                                     │
│    S   M   T   W   T   F   S       │
│   25  26  27  28  29  30   1       │
│    2   3   4   5   6   7   8       │
│    9  10  11  12  13  14  15       │
│   16  17  18  19  20  21  22       │
│   23  24  25  26  27  28  29       │
│   30  31                           │
│                                     │
├─────────────────────────────────────┤
│  [Today]  [Yesterday]  [This Week] │
└─────────────────────────────────────┘

✓ Use `.graphical` for date range selection
✓ Use `.compact` for single date inline
✓ Dot indicator for dates with records
```

---

## 6. List Operations

### Components

- **Swipe Actions**: Leading/trailing
- **Edit Mode**: Bulk selection

### Interactions

- **Swipe left**: Reveal destructive action
- **Swipe right**: Reveal secondary action
- **Long press**: Enter edit mode
- **Tap checkbox**: Multi-select

### Layout

```
┌─────────────────────────────┐
│  Q   Today                  │
├─────────────────────────────┤
│  ○  7h 30m                  │
│     10:30 PM → 6:00 AM      │
├─────────────────────────────┤
│  ○  8h 15m                  │
│     11:00 PM → 7:15 AM      │
└─────────────────────────────┘
       ↑ Swipe Right  ↓ Swipe Left
┌─────────────────────────────┐
│  [Pin]        [Delete]     │
└─────────────────────────────┘

✓ Use `.destructive` for delete (red)
✓ Use `.warning` for caution actions (orange)
✓ Use `.idle` for secondary actions (gray)
✓ Max 2 swipe actions per side
```

### Edit Mode

```
┌─────────────────────────────┐
│  Cancel          Delete (2)│
├─────────────────────────────┤
│  ☑  7h 30m                  │
│  ☑  8h 15m                  │
│     9h 00m                  │
├─────────────────────────────┤
│         [Add to Favorites]  │
└─────────────────────────────┘
```

---

## 7. Feedback

### Components

- **Toast**: For brief confirmation (SwiftUI)
- **Alert**: For errors requiring action
- **Banner**: For persistent messages
- **ProgressView**: For loading states

### Usage

```
✓ Toast (1-2s): Operation success
┌─────────────────────────────┐
│  ✓ Saved                    │
└─────────────────────────────┘

✓ Alert (user action required):
┌─────────────────────────────┐
│  Delete Record?             │
│                             │
│  This cannot be undone.     │
│                             │
│      Cancel   Delete        │
└─────────────────────────────┘

✓ Banner (persistent info):
┌─────────────────────────────┐
│  ⚠️ iCloud Sync Required    │
│  Sign in to sync data       │
└─────────────────────────────┘

✓ ProgressView (loading):
┌─────────────────────────────┐
│     ⏳ Loading...           │
└─────────────────────────────┘
```

### Guidelines

- **Toast**: Max 2 lines, auto-dismiss
- **Alert**: Max 2 buttons (Cancel + Action)
- **Banner**: Top of screen, swipe to dismiss
- **Skeleton**: For content loading

---

## 8. Navigation

### Structure

- **TabBar**: Top-level sections (max 5)
- **NavigationStack**: Hierarchical content
- **Sheet**: Secondary content

### Tab Structure

```
┌─────────────────────────────┐
│          Sleep Log          │
├─────────────────────────────┤
│                             │
│        [Statistics]         │
│                             │
│                             │
├─────────────────────────────┤
│  📊    📝    📅    ⚙️       │
│  Log   Cal  Stats  Settings │
└─────────────────────────────┘
```

---

## 9. Accessibility

### Requirements

- **Dynamic Type**: Support `.largeTitle` → `.caption1`
- **Haptic**: Use `UIImpactFeedbackGenerator`
- **VoiceOver**: Proper accessibility labels
- **Color**: WCAG AA contrast ratio (4.5:1)

### Example

```swift
Button(action: save) {
  Label("Save", systemImage: "checkmark.circle.fill")
}
.accessibilityLabel("Save sleep record")
.accessibilityHint("Double tap to save")
```

---

## Priority Matrix

| Priority | Feature | Complexity |
|----------|---------|------------|
| P0 | Quick Log Entry | Low |
| P0 | Time Adjustment | Low |
| P1 | Sleep Statistics | Medium |
| P1 | Calendar View | Medium |
| P2 | Tag Management | Medium |
| P2 | Data Export | High |
| P3 | Cloud Sync | High |

---

## Design Resources

- **SF Symbols**: `A` → `Z` + numbers + symbols
- **System Colors**: Primary, Secondary, Tertiary
- **Corner Radius**: 10pt (default), 20pt (cards)
- **Spacing**: 8pt grid system
