#!/bin/sh

# exit immediately if rbw is already in $PATH
type rbw >/dev/null 2>&1 && exit

case "$(uname -s)" in
Linux)
    mkdir -pv ~/.local/bin

    # Try installing with cargo first
    if type cargo >/dev/null 2>&1; then
        echo "Installing rbw using cargo..."
        cargo install --locked rbw
        exit 0
    fi

    # Fallback to downloading binary
    echo "Cargo not found, downloading rbw binary..."

    # Determine architecture
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)
            ARCH="x86_64"
            ;;
        *)
            echo "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac

    # Get latest release version
    if type curl >/dev/null 2>&1; then
        RBW_VERSION=$(curl -s https://api.github.com/repos/doy/rbw/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    elif type wget >/dev/null 2>&1; then
        RBW_VERSION=$(wget -qO- https://api.github.com/repos/doy/rbw/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    else
        echo "Neither curl nor wget found. Cannot check latest rbw version."
        exit 1
    fi

    if [ -z "$RBW_VERSION" ]; then
        echo "Failed to get latest rbw version"
        exit 1
    fi

    # Download URL
    URL="https://github.com/doy/rbw/releases/download/${RBW_VERSION}/rbw_${RBW_VERSION}_linux_amd64.tar.gz"

    # Try curl first
    if type curl >/dev/null 2>&1; then
        echo "Downloading rbw using curl..."
        curl -L "$URL" -o /tmp/rbw.tar.gz
    elif type wget >/dev/null 2>&1; then
        echo "Downloading rbw using wget..."
        wget "$URL" -O /tmp/rbw.tar.gz
    else
        echo "Neither curl nor wget found. Cannot download rbw."
        exit 1
    fi

    # Extract and install
    cd /tmp
    tar -xzf rbw.tar.gz
    mv rbw ~/.local/bin/
    mv rbw-agent* ~/.local/bin/
    chmod +x ~/.local/bin/rbw
    chmod +x ~/.local/bin/rbw-agent*
    rm rbw.tar.gz

    echo "rbw installed successfully to ~/.local/bin/rbw"
    ;;
*)
    echo "unsupported OS"
    exit 1
    ;;
esac
