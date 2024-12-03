#!/bin/bash

# Enable debug mode
set -x
# Get repository name from git
REPO_NAME=$(basename -s .git `git config --get remote.origin.url`)

# Output file name
OUTPUT_FILE="${REPO_NAME}_repo_digest.txt"


# Source code extensions to include (excluding .css files)
SOURCE_EXTENSIONS="\.(py|js|jsx|ts|tsx|vue|java|cpp|hpp|c|h|go|rs|rb|php|cs|scala|kt|swift|m|mm|sh|bash|pl|pm|t|less|html|xml|sql|graphql|md|rst|tex|yaml|yml|json|coffee|dart|r|jl|lua|clj|cljs|ex|exs)$"

# Common files and patterns to exclude
EXCLUDE_PATTERNS=(
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

    # Docker related
    "Dockerfile.*"
    "\.dockerignore"
    "docker-compose.*\.(yml|yaml)"
    "\.docker/"

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
    "bootstrap.*\.(css|js)"
    "bulma.*\.(css|js)"
    "tailwind.*\.(css|js)"
    "foundation.*\.(css|js)"
    "materialize.*\.(css|js)"
    "semantic.*\.(css|js)"
    "normalize.*css"
    "reset.*css"
    "fontawesome.*\.(css|js)"
    "all\.css"
    "styles\.min\.css"
    "main\.min\.css"
    
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
    
    # General patterns for minified files
    "\.min\.(js|css)$"
    "bundle\.(js|css)$"
    "vendor\.(js|css)$"
    "dist/.*\.(js|css)$"
    "build/.*\.(js|css)$"
    
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

# Function to check if a file should be excluded
should_exclude() {
    local file="$1"
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        if echo "$file" | egrep -qi "$pattern"; then
            echo "Excluding file: $file (matched pattern: $pattern)"
            return 0
        fi
    done
    return 1
}

# Function to check if a file is binary
is_binary() {
    if [ ! -f "$1" ]; then
        echo "Warning: File $1 does not exist"
        return 1
    fi
    mime=$(file -b --mime "$1")
    echo "Mime type for $1: $mime"
    case "$mime" in
        *binary*) return 0 ;;
        *charset=binary*) return 0 ;;
        *) return 1 ;;
    esac
}

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Error: Not in a git repository"
    exit 1
fi

# Clear or create output file
echo "Repository Source Code Contents" > "$OUTPUT_FILE"
echo "Generated on: $(date)" >> "$OUTPUT_FILE"
echo "----------------------------------------" >> "$OUTPUT_FILE"

# Get list of all tracked files recursively
OLDIFS="$IFS"
IFS=$'\n'
files=($(git ls-files))
IFS="$OLDIFS"

echo "Found ${#files[@]} files in repository"

# Statistics
total_files=0
excluded_libs=0
excluded_binary=0
excluded_config=0
included_files=0

# Process each file
for file in "${files[@]}"; do
    ((total_files++))
    echo "Processing file: $file"
    
    # Check if file exists and is not in .git directory
    if [ ! -f "$file" ] || [[ "$file" == .git/* ]]; then
        echo "Skipping: $file"
        continue
    fi
    
    # Check if file should be excluded
    if should_exclude "$file"; then
        ((excluded_config++))
        continue
    fi
    
    # Check if file matches source code extensions
    if echo "$file" | egrep -i "$SOURCE_EXTENSIONS" >/dev/null; then
        echo "File $file matches source extensions"
        
        # Check if file is binary
        if ! is_binary "$file"; then
            echo "Adding $file to output"
            echo -e "\nFile: $file" >> "$OUTPUT_FILE"
            echo "----------------------------------------" >> "$OUTPUT_FILE"
            cat "$file" >> "$OUTPUT_FILE"
            echo -e "\n----------------------------------------" >> "$OUTPUT_FILE"
            ((included_files++))
        else
            echo "Skipping binary file: $file"
            ((excluded_binary++))
        fi
    else
        echo "Skipping file with non-matching extension: $file"
    fi
done

# Print summary
echo -e "\nConcatenation Summary:"
echo "Total files processed: $total_files"
echo "Configuration/Environment files excluded: $excluded_config"
echo "Binary files excluded: $excluded_binary"
echo "Files included in output: $included_files"
echo "Output saved to: $OUTPUT_FILE"
echo "Total size: $(wc -l < "$OUTPUT_FILE") lines"

# List all included files
echo -e "\nFiles included in concatenation:"
grep "^File: " "$OUTPUT_FILE" | sed 's/^File: //'

# Disable debug mode
set +x
