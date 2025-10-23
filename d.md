# 📦 Supabase Schema for DirectorStudio Agent

Use this as the authoritative schema for all Supabase integration.

### Table: `clip_jobs`
  - `id`: UUID (required)
  - `user_id`: UUID (required)
  - `user_key`: TEXT (required)
  - `prompt`: TEXT (required)
  - `status`: TEXT (required)
  - `submitted_at`: TIMESTAMP WITH TIME ZONE (required)
  - `completed_at`: TIMESTAMP WITH TIME ZONE (optional)
  - `download_url`: TEXT (optional)
  - `error_message`: TEXT (optional)

### Table: `continuity_daily_analytics`
  - `user_id`: UUID (optional)
  - `validation_date`: TIMESTAMP WITH TIME ZONE (optional)
  - `total_scenes`: BIGINT (optional)
  - `avg_confidence`: DOUBLE PRECISION (optional)
  - `scenes_passed`: BIGINT (optional)
  - `scenes_failed`: BIGINT (optional)
  - `min_confidence`: DOUBLE PRECISION (optional)
  - `max_confidence`: DOUBLE PRECISION (optional)
  - `confidence_stddev`: DOUBLE PRECISION (optional)

### Table: `continuity_logs`
  - `id`: UUID (required)
  - `scene_id`: INTEGER (required)
  - `confidence`: DOUBLE PRECISION (required)
  - `issues`: JSONB (required)
  - `passed`: BOOLEAN (required)
  - `timestamp`: TIMESTAMP WITH TIME ZONE (required)
  - `user_id`: UUID (required)
  - `created_at`: TIMESTAMP WITH TIME ZONE (required)

### Table: `continuity_recent_validations`
  - `user_id`: UUID (optional)
  - `scene_id`: INTEGER (optional)
  - `confidence`: DOUBLE PRECISION (optional)
  - `passed`: BOOLEAN (optional)
  - `issue_count`: INTEGER (optional)
  - `timestamp`: TIMESTAMP WITH TIME ZONE (optional)

### Table: `continuity_scene_states`
  - `id`: INTEGER (required)
  - `location`: TEXT (required)
  - `characters`: JSONB (required)
  - `props`: JSONB (required)
  - `prompt`: TEXT (required)
  - `tone`: TEXT (required)
  - `timestamp`: TIMESTAMP WITH TIME ZONE (required)
  - `user_id`: UUID (required)
  - `created_at`: TIMESTAMP WITH TIME ZONE (required)
  - `updated_at`: TIMESTAMP WITH TIME ZONE (required)

### Table: `continuity_telemetry`
  - `element`: TEXT (required)
  - `attempts`: INTEGER (required)
  - `successes`: INTEGER (required)
  - `rate`: DOUBLE PRECISION (required)
  - `timestamp`: TIMESTAMP WITH TIME ZONE (required)
  - `user_id`: UUID (required)
  - `created_at`: TIMESTAMP WITH TIME ZONE (required)
  - `updated_at`: TIMESTAMP WITH TIME ZONE (required)

### Table: `continuity_telemetry_performance`
  - `user_id`: UUID (optional)
  - `element`: TEXT (optional)
  - `attempts`: INTEGER (optional)
  - `successes`: INTEGER (optional)
  - `rate`: DOUBLE PRECISION (optional)
  - `performance_category`: TEXT (optional)
  - `last_updated`: TIMESTAMP WITH TIME ZONE (optional)

### Table: `credits_ledger`
  - `id`: UUID (required)
  - `user_key`: TEXT (required)
  - `credits`: INTEGER (required)
  - `first_clip_granted`: BOOLEAN (optional)
  - `first_clip_consumed`: BOOLEAN (optional)
  - `granted_at`: TIMESTAMP WITH TIME ZONE (optional)
  - `updated_at`: TIMESTAMP WITH TIME ZONE (optional)
  - `user_id`: UUID (optional)

### Table: `project_overview`
  - `project_id`: TEXT (optional)
  - `user_id`: UUID (optional)
  - `scene_count`: BIGINT (optional)
  - `total_duration`: DOUBLE PRECISION (optional)
  - `project_created_at`: TIMESTAMP WITH TIME ZONE (optional)
  - `last_updated`: TIMESTAMP WITH TIME ZONE (optional)

### Table: `scene_drafts`
  - `id`: UUID (required)
  - `user_id`: UUID (required)
  - `project_id`: TEXT (required)
  - `order_index`: INTEGER (required)
  - `prompt_text`: TEXT (required)
  - `duration`: DOUBLE PRECISION (required)
  - `scene_type`: TEXT (optional)
  - `shot_type`: TEXT (optional)
  - `created_at`: TIMESTAMP WITH TIME ZONE (required)
  - `updated_at`: TIMESTAMP WITH TIME ZONE (required)

### Table: `screenplay_sections`
  - `id`: UUID (required)
  - `screenplay_id`: UUID (required)
  - `heading`: TEXT (required)
  - `content`: TEXT (required)
  - `order_index`: INTEGER (required)
  - `created_at`: TIMESTAMP WITH TIME ZONE (required)

### Table: `screenplays`
  - `id`: UUID (required)
  - `user_id`: UUID (required)
  - `title`: TEXT (required)
  - `content`: TEXT (required)
  - `version`: INTEGER (required)
  - `created_at`: TIMESTAMP WITH TIME ZONE (required)
  - `updated_at`: TIMESTAMP WITH TIME ZONE (required)

### Table: `user_statistics`
  - `user_id`: UUID (optional)
  - `email`: CHARACTER VARYING (optional)
  - `credits`: INTEGER (optional)
  - `total_scenes`: BIGINT (optional)
  - `total_screenplays`: BIGINT (optional)
  - `completed_videos`: BIGINT (optional)
  - `last_activity`: TIMESTAMP WITH TIME ZONE (optional)

### Table: `video_uploads`
  - `id`: UUID (required)
  - `project_id`: TEXT (optional)
  - `order_index`: INTEGER (optional)
  - `filename`: TEXT (optional)
  - `uploaded_at`: TIMESTAMP WITHOUT TIME ZONE (optional)
  - `user_id`: UUID (optional)