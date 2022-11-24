# Recipes for this Makefile

## Build everything
##   $ make CRYSTAL_VERSION=0.xx.y PREVIOUS_CRYSTAL_RELEASE_LINUX64_TARGZ=...
## Build just 64bit distribution packages
##   $ make package64 CRYSTAL_VERSION=0.xx.y PREVIOUS_CRYSTAL_RELEASE_LINUX64_TARGZ=...
## Build everything for final release
##   $ make clean all no_cache=true pull_images=true release=true CRYSTAL_VERSION=0.xx.y PREVIOUS_CRYSTAL_RELEASE_LINUX64_TARGZ=...

no_cache ?=     ## Disable the docker build cache
pull_images ?= ## Always pull docker images to ensure they're up to date
release ?=     ## Create an optimized build for the final release

CRYSTAL_VERSION ?=                 ## How the binaries should be branded
CRYSTAL_SHA1 ?= $(CRYSTAL_VERSION) ## Git tag/branch/sha1 to checkout and build source
PACKAGE_ITERATION ?= 1

PREVIOUS_CRYSTAL_VERSION ?= ## Version of the bootstrap compiler
PREVIOUS_CRYSTAL_PACKAGE_ITERATION ?= 1## Package iteration of the bootstrap compiler
PREVIOUS_CRYSTAL_RELEASE_LINUX64_TARGZ ?= https://github.com/crystal-lang/crystal/releases/download/$(PREVIOUS_CRYSTAL_VERSION)/crystal-$(PREVIOUS_CRYSTAL_VERSION)-$(PREVIOUS_CRYSTAL_PACKAGE_ITERATION)-linux-x86_64.tar.gz ## url to crystal-{version}-{package}-linux-x86_64.tar.gz

SHARDS_VERSION = v0.17.1
GC_VERSION = v8.2.2
LIBPCRE_VERSION = 8.45
LIBEVENT_VERSION = release-2.1.12-stable

OUTPUT_DIR = build
OUTPUT_BASENAME64 = $(OUTPUT_DIR)/crystal-$(CRYSTAL_VERSION)-$(PACKAGE_ITERATION)-linux-aarch64

DOCKER_BUILD_ARGS = $(if $(no_cache),--no-cache )$(if $(pull_images),--pull )

BUILD_ARGS_COMMON = $(DOCKER_BUILD_ARGS) \
                    $(if $(release),--build-arg release=true) \
                    --build-arg crystal_version=$(CRYSTAL_VERSION) \
                    --build-arg crystal_sha1=$(CRYSTAL_SHA1) \
                    --build-arg gc_version=$(GC_VERSION) \
                    --build-arg package_iteration=$(PACKAGE_ITERATION)

BUILD_ARGS64 = $(BUILD_ARGS_COMMON)

.PHONY: all
all: all64 ## Build all distribution tarballs [default]

.PHONY: all64
all64: compress64 ## Build distribution tarballs for 64 bits

.PHONY: build
build: $(OUTPUT_BASENAME64).tar ## Build the raw uncompressed tarball

$(OUTPUT_BASENAME64).tar: Dockerfile
	mkdir -p $(OUTPUT_DIR)
	docker build $(BUILD_ARGS64) --platform=linux/arm64 --output="type=docker,name=cry2:latest" --tag crystal-build-temp2 .
	container_id="$$(docker create crystal-build-temp2)" \
	  && docker cp "$$container_id":/output/crystal-$(CRYSTAL_VERSION)-$(PACKAGE_ITERATION).tar $@ \
	  && docker rm -v "$$container_id"

.PHONY: compress64
compress64: $(OUTPUT_BASENAME64).tar.gz $(OUTPUT_BASENAME64).tar.xz ## Build compressed tarballs

$(OUTPUT_DIR)/%.gz: $(OUTPUT_DIR)/%
	gzip -c $< > $@

$(OUTPUT_DIR)/%.xz: $(OUTPUT_DIR)/%
	xz -T 0 -c $< > $@

# .PHONY: clean
# clean: ## Clean up build directory
# 	rm -Rf $(OUTPUT_DIR)
