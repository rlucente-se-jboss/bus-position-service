# Lightweight Web Service
This is a very lightweight bus position reporting service.  The
service is seeded from the file `40min_busses.json` but that can
be overridden on the command line using the `-f <filename>` command
line argument.

To build the service,

    go build bus.go

The executable will have the name of the folder it's in, which if
you've cloned this repository, will be `bus-position-service`.

To run the service,

    ./bus-position-service

This will create a simple web service listening on port 8080 that
returns a report of all current bus positions as a JSON string for
each HTTP GET request.
