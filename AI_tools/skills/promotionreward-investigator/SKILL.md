---
name: promotionreward-investigator
description: Investigates failures in 91APP Promotion Console's reward/loyalty-point NMQ Worker flows (nine1.promotion.worker repo) — e.g. NMQ Task/TaskId execution failures, duplicate GivingPoint API blocks (ResultCode api_0004), DDB PromotionReward record stuck in WaitToReward, Lock contention, retry storms caused by hourly dispatcher CronJobs. Use when the user gives an NMQ TaskId, JobName (PromotionRewardLoyaltyPointsV2, BookingRewardLoyaltyPointsDispatcherV2, PromotionRewardBatchDispatcherV2, RecycleLoyaltyPointsV2, PromotionRewardCouponJob, etc.), a ShopId/MemberId/PromotionEngineId, or an order/orderCode and asks to investigate why a reward/point/coupon flow failed, why points were double-attempted, or why a job keeps retrying/failing. Combines Grafana Loki log tracing with reading the nine1.promotion.worker source code and checking Kubernetes CronJob schedules.
---

# PromotionReward Investigator

## Overview

Investigates failures/anomalies in the Promotion Console reward pipeline (loyalty points & coupons) by tracing NMQ Task logs in Loki, cross-referencing the actual DynamoDB record state, and reading the corresponding job source code in `C:\91APP\Promotion\worker\nine1.promotion.worker`. Produces a 現象/根因/建議 report.

## When a case comes in

Typical inputs: an NMQ TaskId (sometimes truncated by copy-paste — recover the full GUID first), a JobName, or a description like "給點失敗"/"重複給點"/"Job 一直 retry".

**Before running any Loki query, always confirm with the user first (do not guess or search blindly across markets — it is slow and wastes query budget):**
- **Market/env** (TW / HK / MY prod, or others) — this determines which Loki datasource/k8s context to use.
- **TaskId** (full GUID if available; if only a partial/truncated string is given, confirm that with the user and note it will need GUID recovery via Loki partial-string search).
- If TaskId is unknown, confirm at least one of: JobName, ShopId+MemberId+PromotionEngineId, or 訂單代碼/orderCode — enough to construct a targeted Loki query.

Only proceed to Loki querying once market is confirmed. If any of the above is genuinely ambiguous after asking, ask a follow-up rather than defaulting to a wide/blind search.

## Workflow

1. **Recover full TaskId (if truncated)**
   - If TaskId looks truncated (not 36 chars), search Loki with the partial string (`|= "<partial>"`) against the confirmed market's `service=prod-promotion-service` — the full GUID appears in `_props.CorrelationId` or in `Path: "/api/v1/tasks/<guid>"` lines.
   - Datasource UIDs / k8s contexts: see `references/environment-map.md`.

2. **Pull the full task timeline**
   - Query `grafana-mcp-query_loki_logs` with `logql: {service="prod-promotion-service"} |= "<TaskId>"`.
   - **`limit` is effectively capped around 100 rows regardless of the value passed.** A busy task easily exceeds this in a burst of ms-level logs. Check the returned first/last timestamp — if the span looks too short to contain "start → finish", narrow `startRfc3339`/`endRfc3339` and re-query in slices to get the full picture.
   - Log lines are **nested JSON** — the outer envelope's `_msg` field often contains another full JSON log line as a string (sometimes 2+ levels deep). Always recursively unwrap before reading `_msg`/`_lvl`/`_srctx`/`_props`. See `references/log-tracing.md` for the ready-to-use PowerShell unwrap snippet.
   - **`_props.CorrelationId` on low-level `NMQ.Core.Router.ProcessPool` lines is not always 1:1 with the business TaskId** (it can reflect the RabbitMQ delivery context of the polling loop). When correlating, prefer matching the literal TaskId string / `ShopId`+`MemberId`+`PromotionEngineId` / orderCode inside the log content over trusting the `CorrelationId` label alone.

3. **If the task failed with "訂單編號重複" (ResultCode `api_0004`) — do not stop here.**
   This means the loyalty-api's idempotency guard blocked a duplicate `GivingPoint` call — i.e., **some earlier call already succeeded** for that orderCode. Find that earlier success:
   - Extract the order code (e.g. `YSS00121987`) or `TradesOrderGroupCode`/`PromotionEngineId` from the failing log.
   - Search Loki for that order code string over a **wide window (48–72h)** — the original successful call and the DDB-update failure that caused the stuck state can be days earlier.
   - Confirm success via `"ResultCode":"api_0000"` and `"給點完成 TransactionCode:..."`.
   - Then look at what happened in the few seconds *after* that success — this is where the DDB update (`RewardStatus -> Reward`) should occur but often doesn't. Look for `Fatal` logs (e.g. `the task state is not 'ready' or 'pause'`), DynamoDB errors, or unexplained multi-second gaps with no logs (often indicates a hung/slow DynamoDB call or worker crash before the record could be persisted).
   - See `references/known-patterns.md` for the documented root-cause pattern (worker Fatal crash right after a successful GivingPoint call, leaving the DDB record permanently `WaitToReward`) and its downstream effects.

4. **Check the DDB record state directly if needed**
   - Table/GSI/key structure, RewardStatus/RewardDetailStatus enums: `references/ddb-and-state.md`.
   - A record log-dumped mid-investigation (`[DynamoDB Record]Get item from table...`) already shows the full JSON snapshot — no separate DB query tool is needed; read it from the Loki log itself.

5. **Identify which dispatcher created/re-created the task**
   - The task's input JSON has an `S3Key` field whose path segment names the creating dispatcher, e.g. `Prod/PromotionRewardBatchDispatcherV2/...` vs `Prod/BookingRewardLoyaltyPointsDispatcherV2Job/...`. This tells you whether it was the original direct-order flow or a re-scan by the hourly booking dispatcher.
   - `BookingRewardLoyaltyPointsDispatcherV2Job` scans a **1-hour sliding window** (`ExecuteTime-1h ~ ExecuteTime`, hour-truncated) of `WaitToReward` records every run — see `references/repo-and-jobs.md` for the exact query logic and why a stuck record gets repeatedly re-picked-up.
   - Confirm the actual cron cadence via `k8s-mcp-kubectl_describe resourceType=cronjob` in the relevant namespace/context (job names follow `<job-name-kebab-case>` in `prod-promotion-service`, e.g. `booking-reward-loyalty-points-dispatcher-v2-job`). Don't assume the schedule — verify it.

6. **Cross-reference source code**
   - Repo: `C:\91APP\Promotion\worker\nine1.promotion.worker`. Job classes live under `src\Nine1.Promotion.Console.NMQv3Worker\Jobs\PromotionReward\`; business logic (give/recycle points) in `src\Nine1.Promotion.Console.BL\Services\PromotionReward\LoyaltyPointService.cs`.
   - See `references/repo-and-jobs.md` for a map of the key jobs/classes/methods and how they relate to each other (dispatcher → worker → DDB update sequence).

7. **Produce the report** using `references/report-template.md` (現象/根因/建議), including:
   - Full timeline table (time / TaskId / creating dispatcher / event)
   - Financial/business impact assessment (duplicate-block by loyalty-api means points were NOT double-given — state this explicitly, it's usually the first thing people worry about)
   - Root cause (usually: a transient failure between "GivingPoint API success" and "DDB status update", leaving the record stuck)
   - Suggested fix: DDB record manual correction (which key/table), and process improvement (idempotency/compensation between the external API call and the DDB write)

## Cleanup

Delete any temp files written under the session's `files/` folder for large Loki query exports once the report is delivered.
