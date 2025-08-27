set -e

VERSION="latest"

echo "Downloading Rover version $VERSION..."
curl -sSL https://rover.apollo.dev/nix/$VERSION | sh
