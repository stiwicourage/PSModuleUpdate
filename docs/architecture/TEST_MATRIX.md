# Proposed cross-platform test matrix

## TL;DR

Start with **six native OS/runtime lanes per project**: Windows x64, Linux x64,
macOS ARM64, each on PowerShell 7.4 and latest stable. Run secret-free behavioral
contracts and safe build/integration checks on every PR. Native provider,
privileged, real-vault, live-feed, persistent-recovery and extra-architecture
rows extend qualification; they are not existing passes or implicit PR gates.

See [strategy](CROSS_PLATFORM_TESTING.md),
[comparison](TEST_TECHNOLOGY_COMPARISON.md), and
[roadmap/approvals](TEST_IMPLEMENTATION_ROADMAP.md).

## Reading the matrix

- **7.4:** concrete latest 7.4 patch selected/pinned for that run.
- **Latest:** newest official non-preview stable release, including LTS when
  newest; exact version recorded. It never replaces the 7.4 row.
- **Both:** execute independently on 7.4 and Latest, not just one runtime.
- **User:** genuinely unprivileged test identity. **Admin/root:** disposable
  worker only, never a real developer installation.
- Local availability describes a proposed feasible environment, not installed
  tools. CI availability is conditional on provider/account/image capabilities.
- Time estimates are planning bands **per job**, excluding cold provisioning
  and downloads: S under 5 minutes; M 5-15; L 15-45; XL over 45 or interactive.
  They are not measured SLAs. Profile before setting production timeouts.
- Unexpected skips in a claimed qualification category fail completeness.
  Explicit unavailable infrastructure is blocked/not tested, not success.

## Minimum viable native matrix

Every row includes PMU and Gerber as independent jobs or project invocations
with independent artifacts. Six lanes per project means twelve project/runtimes,
not one combined test total. Projects keep their own dependency/coverage settings.

| Category | OS / architecture | PowerShell | Privilege | Environment | Local on Apple Silicon | CI availability | Frequency | Time |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Unit/contracts + build/import + safe integration + controlled process smoke | Windows x64 | 7.4 | User; admin provisioning separate | Fresh hosted Windows OS worker | Remote x64 worker; local ARM VM not equivalent | GitHub/Azure hosted x64 after isolation setup | Every PR | M |
| Same baseline | Windows x64 | Latest | User | Fresh hosted Windows OS worker | Remote x64 worker | GitHub/Azure hosted x64 | Every PR | M |
| Same baseline | Linux x64 | 7.4 | User | Fresh hosted Linux OS worker | Remote/native x64; emulated container diagnostic only | GitHub/Azure hosted x64 | Every PR | M |
| Same baseline | Linux x64 | Latest | User | Fresh hosted Linux OS worker | Remote/native x64; local ARM container supplementary | GitHub/Azure hosted x64 | Every PR | M |
| Same baseline | macOS ARM64 | 7.4 | User | Disposable macOS OS worker/account | Native secret-free safe selection; disposable account for mutations | GitHub ARM64 subject to runner entitlement; Azure ARM availability not assumed | Every PR | M |
| Same baseline | macOS ARM64 | Latest | User | Disposable macOS OS worker/account | Same local boundary | Same capability/entitlement check | Every PR | M |

If the selected CI cannot provide macOS ARM64, approve a remote Mac worker or
an explicitly different architecture baseline; do not silently substitute x64.
The MVP cannot be called complete while a required native lane is unavailable.

Baseline includes real OS path/encoding/module loading and controlled
filesystem/process tests that meet isolation requirements. It does not
automatically run opt-in native credential/live repository tests or all
currently macOS-only provider integration.

**Gerber limitation:** the six lanes initially establish Nova component
evidence, not a passing full Windows `run.ps1`. Its Unix PTY wrapper is not
Windows-compatible. Phase 3 must add and qualify Windows terminal automation
before claiming a full Windows project quality loop. Preserve its existing 90%
coverage contract and mark any unexecuted gate explicitly.

## Extended PSModuleUpdate qualification

| Category | OS / architecture | PowerShell | Privilege | Environment | Local availability | CI availability | Frequency | Time |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Actual CurrentUser provider install, discovery, PSModulePath precedence | Windows/Linux x64, macOS ARM64 | Both | User | Disposable native OS/profile with actual destination verified | Native disposable Mac account; Linux container/VM supplementary; Windows remote/VM | Hosted native jobs after safety port | Nightly; release | M |
| Local feed stable, previews, same-base replacement, four-component version, GUID/SHA256/metadata | All three native OS baselines | Both | User | Real PSResourceGet 1.2.0, disposable feed/modules/store | Same as above | Hosted native, local feed no secrets | Nightly; release | M |
| Rollback, journal validation, next-process recovery, two updater races, timeout/kill | All three native OS baselines | Both | User | Native local disk; controlled provider + real processes | Mac owned roots; Linux container supplement; remote Windows | Controlled smoke PR; broad native nightly | PR smoke; nightly; release | M-L |
| Real-provider interruption at synchronized mutation phases | All three native OS baselines | Both | User | Disposable full OS and persistent test disk across child processes | Disposable VM/account only | Protected disposable workers; ordinary job possible if no reboot needed | Manual; release | L |
| Registered and temporary repositories, RepositoryUri, cleanup/API-binding crash window | All three native OS baselines | Both | User | Disposable actual native registry/profile; controlled feed | Not real developer registry; VM/container profile where safe | Hosted/isolated job serialized per store | Nightly; release | M-L |
| AllUsers stable + same-base replacement, cross-scope preservation | All three native OS baselines | Both | Admin/root mutation; normal-user verification | Disposable full OS, genuine system roots | No host execution; Linux/Windows VM or remote; disposable Mac worker | Protected hosted job if capability verified, else VM | Manual; release | L |
| Denied permissions, ACLs, ownership, symlink/reparse protection | All three native OS baselines | Both | User + admin setup/second identity | Native NTFS/APFS/Linux local filesystem | Disposable VM/account; no root developer shell | Protected native worker | Nightly selected; release | M-L |
| Loaded binary locks, exclusive handle, active/installed/restart semantics | Windows x64 primary; macOS ARM64/Linux x64 contrasts | Both | User | Native OS; fresh process; platform-built binary fixture | Windows remote/VM; native safe Mac fixtures | Hosted native jobs | Nightly; release | M |
| PSGallery stable + public prerelease where suitable | All three native OS baselines | Both | User | Disposable provider worker, network opt-in | Explicit disposable live job | Scheduled/protected network job | Weekly; release | M-L |
| NuGet.org acquisition/nonmodule rejection; valid module only if fixture exists | All three native OS baselines | Both | User | Disposable provider worker; exact package/source | Explicit network opt-in | Scheduled network job | Weekly; release | M |
| Azure authenticated stable + private HTTPS-v3 temporary URI | All three native OS baselines | Both | User | Protected disposable worker; scoped test identity | Remote/protected or explicitly authorized disposable account | Protected secrets/environment approval | Weekly if approved; release | L |
| Azure preview-to-preview-to-stable; dependencies | All three native OS baselines | Both | User | Same plus authorized immutable package sequence | Blocked without suitable fixture | Blocked until endpoint/fixture authorization | Manual; release if required | L |
| Nexus authenticated compatible NuGet-v3 | All three native OS baselines | Both | User | Approved endpoint, fixture, TLS and scoped identity | Blocked without endpoint | Protected job when infrastructure exists | Manual; release if support claimed | L |
| VM restart, preserved journal/disk, recovery controller | OSes in approved restart support claim | 7.4 first, then Latest | VM control-plane + guest authority | Snapshot/rebuild-capable isolated VM | Linux/Windows VM; macOS VM capability/licensing check | Dedicated cloud/VM adapter, not ordinary disposable job alone | Manual; major release | XL |
| Provider upgrade, extra OS image/filesystem | Three OS baselines; explicit new image | Both | Scenario-specific | Separate baseline/candidate provider jobs | Depends on environment | Scheduled matrix extension | Weekly; before support expansion | M-L |

Rollback after controlled exceptions and process death is distinct from storage
failure/power loss. VM reset tests do not justify guaranteed power-loss durability.
Network filesystems require a separate decision and are not implied supported.

## Extended Gerber Core qualification

| Category | OS / architecture | PowerShell | Privilege | Environment | Local availability | CI availability | Frequency | Time |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Config/env, real path semantics, UTF-8, user permissions, module/assembly isolation | All three native baselines | Both | User; second identity/admin setup only for ACL tests | Native fresh profile/process | Safe owned roots on Mac; remote other OSes | Hosted native | PR safe subset; nightly expanded | S-M |
| Synthetic secret abstraction, redaction and noninteractive missing auth | All three native baselines | Both | User | Controlled store/HTTP double, no real secret backend | Native Mac; Linux container supplement | Hosted native | Every PR | S |
| Linux native store unavailable; no plaintext fallback/environment restored | Linux x64 + optional ARM64 | Both | User | Headless container with no Secret Service | Native ARM64 Linux container | Hosted Linux/container | PR controlled case; nightly native | S-M |
| Linux native Secret Service CRUD/session lifecycle | Linux x64; ARM64 extended | Both | User; service provisioning separate | Private D-Bus + libsecret + owned Secret Service, or session VM | Linux container with explicit service or full VM | Special session/service job | Weekly; release | L |
| macOS native Keychain CRUD/backend/user boundary/locked access | macOS ARM64; x64 extended | Both | Dedicated user; no elevation expected for own entries | Disposable verified keychain/profile session | Separate account/VM, never developer login keychain | Special protected Mac session; prompts may need manual qualification | Weekly if automated; release | L-XL |
| Windows actual native backend CRUD/user boundary | Windows x64; ARM64 extended | Both | Dedicated user; setup may need admin | Verified native store/profile, service vs interactive tested separately | Hosted/remote x64; ARM VM separate claim | Special protected Windows job after backend probe | Weekly; release | L |
| Unix PTY masking/cancel/EOF, navigation, terminal encoding | Linux x64 + macOS ARM64 | Both | User | Existing pexpect harness, synthetic vault, pinned Python dependencies | Native Mac/Linux VM/container with PTY | Hosted Unix after prerequisites | PR targeted; nightly full; release | M-L |
| Windows interactive terminal / secure input | Windows x64 | Both | User | Proposed ConPTY adapter or controlled Windows session | Remote/VM after harness implemented | Blocked by current harness; future approved job | Nightly; release once implemented | L |
| Real curl process, quoting, stdin config, nonzero exits, REST fallback | All three native baselines | Both | User | Owned fake executable/local controlled HTTP; no live ADO | Mac native; remote other OS | Hosted native | PR controlled; nightly native | S-M |
| Live ADO PAT integration | Approved OS/runtime support rows | Both when claiming parity | Scoped test identity, not admin by default | Protected tenant/project, network; no developer credentials | Protected remote preferred | Manual/protected secrets job | Release/on auth change | L |
| Plugin external OAuth/provider interaction | Plugin-selected OSes/runtimes | Explicit | Scoped external identity | Plugin-owned service/VPN/browser/device flow if actually required | Special infrastructure/manual | Not a Core baseline gate; separately approved | Plugin release/auth change | L-XL |

## Architecture and future compatibility extensions

| Category | OS / architecture | PowerShell | Privilege | Environment | Local availability | CI availability | Frequency | Time |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Additional native CPU | Linux ARM64 | Both | Scenario-specific | Native ARM worker | Apple Silicon Linux container/VM; host-kernel limits still apply | GitHub/account native ARM or controlled remote; Azure not assumed | Weekly; release if supported | M-L |
| Intel Mac compatibility | macOS x64 | Both | User first | Native Intel Mac runner | Remote Intel Mac | Hosted label/entitlement verified separately | Weekly; release if supported | M |
| Windows ARM compatibility | Windows ARM64 | Both if official assets/dependencies supported | User first | Native Windows ARM VM/runner | ARM guest on supported Mac hypervisor/provider | Account/catalog probe required | Scheduled; before support claim | M-L |
| Intermediate supported stable line | Approved native baselines | Explicit pinned line | User | Same native workers | Same runtime availability checks | Optional scheduled matrix | Weekly | M |
| Preview diagnostic | Representative native baselines | Exact preview | User; no secrets | Isolated compatibility job | Optional | Advisory, not stable release proof | Weekly | M |

## Reporting and promotion criteria

Each category has explicit required, optional and unavailable scenarios. Promote
a row to qualified only with actual execution, artifact hash, concrete OS/
architecture/runtime/provider versions, expected observable assertions,
privilege identity, result/skips, cleanup verification and sanitized artifacts.

A six-lane baseline is minimum infrastructure acceptance, not completion of the
extended qualification matrix. Release support claims select required extended
rows up front. Missing Azure preview packages, Nexus, native vault sessions or
Windows terminal automation remain visible blockers for those claims; they do
not retroactively invalidate accepted G-4A3 macOS evidence.
