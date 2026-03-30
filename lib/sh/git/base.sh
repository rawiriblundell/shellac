# shellcheck shell=bash

# Copyright 2022 Rawiri Blundell
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
################################################################################
# Provenance: https://github.com/rawiriblundell/shellac
# Adapted from HariSekhon/DevOps-Bash-tools (MIT) https://github.com/HariSekhon/DevOps-Bash-tools
# SPDX-License-Identifier: Apache-2.0

[ -n "${_SHELLAC_LOADED_git_base+x}" ] && return 0
_SHELLAC_LOADED_git_base=1

# @description Return 0 if the current directory is inside a git repository.
# @exitcode 0 Inside a git repo; 1 Otherwise
git_is_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

# @description Get the absolute path to the root of the current git repository.
#
# @stdout Repository root path
# @exitcode 0 Success; 1 Not in a git repo
git_root() {
  git rev-parse --show-toplevel 2>/dev/null
}

# @description Get the URL for a named git remote.
#
# @arg $1 string Remote name (default: origin)
#
# @example
#   git_remote_get            # => git@github.com:owner/repo.git
#   git_remote_get upstream   # => https://github.com/owner/upstream.git
#
# @stdout Remote URL
# @exitcode 0 Success
# @exitcode 1 Not in a git repo or remote not found
git_remote_get() {
  local remote
  remote="${1:-origin}"
  if ! git_is_repo; then
    printf -- '%s\n' "git_remote_get: not in a git repository" >&2
    return 1
  fi
  command git remote get-url "${remote}" 2>/dev/null || {
    printf -- '%s\n' "git_remote_get: remote '${remote}' not found" >&2
    return 1
  }
}

# @description Get the name of the current git repository (from the remote URL,
#   falling back to the directory name).
#
# @stdout Repository name (without .git suffix)
# @exitcode 0 Always
git_repo_name() {
  local remote name
  remote="$(git remote get-url origin 2>/dev/null)"
  if [[ -n "${remote}" ]]; then
    # Strip trailing .git and take the basename
    name="${remote##*/}"
    name="${name%.git}"
    printf -- '%s\n' "${name}"
  else
    # Fall back to directory name
    basename "$(git_root 2>/dev/null || pwd)"
  fi
}

# @description Get the name of the current branch.
#
# @stdout Branch name
# @exitcode 0 Success; 1 Not in a git repo or detached HEAD
git_current_branch() {
  local branch
  branch="$(git symbolic-ref --short HEAD 2>/dev/null)" || return 1
  printf -- '%s\n' "${branch}"
}

# @description Get the default branch name (main or master) for the repo.
#   Checks remote HEAD reference first; falls back to probing local branches.
#
# @stdout Default branch name (e.g. "main" or "master")
# @exitcode 0 Found; 1 Unable to determine
git_default_branch() {
  local branch
  # Try remote HEAD symbolic ref
  branch="$(git remote show origin 2>/dev/null | awk '/HEAD branch/{print $NF}')"
  if [[ -n "${branch}" && "${branch}" != "(unknown)" ]]; then
    printf -- '%s\n' "${branch}"
    return 0
  fi
  # Probe common names in local refs
  local candidate
  for candidate in main master trunk develop; do
    if git show-ref --verify --quiet "refs/heads/${candidate}" 2>/dev/null; then
      printf -- '%s\n' "${candidate}"
      return 0
    fi
  done
  return 1
}

# @description Get the short (7-char) SHA of the current HEAD commit.
#
# @stdout Short SHA string
# @exitcode 0 Success; 1 Not in a git repo
git_short_sha() {
  git rev-parse --short HEAD 2>/dev/null
}

# @description Return 0 if the given file is tracked by git.
#
# @arg $1 string File path
#
# @exitcode 0 Tracked; 1 Not tracked or not in repo
git_is_tracked() {
  local file
  file="${1:?git_is_tracked: missing file argument}"
  git ls-files --error-unmatch -- "${file}" >/dev/null 2>&1
}

# @description Print the commit date of the most recent commit that touched a file,
#   in epoch seconds followed by a relative date string, for easy sorting.
#
# @arg $1 string File path to query
#
# @example
#   git_newest_commit_date README.md   # => 1710000000 (3 weeks ago)
#
# @stdout Epoch time and relative date, e.g. "1710000000 (3 weeks ago)"
# @exitcode 0 Always
git_newest_commit_date() {
    git --no-pager log -1 --pretty=format:'%ct (%cr)' -- "${1:?No file specified}"
}

# @description Change directory to the top of the current git repository tree,
#   optionally appending a subdirectory path.
#
# @arg $1 string Optional subdirectory path relative to the repo root
#
# @exitcode 0 Success
# @exitcode 1 Not in a git repository or cd failed
git_cd() {
  case "$(git rev-parse --show-toplevel 2>&1)" in
    (fatal*) return 1 ;;
    (*)      cd "$(git rev-parse --show-toplevel)/${1}" || return 1 ;;
  esac
}

# @description Alias for git_cd.
gcd() { git_cd "${@}"; }

# @description Delete one or more git branches locally, remotely, or both. With no
#   branch argument, launches an fzf multi-select prompt.
#
# @arg $1 string Optional mode flag: --local (default), --remote, or --both
# @arg $2 string Branch name(s) to delete, or omit to use fzf interactive selection
#
# @exitcode 0 Always (individual git commands may fail silently)
git_delete_branch() {
  local unwanted_branches current_branch mode
  current_branch="$(git symbolic-ref -q HEAD)"
  current_branch="${current_branch##refs/heads/}"
  current_branch="${current_branch:-HEAD}"

  case "${1}" in
    (--local)  shift 1; mode=local ;;
    (--remote) shift 1; mode=remote ;;
    (--both)   shift 1; mode=both ;;
    (*)        mode=local ;;
  esac

  case "${1}"  in
    ('')
      unwanted_branches=$(
        git branch |
          grep --invert-match '^\*' |
          cut -c 3- |
          fzf --multi --preview="git log {}"
      )
    ;;
    (*)  unwanted_branches="${*}" ;;
  esac

  case "${mode}" in
    (local)
      for branch in ${unwanted_branches}; do
        git branch --delete --force "${branch}"
      done
    ;;
    (remote)
      for branch in ${unwanted_branches}; do
        git push origin --delete "${branch}"
      done
    ;;
    (both)
      for branch in ${unwanted_branches}; do
        git branch --delete --force "${branch}"
        git push origin --delete "${branch}"
      done
    ;;
  esac
}

# Let 'git' take the perf hit of setting GIT_BRANCH rather than PROMPT_COMMAND.
# There's no one true way to get the current git branch; they all have pros/cons.
# See e.g. https://stackoverflow.com/q/6245570
if command -v git >/dev/null 2>&1; then
  # @description Wrapper around the 'git' command that keeps GIT_BRANCH up to date
  #   after every invocation and warns if a command references 'master' when the repo
  #   uses 'main' instead.
  #
  # @arg $1 string Git subcommand and arguments (passed through to git)
  #
  # @exitcode 0 Git command succeeded
  # @exitcode 1 'master' reference detected in a 'main'-only repo
  git() {
    # If the args contain any mention of a master branch, we check for the newer
    # 'main' nomenclature.  We take no other position than to suggest the correct command.
    if case "${*}" in (*master*) true ;; (*) false ;; esac; then
      if command git branch 2>/dev/null | grep -qw "main"; then
        printf -- '%s\n' "This repo uses 'main' rather than 'master'." \
          "Try: 'git ${*/master/main}'" \
          "To override this warning, try: 'command git ${*}'" >&2
        return 1
      fi
    fi
    command git "${@}"
    GIT_BRANCH="$(command git branch 2>/dev/null| sed -n '/\* /s///p')"
    export GIT_BRANCH
  }
fi
