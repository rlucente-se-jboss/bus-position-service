# Lightweight Web Service
This is a very lightweight bus position reporting service.  The
service is seeded from a JSON file of bus reports which can be
overridden on the command line using the `-f <filename>` command
line argument.

## Trying it out
To build the service locally,

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

## Building as a small container
Do a minimal install of RHEL 7.6+ and then run the following script
as root to enable building containers via the CRI-O tools.  Be sure
to edit the `RHSM_USER` and `POOL` parameters to match your registered
user name and desired Pool ID from the [Red Hat Customer
Portal](https://access.redhat.com).

    ./setup-rhel.sh

To build a container, review the file `create-image.sh` and set the
parameters at the top appropriately.  Then run the following script
as root to execute the buildah commands to create your image:

    ./create-image.sh

To see the image that was built, run this command as root:

    buildah images

## Running in OpenShift
TODO

