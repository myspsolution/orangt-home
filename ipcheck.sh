#!/bin/bash

grep -hEo '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' /var/log/nginx/*.access.log | grep -v '^127\.0\.0\.1$' | sort | uniq -c | awk '$1 > 99' | sort -nr
