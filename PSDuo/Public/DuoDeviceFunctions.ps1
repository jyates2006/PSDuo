Function Get-DuoDestktop {
    PARAMS(
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $true,
            Position=0
            )]
        [ValidateScript({
            If(Test-DuoWEbAuthnKey -TokenID $_){$true}
            Else{Throw "Token: $($_) doesn't exist in Duo"}
        })]
        [String]$DesktopKey
    )
    
    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/desktop_authenticators"
    [Hashtable]$DuoParams = @{}

    If($DesktopKey){
        $Uri = "/admin/v1/desktop_authenticators/$($DesktopKey)"
    }
    
    $Offset = 0

    #Duo has a 300 user limit in their api. Loop to return all users
    Do{
        $DuoParams.Offset = $Offset
        $Request = New-DuoRequest -UriPath $Uri -Method $Method -Arguments $DuoParams
        $Response = Invoke-RestMethod @Request
        If($Response.stat -ne 'OK'){
            Write-Warning 'DUO REST Call Failed'
            Write-Warning "Arguments:"+($DuoParams | Out-String)
            Write-Warning "Method:$Method    Path:$Uri"
        }   
        Else{
            $Output = $Response | Select-Object -ExpandProperty Response 
            $Output
            #Increment offset to return the next 300 users
            $Offset += 300
        }
    }Until($Output.Count -lt 300)

}

Function Remove-DuoDestktop {
    PARAMS(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $true,
            Position=0
            )]
        [ValidateScript({
            If(Test-DuoDesktop -DesktopKey $_){$true}
            Else{Throw "Desktop: $($_) doesn't exist in Duo"}
        })]
        [String]$DesktopKey
    )
    
    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/desktop_authenticators/$($DesktopKey)"
    [Hashtable]$DuoParams = @{}

    $Request = New-DuoRequest -UriPath $Uri -Method $Method -Arguments $DuoParams
    $Response = Invoke-RestMethod @Request
    If($Response.stat -ne 'OK'){
        Write-Warning 'DUO REST Call Failed'
        Write-Warning "Arguments:"+($DuoParams | Out-String)
        Write-Warning "Method:$Method    Path:$Uri"
    }   
    Else{
        $Output = $Response | Select-Object -ExpandProperty Response 
        $Output
    }
}

Function Get-DuoEndpoint {
    [CmdletBinding(DefaultParameterSetName="EKey")]
    PARAM(
        [Parameter(ParameterSetName="EKey",
            Mandatory = $false,
            ValueFromPipeLine = $true,
            Position=0
            )]
        <#[ValidateScript({
            If(Test-DuoTokens -TokenID $_){$true}
            Else{Throw "Token: $($_) doesn't exist in Duo"}
        })]#>
            [String]$EndpointKey
    )

     #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/endpoints"
    [Hashtable]$DuoParams = @{}

    If($EndpointID){    
        $Uri = "/admin/v1/endpoints/$($EndpointKey)"
    }
    Else{
        $DuoParams.Add("limit","300")
        $DuoParams.Add("offset","0")
    }
    $Offset = 0

    #Duo has a 300 user limit in their api. Loop to return all users
    Do{
        $DuoParams.Offset = $Offset
        $Request = New-DuoRequest -UriPath $Uri -Method $Method -Arguments $DuoParams
        $Response = Invoke-RestMethod @Request
        If($Response.stat -ne 'OK'){
            Write-Warning 'DUO REST Call Failed'
            Write-Warning "Arguments:"+($DuoParams | Out-String)
            Write-Warning "Method:$Method    Path:$Uri"
        }   
        Else{
            $Output = $Response | Select-Object -ExpandProperty Response 
            $Output
            #Increment offset to return the next 300 users
            $Offset += 300
        }
    }Until($Output.Count -lt 300)
}

Function Get-DuoRegisteredDevices {
    PARAM(
        [Parameter(ParameterSetName="DID",
            Mandatory = $false,
            ValueFromPipeLine = $true,
            Position=0
            )]
        <#[ValidateScript({
            If(Test-DuoTokens -TokenID $_){$true}
            Else{Throw "Token: $($_) doesn't exist in Duo"}
        })]#>
            [String]$DeviceID
    )

     #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/registered_devices"
    [Hashtable]$DuoParams = @{}

    If($DeviceID){    
        $Uri = "/admin/v1/registered_devices/$($DeviceID)"
    }
    Else{
        $DuoParams.Add("limit","300")
        $DuoParams.Add("offset","0")
    }
    $Offset = 0

    #Duo has a 300 user limit in their api. Loop to return all users
    Do{
        $DuoParams.Offset = $Offset
        $Request = New-DuoRequest -UriPath $Uri -Method $Method -Arguments $DuoParams
        $Response = Invoke-RestMethod @Request
        If($Response.stat -ne 'OK'){
            Write-Warning 'DUO REST Call Failed'
            Write-Warning "Arguments:"+($DuoParams | Out-String)
            Write-Warning "Method:$Method    Path:$Uri"
        }   
        Else{
            $Output = $Response | Select-Object -ExpandProperty Response 
            $Output
            #Increment offset to return the next 300 users
            $Offset += 300
        }
    }Until($Output.Count -lt 300)
}

Function Remove-DuoRegisteredDevice {
    PARAM(
        [Parameter(ParameterSetName="DID",
            Mandatory = $true,
            ValueFromPipeLine = $true,
            Position=0
            )]
        <#[ValidateScript({
            If(Test-DuoTokens -TokenID $_){$true}
            Else{Throw "Token: $($_) doesn't exist in Duo"}
        })]#>
            [String]$DeviceID
    )

     #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/registered_devices/$($DeviceID)"
    [Hashtable]$DuoParams = @{}

    $DuoParams.Offset = $Offset
    $Request = New-DuoRequest -UriPath $Uri -Method $Method -Arguments $DuoParams
    $Response = Invoke-RestMethod @Request
    If($Response.stat -ne 'OK'){
        Write-Warning 'DUO REST Call Failed'
        Write-Warning "Arguments:"+($DuoParams | Out-String)
        Write-Warning "Method:$Method    Path:$Uri"
    }   
    Else{
        $Output = $Response | Select-Object -ExpandProperty Response 
        $Output
    }
}