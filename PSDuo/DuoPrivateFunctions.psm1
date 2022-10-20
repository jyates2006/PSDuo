Function New-DuoRequest{
<#
.SYNOPSIS
    Formats hashtables to payloads for Duo web requst

.DESCRIPTION
    Creates request to send to Duo to preform requested function

.PARAMETER Uri
    The child path to the api that follows the Duo API host name

.PARAMETER Methods
    The method type of the request [GET], [POST], [DELETE]

.PARAMETER Arguments
    The parameters that will be sent within the Duo request

.OUTPUTS
    [PSCustomObject]DuoRequest

.EXAMPLE
    Create-DuoRequest -UriPath "/admin/v1/users" -Method Post -Arguments @{username,"username"}

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo

.NOTES
    Version:        1.0
    Author:         Jared Yates
    Creation Date:  10/5/2022
    Purpose/Change: Initial script development
#>
    PARAM(
        [Parameter(Mandatory = $true)]$UriPath,
        [Parameter(Mandatory = $true)] $Method,
        [Parameter(Mandatory = $true)] $Arguments
    )
    
    #Decrypt our keys from our config
    $skey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Script:DuoConfig.SecretKey))
    $iKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Script:DuoConfig.IntergrationKey))
    $apiHost = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Script:DuoConfig.apiHost))
    $Date = (Get-Date).ToUniversalTime().ToString("ddd, dd MMM yyyy HH:mm:ss -0000")
    
    $DuoParamsParamsString = ($Arguments.Keys | Sort-Object | ForEach-Object {
        $_ + "=" + [uri]::EscapeDataString($Arguments.$_)
    }) -join "&"

    $DuoParams = (@(
        $Date.Trim(),
        $method.ToUpper().Trim(),
        $apiHost.ToLower().Trim(),
        $Uri.Trim(),
        $DuoParamsParamsString.trim()
    ).trim() -join "`n").ToCharArray().ToByte([System.IFormatProvider]$UTF8)

    $Secret = [System.Security.Cryptography.HMACSHA1]::new($skey.ToCharArray().ToByte([System.IFormatProvider]$UTF8))
    $Secret.ComputeHash($DuoParams) | Out-Null
    $Secret = [System.BitConverter]::ToString($Secret.Hash).Replace("-", "").ToLower()
    $AuthHeader = $ikey + ":" + $Secret
    [byte[]]$AuthHeader = [System.Text.Encoding]::ASCII.GetBytes($AuthHeader)

    $WebReqest = @{
        URI         = ('Https://{0}{1}' -f $apiHost, $UriPath)
        Headers     = @{
            "X-Duo-Date"    = $Date
            "Authorization" = ('Basic: {0}' -f [System.Convert]::ToBase64String($AuthHeader))
        }
        Body        = $Arguments
        Method      = $method
        ContentType = 'application/x-www-form-urlencoded'
    }
    $WebReqest
}

Function ConvertTo-UnixTime($Time){
<#
.Synopsis
    Converts time to epox time format
.DESCRIPTION
    Converts time to epox time format copatibale for unix systems
.EXAMPLE
    ConvertTo-UnixTime
.INPUTS

.OUTPUTS
    [int]$Timespan
.NOTES

.COMPONENT

.FUNCTIONALITY
    Time conversion
#>
    $Epox = Get-Date -Date '01/01/1970'
    $Timespan = New-Timespan -Start $Epox -End $Time | Select-Object -ExpandProperty TotalSeconds
    Write-Output $Timespan
}

Function Get-DuoDirectoryKey{

    Param(
        [Parameter(Mandatory=$false,
            ValueFromPipeLine=$true
        )]
            [String]$DirectoryName
    )

    If($DirectoryName){
        $Directories = $DirectoryName
    }
    Else{
        $Directories = Get-DuoDirectoryNames
    }

    $DuoConfig = Get-DuoConfig
    ForEach($Directory in $Directories){
        $Output = $DuoConfig.GetEnumerator() | Where-Object Name -EQ $DirectoryName
        $Output.Value
    }
}

Function Get-AllDuoGroups{
    
    #Base Claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/groups"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("limit","100")
    $DuoParams.Add("offset","0")

    #Duo has a 100 group limit in their api. Loop to return all groups
    $Offset=0
    Do{
        $DuoParams.Offset = $Offset
        $Request = Create-DuoRequest -UriPath $Uri -Method $Method -Arguments $DuoParams
        $Response = Invoke-RestMethod @Request
        If($Response.stat -ne 'OK'){
            Write-Warning 'DUO REST Call Failed'
            Write-Warning "Arguments:"+($DuoParams | Out-String)
            Write-Warning "Method:$Method    Path:$Uri"
        }   
        Else{
            $Output = $Response | Select-Object -ExpandProperty Response 
            $Output
            #Increment offset to return the next 100 groups
            $Offset += 100
        }
    }Until($Output.Count -lt 100)
}

