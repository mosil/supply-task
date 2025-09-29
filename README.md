# supply_task

補給任務

## 設定

### 1. Firebase 專案與 CLI

1. 前往 [Firebase Console](https://console.firebase.google.com/) 新增一個 Firebase 專案。
2. 在您的本機環境中安裝 [Firebase CLI](https://firebase.google.com/docs/cli#install_the_firebase_cli)。
3. 在專案根目錄執行 `flutterfire configure`，依照指示將 Flutter 專案與 Firebase 連結。
    * **重要**: 執行後，請檢查 `lib/firebase_options.dart` 檔案，確保 `web`, `android`, `ios` 等平台的 `FirebaseOptions`
      中，都包含了 `databaseURL: 'https://<YOUR_PROJECT_ID>-default-rtdb.firebaseio.com'` 這一行。如果沒有，請手動補上。
4. 在 Firebase Console 中，手動啟用並建立 **Firestore Database** 和 **Realtime Database**。
    * **重要**: 在 Realtime Database 中，手動建立 `/projects` 節點，並加入您的專案 ID 和名稱，例如：
      ```json
      {
        "projects": {
          "hualien-matayan-landslide-2025": "2025 花蓮馬太鞍溪堰塞湖災害"
        }
      }
      ```
    * **重要**: 更新 Realtime Database 的安全性規則，允許公開讀取 `/projects` 節點：
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

### 2. Google 登入設定

1. 在 Firebase Console 的 **Authentication** 服務中，啟用 **Google** 登入方式。
2. 前往 [Google Cloud Console](https://console.cloud.google.com/)，在您的專案中啟用 **Google People API** (這是 Google
   登入所需的 API)。
3. **重要**: 將 `.env.example` 檔案複製為 `.env`，並在 `.env` 檔案中填入您的 Google 登入 Web Client ID：
   ```
   GOOGLE_WEB_CLIENT_ID=您的Google登入WebClientID
   ```
    * 這個 ID 可以在 Firebase Console 的 Authentication -> 登入方式 -> Google -> 網頁 SDK 設定中找到。

### 3. 本地開發

1. 執行 `flutter run -d chrome --web-port=5000`。
    * `--web-port=5000` 是為了符合 Google OAuth 的授權重新導向 URI 設定。

### 4. 部署到 Firebase Hosting

1. 確保 `firebase.json` 檔案中包含 Hosting 設定 (已自動加入)。
2. 在專案根目錄執行 `firebase use <您的專案ID>`，將當前目錄與您的 Firebase 專案連結。
3. 執行 `flutter build web` 建置網頁應用程式。
4. 執行 `firebase deploy --only hosting` 部署到 Firebase Hosting。

## 你可能會遇到的問題

1. `.env` 環境變數未設定
    - 看到的錯誤訊息
      ```
      Error while trying to load an asset: Flutter Web engine failed to fetch "assets/.env". HTTP request succeeded, but
      the server responded with HTTP status 404.

## Acknowledgements / 致謝

This project was initiated and developed by [Ahdaa](https://github.com/mosil). If you find this project helpful or have
used it as a basis for your own work, we would appreciate an attribution by linking back to the original repository.
Your support is the greatest motivation for us to continue contributing to open source!

本專案由 [Ahdaa](https://github.com/mosil) 發起並開發。如果您發現這個專案對您有幫助，或您基於此專案進行了二次開發，我們誠摯地希望您能在您的作品中標註來源，並附上原始專案的
GitHub 連結。您的支持是我們持續開源的最大動力！

---

## Contributor / 貢獻者

- [Ahdaa](https://github.com/mosil)

## License / 授權聲明

This project is licensed under the MIT License.

本專案採用 MIT 授權條款。

### MIT License

Copyright (c) 2025 Ahdaa

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

### MIT 授權條款（中文翻譯僅供參考）

版權所有 (c) 2025 Ahdaa

特此授予任何人免費獲得本軟體和相關文件檔案（「本軟體」）副本的權利，得無限制地處理本軟體，包括但不限於使用、複製、修改、合併、發布、散布、再授權和/或銷售本軟體副本的權利，並允許獲提供本軟體的人員進行上述操作，但須符合以下條件：

上述版權聲明和本許可聲明應包含在本軟體的所有副本或主要部分中。

本軟體乃以「現況」提供，不作任何明示或暗示的保證，包括但不限於可銷售性、特定用途適用性和無侵權的保證。在任何情況下，作者或版權持有人均不對任何索賠、損害或其他責任負責，無論是在合約、侵權或其他訴訟中，源自、出於或與本軟體或本軟體的使用或其他人為交易有關。