#!/bin/bash

# Get repository name and set up output file
REPO_NAME=$(basename "$PWD")
OUTPUT_FILE="${REPO_NAME}_repo_digest.txt"

# Define source code file extensions we want to include
SOURCE_EXTENSIONS="\.(py|ipynb|js|jsx|ts|tsx|vue|java|cpp|hpp|c|h|go|rs|rb|php|cs|scala|kt|swift|m|mm|sh|bash|pl|pm|t|less|html|xml|sql|graphql|md|rst|tex|yaml|yml|json|coffee|dart|r|jl|lua|clj|cljs|ex|exs)$"

# Define common patterns to exclude - simplified but maintaining key exclusions
EXCLUDE_PATTERNS=(
    # Version control
    ".git"
    "__pycache__"
    
    # Data and binary files
    "*.csv"
    "*.xlsx"
    "*.json"
    "*.log"
    
    # Build and environment
    "node_modules"
    "docker"
    "venv"
    ".env"
    
    # IDE and editor files
    ".vscode"
    ".idea"
    "*.swp"
)

# Helper function to check if a file is binary
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

# Build the find command arguments with proper pattern handling
build_prune_args() {
    local prune_args=()
    
    # Start with grouping
    prune_args+=( "\\(" )
    
    # Process exclude patterns array with proper quoting
    for pat in "${EXCLUDE_PATTERNS[@]}"; do
        # Add OR operator if not first pattern
        [[ ${#prune_args[@]} -gt 1 ]] && prune_args+=( "-o" )
        
        # Handle wildcards with proper quoting
        if [[ "$pat" == *[*?]* ]]; then
            prune_args+=( "-name" "\"$pat\"" )
        else
            prune_args+=( "-path" "./$pat" )
        fi
    done
    
    # Add patterns from .gitignore if it exists
    if [ -f .gitignore ]; then
        while IFS= read -r pattern; do
            # Skip comments and empty lines
            [[ "$pattern" =~ ^#.*$ || -z "$pattern" ]] && continue

            # Clean up pattern: remove trailing and leading slashes
            pattern="${pattern%/}"
            pattern="${pattern#/}"
            [[ -n "$pattern" ]] || continue

            # Add OR operator
            prune_args+=( "-o" )

            # Handle wildcards in gitignore patterns
            if [[ "$pattern" == *[*?]* ]]; then
                prune_args+=( "-name" "\"$pattern\"" )
            else
                prune_args+=( "-path" "./$pattern" )
            fi
        done < .gitignore
    fi

    
    # Close grouping and add prune
    prune_args+=( "\\)" "-prune" "-o" )
    
    echo "${prune_args[@]}"
}

# Initialize output file
> "$OUTPUT_FILE"
echo "Repository Source Code Contents" >> "$OUTPUT_FILE"
echo "Generated on: $(date)" >> "$OUTPUT_FILE"
echo "----------------------------------------" >> "$OUTPUT_FILE"

# Initialize counters
total_files=0
included_files=0
excluded_binary=0

# Build and execute find command
PRUNE_ARGS=$(build_prune_args)
echo "Generated find command arguments:" >&2
echo "$PRUNE_ARGS" >&2

# Process files
while IFS= read -r -d $'\0' path; do
    ((total_files++))
    echo "Processing: $path"
    
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

# Print summary
echo -e "\nSummary:"
echo "Total files found: $total_files"
echo "Included in output: $included_files"
echo "Skipped binary files: $excluded_binary"
echo "Output: $OUTPUT_FILE"