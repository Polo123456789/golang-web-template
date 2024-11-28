Golang Web Quickstart Template
==============================

By me, for me. But you can use it too, because its too boring to write the same
code over and over again.

It uses:

* Sqlite3 + Goose for migrations + SQLc to reduce boilerplate
* Templ for HTML templates
* The default net/http package for routing

## How to use

1. Run `./quickstart.sh` to rename the project to your project name
2. Create your database with `make migration/create` and `make migration/up`.
   Connect it in your main function.
3. Run `make run` to start the server, or `make run/live` to start the server
   with live reload.
4. Follow your prefered paradigms to build your web app.
5. Profit!
