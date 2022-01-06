# Golang Image for Windows

## Efficient Build via Terraform

With the support of [Alibaba Cloud](https://registry.terraform.io/providers/aliyun/alicloud/latest) and [Windbag](https://registry.terraform.io/providers/thxcode/windbag/latest), you can fairly easy to build the multi-release image of Windows.

### TL;DR

```bash

$ ACCESS_KEY="<ID of Alibaba OpenAPI AceessKey>" \
SECRET_KEY="<Secret of Alibaba OpenAPI AceessKey>" \
HOST_IMAGE_LIST="<VHD of Alibaba Windows ECS(in form of a space-seperated list), select from https://help.aliyun.com/document_detail/100410.html>" \
IMAGE_REPOSITORY="<Repository of Storing, i.e. registry.aliyuncs.com/thxcode>" \
IMAGE_NAME="golang" \
TAG="v0.0.0" \
DOCKER_USERNAME="<Username of Docker Registry Credential>" \
DOCKER_PASSWORD="<Password of Docker Registry Credential>" \
make golang package,deploy

```