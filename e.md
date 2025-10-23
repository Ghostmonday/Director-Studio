### Handoff: Supabase-integrated App — PR-ready deliverables

---

### Overview
This package contains everything your AI agent coder needs to implement Supabase as the authoritative backend, wire a local-first UI, and deliver an auditable, optimistic-create project library and clip-job flow. It includes: a single Postgres migration SQL file, API/Sync contracts, LocalStorageService / SyncService interface sketches, ViewModel responsibilities and sample methods, UI wiring checklist, telemetry hooks, test cases, and release acceptance criteria.

---

### Migration SQL (single file)
Save as migrations/2025_10_22_create_directorstudio_schema.sql.

```sql
-- migrations/2025_10_22_create_directorstudio_schema.sql
BEGIN;

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Users table reference (minimal) for FK use if not present
CREATE TABLE IF NOT EXISTS app_users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- clip_jobs
CREATE TABLE IF NOT EXISTS clip_jobs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  user_key TEXT NOT NULL,
  prompt TEXT NOT NULL,
  status TEXT NOT NULL,
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ,
  download_url TEXT,
  error_message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_clip_jobs_user_status_submitted ON clip_jobs(user_id, status, submitted_at);

-- continuity_daily_analytics
CREATE TABLE IF NOT EXISTS continuity_daily_analytics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID,
  validation_date TIMESTAMPTZ,
  total_scenes BIGINT,
  avg_confidence DOUBLE PRECISION,
  scenes_passed BIGINT,
  scenes_failed BIGINT,
  min_confidence DOUBLE PRECISION,
  max_confidence DOUBLE PRECISION,
  confidence_stddev DOUBLE PRECISION,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- continuity_logs
CREATE TABLE IF NOT EXISTS continuity_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  scene_id INTEGER NOT NULL,
  confidence DOUBLE PRECISION NOT NULL,
  issues JSONB NOT NULL,
  passed BOOLEAN NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL,
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_continuity_logs_user_scene_time ON continuity_logs(user_id, scene_id, timestamp);

-- continuity_recent_validations
CREATE TABLE IF NOT EXISTS continuity_recent_validations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID,
  scene_id INTEGER,
  confidence DOUBLE PRECISION,
  passed BOOLEAN,
  issue_count INTEGER,
  timestamp TIMESTAMPTZ
);

-- continuity_scene_states
CREATE TABLE IF NOT EXISTS continuity_scene_states (
  id BIGSERIAL PRIMARY KEY,
  location TEXT NOT NULL,
  characters JSONB NOT NULL,
  props JSONB NOT NULL,
  prompt TEXT NOT NULL,
  tone TEXT NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL,
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_continuity_scene_states_user ON continuity_scene_states(user_id);

-- continuity_telemetry
CREATE TABLE IF NOT EXISTS continuity_telemetry (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  element TEXT NOT NULL,
  attempts INTEGER NOT NULL DEFAULT 0,
  successes INTEGER NOT NULL DEFAULT 0,
  rate DOUBLE PRECISION NOT NULL DEFAULT 0,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_continuity_telemetry_element_time ON continuity_telemetry(element, timestamp);

-- continuity_telemetry_performance
CREATE TABLE IF NOT EXISTS continuity_telemetry_performance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID,
  element TEXT,
  attempts INTEGER,
  successes INTEGER,
  rate DOUBLE PRECISION,
  performance_category TEXT,
  last_updated TIMESTAMPTZ
);

-- credits_ledger
CREATE TABLE IF NOT EXISTS credits_ledger (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_key TEXT NOT NULL,
  credits INTEGER NOT NULL DEFAULT 0,
  first_clip_granted BOOLEAN DEFAULT FALSE,
  first_clip_consumed BOOLEAN DEFAULT FALSE,
  granted_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  user_id UUID REFERENCES app_users(id)
);

CREATE INDEX IF NOT EXISTS ix_credits_ledger_userkey ON credits_ledger(user_key);

-- project_overview
CREATE TABLE IF NOT EXISTS project_overview (
  project_id TEXT PRIMARY KEY,
  user_id UUID,
  scene_count BIGINT,
  total_duration DOUBLE PRECISION,
  project_created_at TIMESTAMPTZ,
  last_updated TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS ix_project_overview_user ON project_overview(user_id);

-- scene_drafts
CREATE TABLE IF NOT EXISTS scene_drafts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  project_id TEXT NOT NULL REFERENCES project_overview(project_id) ON DELETE CASCADE,
  order_index INTEGER NOT NULL,
  prompt_text TEXT NOT NULL,
  duration DOUBLE PRECISION NOT NULL,
  scene_type TEXT,
  shot_type TEXT,
  archived BOOLEAN DEFAULT FALSE,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_scene_drafts_project_order ON scene_drafts(project_id, order_index);

-- screenplay_sections
CREATE TABLE IF NOT EXISTS screenplay_sections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  screenplay_id UUID NOT NULL,
  heading TEXT NOT NULL,
  content TEXT NOT NULL,
  order_index INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE screenplay_sections ADD CONSTRAINT fk_screenplay_sections_screenplays FOREIGN KEY (screenplay_id) REFERENCES screenplays(id) ON DELETE CASCADE;

-- screenplays
CREATE TABLE IF NOT EXISTS screenplays (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  version INTEGER NOT NULL DEFAULT 1,
  archived BOOLEAN DEFAULT FALSE,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_screenplays_user ON screenplays(user_id);

-- user_statistics
CREATE TABLE IF NOT EXISTS user_statistics (
  user_id UUID PRIMARY KEY,
  email VARCHAR,
  credits INTEGER,
  total_scenes BIGINT,
  total_screenplays BIGINT,
  completed_videos BIGINT,
  last_activity TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- video_uploads
CREATE TABLE IF NOT EXISTS video_uploads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id TEXT REFERENCES project_overview(project_id) ON DELETE SET NULL,
  order_index INTEGER,
  filename TEXT,
  uploaded_at TIMESTAMP WITHOUT TIME ZONE,
  user_id UUID REFERENCES app_users(id)
);

-- Triggers to maintain updated_at
CREATE OR REPLACE FUNCTION touch_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger to tables that have updated_at
DROP TRIGGER IF EXISTS trg_touch_clip_jobs ON clip_jobs;
CREATE TRIGGER trg_touch_clip_jobs BEFORE UPDATE ON clip_jobs FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

DROP TRIGGER IF EXISTS trg_touch_continuity_scene_states ON continuity_scene_states;
CREATE TRIGGER trg_touch_continuity_scene_states BEFORE UPDATE ON continuity_scene_states FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

DROP TRIGGER IF EXISTS trg_touch_continuity_telemetry ON continuity_telemetry;
CREATE TRIGGER trg_touch_continuity_telemetry BEFORE UPDATE ON continuity_telemetry FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

DROP TRIGGER IF EXISTS trg_touch_scene_drafts ON scene_drafts;
CREATE TRIGGER trg_touch_scene_drafts BEFORE UPDATE ON scene_drafts FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

DROP TRIGGER IF EXISTS trg_touch_screenplays ON screenplays;
CREATE TRIGGER trg_touch_screenplays BEFORE UPDATE ON screenplays FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

COMMIT;
```

---

### API / Sync contracts (hand-off interfaces)
Provide these endpoints or Supabase function names. Use REST or direct Supabase client as appropriate.

- Projects
  - getProjectOverviews(user_id) -> SELECT * FROM project_overview WHERE user_id = $1 ORDER BY last_updated DESC
  - upsertProjectOverview(payload) -> UPSERT into project_overview
- Scene Drafts
  - listSceneDrafts(project_id) -> SELECT * FROM scene_drafts WHERE project_id = $1 AND archived = false ORDER BY order_index
  - createSceneDraft(payload) -> INSERT into scene_drafts RETURNING id
  - updateSceneDraft(id, patch) -> UPDATE scene_drafts SET ... WHERE id = $1
  - reorderSceneDrafts(project_id, ordered_ids[]) -> batch UPDATE order_index
  - softDeleteSceneDraft(id) -> UPDATE scene_drafts SET archived = true, deleted_at = now() WHERE id = $1
- Clip Jobs
  - enqueueClipJob(payload) -> INSERT into clip_jobs; return id
  - getClipJobStatus(user_id, job_id) -> SELECT status, download_url, error_message FROM clip_jobs WHERE id = $1 AND user_id = $2
  - listClipJobs(user_id, limit, offset)
  - webhook handler or Realtime subscription: on clip_jobs update push to client
- Credits Ledger
  - getCredits(user_key) -> SELECT * FROM credits_ledger WHERE user_key = $1
  - adjustCredits(user_key, delta) -> idempotent upsert and RETURN credits
- Telemetry
  - batchUpsertTelemetry(batch[]) -> use INSERT ... ON CONFLICT(element, user_id, date) DO UPDATE to increment attempts/successes and recalc rate
- Continuity
  - insertContinuityLog(payload) -> INSERT continuity_logs
  - upsertRecentValidation(payload) -> UPSERT into continuity_recent_validations
  - appendDailyAnalytics(payload) -> INSERT

Contract patterns:
- Use UUIDs for client-generated ids. For optimistic creates, client inserts local UUID and sends same id to server upsert.
- All write ops must be idempotent with unique constraint on client-provided id.

---

### LocalStorageService & SyncService interfaces (sketches)
Provide language-agnostic interfaces. Implement durable queue and reconciliation.

- LocalStorageService (methods)
  - getProjectOverviews(userId): ProjectOverview[]
  - getSceneDrafts(projectId): SceneDraft[]
  - upsertSceneDraft(sceneDraft): SceneDraft
  - markSceneDraftArchived(id)
  - upsertClipJob(clipJob)
  - getPendingSyncEntries(): SyncEntry[]
  - enqueueSync(entry: SyncEntry)
  - removeSyncEntry(entryId)
  - subscribe(key, callback) -> in-app pub/sub for UI updates

- SyncService (methods)
  - start(): opens realtime subscriptions and drains local queue
  - stop()
  - enqueueRemoteUpsert(tableName, record): returns promise of remote confirmation
  - enqueueRemoteDelete(tableName, id)
  - reconcileServerDelta(tableName, serverRecords[]):
    - merge into local cache using last-writer-wins and produce conflict events when field-level differences detected
  - subscribeToRemote(tableName, userId, onChange)
  - pollClipJobStatus(jobId) or registerWebhook(endpoint)

- Sync semantics
  - Local-first rendering: UI reads LocalStorageService, then SyncService.fetchAndReconcile
  - Optimistic create: LocalStorageService.upsertSceneDraft with temp id -> SyncService.enqueueRemoteUpsert
  - On remote confirm: SyncService updates local record id mapping if server replaced id (avoid where possible by using client id)
  - Conflict event schema:
    - { table, id, local, remote, diffFields, resolutionChoices }
  - Queue persistence: store queue as table or local DB; retry with exponential backoff.

---

### ViewModels, UI wiring, and telemetry hooks
Provide method prototypes, states, and acceptance expectations per ViewModel.

- ProjectListViewModel
  - state: { items: ProjectOverview[], status: enum, error, lastLoadedAt }
  - methods:
    - loadList(): render local immediately, call syncService.fetchProjectOverview(userId), reconcile, emit telemetry library_load
    - createProjectQuick(prompt?): returns tempProjectId; LocalStorageService.upsertProjectOverview(); enqueue New Project creation flow; emit create_initiated
    - importSample(): inserts seed project
  - acceptance:
    - Renders local cache within 200ms.
    - createProjectQuick shows "Saving…" until server persisted; emits create_confirmed or create_failed.

- ProjectRowViewModel
  - methods:
    - openProject(projectId)
    - quickActions: rename(id, name), duplicate(id), archive(id)
  - telemetry: emit project_open, project_action_{rename|duplicate|archive}

- SceneEditorViewModel
  - methods:
    - loadScenes(projectId)
    - createSceneOptimistic(payload) -> temp id, enqueue upsert, emit scene_create_initiated
    - reorderScenes(orderedIds)
    - saveScene(id, patch)
  - acceptance:
    - Reorder persisted and visible after sync; scene edits reconciled without data loss or with merge UI.

- ClipJobViewModel
  - methods:
    - submitClip(prompt, user_key) -> upsert local clip_job status=queued; enqueue remote; emit clip_job_submitted
    - pollStatus(jobId) / subscribeToRealtime(jobId) -> update status; when completed set download_url and emit clip_job_completed
    - cancelJob(jobId)
  - acceptance:
    - clip_jobs transitions propagate to UI and download_url present when completed.

- Telemetry hooks
  - Emit events: library_load, create_initiated, create_confirmed, create_failed, clip_job_submitted, clip_job_completed, sync_latency, conflict_detected.
  - Batch write telemetry to continuity_telemetry using upsert with increment semantics at periodic intervals.

---

### Tests, Acceptance Criteria, and Rollout checklist
- Unit tests
  - ProjectListViewModel.loadList: local-first render and reconciliation path.
  - SceneEditorViewModel.createSceneOptimistic: temp id insertion, enqueue call, local visible.
  - ClipJobViewModel.submitClip: local job created, remote enqueue invoked.

- Integration tests
  - Local insert -> SyncService.upsert -> server persisted -> local id reconciliation when server assigns id.
  - Realtime update from clip_jobs updates local cache and UI.

- E2E tests
  - Empty-state flow: launch with no projects -> empty message visible -> create path creates project and appears in list.
  - Offline create: create scene while offline -> reconnect -> verify server persisted and credits ledger updated if applicable.
  - Conflict path: two edits on same scene_drafts record -> conflict UI appears and choosing merge records an entry in continuity_logs.

- Performance & SLA
  - ProjectLibraryView must render local cache within 200ms on median device.
  - Sync acknowledgment for optimistic creates must succeed or requeue within configurable retry window (default 60s, exponential backoff).
  - clip_jobs status updates must reach UI within 5s of server change via Realtime/webhook; otherwise fall back to polling every 10s.

- Rollout checklist
  - Deploy DB migration in staging; run migration integrity and FK checks.
  - Smoke test: seed user; verify ProjectLibrary local render; create scene; submit clip_job; verify telemetry rows.
  - Canary release to 5% users; monitor sync failure rate & telemetry.
  - Full release when sync failure < 1% and create-to-confirm latency median < 3s.

---

### PR-ready task list (issue titles + acceptance)
1. Define and add migration SQL file to repo.  
   - Acceptance: DB schema created in staging with all tables, indices, triggers.
2. Implement LocalStorageService (local DB) models mirroring Supabase tables.  
   - Acceptance: unit tests for get/upsert/enqueue pass.
3. Implement SyncService adapter for Supabase with durable queue and realtime subscription.  
   - Acceptance: queue persisted across app restart; realtime updates update local cache.
4. Wire ProjectListViewModel to local-first load + optimistic create flow.  
   - Acceptance: local render within 200ms; create shows saving badge then confirmed.
5. Integrate clip_jobs handling: enqueue, poll/webhook subscribe, update local cache and UI.  
   - Acceptance: clip job lifecycle visible and download_url appears when completed.
6. Implement credits_ledger checks in create/clip flows with idempotent consumption.  
   - Acceptance: first_clip flags update exactly once per user_key.
7. Add telemetry emitter and batch writer to continuity_telemetry.  
   - Acceptance: required telemetry events stored and aggregated.
8. Add tests: unit, integration, E2E for offline and conflict flows.  
   - Acceptance: CI green for test matrix.
9. Seed migration data for empty-state / sample import to enable UX QA.  
   - Acceptance: sample project visible in staging.

---

### Final delivery notes
- Use client-generated UUIDs to avoid server-side id swaps; only allow server-assigned ids when unavoidable and ensure mapping code handles replacement.
- Keep sync queue durable and observable; expose queue health telemetry.
- Prioritize simple, auditable SQL (UPSERT semantics) and record conflict resolutions in continuity_logs for review.
- Hand off migration SQL plus the interface sketches and PR-ready tasks above to the AI agent coder for immediate implementation and test automation.