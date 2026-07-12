# Android File Manager — Implementation Plan

**Stack:** Flutter (UI + Dart logic) + Java (Android native layer via Platform Channels)
**Target:** Android only
**Status:** 🟡 Not started
**Last updated:** 2026-06-19

> How to use this doc: work top to bottom, phase by phase. Check items off as you go (`- [x]`). Each phase has a "Definition of Done" — don't move on until it's true. If you step away for weeks, re-read the **Current State** section at the bottom first; keep it updated as you progress.

---

## 1. Why Java + Flutter (architecture rationale)

**Confirmed scope: full-featured explorer** (browse all storage, large galleries, thumbnails — comparable to Files by Google / Solid Explorer), not a lightweight app-scoped tool. For this scope, a native Java engine is the right call, not an optional optimization.

Flutter alone *can* do basic file listing with packages like `path_provider` and `file_picker`, but a real file manager needs things Flutter can't do well on its own:

- Scoped Storage / `MediaStore` API access (Android 10+)
- `MANAGE_EXTERNAL_STORAGE` ("All files access") permission flow
- Reading file metadata efficiently at scale (thousands of files)
- Listening to filesystem changes (`FileObserver`)
- Root-level operations if you ever go there
- Tighter control over Android's Storage Access Framework (SAF)

**The bottleneck in practice:** with an all-Flutter approach, Flutter does the scanning, filtering, sorting, *and* builds Dart objects for every entry — all communication and processing happens in Dart. At real-world scale (e.g. a device with 200,000 images, 50,000 videos, 10,000 PDFs) this shows up as high RAM usage, long scan times, and UI jank. Pushing scan → filter → sort → paginate into Java and only returning the Flutter-relevant slice to Dart avoids all three.

**Division of labor:**
| Layer | Responsibility |
|---|---|
| **Flutter (Dart)** | File Explorer UI, Search UI, Storage Analyzer UI, navigation, state management (Bloc/Riverpod), settings, in-app rendering of returned data |
| **Java (Android)** | Scanner, Thumbnail Engine, File Operations (copy/move/delete), Storage Statistics, MediaStore Service, background tasks (`ExecutorService`/`WorkManager`/`ForegroundService`) |
| **Platform Channel** | The bridge — Dart calls Java methods, Java returns results/streams events back |

```
Flutter
  │
  ├── File Explorer UI
  ├── Search UI
  ├── Storage Analyzer UI
  │
  Platform Channel
  │
  Java/Kotlin
  ├── Scanner
  ├── Thumbnail Engine
  ├── File Operations
  ├── Storage Statistics
  └── MediaStore Service
```

This mirrors how most production-grade Android file managers are actually structured — Java does the heavy filesystem work, Flutter focuses purely on rendering.

---

## 2. High-Level Phases

- [x] Phase 0 — Project setup & scaffolding
- [ ] Phase 1 — Permissions (the unglamorous but critical first real step)
- [ ] Phase 2 — Platform Channel contract (Java ⟷ Dart bridge)
- [ ] Phase 3 — Core file listing (read-only browsing, paginated)
- [ ] Phase 4 — File operations (copy/move/delete/rename/create)
- [ ] Phase 5 — Search
- [ ] Phase 6 — File preview (images, text, video thumbnails)
- [ ] Phase 7 — Storage Analyzer (usage breakdown by type/folder)
- [ ] Phase 8 — Polish: sorting, view modes, breadcrumbs, favorites
- [ ] Phase 9 — Performance (large directories, pagination, isolates)
- [ ] Phase 10 — Testing & edge cases
- [ ] Phase 11 — Release prep

---

## Phase 0 — Project Setup & Scaffolding

**Goal:** Empty but runnable skeleton with the Java/Dart bridge proven to work end-to-end.

- [x] Create Flutter project: `flutter create file_manager`
- [x] Confirm Android embedding v2 (default in modern Flutter — verify `android/app/src/main/AndroidManifest.xml` has `<meta-data android:name="flutterEmbedding" android:value="2" />`)
- [x] Set `minSdkVersion` to 26+ (Android 8.0) — gives access to modern storage APIs while keeping reasonable device coverage. Bump to 29+ later if you decide to drop legacy storage support entirely.
- [ ] Create package structure:
  ```
  lib/
    main.dart
    core/
      platform/
        file_channel.dart       // MethodChannel wrapper
    features/
      browser/                  // file listing screen
      operations/                // copy/move/delete logic
      search/
      preview/
    models/
      file_item.dart

  android/app/src/main/java/<your_package>/
    MainActivity.java
    filemanager/
      FileChannelHandler.java   // registers MethodChannel + EventChannel
      PermissionManager.java
      Scanner.java               // directory scanning, paginated listing, search
      ThumbnailEngine.java       // thumbnail generation + caching
      FileOperations.java        // copy/move/delete/rename/create
      StorageStatsService.java   // powers Storage Analyzer
      MediaStoreService.java     // MediaStore queries
  ```
- [ ] Add a trivial "ping" method channel (`getPlatformVersion`) and confirm Dart → Java → Dart round trip works before building anything real.

**Definition of Done:** App launches, button press calls into Java, Java returns a string, Dart displays it.

---

## Phase 1 — Permissions

This trips up almost every Android file manager project, so front-load it.

- [ ] Determine permission strategy based on target Android versions:
  - **Android 10 (API 29) and below:** `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE`
  - **Android 11+ (API 30+):** Need `MANAGE_EXTERNAL_STORAGE` ("All files access") for a true file-manager experience — this requires sending the user to a special system settings screen, it's not a normal runtime permission dialog
  - **Android 13+ (API 33+):** Granular media permissions (`READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `READ_MEDIA_AUDIO`) if you only need media, not full filesystem access
- [ ] Decide: do you need **full filesystem access** (true file manager, browsing any folder) or just **media/app-scoped access**? This decision changes your entire permission model — pin it down before writing code.
- [ ] Implement `PermissionManager.java`:
  - [ ] Check current permission state
  - [ ] Request runtime permissions (API <30)
  - [ ] Build intent to `Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION` (API 30+)
  - [ ] Expose state + request methods over the platform channel
- [ ] Build a Dart-side permission gate screen — block the file browser UI until permission is confirmed, with a clear explanation of why it's needed (Play Store review will also want this justified if you publish)
- [ ] Manifest entries:
  ```xml
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
      android:maxSdkVersion="32" />
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
      android:maxSdkVersion="29" />
  <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
  ```

**Definition of Done:** App correctly detects permission state on a real device across at least two Android versions (e.g. emulator on API 29 and API 33+), and can successfully obtain full storage access on both.

---

## Phase 2 — Platform Channel Contract

Define this clearly up front — it's the seam between your two codebases and is painful to refactor later.

- [ ] Decide channel name convention, e.g. `com.yourapp.filemanager/files`
- [ ] Define the method contract (write this down, keep it updated as source of truth):

| Method (Dart → Java) | Args | Returns | Notes |
|---|---|---|---|
| `listDirectory` | `path: String, page: int, pageSize: int` | `{items: List<FileItemMap>, hasMore: bool}` | **Paginate from day one** — never return a full directory listing in one call; see rationale below |
| `createDirectory` | `path: String` | `bool` | |
| `deleteEntry` | `path: String` | `bool` | recursive for dirs |
| `renameEntry` | `oldPath, newPath: String` | `bool` | |
| `copyEntry` | `src, dest: String` | `bool` (or stream progress, see below) | |
| `moveEntry` | `src, dest: String` | `bool` | |
| `getStorageVolumes` | — | `List<VolumeInfo>` | internal storage, SD card if present |
| `searchFiles` | `query, rootPath: String` | `List<FileItemMap>` | native-side, with cancellation support |
| `getStorageStats` | `rootPath: String` | `{byType: Map<String,long>, byFolder: Map<String,long>, totalUsed, totalFree}` | powers the Storage Analyzer (Phase 7); run off main thread, cache result |
| `generateThumbnail` | `path: String, size: int` | `bytes / cached file path` | route through Thumbnail Engine; cache to disk, don't regenerate per scroll |

**Pagination is not a Phase 9 optimization — it's a Phase 2 contract decision.** Returning 50,000+ items in a single MethodChannel call is the single biggest cause of jank and OOM crashes in Flutter file managers (per the architecture reference: a device with 200K images / 50K videos / 10K PDFs will visibly stutter if scanned and returned in one shot). Design `listDirectory` and `searchFiles` as paginated from the first implementation, even if Phase 3 only ever requests page 1 in early testing.

- [ ] For long-running ops (copy/move large files), use an **EventChannel** instead of a one-shot MethodChannel response, so Java can stream progress updates back to Dart (e.g. `{bytesCopied, totalBytes}`).
- [ ] Define a consistent error contract — Java exceptions should map to Dart `PlatformException` with clear `code` values (e.g. `PERMISSION_DENIED`, `FILE_NOT_FOUND`, `IO_ERROR`) so Dart UI can show meaningful messages, not raw stack traces.
- [ ] Write the Dart wrapper class (`file_channel.dart`) so the rest of the app never calls `MethodChannel` directly — only through typed Dart methods.

**Definition of Done:** Every method above has a Java handler (can be a stub initially) and a typed Dart method calling it, with the error contract in place.

---

## Phase 3 — Core File Listing (Read-Only Browsing)

- [ ] Java: implement `listDirectory` with pagination built in from the start (`page`/`pageSize` params, `hasMore` flag) — use `MediaStore` query for indexed metadata where possible (faster than raw `File.listFiles()` at scale), fall back to `java.io.File` for non-indexed paths
- [ ] Java: return structured data (use a `Map<String,Object>` per entry, or serialize to JSON string for simplicity across the channel)
- [ ] Dart: `FileItem` model class matching the structure
- [ ] Dart: directory browser screen — paginated list view (infinite scroll / "load more"), tap to navigate into folders
- [ ] Dart: back navigation / breadcrumb state management (consider a simple stack of visited paths)
- [ ] Handle empty directories, permission-denied subfolders, and symlinks gracefully (don't crash — show an inline error state for that one item)

**Definition of Done:** You can browse from internal storage root down through nested folders and back up, on a real device, without crashes — including a folder with several thousand entries, scrolling smoothly via pagination.

---

## Phase 4 — File Operations

- [ ] Create folder (Dart UI: dialog with name input → Java `createDirectory`)
- [ ] Delete (single + multi-select) — confirm with dialog, handle recursive directory delete in Java
- [ ] Rename
- [ ] Copy — implement in Java with buffered streams; stream progress via EventChannel for large files
- [ ] Move — prefer `File.renameTo()` when same volume (instant), fall back to copy+delete across volumes
- [ ] Multi-select mode in UI (checkboxes / long-press to enter selection mode)
- [ ] Undo for delete (optional but nice — e.g. move to an app-internal "trash" folder instead of immediate permanent delete)

**Definition of Done:** All CRUD operations work reliably on real files, including across nested folders and (if testing on a device with one) an SD card.

---

## Phase 5 — Search

- [ ] Decide: native (Java, fast, can use `MediaStore` index) vs Dart-side (simpler, but slow on large trees)
- [ ] Recommended: native recursive search with a cancellation token (don't let stale searches keep running/returning results after the user types a new query)
- [ ] Debounce search input in Dart (e.g. 300ms) before triggering native search
- [ ] Filter by file type/extension as a stretch feature

**Definition of Done:** Typing a query returns matching files/folders from the current directory downward within a reasonable time on a real device's storage.

---

## Phase 6 — File Preview

- [ ] Images: Flutter's built-in `Image.file()` is sufficient — no Java needed
- [ ] Text files: read content (small files only — cap size, e.g. 1MB, before attempting to load into memory)
- [ ] Video: generate thumbnail — `video_thumbnail` Dart package, or do it natively via `MediaMetadataRetriever` in Java if you want more control
- [ ] PDFs/other: launch external viewer via Android intent (`Intent.ACTION_VIEW` with proper `FileProvider` URI — required since direct `file://` URIs are blocked on modern Android)
- [ ] Set up a `FileProvider` in the manifest now — you'll need it for any "open with external app" feature

**Definition of Done:** Tapping an image, text file, and at least one "open externally" file type all work correctly.

---

## Phase 7 — Storage Analyzer

A dedicated feature, not just a number on a settings screen — this is what separates a basic browser from a Files-by-Google-style app.

- [ ] Java: implement `getStorageStats` — scan storage once and aggregate:
  - Usage by file type (images, videos, documents, audio, apps, other)
  - Usage by top-level folder
  - Total used / free space per volume
- [ ] Run the scan via `ExecutorService` off the main thread; this can be a real scan on first run, several seconds on a full device — show a progress/loading state in Dart, don't block
- [ ] Cache the result (in-memory + optionally persisted with a timestamp) so reopening the analyzer screen doesn't always trigger a full rescan — add a manual "refresh" action
- [ ] Dart: Storage Analyzer UI — breakdown chart (by type) + tappable list (by folder) that drills into the file browser at that path
- [ ] Consider a background `WorkManager` job to keep stats reasonably fresh without the user needing to manually refresh every time (stretch — not required for v1)

**Definition of Done:** Opening the Storage Analyzer on a real device with a non-trivial amount of data (thousands of files) shows accurate-ish totals within a few seconds, without freezing the UI.

---

## Phase 8 — Polish

- [ ] Sort: name, date modified, size, type (ascending/descending)
- [ ] View mode toggle: list vs grid
- [ ] Favorites/bookmarks (persisted — `shared_preferences` or local sqlite)
- [ ] Recent files
- [ ] Dark mode support
- [ ] Empty states, loading states, error states for every screen

---

## Phase 9 — Performance

- [ ] Confirm `listDirectory` and `searchFiles` pagination (built in Phase 2/3) holds up under real load — test against a folder with 10,000+ entries, not just a handful
- [ ] Run heavy Dart-side processing (e.g. client-side filtering of already-paginated lists) in an `Isolate` to avoid jank
- [ ] On the Java side, confirm all file I/O, scanning, and thumbnail generation run off the main thread via `ExecutorService` (never `AsyncTask` — deprecated) — verify with a large copy/scan that the UI thread never blocks
- [ ] Thumbnail caching: confirm thumbnails are cached to disk/memory and not regenerated on every scroll past the same item
- [ ] Cache directory listings briefly to avoid redundant native calls on quick back/forward navigation
- [ ] Re-test the benchmark scenario: a device-equivalent of ~200K images / 50K videos / 10K PDFs should still produce fast startup, low memory consumption, and smooth scrolling — this is the target bar, not just "doesn't crash"

---

## Phase 10 — Testing & Edge Cases

- [ ] Test on at least 2 Android versions (e.g. API 26 and API 34) — permission flows differ significantly
- [ ] Test with: empty folders, deeply nested paths, very long filenames, special characters/emoji in filenames, read-only system folders, symlinks, 0-byte files, very large files (1GB+ copy)
- [ ] Test permission revocation mid-session (user revokes storage access while app is open — should fail gracefully, not crash)
- [ ] Test low storage / operation failure mid-copy (partial file cleanup)
- [ ] Test on a device with both internal storage and a removable SD card if you can get access to one
- [ ] Test Storage Analyzer accuracy against actual device settings (Android's own Storage screen) as a sanity check

---

## Phase 11 — Release Prep

- [ ] App icon, splash screen
- [ ] Play Store data safety form — broad storage permission apps get extra scrutiny; prepare a clear justification (Google requires a video demo or detailed explanation for `MANAGE_EXTERNAL_STORAGE` apps)
- [ ] Privacy policy (required if requesting broad storage access)
- [ ] ProGuard/R8 rules check — make sure obfuscation doesn't break your platform channel method names or Java reflection if used anywhere
- [ ] Final permission UX review — first-run experience should clearly explain *why* before asking

---

## 3. Key Technical Decisions to Lock In Early

These are the ones that are expensive to change mid-project — decide them in Phase 0–2, not later:

1. **Full filesystem access vs MediaStore-scoped access** — determines your entire permission model (Phase 1)
2. **JSON string vs native Map serialization** across the platform channel — Map is more idiomatic but JSON is easier to debug/log
3. **MethodChannel-only vs adding EventChannel** for progress streaming — needed if you want non-blocking copy/move progress bars
4. **State management approach in Flutter** — Provider, Riverpod, Bloc, or plain setState — pick one before Phase 3 grows the codebase

---

## 4. Open Questions / To Revisit

*(Use this section as a parking lot — add anything you're unsure about instead of blocking progress)*

- [ ] Do you want SD card / removable storage support, or internal storage only?
- [ ] Do you want a "trash/recycle bin" feature or permanent delete only?
- [ ] Any plan to eventually support cloud storage (Google Drive, etc.) — if yes, design the `FileItem` model to be source-agnostic now rather than retrofitting later

---

## 5. Current State

*(Keep this section updated — this is what to read first when you come back to the project)*

- **Last phase worked on:** —
- **Last thing done:** Architecture confirmed (full-featured explorer scope, Java engine + Flutter UI), Storage Analyzer added as Phase 7
- **Next thing to do:** Phase 0 — project scaffolding
- **Blockers:** —
- **Notes from reference material reviewed:** Reviewed `File_Manager_Considerations.pdf` — confirmed the Java+Flutter hybrid split (Scanner / Thumbnail Engine / File Operations / Storage Stats / MediaStore Service in Java; Explorer/Search/Analyzer UI in Flutter), and that pagination is non-negotiable at scale (benchmark: 200K images / 50K videos / 10K PDFs). Source PDF reasoning is folded into Sections 1, 2 (Phase 2 table), and Phase 7 above.
