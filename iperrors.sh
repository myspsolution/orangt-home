#!/bin/bash

grep -Ei 'SSL_do_handshake|access forbidden by rule|SSL routines|client denied' /var/log/nginx/*error.log | grep -oP 'client: \K[\d\.]+' | sort | uniq -c | awk '{print $2, $1}' | sort
