#!/usr/bin/env bash
# ============================================================
#  update-docker-notes-repo-session4.sh
#  Pushes the latest notes 16-18 + updated cheatsheet + README
#  Run from INSIDE your cloned repo directory:
#    cd docker-learning-notes
#    bash update-docker-notes-repo-session4.sh
# ============================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
die()     { echo -e "${RED}[ERR]${RESET}   $*" >&2; exit 1; }

echo -e "\n${BOLD}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║   Docker Notes — Update Script                       ║${RESET}"
echo -e "${BOLD}║   Topics: Advanced Dockerfiles, Apps, Multistage     ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════╝${RESET}\n"

# ── sanity checks ─────────────────────────────────────────
command -v git &>/dev/null || die "git not found."
[[ -f "README.md" ]] || die "Run this from inside your cloned repo directory!"
[[ -d "notes" ]]     || die "'notes/' directory not found. Wrong directory?"

success "Repo directory confirmed: $(pwd)"

# ── PAT ───────────────────────────────────────────────────
read -rsp "$(echo -e ${CYAN}Paste your GitHub PAT \(hidden\):${RESET} )" GIT_PAT
echo ""
[[ -z "${GIT_PAT}" ]] && die "PAT cannot be empty."
git remote set-url origin "https://ganesh928k:${GIT_PAT}@github.com/ganesh928k/docker-learning-notes.git"

info "Pulling latest from origin/main..."
git pull origin main
success "Up to date."

# ════════════════════════════════════════════════════════════
#  GIT COMMIT & PUSH
# ════════════════════════════════════════════════════════════
echo ""
info "Staging all changes..."
git add .

info "Committing..."
git commit -m "feat: add session-4 notes (Advanced Dockerfile, Apps, Multistage)

New notes:
- 16-dockerfile-advanced-instructions.md
- 17-practical-app-deployments.md
- 18-multistage-builds.md

Updated:
- cheatsheet.md: added Advanced Dockerfile commands
- README.md: added new notes to table of contents" || true

info "Pushing to GitHub..."
git push origin main

# ── done ──────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GREEN}║   ✅  Done! Updates pushed successfully.                   ║${RESET}"
echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  🔗 ${CYAN}https://github.com/ganesh928k/docker-learning-notes${RESET}"
echo ""
