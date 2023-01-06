# Manual Steps to prepare a new GCP Project for provisioning 

## Enable terraform to provision your project
These steps are based on [the official documentation from Hashicorp](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/google-cloud-platform-build)

1. [Create a new Google Cloud Project](https://console.cloud.google.com/projectcreate) and take note of the project ID.
3. Add Billing to your project (https://console.cloud.google.com/billing/manage)
4. Enable required APIs and Services
    - the [Cloud Identity-Aware Proxy API]( https://console.developers.google.com/apis/api/iap.googleapis.com/overview)
    - the [Compute Engine API](https://console.developers.google.com/apis/api/compute.googleapis.com/overview)
    - the [Cloud Run API](https://console.developers.google.com/apis/api/run.googleapis.com/overview)
5. On your machine, run `gcloud auth application-default login` and make sure you're identified as the owner of your project. This will make terraform use your own account to perform actions.


## Create on Oauth Client ID and Secret for the IAP configuration of the load balancer
1. Go to the [Credentials Page](https://console.cloud.google.com/apis/credentials)
2. Click on `+ Create Credentials` and select "Oauth Client ID", then fill in the information.
3. **Make sure that Authorized Redirect URIs contains the following** : `https://iap.googleapis.com/v1/oauth/clientIds/<your-oauth-client-id>:handleRedirect`. You might need to save your new oauth credentials and modify it again to be able to use the id


## (Optional) Prepare an image on artifacts repository 
If you want to deploy a private image to cloud run, a good idea would be to store the image in Arifacts Repository.
1. Enable the [Artifacts Registry API](https://console.developers.google.com/apis/api/artifactregistry.googleapis.com/overview) (to store your cloud run images) -->
2. Go to Artifacts Repository and Create a new docker repository. Then copy its url
3. Run the gcloud command suggested in the Setup Intructions of your repository (gcloud auth configure-docker [region]-docker.pkg.dev)
4. Tag your docker image properly and push it to your repository
    ```shell
    docker image tag <current-image-tag> <region>-docker.pkg.dev/<project-name>/<repository_name>/<image_tag>
    docker image push <region>-docker.pkg.dev/<project-name>/<repository_name>/<image_tag>
    ```
5. Provide the url to your image inside the CLOUD_RUN_IMAGE variable in terraform.tfvars