# Automated Deployment of GCP Backend

## How to run

- Create a terraform.tfvars file and assign the variables defined in the variables.tf file (project, region, credentials file, service Account)
```
cd deploy_be/terraform  
terraform apply
```

This will deploy the required infrastructure and create a values.yaml that is required for the Helm Chart.


- Get GKE Credentials
```
gcloud container clusters get-credentials martys-cluster --zone $YOUR_ZONE
```

- Run Helm Chart with Values.yaml
```
helm install backend ../helm/golang-api -f values.yaml
```