# 規格書：Supply Task - UI 與資料模型

本文件定義了 Supply Task 應用程式的 UI 介面、元件、資料模型和初期使用的假資料。

## 1. 專案結構與核心套件

- **狀態管理**: `provider`
- **路徑管理**: `go_router`
- **本地端儲存**: `flutter_secure_storage`

## 2. 色彩與風格

採用 Material Design 3 設計風格，以明亮、活潑的色調為主。

- **主要色 (Primary)**: 藍色系，用於主要按鈕、分頁指示器等。
- **次要色 (Secondary)**: 綠色系，用於強調、成功狀態等。
- **強調色 (Accent)**: 橘色或黃色系，用於浮動按鈕等。
- **錯誤色 (Error)**: 紅色系。
- **成功色 (Success)**: 綠色系。
- **中性色 (Neutral)**: 灰色系，用於背景、次要文字。

## 3. 資料模型 (Data Models)

所有時間格式均為 `YYYY/MM/dd HH:mm`。

### 3.1 `Task` (任務)

```dart
enum TaskStatus {
  draft,      // 草稿
  published,  // 發布
  claimed,    // 認領
  completed,  // 已完成
  abandoned,  // 放棄
  canceled,   // 取消
}

class Task {
  final String id;
  final String name;
  final String content;
  final String address;
  final String type;
  final TaskStatus status;
  final String publisherId;
  final String contactInfo;
  final String contactPhone;
  final DateTime publishedAt;
  final DateTime? editedAt;
  final DateTime? canceledAt;
  final String? claimantId;
  final DateTime? claimedAt;
  final DateTime? completedAt;
  final DateTime? statusChangedAt; // 用於認領、完成、放棄、取消的狀態變更時間

  Task({
    required this.id,
    required this.name,
    required this.content,
    required this.address,
    required this.type,
    required this.status,
    required this.publisherId,
    required this.contactInfo,
    required this.contactPhone,
    required this.publishedAt,
    this.editedAt,
    this.canceledAt,
    this.claimantId,
    this.claimedAt,
    this.completedAt,
    this.statusChangedAt,
  });
}
```

### 3.2 `UserProfile` (使用者資料)

```dart
class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String contactInfo;
  final String phoneNumber;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.contactInfo,
    required this.phoneNumber,
  });
}
```

### 3.3 `TaskType` (任務性質)

任務性質為動態資料，初期提供預設選項。

- 勞力任務
- 補給品需求
- 發放資源

## 4. 畫面規格 (Page Specifications)

### 4.1 路由管理 (`go_router`)

- `/`: 首頁 (HomePage)
- `/task/:id`: 任務資料頁 (TaskDetailsPage)
- `/task/new`: 新增任務頁 (CreateEditTaskPage)
- `/task/:id/edit`: 編輯任務頁 (CreateEditTaskPage)
- `/profile`: 使用者資料頁 (UserProfilePage)
- `/profile/edit`: 使用者編輯頁 (EditProfilePage)
- `/login`: 登入頁 (LoginPage)
- `/my-tasks/:type`: 我發布/承接的任務清單 (MyTasksPage)

### 4.2 首頁 (`HomePage`)

- **結構**:
    - `AppBar`: 標題為「2025 花蓮馬太鞍溪堰塞湖災害」。右側有使用者圖示按鈕。
    - `TabBar`:
        - **任務**: 顯示 `published` 或 `abandoned` 狀態的任務。
        - **執行中**: 顯示 `claimed` 狀態的任務。
        - **完成**: 顯示 `completed` 狀態的任務。
    - `TabBarView`: 對應各分頁的任務清單。
    - `FloatingActionButton`: 新增任務按鈕。
- **元件**:
    - `TaskCard`:
        - 顯示 `任務名稱`、`發布時間`。
        - `發布人` 名稱會透過 `publisherId` 非同步地從 `users` 集合獲取並顯示。
        - 狀態標籤:
            - **認領** (藍色): `claimed` 狀態。
            - **已完成** (綠色): `completed` 狀態。
        - 若為 `claimed` 或 `completed` 狀態，額外顯示 `狀態變更時間`。
- **邏輯**:
    - 未登入時，點擊 AppBar 的使用者圖示或 FAB，導向 `/login`。
    - 登入後，點擊 AppBar 的使用者圖示，導向 `/profile`。
    - 登入後，點擊 FAB，導向 `/task/new`。
    - 若分頁無資料，顯示「目前尚無任務」的提示訊息。

### 4.3 任務資料頁 (`TaskDetailsPage`)

- **結構**:
    - `AppBar`: 標題為 `任務名稱`。根據使用者身份顯示對應的 Action 按鈕。
    - `SingleChildScrollView`:
        - 顯示所有任務欄位資訊。其中 `發布人` 和 `承接人` 的名稱會透過 ID 非同步獲取。
        - `地址` 可點擊，並透過 `url_launcher` 開啟 Google Map。
        - `聯絡電話` 可點擊，並透過 `url_launcher` 開啟撥號功能。
        - 任務狀態區塊 (Card)。
        - 承接人狀態區塊 (Card)，若無承接人則不顯示。
    - 置底按鈕區。
- **邏輯**:
    - **AppBar Actions**:
        - **發布人**: 顯示「取消任務」圖示按鈕，點擊後跳出確認 Dialog。
        - **承接人**: 顯示「放棄任務」圖示按鈕，點擊後跳出確認 Dialog。
    - **置底按鈕**:
        - **發布人**: 顯示「編輯」按鈕，導向 `/task/:id/edit`。
        - **其他已登入使用者**:
            - 若任務狀態為 `published` 或 `abandoned`，顯示「承接」按鈕。
            - 若任務已被認領，按鈕變為不可點擊狀態。

### 4.4 發布/編輯任務頁 (`CreateEditTaskPage`)

- **結構**:
    - `AppBar`: 標題為「發布任務」或「編輯任務」。Action 有「取消」圖示按鈕。
    - `Form`: 包含所有表單欄位。
        - `TextFormField` 用於文字輸入，包含字數限制提示。
        - `DropdownButtonFormField` 用於任務性質選擇。
        - 若任務性質選擇「其他」，則顯示一個新的 `TextFormField` 讓使用者輸入自訂性質。
    - 置底按鈕區。
- **邏輯**:
    - **欄位驗證**:
        - 任務名稱、內容、聯絡人、任務性質為必填。
    - **自動帶入**:
        - 新增任務時，自動帶入當前登入者的 `顯示名稱`、`聯絡資訊`、`聯絡電話`。
    - **置底按鈕**:
        - **新增任務時**: 顯示「發布」與「儲存草稿」按鈕。
        - **編輯草稿時**: 顯示「發布」與「更新草稿」按鈕。
        - **編輯已發布任務時**: 顯示單一的「更新任務」按鈕。
    - **AppBar Actions**:
        - **刪除**: **僅在編輯模式下顯示**。點擊後跳出確認 Dialog，確認後刪除該任務。
    - **返回保護**: 當表單內容被修改後，若使用者試圖透過任何方式返回，皆會跳出確認對話框，詢問是否要捨棄變更。

### 4.5 使用者資料頁 (`UserProfilePage`)

- **結構**:
    - `AppBar`: 標題為「使用者資料」。Actions 包含「編輯」和「登出」圖示按鈕。
    - 顯示使用者所有基本資料。
    - 「發布任務」按鈕: 導向 `/my-published-tasks`。
    - 「承接任務」按鈕: 導向 `/my-claimed-tasks`。
- **邏輯**:
    - 只有在使用者有發布/承接的任務時，才顯示對應的按鈕。
    - **編輯**: 導向 `/profile/edit`。
    - **登出**: 清除本地端 `flutter_secure_storage` 的資料，並導向 `/login`。

### 4.6 使用者編輯頁 (`EditProfilePage`)

- **結構**:
    - `AppBar`: 標題為「編輯個人資料」。
    - `Form`:
        - `TextFormField` 用於編輯 `顯示名稱`、`聯絡資訊`、`聯絡電話`。
    - 置底「儲存」按鈕。
- **邏輯**:
    - `顯示名稱` 為必填。
    - 儲存成功後，返回使用者資料頁。
    - **返回保護**: 同 `CreateEditTaskPage`，當表單內容被修改後，會攔截返回操作並提示使用者。

### 4.7 登入頁 (`LoginPage`)

- **結構**:
    - 頁面中央顯示一個「使用 Google 登入」按鈕。
- **邏輯**:
    - 登入流程結束後，若為新使用者，強制導向 `/profile/edit` 頁面填寫基本資料。
    - 若為既有使用者，返回登入前的頁面或首頁。

### 4.8 我的任務清單頁 (`MyTasksPage`)

- **結構**:
    - `AppBar`: 標題根據路由參數動態顯示為「我發布的任務」或「我承接的任務」。包含返回按鈕，可回到使用者資料頁。
    - `Body`: 重複使用 `TaskList` 元件來顯示對應的任務清單。
- **邏輯**:
    - 根據路由傳入的 `type` (`published` 或 `claimed`)，從 `TaskProvider` 篩選出對應的任務列表並顯示。

## 5. 假資料 (Mock Data)

### 5.1 `mock_tasks`

```dart
final List<Task> mockTasks = [
  Task(
    id: 'task-001',
    name: '物資集中站需要分類志工',
    content: '大量救援物資湧入，急需人手協助分類、打包，以便快速送達災民手中。',
    address: '花蓮縣壽豐鄉中山路一段1號',
    type: '勞力任務',
    status: TaskStatus.published,
    publisherName: '王大明',
    publishedAt: DateTime(2025, 9, 30, 10, 0),
  ),
  Task(
    id: 'task-002',
    name: '急需瓶裝水 100 箱',
    content: '臨時避難所目前缺乏乾淨飲用水，希望善心人士能捐贈。',
    address: '花蓮縣豐濱鄉豐濱村1鄰3號',
    type: '補給品需求',
    status: TaskStatus.claimed,
    publisherName: '陳小姐',
    publishedAt: DateTime(2025, 9, 30, 11, 30),
    claimantName: '李四',
    claimedAt: DateTime(2025, 9, 30, 14, 0),
    statusChangedAt: DateTime(2025, 9, 30, 14, 0),
  ),
  Task(
    id: 'task-003',
    name: '發放熱食便當',
    content: '預計於中午12點在村活動中心發放熱食便當給受災居民。',
    address: '花蓮縣光復鄉大安村2鄰5號',
    type: '發放資源',
    status: Task.completed,
    publisherName: '鄉公所',
    publishedAt: DateTime(2025, 9, 29, 18, 0),
    claimantName: '張三',
    claimedAt: DateTime(2025, 9, 30, 9, 0),
    completedAt: DateTime(2025, 9, 30, 13, 0),
    statusChangedAt: DateTime(2025, 9, 30, 13, 0),
  ),
];
```

### 5.2 `mock_users`

```dart
final UserProfile mockUser1 = UserProfile(
  uid: 'user-uid-001',
  email: 'ming@example.com',
  displayName: '王大明',
  contactInfo: 'LINE ID: davidwang',
  phoneNumber: '0912-345-678',
);

final UserProfile mockUser2 = UserProfile(
  uid: 'user-uid-002',
  email: 'lee@example.com',
  displayName: '李四',
  contactInfo: '',
  phoneNumber: '0987-654-321',
);
```

## 6. PWA 與 Web 平台強化規格

為了確保在 Web 平台有最佳體驗並符合 PWA 最高標準，特此補充以下規格。

### 6.1 響應式佈局 (Responsive Layout)

- **桌面版 (寬度 > 1024px)**:
    - **首頁**: 採用 Master-Detail 佈局。左側為任務清單，右側顯示選中任務的詳細資料 (`TaskDetailsPage`)。
    - **表單頁**: 考慮將標籤與輸入框左右並排，以利用空間。
- **平板版 (600px < 寬度 <= 1024px)**:
    - **首頁**: 維持分頁與清單的佈局，但卡片 (`TaskCard`) 可以一行顯示兩張。
- **手機版 (寬度 <= 600px)**:
    - 採用規格書中原定義的堆疊式 (Stack) 導航流程。

### 6.2 離線使用者體驗 (Offline UX)

- **App Shell 快取**: 應用程式的核心靜態資源 (HTML, CSS, JavaScript, 字體, 圖示) 必須被 Service Worker 快取，確保在離線時能立即載入基本外殼。
- **離線資料顯示**:
    - 當 App 處於離線狀態時，必須在 `AppBar` 下方顯示一個明顯的提示條 (Banner)，告知使用者「目前處於離線狀態」。
    - 已瀏覽過的任務清單與內容應從本地快取載入並顯示。
- **離線操作佇列 (Action Queue)**:
    - 對於所有會寫入資料庫的操作 (新增/編輯/承接/放棄/取消任務)，若在離線狀態下觸發，需將該操作的意圖 (Intent) 暫存於本地 (例如使用 `shared_preferences` 或本地資料庫)。
    - App 需監聽網路狀態。一旦網路恢復，應自動依序執行佇列中的操作，並在完成後清除。
    - 在佇列中的任務，應在 UI 上有明確標示 (例如：待同步圖示)。
