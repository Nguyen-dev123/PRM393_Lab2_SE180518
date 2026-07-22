# Requirements Document

## Introduction

Feature **firebase-crud-enhancement** bổ sung ba nhóm tính năng Firebase cho ứng dụng Flutter **Journal Trend Analyzer** (PRM393 Final Assignment):

1. **Firestore Bookmark CRUD** – Người dùng có thể lưu (bookmark) publication yêu thích vào Cloud Firestore, xem danh sách đã lưu, thêm ghi chú cá nhân, và xoá bookmark. Mỗi người dùng có collection riêng theo UID.
2. **Firebase Storage PDF Upload** – Thay thế việc chỉ lưu file PDF local bằng cách upload thật lên Firebase Storage và trả về download URL để chia sẻ.
3. **User Profile Editing** – Người dùng có thể chỉnh sửa display name; thay đổi được lưu vào cả Firebase Auth và Firestore.

---

## Glossary

- **App**: Ứng dụng Flutter Journal Trend Analyzer.
- **Authenticated_User**: Người dùng đã đăng nhập qua Firebase Authentication (Google Sign-In hoặc anonymous).
- **Publication**: Bài báo khoa học lấy từ OpenAlex API, được đại diện bởi model `Publication`.
- **Bookmark**: Bản ghi Firestore lưu thông tin một Publication mà người dùng muốn giữ lại, kèm tuỳ chọn ghi chú.
- **Bookmark_Service**: Dart service class chịu trách nhiệm tất cả thao tác CRUD bookmark trên Cloud Firestore.
- **Bookmark_ViewModel**: ChangeNotifier cung cấp trạng thái bookmark cho UI.
- **Bookmarks_Screen**: Màn hình hiển thị danh sách bookmark của người dùng.
- **PDF_Export_Service**: Class hiện tại tại `lib/services/pdf_export_service.dart` tạo và lưu file PDF.
- **Firebase_Storage**: Dịch vụ Firebase lưu trữ file; được sử dụng để upload PDF.
- **Profile_Screen**: Màn hình hiện tại tại `lib/screens/profile_screen.dart` hiển thị thông tin tài khoản.
- **Auth_ViewModel**: ChangeNotifier hiện tại tại `lib/viewmodels/auth_viewmodel.dart` quản lý trạng thái xác thực.
- **Display_Name**: Tên hiển thị của người dùng được lưu trong Firebase Auth và Firestore.
- **UID**: ID duy nhất của người dùng do Firebase Authentication cấp.
- **Download_URL**: URL công khai do Firebase Storage trả về sau khi upload file thành công.
- **Firestore_Users_Collection**: Collection `users/{uid}` trong Cloud Firestore lưu thông tin profile.
- **Firestore_Bookmarks_Collection**: Sub-collection `users/{uid}/bookmarks` trong Cloud Firestore lưu bookmark.

---

## Requirements

### Requirement 1: Bookmark a Publication (Create)

**User Story:** As an Authenticated_User, I want to bookmark a Publication, so that I can save it for later reference.

#### Acceptance Criteria

1. WHEN an Authenticated_User taps the bookmark icon on a Publication, THE Bookmark_Service SHALL create a new document in the Firestore_Bookmarks_Collection with the following fields: `publicationId`, `title`, `year`, `citationCount`, `journalName`, `authors`, `doi`, `url`, `note` (empty string), and `savedAt` (server timestamp).
2. WHEN a bookmark is successfully created, THE Bookmark_ViewModel SHALL add the bookmark to the in-memory list and call `notifyListeners()`.
3. WHEN a bookmark is successfully created, THE App SHALL display a SnackBar confirmation message within 1 second.
4. IF the Authenticated_User attempts to bookmark a Publication that is already bookmarked (same `publicationId`), THEN THE Bookmark_Service SHALL silently skip the creation and return without error.
5. IF a Firestore write operation fails, THEN THE Bookmark_Service SHALL throw an exception, and THE App SHALL display an error SnackBar to the Authenticated_User.

---

### Requirement 2: Read Bookmarks (Read)

**User Story:** As an Authenticated_User, I want to view all my saved bookmarks, so that I can revisit publications I care about.

#### Acceptance Criteria

1. WHEN the Bookmarks_Screen is opened, THE Bookmark_Service SHALL fetch all documents from the Firestore_Bookmarks_Collection for the current Authenticated_User, ordered by `savedAt` descending.
2. THE Bookmark_ViewModel SHALL expose a `bookmarks` list and an `isLoading` boolean to the UI.
3. WHILE `isLoading` is true, THE Bookmarks_Screen SHALL display a loading indicator alongside any currently loaded bookmark items.
4. WHEN the bookmarks list is empty, THE Bookmarks_Screen SHALL immediately display an empty-state message with a prompt to start bookmarking, regardless of whether loading is still in progress.
5. WHEN bookmarks are loaded, THE Bookmarks_Screen SHALL display each bookmark's `title`, `savedAt` date, `citationCount`, and `note` (if non-empty).
6. IF the Firestore read operation fails, THEN THE Bookmark_ViewModel SHALL set an `errorMessage` string, and THE Bookmarks_Screen SHALL display the error message while maintaining the current bookmark list display and loading state.

---

### Requirement 3: Update Bookmark Note (Update)

**User Story:** As an Authenticated_User, I want to add or edit a personal note on a saved bookmark, so that I can annotate why I saved it.

#### Acceptance Criteria

1. WHEN an Authenticated_User taps the edit icon on a bookmark card, THE App SHALL display a dialog containing a text field pre-populated with the existing `note` value.
2. WHEN an Authenticated_User confirms the note edit, THE Bookmark_Service SHALL update only the `note` field of the corresponding Firestore document using `update()` (not `set()`).
3. WHEN the Firestore `update()` succeeds and the in-memory bookmark object is also updated, THE Bookmark_ViewModel SHALL call `notifyListeners()`.
4. WHEN the note is successfully updated, THE App SHALL display a SnackBar confirmation message within 1 second.
5. IF the Authenticated_User submits an empty string as the note, THE Bookmark_Service SHALL update the `note` field to an empty string without error.
6. IF the Firestore update operation fails, THEN THE Bookmark_Service SHALL throw an exception, and THE App SHALL display an error SnackBar to the Authenticated_User.

---

### Requirement 4: Delete Bookmark (Delete)

**User Story:** As an Authenticated_User, I want to remove a publication from my bookmarks, so that I can keep my saved list clean.

#### Acceptance Criteria

1. WHEN an Authenticated_User taps the delete icon on a bookmark card, THE App SHALL display a confirmation dialog before deleting.
2. WHEN the Authenticated_User confirms deletion, THE Bookmark_Service SHALL delete the corresponding document from the Firestore_Bookmarks_Collection.
3. WHEN a bookmark is successfully deleted, THE Bookmark_ViewModel SHALL remove the bookmark from the in-memory list and call `notifyListeners()`.
4. WHEN a bookmark is successfully deleted, THE App SHALL display a SnackBar confirmation message within 1 second.
5. IF the Firestore delete operation fails, THEN THE Bookmark_Service SHALL throw an exception, and THE App SHALL display an error SnackBar to the Authenticated_User.

---

### Requirement 5: Bookmark State in Publication Detail

**User Story:** As an Authenticated_User, I want to see whether a publication is already bookmarked from its detail screen, so that I avoid duplicate saves.

#### Acceptance Criteria

1. WHEN an Authenticated_User taps the bookmark icon on a Publication and the publication is already bookmarked, THE App SHALL display a SnackBar informing the user the publication is already saved without changing the bookmark state.
2. WHEN the publication is already bookmarked, THE Publication_Detail_Screen SHALL display a filled bookmark icon (e.g., `Icons.bookmark`).
3. WHEN the publication is not bookmarked, THE Publication_Detail_Screen SHALL display an outlined bookmark icon (e.g., `Icons.bookmark_border`).
4. WHEN the Publication_Detail_Screen is opened, THE Bookmark_ViewModel SHALL check if the publication's `id` exists in the in-memory bookmarks list.

---

### Requirement 6: Firebase Storage PDF Upload

**User Story:** As an Authenticated_User, I want the exported PDF report to be uploaded to Firebase Storage, so that I receive a shareable download URL.

#### Acceptance Criteria

1. WHEN an Authenticated_User triggers a PDF export, THE PDF_Export_Service SHALL first generate and save the PDF file locally as it currently does.
2. AFTER the local file is saved, THE PDF_Export_Service SHALL upload the file to Firebase_Storage at the path `reports/{uid}/{fileName}` using the current Authenticated_User's UID.
3. WHEN the upload succeeds, THE PDF_Export_Service SHALL call `getDownloadURL()` on the uploaded file reference and return the Download_URL string.
4. WHEN the upload succeeds, THE App SHALL display the Download_URL in a dialog or SnackBar so the user can copy or share it.
5. IF the Firebase_Storage upload fails, THEN THE PDF_Export_Service SHALL log the error and return the local file path as a fallback instead of throwing.
6. THE PDF_Export_Service SHALL log a Firebase Analytics event named `export_pdf` with parameters `topic` (string) and `upload_success` (boolean) after each export attempt.

---

### Requirement 7: User Profile Display Name Editing

**User Story:** As an Authenticated_User, I want to edit my display name, so that my profile reflects my preferred name.

#### Acceptance Criteria

1. WHEN an Authenticated_User views the Account tab in Profile_Screen, THE Profile_Screen SHALL display an edit icon next to the Display_Name field.
2. WHEN the Authenticated_User taps the edit icon, THE App SHALL display a dialog containing a text field pre-populated with the current Display_Name.
3. WHEN the Authenticated_User confirms the new Display_Name, THE Auth_ViewModel SHALL call `updateDisplayName()` on the Firebase Auth user profile regardless of client-side validation, allowing Firebase to handle invalid inputs.
4. WHEN the Firebase Auth update succeeds, THE Auth_ViewModel SHALL also write the new Display_Name to the Firestore_Users_Collection document at `users/{uid}` under the field `displayName`.
5. WHEN both updates succeed, THE Auth_ViewModel SHALL call `notifyListeners()` so the Profile_Screen rebuilds with the new Display_Name.
6. WHEN the updates succeed, THE App SHALL display a SnackBar confirmation message within 1 second.
7. IF the Authenticated_User submits a Display_Name with fewer than 1 character or more than 50 characters, THEN THE App SHALL display an inline validation error in the dialog and SHALL NOT call the update methods.
8. IF either the Firebase Auth update or the Firestore write fails, THEN THE Auth_ViewModel SHALL expose an `updateError` string, and THE App SHALL display an error SnackBar to the Authenticated_User.
