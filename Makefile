PREFIX ?= /usr/local
DESTDIR ?=
CONFIGURATION ?= release
VERSION ?= 0.1.0

.PHONY: build test package install uninstall clean

build:
	swift build -c $(CONFIGURATION)

test:
	swift test

package:
	./scripts/package-release.sh "$(VERSION)" dist

install: build
	@bin_path="$$(swift build -c $(CONFIGURATION) --show-bin-path)"; \
	install -d "$(DESTDIR)$(PREFIX)/bin"; \
	install -m 0755 "$$bin_path/mdview" "$(DESTDIR)$(PREFIX)/bin/mdview"; \
	install -m 0755 install.sh "$(DESTDIR)$(PREFIX)/bin/mdview-update"; \
	rm -rf "$(DESTDIR)$(PREFIX)/bin/mdview_MDView.bundle"; \
	cp -R "$$bin_path/mdview_MDView.bundle" "$(DESTDIR)$(PREFIX)/bin/mdview_MDView.bundle"; \
	echo "Installed mdview to $(DESTDIR)$(PREFIX)/bin/mdview"

uninstall:
	rm -f "$(DESTDIR)$(PREFIX)/bin/mdview"
	rm -f "$(DESTDIR)$(PREFIX)/bin/mdview-update"
	rm -rf "$(DESTDIR)$(PREFIX)/bin/mdview_MDView.bundle"

clean:
	swift package clean
