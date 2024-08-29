Function Get-DuoAdminUnit {
    PARAM(
        [Parameter(ParameterSetName="AUDetails",
            Mandatory = $false,
            ValueFromPipeLine = $true
            )]
            [String]$AdminUnitID,
        [Parameter(ParameterSetName="AID",
            Mandatory = $false,
            ValueFromPipeLine = $true
            )]
            [String]$AdminID,
        [Parameter(ParameterSetName="GID",
            Mandatory = $false,
            ValueFromPipeLine = $true
            )]
            [String]$GroupID,
        [Parameter(ParameterSetName="iKey",
            Mandatory = $false,
            ValueFromPipeLine = $true
            )]
            [String]$IntegrationKey
    )    

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/administrative_units"
    [Hashtable]$DuoParams = @{}

    If($AdminUnitID){
        [String]$Uri = "/admin/v1/adminstrative_units/$($AdminUnitID)"
    }
    ElseIf($AdminID){
        $DuoParams.Add("admni_id",$AdminID)
    }
    ElseIf($GroupID){
        $DuoParams.Add("GroupID",$GroupID)
    }
    ElseIf($IntegrationKey){
        $DuoParams.Add("integration_key",$IntegrationKey)
    }

    $DuoParams.Add("limit","300")
    $DuoParams.Add("offset","0")
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

Function New-DuoAdminUnit {
    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $true,
            Position=0
            )]
            [String]$Name,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $true,
            Position=1
            )]
            [String]$Description,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $true,
            Position=2
            )]
            [Bool]$RestrictByGroups,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $true,
            Position=3
            )]
            [Bool]$RestrictByIntegrations,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $true,
            Position=4
            )]
            [String]$AdminIDs,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $true,
            Position=5
            )]
            [String]$GroupIDs,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $true,
            Position=6
            )]
            [String]$IntegrationKeys
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/administrative_units"
    [Hashtable]$DuoParams = @{}

    $DuoParams.Add("name",$Name)
    $DuoParams.Add("description",$Description)
    $DuoParams.Add("restrict_by_groups",$RestrictByGroups)
    If($RestrictByIntegrations){
        $DuoParams.Add("restrict_by_integrations",$RestrictByIntegrations)
    }
    If($AdminIDs){
        $DuoParams.Add("admins",$AdminIDs)
    }
    If($IntegrationKeys){
        $DuoParams.Add("integrations",$IntegrationKeys)
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

Function Set-DuoAdminUnit {
    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $true,
            Position=0
            )]
            [String]$AdminUnitID,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=1
            )]
            [String]$Name,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=2
            )]
            [String]$Description,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false,
            Position=3
            )]
            [Bool]$RestrictByGroups,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=4
            )]
            [Bool]$RestrictByIntegrations,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=4
            )]
            [String]$AdminIDs,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=5
            )]
            [String]$GroupIDs,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=6
            )]
            [String]$IntegrationKeys
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/administrative_units/$($AdminUnitID)"
    [Hashtable]$DuoParams = @{}

    $DuoParams.Add("name",$Name)
    $DuoParams.Add("description",$Description)
    $DuoParams.Add("restrict_by_groups",$RestrictByGroups)
    If($RestrictByIntegrations){
        $DuoParams.Add("restrict_by_integrations",$RestrictByIntegrations)
    }
    If($AdminIDs){
        $DuoParams.Add("admins",$AdminIDs)
    }
    If($IntegrationKeys){
        $DuoParams.Add("integrations",$IntegrationKeys)
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

Function Add-DuoAdminUnitMember {
    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $true
        )]
        [String]$AdminUnitID,

        [Parameter(ParameterSetName="AID",
            Mandatory = $true,
            ValueFromPipeLine = $false
        )]
        [String]$AdminID,

        [Parameter(ParameterSetName="GID",
            Mandatory = $true,
            ValueFromPipeLine = $false
        )]
        [String]$GroupID,

        [Parameter(ParameterSetName="IKey",
            Mandatory = $true,
            ValueFromPipeLine = $false
        )]
        [String]$IntegrationKey
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/administrative_units/$($AdminUnitID)"
    [Hashtable]$DuoParams = @{}

    If($AdminID){
        [String]$Uri = "/admin/v1/administrative_units/$($AdminUnitID)/admin/$($AdminID)"
    }
    ElseIf($GroupID){
        [String]$Uri = "/admin/v1/administrative_units/$($AdminUnitID)/group/$($GroupID)"
    }
    ElseIf($IntegrationKey){
        [String]$Uri = "/admin/v1/administrative_units/$($AdminUnitID)/integration/$($IntegrationKey)"
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

Function Remove-DuoAdminUnitMember {
    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $true
        )]
        [String]$AdminUnitID,

        [Parameter(ParameterSetName="AID",
            Mandatory = $true,
            ValueFromPipeLine = $false
        )]
        [String]$AdminID,

        [Parameter(ParameterSetName="GID",
            Mandatory = $true,
            ValueFromPipeLine = $false
        )]
        [String]$GroupID,

        [Parameter(ParameterSetName="IKey",
            Mandatory = $true,
            ValueFromPipeLine = $false
        )]
        [String]$IntegrationKey
    )

    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/administrative_units/$($AdminUnitID)"
    [Hashtable]$DuoParams = @{}

    If($AdminID){
        [String]$Uri = "/admin/v1/administrative_units/$($AdminUnitID)/admin/$($AdminID)"
    }
    ElseIf($GroupID){
        [String]$Uri = "/admin/v1/administrative_units/$($AdminUnitID)/group/$($GroupID)"
    }
    ElseIf($IntegrationKey){
        [String]$Uri = "/admin/v1/administrative_units/$($AdminUnitID)/integration/$($IntegrationKey)"
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

Function Remove-DuoAdminUnit {
    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $true
        )]
        [String]$AdminUnitID
    )

    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/administrative_units/$($AdminUnitID)"
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

Function Get-DuoLog {
    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $false
        )]
        
        [String]$Log,

        [Parameter(ParameterSetName="Unix",
            Mandatory = $false,
            ValueFromPipeLine = $True
        )]
        [INT]$Since
    )

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/logs"
    [Hashtable]$DuoParams = @{}

    Switch($Log){
        "Authentication" {
            [String]$Uri = "/admin/v1/logs/authentication"
        }
        "Administrator" {
            [String]$Uri = "/admin/v1/logs/administrator"
        }
        "Telephony" {
            [String]$Uri = "/admin/v1/logs/telephony"
        }
        "OfflineEnrollment" {
            [String]$Uri = "/admin/v1/logs/offline_enrollment"
        }
    }

    If($Since){
        $DuoParams.Add("mintime",$Since)
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

Function Get-DuoTrustMonitor {
    PARAM(
        [Parameter(ParameterSetName="Unix",
            Mandatory = $true,
            ValueFromPipeLine = $false
        )]
        [INT]$MinTime,

        [Parameter(ParameterSetName="Unix",
            Mandatory = $true,
            ValueFromPipeLine = $false
        )]
        [INT]$MaxTime,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$Type
    )

    $Offset = 0

    #Duo has a 200 Trust Monitor limit in their api. Loop to return all events
    Do{
        #Base claim
        [String]$Method = "GET"
        [String]$Uri = "/admin/v1/trust_monitor/events"
        [Hashtable]$DuoParams = @{}
        $DuoParams.Offset = $Offset

        $DuoParams.Add("mintime",$MinTime)
        $DuoParams.Add("maxtime",$MaxTime)
        If($Type){
            $DuoParams.Add("type",$Type)
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
            #Increment offset to return the next 300 users
            $Offset += 200
        }
    }Until($Output.Count -lt 300)
}

Function Get-DuoSetting {
    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/settings"
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

Function Set-DuoSetting {
    PARAM(
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$CallerID,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$MobileOTP_Type,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$EmailActivityNotification,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$Enrollment_UniverseralPrompt,
        
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$FraudEmail,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$EnableFraudEmail,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$EnforceGlobalSS_Policy,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$HelpDesk_Bypass,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$BypassExpiration,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$AllowHelpDesk_SendEnrollment,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Int]$Inactive_Expiration,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$KeyPressConfirm,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$KeyPressFraud,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$Language,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Int]$LockDuration,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Int]$LockoutThreshold,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Int]$LogRetention,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$MinPasswordLength,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$EnableMobleOTP,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$Name,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$PassRequiresLowerAlpha,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$PassRequiresNumeric,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$PassRequiresSpecial,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$PassRequiresUpperAlpha,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$EnableActivityNofication,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Int]$SMS_BatchSize,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Int]$SMS_Expiration,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$SMS_Message,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Int]$SMS_Refresh,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Int]$Telephony_Warning,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$Timezone,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$EnableU2F,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Int]$Unenrolled_LockoutThreshold,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$Allow_UserManagersBypass,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Int]$MaxTelephonyCredit,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$EnableVoice
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/settings"
    [Hashtable]$DuoParams = @{}

    If($CallerID){
        $DuoParams.Add("caller_id",$CallerID)
    }
    If($MobileOTP_Type){
        $DuoParams.Add("duo_mobile_otp_type",$MobileOTP_Type)
    }
    If($EnableMobleOTP){
        $DuoParams.Add("mobile_otp_enabled",$EnableMobleOTP)
    }
    If($EmailActivityNotification){
        $DuoParams.Add("email_activity_notification_enabled",$EmailActivityNotification)
    }
    If($Enrollment_UniverseralPrompt){
        $DuoParams.Add("enrollment_universal_prompt_enabled",$Enrollment_UniverseralPrompt)
    }
    If($FraudEmail){
        $DuoParams.Add("fraud_email",$FraudEmail)
    }
    If($EnableFraudEmail){
        $DuoParams.Add("fraud_email_enabled",$EnableFraudEmail)
    }
    If($EnforceGlobalSS_Policy){
        $DuoParams.Add("global_ssp_policy_enforced",$EnforceGlobalSS_Policy)
    }
    If($HelpDesk_Bypass){
        $DuoParams.Add("helpdesk_bypass",$HelpDesk_Bypass)
    }
    If($BypassExpiration){
        $DuoParams.Add("helpdesk_bypass_expiration",$BypassExpiration)
    }
    If($AllowHelpDesk_SendEnrollment){
        $DuoParams.Add("helpdesk_can_send_enroll_email",$AllowHelpDesk_SendEnrollment)
    }
    If($Inactive_Expiration){
        $DuoParams.Add("inactive_user_expiration",$Inactive_Expiration)
    }
    If($KeyPressConfirm){
        $DuoParams.Add("keypress_confirm",$KeyPressConfirm)
    }
    If($KeyPressFraud){
        $DuoParams.Add("keypress_fraud",$KeyPressFraud)
    }
    If($Language){
        $DuoParams.Add("language",$Language)
    }
    If($LockDuration){
        $DuoParams.Add("lockout_expire_duration",$LockDuration)
    }
    If($LockoutThreshold){
        $DuoParams.Add("lockout_threshold",$LockoutThreshold)
    }
    If($LogRetention){
        $DuoParams.Add("log_retention_days",$LogRetention)
    }
    If($MinPasswordLength){
        $DuoParams.Add("minimum_password_length",$MinPasswordLength)
    }
    If($Name){
        $DuoParams.Add("name",$Name)
    }
    If($PassRequiresLowerAlpha){
        $DuoParams.Add("password_requires_lower_alpha",$PassRequiresLowerAlpha)
    }
    If($PassRequiresNumeric){
        $DuoParams.Add("password_requires_numeric",$PassRequiresNumeric)
    }
    If($PassRequiresSpecial){
        $DuoParams.Add("password_requires_special",$PassRequiresSpecial)
    }
    If($EnableActivityNofication){
        $DuoParams.Add("push_activity_notification_enabled",$EnableActivityNofication)
    }
    If($SMS_BatchSize){
        $DuoParams.Add("sms_batch",$SMS_BatchSize)
    }
    If($SMS_Expiration){
        $DuoParams.Add("sms_expiration",$SMS_Expiration)
    }
    If($SMS_Message){
        $DuoParams.Add("sms_message",$SMS_Message)
    }
    If($SMS_Refresh){
        $DuoParams.Add("sms_refresh",$SMS_Refresh)
    }
    If($Telephony_Warning){
        $DuoParams.Add("telephony_warning_min",$Telephony_Warning)
    }
    If($Timezone){
        $DuoParams.Add("timezone",$Timezone)
    }
    If($Unenrolled_LockoutThreshold){
        $DuoParams.Add("unenrolled_user_lockout_threshold",$Unenrolled_LockoutThreshold)
    }
    If($Allow_UserManagersBypass){
        $DuoParams.Add("user_managers_can_put_users_in_bypass",$Allow_UserManagersBypass)
    }
    If($MaxTelephonyCredit){
        $DuoParams.Add("user_telephony_cost_max",$MaxTelephonyCredit)
    }
    If($EnableVoice){
        $DuoParams.Add("voice_enabled",$EnableVoice)
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

Function Get-DuoLogo {
    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/logo"
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

Function Set-DuoLogo {
    PARAM(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $true
        )]
        [String]$ImagePath
    )

    $Logo = (Get-Base64Image -ImagePath $ImagePath).Base64String

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/logo"
    [Hashtable]$DuoParams = @{}

    $DuoParams.Add("logo",$Logo)

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

Function Remove-DuoLogo {
    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/logo"
    [Hashtable]$DuoParams = @{}

    $DuoParams.Add("logo",$Logo)

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

Function Get-DuoBranding {
    PARAM(
        [Parameter(ParameterSetName="Live",
            Mandatory = $true,
            ValueFromPipeLine = $true
        )]
        [Switch]$Live,
        
        [Parameter(ParameterSetName="Draft",
            Mandatory = $true,
            ValueFromPipeLine = $true
        )]
        [Switch]$Draft
    )
    
    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/"
    [Hashtable]$DuoParams = @{}

    If($Live){
        [String]$Uri = "/admin/v1/branding"
    }
    ElseIf($Draft){
        [String]$Uri = "/admin/v1/branding/draft"
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

Function Set-DuoBranding {
    PARAM(
        [Parameter(ParameterSetName="Live",
            Mandatory = $true,
            ValueFromPipeLine = $true
        )]
        [Switch]$Live,
        
        [Parameter(ParameterSetName="Draft",
            Mandatory = $true,
            ValueFromPipeLine = $true
        )]
        [Switch]$Draft,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$background_img,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$CardAccentColor,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$Logo,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$BackgroundColor,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [Bool]$PowerdByDuo,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$UsernameLabel,

        [Parameter(ParameterSetName="Draft",
            Mandatory = $false,
            ValueFromPipeLine = $false
        )]
        [String]$UserID,

        [Parameter(ParameterSetName="Draft",
            Mandatory = $true,
            ValueFromPipeLine = $true
        )]
        [Switch]$Publish
    )
    
    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/"
    [Hashtable]$DuoParams = @{}

    If($Live){
        [String]$Uri = "/admin/v1/branding"
    }
    ElseIf($Draft){
        [String]$Uri = "/admin/v1/branding/draft"
    }
    If($background_img){
        $BkgImg = (Get-Base64Image -ImagePath $background_img).Base64String
        $DuoParams.Add("background_img",$BkgImg)
    }
    If($CardAccentColor){
        $DuoParams.Add("card_accent_color",$CardAccentColor)
    }
    If($Logo){
        $LogoImg = (Get-Base64Image -ImagePath $Logo).Base64String
        $DuoParams.Add("logo",$LogoImg)
    }
    If($BackgroundColor){
        $DuoParams.Add("page_background_color",$BackgroundColor)
    }
    If($PowerdByDuo){
        $DuoParams.Add("powered_by_duo",$PowerdByDuo)
    }
    If($UsernameLabel){
        $DuoParams.Add("sso_custom_username_label",$UsernameLabel)
    }
    If($UserID){
        $DuoParams.Add("user_ids",$UserID)
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

Function Add-DuoDraftMember {
    PARAM(
        [String]$UserID
    )
    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/branding/draft/users/$($UserID)"
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

Function Remove-DuoDraftMember {
    PARAM(
        [String]$UserID
    )
    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/branding/draft/users/$($UserID)"
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

Function Get-DuoCustomMessaging {
    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/branding/custom_messaging"
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

Function Set-DuoCustomMessaging {
    PARAM(
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [String]$HelpLinks,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [String]$HelpText,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeLine = $false
            )]
            [String]$locale
    )
       
    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/branding/custom_messaging"
    [Hashtable]$DuoParams = @{}

    If($HelpLinks){
        $DuoParams.Add("help_links",$HelpLinks)
    }
    If($HelpText){
        $DuoParams.Add("help_text",$HelpText)
        $DuoParams.Add("locale",$locale)
    }
    ElseIf($locale){
        $DuoParams.Add("locale",$locale)
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

Function Get-DuoAccount {
    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/info/summary"
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

Function Get-DuoReport {
    PARAM(
        [String]$Report,
        [Int]$MinTime,
        [Int]$MaxTime,
        [Int]$CreditsUsed
    )

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/info/"
    [Hashtable]$DuoParams = @{}

    Switch($Report){
        "TelephonyCredits" {
            [String]$Uri = "/admin/v1/info/telephony_credits_used"
        }
        "AuthenticationAttempts" {
            [String]$Uri = "/admin/v1/info/authentication_attempts"
        }
        "UsersWithAuthAttempts" {
            [String]$Uri = "/admin/v1/info/user_authentication_attempts"
        }
    }

    If($MinTime){
        $DuoParams.Add("mintime",$MinTime)
    }
    If($MaxTime){
        $DuoParams.Add("maxtime",$MaxTime)
    }
    If($Report -eq "TelephonyCredits" -and $CreditsUsed){
        $DuoParams.Add("telephony_credits_used",$CreditsUsed)
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