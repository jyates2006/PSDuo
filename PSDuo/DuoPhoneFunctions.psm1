Function Get-DuoPhone{

    [CmdletBinding(DefaultParameterSetName="Name")]
    Param(
        [Parameter(ParameterSetName="Name",
            Mandatory=$false,
            Position=0
        )]
            [String]$Name,
        [Parameter(ParameterSetName="ID",
            Mandatory=$false,
            Position=0
        )]
            [String]$PhoneID,
        [Parameter(ParameterSetName="Number",
            Mandatory=$false,
            Position=0
        )]
            [String]$Number,
        [Parameter(ParameterSetName="Number",
            Mandatory=$false,
            Position=1
        )]
            [String]$Extension
    )
    
    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/phones"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("limit","500")
    $DuoParams.Add("offset","0")
    $Offset = 0

    #Duo has a 500 phone limit in their api. Loop to return all phones
    $AllPhones = Do{
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
            #Increment offset to return the next 500 phones
            $Offset += 500
        }
    }Until($Output.Count -lt 500)

    If($Name){
        $AllPhones | Where-Object Name -EQ $Name
    }
    ElseIf($PhoneID){
        $AllPhones | Where-Object Phone_ID -EQ $PhoneID
    }
    ElseIF($Number -and $Extension){
        $AllPhones | Where-Object ($_.Number -eq $Number -and $_.Extension -eq $Extension)
    }
    ElseIf($Number){
        $AllPhones | Where-Object Number -EQ $Number
    }
    ElseIf($Extension){
        $AllPhones | Where-Object Extension -EQ $Extension
    }
    Else{
        $AllPhones
    }
}

Function New-DuoPhone{

    Param(
        [Parameter(Mandatory=$false)]
            [String]$Name,
        [Parameter(Mandatory=$false)]
        [ValidateScript({
            If(Test-DuoPhone -Number $_){Throw "Number is already in use"}
            Else{$true}
        })]
            [String]$Number,
        [Parameter(ParameterSetName="Ext",
            Mandatory=$false)]
            [String]$Extension,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Mobile","Landline","Unknown")]
            [String]$Type,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Google Android","Apple ios","Windows Mobile","Palm WebOS","Java j2me","Generic SmartPhone","Rim Blackberry","Symbian OS")]
            [String]$Platform,
        [Parameter(ParameterSetName="Ext",
            Mandatory=$false)]
            [Int]$Predelay,
        [Parameter(ParameterSetName="Ext",
            Mandatory=$false)]
            [Int]$PostDelay
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/phones"
    [Hashtable]$DuoParams = @{}

    If($Name){
        $DuoParams.Add("name",$Name)
    }
    If($Number){
        $DuoParams.Add("number",$Number)
    }
    If($Extension){
        $DuoParams.Add("extension",$Extension)
    }
    If($Type){
        $DuoParams.Add("type",$type.ToLower())
    }
    If($Platform){
        $DuoParams.Add("Platform",$Platform.ToLower())
    }
    If($Predelay){
        $DuoParams.Add("predelay",$Predelay)
    }
    If($PostDelay){
        $DuoParams.Add("postdelay",$PostDelay)
    }

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
    }
}

Function Set-DuoPhone{

    [CmdletBinding(DefaultParameterSetName="None")]
    Param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoPhone -PhoneID $_){$true}
            Else{Throw "Invalid ID"}
        })]
            [String]$PhoneID,
        [Parameter(Mandatory=$false)]
            [String]$Name,
        [Parameter(Mandatory=$false)]
            [String]$Number,
        [Parameter(ParameterSetName="Ext",
            Mandatory=$false)]
            [String]$Extension,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Mobile","Landline","Unknown")]
            [String]$Type,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Google Android","Apple ios","Windows Mobile","Palm WebOS","Java j2me","Generic SmartPhone","Rim Blackberry","Symbian OS")]
            [String]$Platform,
        [Parameter(ParameterSetName="Ext",
            Mandatory=$false)]
            [Int]$Predelay,
        [Parameter(ParameterSetName="Ext",
            Mandatory=$false)]
            [Int]$PostDelay
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/phones/$($PhoneID)"
    [Hashtable]$DuoParams = @{}
    
    If($Name){
        $DuoParams.Add("name",$Name)
    }
    If($Number){
        $DuoParams.Add("number",$Number)
    }
    If($Extension){
        $DuoParams.Add("extension",$Extension)
    }
    If($Type){
        $DuoParams.Add("type",$type.ToLower())
    }
    If($Platform){
        $DuoParams.Add("Platform",$Platform.ToLower())
    }
    If($Predelay){
        $DuoParams.Add("predelay",$Predelay)
    }
    If($PostDelay){
        $DuoParams.Add("postdelay",$PostDelay)
    }

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
    }
}

Function Remove-DuoPhone{

    Param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoPhone -PhoneID $_){$true}
            Else{Throw "Invalid ID"}
        })]
            [String]$PhoneID
    )

    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/phones/$($PhoneID)"
    [Hashtable]$DuoParams = @{}

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
    }
}

Function New-DuoMobileActivation{

    [CmdletBinding(DefaultParameterSetName="None")]
    Param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoPhone -PhoneID $_){$true}
            Else{Throw "Invalid ID"}
        })]
            [String]$PhoneID,

        [Parameter(ParameterSetName="DateTime",
            Mandatory=$false
        )]
        [Parameter(ParameterSetName="Seconds",
            Mandatory=$false
        )]
            [DateTime]$ExpirationDate,
        [Parameter(ParameterSetName="Seconds",
            Mandatory=$false
        )]
            [Int]$TimeToExpire,

        [Parameter(Mandatory=$false)]
            [Switch]$Install,
        [Parameter(ParameterSetName="Send",
            Mandatory=$false
        )]
        [Parameter(ParameterSetName="Seconds",
            Mandatory=$false
        )]
            [Switch]$SendSMS,

        [Parameter(ParameterSetName="Send",
            Mandatory=$true
        )]
        [Parameter(ParameterSetName="Seconds",
            Mandatory=$false
        )]
            [String]$Activation_Message,
        [Parameter(ParameterSetName="Send",
            Mandatory=$false
        )]
        [Parameter(ParameterSetName="Seconds",
            Mandatory=$false
        )]
            [String]$Installation_Message
    )

    If($ExpirationDate){
        $TimeToExpire = [Math]::Round(($ExpirationDate - (Get-Date)).TotalSeconds)
    }
    ElseIf($TimeToExpire){
        $ExpireTime = $TimeToExpire
    }
    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/phones/$($PhoneID)/activation_url"
    [Hashtable]$DuoParams = @{}
    
    If($Install){
        $DuoParams.Add("install","1")
    }
    If($ExpireTime){
        $DuoParams.Add("valid_secs",$ExpireTime)
    }

    If($SendSMS){
        #Base claim
        [String]$Uri = "/admin/v1/phones/$($PhoneID)/send_sms_activation_url"
        If($Activation_Message){
            $DuoParams.Add("activation_msg",$Activation_Message)
        }
        If($Installation_Message){
            $DuoParams.Add("installation_msg",$Installation_Message)
        }
    }

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
    }
}
