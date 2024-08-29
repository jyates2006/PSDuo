Function Get-DuoAdmin {
    PARAM(
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [String]$AdminID
    )

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/admins"
    [Hashtable]$DuoParams = @{}

    If($AdminID){    
        $Uri = "/admin/v1/admins/$($AdminID)"
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

Function New-DuoAdmin {
    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [String]$Email,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [String]$Name,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [String]$Phone,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [Bool]$RequirePasswordChange,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [String]$Role,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [Bool]$RestricedBy_AdminUnits,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [Bool]$SendEmail,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [String]$TokenID,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [Int]$ExpirationDays
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/admins"
    [Hashtable]$DuoParams = @{}

    $DuoParams.Add("email",$Email)
    $DuoParams.Add("name",$Name)
    If($Phone){
        $DuoParams.Add("phone",$Phone)
    }
    If($RequirePasswordChange){
        $DuoParams.Add("password_change_required",$RequirePasswordChange)
    }
    If($Role){
        $DuoParams.Add("role",$Role)
    }
    If($RestricedBy_AdminUnits){
        $DuoParams.Add("restricted_by_admin_units",$RestricedBy_AdminUnits)
    }
    If($SendEmail){
        Switch($SendEmail){
            $true {$DuoParams.Add("send_email",1)}
            $false {$DuoParams.Add("send_email",0)}
        }
    }
    If($TokenID){
        $DuoParams.Add("token_id",$TokenID)
    }
    If($ExpirationDays){
        $DuoParams.Add("valid_days",$ExpirationDays)
    }

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

Function Set-DuoAdmin {
    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [String]$AdminID,
        [Parameter(ParameterSetName="AdminFields",
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [String]$Name,
        [Parameter(ParameterSetName="AdminFields",
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [String]$Phone,
        [Parameter(ParameterSetName="AdminFields",
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [Bool]$RequirePasswordChange,
        [Parameter(ParameterSetName="AdminFields",
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [String]$Role,
        [Parameter(ParameterSetName="AdminFields",
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [Bool]$RestricedBy_AdminUnits,
        [Parameter(ParameterSetName="AdminFields",
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [String]$Status,
        [Parameter(ParameterSetName="AdminFields",
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [String]$TokenID,
        [Parameter(ParameterSetName="Reset",
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [Switch]$ResetAuthAttempts,
        [Parameter(ParameterSetName="Clear",
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [Switch]$ClearExpiration
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/admins/$($AdminID)"
    [Hashtable]$DuoParams = @{}

    If($Name){
        $DuoParams.Add("name",$Name)
    }
    If($Phone){
        $DuoParams.Add("phone",$Phone)
    }
    If($RequirePasswordChange){
        $DuoParams.Add("password_change_required",$RequirePasswordChange)
    }
    If($Role){
        $DuoParams.Add("role",$Role)
    }
    If($RestricedBy_AdminUnits){
        $DuoParams.Add("restricted_by_admin_units",$RestricedBy_AdminUnits)
    }
    If($Status){
        $DuoParams.Add("status",$Status)
    }
    If($TokenID){
        $DuoParams.Add("token_id",$TokenID)
    }
    If($ResetAuthAttempts){
        [String]$Uri = "/admin/v1/admins/$($AdminID)/reset"
    }
    ElseIf($ClearExpiration){
        [String]$Uri = "/admin/v1/admins/$($AdminID)/clear_inactivity"
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

Function Remove-DuoAdmin {
    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [String]$AdminID
    )

    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/admins/$($AdminID)"
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

Function Send-DuoAdminActivationLink {
    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [String]$AdminID
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/admins/$($AdminID)/activation_link/email"
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

Function Remove-DuoAdminActivationLink {
    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [String]$AdminID
    )

    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/admins/$($AdminID)"
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

Function New-DuoAdminActivationLink {
    PARAM(
        [Parameter(ParameterSetName="Existing",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [String]$AdminID,
        [Parameter(ParameterSetName="New",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [String]$Email,
        [Parameter(ParameterSetName="New",
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=1
            )]
            [String]$Name,
        [Parameter(ParameterSetName="New",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [String]$Role,
        [Parameter(ParameterSetName="New",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [Switch]$SendEmail,
        [Parameter(ParameterSetName="New",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [Int]$Valid_Days
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/admins/activations"
    [Hashtable]$DuoParams = @{}

    If($AdminID){
        [String]$Uri = "/admin/v1/admins/$($AdminID)/activation_link"
    }
    Else{
        [String]$Uri = "/admin/v1/admins/activations"
        $DuoParams.Add("email",$Email)
        If($Name){
            $DuoParams.Add("admin_name",$Name)
        }
        If($Role){
            $DuoParams.Add("admin_role",$Role)
        }
        If($SendEmail){
            $DuoParams.Add("send_email",1)
        }
        Else{
            $DuoParams.Add("send_email",0)
        }
        If($Valid_Days){
            $DuoParams.Add("valid_days",$Valid_Days)
        }
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

Function Get-DuoAdminActivationLink {
    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/admins/activations"
    [Hashtable]$DuoParams = @{}

    
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

Function Remove-DuoPendingActivation {
    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [String]$ActivationID
    )

    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/admins/activations/$($ActivationID)"
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

Function Sync-DuoAdmin {
    PARAM(
        [Parameter(ParameterSetName="Name",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [String]$DirectoryName,
        [Parameter(ParameterSetName="Key",
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [String]$DirectoryKey,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=1
            )]
            [String]$Email
    )
    
    If($DirectoryName){
        $DirectoryKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR((Get-DuoDirectoryKey -DirectoryName $DirectoryName)))
    }

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/admins/directorysync/$($DirectoryKey)/syncadmin"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("email",$Email)

    
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

Function Get-DuoAdminExternalPwManagement {
    PARAM(
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [String]$AdminID
    )

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/admins/password_mgmt"
    [Hashtable]$DuoParams = @{}

    If($AdminID){    
        $Uri = "/admin/v1/admins/$($AdminID)/password_mgmt"
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

Function Set-DuoAdminExternalPwManagement {
    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [String]$AdminID,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=1
            )]
            [String]$Password,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=1
            )]
            [Bool]$ExternalPassword_Mgmt
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/admins/$($AdminID)/password_mgmt"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("has_external_password_mgmt",$true)
    $DuoParams.Add("password",$Password)

    
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

Function Get-DuoAuthFactors {
    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/admins/allowed_auth_methods"
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

Function Set-DuoAuthFactors {
    PARAM(
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [Bool]$HardwareToken,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [Bool]$MobileOTP,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [Bool]$Push,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [Bool]$SMS,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [Bool]$Voice,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [Bool]$WebAuthN,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [Bool]$YubiKey
    )
    If($HardwareToken -or $MobileOTP -or $Push -or $SMS -or $Voice -or $WebAuthN -or $YubiKey){

    }
    Else{
        #Write-Host "You must include at least one option." -ForegroundColor Red -BackgroundColor Black
    }

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/admins/allowed_auth_methods"
    [Hashtable]$DuoParams = @{}

    If($HardwareToken){
        $DuoParams.Add("hardware_token_enabled",$HardwareToken)
    }
    If($MobileOTP){
        $DuoParams.Add("mobile_opt_enabled",$MobileOTP)
    }
    If($Push){
        $DuoParams.Add("push_enabled",$Push)
    }
    If($SMS){
        $DuoParams.Add("sms_enabled",$SMS)
    }
    If($Voice){
        $DuoParams.Add("voice_enabled",$Voice)
    }
    If($WebAuthN){
        $DuoParams.Add("webauthn_enabled",$WebAuthN)
    }
    If($YubiKey){
        $DuoParams.Add("yubikey_enabled",$YubiKey)
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