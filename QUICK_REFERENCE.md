# 🚀 FitTracker Premium UI - Quick Reference Card

## 🎨 Colors

### Dark Mode
```dart
kDarkBg      = #0D0D0D
kDarkCard    = #1E1E1E
kDarkText    = #FFFFFF
kDarkSubtext = #9E9E9E
```

### Light Mode
```dart
kLightBg      = #F8F9FA
kLightCard    = #FFFFFF
kLightText    = #1A1A1A
kLightSubtext = #6B7280
```

### Accent
```dart
kOrange     = #FF6B35
kOrangeDark = #E04E1A
```

### Workout Types
```dart
Cardio:      #EF5350 (Red)
Strength:    #42A5F5 (Blue)
Flexibility: #66BB6A (Green)
HIIT:        #FF7043 (Orange)
Sports:      #AB47BC (Purple)
```

---

## 🧩 Components Cheat Sheet

### FitCard
```dart
FitCard(child: Widget)
FitCard(gradient: LinearGradient, showGlow: true, child: Widget)
FitCard(onTap: () {}, child: Widget)
```

### FitButton
```dart
FitButton(label: 'Text', onTap: () {})
FitButton(label: 'Text', icon: Icons.add, onTap: () {})
FitButton(label: 'Text', isLoading: true, onTap: () {})
FitButton(label: 'Text', isSecondary: true, onTap: () {})
```

### WorkoutCard
```dart
WorkoutCard(
  title: 'Name',
  type: 'Cardio',
  duration: 30,
  onTap: () {},
  onEdit: () {},
  onDelete: () {},
)
```

### StatTile
```dart
StatTile(
  value: '1,278',
  label: 'Calories',
  icon: Icons.local_fire_department,
  color: kOrange,
)
```

### ThemeToggle
```dart
ThemeToggle(
  isDark: provider.isDark,
  onToggle: provider.toggle,
)
```

### EmptyState
```dart
EmptyState(
  icon: Icons.fitness_center,
  title: 'No data',
  subtitle: 'Add your first item',
  actionLabel: 'Add',
  onAction: () {},
)
```

---

## 📐 Spacing

```dart
4px   - Extra Small
8px   - Small
12px  - Medium
16px  - Default
20px  - Large
24px  - Extra Large
32px  - XXL
```

---

## 🎯 Border Radius

```dart
8px   - Chips, Badges
12px  - Small Cards
16px  - Buttons, Inputs
20px  - Cards
24px  - Hero Cards
```

---

## 🎨 Shadows

```dart
Level 1: blurRadius: 4,  offset: (0, 2)
Level 2: blurRadius: 8,  offset: (0, 4)
Level 3: blurRadius: 12, offset: (0, 6)
Level 4: blurRadius: 16, offset: (0, 8)
Level 5: blurRadius: 24, offset: (0, 12)
```

---

## 📱 Responsive

```dart
// Check screen size
final width = MediaQuery.of(context).size.width;
final isMobile = width < 600;
final isTablet = width >= 600 && width < 1200;

// Adaptive padding
EdgeInsets.symmetric(
  horizontal: isMobile ? 16 : 32,
)

// Responsive grid
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: isMobile ? 2 : 3,
  ),
)
```

---

## 🎞️ Animations

```dart
// Haptic feedback
HapticFeedback.lightImpact();
HapticFeedback.mediumImpact();

// Animated container
AnimatedContainer(
  duration: Duration(milliseconds: 300),
  curve: Curves.easeInOut,
)

// Page transition
PageRouteBuilder(
  transitionDuration: Duration(milliseconds: 300),
  pageBuilder: (_, __, ___) => NextScreen(),
)
```

---

## 🌗 Theme

```dart
// Get theme
final isDark = Theme.of(context).brightness == Brightness.dark;

// Use provider
final provider = Provider.of<ThemeProvider>(context);
provider.toggle();

// Theme colors
final textColor = isDark ? kDarkText : kLightText;
```

---

## 🔧 Common Patterns

### Screen Template
```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    // Load data
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? kDarkBg : kLightBg,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : CustomScrollView(slivers: [...]),
      ),
    );
  }
}
```

### List with Empty State
```dart
if (_items.isEmpty)
  EmptyState(...)
else
  ListView.builder(
    itemCount: _items.length,
    itemBuilder: (_, i) => ItemCard(_items[i]),
  )
```

### Pull to Refresh
```dart
RefreshIndicator(
  onRefresh: _loadData,
  color: kOrange,
  child: ListView(...),
)
```

---

## ⚡ Performance Tips

```dart
// Use const
const FitCard(child: Text('Static'))

// Use builder
ListView.builder(...)

// Add keys
ListView.builder(
  itemBuilder: (_, i) => ItemCard(
    key: ValueKey(_items[i].id),
    item: _items[i],
  ),
)

// Repaint boundary
RepaintBoundary(child: ComplexWidget())
```

---

## 📦 Imports

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../widgets/components.dart';
import '../models/models.dart';
import '../db/db_helper.dart';
```

---

## 🎯 Quick Commands

```bash
# Get dependencies
flutter pub get

# Run app
flutter run

# Build release
flutter build apk --release

# Analyze code
flutter analyze

# Format code
flutter format lib/
```

---

## 📚 Documentation

- **Design System:** `UI_DESIGN_SYSTEM.md`
- **Widget Tree:** `WIDGET_TREE.md`
- **Implementation:** `IMPLEMENTATION_GUIDE.md`
- **Summary:** `SUMMARY.md`

---

## 🐛 Debug Checklist

- [ ] Theme switching works
- [ ] Colors match design
- [ ] Responsive on all sizes
- [ ] Animations smooth (60fps)
- [ ] No overflow errors
- [ ] Loading states work
- [ ] Empty states show
- [ ] Haptic feedback works (device)

---

**Print this card and keep it handy! 📌**
