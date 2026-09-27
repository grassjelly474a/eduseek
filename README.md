# EduSeek
A webapp to help students find learning material.

## How to run the app.

The client-side uses the Elm programming language. Check out https://elm-lang.org/ to see how to install Elm on your machine.

Once Elm is installed, run ```elm reactor``` to run an interactive development server.
```bash
cd client
elm reactor
```

Or alternatively, build the entire app into a single ```index.html``` file.
```bash
cd client
elm make src/Main.elm --output=index.html
```

The server-side uses the Go programming language. Check out https://go.dev/ to see how to install Go on your machine.

Once Go is installed, run this command to host the database server.
```bash
cd server
go run --tags fts5 src/main.go
```