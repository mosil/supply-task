# 規格書：Supply Task - Firebase 整合

本文件定義了 Supply Task 應用程式與 Firebase 後端服務的整合細節，包含資料庫結構、認證流程與安全性規則。

## 1. Firebase 服務啟用

- **Authentication**: 用於使用者登入驗證。
- **Firestore**: 儲存使用者與任務資料。
- **Realtime Database**: 儲存專案基本資訊。
- **Remote Config**: 儲存客戶端遠端設定。

## 2. Authentication (使用者認證)

- **供應商**: 啟用 `Google` 登入。
- **流程**:
    1. 客戶端使用 `google_sign_in` 套件取得 Google 用戶的 `idToken` 和 `accessToken`。
    2. 將 `AuthCredential` 傳遞給 Firebase Auth 的 `signInWithCredential` 方法。
    3. 成功登入後，取得 Firebase `User` 物件，其 `uid` 是所有資料關聯的主鍵。
    4. **新使用者檢查**: 拿 `uid` 到 Firestore 的 `users` collection 中查詢。如果文件不存在，表示為新使用者。
    5. **強制更新資料**: 對於新使用者，導向「使用者編輯頁 (`/profile/edit`)」，強制使用者填寫完 `顯示名稱` 才能繼續使用 App。
    6. **Token 管理**: 雖然 Firebase SDK 會自動管理 token，但為了教學目的，我們會將 `idToken` 儲存於 `flutter_secure_storage`，並在 App 啟動時檢查其有效性來判斷登入狀態。

## 3. 資料庫結構

### 3.1 Remote Config

用於存放非機密性的客戶端設定。

- **`versionName`** (String):
    - 描述: App 的版本名稱，例如 "1.0.0"。
    - 預設值: "1.0.0"
- **`modifyTime`** (String):
    - 描述: 上次更新設定的時間，格式 `YYYY-MM-DDTHH:mm:ssZ`。
    - 預設值: 當前時間。

### 3.2 Realtime Database

用於存放專案列表，結構簡單，讀取頻繁。

- **根節點**: `projects`
- **結構**:
    ```json
    {
      "projects": {
        "hualien-matayan-landslide-2025": "2025 花蓮馬太鞍溪堰塞湖災害"
      }
    }
    ```
    - **Key**: 專案 ID，將作為 Firestore 的 Collection 名稱。
    - **Value**: 專案的完整顯示名稱。

### 3.3 Firestore

主要業務資料庫，用於儲存使用者和任務等複雜資料。

#### **Collection: `users`**

- **Document ID**: 使用者的 `uid`。
- **欄位 (Fields)**:
    - `email` (String): 使用者 Email。
    - `displayName` (String): 顯示名稱。
    - `contactInfo` (String): 聯絡資訊 (可為空)。
    - `phoneNumber` (String): 聯絡電話 (可為空)。
    - `createdAt` (Timestamp): 帳號建立時間。

#### **Collection: `hualien-matayan-landslide-2025` (專案 ID)**

- **Document ID**: 自動生成的任務 ID。
- **欄位 (Fields)**:
    - `name` (String): 任務名稱。
    - `content` (String): 任務內容。
    - `address` (String): 地址。
    - `typeId` (String): 任務性質的 ID (對應 `taskTypes` 集合中的文件 ID)。
    - `status` (String): 任務狀態 (對應 `TaskStatus` enum 的字串，如 `published`)。
    - `publisherId` (String): 發布人的 `uid`。
    - `publishedAt` (Timestamp): 發布時間。
    - `editedAt` (Timestamp, nullable): 編輯時間。
    - `canceledAt` (Timestamp, nullable): 取消時間。
    - `claimantId` (String, nullable): 承接人的 `uid`。
    - `claimedAt` (Timestamp, nullable): 承接時間。
    - `completedAt` (Timestamp, nullable): 完成時間。
    - `statusChangedAt` (Timestamp, nullable): 狀態變更時間。

**備註**: `publisherName` 與 `claimantName` 已被移除，改為在客戶端需要顯示時，根據 `publisherId` 或 `claimantId` 即時從 `users` 集合中讀取，以確保使用者名稱永遠是最新狀態。

#### **Collection: `taskTypes`**

- **Document ID**: 自動生成的 ID (例如 `2aGf...`)。
- **欄位 (Fields)**:
    - `name` (String): 任務性質的顯示名稱 (例如 "勞力任務")。
- **初始化邏輯**: 客戶端 App 在啟動時，若發現此集合為空，則自動寫入三筆預設資料：
    - `{ name: "勞力任務" }`
    - `{ name: "補給品需求" }`
    - `{ name: "發放資源" }`

## 4. 資料服務層 (Data Service Layer)

建立一個或多個服務類 (例如 `FirebaseService` 或 `TaskRepository`, `UserRepository`) 來封裝所有與 Firebase 的互動邏輯。

- **`AuthService`**
    - `Future<User?> signInWithGoogle()`
    - `Future<void> signOut()`
    - `Stream<User?> get authStateChanges`
    - `String? get currentUserUid`
- **`UserService`**
    - `Future<UserProfile?> getUserProfile(String uid)`
    - `Future<void> createUserProfile({String uid, String email, String displayName})`
    - `Future<void> updateUserProfile(UserProfile profile)`
- **`TaskService`**
    - `Stream<List<Task>> getTasks(String projectId, TaskStatus status)`
    - `Future<Task?> getTask(String projectId, String taskId)`
    - `Future<void> addTask(String projectId, Task task)`
    - `Future<void> updateTask(String projectId, Task task)`
    - `Future<List<String>> getTaskTypes()`
    - `Future<void> addTaskType(String newType)`

## 5. 安全性規則 (Security Rules)

### 5.1 Firestore

```rules
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // 使用者只能讀寫自己的資料
    match /users/{userId} {
      allow read, update, delete: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null;
    }

    // 任務性質，所有登入者都可讀，但不可寫
    match /task_types/{docId} {
        allow read: if request.auth != null;
        allow write: if false; // 透過 Cloud Function 管理
    }

    // 專案下的任務
    match /{projectId}/{taskId} {
      // 公開讀取所有任務
      allow read: if true;

      // 登入後才能建立任務，且發布人ID必須是自己
      allow create: if request.auth != null && request.resource.data.publisherId == request.auth.uid;

      // 更新任務的權限
      allow update: if request.auth != null && (
        // 1. 發布人可以編輯/取消自己的任務
        (resource.data.publisherId == request.auth.uid && (request.resource.data.status == "published" || request.resource.data.status == "canceled")) ||
        // 2. 任何人都可以承接任務
        (request.resource.data.status == "claimed" && request.resource.data.claimantId == request.auth.uid) ||
        // 3. 承接人可以放棄或完成任務
        (resource.data.claimantId == request.auth.uid && (request.resource.data.status == "abandoned" || request.resource.data.status == "completed"))
      );

      // 不允許客戶端刪除任務
      allow delete: if false;
    }
  }
}
```

### 5.2 Realtime Database

```json
{
  "rules": {
    "projects": {
      ".read": true,
      ".write": false
    }
  }
}
```

## 6. PWA 與 Web 平台強化規格

### 6.1 啟用 Firestore 離線數據 (Offline Persistence)

- **關鍵實作**: 在 Flutter 應用程式的 Firebase 初始化流程中，必須明確啟用 Firestore 的離線數據功能。
    ```dart
    // 範例程式碼
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // 根據需求設定快取大小
    );
    ```
- **效益**: 啟用後，Firestore SDK 會自動將所有讀取過的數據和本地的寫入操作進行快取。這解決了大部分離線資料讀取與操作佇列的需求，是實現 PWA 可靠性的核心。

### 6.2 Service Worker 快取策略

- **目標**: 客製化 Flutter 生成的 `flutter_service_worker.js` (或使用如 Workbox 等工具) 來達到更精細的快取控制。
- **策略**:
    - **App Shell (必要資源)**: 對 `index.html`, `main.dart.js`, `manifest.json`, 主要字體與圖示等核心資源，採用 **Cache First** 策略。先從快取讀取，若無快取才從網路請求。
    - **靜態資源 (非必要)**: 對於不影響核心功能的圖片等資源，可採用 **Stale-While-Revalidate** 策略。先從快取提供舊版資源，同時非同步地請求新資源並更新快取，確保下次能載入最新版本。

### 6.3 推播通知 (Push Notifications)

- **整合**: 需整合 `firebase_messaging` for Web，並在 `web/firebase-messaging-sw.js` 中設定背景訊息處理的 Service Worker。
- **功能流程**:
    1. 在使用者登入後，於適當時機 (例如：使用者資料頁) 請求推播權限。
    2. 使用者同意後，取得 FCM token 並將其與使用者 UID 關聯，儲存於該使用者的 Firestore 文件中。
    3. **觸發時機**: 使用 Cloud Functions for Firebase 來監聽 Firestore 的數據變更，當發生特定事件時 (如 `claimed`, `canceled`)，觸發推播通知給相關的使用者。
        - **範例**: 監聽 `tasks` 集合的 `onUpdate` 事件，如果 `status` 欄位從 `published` 變為 `claimed`，則向 `publisherId` 對應的使用者發送通知。
