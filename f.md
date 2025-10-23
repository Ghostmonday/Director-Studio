### Integration Summary
A compact integration plan that makes the provided Supabase schema the single source of truth and maps tables to the App launch flow, viewmodels, sync behavior, telemetry, and acceptance tests. Prioritizes local-first UX, optimistic creates, conflict reconciliation, and minimal, auditable SQL interactions.

---

### Data → UI Mapping (table)
| Supabase table | Purpose | Used by (View/ViewModel) | Key operations |
|---|---:|---|---|
| **clip_jobs** | Backend job lifecycle for clip generation | ProjectDetailView, ClipJobViewModel | enqueue job; poll status; store download_url |
| **scene_drafts** | Scenes within a project (authoring) | ProjectLibraryView, SceneEditorViewModel | list drafts; create/update/delete; reorder |
| **project_overview** | Quick project aggregates for library list | ProjectLibraryView, ProjectListViewModel | read aggregates; refresh after sync |
| **video_uploads** | Attached uploads for a project | ProjectDetailView, UploadManager | upload metadata; list; order |
| **credits_ledger** | User credits and first-clip gating | Create flows, BillingViewModel | charge/credit; check first_clip flags |
| **continuity_scene_states** | Canonical scene state for validations | ContinuityService, ValidatorViewModel | snapshot state; read for continuity checks |
| **continuity_logs** | Validation detail rows | Continuity UI, LogsViewModel | insert logs; list per scene |
| **continuity_recent_validations** | Fast recent validation display | ProjectLibraryView, ContinuitySummaryVM | upsert recent validations |
| **continuity_daily_analytics** | Aggregated daily metrics | AnalyticsView, ReportingService | append daily aggregates |
| **continuity_telemetry** | Event-level telemetry counters | TelemetryService, TelemetryViewModel | increment attempts/successes; compute rates |
| **continuity_telemetry_performance** | Performance categorizations | Telemetry dashboards | update rates by category |
| **screenplays** | Full screenplay documents | ScreenplayEditorView | CRUD screenplay; versioning |
| **screenplay_sections** | Sections for screenplay editor | ScreenplayEditorViewModel | list/insert/update sections |
| **user_statistics** | Denormalized user stats for UI | ProjectLibraryViewModel | read-only dashboard values |
| **video_uploads** | Upload metadata | UploadManager | list uploads; display timestamps |

---

### Sync, Local-first & UX behaviors
- **Local-first pattern**: LocalStorageService mirrors relevant tables (scene_drafts, project_overview, clip_jobs) as authoritative UI cache. UI renders immediately from local cache then reconciles with Supabase.
- **Optimistic create**: Creating project/scene creates local row with temporary UUID, enqueues an upsert to SupabaseSync, shows “Saving…” badge; on remote confirmation replace temp id and clear queue.
- **Conflict resolution**: For edits on same id, prefer **last-writer-wins** by default and surface a **merge UI** when conflicting fields differ in authoritative tables (scene_drafts, continuity_scene_states); record decision in continuity_logs for audit.
- **Sync queue**: Durable local queue persisted to handle offline → online replay for insert/update/delete on mapped tables.
- **Polling & webhooks**: clip_jobs polled for status changes or use Supabase Realtime/webhook to push status updates into local cache.

---

### Schema constraints, indices, and recommended SQL additions
- Add PRIMARY KEYs where missing: scene_drafts(id), clip_jobs(id), screenplays(id).
- Add FOREIGN KEYs for referential integrity: scene_drafts.project_id → project_overview.project_id; clip_jobs.user_id → users.id; screenplay_sections.screenplay_id → screenplays.id.
- Recommended indices:
  - clip_jobs(user_id, status, submitted_at)
  - scene_drafts(project_id, order_index)
  - continuity_logs(user_id, scene_id, timestamp)
  - continuity_telemetry(element, timestamp)
- Soft-delete pattern: add boolean `archived` and `deleted_at` timestamps to scene_drafts and screenplays for reversible actions.
- Audit columns: ensure `created_at` / `updated_at` default to now() with triggers for consistency where absent.

---

### API contracts, viewmodel responsibilities, and telemetry hooks
- ViewModels should expose these primitives:
  - loadList(): returns local cache + remote reconcile.
  - createOptimistic(payload): local insert, enqueue remote upsert, return temp id.
  - syncStatus(id): exposes enum {local-only, syncing, persisted, conflict, error}.
  - reconcile(conflictResolution): apply chosen merge and write to Supabase.
- Telemetry hooks:
  - Emit events for: library_load, create_initiated, create_confirmed, create_failed, sync_latency, clip_job_submitted, clip_job_completed, continuity_validation_run.
  - Map telemetry counters to continuity_telemetry and continuity_telemetry_performance with batch upserts.

---

### Tests, migrations, and rollout checklist
- Migrations:
  - Create tables with explicit PKs/FKs, indices, and default timestamps.
  - Add soft-delete columns and triggers for updated_at.
  - Seed: sample project_overview row and one scene_draft for empty-state UX testing.
- Tests:
  - Unit: ProjectListViewModel load/optimistic create/merge behavior.
  - Integration: Local insert → Supabase upsert -> id reconciliation for scene_drafts and clip_jobs.
  - E2E: Offline create scenes -> reconnect -> verify server persisted and credits_ledger updated.
  - Telemetry: continuity_telemetry counters increment with success/failure scenarios.
- Acceptance criteria:
  - ProjectLibraryView must render local cache within 200ms of launch.
  - Create flow creates local row instantly and persists to Supabase within retry window.
  - clip_jobs status transitions propagate to UI and download_url appears after completed.
  - Conflicts detected show merge UI and result recorded in continuity_logs.

---

### Developer checklist (PR-ready tasks)
- [ ] Define Supabase migration SQL for all tables with PKs, FKs, indices, and defaults.
- [ ] Implement LocalStorageService models mirroring Supabase tables.
- [ ] Implement SyncService adapter for Supabase with durable queue and webhook fallback.
- [ ] Wire ProjectListViewModel to use local-first load + reconcile; add optimistic create path.
- [ ] Integrate clip_jobs handling: enqueue, poll/webhook subscribe, update local cache.
- [ ] Implement credits_ledger checks in create/clip flows and idempotent consumption.
- [ ] Add telemetry emitter and periodic batch writer to continuity_telemetry tables.
- [ ] Add migrations seed data for empty-state / sample import.
- [ ] Write unit/integration tests for load/create/sync/conflict paths.

--- 
