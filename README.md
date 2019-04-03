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
user name and desired Pool ID from the [Red Hat Customer Portal](https://access.redhat.com).

    ./setup-rhel.sh

To build a container, review the file `create-image.sh` and set the
parameters at the top appropriately.  Then run the following script
as `root` to execute the buildah commands to create your image:

    ./create-image.sh

The generated container includes the `tar` command so that you can
use `oc cp` to copy alternative datasets to the container's `/data`
directory.  As an alternative, you can build the smallest container
image with just the executable and a small static dataset using:

    ./create-smallest-image.sh

To see the image that was built, run this command as `root`:

    buildah images

To export as a docker-archive (format equivalent to `docker save`),
do the following as `root`:

    skopeo copy containers-storage:localhost/bus-service:latest docker-archive://$(pwd)/bus-service\@latest.tar
    gzip bus-service\@latest.tar

## Running in OpenShift
The following example works with [minishift](https://developers.redhat.com/products/cdk/download/)
but it can be adapted to other OpenShift 3 environments.  Review
the file `import-imagestream.sh` and adjust the `APP` and `PROJECT`
parameters to match your needs.  The defaults should be fine for
the `bus-service` OCI image.  Next, run the following command to
import the tar.gz image archive:

    ./import-imagestream.sh

This will add a tagged OCI image to the local registry and also add
an imagestream to the `openshift` project.  To create an application,
login as an unprivileged OpenShift user and run the commands:

    oc new-app bus-service
    oc expose svc/bus-service

The `bus-service` looks for a file in the directory `/data/busses.json`.
If none is found, it uses a small default data set.

If you built the image that includes the `tar` command, you can use
a different dataset by overriding the container filesystem location
`/data` with a persistent volume claim.  This project includes a
large `40min_busses.json` file that can be renamed `busses.json`
and placed within the container's overridden `/data` directory.
The following commands work fine on `minishift` but should easily
work in other environments as well:

    oc set volume dc bus-service --add --name=busses-data \
        --type=pvc \
        --claim-name=busses-claim \
        --claim-size=1G \
        --mount-path=/data
    POD_ID=$(oc get pods | grep bus-service | awk 'END{print $1}')
    oc cp data/40min_busses.json $POD_ID:/data/busses.json
    oc delete pod $POD_ID

