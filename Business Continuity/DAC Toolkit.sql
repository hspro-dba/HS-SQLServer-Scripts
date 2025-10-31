/* ---------------------------------------------
|      DAC Toolkit PRO - HS                    |
|      Hugo Silva Database Administrator PRO   |
|      Copyright (C) 2022 - 2025 HS PRO        |
|      Licensed under the MIT License.         |
*/ ---------------------------------------------

/*
 * Dedicated Administrator Connection Toolkit - Business Continuity Module
 * This script sets up the necessary queries for DAC and troubleshoot resources gaps.
 */

/* Query 01: Check quantity of sessions and pool exhaustion
 * 
 * Problem: Users are complaining about not being able to log in the system.
 * Reason: Probally your pool has been exausted and users cannot log in your environment due to lack of available sessions.
 * Solution 01: Check your application pool settings and increase the maximum number of sessions allowed.
 * Solution 02: Identity and kill unused or idle sessions.
 * Solution 03: Identify and notify what host/user is consuming most of the sessions to your application team.
 */

SELECT COUNT(session_id) AS session_count
FROM sys.dm_exec_sessions
WHERE is_user_process = 1;
GO

/* Query 02: Check active transactions */
SELECT COUNT(transaction_id) AS active_transaction_count
FROM sys.dm_tran_active_transactions;
GO

/* Query 03: Verify Top consumer queries */
SELECT TOP 10 
    total_worker_time / execution_count AS avg_cpu_time,
    execution_count,
    total_elapsed_time / execution_count AS avg_elapsed_time,
    SUBSTRING(qt.text, (qs.statement_start_offset/2) + 1,
    ((CASE qs.statement_end_offset
        WHEN -1 THEN DATALENGTH(qt.text)
        ELSE qs.statement_end_offset
      END - qs.statement_start_offset)/2) + 1) AS query_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
ORDER BY avg_cpu_time DESC;
GO

/* Query 04: Analyse Top Locks in Environment */
SELECT TOP 10
    request_session_id,
    resource_type,
    resource_description,
    COUNT(*) AS lock_count
FROM sys.dm_tran_locks
GROUP BY request_session_id, resource_type, resource_description
ORDER BY lock_count DESC;
GO

/* Query 05: Any triggers blocking logins? 
 *
 * Problem: No one can log in the system even with low resource usage.
 * Reason: There might be a server trigger blocking logins.
 * Solution 01: Identify and disable the trigger temporarily to allow logins.
 * Solution 02: Review the trigger logic to ensure it is not overly restrictive. (hurry up!)
 */
 
SELECT name, is_disabled
FROM sys.server_triggers
WHERE is_disabled = 0;
GO

/* End of DAC Toolkit - Business Continuity Module */