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
            Else{Throw "$($_) is an invalid directory"}
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
    $Args = @{}

    #$User = Get-DuoUser -Username $Username
    If($Email){$VerifiedUsername = (Get-Duouser -Username $Username).email}
    Else{$VerifiedUsername = $Username}
    $Args.Add("username",$VerifiedUsername.ToLower())

    $Request = Create-DuoRequest -UriPath $Uri -Method $Method -Arguments $Args
    $Response = Invoke-RestMethod @Request
    If($Response.stat -ne 'OK'){
        Write-Warning 'DUO REST Call Failed'
        Write-Warning "Arguments:"+($Args | Out-String)
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
            [String]$Username,
        [Parameter(ParameterSetName="UID",
            Mandatory = $false,
            ValueFromPipeLine = $false,
            Position=0
            )]
            [String]$UserID
    )

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/users"
    $Args = @{}

    If($Username){
        $Args.Add("username",$Username.ToLower())
    }
    ElseIf($UserID){    
        $Uri = "/admin/v1/users/$($UserID)"
    }
    Else{
        $Args.Add("limit","300")
        $Args.Add("offset","0")
    }
    $Offset = 0

    #Duo has a 300 user limit in their api. Loop to return all users
    Do{
        $Args.Offset = $Offset
        $Request = Create-DuoRequest -UriPath $Uri -Method $Method -Arguments $Args
        $Response = Invoke-RestMethod @Request
        If($Response.stat -ne 'OK'){
            Write-Warning 'DUO REST Call Failed'
            Write-Warning "Arguments:"+($Args | Out-String)
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

Function New-Duouser{
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
    $Args = @{}

    #Add Username
    $Args.Add("username",$Username.ToLower())

    #Add Optional Parameters
    If($Alias1){$Args.Add("alias1",$Alias1.ToLower())}
    If($Alias2){$Args.Add("alias2",$Alias2.ToLower())}
    If($Alias3){$Args.Add("alias3",$Alias3.ToLower())}
    If($Alias4){$Args.Add("alias4",$Alias4.ToLower())}
    If($Realname){$Args.Add("realname",$Realname)}
    If($Firstname){$Args.Add("firstname",$Firstname)}
    If($Lastname){$Args.Add("lastname",$Lastname)}
    If($Email){$Args.Add("email",$Email.ToLower())}
    If($Status){$Args.Add("status",$Status.ToLower())}
    If($Notes){$Args.Add("notes",$Notes)}

    $Request = Create-DuoRequest -UriPath $Uri -Method $Method -Arguments $Args
    $Response = Invoke-RestMethod @Request
    If($Response.stat -ne 'OK'){
        Write-Warning 'DUO REST Call Failed'
        Write-Warning "Arguments:"+($Args | Out-String)
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
            Else{Throw "Invalid User ID"}
        })][String]$UserID,
        [Parameter(
            Mandatory=$false,
            ValueFromPipleLine=$true,
            Position=1
        )]$Username,
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
    $Args = @{}

    #Create claim with selected attributes to be modified
    If($Username){$Args.Add("username",$Username.ToLower())}
    If($Alias1){$Args.Add("Alias1",$alias1.ToLower())}
    If($Alias2){$Args.Add("Alias2",$alias2.ToLower())}
    If($Alias3){$Args.Add("Alias3",$alias3.ToLower())}
    If($Alias4){$Args.Add("Alias4",$alias4.ToLower())}
    If($RealName){$Args.Add("realname",$RealName)}
    If($FirstName){$Args.Add("firstname",$FirstName)}
    If($LastName){$Args.Add("lastname",$LastName)}
    If($Email){$Args.Add("email",$Email.ToLower())}
    If($Status){$Args.Add("status",$Status.ToLower())}
    If($Notes){$Args.Add("Notes",$Notes)}

    #Creates the request
    $Request = Create-DuoRequest -UriPath $Uri -Method $Method -Arguments $Args
    $Response = Invoke-RestMethod @Request
    #Error Handling
    If($Response.stat -ne 'OK'){
        Write-Warning 'DUO REST Call Failed'
        Write-Warning "Arguments:"+($Args | Out-String)
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
            Else{Throw "Invalid User ID"}
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
        $Request = Create-DuoRequest -UriPath $Uri -Method $Method -Arguments $Args
        $Response = Invoke-RestMethod @Request
        
        #Error Handling
        If($Response.stat -ne 'OK'){
            Write-Warning 'DUO REST Call Failed'
            Write-Warning "Arguments:"+($Args | Out-String)
            Write-Warning "Method:$Method    Path:$Uri"
        }
        #Returning request
        Else{
            $Output = $Response | Select-Object -ExpandProperty Response 
            $Output
        }
    }
}

Function Enroll-DuoUser{

    Param(
        [Parameter(
            Mandatory=$true,
            HelpMessage="Duo username to be enrolled",
            ValueFromPipleLine=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoUser -Username $_){$true}
            Else{Throw "Invalid User ID"}
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
    $Args = @{}

    $Args.Add("username",$Username.ToLower())
    $Args.Add("email",$Email.ToString().ToLower())
    If($Time){
        $Time = [Math]::Round($Time)
        $Args.Add("valid_secs",$Time.ToString())
    }

    #Creates the request
    $Request = Create-DuoRequest -UriPath $Uri -Method $Method -Arguments $Args
    $Response = Invoke-RestMethod @Request
    
    #Error Handling
    If($Response.stat -ne 'OK'){
        Write-Warning 'DUO REST Call Failed'
        Write-Warning "Arguments:"+($Args | Out-String)
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
            Else{Throw "Invalid User ID"}
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
    $Args = @{}
    $Args.Add("count",$Count.ToString())
    If($Codes){
        $Codes = $Codes | ConvertTo-Csv -NoTypeInformation
        $Args.Add("codes",$Codes)
    }
    If($NumberOfUses){
        $Args.Add("resuse_count",$NumberOfUses)
    }
    $Args.Add("valid_secs",$Time.ToString())

    #Creates the request
    $Request = Create-DuoRequest -UriPath $Uri -Method $Method -Arguments $Args
    $Response = Invoke-RestMethod @Request
    
    #Error Handling
    If($Response.stat -ne 'OK'){
        Write-Warning 'DUO REST Call Failed'
        Write-Warning "Arguments:"+($Args | Out-String)
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
            Else{Throw "UserID: $($_) doesn't exist in Duo"}
        })]
            [String]$UserID
    )

    If($Username){
        $UserID = (Get-DuoUser -Username $Username).user_id
    }

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/users/$($UserID)/bypass_codes"
    $Args = @{}
    $Args.Add("limit","300")
    $Args.Add("offset","0")

    #Creates the request
    $Request = Create-DuoRequest -UriPath $Uri -Method $Method -Arguments $Args
    $Response = Invoke-RestMethod @Request
    
    #Call private function to validate and format the request
    $Request = Create-DuoRequest -UriPath $Uri -Method $Method -Arguments $Args
    $Offset = 0

    #Duo has a 500 bypass code limit in their api. Loop to return all bypass codes
    Do{
        $Args.Offset = $Offset
        $Request = Create-DuoRequest -UriPath $Uri -Method $Method -Arguments $Args
        $Response = Invoke-RestMethod @Request
        If($Response.stat -ne 'OK'){
            Write-Warning 'DUO REST Call Failed'
            Write-Warning "Arguments:"+($Args | Out-String)
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
            Else{Throw "UserID: $($_) doesn't exist in Duo"}
        })]
            [String]$UserID
    )

    If($Username){
        $UserID = (Get-DuoUser -Username $Username).user_id
    }

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/users/$($UserID)/groups"
    $Args = @{}
    $Args.Add("limit","300")
    $Args.Add("offset","0")

    #Creates the request
    $Request = Create-DuoRequest -UriPath $Uri -Method $Method -Arguments $Args
    $Response = Invoke-RestMethod @Request
    
    #Call private function to validate and format the request
    $Request = Create-DuoRequest -UriPath $Uri -Method $Method -Arguments $Args
    $Offset = 0

    #Duo has a 500 bypass code limit in their api. Loop to return all bypass codes
    Do{
        $Args.Offset = $Offset
        $Request = Create-DuoRequest -UriPath $Uri -Method $Method -Arguments $Args
        $Response = Invoke-RestMethod @Request
        If($Response.stat -ne 'OK'){
            Write-Warning 'DUO REST Call Failed'
            Write-Warning "Arguments:"+($Args | Out-String)
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
            Else{Throw "UserID: $($_) doesn't exist in Duo"}
        })]
            [String]$UserID,
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=1
        )]
        [ValidateScript({
            If(Test-DuoGroup -GroupID $_){$true}
            Else{Throw "GroupID: $($_) doesn't exist in Duo"}
        })]
            [String]$GroupID
    )

    If($Username){
        $UserID = (Get-DuoUser -Username $Username).user_id
    }

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/users/$($UserID)/groups"
    $Args = @{}
    $Args.Add("group_id",$GroupID)

    #Creates the request
    $Request = Create-DuoRequest -UriPath $Uri -Method $Method -Arguments $Args
    $Response = Invoke-RestMethod @Request
    
    #Error Handling
    If($Response.stat -ne 'OK'){
        Write-Warning 'DUO REST Call Failed'
        Write-Warning "Arguments:"+($Args | Out-String)
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
            Else{Throw "UserID: $($_) doesn't exist in Duo"}
        })]
            [String]$UserID,
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=1
        )]
        [ValidateScript({
            If(Test-DuoGroup -GroupID $_){$true}
            Else{Throw "GroupID: $($_) doesn't exist in Duo"}
        })]
            [String]$GroupID
    )

    If($Username){
        $UserID = (Get-DuoUser -Username $Username).user_id
    }

    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/users/$($UserID)/groups/$($GroupID)"
    $Args = @{}

    #Creates the request
    $Request = Create-DuoRequest -UriPath $Uri -Method $Method -Arguments $Args
    $Response = Invoke-RestMethod @Request
    
    #Error Handling
    If($Response.stat -ne 'OK'){
        Write-Warning 'DUO REST Call Failed'
        Write-Warning "Arguments:"+($Args | Out-String)
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
            Else{Throw "UserID: $($_) doesn't exist in Duo"}
        })]
            [String]$UserID
    )

    If($Username){
        $UserID = (Get-DuoUser -Username $Username).user_id
    }

    #Base claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v1/users/$($UserID)/phones"
    $Args = @{}
    $Args.Add("limit","500")
    $Args.Add("offset","0")
    
    $Offset = 0

    #Duo has a 500 phone limit in their api. Loop to return all phones
    Do{
        $Args.Offset = $Offset
        $Request = Create-DuoRequest -UriPath $Uri -Method $Method -Arguments $Args
        $Response = Invoke-RestMethod @Request
        If($Response.stat -ne 'OK'){
            Write-Warning 'DUO REST Call Failed'
            Write-Warning "Arguments:"+($Args | Out-String)
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

}

Function Remove-DuoPhoneMember{

}

Function Get-DuoUserHardwareToken{

}

Function Add-DuoHardwareTokenMember{

}

Function Remove-DuoHardwareTokenMember{

}

Function Get-DuoUserU2FToken{

}

Function Get-DuoUserWebAuthn{

}