﻿#region User
####################################################################

<#
.Synopsis
   Get a information about the Nessus User for a Session.
.DESCRIPTION
   Get a information about the Nessus User for a Session.
.EXAMPLE
    Get-NessusUser -SessionId 0 -Verbose
    VERBOSE: GET https://192.168.1.205:8834/users with 0-byte payload
    VERBOSE: received 125-byte response of content type application/json


    Name       : carlos
    UserName   : carlos
    Email      : 
    Id         : 2
    Type       : local
    Permission : Sysadmin
    LastLogin  : 2/15/2015 4:52:56 PM
#>
function Get-NessusUser
{
    [CmdletBinding()]
    Param
    (
        # Nessus session Id
        [Parameter(Mandatory=$true,
                   Position=0,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('Index')]
        [int32[]]
        $SessionId = @()
    )

    Begin
    {
        $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
    }
    Process
    {
        $ToProcess = @()

        foreach($i in $SessionId)
        {
            $Connections = $Global:NessusConn
            
            foreach($Connection in $Connections)
            {
                if ($Connection.SessionId -eq $i)
                {
                    $ToProcess += $Connection
                }
            }
        }

        foreach($Connection in $ToProcess)
        {
                
            $Users = InvokeNessusRestRequest -SessionObject $Connection -Path '/users' -Method 'Get'
                 
            if ($Users  -is [psobject])
            {
                $Users.users | ForEach-Object -Process {
                    $UserProperties = [ordered]@{}
                    $UserProperties.Add('Name', $_.name)
                    $UserProperties.Add('UserName', $_.username)
                    $UserProperties.Add('Email', $_.email)
                    $UserProperties.Add('Id', $_.id)
                    $UserProperties.Add('Type', $_.type)
                    $UserProperties.Add('Permission', $PermissionsId2Name[$_.permissions])
                    $UserProperties.Add('LastLogin', $origin.AddSeconds($_.lastlogin).ToLocalTime())
                    $UserObj = New-Object -TypeName psobject -Property $UserProperties
                    $UserObj.pstypenames[0] = 'Nessus.User'
                    $UserObj
                }
            }
        }
        
    }
    End{}
}


<#
.Synopsis
   Add a new user to a Nessus Server.
.DESCRIPTION
   Add a new user to a Nessus Server.
.EXAMPLE
   New-NessusUser -SessionId 0 -Credential (Get-Credential) -Permission Sysadmin
#>
function New-NessusUser
{
    [CmdletBinding()]
    Param
    (
        # Nessus session Id
        [Parameter(Mandatory=$true,
                   Position=0,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('Index')]
        [int32[]]
        $SessionId = @(),

        # Credentials for connecting to the Nessus Server
        [Parameter(Mandatory=$true,
        Position=1)]
        [Management.Automation.PSCredential]
        $Credential,

        [Parameter(Mandatory=$true,
        Position=2)]
        [ValidateSet('Read-Only', 'Regular', 'Administrator', 'Sysadmin')]
        [string]
        $Permission,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateSet('Local', 'LDAP')]
        [string]
        $Type = 'Local',

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Email,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name 

    )

    Begin{}
    Process
    {
         $ToProcess = @()

        foreach($i in $Id)
        {
            $Connections = $Global:NessusConn
            
            foreach($Connection in $Connections)
            {
                if ($Connection.Id -eq $i)
                {
                    $ToProcess += $Connection
                }
            }
        }

        foreach($Connection in $ToProcess)
        {
            $NewUserParams = @{}

            $NewUserParams.Add('type',$Type.ToLower())
            $NewUserParams.Add('permissions', $PermissionsName2Id[$Permission])
            $NewUserParams.Add('username', $Credential.GetNetworkCredential().UserName)
            $NewUserParams.Add('password', $Credential.GetNetworkCredential().Password)

            if ($Email.Length -gt 0)
            {
                $NewUserParams.Add('email', $Email)
            }

            if ($Name.Length -gt 0)
            {
                $NewUserParams.Add('name', $Name)
            }

            $NewUser = InvokeNessusRestRequest -SessionObject $Connection -Path '/users' -Method 'Post' -Parameter $NewUserParams
                 
            if ($NewUser)
            {
                $NewUser
            }
        }
    }
    End{}
}

#endregion