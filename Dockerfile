ARG WINDBAGRELEASE_BUILDER_IMAGE_TAG="10.0.17763.2114"

FROM mcr.microsoft.com/windows/servercore:${WINDBAGRELEASE_BUILDER_IMAGE_TAG} as builder
MAINTAINER thxcode "thxcode0824@gmail.com"

# $ProgressPreference: https://github.com/PowerShell/PowerShell/issues/2138#issuecomment-251261324
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# install MinGit (especially for "go get")
# https://blogs.msdn.microsoft.com/visualstudioalm/2016/09/03/whats-new-in-git-for-windows-2-10/
# "Essentially, it is a Git for Windows that was stripped down as much as possible without sacrificing the functionality in which 3rd-party software may be interested."
# "It currently requires only ~45MB on disk."
ENV GIT_VERSION 2.23.0
ENV GIT_TAG v${GIT_VERSION}.windows.1
ENV GIT_DOWNLOAD_URL https://github.com/git-for-windows/git/releases/download/${GIT_TAG}/MinGit-${GIT_VERSION}-64-bit.zip
ENV GIT_DOWNLOAD_SHA256 8f65208f92c0b4c3ae4c0cf02d4b5f6791d539cd1a07b2df62b7116467724735
# steps inspired by "chcolateyInstall.ps1" from "git.install" (https://chocolatey.org/packages/git.install)
RUN Write-Host ('Downloading {0} ...' -f $env:GIT_DOWNLOAD_URL); \
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
    Invoke-WebRequest -Uri $env:GIT_DOWNLOAD_URL -OutFile 'git.zip'; \
    \
    Write-Host ('Verifying sha256 ({0}) ...' -f $env:GIT_DOWNLOAD_SHA256); \
    if ((Get-FileHash git.zip -Algorithm sha256).Hash -ne $env:GIT_DOWNLOAD_SHA256) { \
        Write-Host 'FAILED!'; \
        exit 1; \
    }; \
    \
    Write-Host 'Expanding ...'; \
    Expand-Archive -Path git.zip -DestinationPath C:\git\.; \
    \
    Write-Host 'Removing ...'; \
    Remove-Item git.zip -Force; \
    \
    Write-Host 'Updating PATH ...'; \
    $env:PATH = 'C:\git\cmd;C:\git\mingw64\bin;C:\git\usr\bin;' + $env:PATH; \
    [Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::Machine); \
    \
    Write-Host 'Verifying install ("git version") ...'; \
    git version; \
    \
    Write-Host 'Complete.';

# for 1.17+, we'll follow the (new) Go upstream default for install (https://golang.org/cl/283600), which frees up C:\go to be the default GOPATH and thus match the Linux images more closely (https://github.com/docker-library/golang/issues/288)
ENV GOPATH C:\\go
# HOWEVER, please note that it is the Go upstream intention to remove GOPATH support entirely: https://blog.golang.org/go116-module-changes

# PATH isn't actually set in the Docker image, so we have to set it from within the container
RUN $newPath = ('{0}\bin;C:\Program Files\Go\bin;{1}' -f $env:GOPATH, $env:PATH); \
    Write-Host ('Updating PATH: {0}' -f $newPath); \
    [Environment]::SetEnvironmentVariable('PATH', $newPath, [EnvironmentVariableTarget]::Machine);
# doing this first to share cache across versions more aggressively

ENV GOLANG_VERSION 1.17.3

RUN $url = 'https://dl.google.com/go/go1.17.3.windows-amd64.zip'; \
    Write-Host ('Downloading {0} ...' -f $url); \
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
    Invoke-WebRequest -Uri $url -OutFile 'go.zip'; \
    \
    $sha256 = 'e78684b955742e215926204afc6ed62b9d165b509e25a687d62902516f08726b'; \
    Write-Host ('Verifying sha256 ({0}) ...' -f $sha256); \
    if ((Get-FileHash go.zip -Algorithm sha256).Hash -ne $sha256) { \
        Write-Host 'FAILED!'; \
        exit 1; \
    }; \
    \
    Write-Host 'Expanding ...'; \
    Expand-Archive go.zip -DestinationPath C:\; \
    \
    Write-Host 'Moving ...'; \
    Move-Item -Path C:\go -Destination 'C:\Program Files\Go'; \
    \
    Write-Host 'Removing ...'; \
    Remove-Item go.zip -Force; \
    \
    Write-Host 'Verifying install ("go version") ...'; \
    go version; \
    \
    Write-Host 'Complete.';

WORKDIR $GOPATH
