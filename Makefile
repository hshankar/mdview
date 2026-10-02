PREFIX ?= /usr/local
DESTDIR ?=
CONFIGURATION ?= release
APPDIR ?= $(HOME)/Applications
APP_BUNDLE ?= $(CURDIR)/.build/MDView.app
.PHONY: build test icon app install uninstall clean

build:
	swift build -c $(CONFIGURATION)

test:
	swift test

icon:
	./scripts/generate-icon.py

app: build
	@bin_path="$$(swift build -c $(CONFIGURATION) --show-bin-path)"; \
	./scripts/create-app-bundle.sh "$$bin_path/mdview" "$(APP_BUNDLE)"

install: build
	@bin_path="$$(swift build -c $(CONFIGURATION) --show-bin-path)"; \
	install -d "$(DESTDIR)$(PREFIX)/bin"; \
	install -m 0755 "$$bin_path/mdview" "$(DESTDIR)$(PREFIX)/bin/mdview"; \
	rm -f "$(DESTDIR)$(PREFIX)/bin/mdview-update"; \
	rm -rf "$(DESTDIR)$(PREFIX)/bin/mdview_MDView.bundle"; \
	cp -R "$$bin_path/mdview_MDView.bundle" "$(DESTDIR)$(PREFIX)/bin/mdview_MDView.bundle"; \
	./scripts/create-app-bundle.sh \
		"$$bin_path/mdview" \
		"$(DESTDIR)$(APPDIR)/MDView.app" \
		"$(PREFIX)/bin/mdview"; \
	if [ -z "$(DESTDIR)" ]; then \
		/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
			-f "$(APPDIR)/MDView.app"; \
	fi; \
	echo "Installed mdview to $(DESTDIR)$(PREFIX)/bin/mdview"; \
	echo "Installed MDView.app to $(DESTDIR)$(APPDIR)/MDView.app"

uninstall:
	@if [ -z "$(DESTDIR)" ] && [ -d "$(APPDIR)/MDView.app" ]; then \
		/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
			-u "$(APPDIR)/MDView.app"; \
	fi
	rm -f "$(DESTDIR)$(PREFIX)/bin/mdview"
	rm -f "$(DESTDIR)$(PREFIX)/bin/mdview-update"
	rm -rf "$(DESTDIR)$(PREFIX)/bin/mdview_MDView.bundle"
	rm -rf "$(DESTDIR)$(APPDIR)/MDView.app"

clean:
	swift package clean
