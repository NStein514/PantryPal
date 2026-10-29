# PantryPal

A smart pantry and expiration tracker built with Flutter. Scan groceries, track expiration dates, get reminded before food goes bad, and receive AI-generated recipes that use up what's about to expire.

## Features

| Area | What it does | Tech |
|---|---|---|
| Remembered products | Settings → *Remembered products* lists what the app has learned (category, size, usual shelf life, barcode), with search, *Forget* (with Undo) and *Forget all* (also clears cached barcode lookups; the pantry is untouched) | `RememberedProductsScreen` |
| Categories | 22 aisles: fruit & veg, dairy & eggs, meat, fish & seafood, tofu & plant protein, deli & ready meals, bread & bakery, rice/pasta/grains, baking, canned & jarred, sauces/oils/condiments, spices, spreads & sweeteners, snacks & sweets, pantry staples, frozen, drinks, beer/wine/spirits, baby, pet, household, other. Barcode scans file items from Open Food Facts tags (most specific tag first, broad umbrella tags ignored, frozen/canned decided first); typed and receipt items by name (EN/ES/DE/FR) or by the AI, which is told what each category covers | `kCategories`, `ProductLookupService.categoryFromTags`, `guessCategory` |
| Product memory | Everything you add is remembered locally (category, unit, pack size, the barcode it was scanned with, and how long it usually lasts from dates you confirmed). Every scan mode checks it first, so the app gets faster and more accurate with use. Correcting a name once re-links its barcode | `ProductMemoryDb` (own SQLite file) |
| Scan modes | One **Scan** button opens a picker: Barcode, Date label, Type it in — plus batch modes Barcode run and Receipt. Photo-based modes can use the camera or the photo library. (The AI photo-recognition modes were removed; the receipt is the only scan that uses the AI) | `ScanModeSheet` + `startScan` |
| Batch review | Batch scans land on a review screen: edit names, categories, quantities and dates, untick mistakes, then save everything at once | `BatchReviewScreen` + `ScanDraft` + `PantryStore.addAll` |
| Receipt import | Photograph a grocery receipt; the AI expands store abbreviations, merges repeated lines and skips non-food lines | `AiService.parseReceipt` |
| Barcode run | Continuous scanner: scan product after product (rescanning adds another), then review. Unknown barcodes stay in the list for you to name | `BarcodeScreen(continuous: true)` + `draftsFromBarcodes` |
| Date label | Photograph a date stamp; read on-device, offline. Understands numeric dates in the region's order (03/04 = 3 April outside the US), ISO, month names first or last (EN/ES/DE/FR: ENE, MÄRZ, FÉVR, AOÛT…), year-first, and month-only best-befores (03/2027, MAR 2027 → end of March). Keywords (EXP, BB, CAD, MHD, DLC…) bind to the date right after them; every date found is offered as a chip so a wrong pick is one tap to fix. Day-month dates without a year ("MHD 15.03.") are read after a keyword, assuming the next such date. When no date is found, the text the camera did read is shown with *Pick date* / *Try again* | `google_mlkit_text_recognition` + `OcrService.findDates` | `google_mlkit_text_recognition` + `OcrService.parseDate` |
| Local database | Items persist offline, sorted by soonest expiry | `sqflite` |
| Reminders | Local notification at 9:00, two days before expiry | `flutter_local_notifications` |
| Recipes | Ideas from PantryPal's own **on-device recipe engine**: instant, offline, no AI service needed. It reads the pantry (and unchecked shopping-list items as "coming soon"), works out what each item is in cooking terms (EN/ES/DE/FR), fills 25 flexible dishes (frittata, stir-fry, fried rice, pasta, soup, traybake, curry, quesadillas, bowls, shakshuka, chili, risotto, tacos, noodle soup, dal, potato hash, pasta bake, smoothie, porridge, yogurt pot, toastie, baked potatoes, pancakes, fruit bread, crumble) with your actual items, choosing optional ingredients that go together (spinach with feta, mushroom with parmesan), and ranks them by how much soon-to-expire food they use, adjusted by what it has learned you like. Ideas are alternatives, each checked against the whole pantry; a meal plan spends stock day by day so it never needs more than you have. **Build around**, **More ideas** (never repeats; says when there are no more). Cards show time, servings, expiring items used and what's left to buy (items on your list don't count). Tabs: *Ideas* / *Plan* / *Saved* | `RecipeEngine`, `RecipesScreen`, `recipe_planner.dart` |
| Learns your taste | Cooking a dish counts most, then saving it, then planning it; swapping it out of the plan or tapping **Not for me** (with Undo) counts against it. Learning fades over about a month so tastes can change, never outweighs using up food, and never overrides diet or safety. A dish cooked in the last day or two steps back so dinners don't repeat. Stays on the phone; **Settings → Recipe suggestions** resets it | `TasteProfile`, `TasteStore` |
| Recipe preferences | Diet (vegetarian, vegan, gluten-free, dairy-free), servings, time limit, foods to leave out; kept between sessions. Diet and *leave out* also apply to anything suggested to buy. An allergy caution reminds users to check ingredients | `RecipePreferences` + `SettingsRepo` |
| Recipe detail | Ingredients marked *in your pantry* (with the matched item and its expiry) or *to buy*; missing ones go to the shopping list in one tap; steps tick off as you cook | `RecipeDetailScreen` |
| I cooked this | Takes what the recipe used out of the pantry, converting units (250 ml from a 1 L carton), rounding counted items up, adding up repeated ingredients and never going below zero. Amounts the recipe didn't make clear ("2 cups") start unticked so nothing is removed by guesswork | `planDeductions` + `CookSheet` |
| Saved recipes | Bookmark any idea; saved recipes stay on the device and work offline | `SavedRecipes` |
| Meal plan | *Plan* tab: the next 7 days. Add any recipe to a day, or **Plan my week** (3, 5 or 7 days): the engine fills only empty days with dinners (no smoothies or desserts), in the order the food expires, re-checking what's left after each day so the week never plans more than you have. **Swap** replaces one day's meal; tick a meal cooked (cooking it from the plan does this after updating the pantry) | `MealPlanStore`, `MealPlanView` |
| Shopping for the week | One list for every uncooked planned meal. Pantry stock is reserved meal by meal (1 L of milk covers two recipes at 400 ml, the third is short), amounts add up across recipes with unit conversion, staples (salt, pepper, water) are skipped. Ticked items go onto the shopping list as "Milk 0.2 L"; moving them to the pantry keeps the amount and category | `shoppingForPlan`, `WeekShoppingSheet` |
| Barcode | Your own memory first (instant, offline, knows products Open Food Facts doesn't), then Open Food Facts: name in your language when available, brand, pack size (500 g, 1,5 L, 6 x 330 ml). Unknown codes are learned once you name them. Then offers to scan the date label. Open Food Facts answers are cached for 90 days, and older cached answers are used when offline. Barcodes can be read from a saved photo (button in the scanner, or automatically when *Photos* is chosen). 8 s timeout with a "no connection" message; typed codes are checksum-validated. Viewfinder, torch | `mobile_scanner` + `ProductLookupService` + `ProductMemoryDb` |
| Type it in | Autocomplete from your earlier items (fills category, unit, size, usual shelf life), category guessed from the name in EN/ES/DE/FR, "Usually N days" chip, *Save and add another* for quick entry, and **Add several at once**: type a list ("2 x milk", "flour 1 kg", "eggs 12", commas or new lines) and review it like a receipt | `ScanScreen`, `guessCategory` |
| Use / edit | Tap an item → *Used one* (decrements, removes at zero) or *Edit*; reminders are rescheduled | `PantryStore.useOne/update` |
| Configurable reminders | Choose 1–7 days lead time and hour of day; all reminders reschedule | `SettingsRepo` + `SettingsScreen` (gear icon) |
| Shopping list | Add missing recipe ingredients in one tap, check items off, move bought items into the pantry | `ShoppingStore` + `ShoppingDb` |
| Reminder re-sync | All reminders are re-registered on every launch (covers reboot, OS cleanup, timezone change) | `PantryStore.resyncReminders` |
| Notification deep link | Tapping a reminder (warm or cold start) opens the recipe screen | `NotificationService` + `navigatorKey` |
| Home-screen widget | "Use it up" widget (Android + iOS) listing the next items to expire with color-coded days left and expired / use-soon counts. Tap opens the pantry; *Recipes* opens recipe ideas; a ✓ on each counted item marks one as used right from the home screen, even with the app closed (Android; iOS 17+). Days are computed on the device from expiry dates, so it stays right overnight without opening the app | `HomeWidgetService` + `home_widget`, native code in `android/` and `ios/PantryWidget/` |
| Tab bar | On phones the bottom bar is three equal boxes; the selected box is filled (no pill) and its label bold. Each icon acts out its tab when selected, in one colour (the label's), with soft rounded shapes: the **fridge door swings open with a little bounce** and the inside lights up with an apple, a bottle and a box; the **fork and knife tap together with tiny twinkle stars, then lift apart** ready to eat; and a **baguette, a milk bottle and an apple drop into the cart**, each squashing a little as it lands while the cart dips. Overlapping shapes are separated by a thin gap rather than different colours. Deselecting plays it back quickly; reduced motion shows the end state. Drawn in code from the theme, crisp in light and dark mode. Tablets keep a side rail with the same icons and a squared highlight. A light haptic tick on change | `AppNavBar`, `AnimatedNavIcon`, `nav_icon_geometry.dart` |
| Responsive layout | Phones: the three-box bottom bar, one column. Landscape and small tablets (600–839 px): a navigation rail with labels. Large tablets (≥ 840 px): an extended rail; pantry items and recipes flow into columns; a recipe shows ingredients beside its steps. Forms and lists keep a comfortable reading width instead of stretching; sheets are capped at 640 px. Layouts that could overflow with large system text wrap instead | `AppShell`, `lib/ui/` |
| Motion | Tabs cross-fade while keeping their state; Ideas / Plan / Saved fade through; recipe cards and planned meals expand into the recipe (container transform); new ideas ease in; status counts tick over, filters cross-fade, steps and cooked meals check off smoothly; light haptics when you remove or use up an item. All motion switches off when the phone is set to reduce motion | `animations`, `Motion`, `FadeIndexedStack` |
| First run | A three-screen, skippable intro (add what you buy · know what to use first · cook what you have); the empty pantry offers *Scan your first item* | `IntroScreen` |
| Appearance | Settings → Appearance: System, Light or Dark, remembered and applied before the first frame. Light mode is warm off-white, dark mode neutral grey; green is only an accent (primary buttons, selection, progress). Every text colour meets WCAG AA contrast in both modes, the expiry badges included. The launch screens and the Android widget follow light/dark too | `AppTheme`, `ThemeStore`, `tools/palette.py` |
| Languages | English, Spanish, German and French. Follows the device language, or pick one in Settings → Language (also used for reminders and the widget). Dates follow the device region (en_GB → 28 Oct). AI names, recipes and steps come back in the app language; reminders are written in the device language | `flutter gen-l10n` (ARB files in `lib/l10n/`) |
| Duplicate merging | Adding something you already have (same name, same expiry day, compatible unit) tops up the existing item instead of creating a copy, converting units (500 g onto 1 kg → 1.5 kg; 1 lb onto 8 oz). Different expiry dates stay separate so each batch keeps its own reminder | `PantryItem.canMergeWith` + `Unit.convert` |
| Units | Quantities are counts (×2) or amounts (500 g, 1.5 L, 2.31 lb). Measured items get *Used some…* (type an amount or ¼ / ½ / ¾ / All) instead of *Used one*. The AI reports units, so sold-by-weight receipt lines arrive as weights | `Unit` + `PantryStore.useAmount` |
| Backup & restore | Settings → *Export backup* shares a JSON file (pantry, shopping list, reminder settings, remembered products) via the share sheet; *Import backup* restores it, choosing **Merge** or **Replace**. Merging memory keeps what this phone already knows and fills gaps. v1 backups still import | `BackupService` + `BackupFiles` (`share_plus`, `file_picker`) |
| Pantry list | Status cards (Expired / Use soon / Fresh) that double as filters, search, category chips, sections by status, color-coded days-left badge, swipe to remove with Undo | Material 3 + `provider` |
| Navigation | Bottom tabs: Pantry, Recipes, Shopping (badge shows items left to buy). Tabs build on first visit, so recipes only call the AI when opened | `AppShell` |
| Add / edit form | Category picker, quantity stepper, quick date chips (+3 days … +1 month), clear date, "estimated" note on AI shelf-life dates | `ScanScreen` |

## Architecture

```
lib/
  main.dart                       App entry point (the only main.dart) – wires providers
  models/pantry_item.dart         Immutable item model, daysLeft, map (de)serialisation
  data/pantry_db.dart             sqflite persistence (CRUD); v2 adds `unit`; v3 re-files misclassified items once
  data/settings_repo.dart         Reminder preferences (shared_preferences)
  data/shopping_db.dart           Shopping-list persistence (own SQLite file)
  models/recipe.dart              Typed recipe + ingredients (amount, unit, pantry link); tolerant parsing
  models/recipe_preferences.dart  Diet, servings, time limit, foods to avoid → prompt rules
  models/taste_profile.dart       What the engine has learned (signals, monthly fade, recent cooking, hidden ideas)
  models/meal_plan.dart           Planned meals by day (immutable plan; JSON; pruning; empty days)
  models/reminder_settings.dart   Lead days + hour value object
  models/categories.dart          The 22 categories, what each covers (for the AI), name-based guessing, normalizeCategory
  models/unit.dart                Unit enum (count, g, kg, ml, L, oz, lb), conversion, tolerant parse, pack-size parser
  models/known_product.dart       A remembered product (category, unit, size, barcode, usual shelf life)
  models/barcode.dart             EAN/UPC check-digit validation
  models/widget_action.dart       Strict parsing of widget button links (pantrypal://used?id=12)
  models/quick_list.dart          Parses typed lists ("2 x milk, flour 1 kg") into review drafts
  data/product_memory_db.dart     Product memory (SQLite): by barcode, by name, autocomplete, learning; v2 adds the barcode lookup cache
  l10n/app_*.arb                  UI strings: en (template), es, de, fr
  l10n/l10n.dart                  context.l10n, labels for stored keys, locale/date-order helpers
  models/scan_mode.dart           The scan modes (label, batch?, uses a photo?)
  models/scan_draft.dart          Editable unsaved item from a scan; fromAi() handles printed vs estimated dates
  services/
    ai_service.dart               Receipt reading via Claude through a proxy; 45 s timeout; injectable http client
    recipe_engine.dart            On-device recipe engine: ingredient roles, 25 dishes in 4 languages, flavour pairing, scoring, taste, selection
    ocr_service.dart              ML Kit OCR + expiration-date parsing
    product_lookup_service.dart   Open Food Facts barcode lookup + category mapping
    notification_service.dart     Schedules/cancels expiry reminders
    recipe_planner.dart           Ingredient ↔ pantry matching, have/buy check, cooking deductions
    meal_shopping.dart            The week's shopping list with pantry stock reserved across meals
    batch_scan.dart               Barcode run → review drafts; lookupWithCache (cache → network → stale cache)
    backup_service.dart           Backup JSON encode/decode + validation (pure Dart)
    backup_files.dart             Share sheet export + file picker import
    home_widget_service.dart      Builds the widget payload, publishes it, handles widget taps
    widget_actions.dart           Background callback for widget buttons; applyWidgetAction
  state/pantry_store.dart         ChangeNotifier: DB + notifications orchestration
  state/shopping_store.dart       ChangeNotifier: shopping list (dedupe, check, clear)
  state/locale_store.dart         In-app language choice (null = device), persisted
  state/taste_store.dart          The learned taste, persisted on the device
  state/meal_plan_store.dart      The meal plan, persisted; past days dropped on load
  screens/
    app_shell.dart                Bottom-navigation tabs
    home_screen.dart              Pantry tab: summary, search, filters, grouped list
    scan_mode_sheet.dart          Mode picker + startScan() flow router
    intro_screen.dart             First-run intro
    scan_screen.dart              Single-item add/edit form (can auto-start a scan)
    quick_list_screen.dart        "Add several at once" typed list → batch review
    remembered_products_screen.dart  Review / forget what the product memory has learned
    barcode_screen.dart           Single or continuous barcode scanner
    batch_review_screen.dart      Review and save batch scan results
    recipes_screen.dart           Ideas / Plan / Saved, build-around, preferences, more ideas
    meal_plan_view.dart           Plan tab: 7 days, plan my week, swap, week shopping, add-to-plan
    recipe_detail_screen.dart     Have vs buy, steps, I cooked this (CookSheet)
    recipe_preferences_sheet.dart Diet, servings, time, avoid
    shopping_screen.dart, settings_screen.dart
  ui/breakpoints.dart             Window size classes, column counts (pure)
  ui/motion.dart                  Motion timings honouring reduce-motion; FadeIndexedStack; FadeSlideIn
  ui/app_nav_bar.dart             The three-box bottom bar
  ui/nav_icons.dart               Animated tab icons (painter)
  ui/nav_icon_geometry.dart       Their shapes and motion as plain numbers (tested on their own)
  ui/layout.dart                  ReadableWidth, AdaptiveColumns
  theme/app_theme.dart            Light (off-white) and dark (grey) colour schemes, generated from tools/palette.py
  state/theme_store.dart          Light / dark / system, persisted
  widgets/                        ExpiryBadge, category icons, QuantityStepper/UnitDropdown, Used-some dialog, friendly scan errors
test/                             Unit + widget tests (mirrors lib/)
tools/proxy.mjs                   Dev proxy that holds your Anthropic API key
tool/probe_recipe_engine.dart     Prints what the recipe engine suggests for sample pantries
tools/palette.py                  The two palettes + a WCAG contrast check (python3 tools/palette.py)
tools/set_identity.py             Sets bundle id / App Group / Apple team (and free-account mode) everywhere
android/                          Configured Android project; widget in app/src/main/kotlin/app/pantrypal/
ios/                              Configured Xcode project: Runner + PantryWidgetExtension, Identity.xcconfig
```

Data flow: `Screen → PantryStore → (PantryDb, NotificationService)`; screens call `AiService` / `OcrService` directly for scanning and recipes.

Scan flow: `Scan` → `ScanModeSheet` → `startScan(mode)`. Single-item modes open `ScanScreen(initialMode:)`, which starts the capture itself. Batch modes capture first (continuous barcode screen or one photo), then open `BatchReviewScreen` with a `load` callback that produces `ScanDraft`s; it shows progress, errors with retry, and saves via `PantryStore.addAll`. Services take their dependencies by constructor, which is what makes them testable without devices or network.

## Getting started

The `android/` and `ios/` projects are included and fully configured (permissions, notification receivers, the home-screen widget on both platforms, ML Kit's iOS settings, App Groups, the app icon). There is no `flutter create` step and nothing to set up by hand in Xcode or Android Studio.

**Prerequisites:** a current stable Flutter (3.27 or newer), Java 17 (bundled with Android Studio), Android Studio and/or Xcode 15+ with CocoaPods, Node 18+ for the AI proxy (only needed for the receipt scan).

1. **Fetch packages** (also generates the translations):
   ```bash
   flutter pub get
   ```
2. **Optional: start the AI proxy** (only the receipt scan uses it; recipes work without it). It keeps your Anthropic key off the device:
   ```bash
   ANTHROPIC_API_KEY=sk-ant-... node tools/proxy.mjs
   ```
   Without the proxy, everything except the receipt scan works: a plain `flutter run` is enough to try recipes and meal planning.
3. **Android** — phone with USB debugging on, or an emulator (Android 7.0+):
   ```bash
   flutter run --dart-define=AI_PROXY_URL=http://10.0.2.2:8787/v1/messages        # emulator
   flutter run --dart-define=AI_PROXY_URL=http://<your-computer-LAN-IP>:8787/v1/messages  # phone on the same Wi-Fi
   ```
4. **iOS** — test on a **physical iPhone** (iOS 15.5+): the scanner needs a real camera, and Google ML Kit's iOS libraries don't support Apple-silicon simulators.
   1. Give the app an identity Apple will accept. Bundle ids are unique worldwide, so use your own, and your team id from Xcode → Settings → Accounts:
      ```bash
      python3 tools/set_identity.py --bundle-id com.yourname.pantrypal --team ABCDE12345
      ```
      With a **free Apple ID** (Personal Team), add `--free-account`: App Groups require a paid developer account, so this turns them off. Everything works except that the home-screen widget can't show pantry data.
   2. On the iPhone, turn on Settings → Privacy & Security → **Developer Mode** (iOS 16+).
   3. Run:
      ```bash
      flutter run --dart-define=AI_PROXY_URL=http://<your-computer-LAN-IP>:8787/v1/messages
      ```
      The first time, iOS may ask you to trust the developer: Settings → General → VPN & Device Management.
   4. If signing still complains, open `ios/Runner.xcworkspace` in Xcode once and check *Signing & Capabilities* for both the **Runner** and **PantryWidgetExtension** targets (*Automatically manage signing* is already on).

**What's in the native projects**

| | Android (`android/`) | iOS (`ios/`) |
|---|---|---|
| Identity | `applicationId` in `app/build.gradle.kts` (Kotlin package `app.pantrypal`) | `Flutter/Identity.xcconfig`: bundle id, App Group, team, entitlements, used by every target |
| Toolchain | Gradle 8.14.3, AGP 8.11.1, Kotlin 2.2.20, Java 17, `minSdk` 24, core-library desugaring | iOS 15.5 (ML Kit), CocoaPods (`Podfile` incl. ML Kit's `post_install` settings) |
| Permissions | camera, notifications, boot-completed | camera and photo-library usage strings, `pantrypal://` URL scheme |
| Reminders | flutter_local_notifications receivers (incl. reboot) | notification-center delegate in `AppDelegate` |
| Widget | `PantryWidgetProvider` + layout, home_widget background receiver/service | `PantryWidgetExtension` target (WidgetKit), `UseOneIntent` in both targets, App Group entitlements, plugin registrant for the background engine |
| Icon | legacy + round, adaptive (foreground/background) with a themed monochrome layer (Android 13+), white status-bar icon, launch logo | full AppIcon set (opaque, all sizes), launch image |

The versions were chosen to sit inside what current Flutter accepts (its Gradle plugin refuses Gradle < 8.14, AGP < 8.11.1, Kotlin < 2.2.20) while still working on older stable releases. The iOS project uses the classic `FlutterAppDelegate` rather than the newer `UIScene` setup, which only exists in recent Flutter versions.

## Home-screen widget

Set up in both native projects already: long-press the home screen → Widgets → **PantryPal** (Android), or edit the home screen → **+** → PantryPal (iOS). Open the app once first, so it can publish data and register the button callback.

**Interactive buttons (✓ = used one).** The tap runs `widgetInteractivityCallback` (`lib/services/widget_actions.dart`) in a background Flutter engine: it opens the same database, applies *used one*, reschedules that item's reminder, and republishes the widget. Measured items (500 g flour) have no ✓, since the widget can't ask "how much"; they open the app. The app reloads the pantry when it returns to the foreground. Android: any version. iOS: 17+ (`UseOneIntent`, an AppIntent compiled into both targets; it can wake the app if it isn't running).

**How it stays current.** The app republishes whenever the pantry changes and when it returns to the foreground. The payload holds expiry *dates* and pre-translated labels (with correct plurals for 0–14 days); the native code works out days-left itself. Android refreshes hourly (`updatePeriodMillis`), iOS schedules a timeline entry at midnight.

**App Group.** iOS shares widget data through the App Group in `ios/Flutter/Identity.xcconfig`; the Dart side uses the same id (`HomeWidgetService.appGroupId`). `tools/set_identity.py` keeps them in step.

## Languages

Strings live in `lib/l10n/*.arb`; `flutter pub get` generates `lib/l10n/app_localizations*.dart` (`generate: true` in `pubspec.yaml`, settings in `l10n.yaml`). Do not edit the generated files.

To add a language, copy `app_en.arb` to `app_<code>.arb`, set `@@locale`, translate the values (keep `{placeholders}` and plural structure; skip the `@key` metadata), set `aiLanguage` to the language's English name, add its native name to `languageNativeName` in `lib/l10n/l10n.dart`, and (optionally) an `android/app/src/main/res/values-<code>/widget_strings.xml` for the widget picker. Then run `flutter pub get`; it appears in Settings → Language automatically. `test/l10n/l10n_test.dart` fails if keys or placeholders drift between files.

Stored values stay language-neutral: categories are saved as English keys (`Dairy`) and displayed through `categoryLabel`, so changing the phone's language never rewrites data or backups.

## Configuration

| Setting | Where | Default |
|---|---|---|
| `AI_PROXY_URL` | `--dart-define` | `http://10.0.2.2:8787/v1/messages` |
| AI model | `_model` in `ai_service.dart` | `claude-sonnet-4-6` |
| Reminder lead time / hour | Settings screen (gear icon) | 2 days / 9:00 |

## Testing

### Verification status

- **Static analysis, whole project:** `lib/` and `test/` (screens and widget tests included) analyze with **0 errors, 0 warnings** against the Flutter framework and the exact plugin, `cross_file`, `test_api` and `matcher` versions the pubspec resolves, with `flutter_lints` applied. The one remaining note is `DropdownButtonFormField.value` being deprecated on Flutter ≥ 3.33; it still works, and switching to `initialValue` would break older Flutter versions.
- **Executed:** the logic, data and service tests (date reader, pack-size/list/barcode parsing, categories, AI and Open Food Facts clients, backups, product memory and lookup cache against real SQLite incl. schema upgrades, barcode runs): **113 tests, all passing** on a real Dart VM.
- **Native projects:** `ios/Runner.xcodeproj` parses with mod-pbxproj; all 82 objects are defined once with no dangling references, and every referenced file exists (except the three Flutter generates). Android XML and iOS plists/entitlements all parse, and every Android resource reference resolves. Icons were checked at every size (iOS: exact pixel size, no alpha; Android adaptive art inside the 66dp safe circle). Neither project has been built with Gradle or Xcode here.
- **Native widget code:** the Android `PantryWidgetProvider.kt` compiles with kotlinc 2.0 against signature stand-ins for the Android/org.json APIs it uses, home_widget 0.7.0's exact signatures, and an `R` generated from the real layout (the check was confirmed to reject a wrong view id and argument type). The Swift (WidgetKit + `UseOneIntent`) has **not** been compiled; build it in Xcode.
- **Not yet executed:** widget tests (they need the Flutter engine). Run `flutter test` before release; they compile cleanly.

`tool/probe_scan_parsers.dart` prints what the parsers make of messy input. Paste real OCR text or typed lists into it when tuning.


```bash
flutter test            # all tests
flutter test --coverage # coverage in coverage/lcov.info
flutter analyze         # lints (flutter_lints)
```

| Test file | Covers |
|---|---|
| `models/unit_test.dart` | Unit parsing (aliases, stored names), conversion and dimension checks, number and quantity formatting, pack sizes (g, L, cl, fl oz, lb, multipacks) and where they sit in the text |
| `services/home_widget_payload_test.dart` | Widget payload: soonest-first ISO dates, undated items excluded, plural day labels (en/es), translated chrome, item cap, tap routing, item ids and which rows get ✓ |
| `models/widget_action_test.dart` | Widget button links: round trip, iOS's extra query, rejection of anything else |
| `services/widget_actions_test.dart` | Used one from the widget: decrement, remove at zero, measured items and unknown ids left alone |
| `l10n/l10n_test.dart` | ARB files in sync (keys + placeholders), `l10nFor` fallback, labels, locale date order, language list order, German/French plurals, the pantry rendered in Spanish and German |
| `state/locale_store_test.dart` | Language choice persists, drives the global override used by notifications/widget, returns to system default, ignores unsupported codes |
| `services/backup_service_test.dart` | Backup round-trip, rejection messages and problem codes (not JSON / not a backup / newer version), skipping bad entries, settings clamping, remembered products (v2) incl. v1 compatibility and clean-up |
| `screens/remembered_products_screen_test.dart` | Empty state, list + search, forget with Undo, Forget all with confirmation |
| `screens/settings_screen_test.dart` | Resetting learned taste (disabled until there is something, cancel, confirm), appearance (system/light/dark) and its persistence, language picker, backups carrying remembered products both ways, Remembered products entry, export contents, import Replace vs Merge, invalid file message (fake `BackupFiles`) |
| `models/pantry_item_test.dart` | `daysLeft` (null, today, expired, time-of-day), `status` buckets, duplicate matching and unit-converting merges, `copyWith(clearExpiry:)`, map round-trip incl. unit, legacy rows without unit |
| `data/shopping_db_test.dart` | Real SQLite: unchecked-first ordering, check/uncheck, delete, delete-checked |
| `state/shopping_store_test.dart` | Case-insensitive dedupe + trimming, toggle, remove, clear checked, `restore` |
| `screens/shopping_screen_test.dart` | Empty state, add, check, move to pantry |
| `data/pantry_db_test.dart` | Real SQLite (FFI): ordering with null expiry, update, delete, decimal quantities, **v1 → v2 and v2 → v3 migrations** (re-filing) |
| `data/settings_and_cache_test.dart` | Settings defaults/round-trip, recipe cache round-trip + corruption, `reminderTime` incl. month boundary |
| `models/taste_profile_test.dart` | Signals and cap, 30-day fade, recent cooking by calendar day, hide and undo, JSON and pruning, recipes keeping their dish |
| `services/recipe_engine_test.dart` | Learned taste lifts a favourite but not the day after it was cooked; Not for me hides; disliking nudges rather than bans; taste never overrides diet; flavour pairing; dal uses lentils; all 25 dishes in 4 languages; expiring food first; never expired meat/dairy (every dish checked); vegan with nothing animal suggested to buy; leave-out, time limit, servings; realistic amounts in each item's unit; build-around; more ideas never repeat and run out; a week of dinners that never plans more than you have; shopping-list items; natural titles; every dish in all 4 languages with no placeholders left; works with cooking deductions and the week's shopping; empty or unusable pantries |
| `screens/recipes_screen_test.dart` | Not for me with Undo, cooking and saving teaching the engine, ideas appear at once with no network, empty pantry, more ideas until they run out, build-around, preferences applied and kept, saving, detail (in pantry / on your list / kitchen basics), I cooked this |
| `ui/nav_icon_geometry_test.dart` / `ui/app_nav_bar_test.dart` | Fridge closed→open with a small bounce and light, fork and knife meeting without crossing (with twinkles) then lifting apart, cart filling with three groceries that squash on landing and never leave the icon while the cart dips and settles; three equal boxes with only the selected one filled, tap → icon mid-animation → settled, screen-reader button and selected state, reduced motion jumps to the end |
| `ui/breakpoints_test.dart` / `ui/responsive_test.dart` | Switching away from Shopping while typing or right after swiping an item (no errors, focus released, hidden tabs offstage); size classes and columns; bottom bar vs rail vs extended rail at real sizes; pantry and scan form at 320 px with 200 % text (no overflow); ingredients beside steps on wide screens; reduce motion; fading tabs keep state and block taps; intro next/skip/get started |
| `theme/app_theme_test.dart` | Both palettes re-checked for WCAG AA in Flutter's own luminance maths, neutral (untinted) surfaces, off-white vs grey, badge text contrast |
| `models/meal_plan_test.dart` | Day keys across month ends, add/remove/replace/cooked, empty days, pruning, JSON with junk |
| `services/meal_shopping_test.dart` | Stock reserved across meals, missing items adding up across recipes and units, staples skipped, labels the shopping list reads back |
| `screens/meal_plan_test.dart` | Plan my week fills only empty days with dinners, swap, week shopping reserving stock, cooked meals leaving the list, add-to-plan from a recipe, cooking from the plan, bought items keeping amount and category |
| `models/recipe_test.dart` | Recipe parsing (modelled and unmodelled units, pantry ids, old cache format), JSON round-trip, de-duplication, preferences → prompt rules |
| `services/recipe_planner_test.dart` | Name matching (plurals, extra words, no partial overlaps), trusting/rejecting the AI's pantry ids, soonest-expiring tie-break, have/buy split, deductions: unit conversion, rounding, capping, unknown amounts, repeated ingredients |
| `services/ocr_service_test.dart` | Date formats (ISO, numeric, 2-digit year, month names first/last/year-first, ES/DE/FR months, month-only → end of month, day-month without a year after keywords), keyword binding (same line and line above) and ranking, OCR noise and separator clean-up that leaves sizes and lot codes alone, invalid and non-existent dates, day-first order, duplicates |
| `data/product_memory_db_test.dart` | Real SQLite: remembering, case-insensitive names, barcode lookup and re-linking, shelf-life learning (confirmed dates only, averaged), most-used ordering, lookup cache (per language, max age), v1 → v2 upgrade, v2 → v3 (stale lookups dropped, drinks-that-are-food re-filed), forget/clear, merge vs replace import incl. barcode clashes |
| `models/quick_list_test.dart` | Typed lists: counts before/after/in parentheses, "2x", dozens (EN/ES/DE/FR), sizes anywhere, multipacks, separators vs decimal commas, bullets, remembered products |
| `screens/quick_list_screen_test.dart` | Add several: empty-list message, review, save all |
| `models/barcode_test.dart` / `models/categories_test.dart` (36 everyday items, 4 languages, one-time re-filing rules) | Check digits for EAN-13/UPC-A/EAN-8; category guessing in four languages, overlaps, whole-word short keywords, specific-name overrides (peanut butter, butternut) |
| `screens/scan_screen_test.dart` | Type it in: category guess, autocomplete from memory (category, unit, usual shelf life), Save and add another, empty-name message |
| `widgets/scan_errors_test.dart` | Offline / timeout / AI-down messages |
| `services/product_lookup_service_test.dart` | Barcode lookup success, unknown/blank/HTTP-error cases, category mapping incl. 18 real Open Food Facts tag lists (rice, oil, juice, canned tuna, baked beans…), localized name, brand, pack size, timeout |
| `services/ai_service_test.dart` | Receipt call and `{"items":[…]}` wrapper, language instruction, HTTP errors, and a proxy that never answers failing with a timeout instead of hanging |
| `state/pantry_store_test.dart` | Add/update/remove, `useOne`, reminder scheduling/cancellation, `setReminders`, `resyncReminders`, `addAll`, `useAmount`, `restore` (merge/replace), merging duplicates on add, settings restore, listener notification (fake DB + notifications) |
| `screens/home_screen_test.dart` | Empty state, item rendering, days-left badge, *Used one* flow, search + status filters, swipe + Undo, scan mode picker, *Used some…* for measured items |
| `screens/batch_review_screen_test.dart` | Save ticked drafts, naming an unknown barcode, unticking, error + retry, empty result |
| `models/scan_draft_test.dart` | Printed vs estimated expiry, category/quantity normalisation, `isSavable`, `toItem`, drafts from remembered products, AI alternatives |
| `services/batch_scan_test.dart` | Barcode run drafts: order, counts, unknown and failed lookups, memory-first (no network), pack size × count, `lookupWithCache` (reuse, stale fallback offline, refresh, rethrow) |

`data/pantry_db_test.dart` uses `sqflite_common_ffi`, which needs the SQLite library on the host (Linux: `sudo apt install libsqlite3-dev`; macOS/Windows work out of the box).

Not covered yet: `AppShell` widget, the Barcode/Date-label flows inside `ScanScreen` (they need the camera; their logic is tested underneath), the native widget code (Kotlin/Swift; check on a device), the real share sheet / file picker, camera/ML Kit flows (device-only), `ScanScreen`/`BarcodeScreen` widgets, and `main.dart` (initialises native plugins).

## Privacy & security

- **Never embed an Anthropic API key in the app.** All AI calls go through your proxy; add authentication and rate limiting before exposing it publicly.
- Barcode numbers are sent to Open Food Facts (public API) when you scan one.
- The only photo sent to the AI is a **receipt** you choose to import; it may show store, time and payment details and is sent as-is. Barcode and date-label scanning stay on the device.
- Recipes are made on the device: the pantry, your preferences and what the app learns about your taste never leave the phone.
- The home-screen widget shows item names on your home screen. Its data sits in app-private storage (Android) or your App Group (iOS).
- Pantry data, product memory, reminder settings, recipe preferences, saved recipes and the last recipe set are stored locally only. Backups include the product memory but not cached barcode lookups (they're re-fetched).
- You can review and delete everything the app has learned under Settings → Remembered products. Backups are plain, unencrypted JSON and only leave the device where you send them from the share sheet.

## Known limitations

- Labels are cleaned up before reading: OCR letters inside numbers (`2O27`, `3l.12`), spaces around separators, and month names joined by `-`, `/` or `.`. A keyword alone on a line applies to the date on the next line. Numeric dates use the device region's order; a label printed in another convention (an imported product) can still be misread. Every date found is offered as a chip, so check ambiguous ones.
- Day-month dates without a year are only read right after an expiry keyword, and the year is assumed; it's marked "(year assumed)".
- In typed lists, "2 x 1 kg flour" reads as a 2-pack (×2), not 2 kg.
- **Categories after updating:** on first launch, items wrongly filed as *Drinks* (older barcode rules filed rice, pasta and oil there) are moved to the right food category, and *Pantry* items that now have a specific shelf (flour → Baking) are moved too. Items in any other category are left as you set them. Cached barcode lookups are cleared and re-fetched.
- Category guessing from typed names is a keyword list, not a model; it only suggests until you pick a category.
- AI shelf-life values are estimates and not food-safety guidance; they are labelled "est." in the review screen and form.
- Receipt results depend on photo quality; always check the review screen before saving.
- Recipe ideas come from 25 flexible dishes and an ingredient vocabulary in four languages; items it doesn't recognise fall back to their category, and very unusual pantries may get few ideas. Diet and *leave out* rules apply to what the engine recognises, so check ingredients if you have allergies, and use your own judgement on expired food.
- Pantry matching for recipes is by name (plurals and extra words handled); unusual names may need the AI's pantry link, which is accepted only when the names plausibly fit.
- Merging needs an exact name match after trimming and lower-casing ("Milk" and "Whole milk" stay separate). Counted items never convert to weights. *Used some* works in the item's own unit.
- Learned taste isn't part of backups yet; a restored phone starts learning afresh.
- The in-app Appearance setting changes the app; the home-screen widgets and launch screens follow the phone's own light/dark setting.
- The widget's days-left labels cover 0–14 days (the window it lists); languages with more than one/other plural forms get them right because labels are generated in Dart. It updates immediately after an in-app language change, and on next app open after a device-language change. The iOS widget's own picker name/description is English only.
- English, Spanish, German and French. The Spanish/German/French translations were written without a native-speaker review; AI output quality per language depends on the model.
- Reminders already scheduled are rewritten when you change the language in Settings; a device-language change is picked up the next time the app opens.
- Barcode-run items get no expiry date (Open Food Facts has no shelf-life data); add dates in the review screen.
- Reminders are re-synced when the app launches; after a timezone change they may be off until the next launch.

## Roadmap

Done: barcode lookup, edit/used-one flow, notification tap → recipes.
Done also: offline recipe cache, configurable reminders, sqflite integration tests, reminder re-sync, shopping list.
Done also: scan mode picker, receipt import, haul photo, barcode run, batch review, tabbed navigation, pantry search/filters, swipe Undo.
Done also: unit-aware quantities (with DB migration), backup export/import.
Done also: localization (English + Spanish), region-aware OCR dates, duplicate merging with unit conversion.
Done also: home-screen widget (Android + iOS).
Done also: in-app language setting, German and French.
Done also: scan modes upgrade (product memory, barcode/photo/date-label/type-it-in improvements).
Done also: barcode from photo + offline lookup cache, no-date fallback and year-less dates, Add several at once.
Done also: removed the AI photo and haul-photo scan modes; recipe system v2 (typed recipes, local pantry check, I cooked this, preferences, build-around, more ideas, saved recipes).
Done also: real execution of the scan logic (106 tests), fixing OCR-noise, separator, keyword-above, list-count and category bugs it exposed.
Done also: product memory in backups (format v2), Remembered products screen; whole-project static analysis clean.
Done also: interactive widget (✓ used one) on Android and iOS 17+.
Done also: configured android/ and ios/ projects (no manual native setup), PantryPal app icon on every platform and size, identity script.
Done also: 22 categories; barcode classification rewritten (rice no longer a drink) with one-time repair of stored items.
Done also: meal plan (plan my week, swap, cooked), shopping for the week with stock reservation, bought items keeping amounts.
Done also: light/dark mode setting with off-white and grey palettes (WCAG AA), accessible expiry colours, theme-aware launch screens and widget.
Done also: responsive layout (bar/rail, columns, two-pane recipes, readable widths), Material motion with reduce-motion support, first-run intro.
Done also: on-device recipe engine (recipes no longer need the AI proxy), tab-switching fix, AI request timeout.
Done also: recipe engine learns from what you cook, save, plan and turn down; 25 dishes; flavour pairing; ideas vs plans.
Done also: three-box tab bar with animated fridge, utensils and cart icons.
Next: first device builds on Android and iOS · run the widget tests with `flutter test` · native-speaker review of translations.
