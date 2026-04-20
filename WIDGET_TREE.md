# 🌳 FitTracker Widget Tree Structure

## 📱 App Architecture

```
MaterialApp
├── ThemeProvider (ChangeNotifier)
├── WorkoutProvider (ChangeNotifier)
└── Home Navigation
    ├── Dashboard Screen (Index 0)
    ├── Workouts Screen (Index 1)
    ├── Progress Screen (Index 2)
    ├── Exercise Library (Index 3)
    └── Profile Screen (Index 4)
```

---

## 🏠 Dashboard Screen Widget Tree

```
DashboardScreen (StatefulWidget)
└── Scaffold
    ├── backgroundColor: kDarkBg / kLightBg
    └── body: SafeArea
        └── RefreshIndicator
            └── CustomScrollView
                ├── SliverToBoxAdapter: Header
                │   └── Padding (20px horizontal)
                │       └── Row
                │           ├── Avatar Container (48x48)
                │           │   └── Gradient Box
                │           │       └── Text (Initial)
                │           ├── SizedBox (14px)
                │           ├── Expanded: User Info
                │           │   └── Column
                │           │       ├── Text (Greeting)
                │           │       └── Text (Username)
                │           └── ThemeToggle
                │
                ├── SliverToBoxAdapter: Spacing (24px)
                │
                ├── SliverToBoxAdapter: Hero Card
                │   └── Padding (20px horizontal)
                │       └── HeroCard
                │           └── Column
                │               ├── Row: Progress Header
                │               │   ├── Column: Text Info
                │               │   │   ├── Text ("Weekly Progress")
                │               │   │   ├── RichText (Count/Goal)
                │               │   │   └── Text ("workouts this week")
                │               │   └── Stack: Circular Progress
                │               │       ├── CircularProgressIndicator
                │               │       └── Text (Percentage)
                │               ├── SizedBox (20px)
                │               ├── LinearProgressIndicator
                │               ├── SizedBox (20px)
                │               └── Row: Mini Stats
                │                   ├── MiniStat (Total)
                │                   ├── VerticalDivider
                │                   ├── MiniStat (Minutes)
                │                   ├── VerticalDivider
                │                   └── MiniStat (Calories)
                │
                ├── SliverToBoxAdapter: Spacing (24px)
                │
                ├── SliverToBoxAdapter: Quick Stats
                │   └── Padding (20px horizontal)
                │       └── Row
                │           ├── StatTile (Workouts)
                │           ├── SizedBox (12px)
                │           ├── StatTile (Hours)
                │           ├── SizedBox (12px)
                │           └── StatTile (Calories)
                │
                ├── SliverToBoxAdapter: Spacing (24px)
                │
                ├── SliverToBoxAdapter: Today's Workouts
                │   └── Padding (20px horizontal)
                │       └── Column
                │           ├── Row: Section Header
                │           │   ├── Column: Title & Subtitle
                │           │   └── Add Button Container
                │           ├── SizedBox (16px)
                │           └── Conditional:
                │               ├── If Empty: EmptyState
                │               └── If Has Data: ListView
                │                   └── WorkoutCard (repeated)
                │
                └── SliverToBoxAdapter: Bottom Spacing (100px)
```

---

## 💪 Workout Screen Widget Tree

```
WorkoutScreen (StatefulWidget)
└── Scaffold
    ├── appBar: AppBar
    │   ├── title: Text
    │   └── actions: [IconButton]
    ├── body: Column
    │   ├── Expanded: Exercise List
    │   │   └── ListView.builder
    │   │       └── ExerciseCard (repeated)
    │   │           └── FitCard
    │   │               └── Column
    │   │                   ├── Row: Exercise Header
    │   │                   │   ├── Icon
    │   │                   │   └── Text (Name)
    │   │                   ├── Row: Previous Stats
    │   │                   ├── Divider
    │   │                   └── Set Logging Section
    │   │                       ├── Row: Input Fields
    │   │                       │   ├── FitInput (Weight)
    │   │                       │   └── FitInput (Reps)
    │   │                       └── FitButton (Log Set)
    │   └── Sticky Bottom Panel
    │       └── Container
    │           └── Row
    │               ├── Rest Timer Display
    │               └── Quick Action Buttons
    └── floatingActionButton: FAB (Finish Workout)
```

---

## 📊 Progress Screen Widget Tree

```
ProgressScreen (StatefulWidget)
└── Scaffold
    ├── appBar: AppBar
    │   ├── title: Text
    │   └── actions: [DatePicker, Filter]
    └── body: Column
        ├── TabBar
        │   ├── Tab ("Strength")
        │   ├── Tab ("Volume")
        │   └── Tab ("PRs")
        └── Expanded: TabBarView
            ├── Tab 1: Strength Progress
            │   └── SingleChildScrollView
            │       ├── Padding
            │       │   └── Column
            │       │       ├── FitCard: Summary Stats
            │       │       ├── SizedBox (16px)
            │       │       ├── FitCard: Line Chart
            │       │       │   └── LineChart Widget
            │       │       ├── SizedBox (16px)
            │       │       └── FitCard: Exercise List
            │       │           └── ListView (Exercises)
            │       └── SizedBox (Bottom Padding)
            ├── Tab 2: Volume Progress
            │   └── Similar structure with Bar Charts
            └── Tab 3: Personal Records
                └── ListView of PR Cards
```

---

## 📚 Exercise Library Widget Tree

```
ExerciseLibraryScreen (StatefulWidget)
└── Scaffold
    ├── appBar: AppBar
    │   ├── title: Text
    │   └── actions: [GridToggle]
    └── body: Column
        ├── Padding: Search Bar
        │   └── FitInput (Search)
        ├── SizedBox (12px)
        ├── Filter Chips Row
        │   └── SingleChildScrollView (Horizontal)
        │       └── Row
        │           ├── FilterChip (All)
        │           ├── FilterChip (Chest)
        │           ├── FilterChip (Back)
        │           └── ... (more filters)
        ├── SizedBox (16px)
        └── Expanded: Exercise Grid/List
            └── Conditional:
                ├── If Grid: GridView.builder
                │   └── ExerciseCard (repeated)
                │       └── FitCard
                │           ├── Image/GIF
                │           ├── Text (Name)
                │           └── Badge (Muscle Group)
                └── If List: ListView.builder
                    └── ExerciseListTile (repeated)
```

---

## 👤 Profile Screen Widget Tree

```
ProfileScreen (StatefulWidget)
└── Scaffold
    ├── appBar: AppBar
    │   ├── title: Text
    │   └── actions: [EditButton]
    └── body: SingleChildScrollView
        └── Padding (20px)
            └── Column
                ├── Profile Header
                │   └── FitCard
                │       └── Column
                │           ├── Avatar (Large, 80x80)
                │           ├── SizedBox (16px)
                │           ├── Text (Username)
                │           ├── Text (Email)
                │           └── Row: Theme Toggle
                ├── SizedBox (24px)
                ├── Stats Grid
                │   └── Row
                │       ├── StatTile (Workouts)
                │       ├── SizedBox (12px)
                │       ├── StatTile (Streak)
                │       └── SizedBox (12px)
                │       └── StatTile (Hours)
                ├── SizedBox (24px)
                ├── Settings Section
                │   └── Column
                │       ├── SectionHeader ("Settings")
                │       ├── SizedBox (12px)
                │       ├── SettingsTile (Account)
                │       ├── SettingsTile (Goals)
                │       ├── SettingsTile (Notifications)
                │       └── SettingsTile (Data Export)
                ├── SizedBox (24px)
                ├── About Section
                │   └── FitCard
                │       └── Column
                │           ├── Text (App Version)
                │           └── Text (Build Number)
                ├── SizedBox (24px)
                └── FitButton (Logout, isSecondary: true)
```

---

## 🎨 Reusable Component Trees

### FitCard Component
```
FitCard
└── GestureDetector (optional onTap)
    └── Container
        ├── decoration: BoxDecoration
        │   ├── color / gradient
        │   ├── borderRadius
        │   ├── border
        │   └── boxShadow
        └── padding
            └── child (provided)
```

### FitButton Component
```
FitButton
└── GestureDetector
    └── AnimatedContainer
        ├── decoration: BoxDecoration
        │   ├── gradient / color
        │   ├── borderRadius
        │   └── boxShadow
        └── child: Conditional
            ├── If loading: CircularProgressIndicator
            └── If not loading: Row
                ├── Icon (optional)
                └── Text
```

### WorkoutCard Component
```
WorkoutCard
└── GestureDetector
    └── FitCard
        └── Row
            ├── Icon Container (56x56)
            │   └── Gradient Box
            │       └── Icon
            ├── SizedBox (14px)
            ├── Expanded: Content
            │   └── Column
            │       ├── Text (Title)
            │       ├── Row: Metadata
            │       │   ├── Badge (Type)
            │       │   └── Duration
            │       └── Text (Notes, optional)
            └── Action Buttons Column
                ├── Edit Button
                └── Delete Button
```

### StatTile Component
```
StatTile
└── Expanded
    └── FitCard
        └── Column
            ├── Icon Container (Circle)
            │   └── Icon
            ├── SizedBox (10px)
            ├── Text (Value, bold)
            └── Text (Label, small)
```

### ThemeToggle Component
```
ThemeToggle
└── GestureDetector
    └── AnimatedContainer
        ├── decoration: BoxDecoration
        │   ├── color
        │   ├── borderRadius
        │   └── border
        └── Stack
            └── AnimatedAlign
                └── Container (Toggle Circle)
                    ├── decoration: Gradient
                    └── Icon (Sun/Moon)
```

---

## 🔄 State Management Flow

```
App Root
├── MultiProvider
│   ├── ThemeProvider
│   │   ├── isDark: bool
│   │   ├── themeMode: ThemeMode
│   │   ├── toggle(): void
│   │   └── _load(): Future<void>
│   └── WorkoutProvider
│       ├── workouts: List<Workout>
│       ├── isLoading: bool
│       ├── loadWorkouts(): Future<void>
│       ├── addWorkout(): Future<void>
│       ├── updateWorkout(): Future<void>
│       └── deleteWorkout(): Future<void>
└── Consumer Widgets
    ├── Dashboard (consumes both)
    ├── Workouts (consumes WorkoutProvider)
    └── Profile (consumes ThemeProvider)
```

---

## 📐 Layout Hierarchy

### Spacing System (8px Grid)
```
Extra Small:  4px
Small:        8px
Medium:       12px
Default:      16px
Large:        20px
Extra Large:  24px
XXL:          32px
```

### Border Radius Scale
```
Small:   8px  (Chips, Badges)
Medium:  12px (Buttons, Inputs)
Default: 16px (Cards, Containers)
Large:   20px (Hero Cards)
XL:      24px (Modal, Sheets)
```

### Shadow Elevation
```
Level 1: blurRadius: 4,  offset: (0, 2)  - Subtle
Level 2: blurRadius: 8,  offset: (0, 4)  - Cards
Level 3: blurRadius: 12, offset: (0, 6)  - Buttons
Level 4: blurRadius: 16, offset: (0, 8)  - Hero
Level 5: blurRadius: 24, offset: (0, 12) - Modal
```

---

## 🎯 Navigation Structure

```
Main App
└── Bottom Navigation Bar (5 tabs)
    ├── Tab 0: Dashboard
    │   └── Can navigate to:
    │       ├── Workout Detail
    │       ├── Add Workout
    │       └── Quick Tools
    ├── Tab 1: Workouts
    │   └── Can navigate to:
    │       ├── Active Workout
    │       ├── Workout History
    │       └── Templates
    ├── Tab 2: Progress
    │   └── Can navigate to:
    │       ├── Exercise Detail
    │       └── Date Range Picker
    ├── Tab 3: Exercise Library
    │   └── Can navigate to:
    │       └── Exercise Detail
    └── Tab 4: Profile
        └── Can navigate to:
            ├── Edit Profile
            ├── Settings
            └── Data Export
```

---

**Note:** This widget tree represents the ideal structure. Actual implementation may vary based on specific requirements and optimizations.
