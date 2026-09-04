# Ops routine

## Lean (hourly)
```
Create a routine named "ops-watchdog" that runs every hour. On each run: read /workspace/desk/playbooks/ops.md and execute steps 1-5 exactly, with at most 6 steps and only the four allowed commands. Always write /workspace/desk/state/ops/heartbeat.json and a heartbeat signal. Post one line here: "ops: uplink=<alive|restarted|dead>, outbox=<n>, cache=<age>s".
```

## Standard (every 30 minutes)
```
Update the routine "ops-watchdog" to run every 30 minutes.
```

Before enabling: in Settings → General → Auto-review add Always Allow rules for exactly the four commands listed in `playbooks/ops.md`, and a Require Approval rule for `curl`, `wget`, `ssh`, `scp`, `nc`.
