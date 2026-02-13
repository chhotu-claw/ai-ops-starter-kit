SHELL := /bin/bash

.PHONY: bootstrap status doctor backup restore upgrade

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
