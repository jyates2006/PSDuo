Function Get-DuoToken {
    Param(
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoToken -Serial $_){$true}
            Else{Throw "Token ID: $($_) doesn't exist within Duo"}
        })]
            [String]$Serial,

        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=1
        )]
        [ValidateSet("HOTP-6","HOTP-8","YubiKey")]
            [String]$Type
    )

        #Base Claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/tokens"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("limit","500")
    $DuoParams.Add("offset","0")

    If($Serial){
        $DuoParams.Add("serial",$Serial)
    }
    If($Type){
        Switch($Type){
            "HOTP-6" {$DuoParams.Add("type","h6")}
            "HOTP-8" {$DuoParams.Add("type","h8")}
            "YubiKey" {$DuoParams.Add("type","yk")}
        }
    }

        #Duo has a 500 token limit in their api. Loop to return all tokens
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
                #Increment offset to return the next 500 tokens
            $Offset += 500
        }
    }Until($Output.Count -lt 500)
        #End loop if count limit hasn't been reached
}

Function New-DuoToken {
    Param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
            [String]$Serial,
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=1
        )]
        [ValidateSet("HOTP-6","HOTP-8","YubiKey")]
            [String]$Type,
        [Parameter(ParameterSetName="HOTP",
            Mandatory=$false,
            ValueFromPipeline=$false
        )] 
            [Switch]$HOTP,
        [Parameter(ParameterSetName="YubiKey",
            Mandatory=$false,
            ValueFromPipeline=$false
        )] 
            [Switch]$YubiKey,
        [Parameter(ParameterSetName="HOTP",
            Mandatory=$true,
            ValueFromPipeline=$false
        )]
            [String]$Secret,
        [Parameter(ParameterSetName="HOTP",
            Mandatory=$false
        )]
            [Int]$Counter,
        [Parameter(ParameterSetName="YubiKey",
            Mandatory=$true
        )]
            [String]$PrivateID,
        [Parameter(ParameterSetName="YubiKey",
            Mandatory=$true
        )]
            [String]$AES_Key
    )

        #Base Claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/tokens"
    [Hashtable]$DuoParams = @{}

    If($Type){
        Switch($Type){
            "HOTP-6" {$DuoParams.Add("type","h6")}
            "HOTP-8" {$DuoParams.Add("type","h8")}
            "YubiKey" {$DuoParams.Add("type","yk")}
        }
    }

    If($HOTP){
        $DuoParams.Add("secret",$Secret)
        If($Counter){
            $DuoParams.Add("counter",$Counter)
        }
        else {
            $DuoParams.Add("counter","0")
        }
    }
    
    If($YubiKey){
        $DuoParams.Add("private_id",$PrivateID)
        $DuoParams.Add("aes_key",$AES_Key)
    }

        #Creates the request
    $Request = Create-DuoRequest -UriPath $Uri -Method $Method -Arguments $DuoParams
    $Response = Invoke-RestMethod @Request
     
        #Error Handling
    If($Response.stat -ne 'OK'){
        Write-Warning 'DUO REST Call Failed'
        Write-Warning "Arguments:"+($DuoParams | Out-String)
        Write-Warning "Method:$Method    Path:$Uri"
    }
        #Returning request
    Else{
        $Output = $Response | Select-Object -ExpandProperty Response 
        $Output
    }
}

Function Sync-DuoToken {
    Param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoToken -Serial $_){$true}
            Else{Throw "Token ID: $($_) doesn't exist within Duo"}
        })]
            [String]$TokenID,
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$false,
            Position=1
        )]
            [Int]$Code1,
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$false,
            Position=2
        )]
            [Int]$Code2,
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$false,
            Position=3
        )]
            [Int]$Code3
    )

        #Base Claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/tokens/$($TokenID)/resync"
    [Hashtable]$DuoParams = @{}

        #Creates the request
    $Request = Create-DuoRequest -UriPath $Uri -Method $Method -Arguments $DuoParams
    $Response = Invoke-RestMethod @Request
     
        #Error Handling
    If($Response.stat -ne 'OK'){
        Write-Warning 'DUO REST Call Failed'
        Write-Warning "Arguments:"+($DuoParams | Out-String)
        Write-Warning "Method:$Method    Path:$Uri"
    }
        #Returning request
    Else{
        $Output = $Response | Select-Object -ExpandProperty Response 
        $Output
    }
}

Function Remove-DuoToken {
    Param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoToken -Serial $_){$true}
            Else{Throw "Token ID: $($_) doesn't exist within Duo"}
        })]
            [String]$TokenID
    )
    
        #Base Claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/tokens/$($TokenID)/resync"
    [Hashtable]$DuoParams = @{}

        #Creates the request
    $Request = Create-DuoRequest -UriPath $Uri -Method $Method -Arguments $DuoParams
    $Response = Invoke-RestMethod @Request
     
        #Error Handling
    If($Response.stat -ne 'OK'){
        Write-Warning 'DUO REST Call Failed'
        Write-Warning "Arguments:"+($DuoParams | Out-String)
        Write-Warning "Method:$Method    Path:$Uri"
    }
        #Returning request
    Else{
        $Output = $Response | Select-Object -ExpandProperty Response 
        $Output
    }
}

Function Get-DuoWebAuthn {
    Param(
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true
        )]
        [ValidateScript({
            If(Test-DuoWebAuthn -WebAuthNKey $_){$true}
            Else{Throw "WebAuthn Key: $($_) doesn't exist within Duo"}
        })]
            [String]$WebAuthnKey

    )

        #Base Claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/webauthncredentials"
    [Hashtable]$DuoParams = @{}

    If($WebAuthnKey){
        $Uri = "/admin/v1/webauthncredentials/$($WebAuthnKey)"
    }

    $DuoParams.Add("limit","500")
    $DuoParams.Add("offset","0")

        #Duo has a 500 token limit in their api. Loop to return all tokens
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
                #Increment offset to return the next 500 tokens
            $Offset += 500
        }
    }Until($Output.Count -lt 500)
        #End loop if count limit hasn't been reached
}

Function Remove-DuoWebAuthn {
    Param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true
        )]
        [ValidateScript({
            If(Test-DuoWebAuthn -WebAuthNKey $_){$true}
            Else{Throw "WebAuthn Key: $($_) doesn't exist within Duo"}
        })]
            [String]$WebAuthnKey
    )

        #Base Claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/webauthncredentials/$($WebAuthnKey)"
    [Hashtable]$DuoParams = @{}

        #Creates the request
    $Request = Create-DuoRequest -UriPath $Uri -Method $Method -Arguments $DuoParams
    $Response = Invoke-RestMethod @Request
     
        #Error Handling
    If($Response.stat -ne 'OK'){
        Write-Warning 'DUO REST Call Failed'
        Write-Warning "Arguments:"+($DuoParams | Out-String)
        Write-Warning "Method:$Method    Path:$Uri"
    }
        #Returning request
    Else{
        $Output = $Response | Select-Object -ExpandProperty Response 
        $Output
    }
}
