# Design Lab: backend-free UI/UX testing

Design Lab runs Docmac with sample data and no Firebase connection. Use it while
building or reviewing the real UI/UX so a missing backend, signed-out account,
or empty Firestore project never blocks the work.

It is a **development tool only**. Release builds compile it out, and no Design
Lab action writes to Firebase.

## Run it

```bash
flutter run --dart-define=DOCMAC_DESIGN_LAB=true
```

On Windows desktop:

```bash
flutter run -d windows --dart-define=DOCMAC_DESIGN_LAB=true
```

The app skips Firebase initialization, bypasses the auth gate, starts on the
Orbit shell, and shows a diagonal **DESIGN LAB** ribbon. Talk, Chat,
Connections, People, Moments, Live, Orbit, Forge, and Search use their existing
sample data.

You can combine it with the older preview switches if you want to be explicit:

```bash
flutter run \
  --dart-define=DOCMAC_DESIGN_LAB=true \
  --dart-define=DOCMAC_SIGNED_OUT_PREVIEWS=true \
  --dart-define=DOCMAC_LOCAL_PREVIEWS=true
```

## What is sample data

| Surface | Fixture | Notes |
| --- | --- | --- |
| Talk inbox | `curatedTalkThreads` in `lib/features/talk/data/talk_thread.dart` | Includes 1:1 and group previews |
| Chat messages | `curatedChatMessages` in `lib/features/chat/presentation/providers/chat_providers.dart` | Sends append to an in-memory outbox |
| Connections | `ConnectionsController.seeded()` | Followers, following, requests, contacts |
| People | Sample roster in `people_page.dart` | Cards, requests, suggestions |
| Person space / chat header | `_personInfo` in `lib/config/router/app_router.dart` | Name, initial, online dot |
| Moments | Sample lists in `moments_page.dart` | My moments and people moments |
| Archive | `_seedArchive()` in `moment_archive_page.dart` | Archived moments |
| Live / calls | `call_repository.dart` seeds and page samples | Call history and sample people |
| Orbit / Forge / Search | Page-level sample lists | Static activity and catalogue |

Some fixtures are still private to their page. Consolidating them into one
fixture catalogue is part of Phase 2 workstream B; it does not block UI work
today.

## What is real

- Widgets, theme, typography, spacing, motion, and navigation are the real app.
- Local interactions persist in memory only: sending a message, following,
  accepting a request, muting, archiving, and similar actions.
- Nothing is uploaded, synced, or saved after restart.
- Firebase Auth, Firestore, Functions, Crashlytics, and Analytics are not
  started.
- Actions that need a real backend keep their honest unavailable state. The
  ribbon reminds you that the data is sample data.

## Add or change a fixture

1. Prefer editing the existing sample list for that surface.
2. Keep fixture values deterministic; do not use real names, phone numbers, or
   email addresses.
3. Use `AppFeatureFlags.localPreviews` or `signedOutPreviews` so release builds
   still show honest empty states.
4. Add a widget test if the fixture drives a state that can regress.
5. Do not make a production repository return sample data when a real user is
   signed in; that is the one rule the honesty sweeps enforce.

## Known limits

- Design Lab is not a load, performance, or security test. Fixtures are small.
- Share sheets, notifications, camera, and microphone still use the real
  platform; some may be unavailable on desktop.
- Restarting resets all local changes.
- Release builds ignore `DOCMAC_DESIGN_LAB`; verify store builds separately.

## Relationship to Phase 2

Design Lab is milestone **M2.0** in `PHASE_2_PLAN.md`. It gives the UI/UX work a
stable playground while the production backend is unblocked. The next step is a
shared fixture catalogue plus golden screenshots for the main states.
