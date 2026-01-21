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

echo -e "${BLUE}=== PLAI Maker Auto-Archive & Commit Tool ===${NC}"
echo "Detecting uncommitted changes in $PROMPTS_DIR..."
echo ""

# 1. Detect modified files in prompts/
# ' M' means modified in track, 'M ' means staged
modified_files=$(git status --porcelain "$PROMPTS_DIR" | grep -E '^ M|^M ' | awk '{print $NF}')

if [ -z "$modified_files" ]; then
    echo -e "${YELLOW}No modified files detected in $PROMPTS_DIR.${NC}"
    exit 0
fi

echo -e "Found modified files:"
echo "$modified_files"
echo ""

for selected_file in $modified_files; do
    echo -e "${BLUE}Processing:${NC} $selected_file"
    
    # 2. Verify file is tracked (to get original content)
    if ! git ls-files --error-unmatch "$selected_file" > /dev/null 2>&1; then
        echo -e "${YELLOW}Skipping $selected_file (not tracked by git, cannot extract original version)${NC}"
        continue
    fi

    # 3. Get Version Info from user
    display_name=${selected_file#$PROMPTS_DIR/}
    echo -e "Describe changes for ${YELLOW}$display_name${NC}:"
    read -p "Description: " description
    description=$(echo "$description" | tr ' ' '_' | tr -cd '[:alnum:]_-')

    if [ -z "$description" ]; then
        description="updated"
    fi

    # 4. Determine path and version
    relative_path="${selected_file#$PROMPTS_DIR/}"
    target_dir="$LEGACY_DIR/$(dirname "$relative_path")"
    mkdir -p "$target_dir"
    
    # Calculate next version
    existing_backups=($(find "$target_dir" -name "*_v*_"* 2>/dev/null | sort))
    next_v=1
    max_v=0
    if [ ${#existing_backups[@]} -gt 0 ]; then
        for backup in "${existing_backups[@]}"; do
            if [[ "$backup" =~ _v([0-9]+)_ ]]; then
                ver="${BASH_REMATCH[1]}"
                if [ "$ver" -gt "$max_v" ]; then max_v=$ver; fi
            fi
        done
        next_v=$((max_v + 1))
    fi

    # 5. Extract "Original" (last committed) version
    timestamp=$(date +"%Y%m%d")
    new_filename="${timestamp}_v${next_v}_${description}.md"
    destination="$target_dir/$new_filename"
    
    echo "Archiving committed version to: $destination"
    git show HEAD:"$selected_file" > "$destination" 2>/dev/null
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to extract original version from git.${NC}"
        continue
    fi

    # 6. Git Add and Commit
    echo "Staging and Committing..."
    git add "$selected_file" "$destination"
    git commit -m "Update prompt: $display_name ($description) - archived as v$next_v"
    
    echo -e "${GREEN}Finished processing $display_name${NC}"
    echo "-------------------------------------------"
done

echo -e "${GREEN}All detected changes have been archived and committed.${NC}"
