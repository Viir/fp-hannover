{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  buildInputs = [
    (pkgs.writers.writeDashBin "build-website" ''
      set -eu

      about=$(mktemp)
      eventTemplate=$(mktemp)
      nextEventTemplate=$(mktemp)
      clean() {
        rm -f "$about"
        rm -f "$eventTemplate"
        rm -f "$nextEventTemplate"
      }
      trap clean EXIT INT TERM

      out="${toString ./.}"/public
      rm -rf "$out"
      mkdir -p "$out"

      events=$(
        find "${toString ./.}"/events -name '*.md' -exec basename '{}' .md \; \
          | sort
      )
      nextEvent=""
      pastEvents=
      futureEvents=
      now=$(date -d $(date +%Y-%m-%d) +%s)
      for event in $events; do
        if test $(date -d $event +%s) -ge $now; then
          if test -z $nextEvent; then
            nextEvent="$event"
          else
            futureEvents="$futureEvents $event"
          fi
        else
          pastEvents="$pastEvents $event"
        fi
      done

      cat >"$about" <<'EOF'
      This is a group for anyone interested in functional programming and related technology.

      We are organizing a monthly meetup to share our current projects and interests, to discuss functional programming in general, and to provide guidance on learning.

      We are currently invested in the following technology, but what we offer changes with who is attending:

      - [Elm](https://elm-lang.org/)
      - [Haskell](https://www.haskell.org/)
      - [Nix/ NixOS](https://nixos.org/)

      Our events will usually be held in German, but we are happy to switch to English!
      EOF

      viewAbout() {
        ${pkgs.pandoc}/bin/pandoc -f markdown -t html "$about"
      }

      cat >"$nextEventTemplate" <<'EOF'
        <h2>
          <span>
            Next Session:
          </span>
          <small>
            $date$, $time$ CET/CEST
          </small>
        </h2>
      EOF

      viewNextSession() {
        ${pkgs.pandoc}/bin/pandoc -f markdown -t html \
          --template "$nextEventTemplate" \
          -V date=$1 \
          "${toString ./.}"/events/$1.md
      }

      cat >"$eventTemplate" <<'EOF'
      <article>
        <h3>
          <small>
            $date$, $time$ CET/CEST
          </small>
          <span>
            $title$
          </span>
        </h3>
        $body$
      </article>
      EOF

      viewEvent() {
        ${pkgs.pandoc}/bin/pandoc -f markdown -t html \
          --template "$eventTemplate" \
          -V date=$1 \
          "${toString ./.}"/events/$1.md
      }

      viewEvents() {
        for event in "$@"; do
          viewEvent $event
        done
      }

      cat > public/index.html <<EOF
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1.0" />
          <link rel="preconnect" href="https://fonts.googleapis.com">
          <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
          <link href="https://fonts.googleapis.com/css2?family=Roboto:ital,wght@0,100;0,300;0,400;0,500;0,700;0,900;1,100;1,300;1,400;1,500;1,700;1,900&display=swap" rel="stylesheet">
          <style type="text/css">
            html {
              font-family: "Roboto", sans-serif;
              color: rgba(0,0,0,0.87);
              background-color: #efefef; }
            * {
              box-sizing: border-box; }
            body {
              max-width: 600px;
              background-color: #fff;
              padding: 10px; }
            h2 span,
            h2 small {
              display: block; }
            article {
              border-radius: 6px;
              border: 1px solid #ccc;
              padding: 10px;
              margin: 10px 0; }
            article h3 small,
            article h3 span {
              display: block;
            }
            article h3 small {
              font-size: 0.875rem; }
            article :first-child {
              margin-top: 0; }
            article :last-child {
              margin-bottom: 0; }
          </style>
        </head>
        <body>
          <main>
            <section>
              <h1>Hannover Functional Programming Meetup</h1>
              $(viewAbout)
            </section>
            <section>
              $(viewNextSession $nextEvent)
              $(viewEvents $nextEvent)
            </section>
            <section>
              <h2>Future Events</h2>
              $(viewEvents $futureEvents)
            </section>
            <section>
              <h2>Past Events</h2>
              $(viewEvents $pastEvents)
            </section>
          </main>
        </body>
      </html>
      EOF
    '')
  ];
}