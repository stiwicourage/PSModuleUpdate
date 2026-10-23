# Cross-platform testing technology comparison

## TL;DR

No single container/VM product supplies credible Windows, Linux and macOS
qualification from an Apple Silicon Mac. After comparing the alternatives,
recommend native hosted OS jobs for the six-lane baseline, optional Linux
containers for local speed, and selective disposable full-OS/session VMs for
privilege, native vaults and persistent recovery. Vagrant is an orchestration
option only after a concrete provider/guest capability proof, not the baseline.

Research date: 2026-10-23. Public product documentation is cited below. Runner
catalogs, release versions, licensing and prices change; implementation must
record the exact product/image/version and recheck terms. No installations,
provisioning, purchases or CI definitions are delivered here.

## Coverage and architecture comparison

**Container testing** runs isolated processes sharing a kernel. **Full-OS
testing** runs against an actual Windows/Linux/macOS kernel and its user/profile/
filesystem services, natively or in a VM. Both can be reproducible; their
evidence is different. A container on Docker Desktop/Podman on macOS uses a
Linux VM, not the Mac's kernel for its Linux processes.

| Technology | Windows | Linux | macOS | Apple Silicon / x64 versus ARM64 | Suitable scope |
| --- | --- | --- | --- | --- | --- |
| Direct native process | Yes on Windows host | Yes on Linux host | Yes on Mac | Native host architecture; translated process is separately labeled | Fast pure tests and bounded user effects; not automatic isolation |
| Docker / Docker Desktop | Windows containers require Windows host; Linux containers do not qualify Windows | Yes, actual Linux kernel shared by containers | Host application exists; cannot run a macOS kernel container | Native Linux ARM64 on Mac; x64 image emulation slower/different from native x64 | Linux userland/contracts, controlled filesystem/process fixtures |
| Podman / Podman machine | Windows client uses Linux VM; not native Windows test coverage | Yes; rootless available | Client uses Linux VM, not macOS container qualification | macOS machine providers vary by release; native ARM VM/architecture-specific images; emulation must be explicit | Similar Linux use; attractive where Docker Desktop licensing/daemon model is undesirable |
| Vagrant | Via compatible provider/box and actual Windows guest | Via compatible provider/box | Possible only through a provider and lawful supported Apple-host guest setup | Box provider **and** guest architecture must match; Vagrant itself supplies neither hypervisor nor CPU portability | Repeatable full-VM lifecycle where a maintained provider/box is proven |
| Parallels Desktop VM | Windows ARM on supported Apple Silicon configuration; not proof of x64 Windows | ARM Linux guests | Supported macOS guest configurations depend on product/host release | Native ARM path; do not assume x64 guest support or snapshot features identical across guest types | Local Windows ARM/Linux/session tests with commercial licensing |
| VMware Fusion VM | Windows ARM on Apple Silicon; x86 guest support not implied | ARM Linux | Do not presume Apple Silicon macOS guest support; verify product/guest matrix | ARM guest capability and actual Vagrant integration must be checked separately | Cost-effective native ARM full-OS option where supported |
| UTM / QEMU / Apple Virtualization | Windows guest options vary; x64 emulation is not native x64 qualification | ARM virtualization; other CPU emulation possible | Supported Apple virtualization guest path on Apple hardware | Distinguish QEMU emulation from virtualization; automation/snapshot capability depends on backend/guest | Useful controlled VM or emulator when specific capabilities justify maintenance |
| Hyper-V | Full Windows/Linux guests on supported Windows host | Guest supported, not a Linux-host hypervisor | Not an Apple Silicon Mac host option | Hardware/Windows edition and guest support must match | Remote Windows-owned qualification infrastructure |
| Managed remote/cloud VMs or dedicated Macs | Native Windows guest | Native Linux guest | Requires an appropriate Apple-hardware hosting service | Select actual provider instance CPU/OS; control-plane rights separate from guest admin | Snapshot/reboot, special identity/session or architecture unavailable locally |
| GitHub-hosted Actions | Native Windows images | Native Linux images | Native macOS images | ARM/x64 labels and entitlement checked per OS; do not infer all architectures from one runner family | Disposable per-job native matrix |
| Azure Microsoft-hosted Pipelines | Native Windows images | Native Linux images | Native macOS images | Product pool catalog differs from GitHub even when image definitions overlap; macOS ARM preview availability is not a GA guarantee | Disposable per-job native matrix where organization capacity/governance fits |

Official support matrices are a necessary preflight, not a substitute for
actually executing the project tests. Containers do exercise Linux kernel
behavior, but a Mac-hosted Linux VM may not match a supported release kernel,
filesystem, user session or CPU. Bind mounts can additionally expose macOS
filesystem semantics; use a guest-local disposable volume for filesystem claims.

## Isolation, lifecycle and operating cost

| Option | Isolation / reproducibility / version management | Provisioning and cleanup | Speed / local developer experience | Maintenance, licensing and infrastructure cost |
| --- | --- | --- | --- | --- |
| Native process/account | Pin exact pwsh/tooling; process alone shares user repos/vault/config | Cheap process/temp lifecycle; account creation/destruction stronger than HOME override | Fastest Mac iteration; no local other-OS coverage | Minimal tools; accidental developer state mutation is the main risk |
| Docker | Pin image digest, PS asset and dependencies; shared Linux kernel | Disposable container/volume; no host mounts or engine socket; explicit state retention across restart | Fast warm startup; image/download/storage costs; x64 emulation slower | Engine/image maintenance; Docker Desktop paid plan may be required by company size/revenue/use |
| Podman | Pin image and machine configuration; rootless reduces authority, not a full security proof | Disposable containers/volumes; machine lifecycle still owned and patched | Comparable Linux loop; Mac VM networking/mount quirks may differ from Docker | Open-source engine; machine/image maintenance and enterprise support costs still exist |
| Vagrant | Pin Vagrant/provider/plugin/box version and checksum; box freshness/architecture matters | Declarative VM lifecycle; destroy VM and owned disks; snapshot support provider-dependent | Convenient repeatable multi-VM commands after provisioning; cold boots/downloads slow | Extra orchestration/plugins/box ownership; current Vagrant BSL terms and provider/guest licenses require review |
| Direct full VM | Pin OS image, tool assets and provisioning; actual kernel/profile isolation | Snapshot/rebuild and disk retention where provider supports them; explicit teardown controller | Slower/resource-heavy; concrete benefit for persistent state and desktop/system behavior | Patch images, manage drift, storage and licenses; no need for Vagrant if native CLI is adequate |
| Hosted Actions/Pipelines | Fresh job environment; record concrete image build because pinned labels still evolve | Provider handles job VM lifecycle; project owns fixture cleanup and safe reports | No local resources; queue/download overhead; matrix parallelism limited by entitlement | Low VM maintenance; recurring minutes/storage/parallel-job cost; images/tools change |
| Self-hosted/remote worker | Can freeze image and CPU; must prove clean identity/disk each run | Prefer one-job ephemeral rebuild; long-lived agents require stronger quarantine/reimage | Flexible special hardware/session, but queue/network/VPN dependency | Highest operational burden; compute/disk/control-plane/macOS hardware cost plus patching/security |

A full VM improves isolation but is not automatically reproducible: shared
folders, reused accounts, interactive changes and auto-updated software can
contaminate it. A Docker image is not an OS image qualification shortcut.

## Privilege, persistence and credential security

| Option | Privileged operations | Persistent state / recovery | Credential and CI boundary |
| --- | --- | --- | --- |
| Native developer host | Avoid real system roots, vault mutation and forced interruption | Easy persistence but dangerous to real installations | No routine credential/provider-mutating tests under developer identity |
| Linux container | Container root is not host admin unless dangerous mounts/capabilities are granted | Volume can survive child/container death; cannot prove Windows locks/macOS vaults or machine reboot | No host secrets/socket; rootless where possible; private D-Bus/service can test limited integration |
| Full OS VM | Real admin/root and second-user tests within disposable guest | Test disk + snapshots/controller enable restart/resume; hard reset is not guaranteed power-loss simulation | Dedicated guest identity/vault; remove/reimage secrets; desktop prompts may need explicit session |
| Hosted native job | Usually elevated capabilities available, but exact user token/sudo must be checked | Child-process persistence within a job; next job normally fresh; no assumed snapshot/hypervisor API | Protected secrets for trusted jobs only; fork PRs secret-free; ephemeral profile still needs backend/session probe |
| Dedicated remote/session worker | Can provide desktop/native stores or privileged tests unavailable in generic hosted jobs | Control-plane snapshot/reboot only if separately authorized | Least-privilege service identity, network allowlist, one-job rebuild; never untrusted PR code on credentialed persistent workers |

PMU's actual AllUsers provider install, Windows file locking, Windows known
folders/ACLs, macOS Keychain and Gerber's native-store user/session semantics
require native OS evidence. Pure policy/version/identity logic, synthetic
credential contracts, controlled Unix process/file fixtures, and Linux headless
failure cases can safely run in properly isolated containers.

Linux Secret Service success can be automated in a container with a private
D-Bus/session/service setup, but that qualifies that configured service context,
not every desktop session. Restarting a container or killing a process is not
rebooting the machine or interrupting storage power.

## Vagrant on an Apple Silicon Mac

Vagrant is a coordinator over providers. A usable configuration needs a
compatible **host hypervisor + Vagrant provider/plugin + guest architecture +
box image + guest OS license + PowerShell/tool assets**. A box being named
Windows, Ubuntu or x64 in a catalog does not prove it boots on this Mac.

| Provider direction | Feasibility and concrete benefit | Limit / proof required before adoption |
| --- | --- | --- |
| Parallels Vagrant provider | Maintained vendor plugin; repeatable ARM Linux/Windows guest lifecycle is a plausible local option | Plugin requires Desktop Pro/Business/Enterprise, not Standard; prove Apple Silicon guest/box support, Windows ARM communicator, provisioning and snapshot/restore on actual selected versions |
| VMware Vagrant provider | Possible orchestration over Fusion for supported ARM guests | Verify current plugin/utility/Fusion/box ARM support together; free Fusion licensing is not proof of provider functionality |
| VirtualBox Vagrant provider | Familiar default provider; Oracle's current downloads include a macOS Apple Silicon host package, contrary to older x86-only introductory manual text | ARM host package availability is confirmed; Vagrant/provider integration, guest types and feature limits remain unverified. Do not infer arbitrary x64 boxes or Windows ARM guest support |
| UTM/community integration | UTM itself is useful for ARM virtualization or explicit CPU emulation | No verified supported Vagrant integration selected here; plugin ownership/maintenance and snapshot backend remain unverified |
| Hyper-V | Useful on remote Windows hosts | Cannot be the local macOS host provider |
| Docker provider | Could orchestrate Linux containers | Still container evidence, not Windows/macOS/full-OS testing; little value over a simple container command/CI job for the MVP |

The minimum feasible local path is native macOS plus ARM Linux
container/VM, and hosted/remote Windows x64. Local Windows ARM is an optional
separate architecture target with a proven hypervisor/guest configuration.
Do not assume arbitrary Windows/x64 images run under Vagrant on ARM.

Adopt Vagrant only if Phase 4 demonstrates repeatable multi-VM lifecycle or
snapshot workflow that is materially simpler than the provider CLI. Otherwise
its provider/box/plugin surface is unnecessary maintenance. Conversely, a
VM-dependent native-vault or recovery scenario is a legitimate reason to use a
VM even though containers run the unit suite.

## GitHub Actions versus Azure Pipelines

| Criterion | GitHub Actions | Azure Pipelines |
| --- | --- | --- |
| Existing conventions | GitHub PR template/agent workflow guidance fits naturally; no active PMU/Gerber workflow found | Azure feed/ADO usage exists but is not evidence of an existing pipeline or infrastructure owner |
| Native OS matrix | Hosted Windows/Linux/macOS; choose explicit OS and architecture labels | Hosted Windows/Linux/macOS; independent pool/architecture catalog, not parity inferred from runner-images |
| PowerShell management | Provision exact pwsh; preinstalled `pwsh` can drift | Same; task shell selection alone does not prove 7.4 |
| Reuse | Versioned reusable workflow/composite action with project-owned callers | Versioned templates/tasks with project-owned callers |
| Results | Upload raw NUnit XML plus reviewed summary/check integration | First-party Publish Test Results task supports NUnit |
| Retention | Artifact retention/storage limits vary by plan/repository | Pipeline artifact/test retention limits vary by project/organization |
| Secrets | Repository/org/environment policy, least-privilege token, approvals; secret-free untrusted PR path | Scoped secret variables/Key Vault/service connections, protected resources/checks and limited job token scope |
| Privileged tests | Disposable hosted capabilities may suffice; session/reboot needs special worker | Similar; custom pool/VM for session/reboot where needed |
| Cost/time | Plan/visibility/runner/minutes/storage/concurrency dependent; Mac commonly more expensive | Hosted parallel-job capacity, minutes/storage and organization grants dependent; self-hosted costs separate |
| Principal gap for this MVP | Verify macOS ARM64 entitlement, exact labels and budget | Verify actual macOS ARM64 capacity; paused/limited preview is not a production capability commitment |

No fixed dollar quote or free-tier promise is made: public/private repository
visibility, current plans, larger/ARM runners and retention can change billing.
Phase 1 should measure job duration, queue time and cache effectiveness, then
project monthly costs from actual PR/schedule volume and concurrency.

## Recommendation after comparison

Use GitHub Actions provisionally for the six native lanes, unless confirmed
organizational capacity/governance favors Azure. This is a preference requiring
approval, not a finding that the repository already uses GitHub hosting.
Keep Azure as an alternative implementation of the same contract.

Offer Podman or Docker for an optional Linux developer lane after IT/license
review; do not require both. Prefer a guest-local volume and native ARM image
for speed. Use remote native x64 for x64 qualification. Keep native macOS fast
tests secret-free and move provider/vault mutations into disposable identities.

Reject all-container testing as insufficient native coverage, not because
containers are unsuitable for unit tests. Defer all-Vagrant orchestration
because three-OS native coverage is easier through hosted jobs and current ARM
provider/box compatibility needs proof. Defer always-on self-hosted farms due to
security/maintenance/cost. Introduce direct VMs or Vagrant later only for named
privilege, session, architecture or persistent-recovery needs.

## Sources and verification limits

These are authoritative public references used in the investigation.
Read them again when implementing dynamic choices; they do not qualify a
project environment by themselves.

| Reference | Supports / caveat |
| --- | --- |
| [PowerShell support lifecycle](https://learn.microsoft.com/en-us/powershell/scripting/install/powershell-support-lifecycle) | Supported lines, OS/runtime lifecycle and 7.4 support ending 2026-11-10; narrative patch numbers may lag |
| [Official PowerShell releases](https://github.com/PowerShell/PowerShell/releases) | Resolve concrete non-preview versions and architecture-specific assets; newest stable includes an LTS release if newer than the separately named Stable channel |
| [Vagrant providers](https://developer.hashicorp.com/vagrant/docs/providers) and [boxes](https://developer.hashicorp.com/vagrant/docs/boxes) | Provider-specific boxes and lifecycle; no automatic CPU/guest portability |
| [Vagrant license](https://github.com/hashicorp/vagrant/blob/main/LICENSE) | Review current BSL terms, provider licenses and use case; not a blanket open-source/free-commercial assertion |
| [Parallels Vagrant provider](https://github.com/Parallels/vagrant-parallels) | Plugin edition/CLI requirements; actual ARM box/guest proof remains required |
| [Oracle VirtualBox downloads](https://www.virtualbox.org/wiki/Downloads) | Current host packages; check current ARM host/guest limitations, not an old introductory x86-only description |
| [VMware Fusion licensing announcement](https://blogs.vmware.com/cloud-foundation/2024/11/11/vmware-fusion-and-workstation-are-now-free-for-all-users/) | Free for commercial/educational/personal use announced 2024-11-11; verify current terms/support and guest matrix separately |
| [UTM documentation](https://docs.getutm.app/) | Virtualization/emulation and backend-specific capabilities; no Vagrant plugin selected or proven |
| [Apple software license agreements](https://www.apple.com/legal/sla/) | Select actual macOS agreement; Apple-hardware/virtualization restrictions require license review; no asserted universal guest-copy entitlement |
| [Docker Desktop Mac installation](https://docs.docker.com/desktop/setup/install/mac-install/) and [VM manager](https://docs.docker.com/desktop/features/vmm/) | Mac host/VM architecture and host requirements; VM backend/version can vary |
| [Docker Desktop license](https://docs.docker.com/subscription/desktop-license/) | Organization/use-dependent subscription requirements; review before standardizing |
| [Podman machine](https://docs.podman.io/en/latest/markdown/podman-machine.1.html) | VM required on macOS/Windows; provider defaults and support vary by installed release |
| [Windows container compatibility](https://learn.microsoft.com/en-us/virtualization/windowscontainers/deploy-containers/version-compatibility) | Windows host/kernel compatibility and Hyper-V isolation; not a Mac Windows-container solution |
| [GitHub hosted runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners) | Per-OS/architecture runner catalog, job isolation and capabilities; verify exact label/entitlement |
| [Azure hosted agents](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/hosted) | Per-product image/pool capabilities, disposable VM model; macOS ARM64 limited-preview availability requires recheck |
| [GitHub Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions) | Visibility/plan/minutes/storage-dependent costs |
| [Azure parallel jobs](https://learn.microsoft.com/en-us/azure/devops/pipelines/licensing/concurrent-jobs) | Hosted capacity/grants/concurrency; not inferred from GitHub pricing |
| [GitHub Actions secrets](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets) and [secure use](https://docs.github.com/en/actions/reference/security/secure-use) | Secret scope, masking and least privilege; protected workflow design still required |
| [Azure GitHub fork builds](https://learn.microsoft.com/en-us/azure/devops/pipelines/repos/github#validate-contributions-from-forks) and [job tokens](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/access-tokens) | Untrusted contribution and job authorization boundaries; verify organization policy before enablement |
| [Azure Publish Test Results](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/publish-test-results-v2) | First-party NUnit result publication |
| [Register-PSResourceRepository](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.psresourceget/register-psresourcerepository) | Persistent provider registration; precise macOS store behavior is additionally established by PMU execution evidence |
| [Export-Clixml](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/export-clixml) | Credentials encrypted only on Windows; non-Windows Unicode-array representation is obfuscation, not encryption; no `-Key` parameter |

Version-resolution and provider/architecture probes remain implementation
acceptance checks, not executed results from this research. No claims about
exact current prices, general Windows ARM box support, UTM Vagrant support or
automatic macOS VM snapshot capabilities are made without that proof.
