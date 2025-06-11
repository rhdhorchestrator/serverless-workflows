# Slack interacting workflow

This workflow sends a message to a public channel in slack. e.g. of public channels: #general or #random.

## Prerequisites
* An existing workspace in slack.
* An existing Slack App and Bot Token with the correct scopes.
* Ensure the app is invited to the public channel.

## Running the application dev mode
You can run your application in dev mode that enables live coding using:

```shell script
mvn compile quarkus:dev
```

## Testing with curl
First, validate the workflows exposed by the application:
```shell script
curl -v -H "Content-Type: application/json" http://localhost:8080/management/processes
```
(house should be included in the returned array)

Following the input schema specifications at [house-schema.json](./src/main/resources/schemas/house-input-schema.json ), run the following to trigger an instance of the workflow.
```shell script
curl -v -X POST -H "Content-Type: application/json" http://localhost:8080/house -d '{"channel": "#random","message": "Your message"}'
```

## Slack Setup Guides 
Follow [slack guide](https://api.slack.com/tutorials/tracks/getting-a-token) on setting up slack app and bot token.