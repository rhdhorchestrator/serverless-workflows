package io.rhdhorchestrator;

import io.quarkus.funqy.knative.events.CloudEvent;
import io.quarkus.funqy.knative.events.CloudEventBuilder;
import org.eclipse.microprofile.config.ConfigProvider;

import java.time.OffsetDateTime;
import java.util.Map;
import java.util.UUID;

public class EventGenerator {

  public static final String ERROR_EVENT = ConfigProvider.getConfig().getValue("error.event.name",String.class);

  public static final String CLUSTER_DEPLOY_EVENT = ConfigProvider.getConfig().getValue("transformation-saved.event.name",String.class);

  public static CloudEvent<EventGenerator.EventPOJO> createCloudEvent(String workflowId, EventPOJO data, String eventType, String source) {
    return baseCloudEventBuilder(workflowId, eventType, source)
        .build(data);
  }

  public static CloudEvent<EventGenerator.EventPOJO> createCloudEvent(String workflowId, String eventType, String source) {
    return baseCloudEventBuilder(workflowId, eventType, source)
        .build(new EventPOJO());
  }

  public static CloudEvent<EventGenerator.EventPOJO> createClusterDeployEvent(String workflowId, String appHost, String source) {
    return baseCloudEventBuilder(workflowId, CLUSTER_DEPLOY_EVENT, source)
        .build(new EventPOJO(appHost));
  }

  public static CloudEvent<EventGenerator.EventPOJO> createErrorEvent(String workflowCallerId, String message, String source) {
    return createCloudEvent(workflowCallerId, new EventPOJO().setError(message), ERROR_EVENT, source);
  }
  private static CloudEventBuilder baseCloudEventBuilder(String workflowId, String eventType, String source) {
    return CloudEventBuilder.create()
        .id(UUID.randomUUID().toString())
        .source(source)
        .type(eventType)
        .time(OffsetDateTime.now())
        .extensions(Map.of("kogitoprocrefid", workflowId));
  }


  public static class EventPOJO {
    public String error;
    public String message;

    public EventPOJO() {
    }

    public EventPOJO(String message) {
      this.message = message;
    }

    public EventPOJO setError(String error) {
      this.error = error;
      return this;
    }

    public EventPOJO setMessage(String message) {
      this.message = message;
      return this;
    }
  }
}
