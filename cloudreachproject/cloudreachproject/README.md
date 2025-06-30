## Initialize terraform to download necessary provider plugins

```
terraform init
```

## list workspaces

```
terraform workspace list
```

## Create workspace

```
terraform workspace new prod

```

## show specific workspace

```
terraform workspace show
```

## first step verify the workspace

```
terraform worspace show
```

## Validate syntax with command

```
terraform validate
```

## Verify plan with command

```
terraform plan -var-file prod.tfvars
```

## Deploy infrastructure

```
terraform apply -var-file prod.tfvars
```

## How to Destroy

```
terraform workspace select prod
terraform destroy -var-file prod.tfvars
```
