#!/usr/bin/env bash
# Generates the native platform folders and installs dependencies.
# Requires: Flutter 3.27 or newer.
set -euo pipefail
cd "$(dirname "$0")/../frontend"

flutter create --project-name plant_care --org com.plantcare --platforms=android,ios,web .
rm -f test/widget_test.dart      # the generated sample test refers to a widget that does not exist here
flutter pub get
echo "Frontend ready. Run: cd frontend && flutter run   (see README for the API URL per target)"
