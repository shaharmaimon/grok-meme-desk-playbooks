# Risk routine

```
Create a routine named "risk-daily" that runs every day at 06:30 Asia/Jerusalem. On each run: read /workspace/desk/playbooks/common.md and /workspace/desk/playbooks/risk.md and execute the review with at most 12 steps, no X plugin, no browser. Write /workspace/desk/reports/risk-<date>.md and at most 3 risk_proposal signals inside the allowed ranges. If /workspace/desk/cache/pnl.json is older than 6 hours, write the report with status=stale and no proposals. Post one line here: "risk: <n> proposals, 7d expectancy=<x>".
```
