cdrepo_parse_url() {
    local url="$1"
    local host
    local path

    # <protocol>://[<user>@]<host>[:<port>]/<path-to-git-repo>
    if [[ "$url" =~ '^([A-Za-z0-9_]+)://([A-Za-z0-9_\.\-]+@)?([A-Za-z0-9_\.\-]+)(:[0-9]+)?/([^@:]*)$' ]]; then
        host=${match[3]}
        path=${match[5]}
    # [<user>@]<host>[:<port>]:<path-to-git-repo>
    elif [[ "$url" =~ '^([A-Za-z0-9_\.\-]+@)?([A-Za-z0-9_\.\-]+)(:[0-9]+)?:([^@:]*)$' ]]; then
        host=${match[2]}
        path=${match[4]}
    else
        echo "Invalid URL: unknown format"
        return 1
    fi

    if [[ "/$path" == */.git ]]; then
        echo "Invalid URL: empty repository name"
        return 1
    fi
    path=${path%.git}

    echo "$host/$path"
    return 0
}

# Function to change directory to a Git repository based on the provided URL
cdrepo() {
    # Check if CDREPO_DIR is set
    if [ -z "${CDREPO_DIR}" ]; then
        echo "Error: CDREPO_DIR environment variable is not set."
        echo "Please set CDREPO_DIR to the desired directory where repositories should be cloned."
        return 1
    fi

    # Check if the repo_url argument is provided
    if [ $# -ne 1 ]; then
        echo "Usage: cdrepo <repo_url>"
        return 1
    fi
    local repo_url="$1"

    # Get the local path
    local local_path
    local_path="$(cdrepo_parse_url "$repo_url")"
    if [ $? -ne 0 ] || [ -z "$local_path" ]; then
        echo "Error: Failed to determine local path from the repository URL."
        return 1
    fi
    local_path="${CDREPO_DIR}/${local_path}"

    # Ensure the parent directory of local_path exists
    local parent_dir=$(dirname "$local_path")
    if [ ! -d "$parent_dir" ]; then
        echo "Creating parent directory: $parent_dir"
        mkdir -p "$parent_dir"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to create parent directory: $parent_dir"
            return 1
        fi
    fi

    # Check if the local path exists and is not empty
    if [ ! -d "$local_path" ] || [ -z "$(ls -A "$local_path")" ]; then
        # If the path doesn't exist or is empty, clone the repository
        echo "Cloning repository into: $local_path"
        git clone "$repo_url" "$local_path"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to clone repository into: $local_path"
            return 1
        fi
    fi

    # Change directory to the local path
    cd "$local_path"
}
