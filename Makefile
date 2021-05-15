NODE_REPO="https://github.com/input-output-hk/cardano-node.git"
NODE_BRANCH="master"

amd64:
	docker build \
		--platform linux/amd64 \
		--build-arg NODE_REPO=${NODE_REPO} \
		--build-arg NODE_VERSION=${NODE_VERSION} \
		--build-arg NODE_BRANCH=${NODE_BRANCH} \
		--no-cache \
		--pull \
        -t "adalove/cardano-node:u${NODE_VERSION}_amd64" .
	docker push "adalove/cardano-node:u${NODE_VERSION}_amd64"

arm64:
	docker build \
		--platform linux/arm64/v8 \
		--build-arg NODE_REPO=${NODE_REPO} \
		--build-arg NODE_VERSION=${NODE_VERSION} \
		--build-arg NODE_BRANCH=${NODE_BRANCH} \
		--no-cache \
		--pull \
        -t "adalove/cardano-node:u${NODE_VERSION}_arm64" .
	docker push "adalove/cardano-node:u${NODE_VERSION}_arm64"

manifest:
	docker manifest create "adalove/cardano-node:u${NODE_VERSION}" \
		"adalove/cardano-node:u${NODE_VERSION}_amd64" \
		"adalove/cardano-node:u${NODE_VERSION}_arm64"
	docker manifest push --purge "adalove/cardano-node:u${NODE_VERSION}"

all: amd64 arm64 manifest
