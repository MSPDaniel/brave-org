# brave-org

Self-hosted **Brave Origin** browser on LinuxServer's Selkies desktop stack, based on the same distro family as the working Meru container. It opens Brave Origin automatically, with persistent settings, extensions and password database files.

## Key settings

- GitHub repository: `MSPDaniel/brave-org`
- Published image: `ghcr.io/mspdaniel/brave-org:latest`
- Unraid container name: `brave-org`
- Unraid persistent data: `/mnt/user/appdata/brave-org` mounted at `/config`
- Brave user profile: `/mnt/user/appdata/brave-org/brave-org-profile`
- HTTPS access: `https://UNRAID-IP:3012` (or configure an HTTPS reverse proxy)
- Browser tab / Selkies header: **XOM** by default (`TITLE` runtime environment variable)
- Tab favicon / PWA app icon: **black Brave lion on white** (Simple Icons Brave glyph; converted to PNG at build time)
- Unraid template icon: monochrome Brave icon from IconArchive's Simple Icons collection
- Default desktop: X11 mode, matching the Meru configuration (`PIXELFLUX_WAYLAND=false`)
- Built-in web authentication via `CUSTOM_USER` and `PASSWORD` at the LinuxServer Nginx gateway

**Tab name distinction:** `TITLE` sets the title of the local Edge tab *hosting the Selkies remote session*. The Brave windows and tabs *inside* the streamed desktop retain their normal titles.

## Daily checks without unnecessary builds

GitHub Actions runs daily at **09:24 UTC**, checking:

1. The digest of `ghcr.io/linuxserver/baseimage-selkies:debiantrixie` (which bundles Selkies, Pixelflux, and the desktop stack).
2. The version of the official `brave-origin` stable package in Brave's signed APT repository.
3. The versions recorded in OCI labels of your published `ghcr.io/mspdaniel/brave-org:latest` image.

**If neither changes, the daily run stops without building/publishing an image.** If either changes, it builds from the exact detected base digest and Brave package version and publishes:

- `ghcr.io/mspdaniel/brave-org:latest` (moving)
- `ghcr.io/mspdaniel/brave-org:build-<github-run-id>-<attempt>` (retained immutable-in-practice tag)
- `ghcr.io/mspdaniel/brave-org:sha-<git-sha>` (code revision; can be moved if rebuilt at same commit)

`push` and manual `workflow_dispatch` intentionally force a build even if upstream is unchanged, to incorporate changed project files or allow recovery. An unsuccessful build does **not** publish new tags. Older build tags remain in GHCR unless deleted manually or by a retention/cleanup policy. The project does not implement automatic rollback.

**What counts as a Selkies change:** We compare the whole moving LinuxServer base-image digest, not only its Selkies package version. This catches updates to Selkies, Pixelflux and other base components. An upstream Selkies release not yet bundled in `debiantrixie` will not be incorporated until LinuxServer updates that base image.

**First build:** Create a *new* GitHub repository `brave-org`, upload these files including the hidden `.github` folder, and push to `main`. In GitHub Actions, run `Check Upstream and Publish brave-org`. Make the GHCR package public if you want anonymous pulls from Unraid.

## Built-in HTTP Basic authentication

This uses LinuxServer's Nginx HTTP Basic authentication (`CUSTOM_USER` and `PASSWORD`), not the Selkies backend's `SELKIES_ENABLE_BASIC_AUTH`. A username alone does not enable login: you must set a password.

- **Unraid template:** Set **Basic auth username** and **Basic auth password** when adding the container. The password field is masked. Never put credentials in the XML or commit real passwords to GitHub.
- **Docker Compose:** Copy `.env.example` to `.env` and replace the placeholder with a strong unique password. `.env` is gitignored; Compose rejects an unset password.
- **Verification:** In a private window visit `https://UNRAID-IP:3012`. It should prompt for HTTP Basic credentials and reject wrong ones. Do not expose publicly if login is missing.

Keep HTTPS and your existing Nginx Proxy Manager + Authelia gateway for external access. The LinuxServer team warns that built-in HTTP basic auth alone is inadequate as an internet-facing security gateway. Your `/config` directory stores sensitive profile data and should be backed up securely.

## Docker Compose

```bash
cp .env.example .env
# Edit .env and set a strong password.
docker compose up -d
```

The container listens on HTTPS port 3001 internally and publishes it on host port 3012. Do **not** use HTTP with port 3012. Use the included Unraid template in `unraid/brave-org.xml`, or copy its settings into Unraid's Add Container UI.

The `/config` volume preserves profile, bookmarks, extensions, cookies, browser settings and the saved-password database. Password **decryption** after recreation depends on Chromium's Linux keyring setup. Test a dummy saved password across a recreation and back up your appdata securely. Don't use `--password-store=basic` merely to improve portability; it may weaken password protection.

The image currently includes `seccomp=unconfined` to match your working Meru session, and 1 GiB of shared memory. This weakens container isolation: keep access authenticated and restrict external access. To preserve the working Meru keyboard path, start with X11 and verify Russian before replacing an existing container.

## Rollback

In Unraid change repository from `ghcr.io/mspdaniel/brave-org:latest` to a real historical `build-<run-id>-<attempt>` tag shown under GitHub Packages. This restores the earlier container **image**, but does not undo browser-profile migrations performed by a newer Brave version; back up the profile before upgrades.

## Icon attribution

The app icon uses the Brave glyph from Simple Icons (CC0) rendered in black on white. The Docker build downloads it from jsDelivr's Simple Icons v15 package and renders a 256px PNG. The Unraid template references the Simple Icons collection on IconArchive.

## Sources

- https://docs.linuxserver.io/selkies/developer-guide/building-images/
- https://docs.linuxserver.io/selkies/user-guide/configuration/
- https://brave.com/origin/linux/
- https://simpleicons.org/?q=brave

## Changing the external browser tab title

Change the **Tab title** environment variable (`TITLE`) in Unraid's brave-org container template, then Apply to recreate the container. There is deliberately **no** baked-in `SELKIES_UI_TITLE`: that variable can override `TITLE` in the browser tab. If migrating an existing Unraid template, **remove** its legacy `SELKIES_UI_TITLE=XOM` variable entirely.

Verify using `docker inspect brave-org --format '{{range .Config.Env}}{{println .}}{{end}}' | grep -E '^(TITLE|SELKIES_UI_TITLE)='` and open the external web session in an InPrivate window if the title remains cached. This does not change titles of pages inside the remote Brave browser.
