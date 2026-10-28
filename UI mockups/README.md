# ReceiptLedger Design Specifications & UI Assets

This directory serves as the centralized, technical repository for ReceiptLedger's visual design system, vector icon tokens, screen mockups, UX reference benchmarks, and sprint deliverable evidence.

---

## 1. Directory Structure

```text
UI mockups/
├── README.md                          # Technical design system specification (this document)
├── icons/                             # Vector brand & navigation SVG assets
│   ├── app_icon.svg                   # Primary brand logo mark (Ledger + Receipt glyph)
│   ├── capture_icon.svg               # OCR camera & receipt scanner navigation icon
│   ├── ledger_icon.svg                # Expense log & history ledger navigation icon
│   ├── review_icon.svg                # Human-in-the-loop review queue navigation icon
│   └── settings_icon.svg              # User profile & system preferences icon
├── mockups/                           # High-fidelity screen wireframes & mockups
│   ├── core/                          # Primary production screen specifications
│   │   ├── capture_screen.png         # Receipt scan & camera capture interface
│   │   ├── ledger_screen.png          # Categorized transactions & monthly spend ledger
│   │   ├── review_screen.png          # Bounding-box verification & confirmation flow
│   │   └── settings_screen.png        # Preferences, dark mode, & security settings
│   └── variations/                    # Exploratory design variations (V1 – V4)
├── reference_designs/                 # High-end UX benchmarks & design inspiration
│   ├── leafora_design_benchmark.jpg   # Warm organic palette, pill navigation, & card elevation
│   └── verification_flow_wireframe.png# Human-in-the-loop verification card flow
└── sprint_deliverables/               # Project management & Jira sprint evidence
    ├── sprint_1_scrum_17_overview.png # SCRUM-17 completion & acceptance criteria overview
    ├── sprint_1_subtasks_deliverables.png # SCRUM-53 to SCRUM-56 deliverables & attachments
    └── sprint_1_jira_board_status.png # Jira board status (SCRUM-17 Done, backlog progress)
```

---

## 2. Design System Tokens & Aesthetics

ReceiptLedger employs an **Organic Botanical Ledger** aesthetic—a synthesis of classical financial accounting warmth and modern luxury Scandinavian minimalism.

### Color Tokens

| Token Name | Hex Code | Purpose & Usage |
| :--- | :--- | :--- |
| `forestPrimary` | `#1E3A2B` | Brand identity, primary buttons, active pill navigation, strong text |
| `forestLight` | `#2D543F` | Dark mode accents, hovered primary interactive states |
| `forestDeep` | `#0E1B14` | High-contrast elements, brand headers |
| `sageAccent` | `#4A7C59` | Subtle highlights, icons, verified confidence indicators |
| `sageLight` | `#E8EFE9` | Soft chip backgrounds, badge containers, secondary buttons |
| `sageMuted` | `#C2D6C6` | Borders on subtle elevated cards |
| `canvasLight` | `#F8F9F5` | Warm linen background surface (Light mode canvas) |
| `canvasDark` | `#0F1713` | Deep obsidian pine surface (Dark mode canvas) |
| `cardWhite` | `#FFFFFF` | Light mode card background |
| `cardDark` | `#17231C` | Dark mode card background |
| `cardDarkElevated` | `#1E2D24` | Elevated inner containers in Dark mode |
| `borderLight` | `#E5EAE3` | Subtle 1px dividers and borders (Light mode) |
| `borderDark` | `#25352B` | Subtle 1px dividers and borders (Dark mode) |
| `greenVerified` | `#16A34A` | High confidence OCR match (>95%), verification pill |
| `amberWarning` | `#D97706` | Medium confidence review items (70–94%), offline indicators |
| `badgeRed` | `#DC2626` | Unresolved queue badge, destructive actions |

### Typography

- **Headings & Brand Title**: High-contrast, clean sans-serif with tight letter-spacing (`-0.6px` to `-0.8px`), weights `800` (Extrabold) and `900` (Black).
- **Body & Currency Figures**: Clean legible numerical alignment with weights `500` (Medium) to `700` (Bold).
- **Micro-labels & Badges**: Uppercase tracked typography (`letterSpacing: 0.8` to `1.2px`), weight `800`, font size `10`–`11px`.

---

## 3. Screen Specifications & Features

1. **Splash Screen ([`splash_screen.dart`](file:///c:/Users/Asad/Desktop/ReceiptLedger/mobile/lib/screens/splash_screen.dart))**:
   - Concentric ambient glowing rings with breathing scale animation (`Tween 0.96 -> 1.05`).
   - Live telemetry status ticker reporting backend connectivity.
   - Smooth animated progress bar with manual bypass ("Tap to Continue →").

2. **Authentication Screen ([`auth_screen.dart`](file:///c:/Users/Asad/Desktop/ReceiptLedger/mobile/lib/screens/auth_screen.dart))**:
   - Sliding pill tab switcher between **Sign In** and **Create Account**.
   - 1-Click Instant Demo Credentials (`user@receiptledger.com` / `demo1234`).
   - Client-side RFC email validation, currency selector dropdown, and biometric toggles.
   - Zero keyboard clipping via `SingleChildScrollView` and `Flexible` labels.

3. **Receipt Capture Screen ([`upload_screen.dart`](file:///c:/Users/Asad/Desktop/ReceiptLedger/mobile/lib/screens/upload_screen.dart))**:
   - Hero scan card with camera and gallery integration.
   - Hidden tuning modal for high-res OCR modes and auto-crop toggles.
   - Horizontal category filter chips with interactive hover scaling.
   - Bottom padding of `110px` ensuring zero occlusion from the floating navigation bar.

4. **Financial Ledger Screen ([`ledger_screen.dart`](file:///c:/Users/Asad/Desktop/ReceiptLedger/mobile/lib/screens/ledger_screen.dart))**:
   - Period-based spend aggregation (Weekly, Monthly, Annual).
   - Custom-painted bezier sparkline graph with interactive day selector.
   - Expandable receipt tiles with itemized line items and tax breakdown.

5. **Review Queue Screen ([`review_screen.dart`](file:///c:/Users/Asad/Desktop/ReceiptLedger/mobile/lib/screens/review_screen.dart))**:
   - Split verification interface: cropped receipt snippet vs. extracted OCR form fields.
   - Confidence score indicators and multi-category reclassification pills.
   - One-tap "Confirm to Ledger ✓" and batch "Edit All Line Items" modal.

---

## 4. Asset Inventory

| File Path | Description | Dimensions / Format |
| :--- | :--- | :--- |
| `icons/app_icon.svg` | Official Vector App Mark | Scalable Vector Graphic |
| `icons/capture_icon.svg` | Camera / Scanner Glyphs | Scalable Vector Graphic |
| `icons/ledger_icon.svg` | Account Book Glyphs | Scalable Vector Graphic |
| `icons/review_icon.svg` | Triage / Verification Glyphs | Scalable Vector Graphic |
| `icons/settings_icon.svg` | System Settings Glyphs | Scalable Vector Graphic |
| `mockups/core/capture_screen.png` | Camera Scanner Wireframe | High-Res PNG |
| `mockups/core/ledger_screen.png` | Financial Ledger Wireframe | High-Res PNG |
| `mockups/core/review_screen.png` | Line Item Review Wireframe | High-Res PNG |
| `mockups/core/settings_screen.png` | User Preferences Wireframe | High-Res PNG |
| `reference_designs/leafora_design_benchmark.jpg` | Organic Aesthetic Benchmark | High-Res JPEG |
| `reference_designs/verification_flow_wireframe.png` | Human-in-the-Loop Flow Wireframe | High-Res PNG |
| `sprint_deliverables/sprint_1_scrum_17_overview.png` | SCRUM-17 Sprint Acceptance Evidence | High-Res PNG |
| `sprint_deliverables/sprint_1_subtasks_deliverables.png` | Subtasks (SCRUM-53–56) & Docs | High-Res PNG |
| `sprint_deliverables/sprint_1_jira_board_status.png` | Backlog & Sprint Progress Board | High-Res PNG |
