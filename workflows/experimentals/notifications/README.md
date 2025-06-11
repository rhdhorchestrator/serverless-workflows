# Notifications workflow example
This workflow demonstrates creating a notification via the core backstage notifications plugin
The token for authenticating to backstage is stored in `application.properties`
NOTE!! this is not the notifications plugin from janus-idp/backstage-plugins

## Prerequisite
start a backstage backend instance
* clone https://github.com/backstage/backstage.git
* edit app-config.yaml `backend.auth` section. add the following:
  ```yaml
  externalAccess:
      - type: static
        options:
          token: lBb9+r50NUNYxKicBZob0NjespLBAb9C
          subject: admin-curl-access
  ```
* start backstage backend: `yarn install; yarn start-backend:next`


## How to run

```bash
mvn clean quarkus:dev
```

Example of POST to trigger the flow:
```bash
curl -X POST -H "Content-Type: application/json" http://localhost:8080/notifications
```

The response will include the created notification
