# Le préfixe ">" remplace la tabulation : le copier-coller ne casse rien.
.RECIPEPREFIX = >
PREFIX ?= $(HOME)/.local
BINDIR := $(PREFIX)/bin

.PHONY: help install uninstall test lint
help:
> @echo "make install    → $(BINDIR)/orm-pack"
> @echo "make uninstall  → supprime le binaire"
> @echo "make test       → tests de fumée"
> @echo "make lint       → shellcheck + bash -n"

install:
> install -d $(BINDIR)
> install -m 755 orm-pack.sh $(BINDIR)/orm-pack
> @echo "✔ $(BINDIR)/orm-pack"

uninstall:
> rm -f $(BINDIR)/orm-pack

test:
> bash tests/smoke.sh

lint:
> shellcheck -S warning orm-pack.sh tests/smoke.sh install.sh
> bash -n orm-pack.sh
