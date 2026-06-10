.PHONY: build check lint test verify

ANDROID_HOME ?=
ANDROID_SDK_ROOT ?= $(ANDROID_HOME)
ANDROID_LINT_TOOL ?= $(ANDROID_HOME)/tools/bin/lint
NDK_BUILD ?= ndk-build

lint:
	scripts/check-baseline.sh
	@if [ -n "$(ANDROID_HOME)" ] && [ -x "$(ANDROID_LINT_TOOL)" ]; then \
		ANDROID_HOME="$(ANDROID_HOME)" ANDROID_SDK_ROOT="$(ANDROID_SDK_ROOT)" "$(ANDROID_LINT_TOOL)" --exitcode .; \
	else \
		echo "Android SDK not configured; legacy lint skipped."; \
	fi

test:
	scripts/check-baseline.sh

build:
	@if command -v "$(NDK_BUILD)" >/dev/null 2>&1; then \
		"$(NDK_BUILD)"; \
	else \
		echo "ndk-build unavailable; skipping legacy native rebuild"; \
	fi

verify: lint test build

check: verify
