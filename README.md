# cloudrun-iap-bootstrap

This repository provides everything you need to quickly setup a Google Cloud Platform project with a Cloud Run App secured by the Identity-Aware-Proxy.


Loosely based on a couple of resources:
- https://cloud.google.com/iap/docs/enabling-cloud-run#configuring_to_limit_access
- https://cloud.google.com/load-balancing/docs/https/ext-http-lb-tf-module-examples#with_a_backend
- https://www.karimarttila.fi/gcp/2022/05/10/gcp-cloud-run-with-iap.html


## Pre-requisites
1. [Install terraform] https://developer.hashicorp.com/terraform/downloads
2. Install the [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
3. [Prepare a GCP Project for provisioning](./MANUAL_STEPS.md)


## Considerations
- Terraform [can only configure IAP with "Organisation Internal"](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iap_brand) Brand data, requiring manual steps to convert it into external brands
- While it should be possible to enable API Services automatically, it would complicate the terraform file too much, so API enabling is done manually.
- This solution uses a Google-managed certificate for SSL on the External Load Balancer
- This is based on [Enabling IAP For Cloud Run](https://cloud.google.com/iap/docs/enabling-cloud-run#configuring_to_limit_access). Make sure to be aware of the **mentioned limitations**

## Use the terraform script to install Cloud Run and the External HTTPs Load Balancer 
1. Make sure you have a terraform.tfvars containing:
    - **GCP_PROJECT_ID**: the id of the project to provision
    - **GCP_IAP_SUPPORT_EMAIL**: this email will be displayed on the IAP consent screen as a contact email for the application
    - **APPLICATION_TITLE**: Name of the application as displayed by the IAP consent screen.
    - **CLOUD_RUN_IMAGE** : the image used to start a new Cloud Run Service
    - **GCP_LB_DOMAIN**: domain to associate to the external load balancer
    - **GCP_IAP_OAUTH_CLIENT_ID**: the Oauth Client id created during [the manual steps](./MANUAL_STEPS.md)
    - **GCP_IAP_OAUTH_CLIENT_SECRET**: the Oauth Client secret created during [the manual steps](/MANUAL_STEPS.md)
    - **GCP_REGION** (optional): a default region for all deployment and create steps that require it. Defaults to `europe-west9`
    - **GCP_ZONE** (optional): a default zone for all deployment and create steps that require it. Defaults to `europe-west9-a`
2. Run `terraform init` to retrieve the required providers
3. Run `terraform apply`


## Post-run steps
1. Point your domain name to your load balancer's IP address, which can be find in the Google Cloud Console's [Load Balancers page](https://console.cloud.google.com/net-services/loadbalancing/list/loadBalancers).
2. Please note that certificate provisionning can take a while on Google's end. To check status, go to [Load Balancers](https://console.cloud.google.com/net-services/loadbalancing/list/loadBalancers), click on your load balancer, then its certificate.
3. Make sure that all users that you want to be able to go through IAP must have the `IAP-secured web app user` role set in [IAM](https://console.cloud.google.com/iam-admin/iam)