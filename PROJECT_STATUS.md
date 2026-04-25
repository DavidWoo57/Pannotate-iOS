# Pannotate Project Status

## Current App Goal

Pannotate is an iPhone-first native SwiftUI prototype for spatially guided AI video creation. The current goal is a clean, buildable UI foundation that matches the design direction using mock data only.

## SwiftUI Project Structure

- `Pannotate-iOS/Views/`: root tabs and app screens.
- `Pannotate-iOS/Components/`: reusable UI components.
- `Pannotate-iOS/Theme/`: app theme, adaptive colors, and layout constants.
- `Pannotate-iOS/Models/`: mock model types.
- `Pannotate-iOS/MockData/`: static sample data.

## Completed Steps

- Replaced the default Hello World screen with a five-tab SwiftUI app shell.
- Added Projects, Studio, Outputs, Sequence, Profile, and Settings screens.
- Added fixed headers, refined spacing, safer scroll padding, and improved Sequence layout.
- Restored and kept the native SwiftUI `TabView` tab bar.
- Implemented working Light / Dark / System theme switching with local persistence.

## Important Constraints

- Do not modify `DesignReference/`; it contains the design brief and screenshots.
- Use SwiftUI only and do not add external packages.
- Do not implement backend, real upload, drawing engine, AI video generation, video playback, login, database, or payment yet.
- Keep the app iPhone-first for now.

## Navigation Structure

- The app uses native SwiftUI `TabView` with five tabs: Projects, Studio, Outputs, Sequence, and Profile.
- Each tab owns a `NavigationStack`.
- Settings is a secondary page pushed from Profile and shows a native back button.

## Theme Behavior

- Settings supports Light, Dark, and System theme options.
- The selected theme applies globally with SwiftUI `preferredColorScheme`.
- The choice persists locally with `@AppStorage`.
- The current UI is dark/light capable through shared adaptive theme colors.

## Tab Bar Decision

Keep the native SwiftUI `TabView` tab bar. Do not create a custom tab bar or manually drawn bottom navigation.

## Known Remaining Tasks

- Add basic interactive prototype behavior using mock data only.
- Improve placeholder canvas and annotation-tool affordances.
- Add simple mock project/clip detail flows if needed.
- Continue visual refinement toward the screenshots without implementing real product services.

## Next Recommended Step

Build basic interactive prototype behavior using mock data only, such as selecting projects/clips, opening placeholder detail screens, and making existing controls update local UI state.
