MY JOURNEYS V2 - GitHub Pages + Supabase

檔案：
- index.html：升級後網站（保留原有行程、航班、票券、預算、支出、行李功能）
- config.js：填入 Supabase Project URL 與 Publishable key
- supabase_upgrade.sql：在既有 Supabase 專案執行一次的升級 SQL

設定步驟：
1. 在 config.js 將 publishableKey 的提示文字換成你自己的 sb_publishable_... 金鑰。不要使用 sb_secret_ 或 service_role。
2. Supabase SQL Editor 執行 supabase_upgrade.sql。此 SQL 建立私人 trip-files Storage bucket、附件權限，以及接受邀請的 RPC。
3. 將 index.html、config.js、supabase_upgrade.sql 一起放在 GitHub repository 根目錄。
4. GitHub Pages 發布後，在 Supabase Authentication > URL Configuration 設定 Site URL 為實際 GitHub Pages 網址，並將該網址加入 Redirect URLs。
5. 使用者註冊時會收到 Email 驗證信。驗證完成後登入。

注意：
- Supabase Storage 附件目前限制單檔 20MB，只允許 JPEG、PNG、WebP、GIF、PDF。
- 附件存在私人 bucket，只有該趟旅程成員可讀取；上傳需 owner/editor 權限。
- 舊版 localStorage 旅程在首次登入且雲端沒有旅程時，會詢問是否匯入。
- 這版提供基本即時同步與邀請流程；上線前請先用兩個測試帳號測試權限。
- 邀請連結為一次性、7 天有效，並綁定受邀 Email。
