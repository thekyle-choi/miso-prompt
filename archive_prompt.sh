#!/bin/bash

# Configuration
PROMPTS_DIR="prompts"
LEGACY_DIR="prompts_legacy"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== PLAI Maker Prompt Archiving Tool ===${NC}"
echo "This tool backs up your current prompt to the legacy folder before editing."
echo ""

# 1. Check directories
if [ ! -d "$PROMPTS_DIR" ]; then
    echo -e "${RED}Error: '$PROMPTS_DIR' directory not found!${NC}"
    exit 1
fi

if [ ! -d "$LEGACY_DIR" ]; then
    echo -e "${YELLOW}Creating '$LEGACY_DIR' directory...${NC}"
    mkdir -p "$LEGACY_DIR"
fi

# 2. List prompt files
echo "Select a prompt to archive:"
files=($(find "$PROMPTS_DIR" -name "*.md" | sort))

if [ ${#files[@]} -eq 0 ]; then
    echo -e "${RED}No prompt files found in $PROMPTS_DIR${NC}"
    exit 1
fi

i=1
for file in "${files[@]}"; do
    # Remove prefix for cleaner display
    display_name=${file#$PROMPTS_DIR/}
    echo "[$i] $display_name"
    ((i++))
done

# 3. User Selection
echo ""
read -p "Enter number (1-${#files[@]}): " selection

# Validate selection
if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "${#files[@]}" ]; then
    echo -e "${RED}Invalid selection.${NC}"
    exit 1
fi

# Get selected file
selected_file="${files[$((selection-1))]}"
relative_path="${selected_file#$PROMPTS_DIR/}"
target_dir="$LEGACY_DIR/$(dirname "$relative_path")"
filename="$(basename "$selected_file")"

echo -e "${GREEN}Selected:${NC} $relative_path"

# 4. Get Version Info
echo ""
read -p "Enter version description (e.g., 'add_retry_logic', 'fix_tone'): " description

# Sanitize description (replace spaces with underscores, remove special chars)
description=$(echo "$description" | tr ' ' '_' | tr -cd '[:alnum:]_-')

if [ -z "$description" ]; then
    echo -e "${RED}Description cannot be empty.${NC}"
    exit 1
fi

# 5. Determine next version number
# Find existing legacy files for this node
mkdir -p "$target_dir"
existing_backups=($(find "$target_dir" -name "*_v*_"* | sort))
next_v=1

if [ ${#existing_backups[@]} -gt 0 ]; then
    # Extract version numbers and find max
    max_v=0
    for backup in "${existing_backups[@]}"; do
        # Extract v{N} part
        if [[ "$backup" =~ _v([0-9]+)_ ]]; then
            ver="${BASH_REMATCH[1]}"
            if [ "$ver" -gt "$max_v" ]; then
                max_v=$ver
            fi
        fi
    done
    next_v=$((max_v + 1))
fi

# 6. Archive
timestamp=$(date +"%Y%m%d")
new_filename="${timestamp}_v${next_v}_${description}.md"
destination="$target_dir/$new_filename"

echo ""
echo "Archiving to: $destination"
cp "$selected_file" "$destination"

if [ $? -eq 0 ]; then
    echo -e "${BLUE}Success!${NC} File archived."
    echo "Now you can safely edit: $selected_file"
else
    echo -e "${RED}Error: Failed to copy file.${NC}"
    exit 1
fi
