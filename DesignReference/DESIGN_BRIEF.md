# Pannotate iOS Design Reference

This folder contains Figma screenshots and product notes for the first native SwiftUI version of Pannotate.

The goal is to recreate the provided Figma iPhone UI as a real native iOS app that can run in Xcode.

This is an iPhone-first implementation. iPadOS support can be added later.

---

## Product Overview

Pannotate is an AI video creation app focused on spatially guided video generation.

Users start with a still image, then annotate directly on the image using visual tools such as drawing, circles, text, and directional marks. These annotations tell the AI which object should move, what should happen, and how the motion should be guided.

Users can also add a motion description prompt. The intended AI input is a combination of:

1. the original image
2. visual annotations on the image
3. a text motion description

After a short video clip is generated, users can either:

1. continue from the last frame of the previous clip
2. start a new shot
3. add clips to a sequence and export a final video

---

## Current Implementation Goal

Build the first working native SwiftUI UI version.

This first version should focus on:

- static UI
- screen structure
- tab navigation
- basic navigation between screens
- mock data
- placeholder assets
- visual similarity to the provided screenshots

Do not implement real product functionality yet.

Do not implement:

- real login
- real image upload
- real drawing/annotation engine
- real AI video generation
- real video playback
- real backend
- real database
- real payment or subscription logic
- full iPadOS layout

Use mock data and placeholder UI where needed.

---

## Important Instruction

Do not use Figma-generated web code.

The Figma screenshots are visual references only. Recreate the app as a native SwiftUI iOS app.

Use SwiftUI-native components, layout, navigation, and styling where practical.

---

## Screenshot Reference

The screenshots are located in:

`DesignReference/Screenshots/`

Suggested interpretation:

- `01_Projects.png`  
  Main Projects / Home screen

- `02_Studio.png`  
  Studio editor screen with canvas, annotation tools, motion prompt, and generate button

- `03_Outputs_Top.png` and `04_Outputs_List.png`  
  Outputs screen at different scroll positions

- `05_Sequence.png`  
  Sequence / storyboard screen

- `06_Profile_Top.png` and `07_Profile_Bottom.png`  
  Profile screen at different scroll positions

- `08_Settings_Top.png`, `09_Settings_Middle.png`, `10_Settings_Bottom.png`  
  Settings screen at different scroll positions

Top / Middle / Bottom screenshots are scroll positions of the same screen, not separate screens.

If a browser, Figma, or preview tooltip appears in a screenshot, ignore it. It is not part of the app UI.

---

## Main App Structure

The app should use a bottom tab bar with these main tabs:

1. Projects
2. Studio
3. Outputs
4. Sequence
5. Profile

Each tab should correspond to a main top-level screen.

Settings should not be a main tab. Settings should be accessible from the Profile screen.

---

## Navigation Rules

Main tab screens should not show a back button.

Secondary screens should show a clear back button.

Examples of secondary screens:

- Settings
- Project Detail placeholder
- Clip Preview placeholder
- Account placeholder
- Subscription placeholder
- Privacy placeholder
- Help placeholder

If a secondary screen is needed but not shown in the screenshots, create only a simple placeholder screen with a title and back button.

Do not invent complex screens that are not represented in the Figma screenshots.

---

## Screen Requirements

### 1. Projects Screen

Purpose:

- Show Pannotate branding
- Show page title: Projects
- Show subtitle: Your creative workspace
- Show Create New Project card
- Show recent project cards
- Use mock project data

Expected content:

- Pannotate logo / placeholder icon
- search button
- create new project card
- recent projects such as:
  - Urban Sunset
  - Ocean Waves
  - Forest Path

---

### 2. Studio Screen

Purpose:

- Main image-to-video creation workspace
- Show an image canvas
- Show annotation tools
- Show motion description input
- Show Generate Video button

Tools shown in the screenshot:

- Pan
- Draw
- Circle
- Text

Use mock canvas content and placeholder image.

Do not implement real drawing tools yet. Buttons can be static or lightly interactive placeholders.

If the screenshot contains a small “Preview” tooltip, ignore it.

---

### 3. Outputs Screen

Purpose:

- Show generated clips
- Show job status
- Show completed, processing, and queued states
- Provide Continue and Sequence actions

Use mock clips such as:

- Urban Sunset - Scene 1
- Forest Path - Scene 3
- City Lights - Opening

Status examples:

- Done
- 65%
- Queued

Do not implement real video playback or download yet. Use placeholder buttons and static mock cards.

---

### 4. Sequence Screen

Purpose:

- Show a list of clips arranged into a final sequence
- Show clip order
- Show clip duration
- Show “continues from previous frame” indicator
- Show Preview and Export buttons

Use mock sequence data.

Do not implement real drag-and-drop, trimming, preview, or export yet.

---

### 5. Profile Screen

Purpose:

- Show user identity
- Show Pannotate branding
- Show usage / credits
- Show project, clip, and export stats
- Show recent activity
- Show account/support sections
- Link to Settings

Use mock user:

- Jordan Davis
- @jordan.davis
- Pro Creator
- Monthly Credits: 340 / 500

Use mock stats:

- 12 Projects
- 47 Clips
- 8 Exports

Settings should open from this screen.

---

### 6. Settings Screen

Purpose:

- Configure app appearance, notifications, generation preferences, account, and about/legal items

Settings should include:

Appearance:
- Light
- Dark
- System

Notifications:
- Push Notifications

Generation:
- Output Quality: Draft / Standard / High
- Auto-chain Clips
- Motion Smoothing

Account:
- Subscription
- Privacy & Data
- Connected Accounts

About:
- Pannotate
- Version 1.0.0
- Terms of Service
- Privacy Policy

For this first version, settings can be static or lightly interactive mock controls. Real persistence is not required.

---

## Visual Style

Match the screenshots as closely as practical.

The current visual direction is:

- dark mode first
- premium
- modern
- cinematic
- creator-focused
- clean
- high contrast
- rounded cards
- large titles
- blue primary accent
- subtle glass / translucent feel where practical

Use native SwiftUI styling but keep the visual hierarchy close to the screenshots.

Primary accent color:

- bright iOS-style blue

Secondary accent:

- purple / blue gradient for Pannotate branding

---

## Theme Support

Support dark mode first.

Light mode can be added in the first implementation if practical, but if time is limited, prioritize dark mode visual accuracy and keep the code ready for light mode later.

If light mode is implemented now, keep it clean, soft, and readable.

Do not hardcode every color directly inside individual views. Prefer reusable color helpers or theme constants where practical.

---

## Assets

Use placeholder assets for now.

Acceptable placeholders:

- SF Symbols
- gradients
- mock image cards
- simple rectangles with image-like backgrounds
- text branding

Real logo, app icon, custom images, and video thumbnails can be replaced later.

Do not block implementation because real assets are missing.

---

## iPadOS Support

This first version is iPhone-first.

Do not build a full iPadOS-specific layout yet.

However, write the SwiftUI code in a way that can be extended later:

- use reusable components
- avoid putting everything into one huge view file
- avoid hardcoding the entire UI to one fixed iPhone size
- avoid unnecessary absolute positioning
- use flexible SwiftUI layout where practical
- keep mock data separate from UI components

Future iPadOS can later add:

- larger Studio canvas
- side panels
- split view layouts
- more advanced sequence editing

---

## Code Organization Expectations

Use clean SwiftUI structure.

Prefer multiple files and reusable components instead of one giant ContentView.

Suggested structure:

- `ContentView.swift`
- `RootTabView.swift`
- `ProjectsView.swift`
- `StudioView.swift`
- `OutputsView.swift`
- `SequenceView.swift`
- `ProfileView.swift`
- `SettingsView.swift`
- `Components/`
- `MockData/`
- `Models/`
- `Theme/`

Use mock models such as:

- Project
- GeneratedClip
- SequenceClip
- ActivityItem
- UserProfile

The project must build successfully in Xcode after changes.

---

## Build Requirement

The app must compile and run in Xcode.

The first implementation should replace the default “Hello, world!” screen with the Pannotate tab-based UI.

Do not add external packages unless absolutely necessary.

Use only SwiftUI and standard Apple frameworks for now.

---

## First Version Priority

Priority order:

1. Build successfully
2. Correct tab navigation
3. Main screens represented
4. Visual similarity to screenshots
5. Clean reusable code
6. Placeholder data and assets
7. Easy to extend later

Do not over-engineer backend or real functionality in this version.