SHELL := /bin/bash

.PHONY: bootstrap status doctor backup restore upgrade apply-config

bootstrap:
	./scripts/bootstrap.sh

status:
	./scripts/status.sh

doctor:
	./scripts/doctor.sh

backup:
	./scripts/backup.sh

restore:
	./scripts/restore.sh

upgrade:
	./scripts/upgrade.sh

apply-config:
	./scripts/apply-config.sh templates/org.sample.json

package-release:
	./scripts/package-release.sh --version $$(cat VERSION) --output releases

release-publish:
	./scripts/package-release.sh --version $$(cat VERSION) --output releases --publish
