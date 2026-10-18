#!/usr/bin/env bash
#
# scripts/sync-skills.sh
# Synchronizes the central agent skills repository with origin/main and
# ensures all harness symlinks (T3 Code, Claude, Cursor, Codex, OpenCode, Gemini/Antigravity)
# point to the active skills directory.
#

set -euo pipefail

SKILLS_REPO="${SKILLS_REPO:-$HOME/code/skills}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_FILE="$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"

VERBOSE=false
SKIP_GIT=false

log() {
  if [ "$VERBOSE" = true ]; then
    echo "[skills-sync] $*"
  fi
}

log_err() {
  echo "[skills-sync] ERROR: $*" >&2
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --install     Install systemd user service & timer for background auto-sync and link CLI to ~/.local/bin/skills-sync
  --status      Display sync status and harness symlink verification
  --skip-git    Skip git fetch/merge and only verify harness symlinks
  --verbose, -v Enable verbose output
  --help, -h    Show this help message
EOF
}

ensure_symlink() {
  local target="$1"
  local link="$2"

  local link_parent
  link_parent="$(dirname "$link")"
  if [ ! -d "$link_parent" ]; then
    mkdir -p "$link_parent"
  fi

  if [ -L "$link" ]; then
    local current_target
    current_target="$(readlink "$link")"
    if [ "$current_target" != "$target" ]; then
      log "Updating symlink: $link -> $target (was $current_target)"
      ln -sfn "$target" "$link"
    fi
  elif [ -e "$link" ]; then
    log_err "$link exists and is not a symlink. Skipping to avoid data loss."
  else
    log "Creating symlink: $link -> $target"
    ln -s "$target" "$link"
  fi
}

verify_and_link_harnesses() {
  log "Verifying harness symlinks..."

  # Standard agent discovery paths
  ensure_symlink "$SKILLS_REPO" "$HOME/.agents/skills"
  ensure_symlink "$SKILLS_REPO" "$HOME/.claude/skills"
  ensure_symlink "$SKILLS_REPO" "$HOME/.cursor/skills"
  ensure_symlink "$SKILLS_REPO" "$HOME/.codex/skills"
  ensure_symlink "$SKILLS_REPO" "$HOME/.config/opencode/skills"
  ensure_symlink "$SKILLS_REPO" "$HOME/skills"
  ensure_symlink "$SKILLS_REPO" "$HOME/.gemini/config/skills"
  ensure_symlink "$SKILLS_REPO/pstack" "$HOME/.gemini/antigravity-cli/skills"

  # T3 Code Antigravity providers
  if [ -d "$HOME/.t3/userdata/providers/antigravity" ]; then
    for provider_dir in "$HOME/.t3/userdata/providers/antigravity"/*; do
      if [ -d "$provider_dir" ]; then
        ensure_symlink "$HOME/.gemini/config/skills" "$provider_dir/config/skills"
        if [ -d "$SKILLS_REPO/pstack" ]; then
          ensure_symlink "$HOME/.gemini/antigravity-cli/skills" "$provider_dir/antigravity-cli/skills"
        fi
      fi
    done
  fi
}

sync_git_repo() {
  if [ ! -d "$SKILLS_REPO/.git" ]; then
    log_err "Skills repository not found at $SKILLS_REPO"
    return 1
  fi

  # Check if remote origin is configured
  if ! git -C "$SKILLS_REPO" remote get-url origin >/dev/null 2>&1; then
    log "No remote 'origin' configured for $SKILLS_REPO"
    return 0
  fi

  # Attempt git fetch with timeout
  log "Fetching updates from origin..."
  if ! git -C "$SKILLS_REPO" fetch origin main --quiet 2>/dev/null; then
    log "Could not fetch from origin (offline or credentials unavailable). Skipping git update."
    return 0
  fi

  # Only fast-forward if we are currently on branch 'main'
  local current_branch
  current_branch="$(git -C "$SKILLS_REPO" branch --show-current 2>/dev/null || echo "")"

  if [ "$current_branch" = "main" ]; then
    local local_sha upstream_sha
    local_sha="$(git -C "$SKILLS_REPO" rev-parse HEAD)"
    upstream_sha="$(git -C "$SKILLS_REPO" rev-parse origin/main)"

    if [ "$local_sha" != "$upstream_sha" ]; then
      log "Updates detected. Fast-forwarding main ($local_sha -> $upstream_sha)..."
      local merge_output
      if merge_output="$(git -C "$SKILLS_REPO" merge --ff-only origin/main 2>&1)"; then
        echo "[skills-sync] Successfully fast-forwarded skills repository to origin/main."
      else
        # If untracked files block the merge, check if they are identical to origin/main
        local resolved_all=false
        local untracked_files=()
        while IFS= read -r line; do
          if [[ "$line" =~ ^[[:space:]]+(.*)$ ]]; then
            untracked_files+=("${BASH_REMATCH[1]}")
          fi
        done < <(echo "$merge_output" | sed -n '/untracked working tree files would be overwritten by merge:/,/Please move or remove/p' | grep '^[[:space:]]' || true)

        if [ ${#untracked_files[@]} -gt 0 ]; then
          resolved_all=true
          for f in "${untracked_files[@]}"; do
            local file_path="$SKILLS_REPO/$f"
            if [ -f "$file_path" ] && git -C "$SKILLS_REPO" cat-file -e "origin/main:$f" 2>/dev/null; then
              local local_hash upstream_hash
              local_hash="$(git -C "$SKILLS_REPO" hash-object "$file_path")"
              upstream_hash="$(git -C "$SKILLS_REPO" rev-parse "origin/main:$f")"
              if [ "$local_hash" = "$upstream_hash" ]; then
                log "Removing identical untracked file before merge: $f"
                rm -f "$file_path"
              else
                resolved_all=false
                break
              fi
            else
              resolved_all=false
              break
            fi
          done

          if [ "$resolved_all" = true ]; then
            if merge_output="$(git -C "$SKILLS_REPO" merge --ff-only origin/main 2>&1)"; then
              echo "[skills-sync] Successfully fast-forwarded skills repository to origin/main."
              return 0
            fi
          fi
        fi

        log_err "Could not fast-forward main (uncommitted changes or diverge). Manual resolution needed."
        while IFS= read -r line; do
          log_err "  $line"
        done <<< "$merge_output"
      fi
    else
      log "Repository is already up to date with origin/main."
    fi
  else
    log "Repository on branch '$current_branch' (not main). Skipping automatic fast-forward."
  fi
}

install_systemd_timer() {
  echo "Installing skills-sync to ~/.local/bin/skills-sync..."
  mkdir -p "$HOME/.local/bin"

  # Ensure canonical repository has scripts/sync-skills.sh
  mkdir -p "$SKILLS_REPO/scripts"
  if [ "$SCRIPT_FILE" != "$SKILLS_REPO/scripts/sync-skills.sh" ]; then
    cp "$SCRIPT_FILE" "$SKILLS_REPO/scripts/sync-skills.sh"
  fi
  chmod +x "$SKILLS_REPO/scripts/sync-skills.sh"

  ln -sfn "$SKILLS_REPO/scripts/sync-skills.sh" "$HOME/.local/bin/skills-sync"

  echo "Configuring systemd user service and timer..."
  local systemd_dir="$HOME/.config/systemd/user"
  mkdir -p "$systemd_dir"

  cat > "$systemd_dir/skills-sync.service" <<EOF
[Unit]
Description=Sync Central Skills Repository with Origin
After=network-online.target

[Service]
Type=oneshot
ExecStart=$HOME/.local/bin/skills-sync
EOF

  cat > "$systemd_dir/skills-sync.timer" <<EOF
[Unit]
Description=Run skills-sync periodically every 2 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=2min
AccuracySec=10s

[Install]
WantedBy=timers.target
EOF

  systemctl --user daemon-reload
  systemctl --user enable --now skills-sync.timer
  echo "✓ skills-sync.timer enabled and running every 2 minutes."

  # Also install git post-merge hook in code/skills
  if [ -d "$SKILLS_REPO/.git/hooks" ]; then
    cat > "$SKILLS_REPO/.git/hooks/post-merge" << 'HOOK_EOF'
#!/usr/bin/env bash
if command -v skills-sync >/dev/null 2>&1; then
  skills-sync --skip-git
fi
HOOK_EOF
    chmod +x "$SKILLS_REPO/.git/hooks/post-merge"
    echo "✓ Git post-merge hook configured in $SKILLS_REPO."
  fi
}

show_status() {
  echo "=== Skills Repository Status ==="
  echo "Path: $SKILLS_REPO"
  if [ -d "$SKILLS_REPO/.git" ]; then
    local branch
    branch="$(git -C "$SKILLS_REPO" branch --show-current 2>/dev/null || echo "detached")"
    echo "Branch: $branch"
    echo "Latest commit: $(git -C "$SKILLS_REPO" log -1 --oneline 2>/dev/null || echo "none")"
    local diff_count
    diff_count="$(git -C "$SKILLS_REPO" rev-list --count HEAD..origin/main 2>/dev/null || echo "0")"
    echo "Commits behind origin/main: $diff_count"
  else
    echo "Not a git repository."
  fi

  echo ""
  echo "=== Top-Level Skills Available ==="
  for dir in "$SKILLS_REPO"/*; do
    if [ -d "$dir" ] && [ -f "$dir/SKILL.md" ]; then
      echo "  - $(basename "$dir")"
    fi
  done
  if [ -d "$SKILLS_REPO/pstack" ]; then
    local pstack_count=0
    for dir in "$SKILLS_REPO/pstack"/*; do
      if [ -d "$dir" ] && [ -f "$dir/SKILL.md" ]; then
        pstack_count=$((pstack_count + 1))
      fi
    done
    echo "  - pstack ($pstack_count skills)"
  fi

  echo ""
  echo "=== Harness Symlink Status ==="
  local paths=(
    "$HOME/.agents/skills"
    "$HOME/.claude/skills"
    "$HOME/.cursor/skills"
    "$HOME/.codex/skills"
    "$HOME/.config/opencode/skills"
    "$HOME/.gemini/config/skills"
    "$HOME/.gemini/antigravity-cli/skills"
  )

  for p in "${paths[@]}"; do
    if [ -L "$p" ]; then
      echo "  ✓ $p -> $(readlink "$p")"
    elif [ -e "$p" ]; then
      echo "  ! $p (regular directory/file, not symlink)"
    else
      echo "  ✗ $p (missing)"
    fi
  done

  if [ -d "$HOME/.t3/userdata/providers/antigravity" ]; then
    for provider_dir in "$HOME/.t3/userdata/providers/antigravity"/*; do
      if [ -d "$provider_dir" ]; then
        local p_skill="$provider_dir/config/skills"
        if [ -L "$p_skill" ]; then
          echo "  ✓ T3 Antigravity ($provider_dir): $p_skill -> $(readlink "$p_skill")"
        else
          echo "  ✗ T3 Antigravity ($provider_dir): $p_skill missing"
        fi
      fi
    done
  fi

  echo ""
  echo "=== Background Timer Status ==="
  if systemctl --user is-active skills-sync.timer >/dev/null 2>&1; then
    echo "  ✓ skills-sync.timer is active and enabled"
  else
    echo "  ✗ skills-sync.timer is inactive (run $(basename "$0") --install to enable)"
  fi
}

main() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --install)
        install_systemd_timer
        exit 0
        ;;
      --status)
        show_status
        exit 0
        ;;
      --skip-git)
        SKIP_GIT=true
        shift
        ;;
      -v|--verbose)
        VERBOSE=true
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        log_err "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
  done

  if [ "$SKIP_GIT" = false ]; then
    sync_git_repo
  fi
  verify_and_link_harnesses
}

main "$@"
