# PostSaver Mobile — Phase 3: Share Sheet + Polish Implementation Plan

**Goal:** Implement the key differentiator — receiving shared URLs from other apps via the Android share sheet and pre-filling a "save post" form. Plus polish: proper error states, loading states, and edge cases across all screens.

## Phase 3A: Share Sheet (Android)

### Task 19: Share Intent Handler

**Files:**
- Create: `frontend/postsaver/lib/features/share/share_provider.dart`
- Create: `frontend/postsaver/lib/features/share/share_handler.dart`

**Steps:**
1. Create share_provider.dart with SharedUrlState and SharedUrlNotifier
2. Create share_handler.dart to parse shared text/URLs and infer source from domain
3. Update main.dart to listen for share intents on startup and when app is in foreground
4. Commit

### Task 20: Share → Create Post Flow

**Files:**
- Modify: `frontend/postsaver/lib/features/posts/post_form_screen.dart` (accept initialUrl param)
- Modify: `frontend/postsaver/lib/app.dart` (add share deep link route)

**Steps:**
1. Add `initialUrl` parameter to PostFormScreen
2. Add route `/share` that receives URL and navigates to PostFormScreen
3. When shared URL received: check auth → navigate to /posts/new?url=<encoded>
4. Commit

## Phase 3B: Polish

### Task 21: Error & Loading States

**Files:**
- Modify: All screen files

**Steps:**
1. Add consistent error retry UI to all list screens (posts, folders, tags)
2. Add loading shimmer/skeleton where appropriate
3. Add offline detection message
4. Commit

### Task 22: Edge Cases & UX

**Files:**
- Various screen files

**Steps:**
1. Confirm delete with dialog for all delete actions
2. Show snackbar feedback for all CRUD operations
3. Handle empty states with helpful messages
4. Commit

### Task 23: Final Verification & PR

**Steps:**
1. flutter analyze
2. flutter test
3. Create branch, push, PR
