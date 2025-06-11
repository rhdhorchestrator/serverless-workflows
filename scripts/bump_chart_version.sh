#!/bin/bash

# Check if workflow ID parameter and at least one version bump flag are provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <workflow_id> <flag>"
    echo "Flags:"
    echo "  --bump-minor-version       : Bump minor version and set patch to 0"
    echo "  --bump-major-version       : Bump major version"
    echo "  --bump-patch-version       : Bump patch version"
    echo "  --bump-tag-version         : Bump tag version"
    echo "  --bump-minor-app-version   : Bump minor app version and set patch to 0"
    echo "  --bump-major-app-version   : Bump major app version"
    echo "  --bump-patch-app-version   : Bump patch app version"
    echo "  --release                  : Release the chart, hence removing the tag from the version"
    exit 1
fi

# Get the workflow ID and flags
WORKFLOW_ID="$1"
shift
FLAGS=("$@")

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Check if the directory exists in the charts directory
CHART_DIR="${SCRIPT_DIR}/../charts/${WORKFLOW_ID}"
if [ ! -d "$CHART_DIR" ]; then
    echo "Error: Directory '${WORKFLOW_ID}' not found in charts directory."
    exit 1
fi

# File path to the YAML template relative to the script's directory
CHART_FILE="${CHART_DIR}/Chart.yaml"

VERSION="version:"
APP_VERSION="appVersion:"

# Function to bump the version
bump_version() {
    local line_name="$1"
    local increment_type="$2"
    local should_release="$3"
    local version_line=$(grep "^${line_name}" "${CHART_FILE}")
    local current_version=$(echo "${version_line}" | awk '{print $2}')
    local major=$(echo "${current_version}" | cut -d '.' -f1)
    local minor=$(echo "${current_version}" | cut -d '.' -f2)
    local patch=$(echo "${current_version}" | cut -d '.' -f3 | awk -F-rc '{ print $1 }')
    local tag=$(echo "${current_version}" | awk -F-rc '{ print $2 }')
    
    case "${increment_type}" in
        minor)
            ((minor++))
            patch=0  # Reset patch version to 0 after bumping minor version
            tag=0
            ;;
        major)
            ((major++))
            minor=0
            patch=0
            tag=0
            ;;
        patch)
            ((patch++))
            tag=0
            ;;
        tag)
            ((tag++))
            ;;
        *)
            echo "Invalid increment type"
            exit 1
            ;;
    esac

    if [ "$line_name" = "${VERSION}" ]; then 
        if $should_release; then
            new_version="${major}.${minor}.${patch}"
        else
            new_version="${major}.${minor}.${patch}-rc${tag}"
        fi
    else
        new_version="${major}.${minor}.${patch}"
    fi

    sed -i "s/^${line_name} .*$/${line_name} ${new_version}/" "${CHART_FILE}"
}

# Check if at least one version bump flag is provided
has_version_bump_flag=false
for flag in "${FLAGS[@]}"; do
    case "$flag" in
        --bump-minor-version|--bump-major-version|--bump-patch-version|--bump-tag-version|--bump-minor-app-version|--bump-major-app-version|--bump-patch-app-version|--release)
            has_version_bump_flag=true
            ;;
        *)
            echo "Error: Invalid flag: $flag"
            exit 1
            ;;
    esac
done

if ! $has_version_bump_flag; then
    echo "Error: At least one version bump flag is required."
    exit 1
fi

should_release=false
for flag in "${FLAGS[@]}"; do
    case "$flag" in
            --release)
                should_release=true
                ;;
    esac
done

# Parse flags and bump versions accordingly
for flag in "${FLAGS[@]}"; do
    case "$flag" in
        --bump-minor-version)
            bump_version "${VERSION}" "minor" ${should_release}
            ;;
        --bump-major-version)
            bump_version "${VERSION}" "major" ${should_release}
            ;;
        --bump-patch-version)
            bump_version "${VERSION}" "patch" ${should_release}
            ;;
        --bump-tag-version)
            bump_version "${VERSION}" "tag" ${should_release}
            ;;
        --bump-minor-app-version)
            bump_version "${APP_VERSION}" "minor" false
            ;;
        --bump-major-app-version)
            bump_version "${APP_VERSION}" "major" false
            ;;
        --bump-patch-app-version)
            bump_version "${APP_VERSION}" "patch" false
            ;;
    esac
done
