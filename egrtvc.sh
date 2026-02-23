#!/bin/bash
set -e  # Exit immediately on error

# 29ff9a (RGB: 41, 255, 154)
MAIN_COLOR="\e[1;38;2;41;255;154m"
GRAY="\e[2;38;2;150;150;150m"
RED="\e[1;31m"
YELLOW="\e[1;33m"
RESET="\e[0m"

# Configuration file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.json"

# Output files (still in script directory)
CURRENT_FILE="${SCRIPT_DIR}/version.json"
OLD_FILES=(
    "${SCRIPT_DIR}/version_old1.json"
    "${SCRIPT_DIR}/version_old2.json"
    "${SCRIPT_DIR}/version_old3.json"
)

# Colors
echo -e "${MAIN_COLOR}===== Easy Git Real Time Version Checker =====${RESET}"
echo -e "${MAIN_COLOR}Support: Gitea${RESET}"
echo -e "${GRAY}Working directory: ${SCRIPT_DIR}${RESET}"
echo -e "${GRAY}Config file: ${CONFIG_FILE}${RESET}"
echo -e "${GRAY}Current time: $(date)${RESET}"
echo -e "${MAIN_COLOR}-------------------------------------------${RESET}"

# Dependency check
echo -e "${MAIN_COLOR}[1/9]${RESET} Checking dependencies..."
if ! command -v curl &>/dev/null; then
    echo -e "   ${RED}ERROR${RESET}: curl is not installed." >&2
    exit 1
fi
echo -e "   ${MAIN_COLOR}OK${RESET}: curl is installed"
if ! command -v jq &>/dev/null; then
    echo -e "   ${RED}ERROR${RESET}: jq is not installed." >&2
    exit 1
fi
echo -e "   ${MAIN_COLOR}OK${RESET}: jq is installed"

# Read configuration
echo -e "${MAIN_COLOR}[2/9]${RESET} Reading configuration..."
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "   ${RED}ERROR${RESET}: Config file not found: $CONFIG_FILE" >&2
    exit 1
fi

# Parse JSON config
API_BASE=$(jq -r '.api_base // ""' "$CONFIG_FILE")
OWNER=$(jq -r '.owner // ""' "$CONFIG_FILE")
REPO=$(jq -r '.repo // ""' "$CONFIG_FILE")
FIELDS_JSON=$(jq -c '.fields // ["masterid","tags","tagsid","release","releaseid"]' "$CONFIG_FILE")

if [[ -z "$API_BASE" || -z "$OWNER" || -z "$REPO" ]]; then
    echo -e "   ${RED}ERROR${RESET}: Missing required fields in config.json (api_base, owner, repo)" >&2
    exit 1
fi

echo -e "   ${MAIN_COLOR}OK${RESET}: Configuration loaded"
echo -e "       ${GRAY}API Base: $API_BASE${RESET}"
echo -e "       ${GRAY}Owner: $OWNER${RESET}"
echo -e "       ${GRAY}Repo: $REPO${RESET}"
echo -e "       ${GRAY}Fields: $FIELDS_JSON${RESET}"
echo -e "${MAIN_COLOR}-------------------------------------------${RESET}"

# Convert fields JSON to a bash array for easy checking
readarray -t FIELDS < <(echo "$FIELDS_JSON" | jq -r '.[]')

# Helper: check if a field is requested
field_requested() {
    local field="$1"
    for f in "${FIELDS[@]}"; do
        if [[ "$f" == "$field" ]]; then
            return 0
        fi
    done
    return 1
}

# API request wrapper: outputs JSON body to stdout, debug/error info to stderr
api_get() {
    local path="$1"
    local url="${API_BASE}${path}"
    echo -e "   ${GRAY}REQUEST: ${url}${RESET}" >&2
    local response
    local http_code
    response=$(curl -s --http2 \
         -H 'User-Agent: curl/8.18.0' \
         -H 'Accept: */*' \
         --connect-timeout 10 \
         -w "\n%{http_code}" \
         "$url")
    local curl_exit=$?
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')  # Remove last line (status code)
    
    if [[ $curl_exit -ne 0 ]]; then
        echo -e "   ${RED}ERROR${RESET}: curl command failed, exit code: $curl_exit" >&2
        return $curl_exit
    fi
    if [[ "$http_code" -ne 200 ]]; then
        echo -e "   ${RED}ERROR${RESET}: HTTP status code $http_code" >&2
        echo -e "       ${GRAY}Response preview: ${body:0:200}${RESET}" >&2
        return 1
    fi
    # Check if response starts with '{' (JSON object) or '[' (JSON array)
    if [[ ! "$body" =~ ^[[:space:]]*\{ ]] && [[ ! "$body" =~ ^[[:space:]]*\[ ]]; then
        echo -e "   ${RED}ERROR${RESET}: Response is not JSON object or array (maybe HTML), first 200 chars:" >&2
        echo -e "${GRAY}${body:0:200}${RESET}" >&2
        return 1
    fi
    # Success, output body (JSON only)
    echo "$body"
}

# Get default branch
echo -e "${MAIN_COLOR}[3/9]${RESET} Fetching default branch..."
get_default_branch() {
    local result
    result=$(api_get "/repos/${OWNER}/${REPO}")
    if [[ $? -ne 0 ]] || [[ -z "$result" ]]; then
        echo -e "   ${YELLOW}WARNING${RESET}: Failed to get default branch, using 'master'" >&2
        echo "master"
        return
    fi
    echo "$result" | jq -r '.default_branch // "master"'
}
branch=$(get_default_branch)
echo -e "   ${MAIN_COLOR}OK${RESET}: Default branch: ${GRAY}${branch}${RESET}"

# Get master branch commit ID (only if requested)
masterid=""
if field_requested "masterid"; then
    echo -e "${MAIN_COLOR}[4/9]${RESET} Fetching master branch commit ID..."
    get_latest_commit_short() {
        local branch="$1"
        local result
        result=$(api_get "/repos/${OWNER}/${REPO}/branches/${branch}")
        if [[ $? -ne 0 ]] || [[ -z "$result" ]]; then
            echo -e "   ${YELLOW}WARNING${RESET}: Failed to get branch info" >&2
            echo ""
            return
        fi
        echo "$result" | jq -r '.commit.id[:10] // ""'
    }
    masterid=$(get_latest_commit_short "$branch")
    if [[ -n "$masterid" ]]; then
        echo -e "   ${MAIN_COLOR}OK${RESET}: Master commit ID: ${GRAY}${masterid}${RESET}"
    else
        echo -e "   ${YELLOW}WARNING${RESET}: Failed to get master commit ID"
    fi
else
    echo -e "${MAIN_COLOR}[4/9]${RESET} Fetching master branch commit ID... ${GRAY}SKIP (not requested)${RESET}"
fi

# Helper: get commit short ID by tag name
get_commit_by_tag() {
    local tag_name="$1"
    if [[ -z "$tag_name" ]]; then
        echo ""
        return
    fi
    local tags_json
    tags_json=$(api_get "/repos/${OWNER}/${REPO}/tags")
    if [[ $? -ne 0 ]] || [[ -z "$tags_json" ]]; then
        echo ""
        return
    fi
    echo "$tags_json" | jq -r --arg tag "$tag_name" '
        .[] | select(.name == $tag) | .commit.sha[:10] // ""'
}

# Get latest tag (name and commit ID) – only if tags or tagsid is requested
tag=""
tag_commit=""
if field_requested "tags" || field_requested "tagsid"; then
    echo -e "${MAIN_COLOR}[5/9]${RESET} Fetching latest tag..."
    get_latest_tag() {
        echo -e "   ${GRAY}Fetching tags...${RESET}" >&2
        local tags_json
        tags_json=$(api_get "/repos/${OWNER}/${REPO}/tags")
        local api_exit=$?
        
        if [[ $api_exit -ne 0 ]]; then
            echo -e "   ${RED}ERROR${RESET} [DEBUG]: api_get failed, exit code: $api_exit" >&2
            echo ""   # placeholder for two lines
            echo ""
            return
        fi
        
        if [[ -z "$tags_json" ]] || [[ "$tags_json" == "null" ]]; then
            echo -e "   ${GRAY}INFO${RESET} [DEBUG]: tags_json is empty or null" >&2
            echo ""
            echo ""
            return
        fi
        
        echo -e "   ${GRAY}Tags API response preview: ${tags_json:0:200}${RESET}" >&2
        
        # Parse latest tag name and commit ID (short)
        local latest_info
        latest_info=$(echo "$tags_json" | jq -r '
            [ .[] | {name: .name, date: .commit.created, sha: .commit.sha[:10]} ] | 
            sort_by(.date) | reverse | 
            .[0] | "\(.name)\n\(.sha)"' 2>&1)
        local jq_exit=$?
        
        if [[ $jq_exit -ne 0 ]]; then
            echo -e "   ${RED}ERROR${RESET} [DEBUG]: jq parsing failed, exit code: $jq_exit, error: $latest_info" >&2
            echo ""
            echo ""
            return
        fi
        
        echo "$latest_info"
    }
    tag_info=$(get_latest_tag)
    tag=$(echo "$tag_info" | head -n1)
    tag_commit=$(echo "$tag_info" | tail -n1)
    if [[ -n "$tag" ]]; then
        echo -e "   ${MAIN_COLOR}OK${RESET}: Latest tag: ${GRAY}${tag}${RESET} (commit: ${GRAY}${tag_commit}${RESET})"
    else
        echo -e "   ${GRAY}INFO: No tag found${RESET}"
    fi
else
    echo -e "${MAIN_COLOR}[5/9]${RESET} Fetching latest tag... ${GRAY}SKIP (not requested)${RESET}"
fi

# Get latest release (tag name and commit ID) – only if release or releaseid is requested
release=""
release_commit=""
if field_requested "release" || field_requested "releaseid"; then
    echo -e "${MAIN_COLOR}[6/9]${RESET} Fetching latest release..."
    get_latest_release() {
        local result
        result=$(api_get "/repos/${OWNER}/${REPO}/releases")
        if [[ $? -ne 0 ]] || [[ -z "$result" ]] || [[ "$result" == "null" ]] || [[ "$result" == "[]" ]]; then
            echo ""
            echo ""
            return
        fi
        # Get tag name of latest release
        local release_tag
        release_tag=$(echo "$result" | jq -r '.[0].tag_name // ""')
        if [[ -z "$release_tag" ]]; then
            echo ""
            echo ""
            return
        fi
        # Get commit ID for that tag
        local commit_id
        commit_id=$(get_commit_by_tag "$release_tag")
        echo "$release_tag"
        echo "$commit_id"
    }
    release_info=$(get_latest_release)
    release=$(echo "$release_info" | head -n1)
    release_commit=$(echo "$release_info" | tail -n1)
    if [[ -n "$release" ]]; then
        echo -e "   ${MAIN_COLOR}OK${RESET}: Latest release: ${GRAY}${release}${RESET} (commit: ${GRAY}${release_commit}${RESET})"
    else
        echo -e "   ${GRAY}INFO: No release found${RESET}"
    fi
else
    echo -e "${MAIN_COLOR}[6/9]${RESET} Fetching latest release... ${GRAY}SKIP (not requested)${RESET}"
fi

# Construct new JSON (only requested fields)
echo -e "${MAIN_COLOR}[7/9]${RESET} Constructing new JSON data..."
# Build a base object with all possible fields, then filter using fields array
all_json=$(jq -n \
    --arg master "$masterid" \
    --arg tags "$tag" \
    --arg tagsid "$tag_commit" \
    --arg release "$release" \
    --arg releaseid "$release_commit" \
    '{masterid: $master, tags: $tags, tagsid: $tagsid, release: $release, releaseid: $releaseid}')

new_json=$(echo "$all_json" | jq --argjson fields "$FIELDS_JSON" 'with_entries(select(.key as $k | $fields | index($k)))')
echo -e "   ${GRAY}New data: $new_json${RESET}"

# Read existing data
echo -e "${MAIN_COLOR}[8/9]${RESET} Checking existing data..."
if [[ -f "$CURRENT_FILE" ]]; then
    current_json=$(cat "$CURRENT_FILE")
    echo -e "   ${GRAY}Current data: $current_json${RESET}"
else
    current_json=""
    echo -e "   ${GRAY}Current data: (none)${RESET}"
fi

# Compare data
if [[ "$current_json" == "$new_json" ]]; then
    echo -e "   ${MAIN_COLOR}OK${RESET}: Data unchanged, keeping existing file."
    echo -e "${MAIN_COLOR}===== DONE ====${RESET}"
    exit 0
fi

# Data changed, rotate files
echo -e "   ${MAIN_COLOR}ROTATING${RESET}: Data changed, rotating files..."
rotate_files() {
    if [[ -f "${OLD_FILES[2]}" ]]; then
        echo -e "       ${GRAY}Deleting oldest: ${OLD_FILES[2]}${RESET}"
        rm -f "${OLD_FILES[2]}"
    fi
    if [[ -f "${OLD_FILES[1]}" ]]; then
        echo -e "       ${GRAY}Moving: ${OLD_FILES[1]} -> ${OLD_FILES[2]}${RESET}"
        mv "${OLD_FILES[1]}" "${OLD_FILES[2]}"
    fi
    if [[ -f "${OLD_FILES[0]}" ]]; then
        echo -e "       ${GRAY}Moving: ${OLD_FILES[0]} -> ${OLD_FILES[1]}${RESET}"
        mv "${OLD_FILES[0]}" "${OLD_FILES[1]}"
    fi
    if [[ -f "$CURRENT_FILE" ]]; then
        echo -e "       ${GRAY}Moving: ${CURRENT_FILE} -> ${OLD_FILES[0]}${RESET}"
        mv "$CURRENT_FILE" "${OLD_FILES[0]}"
    fi
}
rotate_files

# Write new JSON
echo -e "${MAIN_COLOR}[9/9]${RESET} Writing new version.json..."
write_new_json() {
    local new_json="$1"
    local tmp_file="${CURRENT_FILE}.tmp"
    echo "$new_json" > "$tmp_file"
    mv "$tmp_file" "$CURRENT_FILE"
    echo -e "   ${MAIN_COLOR}OK${RESET}: Written to ${GRAY}${CURRENT_FILE}${RESET}"
}
write_new_json "$new_json"

echo -e "${MAIN_COLOR}===== Script finished ====${RESET}"