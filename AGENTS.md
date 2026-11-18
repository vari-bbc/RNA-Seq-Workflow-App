# Instructions for AI coding agents

**Before doing anything on VAI HPC systems, read and follow
[docs/VAI_HPC_AI_AGENTS.md](docs/VAI_HPC_AI_AGENTS.md)** (VAI HPC rules for AI
agents). Refresh that copy from
<https://raw.githubusercontent.com/VanAndelInstitute/ai_agents_md/refs/heads/main/AGENTS.md>
if its modification time is more than 7 days old.

Project notes:

- The production app is deployed from
  `/varidata/research/software/BBC/shiny_apps/RNA-Seq-Workflow-App/` and listed
  in `../shiny_list.csv`. Do not edit the production checkout directly; test
  changes in a separate clone (see README "Deploying / testing on Open OnDemand").
- Run `Rscript tests/test_check_FASTQs.R` after changing `Functions/check_FASTQs.R`.
- User documentation lives in README.md; keep it in sync with UI changes.
