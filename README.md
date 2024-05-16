# customer-demo

This repo is useful to test the deployment of some IntegrationRuntime.

It contains:

 * **deploy-server-ping.sh**: A script that deploys an IntegrationRuntime that references a remote BAR file stored in this github repo
 * **Containerfile**: A file used to build a custom ACE image that has a BAR file baked in
 * **deploy-baking-image.sh**: A script that deploys an IntegrationRuntime that uses a custom ACE image with a BAR file baked in (the actual image is built using the `Containerfile` above)
 * **configure-registry.sh**: A script that creates a storage area for the cluster's internal image registry and exposes it, useful to store the custom ACE images we build.
 * **bars/ serverPing.bar**: A sample ACE bar that just answers a get with a simple json containing the flow name and the date.

More details on each file below:
 
## Containerfile

 * Line 1 won't change, we are using IBM's ACE image as a base
 * Line 3 defines a variable `BARNAME` which can be edited to chose another bar file from the `bars` directory
 * Line 9 just copies the bar above to a specific directory in the ACE image so that it's deployed at runtime.

## configure-registry.sh

Run that script just one time to get your image registry setup and exposed

