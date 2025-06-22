#!/bin/zsh

function check_installed() {
  if [[ -z "$1" ]]; then
    return 1
  fi
  
  if command -v "$1" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

function biome_init() {
  # This script installs biome in the current repository and migrates exisitng prettier/eslint configs
  echo "Initializing biome for repository $(pwd)"
  if [[ ! -d node_modules ]]; then
    echo "node_modules not present. please install them and then run the command again"
    return 1
  # Figure out, which package manager is used
  PACKAGE_MANAGER=""

  elif [[ -f package-lock.json ]]; then
    echo "Found NPM. Running"
    PACKAGE_MANAGER=`which npm`
    if [[ ! -f "$PACKAGE_MANAGER" ]]; then
      echo "Cannot find $PACKAGE_MANAGER"
      return 1
    fi
    npm install --save-dev --save-exact @biomejs/biome
    npx biome init
    npx biome migrate eslint --write
    npx biome migrate prettier --write
  elif [[ -f bun.lockb ]]; then
    echo "Found Bun. Running..."
    PACKAGE_MANAGER=`which bun`
    if [[ ! -f "$PACKAGE_MANAGER" ]]; then
      echo "Cannot find $PACKAGE_MANAGER"
      return 1
    fi
    bun add --dev --exact @biomejs/biome
    bunx biome init
    bunx biome migrate eslint --write
    bunx biome migrate prettier --write
  elif [[ -f pnpm-lock.json ]]; then
    echo "Found PNPM. Running..."
    PACKAGE_MANAGER=`which pnpm`
    if [[ ! -f "$PACKAGE_MANAGER" ]]; then
      echo "Cannot find $PACKAGE_MANAGER"
      return 1
    fi
    pnpm add --save-dev --save-exact @biomejs/biome
    pnpm biome init
    pnpm biome migrate eslint --write
    pnpm biome migrate prettier --write
  elif [[ -f yarn.lock ]]; then
    echo "Found Yarn. Running..."
    PACKAGE_MANAGER=`which yarn`
    if [[ ! -f "$PACKAGE_MANAGER" ]]; then
      echo "Cannot find $PACKAGE_MANAGER"
      return 1
    fi
    yarn add --dev --exact @biomejs/biome
    yarn biome init
    yarn biome migrate eslint --write
    yarn biome migrate prettier --write
  else
    echo "Package Manager unknown. Exiting..."
    return 1
  fi
  return 0
}

function setup_venv() {
    if [[ ! -d .venv ]]; then 
        echo "creating .venv"
        python3 -m venv .venv
        if [[ ! -f ./.gitignore ]] || ! grep -q "^venv/$" ./.gitignore; then
            curl -L "https://www.gitignore.io/api/python,idea" > ./.gitignore
        fi
        if [[ -f ./requirements.txt ]]; then 
            echo "requirements.txt found, installing"
            ./.venv/bin/pip install -r ./requirements.txt
        fi
    fi
    source ./.venv/bin/activate
}

# Kill Port
function kill_port() {
  echo "Killing multiple processes is not supported."
  if [ -z "$1" ]; then
    echo "Usage: kill_port <port_number>"
    return 1
  fi

  local port="$1"
  local pid

  # Check if lsof is available
  if ! command -v lsof > /dev/null; then
    echo "Error: lsof command is not installed."
    return 1
  fi

  # Find the process using the specified port
  pid=$(lsof -t -i :$port)

  if [ -z "$pid" ]; then
    echo "No process found on port $port."
    return 1
  fi

  # Kill the process
  kill -9 "$pid"
  echo "Killed process $pid running on port $port."
}


function flush_dns() {
  # assert Darwin
  if [[ "$OSTYPE" != "darwin"* ]]; then
    sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
    return 0
  fi

  sudo resolvectl flush-caches
  sudo systemd-resolve --flush-caches
}

function yy() {
  # check if yazi is installed
  if ! command -v yazi > /dev/null; then
    echo "Error: yazi is not installed."
    return 1
  fi
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# Function to browse, confirm, and execute `gi <selection>` with file handling
gif() {
  local gitignore_file=".gitignore"

  # Check if a .gitignore file already exists
  if [[ -e "$gitignore_file" ]]; then
    echo ".gitignore file already exists."
    echo -n "Do you want to overwrite it? (y/n): "
    read overwrite_confirm

    if [[ ! "$overwrite_confirm" =~ ^[Yy]$ ]]; then
      echo "Operation aborted. Existing .gitignore file retained."
      return 1
    fi
  fi

  # Fetch the list of available options from the gitignore API
  local options
  options=$(_gitignoreio_get_command_list)

  # Use fzf for multi-select, separated by commas
  local selection
  selection=$(echo "$options" | fzf --multi --delimiter='\n' --bind 'tab:toggle+down' | tr '\n' ',' | sed 's/,$//')

  if [[ -z "$selection" ]]; then
    echo "No selection made."
    return 1
  fi

  # Confirm the selection with Y as default
  echo "You selected: $selection"
  echo -n "Proceed to write to .gitignore with 'gi $selection'? (Y/n): "
  read confirm

  # Treat empty input or 'y'/'Y' as confirmation
  if [[ -z "$confirm" || "$confirm" =~ ^[Yy]$ ]]; then
    # Write the result of `gi <selection>` to the .gitignore file
    gi "$selection" > "$gitignore_file"
    echo ".gitignore successfully updated with the selected rules."
  else
    echo "Operation cancelled."
  fi
}

# Load homebrew completions, if they exist
load_homebrew_completions() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    MACOS_COMPLETIONS="/opt/homebrew/share/zsh/site-functions"

    # Check if the completions directory exists
    if [[ -d "$MACOS_COMPLETIONS" ]]; then
      for file in "$MACOS_COMPLETIONS"/*; do
        # Check if the file is a regular file and not a directory
        if [[ -f "$file" && ! -d "$file" ]]; then
          # Load the completion file
          source "$file"
        fi
      done
    fi
  fi
}

# Function to browse, confirm, and execute `gi <selection>` with file handling
gitignore_fzf_execute() {
  local gitignore_file=".gitignore"

  # Check if a .gitignore file already exists
  if [[ -e "$gitignore_file" ]]; then
    echo ".gitignore file already exists."
    echo -n "Do you want to overwrite it? (y/n): "
    read overwrite_confirm

    if [[ ! "$overwrite_confirm" =~ ^[Yy]$ ]]; then
      echo "Operation aborted. Existing .gitignore file retained."
      return 1
    fi
  fi

  # Fetch the list of available options from the gitignore API
  local options
  options=$(_gitignoreio_get_command_list)

  # Use fzf for multi-select, separated by commas
  local selection
  selection=$(echo "$options" | fzf --multi --delimiter='\n' --bind 'tab:toggle+down' | tr '\n' ',' | sed 's/,$//')

  if [[ -z "$selection" ]]; then
    echo "No selection made."
    return 1
  fi

  # Confirm the selection with Y as default
  echo "You selected: $selection"
  echo -n "Proceed to write to .gitignore with 'gi $selection'? (Y/n): "
  read confirm

  # Treat empty input or 'y'/'Y' as confirmation
  if [[ -z "$confirm" || "$confirm" =~ ^[Yy]$ ]]; then
    # Write the result of `gi <selection>` to the .gitignore file
    gi "$selection" > "$gitignore_file"
    echo ".gitignore successfully updated with the selected rules."
  else
    echo "Operation cancelled."
  fi
}


init_gitleaks() {
  PRE_COMMIT_CONFIG=".pre-commit-config.yaml"
  if [[ -e $PRE_COMMIT_CONFIG ]]; then
    echo "pre commit config exists"
    return 1
  fi
  if ! check_installed git; then
    echo "git not installed"
    return 1
  fi
  if [[ ! -e ./.git ]]; then
    echo "no git repo present"
    return 1
  fi
  if ! check_installed gitleaks; then
    echo "gitleaks not installed."
    return 1
  fi
  if ! check_installed pre-commit; then
    echo "pre-commit not installed."
    return 1
  fi

  echo "repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.23.1
    hooks:
      - id: gitleaks" >> $PRE_COMMIT_CONFIG
  
  pre-commit autoupdate
  pre-commit install
}