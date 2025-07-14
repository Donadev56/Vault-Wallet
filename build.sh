#!/bin/sh
echo "Runing build and publish script...\n"
echo "Formating dart code...\n"
dart format .
echo "Publishing code on Github...\n"
git status && git add . && git commit -m "update" && git push
echo "Code published!\n"
echo "Building Vault-swap...\n"
flutter build apk --no-tree-shake-icons
echo "Build Done!\n"
