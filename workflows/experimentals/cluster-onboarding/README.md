# Cluster Onboarding workflow
As a user I would like to onboard to my k8s/ocp cluster by creating a namesapce

We can create set of secrets with kubeconfigs in the same namespace where the workflow is deployed and use workflow parameter with the secret name to connect to the right cluster.