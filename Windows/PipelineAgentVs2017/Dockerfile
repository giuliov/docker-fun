# escape=`
FROM microsoft/dotnet-framework:4.7.2-sdk-windowsservercore-ltsc2019

###################################################################
#
# 1.  Windows Server 2019 Core
# 2. .NET Framework 4.7.2
# 3. SQL Server Express 2017
#
###################################################################

ENV sql_express_download_url "https://go.microsoft.com/fwlink/?linkid=829176"

ENV sa_password="_" `
    attach_dbs="[]" `
    ACCEPT_EULA="_" `
    sa_password_path="C:\ProgramData\Docker\secrets\sa-password"

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

RUN Invoke-WebRequest -Uri $env:sql_express_download_url -OutFile sqlexpress.exe ; `
        Start-Process -Wait -FilePath .\sqlexpress.exe -ArgumentList /qs, /x:setup ; `
        .\setup\setup.exe /q /ACTION=Install /INSTANCENAME=SQLEXPRESS /FEATURES=SQLEngine /UPDATEENABLED=0 /SQLSVCACCOUNT='NT AUTHORITY\System' /SQLSYSADMINACCOUNTS='BUILTIN\ADMINISTRATORS' /TCPENABLED=1 /NPENABLED=0 /IACCEPTSQLSERVERLICENSETERMS ; `
        Remove-Item -Recurse -Force sqlexpress.exe, setup

RUN Stop-Service MSSQL`$SQLEXPRESS ; `
        Set-ItemProperty -path 'HKLM:\\software\\microsoft\\microsoft sql server\\mssql14.SQLEXPRESS\\mssqlserver\\supersocketnetlib\\tcp\\ipall' -name tcpdynamicports -value '' ; `
        Set-ItemProperty -path 'HKLM:\\software\\microsoft\\microsoft sql server\\mssql14.SQLEXPRESS\\mssqlserver\\supersocketnetlib\\tcp\\ipall' -name tcpport -value 1433 ; `
        Set-ItemProperty -path 'HKLM:\\software\\microsoft\\microsoft sql server\\mssql14.SQLEXPRESS\\mssqlserver\\' -name LoginMode -value 2


###################################################################
#
# 1.  Visual Studio 2017 Build Tools
# 2.  Azure DevOps agent 2.141.1
# 3.  Node 8.11
# 5.  Chocolatey 2.8.5.130
# 6.  WebDeploy 3.6
# 7.  NuGet CLI 4.9.2
# 8.  Microsoft.Data.Tools.MSBuild targets 10.0.61804.210
# 9. .NET Core SDK 2.2.100
#
###################################################################

# Install Visual Studio 2017 Build Tools
COPY Install.cmd C:\TEMP\
ADD https://aka.ms/vscollect.exe C:\TEMP\collect.exe

ARG CHANNEL_URL=https://aka.ms/vs/15/release/channel
ADD ${CHANNEL_URL} C:\TEMP\VisualStudio.chman

ADD https://aka.ms/vs/15/release/vs_buildtools.exe C:\TEMP\vs_buildtools.exe
RUN C:\TEMP\Install.cmd C:\TEMP\vs_buildtools.exe --quiet --wait --norestart --nocache `
    --channelUri C:\TEMP\VisualStudio.chman `
    --installChannelUri C:\TEMP\VisualStudio.chman `
    --add Microsoft.VisualStudio.Workload.ManagedDesktopBuildTools `
    --add Microsoft.Net.Component.3.5.DeveloperTools `
    --add Microsoft.Net.ComponentGroup.4.6.2.DeveloperTools `
    --add Microsoft.Net.ComponentGroup.TargetingPacks.Common `
    --add Microsoft.VisualStudio.Component.TestTools.BuildTools `
    --add Microsoft.VisualStudio.Workload.NodeBuildTools `
    --add Microsoft.VisualStudio.Component.TypeScript.2.8 `
    --add Microsoft.VisualStudio.Workload.NetCoreBuildTools `    
    --add Microsoft.VisualStudio.Workload.WebBuildTools `
    --add Microsoft.VisualStudio.Workload.MSBuildTools `
    --add Microsoft.VisualStudio.Workload.DataBuildTools

ENV AGENT_VERSION 2.141.1
ENV AGENT_SHA512 d9e7c201c4560f4df0323606eb2c637164fd0d52553c102b20582cb807467be3c8b640330ed5d0e2dbd098029e8c821477b5faaa0f94e7dd8823833baccdd6b3

WORKDIR c:/setup
RUN Invoke-WebRequest -OutFile agent.zip https://vstsagentpackage.azureedge.net/agent/$env:AGENT_VERSION/vsts-agent-win-x64-$env:AGENT_VERSION.zip; `
    if ((Get-FileHash agent.zip -Algorithm sha512).Hash -ne $Env:AGENT_SHA512) { `
        Write-Host 'CHECKSUM VERIFICATION FAILED!'; `
        exit 1; `
    }; `
    Expand-Archive -Path agent.zip -DestinationPath C:\BuildAgent ; `
    Remove-Item -Path agent.zip

# Install Node.js
ADD https://nodejs.org/dist/v8.11.3/node-v8.11.3-x64.msi C:\TEMP\node-install.msi
SHELL ["cmd", "/S", "/C"]
RUN start /wait msiexec.exe /i C:\TEMP\node-install.msi /l*vx "%TEMP%\MSI-node-install.log" /qn ADDLOCAL=ALL

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Install Chocolatey, WebDeploy, NuGet, MSBuild Data Tools
RUN Install-PackageProvider -Name chocolatey -RequiredVersion 2.8.5.130 -Force; `
    Install-Package -Name webdeploy -RequiredVersion 3.6.0 -Force; `
    Install-Package nuget.commandline -RequiredVersion 4.9.2 -Force; `
    & C:\Chocolatey\bin\nuget install Microsoft.Data.Tools.Msbuild -Version 10.0.61804.210

# Install .NET Core SDK
ENV DOTNET_SDK_VERSION 2.2.100
ENV DOTNET_SDK_SHA512 87776c7124cd25b487b14b3d42c784ee31a424c7c8191ed55810294423f3e59ebf799660864862fc1dbd6e6c8d68bd529399426811846e408d8b2fee4ab04fe5

RUN Invoke-WebRequest -OutFile dotnet.zip https://dotnetcli.blob.core.windows.net/dotnet/Sdk/$Env:DOTNET_SDK_VERSION/dotnet-sdk-$Env:DOTNET_SDK_VERSION-win-x64.zip; `
    if ((Get-FileHash dotnet.zip -Algorithm sha512).Hash -ne $Env:DOTNET_SDK_SHA512) { `
        Write-Host 'CHECKSUM VERIFICATION FAILED!'; `
        exit 1; `
    }; `
    Expand-Archive dotnet.zip -force -DestinationPath $Env:ProgramFiles\dotnet; `
    Remove-Item -Force dotnet.zip

RUN setx /M PATH $($Env:PATH + ';' + $Env:ProgramFiles + '\dotnet')

WORKDIR C:/BuildAgent
COPY start-sql.ps1 .
COPY configure-and-start-agent.ps1 .

# Configure and start Azure DevOps agent
CMD powershell -noexit .\configure-and-start-agent.ps1
