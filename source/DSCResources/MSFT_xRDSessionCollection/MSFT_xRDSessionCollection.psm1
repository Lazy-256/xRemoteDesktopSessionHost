Import-Module -Name "$PSScriptRoot\..\..\xRemoteDesktopSessionHostCommon.psm1"
if (!(Test-xRemoteDesktopSessionHostOsRequirement)) { Throw "The minimum OS requirement was not met."}
Import-Module RemoteDesktop
$localhost = [System.Net.Dns]::GetHostByName((hostname)).HostName

#######################################################################
# The Get-TargetResource cmdlet.
#######################################################################
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (    
        [Parameter(Mandatory = $true)]
        [ValidateLength(1,256)]
        [string] $CollectionName,
        [Parameter(Mandatory = $true)]
        [string] $SessionHost,
        [Parameter()]
        [string] $CollectionDescription,
        [Parameter()]
        [string] $ConnectionBroker
    )
    Write-Verbose "Getting information about RDSH collection."
    Write-Verbose "$($env:COMPUTERNAME) | CollectionName :: $CollectionName | ConnectionBroker :: $ConnectionBroker"
    if ($localhost -eq $ConnectionBroker) {
      $Collection = Get-RDSessionCollection -CollectionName $CollectionName -ConnectionBroker $ConnectionBroker #-ErrorAction SilentlyContinue
      @{
          "CollectionName" = $Collection.CollectionName 
          "CollectionDescription" = $Collection.CollectionDescription
          "SessionHost" = $localhost
          "ConnectionBroker" = $ConnectionBroker
      }
    } else {
      Write-Verbose "zzz:: $PsDscRunAsCredential"
      #$cred = New-Object System.Management.Automation.PSCredential('admin_user@test.net', (ConvertTo-SecureString 'Super5ecret+++' -AsPlainText -Force));
      $Collection = invoke-command -computername $ConnectionBroker { Get-RDSessionCollection -CollectionName $using:CollectionName -ConnectionBroker $using:ConnectionBroker } -Credential $PsDscRunAsCredential -Authentication Credssp;
      #$Collection = Get-RDSessionCollection -CollectionName $CollectionName -ConnectionBroker $ConnectionBroker #-ErrorAction SilentlyContinue
      @{
         "CollectionName" = $Collection.CollectionName 
         "CollectionDescription" = $Collection.CollectionDescription
         "SessionHost" = $localhost
         "ConnectionBroker" = $ConnectionBroker
      }
    }
}


######################################################################## 
# The Set-TargetResource cmdlet.
########################################################################
function Set-TargetResource

{
    [CmdletBinding()]
    param
    (    
        [Parameter(Mandatory = $true)]
        [ValidateLength(1,256)]
        [string] $CollectionName,
        [Parameter(Mandatory = $true)]
        [string] $SessionHost,
        [Parameter()]
        [string] $CollectionDescription,
        [Parameter()]
        [string] $ConnectionBroker
    )
    Write-Verbose "Setup a RDSH collection."
    if ($localhost -eq $ConnectionBroker) 
    {       
      if ((Get-RDSessionCollection -CollectionName $CollectionName -ConnectionBroker $ConnectionBroker -ea 0).Length -eq 0) 
      {
        Write-Verbose "Creating a new RDSH collection."
        New-RDSessionCollection @PSBoundParameters
      } else {
        Write-Verbose "Adding new RD host into RDSH collection."
        Add-RDSessionHost @PSBoundParameters
      }
    }
    else 
    {
	      #Write-Verbose 'zzz'
        #$PSBoundParameters.Remove('CollectionDescription')
        #Write-Verbose $PSBoundParameters
        Add-RDSessionHost @PSBoundParameters
        #$para = $PSBoundParameters;
        #Write-Verbose "zzzz"
        #$cred = New-Object System.Management.Automation.PSCredential('admin_user@test.net', (ConvertTo-SecureString 'Super5ecret+++' -AsPlainText -Force));
        #invoke-command -computername 'rdcb.test.net' { Add-RDSessionHost @Using:para } -Credential $cred -Authentication Credssp;
    }
}

#######################################################################
# The Test-TargetResource cmdlet.
#######################################################################
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateLength(1,256)]
        [string] $CollectionName,
        [Parameter(Mandatory = $true)]
        [string] $SessionHost,
        [Parameter()]
        [string] $CollectionDescription,
        [Parameter()]
        [string] $ConnectionBroker
    )
    Write-Verbose "Checking for existence of RDSH collection."
    $null -ne (Get-TargetResource @PSBoundParameters).CollectionName
}


Export-ModuleMember -Function *-TargetResource
