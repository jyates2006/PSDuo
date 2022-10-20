Function Sync-DuoUser{
<#
.SYNOPSIS
    Syncs a user from Duo to from directory within DuO

.DESCRIPTION
     Syncs a user from Duo to from directory

.PARAMETER Username
    Sync user by their Duo username

.PARAMETER UserID
    Sync user by their Duo UserID

.PARAMETER Directory
    The intended directory you wish to sync from

.Parameter Email
    Switch to change username search to email if normalization is on

.OUTPUTS
    [PSCustomObject]DuoRequest

.EXAMPLE
    Sync-DuoUser -Username DuoUser1 -Directory "DuoDirectory"

.EXAMPLE
    Sync-Duouser -Username DuoUser1@Duosecurity.com -Directory "DuoDirectory"

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    Param(
        [Parameter(
            Mandatory=$true,
            ValueFromPipeLine=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserName $_){$true}
            Else{Throw "User: $($_) doesn't exist in Duo"}
        })]
            [String]$Username,
        [Parameter(
            Mandatory=$true,
            Position=1)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            If($_ -In (Get-DuoDirectoryNames)){$true}
            Else{Throw "Directory: $($_) is an invalid entry"}
        })]
            [String]$Directory,
        [Parameter(
            Mandatory=$false,
            Position=2
        )]
            [Switch]$Email
    )
    
    $dKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR((Get-DuoDirectoryKey -DirectoryName $Directory)))
    
    #Base Claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/users/directorysync/$($dKey)/syncuser"
    [Hashtable]$DuoParams = @{}

    #$User = Get-DuoUser -Username $Username
    If($Email){$VerifiedUsername = (Get-Duouser -Username $Username).email}
    Else{$VerifiedUsername = $Username}
    $DuoParams.Add("username",$VerifiedUsername.ToLower())

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

Function Get-DuoUser {
<#
.Synopsis
    Utilizing Duo REST API to return user(s)
.DESCRIPTION
    Returns a list of Duo users or an individual user

.EXAMPLE
    Get-DuoUser
    Returns all users from Duo. Initiates a call for each 300

.EXAMPLE
    Get-UserUser -Username TestUser

.EXAMPLE
    Get-UserUser -UserID ABCDEF12G34567HIJKLM

.OUTPUTS
    [PSCustomObject]$DuoUsers

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    [CmdletBinding(DefaultParameterSetName="Uname")]
    PARAM(
        [Parameter(ParameterSetName="UName",
            Mandatory = $false,
            ValueFromPipeLine = $true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserName $_){$true}
            Else{Throw "User: $($_) doesn't exist in Duo"}
        })]
            [String]$Username,
        [Parameter(ParameterSetName="UID",
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserID $_){$true}
            Else{Throw "User ID: $($_) doesn't exist in Duo"}
        })]
            [String]$UserID
    )

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/users"
    [Hashtable]$DuoParams = @{}

    If($Username){
        $DuoParams.Add("username",$Username.ToLower())
    }
    ElseIf($UserID){    
        $Uri = "/admin/v1/users/$($UserID)"
    }
    Else{
        $DuoParams.Add("limit","300")
        $DuoParams.Add("offset","0")
    }
    $Offset = 0

    #Duo has a 300 user limit in their api. Loop to return all users
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
            #Increment offset to return the next 300 users
            $Offset += 300
        }
    }Until($Output.Count -lt 300)
}

Function New-DuoUser{
<#
.SYNOPSIS
    Creates a new user within Duo with Duo as the source

.DESCRIPTION
     Creates a new user within Duo

.PARAMETER Username
    New user's username

.PARAMETER Alias1
    First alias for the new user

.PARAMETER Alias2
    Second alias for the new user

.PARAMETER Alias3
    Third alias for the new user

.PARAMETER Alias4
    Fourth alias for the new user

.PARAMETER Realname
    The user's realname

.PARAMETER Firstname
    User's first name

.PARAMETER Lastname
    User's last name

.Parameter Email
    User's email address

.Parameter Status
    Status for the account to be created with either Active, Bypass, or Disabled

.Parameter Notes
    Any notes to be included on the Duo account

.OUTPUTS
    [PSCustomObject]DuoRequest

.EXAMPLE
    New-DuoUser -Username DuoUser1

.EXAMPLE
    New-DuoUser -Username DuoUser1 -email DuoUser1@duosecurity.com

.EXAMPLE
    New-DuoUser -UserName DuoUser1 -email DuoUser1@duosecurity.com -alias1 DuoDemo -Status Disabled -Notes "Demo purposes"

.LINK
    https://github.com/jyates2006/PSDuo
    https://jaredyatesit.com/Documentation/PSDuo
#>
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            If(Test-DuoUser -UserName $_){Throw "User: $($_) already exist in Duo"}
            Else{$true}
        })]
            [String]$Username,
        [Parameter(Mandatory=$false)]
            [String]$Alias1,
        [Parameter(Mandatory=$false)]
            [String]$Alias2,
        [Parameter(Mandatory=$false)]
            [String]$Alias3,
        [Parameter(Mandatory=$false)]
            [String]$Alias4,
        [Parameter(Mandatory=$false)]
            [String]$Realname,
        [Parameter(Mandatory=$false)]
            [String]$Firstname,
        [Parameter(Mandatory=$false)]
            [String]$Lastname,
        [Parameter(Mandatory=$false)]
            [String]$Email,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Active","Bypass","Disabled")]
            [String]$Status,
        [Parameter(Mandatory=$false)]
            [String]$Notes
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/users"
    [Hashtable]$DuoParams = @{}

    #Add Username
    $DuoParams.Add("username",$Username.ToLower())

    #Add Optional Parameters
    If($Alias1){$DuoParams.Add("alias1",$Alias1.ToLower())}
    If($Alias2){$DuoParams.Add("alias2",$Alias2.ToLower())}
    If($Alias3){$DuoParams.Add("alias3",$Alias3.ToLower())}
    If($Alias4){$DuoParams.Add("alias4",$Alias4.ToLower())}
    If($Realname){$DuoParams.Add("realname",$Realname)}
    If($Firstname){$DuoParams.Add("firstname",$Firstname)}
    If($Lastname){$DuoParams.Add("lastname",$Lastname)}
    If($Email){$DuoParams.Add("email",$Email.ToLower())}
    If($Status){$DuoParams.Add("status",$Status.ToLower())}
    If($Notes){$DuoParams.Add("notes",$Notes)}

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

Function Set-DuoUser{

    Param(
        [Parameter(
            Mandatory=$true,
            ValueFromPipleLine=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserID $_){$true}
            Else{Throw "User ID: $($_) doesn't exist within Duo"}
        })]
            [String]$UserID,
        [Parameter(
            Mandatory=$false,
            ValueFromPipleLine=$true,
            Position=1
        )]
            [String]$Username,
        [Parameter(Mandatory=$false)]
            [String]$Alias1,
        [Parameter(Mandatory=$false)]
            [String]$Alias2,
        [Parameter(Mandatory=$false)]
            [String]$Alias3,
        [Parameter(Mandatory=$false)]
            [String]$Alias4,
        [Parameter(Mandatory=$false)]
            [String]$RealName,
        [Parameter(Mandatory=$false)]
            [String]$FirstName,
        [Parameter(Mandatory=$false)]
            [String]$LastName,
        [Parameter(Mandatory=$false)]
            [String]$Email,
        [ValidateSet("Active","Bypass","Disabled")]
            [String]$Status,
        [Parameter(Mandatory=$false)]
            [String]$Notes
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/users/$($UserID)"
    [Hashtable]$DuoParams = @{}

    #Create claim with selected attributes to be modified
    If($Username){$DuoParams.Add("username",$Username.ToLower())}
    If($Alias1){$DuoParams.Add("Alias1",$alias1.ToLower())}
    If($Alias2){$DuoParams.Add("Alias2",$alias2.ToLower())}
    If($Alias3){$DuoParams.Add("Alias3",$alias3.ToLower())}
    If($Alias4){$DuoParams.Add("Alias4",$alias4.ToLower())}
    If($RealName){$DuoParams.Add("realname",$RealName)}
    If($FirstName){$DuoParams.Add("firstname",$FirstName)}
    If($LastName){$DuoParams.Add("lastname",$LastName)}
    If($Email){$DuoParams.Add("email",$Email.ToLower())}
    If($Status){$DuoParams.Add("status",$Status.ToLower())}
    If($Notes){$DuoParams.Add("Notes",$Notes)}

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

Function Remove-DuoUser{

    PARAM(
        [Parameter(
            Mandatory=$true,
            ValueFromPipleLine=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserID $_){$true}
            Else{Throw "User ID: $($_) doesn't exist within Duo"}
        })]$UserID,
        [Switch]$Force
    )
    $Username = (Get-DuoUser -UserID $UserID).username
    If($Force -eq $false){
        $Confirm = $Host.UI.PromptForChoice("Please Confirm","Are you sure you want to delete $($Username) from Duo?",@("Yes","No"),1)
    }

    #
    If(($Force -eq $true) -or ($Confirm -eq 0)){
        #Base claim
        [String]$Method = "POST"
        [String]$Uri = "/admin/v1/users/$($UserID)"

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
}

Function New-DuoUserEnrollment{

    Param(
        [Parameter(
            Mandatory=$true,
            HelpMessage="Duo username or alias to be enrolled",
            ValueFromPipleLine=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -Username $_){$true}
            Else{Throw "User ID: $($_) doesn't exist within Duo"}
        })]
            [String]$Username,
        [Parameter(
            Mandatory=$true,
            HelpMessage="Email to be enrolled",
            ValueFromPipeline=$true,
            Position=1
        )]
            [MailAddress]$Email,
        [Parameter(ParameterSetName="DateTime",
            HelpMessage="DateTime for when enrollment expires",
            Mandatory=$false,
            ValueFromPipeline=$false,
            Position=2
        )]
            [DateTime]$ExpirationDate,
        [Parameter(ParameterSetName="Seconds",
            HelpMessage="How many seconds until enrollment expires",
            Mandatory=$false,
            ValueFromPipeline=$false,
            Position=2
        )]
            [Int]$TimeToExpire
    )

    If($ExpirationDate){
        $Time = ($ExpirationDate - (Get-Date)).TotalSeconds
    }
    ElseIf($TimeToExpire){
        $Time = $TimeToExpire
    }


    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/users/enroll"
    [Hashtable]$DuoParams = @{}

    $DuoParams.Add("username",$Username.ToLower())
    $DuoParams.Add("email",$Email.ToString().ToLower())
    If($Time){
        $Time = [Math]::Round($Time)
        $DuoParams.Add("valid_secs",$Time.ToString())
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

Function New-DuoUserBypassCode{

    Param(
        [Parameter(
            Mandatory=$true,
            ValueFromPipleLine=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -Username $_){$true}
            Else{Throw "User ID: $($_) doesn't exist within Duo"}
        })]
            [String]$Username,

        [Parameter(
            Mandatory=$false,
            HelpMessage="Define bypass codes to be used. Maximum of 10",
            ValueFromPipeline=$false
        )]
        [Int]$Count,
        
        [Parameter(
            Mandatory=$false,
            HelpMessage="Define bypass codes to be used. Maximum of 10",
            ValueFromPipeline=$false
        )]
            [String]$Codes,

        [Parameter(
            Mandatory=$false,
            HelpMessage="Number of times the bypass codes can be used. Default of 1",
            ValueFromPipeline=$false
        )]
            [Int]$NumberOfUses,

        [Parameter(ParameterSetName="DateTime",
            HelpMessage="DateTime for when bypass codes expire",
            Mandatory=$false,
            ValueFromPipeline=$false
        )]
            [DateTime]$ExpirationDate,

        [Parameter(ParameterSetName="Seconds",
            HelpMessage="How many seconds until bypass code expires",
            Mandatory=$false,
            ValueFromPipeline=$false
        )]
            [Int]$TimeToExpire
    )
    $UserID = (Get-DuoUser -Username $Username).user_id

    If($ExpirationDate){
        $Time = [Math]::Round(($ExpirationDate - (Get-Date)).TotalSeconds)
    }
    ElseIf($TimeToExpire){
        $Time = $TimeToExpire
    }
    Else{
        $Time = 3600
    }

    If($Count -eq $null){
        $Count = 1
    }

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/users/$($UserID)/bypass_codes"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("count",$Count.ToString())
    If($Codes){
        $Codes = $Codes | ConvertTo-Csv -NoTypeInformation
        $DuoParams.Add("codes",$Codes)
    }
    If($NumberOfUses){
        $DuoParams.Add("resuse_count",$NumberOfUses)
    }
    $DuoParams.Add("valid_secs",$Time.ToString())

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

Function Get-DuoUserBypassCode{

    [CmdletBinding(DefaultParameterSetName="Uname")]
    PARAM(
        [Parameter(ParameterSetName="UName",
            Mandatory = $false,
            ValueFromPipeLine = $true,
            Position=0
            )]
        [ValidateScript({
            If(Test-DuoUser -UserName $_){$true}
            Else{Throw "User: $($_) doesn't exist withinin Duo"}
        })]
            [String]$Username,
        [Parameter(ParameterSetName="UID",
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=0
            )]
        [ValidateScript({
            If(Test-DuoUser -UserName $_){$true}
            Else{Throw "User ID: $($_) doesn't exist within Duo"}
        })]
            [String]$UserID
    )

    If($Username){
        $UserID = (Get-DuoUser -Username $Username).user_id
    }

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/users/$($UserID)/bypass_codes"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("limit","300")
    $DuoParams.Add("offset","0")

    #Creates the request
    $Request = Create-DuoRequest -UriPath $Uri -Method $Method -Arguments $DuoParams
    $Response = Invoke-RestMethod @Request
    
    #Call private function to validate and format the request
    $Request = Create-DuoRequest -UriPath $Uri -Method $Method -Arguments $DuoParams
    $Offset = 0

    #Duo has a 500 bypass code limit in their api. Loop to return all bypass codes
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
            #Increment offset to return the next 300 users
            $Offset += 500
        }
    }Until($Output.Count -lt 500)
}

Function Get-DuoUserGroups{

    [CmdletBinding(DefaultParameterSetName="Uname")]
    PARAM(
        [Parameter(ParameterSetName="UName",
            Mandatory = $false,
            ValueFromPipeLine = $true,
            Position=0
            )]
        [ValidateScript({
            If(Test-DuoUser -UserName $_){$true}
            Else{Throw "User: $($_) doesn't exist in Duo"}
        })]
            [String]$Username,
        [Parameter(ParameterSetName="UID",
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=0
            )]
        [ValidateScript({
            If(Test-DuoUser -UserName $_){$true}
            Else{Throw "User ID: $($_) doesn't exist in Duo"}
        })]
            [String]$UserID
    )

    If($Username){
        $UserID = (Get-DuoUser -Username $Username).user_id
    }

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/users/$($UserID)/groups"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("limit","300")
    $DuoParams.Add("offset","0")

    #Creates the request
    $Request = Create-DuoRequest -UriPath $Uri -Method $Method -Arguments $DuoParams
    $Response = Invoke-RestMethod @Request
    
    #Call private function to validate and format the request
    $Request = Create-DuoRequest -UriPath $Uri -Method $Method -Arguments $DuoParams
    $Offset = 0

    #Duo has a 500 bypass code limit in their api. Loop to return all bypass codes
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
            #Increment offset to return the next 300 users
            $Offset += 500
        }
    }Until($Output.Count -lt 500)
}

Function Add-DuoGroupMember{

    [CmdletBinding(DefaultParameterSetName="Uname")]
    Param(
        [Parameter(ParameterSetName="Uname",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserName $_){$true}
            Else{Throw "User: $($_) doesn't exist in Duo"}
        })]
            [String]$Username,
        [Parameter(ParameterSetName="UID",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserID $_){$true}
            Else{Throw "User ID: $($_) doesn't exist in Duo"}
        })]
            [String]$UserID,
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=1
        )]
        [ValidateScript({
            If(Test-DuoGroup -GroupID $_){$true}
            Else{Throw "Group ID: $($_) doesn't exist in Duo"}
        })]
            [String]$GroupID
    )

    If($Username){
        $UserID = (Get-DuoUser -Username $Username).user_id
    }

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/users/$($UserID)/groups"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("group_id",$GroupID)

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

Function Remove-DuoGroupMember{

    [CmdletBinding(DefaultParameterSetName="Uname")]
    Param(
        [Parameter(ParameterSetName="Uname",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserName $_){$true}
            Else{Throw "User: $($_) doesn't exist in Duo"}
        })]
            [String]$Username,
        [Parameter(ParameterSetName="UID",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserID $_){$true}
            Else{Throw "User ID: $($_) doesn't exist in Duo"}
        })]
            [String]$UserID,
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=1
        )]
        [ValidateScript({
            If(Test-DuoGroup -GroupID $_){$true}
            Else{Throw "Group ID: $($_) doesn't exist in Duo"}
        })]
            [String]$GroupID
    )

    If($Username){
        $UserID = (Get-DuoUser -Username $Username).user_id
    }

    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/users/$($UserID)/groups/$($GroupID)"
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

Function Get-DuoUserPhone{

    [CmdletBinding(DefaultParameterSetName="Uname")]
    Param(
        [Parameter(ParameterSetName="Uname",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserName $_){$true}
            Else{Throw "User: $($_) doesn't exist in Duo"}
        })]
            [String]$Username,
        [Parameter(ParameterSetName="UID",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -UserID $_){$true}
            Else{Throw "User ID: $($_) doesn't exist in Duo"}
        })]
            [String]$UserID
    )

    If($Username){
        $UserID = (Get-DuoUser -Username $Username).user_id
    }

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/users/$($UserID)/phones"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("limit","500")
    $DuoParams.Add("offset","0")
    
    $Offset = 0

    #Duo has a 500 phone limit in their api. Loop to return all phones
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
            #Increment offset to return the next 500 phones
            $Offset += 500
        }
    }Until($Output.Count -lt 500)
}

Function Add-DuoPhoneMember{
    Param(
        [String]$UserID,
        [String]$UserName,
        [String]$PhoneID
    )

        #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/users/$($UserID)/phones"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("phone_id",$PhoneID)

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

Function Remove-DuoPhoneMember{
    Param( 
        [String]$UserID,
        [String]$UserName,
        [String]$PhoneID
    )
        #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/users/$($UserID)/phones/$($PhoneID)"
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

Function Get-DuoUserToken{
    Param(
        [String]$UserID,
        [String]$UserName,
        [String]$TokenID
    )

        #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/users/$($UserID)/tokens"
    [Hashtable]$DuoParams = @{}

    $DuoParams.Add("limit","500")
    $DuoParams.Add("offset","0")
    $Offset = 0

    	#Duo has a 500 Tokens limit in their api. Loop to return all Tokens
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
                #Increment offset to return the next 500 Tokens
            $Offset += 500
        }
    }Until($Output.Count -lt 500)
}

Function Add-DuoTokenMember{
    Param(
        [String]$UserID,
        [String]$UserName,
        [String]$TokenID
    )

    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/users/$($UserID)/tokens"
    [Hashtable]$DuoParams = @{}
    $DuoParams.Add("token_id",$TokenID)

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

Function Remove-DuoTokenMember{
    Param(
        [String]$UserID,
        [String]$UserName,
        [String]$TokenID
    )

        #Base Claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/users/$($UserID)/tokens/$($TokenID)"
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

Function Get-DuoUserWebAuthn{
    Param(
        $UserName,
        $UserID
    )

        #Base Claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/users/$($UserID)/webauthncredentials"
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