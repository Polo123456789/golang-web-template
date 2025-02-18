#!/bin/bash

read -p "App's name: " name
read -p "Golang Module name: " module

for f in ./go.mod ./tools/go.mod ./cmd/app-name/main.go ./internal/http/routes.go; do
	sed -i "s|github.com/Polo123456789/golang-web-template|$module|g" "$f"
done

mv cmd/app-name cmd/"$name"
sed -i "s/app-name/$name/g" makefile

make install-tools

mkdir db/migrations db/sqlc internal/core -p

echo "Done!"
echo "Run 'make run' to start the app. Update the README.md file with your app's information."

rm quickstart.sh

git add .
git commit -m "Quickstart setup for $name"
