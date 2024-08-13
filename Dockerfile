FROM ubuntu:20.04
RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
    apt-transport-https \
    apt-utils \
    ca-certificates \
    curl \
    git \
    iputils-ping \
    jq \
    lsb-release \
    software-properties-common \
    unzip \
    zip \
    p7zip-full \
    p7zip-rar \
    gnupg \
    wget
    

#RUN DEBIAN_FRONTEND=noninteractive

#RUN wget https://github.com/PowerShell/PowerShell/releases/download/v7.4.3/powershell_7.4.3-1.deb_amd64.deb && dpkg -i powershell_7.4.3-1.deb_amd64.deb && apt-get install -f && rm powershell_7.4.3-1.deb_amd64.deb
#RUN wget https://github.com/PowerShell/PowerShell/releases/download/v7.4.4/powershell-7.4.4-osx-arm64.pkg && dpkg -i powershell-7.4.4-osx-arm64.pkg && apt-get install -f && rm powershell-7.4.4-osx-arm64.pkg

# Installer Azure CLI
RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | \
    tee /etc/apt/sources.list.d/azure-cli.list

# Get Microsoft signing key
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.asc.gpg && \
    mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/ && \
    wget -q https://packages.microsoft.com/config/debian/9/prod.list && \
    mv prod.list /etc/apt/sources.list.d/microsoft-prod.list && \
    chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg && \
    chown root:root /etc/apt/sources.list.d/microsoft-prod.list

RUN apt-get update && \
    apt-get install azure-cli



#RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash 

# Can be 'linux-x64', 'linux-arm64', 'linux-arm', 'rhel.6-x64'.
ENV TARGETARCH=linux-x64

WORKDIR /azp

COPY azure-pipelines-agent/start.sh .
RUN chmod +x start.sh

#ENTRYPOINT [ "./start.sh" ]
