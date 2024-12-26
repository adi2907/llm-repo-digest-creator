#!/bin/bash

set -x  # Debug on

REPO_NAME=$(basename "$PWD")
OUTPUT_FILE="${REPO_NAME}_repo_digest.txt"

# Source code extensions
SOURCE_EXTENSIONS="\.(py|ipynb|js|jsx|ts|tsx|vue|java|cpp|hpp|c|h|go|rs|rb|php|cs|scala|kt|swift|m|mm|sh|bash|pl|pm|t|less|html|xml|sql|graphql|md|rst|tex|yaml|yml|json|coffee|dart|r|jl|lua|clj|cljs|ex|exs)$"

# Extra exclude patterns (directories, logs, etc.)
EXCLUDE_PATTERNS=(
    "node_modules"
    ".git"
    # Node.js specific
    "package\.json"
    "package-lock\.json"
    "npm-debug\.log"
    "yarn\.lock"
    "yarn-error\.log"
    "node_modules/"
    "\.npm"
    "\.yarn"
    "\.pnp\.js"
    "\.node"

    # Environment and config files
    "\.env.*"
    "\.config\.js"
    "\.conf$"
    "\.cfg$"
    "config\..*"
    "settings\..*"
    "\.ini$"
    "\.properties$"
  
   # Build and deployment
    "webpack\..*\.js"
    "rollup\..*\.js"
    "babel\..*\.js"
    "jest\..*\.js"
    "tsconfig.*\.json"
    "gulpfile\.js"
    "gruntfile\.js"
    "\.gitlab-ci\.yml"
    "\.travis\.yml"
    "\.circleci/"
    "\.github/"
    "\.jenkins.*"
    "Jenkinsfile.*"
    "\.buildspec\.yml"
    "\.terraform/"
    "terraform\..*"
     # CSS Libraries
    "*.css"
    # JavaScript Libraries
    "jquery.*\.js"
    "angular.*\.js"
    "react.*\.js"
    "vue.*\.js"
    "backbone.*\.js"
    "ember.*\.js"
    "three.*\.js"
    "d3.*\.js"
    "lodash.*\.js"
    "moment.*\.js"
    "popper.*\.js"
    "underscore.*\.js"
    "modernizr.*\.js"
    "axios.*\.js"
    "vendor.*\.js"
    "polyfill.*\.js"

    
    # Common CDN directories
    "node_modules/"
    "bower_components/"
    "vendors/"
    "libs/"
    "assets/lib/"
    "static/lib/"
    "public/"

     # Cache and temp directories
    "\.cache/"
    "\.temp/"
    "\.tmp/"
    "temp/"
    "tmp/"
    
    # IDE and editor files
    "\.idea/"
    "\.vscode/"
    "\.sublime/"
    "\.atom/"
    "\.*\.swp$"

    # Other common exclusions
    "\.d\.ts$"
    "\.map$"
    "\.lock$"
    "\.git.*"
    "\.eslintrc.*"
    "\.prettier.*"
    "\.stylelint.*"
    "\.editorconfig"
    "\.htaccess"
    "\.DS_Store"
    "thumbs\.db"
    "\.log$"
    "\.pid$"
    "\.seed$"
    "\.pid\.lock$"
    "\.sass-cache/"
    "\.env\..*"
    "\.venv"
    "venv/"
    "ENV/"
    "env/"
    "requirements\.txt"
    "poetry\.lock"
    "Pipfile.*"
    "composer\..*"
    "\.pytest_cache/"
    "__pycache__/"
    "\.coverage"
    "coverage/"
    "\.nyc_output/"
    "\.next/"
    "\.nuxt/"
    "\.out/"
    "\.storybook/"
    "storybook-static/"
)

# Check if a file is binary
is_binary() {
  [ ! -f "$1" ] && return 1
  local mime
  mime=$(file -b --mime "$1")
  case "$mime" in
    *binary*) return 0 ;;
    *charset=binary*) return 0 ;;
    *) return 1 ;;
  esac
}

# Build -prune list from .gitignore + EXCLUDE_PATTERNS
build_prune_args() {
  local prune_args=()
  
  # Prune .git always
  prune_args+=( -path "./.git" -prune -o )
  
  # From .gitignore
  if [ -f .gitignore ]; then
    while IFS= read -r pattern; do
      # Skip comments/blank
      [[ "$pattern" =~ ^#.*$ || -z "$pattern" ]] && continue
      # Remove trailing slash
      pattern="${pattern%/}"
      prune_args+=( -path "./$pattern" -prune -o )
    done < .gitignore
  fi
  
  # From EXCLUDE_PATTERNS
  for pat in "${EXCLUDE_PATTERNS[@]}"; do
    prune_args+=( -path "./$pat" -prune -o )
  done
  
  echo "${prune_args[@]}"
}

> "$OUTPUT_FILE"
echo "Repository Source Code Contents" >> "$OUTPUT_FILE"
echo "Generated on: $(date)" >> "$OUTPUT_FILE"
echo "----------------------------------------" >> "$OUTPUT_FILE"

total_files=0
included_files=0
excluded_binary=0

PRUNE_ARGS=$(build_prune_args)

while IFS= read -r -d $'\0' path; do
  ((total_files++))
  echo "Processing: $path"
  
  # Check extension
  if [[ "$path" =~ $SOURCE_EXTENSIONS ]]; then
    if ! is_binary "$path"; then
      echo "File: $path" >> "$OUTPUT_FILE"
      echo "----------------------------------------" >> "$OUTPUT_FILE"
      cat "$path" >> "$OUTPUT_FILE"
      echo -e "\n----------------------------------------" >> "$OUTPUT_FILE"
      ((included_files++))
    else
      echo "Skipping binary: $path"
      ((excluded_binary++))
    fi
  else
    echo "Skipping non-source file: $path"
  fi
done < <(eval "find . $PRUNE_ARGS -type f -print0")

echo -e "\nSummary:"
echo "Total files found: $total_files"
echo "Included in output: $included_files"
echo "Skipped binary files: $excluded_binary"
echo "Output: $OUTPUT_FILE"

set +x  # Debug off
