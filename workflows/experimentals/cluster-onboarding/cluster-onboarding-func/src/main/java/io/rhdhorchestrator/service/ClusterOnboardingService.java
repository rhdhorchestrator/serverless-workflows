package dev.rhdhorchestrator.service;

import io.fabric8.kubernetes.api.model.IntOrString;
import io.fabric8.kubernetes.api.model.Service;
import io.fabric8.kubernetes.api.model.ServiceBuilder;
import io.fabric8.kubernetes.api.model.apps.Deployment;
import io.fabric8.kubernetes.api.model.apps.DeploymentBuilder;
import io.fabric8.kubernetes.client.Config;
import io.fabric8.kubernetes.client.ConfigBuilder;
import io.fabric8.kubernetes.client.KubernetesClient;
import io.fabric8.kubernetes.client.KubernetesClientBuilder;
import io.fabric8.kubernetes.client.KubernetesClientException;
import io.fabric8.openshift.api.model.ProjectRequestBuilder;
import io.fabric8.openshift.api.model.Route;
import io.fabric8.openshift.api.model.RouteBuilder;
import io.fabric8.openshift.api.model.RoutePortBuilder;
import io.fabric8.openshift.api.model.RouteTargetReferenceBuilder;
import io.fabric8.openshift.api.model.TLSConfigBuilder;
import io.fabric8.openshift.client.OpenShiftClient;


import jakarta.enterprise.context.ApplicationScoped;

import java.util.Base64;
import java.util.Collections;
import java.util.Map;

@ApplicationScoped
public class ClusterOnboardingService {
    private static final int CONTAINER_PORT = 8081;

    private static final String DEMO_PORT = "demo-port";

    private static final String NGINX = "nginx";

    public String onboard(String clusterApiUrl, String namespace, String token, String cacert, String image) throws KubernetesClientException {
        token = new String(Base64.getDecoder().decode(token));
        cacert = new String(Base64.getDecoder().decode(cacert));
        Config config = new ConfigBuilder().withMasterUrl(clusterApiUrl).withOauthToken(token).withCaCertData(cacert).build();

        try (KubernetesClient kclient = new KubernetesClientBuilder().withConfig(config).build()) {
            OpenShiftClient client = kclient.adapt(OpenShiftClient.class);

            // Project
            createProject(client, namespace);

            // Deployment
            Deployment deployment = new DeploymentBuilder().withNewMetadata().withName(NGINX).endMetadata()
                    .withNewSpec().withReplicas(1).withNewTemplate().withNewMetadata().addToLabels("app", NGINX)
                    .endMetadata().withNewSpec().addNewContainer().withName(NGINX).withImage(image)
                    .addNewPort().withContainerPort(CONTAINER_PORT).endPort().endContainer().endSpec().endTemplate()
                    .withNewSelector().addToMatchLabels("app", NGINX).endSelector().endSpec().build();
            client.apps().deployments().inNamespace(namespace).resource(deployment).create();

            // Service
            Service service = new ServiceBuilder().withNewMetadata().withName(NGINX).endMetadata().withNewSpec()
                    .withSelector(Collections.singletonMap("app", NGINX)).addNewPort().withName(DEMO_PORT)
                    .withProtocol("TCP").withPort(CONTAINER_PORT).withTargetPort(new IntOrString(CONTAINER_PORT))
                    .endPort().endSpec().build();
            client.services().inNamespace(namespace).resource(service).create();

            // Route
            Route route = new RouteBuilder().withNewMetadata().withName(NGINX).endMetadata().withNewSpec()
                    .withTo(new RouteTargetReferenceBuilder().withKind("Service").withName(NGINX).build())
                    .withTls(new TLSConfigBuilder().withTermination("edge").build())
                    .withPort(new RoutePortBuilder().withTargetPort(new IntOrString(CONTAINER_PORT)).build())
                    .endSpec().build();
            route = client.routes().inNamespace(namespace).resource(route).create();
            return route.getSpec().getHost();
        }
    }

    private void createProject(OpenShiftClient client, String namespace) throws KubernetesClientException {
        try {
            client.projectrequests().create(new ProjectRequestBuilder().withNewMetadata().withName(namespace)
                    .endMetadata().withDescription(namespace).withDisplayName(namespace).build());
        } catch (Exception ignored) {}
    }
}
