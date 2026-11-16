# OpenClaw retirement

OpenClaw was removed from Chopper's configuration on 2026-11-16. Hermes Agent,
its Signal daemon, and its Tailscale Serve endpoint are also being retired as
part of the same recovery deployment.

The former OpenClaw implementation and runbook are preserved in repository
history before change `uvzpnsok`. Runtime state is not repository history;
existing state directories are retained during the deployment.

See [the workstation migration plan](chopper-workstation-migration.md) for the
remaining Chopper/C3po migration work.
