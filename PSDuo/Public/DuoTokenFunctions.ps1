Function Get-DuoToken {
    [CmdletBinding(DefaultParameterSetName="TID")]
    PARAM(
        [Parameter(ParameterSetName="TID",
            Mandatory = $false,
            ValueFromPipeLine = $true,
            Position=0
            )]
        [ValidateScript({
            If(Test-DuoTokens -TokenID $_){$true}
            Else{Throw "Token: $($_) doesn't exist in Duo"}
        })]
            [String]$TokenID,
        [Parameter(ParameterSetName="Tserial",
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [String]$Serial,
        [Parameter(ParameterSetName="Tserial",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=1
            )]
            [ValidateSet("HOTP-6","HOTP-8","YubiKey","Duo-D100")]
            [String]$Type
    )

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/tokens"
    [Hashtable]$DuoParams = @{}

    If($Serial){
        $DuoParams.Add("serial",$serial.ToLower())
        Switch($Type){
            "HOTP-6" {$DuoParams.Add("type","h6")}
            "HOTP-8" {$DuoParams.Add("type","h8")}
            "YubiKey" {$DuoParams.Add("type","yk")}
            "Duo-D100" {$DuoParams.Add("type","d1")}
        }
    }
    ElseIf($TokenID){    
        $Uri = "/admin/v1/tokens/$($TokenID)"
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

Function New-DuoToken {
    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [String]$Serial,
        <#[Parameter(ParameterSetName="Type",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=1
            )]
            [ValidateSet("HOTP-6","HOTP-8","YubiKey")]
            [String]$Type#>
        [Parameter(ParameterSetName="HOTP-6",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position = 1
            )]
            [Switch]$HOTP6,
        [Parameter(ParameterSetName="HOTP8",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position = 1
            )]
            [Switch]$HOTP8,
        [Parameter(ParameterSetName="HOTP6",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position = 1
            )]
            [Switch]$Secret,
        [Parameter(ParameterSetName="HOTP8",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position = 1
            )]
            [Switch]$Secret,
        [Parameter(ParameterSetName="YubiKey",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position = 1
            )]
            [Switch]$PrivateID,
        [Parameter(ParameterSetName="HOTP6",
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position = 2
            )]
            [Switch]$Counter,
        [Parameter(ParameterSetName="HOTP8",
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position = 2
            )]
            [Switch]$Counter,
        [Parameter(ParameterSetName="YubiKey",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position = 2
            )]
            [Switch]$AESkey
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/tokens"
    [Hashtable]$DuoParams = @{}

    If($HOTP6){
        $Type = "h6"
    }
    ElseIf($HOTP8){
        $Type = "h8"
    }
    ElseIf($YubiKey){
        $Type = "yk"
    }
    $DuoParams.Add("type",$Type)
    $DuoParams.Add("serial",$Serial)
    
    If($HOTP6 -or $HOTP8){
        $DuoParams.Add("secret",$Secret)
        If($Counter){
            $DuoParams.Add("counter",$Counter.ToString())
        }
    }
    ElseIf($YubiKey){
        $DuoParams.Add("private_id",$PrivateID)
        $DuoParams.Add("aes_key",$AESkey)
    }

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

Function Sync-DuoToken {
    [CmdletBinding(DefaultParameterSetName="TID")]
    PARAM(
        [Parameter(ParameterSetName="Serial",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [String]$Serial,
        [Parameter(ParameterSetName="TID",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
            )]
        [ValidateScript({
            If(Test-DuoTokens -TokenID $_){$true}
            Else{Throw "Token: $($_) doesn't exist in Duo"}
        })]
            [String]$TokenID,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=2
            )]
            [String]$Code1,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=3
            )]
            [String]$Code2,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=4
            )]
            [String]$Code3,
        [Parameter(ParameterSetName="Serial",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=1
            )]
            [ValidateSet("HOTP-6","HOTP-8","Duo-D100")]
            [String]$Type
        )

    If($Serial){
        $TokenID = (Get-DuoTokens -Serial $Serial -Type $Type).token_id
    }

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/tokens/$($TokenID)"
    [Hashtable]$DuoParams = @{}

    $DuoParams.Add("code1",$Code1)
    $DuoParams.Add("code2",$Code2)
    $DuoParams.Add("code3",$Code3)

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

Function Remove-DuoToken {
    [CmdletBinding(DefaultParameterSetName="TID")]
    PARAM(
        [Parameter(ParameterSetName="TID",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
            )]
        [ValidateScript({
            If(Test-DuoTokens -TokenID $_){$true}
            Else{Throw "Token: $($_) doesn't exist in Duo"}
        })]
            [String]$TokenID,
        [Parameter(ParameterSetName="Serial",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [String]$Serial,
        [Parameter(ParameterSetName="Serial",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=1
            )]
            [ValidateSet("HOTP-6","HOTP-8","YubiKey","Duo-D100")]
            [String]$Type
        )
    
    If($Serial){
        $TokenID = Get-DuoTokens -Serial $Serial -Type $Type
    }

    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/tokens/$($TokenID)"
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

Function Get-DuoWebAuthnCredential {
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
        [String]$WebAuthnKey
    )
    
    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/webauthncredentials"
    [Hashtable]$DuoParams = @{}

    If($WebAuthnKey){
        $Uri = "/admin/v1/webauthncredentials/$($WebAuthnKey)"
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

Function Remove-DuoWebAuthnCredential {
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
        [String]$WebAuthnKey
    )

    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/webauthncredentials/$($WebAuthnKey)"
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