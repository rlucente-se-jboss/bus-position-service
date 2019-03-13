# Lightweight Web Service
This is a very lightweight bus position reporting service.  The
service is seeded from the file `40min_busses.json` but that can
be overridden on the command line using the `-f <filename>` command
line argument.

To build the service,

    go build bus.go

The executable will be called `bus`.

To run the service,

    ./bus

This will create a simple web service listening on http://localhost:8080
that returns a report of all current bus positions as a JSON string
for each HTTP GET request. The current bus positions are updated
every two seconds, based on the timestamps in the underlying position
report data.  At startup, all position report timestamps are adjusted
based on the offset between the earliest report time and the current
time.

## TODO
Package inside scratch image using CRI-O.
