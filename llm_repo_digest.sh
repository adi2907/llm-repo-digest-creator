#!/bin/bash

# Enable debug mode
set -x
# Get repository name from git
REPO_NAME=$(basename "$PWD")
OUTPUT_FILE="${REPO_NAME}_repo_digest.txt"

# Source code extensions to include (excluding .css files)
SOURCE_EXTENSIONS="\.(py|ipynb|js|jsx|ts|tsx|vue|java|cpp|hpp|c|h|go|rs|rb|php|cs|scala|kt|swift|m|mm|sh|bash|pl|pm|t|less|html|xml|sql|graphql|md|rst|tex|yaml|yml|json|coffee|dart|r|jl|lua|clj|cljs|ex|exs)$"

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

# Function to convert gitignore pattern to find pattern
convert_gitignore_pattern() {
    local pattern="$1"
    
    # Remove leading and trailing slashes
    pattern=$(echo "$pattern" | sed 's/^\///' | sed 's/\/$//') 
    
    # Handle special gitignore patterns
    case "$pattern" in
        # Handle '**' pattern (matches zero or more directories)
        *"**"*)
            pattern=$(echo "$pattern" | sed 's/\*\*/*/g')
            ;;
        # Handle leading '*' (doesn't match /)
        "*"*)
            pattern="*/$pattern"
            ;;
        # Handle trailing '*' (doesn't match /)
        *"*")
            pattern="$pattern*"
            ;;
    esac
    
    # Convert ? to . (single character wildcard)
    pattern=$(echo "$pattern" | sed 's/?/./g')
    
    # If pattern is a directory (ends with /), match all contents
    if [[ "$pattern" == */ ]]; then
        echo "./$pattern* -prune -o -path './$pattern' -prune -o"
    else
        echo "-path './$pattern' -prune -o"
    fi
}

# Function to build find command exclusions
build_find_exclusions() {
    local exclusions=""
    
    # Process .gitignore patterns
    if [ -f .gitignore ]; then
        while IFS= read -r pattern; do
            # Skip empty lines and comments
            [[ "$pattern" =~ ^#.*$ || -z "$pattern" ]] && continue
            
            # Handle negation patterns (!)
            if [[ "$pattern" == !* ]]; then
                # Negation patterns are not supported in find directly
                continue
            fi
            
            # Convert and add the pattern
            converted_pattern=$(convert_gitignore_pattern "$pattern")
            exclusions="$exclusions $converted_pattern"
            
            # For directories, also exclude their contents
            if [[ -d "$pattern" ]]; then
                exclusions="$exclusions -path './$pattern/*' -prune -o"
            fi
        done < .gitignore
    fi
    
    # Add custom exclude patterns
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        exclusions="$exclusions -path '*/$pattern' -prune -o"
    done
    
    echo "$exclusions"
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

# Clear or create output file
echo "Repository Source Code Contents" > "$OUTPUT_FILE"
echo "Generated on: $(date)" >> "$OUTPUT_FILE"
echo "----------------------------------------" >> "$OUTPUT_FILE"

# Statistics
total_files=0
excluded_libs=0
excluded_binary=0
excluded_config=0
included_files=0

# Build find exclusions
FIND_EXCLUSIONS=$(build_find_exclusions)

# Execute find command with exclusions and process files
eval "find . $FIND_EXCLUSIONS -type f -print0" | while IFS= read -r -d $'\0' path; do
    ((total_files++))
    
    echo "Processing file: $path"
    
    # Check if file matches source code extensions
    if echo "$path" | egrep -i "$SOURCE_EXTENSIONS" >/dev/null; then
        if ! is_binary "$path"; then
            echo "Adding $path to output"
            echo -e "\nFile: $path" >> "$OUTPUT_FILE"
            echo "----------------------------------------" >> "$OUTPUT_FILE"
            cat "$path" >> "$OUTPUT_FILE"
            echo -e "\n----------------------------------------" >> "$OUTPUT_FILE"
            ((included_files++))
        else
            echo "Skipping binary file: $path"
            ((excluded_binary++))
        fi
    else
        echo "Skipping file with non-matching extension: $path"
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