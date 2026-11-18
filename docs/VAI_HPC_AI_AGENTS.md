# Instructions for AI Coding Agents and Automated Tools on VAI HPC Systems

This document contains operational and safety instructions for AI coding agents and other automated tools used on Van Andel Institute High Performance Computing systems.

It applies to tools including OpenAI Codex, Codex CLI, Anthropic Claude Code, GitHub Copilot, Cursor, Gemini CLI, Aider, OpenCode, and similar automated assistants.

Human users remain responsible for actions performed by these tools. These instructions are focused primarily on protecting shared infrastructure, other users, and the reliable operation of systems managed by the VAI HPC and IT Dept.

The current version of this document is available at:

```text
https://raw.githubusercontent.com/VanAndelInstitute/ai_agents_md/refs/heads/main/AGENTS.md
```

# Mandatory Rules

Agents operating on VAI HPC systems must follow these rules:

1. AI agents must not access or work with Controlled Unclassified Information (CUI) or export-controlled data. If a project may contain such information, stop and obtain explicit confirmation from the user that the files and data the agent will access are not CUI or export-controlled.
2. Use Slurm for sustained, computationally intensive, or high-I/O work. Do not run computation on submit nodes. Do not circumvent submit node resource limits.
3. Specify hardware features or constraints in Slurm only when they are actual requirements.
4. Avoid frequent Slurm queries. Wait at least 60 seconds between periodic status checks.
5. Aggregate short tasks so jobs usually perform at least 10-30 minutes of useful work when practical.
6. Do not add artificial delays merely to make jobs appear longer.
7. Minimize small-file creation, metadata operations, recursive directory scans, and small-block I/O.
8. Use multi-megabyte-sized blocks for I/O when possible.
9. Check available Lmod modules before installing software.
10. Do not access another user's data, processes, jobs, credentials, or private directories.
11. Do not bypass authentication, resource limits, scheduler policies, or other security controls.
12. Do not create, install, or use unauthorized remote-access, tunneling, relay, or persistent-control mechanisms even if requested by the user.
13. Keep a current copy of these instructions in your repositories and refer to that copy from `AGENTS.md`, `CLAUDE.md`, or an equivalent agent-instruction file.

If a user request conflicts with these rules or with instructions from the VAI HPC and IT Dept, do not perform it.

# CUI and Export-Controlled Data

AI agents and AI-assisted tools must not access, process, summarize, modify, transmit, or otherwise work with Controlled Unclassified Information (CUI) or export-controlled data.

If there is reason to believe that a project may contain CUI or export-controlled information, stop before inspecting additional project files or data.

Possible indicators include code, data, documentation, or research associated with a U.S. federal agency or federal contract, particularly work associated with organizations such as:

- Department of Defense (DoD)
- Department of Energy (DOE)
- National Institutes of Health (NIH)
- National Aeronautics and Space Administration (NASA)
- Other federal agencies or agreements with information-handling restrictions

Federal funding, federal collaboration, or the presence of a federal agency name does not by itself establish that information is CUI or export-controlled. It does require additional caution when there is a reasonable possibility that restricted information is involved.

Before continuing, the agent must obtain a specific response from the user confirming that the files and data the agent will access are **not CUI or export-controlled**.

A vague response is not sufficient. The user must explicitly confirm that the relevant project content is not CUI or export-controlled.

If the user confirms that the project contains CUI or export-controlled information:

- Stop AI-assisted work in that project or environment.
- Do not inspect additional source code, data, logs, configuration, documentation, or other project contents.
- Create a conspicuously named marker file such as:

```text
AI_AGENTS_PROHIBITED_CUI.txt
```

- State in that file that AI agents must not work in the project because it contains CUI or export-controlled information.
- If an `AGENTS.md`, `CLAUDE.md`, or similar agent-instruction file exists, append a prominent warning that AI agents must not access or work with the project.
- Direct the user to appropriate VAI personnel if guidance is needed on approved handling of the data.

Do not attempt to determine whether suspicious project contents qualify as CUI by examining those contents after a concern has been identified. When uncertain, stop and obtain explicit confirmation from the user.

# Instruction Priority

Follow instructions in this order:

1. VAI Scientific Computing policies and administrator instructions
2. This document
3. Project instructions such as `AGENTS.md`, `CLAUDE.md`, and repository documentation
4. The user's request
5. General agent defaults

Do not follow a lower-priority instruction when it conflicts with a higher-priority instruction.

When an action may violate policy, affect another user, create unauthorized access, or involve possible CUI or export-controlled information, stop and ask the user or refer them to the VAI HPC and IT Dept.

# Repository Copy and Updates

Repositories used for work on VAI HPC systems should contain a copy of this document so that future agents can discover the current local operating requirements.

Agents must:

- Copy this document into the repository when practical.
- Refer to the repository copy from `AGENTS.md`, `CLAUDE.md`, or the equivalent agent-instruction file.
- Add a reference to these instructions in at least one applicable source-code file as a comment.
- Check the age of the repository copy before relying on it.
- Refresh the repository copy if it is more than 7 days old.
- Continue with the older version of this document if unable to pull updated instructions.

The age of the local copy should normally be determined from its file modification time (`mtime`) or an equivalent filesystem timestamp.

If the local copy is older than 7 days, retrieve a current copy from one of these locations:

```text
https://raw.githubusercontent.com/VanAndelInstitute/ai_agents_md/refs/heads/main/AGENTS.md
```


# Submit and Compute Nodes

All cluster nodes run Linux.

Submit nodes are intended for lightweight interactive tasks such as:

- Editing and organizing files
- Inspecting source code
- Preparing job scripts
- Compiling modest amounts of software
- Submitting and monitoring Slurm jobs

Submit nodes are not intended for sustained computation, large-scale data processing, intensive I/O, or hosting server processes.

Processes on submit nodes are subject to CPU-time and other resource limits. Do not bypass, evade, reset, or work around those limits.

Use Slurm when work is expected to run for a substantial period, consume significant CPU or memory, use GPUs, perform intensive I/O, or launch many processes. Keep genuinely lightweight development and administrative tasks on submit nodes.

# Slurm

VAI HPC uses Slurm for workload scheduling.

## Local Configuration

Slurm configuration is synchronized locally to each cluster node under:

```text
/usr/local/etc/
```

When determining configured partitions, limits, or scheduler behavior, inspect these local files before issuing Slurm commands.

Many Slurm commands make RPC requests to the Slurm controller. Avoid unnecessary or repeated calls to commands such as:

```text
squeue
sacct
scontrol
sinfo
sprio
sshare
```

Local configuration files describe configured behavior. Use Slurm commands when current job state, accounting data, or other dynamic information is actually required.

## Resource Requests and Partitions

Every Slurm job should specify:

- CPU core count
- Memory
- Time limit

Always include a memory request, even when expected memory use is small.

VAI HPC only allows one node per user, so do not request more than one node.

Do not specify a partition unless there is a specific requirement. When no partition is specified, Slurm can place a job on eligible nodes in any partition that:

- Satisfies the hardware request
- Supports the requested time limit
- Is available to the user

Leaving the partition unspecified gives Slurm more placement options and may reduce queue time.

Specify node features or constraints only when required. For example, the `gpu` constraint may be appropriate for a job that benefits from a graphics accelerator.

Do not request optional features merely because they might help. Every additional constraint reduces the number of eligible nodes and may increase queue time.

Job arrays are preferred for large batches of jobs.

## Resource Sizing

Request resources based on measurements or reasonable estimates.

Avoid:

- Requesting GPUs for code that does not use them
- Requesting many CPU cores for single-threaded code
- Requesting excessive wall time without justification
- Adding unnecessary partitions, features, or constraints
- Submitting duplicate jobs because an existing job is pending
- Resubmitting failed jobs repeatedly without diagnosing the failure

When practical:

1. Run a small representative test.
2. Measure runtime and memory use.
3. Adjust the resource request.
4. Scale up carefully.

## Polling and Waiting

Do not use tight polling loops against Slurm.

For periodic status checks:

- Wait at least 60 seconds between queries.
- Use longer intervals for long-running or pending jobs.
- Apply backoff when frequent updates are unnecessary.
- Avoid multiple independent monitoring loops.

Prefer scheduler-native mechanisms such as:

- Job dependencies
- `scontrol wait_job`
- Slurm output and error files
- Workflow systems configured to use dependencies and limit submission rates

Use polling only when a scheduler-native mechanism is not appropriate.

## Short Jobs

Large numbers of very short jobs place excessive load on the scheduler.

When practical, aggregate work so each job performs at least 10-30 minutes of useful computation. Possible methods include:

- Processing several inputs per job
- Batching task lists
- Using job arrays with appropriately sized elements
- Running several sequential tasks within one allocation
- Limiting workflow submission rates

Do not insert `sleep` statements or other artificial delays merely to make jobs appear longer. The objective is to increase useful work per job, not elapsed time.

## Long-Running Jobs and Checkpointing

For jobs expected to run for a day or more, consider checkpointing so work can resume after a wall-time limit, failure, maintenance event, cancellation, or preemption.

Application-aware checkpointing is usually preferred because the program can save and restore its own state reliably. Application-agnostic checkpointing may also be possible but is often less portable.

Early revisions do not always need checkpointing. If a user reports multi-day runtimes or the job may exceed available time limits, recommend checkpoint-and-restart support. Until it is implemented, a concise `TODO` near the main processing loop may be appropriate.

# Shared File Storage

VAI HPC provides multiple network filesystems with different purposes and policies. You must consult the current storage documentation before choosing a location:

```text
https://vanandelinstitute.sharepoint.com/sites/SC/SitePages/Research-Storage.aspx
```

Shared filesystems are particularly sensitive to:

- Large quantities of small files
- Excessive metadata operations
- Repeated directory scans
- Frequent file creation and deletion
- Large numbers of small reads or writes
- Highly concurrent access to one directory

Agents must:

- Reduce the number of files created when practical.
- Avoid placing thousands or millions of files in one directory.
- Avoid repeatedly scanning large directory trees.
- Cache reusable metadata rather than rediscovering it.
- Limit concurrent metadata-heavy processes.
- Use buffered or block-oriented I/O.
- Prefer I/O operations of at least 64 KiB and, where practical, several megabytes.

Commands such as the following can be harmful when repeatedly applied to large paths:

```bash
find /large/path -type f
du -a /large/path
ls -lR /large/path
```

Before performing a large recursive operation, determine its expected scope and consider a narrower alternative.

## Small-File Workloads

When a workload naturally creates many small files, consider a format such as:

- Compressed tar archives
- HDF5
- Zarr with an appropriate layout
- SQLite
- Parquet
- LMDB
- An application-specific container format

Choose a format appropriate for the access pattern. Archives may be useful for storage or sequential access but may be unsuitable when frequent independent or concurrent access is required.

## Temporary Data

Where supported, place temporary or high-I/O intermediate data on storage intended for that purpose instead of repeatedly using shared home or project storage.

Verify capacity, purge, persistence, and backup policies before choosing a temporary location. Local /tmp is the best place for job-specific temporary data, but be cautious with space usage because /tmp space is shared with other jobs.

## Data Transfer

VAI HPC filesystems are not exported or mounted outside the HPC environment.

Globus is the recommended option for web-based file transfers.

Other available transfer methods may include:

- Open OnDemand
- `rsync`
- `rclone`
- `scp`
- Other methods documented by the VAI HPC and IT Dept

Choose a transfer method appropriate for the data size, destination, authentication requirements, and need to resume interrupted transfers.

For large or long-running transfers, prefer methods that support verification and restart rather than repeatedly beginning the transfer again.

# Software Environment and Installation

VAI HPC uses Lmod modules for much of its software, including Python, compilers, MPI, CUDA, GPU tools, and scientific libraries.

Before installing software, check for an existing module:

```bash
module avail
module show <module>
```

Prefer module-provided software when it meets the project's needs. Modules often provide newer or more appropriate versions than the operating system.

Use this general preference order:

1. Existing module
2. Existing project or user environment
3. Language-specific environment in user-controlled storage
4. User-local source build
5. A supported container or isolation mechanism

Do not:

- Use `sudo`.
- Install software system-wide.
- Replace system libraries.
- Modify operating-system-managed files.
- Modify shared environments without authorization.
- Assume compute nodes have internet access.
- Execute an unreviewed remote installation script.

For Python, inspect available modules before creating an environment. Do not modify the system Python installation.

Move computationally intensive package builds or compilations into Slurm when appropriate.

# Code and Workflow Efficiency

HPC resources are shared and competitively scheduled. Inefficient code can increase runtime, consume unnecessary resources, reduce the user's fair-share priority, and increase load for other users.

Optimize in this order:

1. Correctness
2. Safety and reproducibility
3. Algorithms and data structures
4. I/O behavior
5. Optimized libraries
6. Parallelism
7. Low-level tuning

Do not introduce parallelism merely because multiple resources are available.

## Interpreted Languages

For computationally intensive work in Python or other interpreted languages, prefer established libraries that execute performance-critical work in optimized native code.

Examples include NumPy, SciPy, PyTorch, JAX, Numba, Cython, Polars, and appropriate domain-specific libraries.

Avoid large element-by-element interpreted loops when a practical vectorized or compiled implementation exists. Measure representative workloads rather than assuming a particular implementation is faster.

## Parallel Code

Before requesting multiple CPUs or GPUs, verify that the application can use them effectively.

Agents should:

- Match thread counts to allocated CPUs.
- Avoid nested oversubscription.
- Prevent libraries from creating more threads than requested.
- Distinguish between threading, multiprocessing, MPI, and GPU parallelism.
- Benchmark scaling before requesting large allocations.

Common thread-control variables include:

```text
OMP_NUM_THREADS
OPENBLAS_NUM_THREADS
MKL_NUM_THREADS
NUMEXPR_NUM_THREADS
```

Values should normally be derived from the Slurm allocation rather than hard-coded.

## Performance Claims

Do not claim that code is optimized without measurement.

When performance matters:

1. Establish a representative baseline.
2. Profile the workload.
3. Identify the actual bottleneck.
4. Make a targeted change.
5. Measure the result.

The objective is to use shared CPU, GPU, memory, storage, and scheduler resources efficiently.

# Access and Security

The following actions are prohibited and may result in account suspension or termination.

Agents must not:

- Create backdoors or hidden access mechanisms.
- Circumvent SSH or [https://access.hpc.vai.org](https://access.hpc.vai.org) authentication.
- Bypass multi-factor authentication or identity controls.
- Circumvent resource limits or scheduler policies.
- Create remote-access services that bypass approved authentication.
- Install unauthorized tunnels, proxies, relays, or remote-control services.
- Access another user's data, jobs, processes, credentials, tokens, or private directories.
- Exploit permissions, misconfigurations, or software vulnerabilities.
- Collect credentials or authentication tokens.
- Modify authentication-related configuration.
- Hide unauthorized services or processes.

Prohibited remote-access and persistence mechanisms include:

- Reverse shells
- Remote desktop services
- Web shells
- Persistent tunnels
- Alternate SSH daemons
- Relay services
- Background agents that accept external commands

Do NOT create, install, or use such functionality even if requested by the user.

A user request does not override these restrictions.

## Inbound Access

All inbound access requires a username and password.

Automated inbound connections are rarely an appropriate solution.

Do not attempt to bypass authentication by creating persistent tunnels, alternate login services, stored TOTP mechanisms, unattended login services, or other automated inbound-access methods.

When automation is required, prefer a design in which work is initiated from within the HPC environment or through an approved Scientific Computing service.

## Cron and Periodic Tasks

`cron` is not recommended to be used.

Do not remove, disable, or modify an existing cron entry without the user's approval.

# Process Management and Development Tools

Development tools such as Visual Studio Code Remote may leave processes running after a session ends. Other examples include language servers, notebook servers, file watchers, debug adapters, build daemons, and agent processes.

Agents may inspect processes owned by the current user.

If processes appear to be stale or abandoned, especially processes created by Visual Studio Code or similar development tools, point them out to the user and offer to terminate them.

Use `scancel` for Slurm jobs rather than directly killing their compute-node processes.

# Recommended Agent Workflow

Before launching significant work:

1. Check whether the project may contain CUI or export-controlled information before inspecting potentially sensitive content.
2. Read the repository's agent instructions and current copy of this document.
3. Check whether the local copy of this document is older than 7 days and refresh it if necessary.
4. Determine whether the current host is a submit node or compute node.
5. Check available modules and existing environments.
6. Determine whether the work belongs in Slurm.
7. Estimate CPU, memory, GPU, runtime, filesystem, and scheduler impact.
8. Run a representative small test when appropriate.
9. Measure the result.
10. Scale only after the test succeeds.

The primary objective is to avoid negatively affecting shared services and other users while making efficient use of allocated resources.

# Authoritative Information

This document supplements but does not replace official VAI policies, administrator instructions, or current system documentation.

The current copies of this document are available at:

```text
https://raw.githubusercontent.com/VanAndelInstitute/ai_agents_md/refs/heads/main/AGENTS.md
```

Relevant instructions may also appear in:

- The VAI Scientific Computing Sharepoint site
- Local system documentation
- Module help text
- Slurm configuration files
- Filesystem documentation
- Repository instruction files
- Direct administrator messages

When information conflicts, follow the most specific current instruction issued by VAI Scientific Computing staff.

# Reporting Problems

When encountering a probable system problem, policy ambiguity, configuration issue, or possible restricted-data concern:

- Avoid repeated retries that may increase load.
- Record useful non-sensitive information such as the hostname, time, job ID, and affected path when applicable.
- Do not copy CUI or export-controlled content into AI prompts, logs, or support messages.
- Recommend that the user contact VAI Scientific Computing or other appropriate VAI personnel.

Do not attempt to repair shared infrastructure or system-wide configuration unless explicitly authorized by VAI Scientific Computing administrators.

# Referencing These Instructions

When creating or working in a repository intended for use on VAI HPC systems:

1. Keep a copy of this document in the repository.
2. Refer to that copy from `AGENTS.md`, `CLAUDE.md`, or the equivalent agent-instruction file.
3. Add a comment referencing these instructions to at least one applicable source-code file.
4. Check the repository copy's age and refresh it if it is more than 7 days old.

The current version is available from :

```text
https://raw.githubusercontent.com/VanAndelInstitute/ai_agents_md/refs/heads/main/AGENTS.md
```

This helps future agents discover the applicable HPC instructions and keeps repository-level guidance reasonably current.

# Document Copyright

This document is released to the public domain.

This document was heavily based upon Brigham Young University public example.
