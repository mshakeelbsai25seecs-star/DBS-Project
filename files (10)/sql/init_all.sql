-- ============================================================
-- VIEWTUBE DATABASE — MASTER INIT SCRIPT
-- Run this ONE file to set everything up from scratch.
-- Order matters: schema → functions → views → triggers → procedures → data
-- ============================================================

SOURCE schema.sql;
SOURCE functions.sql;
SOURCE views.sql;
SOURCE triggers.sql;
SOURCE procedures.sql;
SOURCE sample_data.sql;

SELECT '✅ ViewTube database initialised successfully!' AS Status;
