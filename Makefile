PREFIX ?= /usr/local
DESTDIR ?=
CONFIGURATION ?= release

.PHONY: build test install uninstall clean

build:
	swift build -c $(CONFIGURATION)

test:
	swift test

install: build
	@bin_path="$$(swift build -c $(CONFIGURATION) --show-bin-path)"; \
	install -d "$(DESTDIR)$(PREFIX)/bin"; \
	install -m 0755 "$$bin_path/mdview" "$(DESTDIR)$(PREFIX)/bin/mdview"; \
	rm -rf "$(DESTDIR)$(PREFIX)/bin/mdview_MDView.bundle"; \
	cp -R "$$bin_path/mdview_MDView.bundle" "$(DESTDIR)$(PREFIX)/bin/mdview_MDView.bundle"; \
	echo "Installed mdview to $(DESTDIR)$(PREFIX)/bin/mdview"

uninstall:
	rm -f "$(DESTDIR)$(PREFIX)/bin/mdview"
	rm -rf "$(DESTDIR)$(PREFIX)/bin/mdview_MDView.bundle"

clean:
	swift package clean
