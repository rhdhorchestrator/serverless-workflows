# Backstage Token workflow
This workflow can be used to test Identity Token Propagation from RHDH to workflows.
This workflow will make a simple API call for a catalog resource that requires an authentication token.
Upon success, the X-Authorization-Backstage Header will be passed alongside the workflow trigger, and will be propagatied to sonataflow. That token will be used to access the Backstage API and access the catalog resource. 

Please configure the BACKSTAGE_URL enviroment variable, that is used in the application properties.
`quarkus.rest-client.backstage_api_yaml.url=${BACKSTAGE_URL}`
This will route the API call used by the workflow to the RHDH route, in order to reach the catalog. 

Please note that the API spec will require the prefix /api/catalog for it's paths.
