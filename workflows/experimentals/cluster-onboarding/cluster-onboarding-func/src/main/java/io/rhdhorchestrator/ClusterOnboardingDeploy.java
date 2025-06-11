package io.rhdhorchestrator;


import io.rhdhorchestrator.service.ClusterOnboardingService;
import io.quarkus.funqy.Funq;
import io.quarkus.funqy.knative.events.CloudEvent;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@ApplicationScoped
public class ClusterOnboardingDeploy {
    private static final Logger log = LoggerFactory.getLogger(ClusterOnboardingDeploy.class);

    public static final String SOURCE = "ClusterOnboardingWF";


    @Inject
    ClusterOnboardingService clusterOnboardingService;


    @Funq("onboardingDeploy")
    public CloudEvent<EventGenerator.EventPOJO> onboardingDeploy(FunInput input) {
        if (!input.validate()) {
            log.error("One or multiple mandatory input field was missing; input: {}", input);
            return EventGenerator.createErrorEvent(input.workflowCallerId, String.format("One or multiple mandatory input field was missing; input: %s", input),
                    SOURCE);
        }

        String appHost;
        try {
            appHost = clusterOnboardingService.onboard(input.clusterApiUrl, input.namespace, input.token, input.cacert, input.image);
        } catch (Exception e) {
            log.error("Error while retrieving cluster onboarding", e);
            return EventGenerator.createErrorEvent(input.workflowCallerId, "Cannot get cluster onboarding output", SOURCE);
        }

        var event = EventGenerator.createClusterDeployEvent(input.workflowCallerId, appHost, SOURCE);
        log.info("Sending cloud event {} to workflow {}", event, input.workflowCallerId);
        return event;
    }

    public static class FunInput {
        public String workflowCallerId;
        public String token;
        public String cacert;
        public String namespace;
        public String clusterApiUrl;
        public String image;


        public boolean validate() {
            return !((token == null || token.isBlank()) ||
                    (cacert == null || cacert.isBlank()) ||
                    (namespace == null || namespace.isBlank()) ||
                    (clusterApiUrl == null || clusterApiUrl.isBlank()) ||
                    (image == null || image.isBlank()) ||
                    (workflowCallerId == null || workflowCallerId.isBlank()));
        }
    }

}
