Function New-DuoConfig{
<#
.Synopsis
    DUO REST API Configuration
.DESCRIPTION
    Sets the default configuration for PSDUO with and option to save it.
.EXAMPLE
    New-DUOConfig -IntergrationKey SDFJASKLDFJASLKDJ -SecretKey ASDKLFJSM<NVCIWJRFKSDM<>SMVNFNSKLF -apiHost api-###XXX###.duosecurity.com
    Generate a module scoped variable for DUO's REST API
.EXAMPLE
   New-DUOConfig -IntergrationKey SDFJASKLDFJASLKDJ -SecretKey ASDKLFJSM<NVCIWJRFKSDM<>SMVNFNSKLF -apiHost api-###XXX###.duosecurity.com -SaveConfig -Path C:\Duo\DuoConfig.xml
    Generates the global variable for DUO's REST API
.OUTPUTS
    [PSCustomObject]$DuoConfig
.NOTES
   
.COMPONENT
    PSDuo
#>
    [CmdLetBinding(DefaultParameterSetName="None")]   
    Param(
        [Parameter(Position=0,Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$IntergrationKey,

        [Parameter(Position=1,Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$SecretKey,
        
        [Parameter(Position=2,Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$apiHost,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String[]]$DirectoryKeys,

        [Parameter(ParameterSetName='SaveConfig',Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [Switch]$SaveConfig,

        [Parameter(ParameterSetName='SaveConfig',Mandatory = $true)]
        [ValidateScript({
            If(Test-Path (Split-Path -Path $_ -Parent)){$true}
            Else{throw "Path $_ is not valid"}
        })]
        [String]$Path
        )

    $iKey = $IntergrationKey | ConvertTo-SecureString -AsPlainText -Force
    $sKey = $SecretKey | ConvertTo-SecureString -AsPlainText -Force
    $DuoAPIHost = $apiHost | ConvertTo-SecureString -AsPlainText -Force

    $DuoConfig = @{}
    $DuoConfig.Add("IntergrationKey",$iKey)
    $DuoConfig.Add("SecretKey", $sKey)
    $DuoConfig.Add("ApiHost", $DuoAPIHost)
    
    If($DirectoryKeys){
        $i = 0
        ForEach($DirectoryKey in $DirectoryKeys){
            $i+1
            $DirectoryKey = $DirectoryKey | ConvertToSecureString -AsPlainText -Force
            $DuoConfig.Add("DirectoryKey$($i)",$DirectoryKey)
        }
    }

    If($SaveConfig){
        $DuoConfig.Add("Config",$Path)
        $DuoConfig | Export-Clixml -Path $Path
    }
    $Script:DuoConfig = $DuoConfig
}

Function Add-DuoDirectoryKeys{
    [CmdLetBinding(DefaultParameterSetName="None")]   
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
            [String]$KeyName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
            [String]$KeyValue,
        [Parameter(ParameterSetName="Save",Mandatory = $false)]
            [Switch]$SaveConfig,
        [Parameter(ParameterSetName="Save",Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            If(Test-Path (Split-Path -Path $_ -Parent)){$true}
            Else{throw "Path $_ is not valid"}
        })]
        [String]$Path
    )

    $dKey = $KeyValue | ConvertTo-SecureString -AsPlainText -Force
    $Script:DuoConfig.Add($KeyName,$dKey)

    If($SaveConfig -and $Path){
        #If(Test-Path $Script:DuoConfig){
        #    $Path = $Script:DuoConfig.Config
        #}
        #Else{
        #    Write-Warning "Running Config is not saved."
        #    $Path = Read-Host "Please enter desired save path."
        #}
        Try{
            $DuoConfig = $Script:DuoConfig
            $DuoConfig | Export-Clixml -Path $Path
        }
        Catch{
            Write-Error "Invalid entry"
        }
    }
}

Function Get-DuoDirectoryNames{
    $DuoConfig = Get-DuoConfig
    $IgnoreValues = @("apiHost","SecretKey","IntergrationKey")
    $Output = $DuoConfig.GetEnumerator() | Where-Object Name -NotIn $IgnoreValues
    $Output.Name
}

Function Import-DuoConfig {
<#
.Synopsis
   DUO REST API Configuration Import
.DESCRIPTION
   Imports a previously saved Duo Configuration
.EXAMPLE
    Import-DuoConfig -Path C:\Duo\DuoConfig.xml
    Generate a module scoped variable for DUO's REST API
.OUTPUTS
    [PSCustomObject]$DuoConfig
.NOTES
   
.COMPONENT
    PSDuo
.ROLE
   
.FUNCTIONALITY
   
#>
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
        If(Test-Path $_){$true}
            Else{throw "Path $_ is not valid"}
        })]
        [String]$Path
    )
    $Imported = Import-Clixml -Path $Path
    $DuoConfig.apiHost = $Imported.apiHost
    
    $Script:DuoConfig = $DuoConfig
    $DuoConfig
}

#Get Duo Config
Function Get-DuoConfig {
<#
.Synopsis
   Return the DUO REST API Configuration Settings
.DESCRIPTION
   Gets the default configuration for PSDUO.
.EXAMPLE
   Get-DuoConfig 
   Returns the Config for the current DUO Session.
.OUTPUTS
   [PSCustomObject]$DuoConfig
.NOTES
   
.COMPONENT
   PSDuo
.ROLE
   
.FUNCTIONALITY
   
#>
    [CmdletBinding(
    )]
    PARAM()
    If(!($Script:DuoConfig)){
        Write-Warning "Please set up a DUO Configuration via New-DuoConfig cmdlet"
    }
    Write-Output $Script:DuoConfig
}

#Test Duo Connection
Function Test-DuoConnection {
<#
.Synopsis
   Ping Duo Endpoints
.DESCRIPTION
    The /ping endpoint acts as a "liveness check" that can be called to verify that Duo is up before 
    trying to call other endpoints. Unlike the other endpoints, this one does not have to be signed 
    with the Authorization header.
.EXAMPLE
    Get-DuoUser
.EXAMPLE
    Test-DuoConnection
.INPUTS

.OUTPUTS
   [PSCustomObject]DuoRequest
.NOTES
    DUO API 
        Method GET 
        Path /auth/v2/ping
    PARAMETERS
        None
    RESPONSE CODES
        Response	Meaning
        200	        Success.
    RESPONSE FORMAT
        Key         Value
        time        Current server time. Formatted as a UNIX timestamp Int.
.COMPONENT
   DUO Auth
.FUNCTIONALITY
   Sends a webrequest to DUO, verifying the service is available. 
#>
    [CmdletBinding(
    )]
    PARAM()

    [String]$method = "GET"
    [String]$path = "/auth/v2/ping"
    $apiHost = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Script:DuoConfig.apiHost))
    
    $DUORestRequest = @{
        URI         = ('Https://{0}{1}' -f $apiHost, $path)
        Method      = $method
        ContentType = 'application/x-www-form-urlencoded'
    }
    
    $Response = Invoke-RestMethod @DUORestRequest
    If($Response.stat -ne 'OK'){
        Write-Warning 'DUO REST Call Failed'
        Write-Warning "APiParams:"+($APiParams | Out-String)
        Write-Warning "Method:$method    Path:$path"
    }   
    #$Output = $Response | Select-Object -ExpandProperty Response 
    #Write-Output $Output
    Write-Output "Successfully connected"

    Try{
        $DuoUsers = Get-DuoUser
    }
    Catch{
        Write-Warning "User Check: Failed"
        Write-Warning "Cannot pull user information"
    }
    Finally{
        If($DuoUsers.Count -gt 1){
            Write-Output "User Check: Passed"
        }
    }
}

Function Test-DuoUser {
<#
.Synopsis
    Validates if a user exist in Duo
.DESCRIPTION
    Test if user exist within Duo
.EXAMPLE
    Test-DuoUser -Username TestUser
.EXAMPLE
    Test-DuoUser -UserID ABCDEF12G34567HIJKLM
.INPUTS

.OUTPUTS
    [bool]$true/$false
.NOTES

.COMPONENT

.FUNCTIONALITY
    Time conversion
#>
    [CmdletBinding(DefaultParameterSetName="Uname")]
    Param(
        [Parameter(
            ParameterSetName="Uname",
            Mandatory=$true
            )]
                $UserName,
        [Parameter(
            ParameterSetName="UID",
            Mandatory=$true
            )]
                $UserID
    )
    	#Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/users"
    [Hashtable]$DuoParams = @{}
    
    If($UserName){
        $DuoParams.Add("username",$UserName)
    }
    elseif ($UserID) {
        $Uri = "/admin/v1/users/user_id"
    }

    Try{
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
            Return $true
        }
    }
    Catch{
        Return $false
    }
}

Function Test-DuoGroup {
    [CmdletBinding(DefaultParameterSetName="Gname")]
    Param(
        [Parameter(
            ParameterSetName="Gname",
            Mandatory=$true,
            ValueFromPipelin=$true,
            Position=0
            )]
                $GroupName,
        [Parameter(
            ParameterSetName="GID",
            Mandatory=$true,
            ValueFromPipelin=$true,
            Position=0
            )]
                $GroupID
    )
   
    If($GroupID){
        	#Base claim
        [String]$Method = "GET"
        [String]$Uri = "/admin/v1/groups/$($GroupID)"
        [Hashtable]$DuoParams = @{}

        Try {
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
                Return $true
            }
        }
        Catch {
            Return $false
        }
    }
    ElseIF($GroupName){
        Try{
            Get-DuoGroup -GroupName $GroupName | Out-Null
            Return $true
        }
        Catch{
            Return $false
        }
    }
}

Function Test-DuoPhone {
    Param(
        [String]$Name,
        [String]$PhoneID,
        [String]$Number,
        [String]$Extension
    )

        #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/phones"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("limit","500")
    $DuoParams.Add("offset","0")
    $Offset = 0

        #Duo has a 300 user limit in their api. Loop to return all users
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
                #Increment offset to return the next 300 users
            $Offset += 500
        }
    }Until($Output.Count -lt 500)

    If($Name){
        If(($AllPhones | Where-Object Name -EQ $Name)){
            Return $true
        }
        Else{
            Return $false
        }
    }
    ElseIf($PhoneID){
        If(($AllPhones | Where-Object Phone_ID -EQ $PhoneID)){
            Return $true
        }
        Else{
            Return $false
        }
    }
    ElseIf($Number -and $Extension){
        If(($AllPhones | Where-Object ($_.Number -EQ $Number -and $_.extension -eq $Extension))){
            Return $true
        }
        Else{
            Return $false
        }
    }
    ElseIf($Number){
        If(($AllPhones | Where-Object Number -EQ $Number)){
            Return $true
        }
        Else{
            Return $false
        }
    }
}

Function Test-DuoBypassCode {
    Param(
        [String]$BypassCodeID
    )
        #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/bypass_codes/$($BypassCodeID)"
    [Hashtable]$DuoParams = @{}
    Try{
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
        Return $true
    }
    Catch{
        Return $false
    }
}

Function Test-DuoToken {
    Param(
        [Parameter(Mandatory=$true,
            ValuefromPipeline=$true
        )]
            [String]$Serial
    )

        #Base Claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/tokens/$($TokenID)"
    [Hashtable]$DuoParams = @{}
    
    Try{
        $Request = Create-DuoRequest -UriPath $Uri -Method $Method -Arguments $DuoParams
        $Response = Invoke-RestMethod @Request
        If($Response.stat -ne 'OK'){
            Write-Warning 'DUO REST Call Failed'
            Write-Warning "Arguments:"+($DuoParams | Out-String)
            Write-Warning "Method:$Method    Path:$Uri"
        }   
        Else{
            Return $ture
        }
    }
    Catch{
        Return $false
    }
}

Function Test-DuoWebAuthn {
    Param(
        [Paramter(Mandatory=$true,
            ValuefromPipeline=$true
        )]
            [String]$WebAuthnKey
    )

        #Base Claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/webauthncredentials/$($WebAuthnKey)"
    [Hashtable]$DuoParams = @{}

    Try{
        $Request = Create-DuoRequest -UriPath $Uri -Method $Method -Arguments $DuoParams
        $Response = Invoke-RestMethod @Request
        If($Response.stat -ne 'OK'){
            Write-Warning 'DUO REST Call Failed'
            Write-Warning "Arguments:"+($DuoParams | Out-String)
            Write-Warning "Method:$Method    Path:$Uri"
        }   
        Else{
            Return $true
        }
    }
    Catch{
        Return $false
    }
}