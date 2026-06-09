#! /bin/bash
# PaperShell installer. See `install --help` for usage.
# Highly inspired (i.e. stolen) from the install script for oh-my-fish.

# Set environment options.
set -q PS_REPO_URI;    or set PS_REPO_URI "https://github.com/sylvainhalle/PaperShell"
set -q PS_REPO_BRANCH; or set PS_REPO_BRANCH "v3"



  # Ensure repository URL ends with .git
  set PS_REPO_URI (echo $PS_REPO_URI | command sed 's/\.git//').git

  # Parse command args
  while set -q argv[1]
    switch "$argv[1]"
      case --help -h
        echo "Usage: install [options]
  Install PaperShell

Options:
  --check                 Do a system readiness check without installing.
  --help, -h              Show this help message.
  --noninteractive        Disable interactive questions (assume no, use with --yes to assume yes).
  --path=<path>           Use a specific install path (default is $PS_PATH_DEFAULT).
  --uninstall             Uninstall existing installation instead of installing.
  --verbose               Enable verbose debugging statements for the installer.
  --yes, -y               Assume yes for interactive questions.
"
        return 0

      case --check
        set -g CHECK_ONLY

      case '--config=*'
        echo "$argv[1]" | command cut -d= -f2- | command sed -e "s#~#$HOME#" | read -g PS_CONFIG

      case --noninteractive
        set -g NONINTERACTIVE

      case '--path=*'
        echo "$argv[1]" | command cut -d= -f2- | command sed -e "s#~#$HOME#" | read -g PS_PATH

      case --uninstall
        set -g UNINSTALL

      case --verbose
        set -g VERBOSE
        debug "verbose turned on"

      case --yes -y
        set -g ASSUME_YES

      case '*'
        abort "Unrecognized option '$argv[1]'. Try 'install --help' for usage."
    end
    set -e argv[1]
  end

  # Do the check only.
  if set -q CHECK_ONLY
    sane_environment_check
    return
  end

  assert_interactive

  # Ensure the environment meets all of the requirements.
  if not sane_environment_check
    abort "Environment does not meet the requirements."
  end

  # If the user wants to uninstall, jump to uninstallation and exit.
  if set -q UNINSTALL
    uninstall_omf
    return
  end

  # Check if OMF is already installed.
  if test -d "$PS_PATH"
    if is_install_dir "$PS_PATH"
      say "Existing installation detected at $PS_PATH"

      confirm_yes "Would you like to remove the existing installation?"
      uninstall_omf
    else
      abort "Target directory $PS_PATH already exists"
    end
  end

  # Begin the install process.
  install_omf

  # We made it!
  say "Installation successful!"

  return 0
end

# Add an exit hook to display a message if the installer aborts or errors.
function on_exit -p %self
  if not contains $argv[3] 0 2
    echo "
PaperShell installation failed.

If you think that it's a bug, please open an
issue with the complete installation log here:

https://github.com/sylvainhalle/PaperShell/issues"

    if not set -q VERBOSE
      echo
      echo "Try rerunning with --verbose to see additional output."
    end
  end
end

# Installs PaperShell.
function install_omf
  say "Installing PaperShell to $PS_PATH..."

  # Prepare paths
  command mkdir -p (dirname "$PS_PATH")

  # Install step
  install_from_github

  # Config step
  install_bootstrap
end

# Downloads and installs the framework from GitHub.
function install_from_github
  say "Cloning PaperShell from $PS_REPO_URI..."

  if not command git clone -q -b "$PS_REPO_BRANCH" "$PS_REPO_URI" "$PS_PATH"
    abort "Error cloning repository!"
  end

	# Get the commit for the latest release.
	set -l hash (command git --git-dir "$PS_PATH/.git" --work-tree "$PS_PATH" rev-list --tags='v*' --max-count=1 2> /dev/null)
	  # Get the release tag.
	  and set -l tag (command git --git-dir "$PS_PATH/.git" --work-tree "$PS_PATH" describe --tags $hash)
	  # Checkout the release.
	  and command git --git-dir "$PS_PATH/.git" --work-tree "$PS_PATH" checkout --quiet tags/$tag
	  or report error "Error getting latest version!"

  set_git_remotes
end

# Set upstream remotes on the framework Git repository.
function set_git_remotes
  set git_upstream (command git --git-dir "$PS_PATH/.git" --work-tree "$PS_PATH" config remote.upstream.url)

  if test -z "$git_upstream"
    command git --git-dir "$PS_PATH/.git" --work-tree "$PS_PATH" remote add upstream $PS_REPO_URI
  else
    command git --git-dir "$PS_PATH/.git" --work-tree "$PS_PATH" remote set-url upstream $PS_REPO_URI
  end
end

# Sets up the necessary bootstrap code for Fish to load OMF.
function install_bootstrap
  set -l fish_config_file "$FISH_CONFIG/config.fish"
  set -l vendor_config_file "$FISH_CONFIG/conf.d/omf.fish"

  # Create the Fish config directory if it doesn't exist yet (if the first thing the user runs with Fish is this
  # installer, for example).
  command mkdir -p "$FISH_CONFIG"

  # If PaperShell is already configured and ready to go, there's nothing else we need to do here.
  if is_omf_loaded
    return 0

  # Even though config.fish already exists, we can prepend to it if the user is OK with it.
  else if confirm "Would you like PaperShell to be added to your configuration automatically?"
    say "Prepending bootstrap to $fish_config_file..."

    # Create a temporary file to store the combined config so that we can write atomically.
    generate_bootstrap | command cat - "$fish_config_file" > "$fish_config_file.tmp"
      or abort "Error prepending config file"

    # Swap in the prepended file.
    command mv "$fish_config_file.tmp" "$fish_config_file"
      or abort "Error moving file to $fish_config_file"

  # We don't have any options left, so let the user set up the bootstrap manually.
  else
    say "Nothing to do then"
  end
end

# Generates the bootstrap code used to initialize PaperShell on shell startup.
function generate_bootstrap
  echo "# Path to PaperShell install."

  if test "$PS_PATH" = "$PS_PATH_DEFAULT"
    echo "\
set -q XDG_DATA_HOME
  and set -gx PS_PATH \"\$XDG_DATA_HOME/omf\"
  or set -gx PS_PATH \"\$HOME/.local/share/omf\""
  else
    echo "set -gx PS_PATH '$PS_PATH'"
  end
end


# Uninstalls an existing OMF installation.
function uninstall_omf
  is_install_dir "$PS_PATH"
    or abort "No installation detected at $PS_PATH"

  say (set_color -o red 2> /dev/null)"This will uninstall PaperShell and all themes from $PS_PATH."(set_color normal 2> /dev/null)

  confirm_yes "Are you sure you want to continue?"
  say "Uninstalling from $PS_PATH..."

  # Remove the core framework
  command rm -rf "$PS_PATH"
    or abort "Uninstall failed"

  # Remove the bootstrap if it is managed by us
  set -l vendor_config_file "$FISH_CONFIG/conf.d/omf.fish"
  if test -e "$vendor_config_file"
    command rm "$vendor_config_file"
      or abort "Failed to remove bootstrap file"
  end

  say "Uninstall complete"
end

# Verify we have a sane environment that OMF can run in.
function sane_environment_check
  say "Checking for a sane environment..."
  assert_cmds

  debug "Checking for a sane 'head' implementation"
  set -l result (printf 'a\nb\n' | cmd head -n 1)
    and test "$result" = 'a'
    or abort (which head)" is not a sane 'head' implementation"

  debug "Verifying Git implementation is not buggy Git for Windows"
  if cmd git --version | cmd grep -i -q windows
    abort (which git)" is Git for Windows which is not supported."
  end

  debug "Verifying Git autocrlf is not enabled"
  if test (cmd git config core.autocrlf; or echo false) = true
    abort "Please disable core.autocrlf in your Git configuration."
  end
end

# Gets the version of Git installed.
function get_git_version
  type -f git > /dev/null 2> /dev/null
    and command git --version | command cut -d' ' -f3
end

# Assert that a minimum required version of Git is installed.
function assert_git_version_compatible -a required_version
  set -l installed_version (get_git_version)
    and is_version_compatible $required_version $installed_version
    or abort "Git version $required_version or greater required; you have $installed_version"
end

# Assert that all tools we need are available.
function assert_cmds
  set -l cmds basename cp dirname env fold git head lualatex mkdir mv readlink rm sed sort texlua tr which

  for cmd in $cmds
    type -f $cmd > /dev/null 2> /dev/null
      or abort "Missing required command: $cmd"

    debug "Command '$cmd' is "(which $cmd)
  end
end

# Ensures the keyboard is readable if in interactive mode.
function assert_interactive
  set -q NONINTERACTIVE
    and return

  test -c /dev/tty -a -r /dev/tty
    and echo -n > /dev/tty 2> /dev/null
    or abort "Running interactively, but can't read from tty (try running with --noninteractive)"
end

# Print a message to the user.
function say -a message
  printf "$message\n" | command fold -s -w 80
end


# Write a debug message.
function debug -a message
  if set -q VERBOSE
    printf 'DEBUG: %s\n' "$message" >&2
  end
end


# Aborts the installer and displays an error.
function abort -a message code
  if test -z "$code"
    set code 1
  end

  if test -n "$message"
    printf "%sInstall aborted: $message%s\n" (set_color -o red 2> /dev/null) (set_color normal 2> /dev/null) >&2
  else
    printf "%sInstall aborted%s\n" (set_color -o red 2> /dev/null) (set_color normal 2> /dev/null) >&2
  end

  exit $code
end


# Asks the user for confirmation.
function confirm -a message
  # Return true if we assume yes for all questions.
  set -q ASSUME_YES
    and return 0

  # Return false if we can't ask the question.
  set -q NONINTERACTIVE
    and return 1

  printf "%s$message (y/N): %s" (set_color yellow 2> /dev/null) (set_color normal 2> /dev/null)
  read -l answer < /dev/tty
    or abort "Failed to read from tty"

  not test "$answer" != y -a "$answer" != Y -a "$answer" != yes
end


# Asks the user for a confirmation or aborts.
function confirm_yes -a message
  confirm "$message"
    or abort "Canceled by user" 2
end


main $argv