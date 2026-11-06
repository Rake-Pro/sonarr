# sonarr

Sonarr on the shared [alpine-base](https://github.com/Rake-Pro/alpine-base) image, built in-house from the upstream release.

```
ghcr.io/rake-pro/sonarr
```

## Tags / releases

| Tag | Meaning |
| --- | --- |
| `X.Y.Z` | Immutable release, built from git tag `vX.Y.Z` |
| `X.Y` | Latest patch of that minor |
| `latest` | Latest release |
| `<upstream-version>` | The exact upstream Sonarr version baked into that release (currently `4.0.20.3014`) |
| `sha-<short>` | Commit the image was built from |

- `dev` is the integration branch (default); `ci.yml` builds, smoke-tests and Trivy-scans on every push and PR.
- `version-check.yml` polls upstream daily and opens a PR into `dev` bumping the pinned `VERSION` build arg.
- `sync-main.yml` opens a promotion PR from `dev` to `main`. Merging it (merge commit) mints the next patch tag and `release.yml` builds, scans and pushes the image. A fixable CRITICAL finding blocks the push.
- Label the promotion PR `release:minor` or `release:major` to change the bump.
- `trivy-rescan.yml` re-scans the released image weekly (CRITICAL+HIGH) so CVEs disclosed after release still surface.
- Dependabot bumps the base image digest and the GitHub Actions weekly.
- Pin `X.Y.Z` in deployments; `latest` is a convenience pointer.

## Image facts

| Item | Value |
| --- | --- |
| Base | `ghcr.io/rake-pro/alpine-base` (Alpine, patched weekly) |
| Init | `catatonit` as PID 1 |
| User | `65534:65534` from the first process (no s6, no privilege drop, no added capabilities) |
| Data | `/config` (Sonarr data dir: config.xml, sonarr.db, logs, Backups) |
| Port | `8989` |
| Upstream | <https://github.com/Sonarr/Sonarr> |
| Upstream version | `4.0.20.3014` (build arg `VERSION`) |
| Platform | linux/amd64 |

## Run

```
docker run -d --name sonarr \
  -p 8989:8989 \
  -v /path/to/config:/config \
  ghcr.io/rake-pro/sonarr:latest
```

- The `/config` mount must be writable by uid 65534 (`chown -R 65534:65534 /path/to/config`).

## Notes

- Self-contained upstream build: the .NET runtime inside the tarball is upstream's choice (v4 stays on .NET 6). Runtime CVEs are not fixable here; they retire with the Sonarr v5 line.
- `UpdateMethod=docker` in `/app/package_info` disables in-app updates; bump the image instead.
