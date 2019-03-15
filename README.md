# Lightweight Web Service
This is a very lightweight bus position reporting service.  The
service is seeded from the file `40min_busses.json` but that can
be overridden on the command line using the `-f <filename>` command
line argument.

## Trying it out
To build the service,

    CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' bus.go

The statically linked executable will be called `bus`.

To run the service,

    ./bus

This will create a simple web service listening on http://localhost:8080
that returns a report of all current bus positions as a JSON string
for each HTTP GET request. The current bus positions are updated
every two seconds, based on the timestamps in the underlying position
report data.  At startup, all position report timestamps are adjusted
based on the offset between the earliest report time and the current
time.

To test with a smaller dataset,

    ./bus -f test_sample.json

## Building as a small container
To build a container, review the file `create-image.sh` and set the
parameters at the top appropriately.  Then run the script to execute
the buildah commands to create your image:

    ./create-image.sh

