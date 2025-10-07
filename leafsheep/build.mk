# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

installer:
	@$(MAKE) -C leafsheep/installer installer

package:
	@$(MAKE) -C leafsheep/installer make-archive

l10n-package:
	@$(MAKE) -C leafsheep/installer make-langpack

mozpackage:
	@$(MAKE) -C leafsheep/installer

package-compare:
	@$(MAKE) -C leafsheep/installer package-compare

stage-package:
	@$(MAKE) -C leafsheep/installer stage-package make-buildinfo-file

sdk:
	@$(MAKE) -C leafsheep/installer make-sdk

install::
	@$(MAKE) -C leafsheep/installer install

clean::
	@$(MAKE) -C leafsheep/installer clean

distclean::
	@$(MAKE) -C leafsheep/installer distclean

source-package::
	@$(MAKE) -C leafsheep/installer source-package

upload::
	@$(MAKE) -C leafsheep/installer upload

source-upload::
	@$(MAKE) -C leafsheep/installer source-upload

hg-bundle::
	@$(MAKE) -C leafsheep/installer hg-bundle

l10n-check::
	@$(MAKE) -C leafsheep/locales l10n-check

ifdef ENABLE_TESTS
# Implemented in testing/testsuite-targets.mk

mochitest-browser-chrome:
	$(RUN_MOCHITEST) --flavor=browser
	$(CHECK_TEST_ERROR)

mochitest:: mochitest-browser-chrome

.PHONY: mochitest-browser-chrome

endif
