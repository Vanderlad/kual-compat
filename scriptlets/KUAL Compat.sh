#!/bin/sh
# Name: KUAL Compat
# Author: KUAL Compat contributors
#
# Opens the local extension manager in KTerm. No system files are modified.

exec /mnt/us/extensions/kterm/bin/kterm.sh -e "/mnt/us/extensions/kual-compat/bin/manage.sh"
