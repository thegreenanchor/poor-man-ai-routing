---
name: wsl-kali-ops
description: Operating Kali Linux inside WSL2 on Windows. Use for any task involving Kali tools, security toolchains running on WSL, dotfile setup, networking between Windows host and WSL, or running pentest/OSINT tools from a Kali WSL distro. Trigger when WSL, Kali, or Linux-on-Windows is referenced.
---

# WSL + Kali Ops

## Scope

Kali Linux installed via WSL2 on Windows 11. A common stack for cybersec/OSINT work.

## Setup checks

Before any task, verify environment:

```bash
# Inside Kali WSL
uname -a              # confirm Linux kernel via WSL
cat /etc/os-release   # confirm Kali
wsl.exe -l -v         # from PowerShell: list distros + version
```

If kali isn't installed:

```powershell
# In PowerShell admin
wsl --install -d kali-linux
wsl -d kali-linux
sudo apt update && sudo apt full-upgrade -y
```

## Networking quick reference

- WSL2 distro IP changes per boot. Get with `ip addr show eth0` or `hostname -I`.
- Windows host accessible from WSL at `$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')` on most systems, or via `host.docker.internal`.
- WSL accessible from Windows at `localhost:<port>` for forwarded ports (WSL2 mirrored networking on Win11+).
- For external (LAN) access to WSL services: use `netsh portproxy` on Windows to bridge.

```powershell
# Forward Windows host port 8080 to WSL2 :8080
netsh interface portproxy add v4tov4 listenport=8080 listenaddress=0.0.0.0 connectport=8080 connectaddress=$(wsl hostname -I).Trim()
```

## Filesystem rules

- Inside WSL, `/mnt/c/` mounts Windows C:. Slow for I/O. Avoid using it as the working dir for Kali tools.
- Best practice: keep tool data inside the Linux filesystem (`~/`, `/opt/`).
- Crossing the boundary is fine for delivering output to Windows: copy to `/mnt/c/Users/<you>/Documents/workspace/`.

## Common Kali tool workflows

### Network recon (nmap)

```
cdx "GOAL: Run nmap against target <target>.
SCOPE: <-sS|-sV|-A|-p->...
OUTPUT: ./.scratch/nmap-<target>-$(date +%Y-%m-%d).xml + parsed CSV
TOOL: nmap with -oX
LEGAL: only against targets the user owns or is authorized to test.
RETURN: STATUS + SUMMARY (open ports, services) + EVIDENCE + ARTIFACTS."
```

### Web app scanning

For authorized engagements only:
- `nikto -h <url> -o ./.scratch/nikto.txt`
- `gobuster dir -u <url> -w /usr/share/wordlists/dirb/common.txt -o ./.scratch/gobuster.txt`
- `wpscan --url <url> --enumerate u,p,t -o ./.scratch/wpscan.json` (WordPress only)

### OSINT chain

- `theHarvester -d <domain> -b all -f ./.scratch/harvester.html`
- `recon-ng` (interactive; better via `cdx "build a recon-ng resource file"` for headless)
- `subfinder -d <domain> -o ./.scratch/subdomains.txt`
- `amass enum -d <domain> -o ./.scratch/amass.txt`

### Wordlists and tools paths

- Wordlists: `/usr/share/wordlists/`
- SecLists (install separately): `/usr/share/seclists/`
- Tool configs: `~/.config/<tool>/`

## Useful aliases (add to ~/.zshrc or ~/.bashrc in Kali)

```bash
alias workspace='cd /mnt/c/Users/<you>/Documents/workspace'
alias scratch='cd /mnt/c/Users/<you>/Documents/workspace/.scratch && pwd'
alias updateall='sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y'
alias myip='hostname -I | awk "{print \$1}"'
alias winhost='ip route | grep default | awk "{print \$3}"'
```

## Resource limits

WSL2 default memory: 50% of host or 8GB. To raise, edit `~\.wslconfig`:

```
[wsl2]
memory=12GB
processors=8
swap=8GB
```

Then `wsl --shutdown` and restart. Required for memory-hungry tools (e.g. ZAP, large fuzzing).

## Snapshot and backup

WSL2 distros export to a tarball:

```powershell
wsl --export kali-linux C:\Backups\kali-2026-05-06.tar
# Restore:
wsl --import kali-restored C:\WSL\kali-restored C:\Backups\kali-2026-05-06.tar
```

Run before risky changes.

## Brand context

This skill is brand-agnostic. Apply your project conventions for output paths and authorization scope.


## Legal hard rules

Active scanning, vulnerability testing, and exploitation tooling are restricted to:
- Targets the user owns
- Targets explicitly authorized in writing
- Lab environments

If a task asks for scans/exploits against a target that isn't clearly authorized, return STATUS: blocked and ask for written scope confirmation.

## Common pitfalls

- Running heavy tools from `/mnt/c/...`. Always copy data into `~/` first.
- Time drift: WSL clock can drift from host. Sync with `sudo hwclock -s`.
- `apt` errors on first run: usually `sudo apt update` resolves.
- Some tools require root: `sudo` works. `sudo -E` to preserve env vars.

## Anti-patterns

- Storing target IPs/scope in CLAUDE.md or scratch without explicit justification.
- Running scans without confirming authorization scope.
- Using `--script vuln` defaults nmap on production targets without auth.
- Treating WSL filesystem as ephemeral; back up before destructive ops.
