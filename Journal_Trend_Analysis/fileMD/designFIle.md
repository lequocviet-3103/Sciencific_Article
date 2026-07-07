# Scientific Journal Publication Trend Tracking System
# API & Flutter Screens

> Dựa trên requirement hiện tại, tài liệu này bổ sung các API và màn hình Flutter còn thiếu. Những chức năng đã có thì giữ nguyên, chỉ bổ sung các API/UI cần thiết để hệ thống hoàn chỉnh.

---

# I. Authentication

## API

| Method | API | Mô tả |
|---------|-----|------|
| POST | /auth/register | Đăng ký |
| POST | /auth/login | Đăng nhập |
| POST | /auth/logout | Đăng xuất |
| POST | /auth/refresh-token | Refresh Token |
| POST | /auth/forgot-password | Quên mật khẩu |
| POST | /auth/reset-password | Đặt lại mật khẩu |
| POST | /auth/change-password | Đổi mật khẩu |
| GET | /users/me | Thông tin cá nhân |
| PUT | /users/me | Cập nhật hồ sơ |
| POST | /users/avatar | Upload avatar |

---

## Flutter Screens

- LoginScreen
- RegisterScreen
- ForgotPasswordScreen
- ResetPasswordScreen
- ProfileScreen
- EditProfileScreen
- ChangePasswordScreen

---

# II. Paper Module

## API

### Search Papers

```
GET /papers
```

Filter

- keyword
- author
- journal
- year
- field
- topic
- sort
- page
- size

Ví dụ

```
GET /papers?keyword=AI&year=2024
```

---

### Paper Detail

```
GET /papers/{id}
```

---

### Related Papers

```
GET /papers/{id}/related
```

---

### Latest Papers

```
GET /papers/latest
```

---

### Trending Papers

```
GET /papers/trending
```

---

### Popular Papers

```
GET /papers/popular
```

---

### Export Search Result

```
GET /papers/export?format=csv
```

---

## Flutter Screens

- PaperListScreen
- SearchScreen
- PaperDetailScreen
- RelatedPaperScreen
- LatestPaperScreen
- TrendingPaperScreen

---

# III. Journal Module

## API

```
GET /journals

GET /journals/{id}

GET /journals/{id}/papers

GET /journals/top

POST /journals/{id}/follow

DELETE /journals/{id}/follow

GET /journals/following
```

---

## Flutter Screens

- JournalListScreen
- JournalDetailScreen
- FollowJournalScreen

---

# IV. Author Module

## API

```
GET /authors

GET /authors/{id}

GET /authors/{id}/papers

GET /authors/top
```

---

## Flutter Screens

- AuthorListScreen
- AuthorDetailScreen

---

# V. Keyword Module

## API

```
GET /keywords

GET /keywords/popular

GET /keywords/trending

GET /keywords/{id}

POST /keywords/{id}/follow

DELETE /keywords/{id}/follow

GET /keywords/following
```

---

## Flutter Screens

- KeywordScreen
- KeywordDetailScreen
- PopularKeywordScreen

---

# VI. Research Topic Module

## API

```
GET /topics

GET /topics/trending

GET /topics/emerging

GET /topics/{id}

POST /topics/{id}/follow

DELETE /topics/{id}/follow

GET /topics/following
```

---

## Flutter Screens

- TopicListScreen
- TopicDetailScreen
- TrendingTopicScreen
- EmergingTopicScreen

---

# VII. Bookmark Module

## API

```
GET /bookmarks

POST /bookmarks

DELETE /bookmarks/{id}

POST /bookmarks/keyword

DELETE /bookmarks/keyword/{id}
```

---

## Flutter Screens

- BookmarkScreen
- SavedKeywordScreen

---

# VIII. Dashboard Module

## API

```
GET /dashboard/overview

GET /dashboard/publication-year

GET /dashboard/field

GET /dashboard/journal

GET /dashboard/top-authors

GET /dashboard/top-keywords

GET /dashboard/top-topics
```

---

## Flutter Screens

- DashboardScreen
- ChartPublicationScreen
- TopAuthorScreen
- TopKeywordScreen

---

# IX. Trend Analysis (Researcher)

## API

```
GET /analysis/keyword-trend

GET /analysis/topic-trend

GET /analysis/journal-trend

POST /analysis/compare-keywords

POST /analysis/compare-journals

GET /analysis/emerging-topics

GET /analysis/forecast

GET /analysis/heatmap
```

---

## Flutter Screens

- TrendAnalysisScreen
- KeywordTrendScreen
- JournalTrendScreen
- CompareTrendScreen
- ForecastScreen
- HeatmapScreen

---

# X. Report Module

## API

```
POST /reports

GET /reports

GET /reports/{id}

GET /reports/{id}/pdf

GET /reports/{id}/csv

DELETE /reports/{id}
```

---

## Flutter Screens

- ReportScreen
- CreateReportScreen
- ReportHistoryScreen

---

# XI. Notification Module

## API

```
GET /notifications

PUT /notifications/read/{id}

PUT /notifications/read-all

DELETE /notifications/{id}

GET /notifications/unread-count

GET /notification-settings

PUT /notification-settings
```

---

## Flutter Screens

- NotificationScreen
- NotificationSettingScreen

---

# XII. Admin - User Management

## API

```
GET /admin/users

GET /admin/users/{id}

POST /admin/users

PUT /admin/users/{id}

DELETE /admin/users/{id}

PUT /admin/users/{id}/ban

PUT /admin/users/{id}/unban

PUT /admin/users/{id}/reset-password

GET /admin/users/activity
```

---

## Flutter Screens

- AdminUserScreen
- CreateUserScreen
- EditUserScreen
- UserActivityScreen

---

# XIII. Admin - Data Source

## API

```
GET /admin/datasources

POST /admin/datasources

PUT /admin/datasources/{id}

DELETE /admin/datasources/{id}

PUT /admin/datasources/{id}/enable

PUT /admin/datasources/{id}/disable

GET /admin/datasources/{id}/health
```

---

## Flutter Screens

- DatasourceScreen
- DatasourceDetailScreen

---

# XIV. Admin - Synchronization

## API

```
POST /admin/sync/run

GET /admin/sync/logs

PUT /admin/sync/schedule

POST /admin/sync/deduplicate

GET /admin/storage
```

---

## Flutter Screens

- SyncScreen
- SyncLogScreen
- StorageScreen

---

# XV. Admin - Category Management

## API

### Journal

```
GET /admin/journals

POST /admin/journals

PUT /admin/journals/{id}

DELETE /admin/journals/{id}
```

### Keyword

```
GET /admin/keywords

POST /admin/keywords

PUT /admin/keywords/{id}

DELETE /admin/keywords/{id}

POST /admin/keywords/merge
```

### Topic

```
GET /admin/topics

POST /admin/topics

PUT /admin/topics/{id}

DELETE /admin/topics/{id}
```

### Paper

```
DELETE /admin/papers/{id}

PUT /admin/papers/{id}/hide
```

---

## Flutter Screens

- ManageJournalScreen
- ManageKeywordScreen
- ManageTopicScreen
- ManagePaperScreen

---

# XVI. Admin - System

## API

```
GET /admin/dashboard

GET /admin/system-config

PUT /admin/system-config

GET /admin/logs

POST /admin/backup

POST /admin/restore

GET /admin/statistics
```

---

## Flutter Screens

- AdminDashboardScreen
- SystemConfigScreen
- BackupScreen
- SystemLogScreen

---

# XVII. Role & Permission

## API

```
GET /roles

GET /permissions

PUT /roles/{id}

PUT /users/{id}/role
```

---

## Flutter Screens

- RoleManagementScreen
- PermissionScreen

---

# XVIII. Analytics APIs

Các API phục vụ biểu đồ trên Flutter.

```
GET /charts/publication-by-year

GET /charts/publication-by-month

GET /charts/publication-by-journal

GET /charts/publication-by-author

GET /charts/publication-by-topic

GET /charts/publication-by-keyword

GET /charts/publication-by-country

GET /charts/citation

GET /charts/trend
```

---

# XIX. Tổng số API

| Module | API |
|---------|----:|
| Authentication | 8 |
| User/Profile | 4 |
| Papers | 8 |
| Journal | 6 |
| Author | 4 |
| Keyword | 6 |
| Topic | 6 |
| Bookmark | 4 |
| Dashboard | 7 |
| Trend Analysis | 8 |
| Reports | 6 |
| Notifications | 6 |
| Admin User | 8 |
| Admin Data Source | 7 |
| Admin Synchronization | 5 |
| Admin Category | 12 |
| Admin System | 6 |
| Role & Permission | 4 |
| Charts | 9 |

---

# Tổng kết

## Tổng số API

**≈ 134 APIs**

---

## Tổng số màn hình Flutter

### Authentication

- LoginScreen
- RegisterScreen
- ForgotPasswordScreen
- ResetPasswordScreen
- ProfileScreen
- EditProfileScreen
- ChangePasswordScreen

### Paper

- PaperListScreen
- SearchScreen
- PaperDetailScreen
- RelatedPaperScreen
- LatestPaperScreen
- TrendingPaperScreen

### Journal

- JournalListScreen
- JournalDetailScreen
- FollowJournalScreen

### Author

- AuthorListScreen
- AuthorDetailScreen

### Keyword

- KeywordScreen
- KeywordDetailScreen
- PopularKeywordScreen

### Topic

- TopicListScreen
- TopicDetailScreen
- TrendingTopicScreen
- EmergingTopicScreen

### Bookmark

- BookmarkScreen
- SavedKeywordScreen

### Dashboard

- DashboardScreen
- ChartPublicationScreen
- TopAuthorScreen
- TopKeywordScreen

### Trend Analysis

- TrendAnalysisScreen
- KeywordTrendScreen
- JournalTrendScreen
- CompareTrendScreen
- ForecastScreen
- HeatmapScreen

### Reports

- ReportScreen
- CreateReportScreen
- ReportHistoryScreen

### Notification

- NotificationScreen
- NotificationSettingScreen

### Admin

- AdminDashboardScreen
- AdminUserScreen
- CreateUserScreen
- EditUserScreen
- UserActivityScreen
- DatasourceScreen
- DatasourceDetailScreen
- SyncScreen
- SyncLogScreen
- StorageScreen
- ManageJournalScreen
- ManageKeywordScreen
- ManageTopicScreen
- ManagePaperScreen
- SystemConfigScreen
- BackupScreen
- SystemLogScreen
- RoleManagementScreen
- PermissionScreen

---

## Tổng số màn hình Flutter

**Khoảng 45–50 màn hình**, đáp ứng đầy đủ 3 role:

- Admin
- Researcher
- Customer

đồng thời bao phủ toàn bộ requirement của hệ thống **Scientific Journal Publication Trend Tracking System**.