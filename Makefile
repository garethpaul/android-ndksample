.PHONY: build check lint test verify

ANDROID_HOME ?=
ANDROID_SDK_ROOT ?=
override ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
ANDROID_SDK := $(if $(ANDROID_HOME),$(ANDROID_HOME),$(ANDROID_SDK_ROOT))
ANDROID_LINT_TOOL ?= $(ANDROID_SDK)/tools/bin/lint
NDK_BUILD ?= ndk-build

lint:
	$(ROOT)scripts/check-baseline.sh
	@if [ -n "$(ANDROID_SDK)" ] && [ -x "$(ANDROID_LINT_TOOL)" ]; then \
		cd $(ROOT) && ANDROID_HOME="$(ANDROID_SDK)" ANDROID_SDK_ROOT="$(ANDROID_SDK)" "$(ANDROID_LINT_TOOL)" --exitcode .; \
	else \
		echo "Android SDK not configured; legacy lint skipped."; \
	fi

test:
	$(ROOT)scripts/check-baseline.sh
	$(ROOT)scripts/check-native-library-elf.sh
	$(ROOT)scripts/test-native-library-elf.sh
	$(ROOT)scripts/test-native-size-guards.sh
	$(ROOT)scripts/test-demo-timeline.sh
	$(ROOT)scripts/test-importgl-ownership.sh
	$(ROOT)scripts/test-native-sanitizers.sh
	$(ROOT)scripts/test-native-review-mutations.sh

build:
	@if command -v "$(NDK_BUILD)" >/dev/null 2>&1; then \
		cd $(ROOT) && "$(NDK_BUILD)"; \
	else \
		echo "ndk-build unavailable; skipping legacy native rebuild"; \
	fi

verify: lint test build

check: verify
