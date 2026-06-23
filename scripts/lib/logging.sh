#!/bin/bash

log_timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

log_info() {
  echo "[$(log_timestamp)] [INFO] $*"
}

log_success() {
  echo "[$(log_timestamp)] [SUCCESS] $*"
}

log_warning() {
  echo "[$(log_timestamp)] [WARNING] $*" >&2
}

log_error() {
  echo "[$(log_timestamp)] [ERROR] $*" >&2
}