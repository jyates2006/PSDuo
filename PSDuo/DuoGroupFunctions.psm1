Function Get-DuoGroup{

    [CmdletBinding(DefaultParameterSetName="Gname")]
    Param(
        [Parameter(
            ParameterSetName="Gname",
            Mandatory=$false
        )]
            [String]$Name,
        [Parameter(
            ParameterSetName="GID",
            Mandatory=$false
        )]
            [String]$GroupID
    )

    #Base Claim
    [String]$Method = "GET"
    [String]$Uri = "/admin/v2/groups"
    $Args = @{}
    $Args.Add("limit","100")
    $Args.Add("offset","0")

    If($GroupID){
        $Groups = $null
        Write-host "ID"
    }
    ElseIf($Name){
        $Groups = Get-AllDuoGroups | Where-Object Name -Like "$($Name)*"
    }
    Else{
        $Groups = Get-AllDuoGroups
    }
    If($Groups -eq $null){
        [String]$Uri = "/admin/v2/groups/$($GroupID)"
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
    Else{
        ForEach($Group in $Groups){
            $GroupID = $Group.group_id
            [String]$Uri = "/admin/v2/groups/$($GroupID)"
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
}

Function Get-DuoGroupMembers{

    [CmdletBinding(DefaultParameterSetName="GID")]
    Param(
        [Parameter(
            ParameterSetName="Gname",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoGroup -GroupName $_){$true}
            Else{Throw "Invalid Group"}
        })]
            [String]$Name,
        [Parameter(
            ParameterSetName="GID",
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateScript({
            If(Test-DuoGroup -GroupName $_){$true}
            Else{Throw "Invalid Group ID"}
        })]
            [String]$GroupID
    )

    If($Name){
        $Group = Get-DuoGroup -GroupName $Name
        If($Group.group_id.count -gt 1){
            Write-Warning "Multiple groups returned"
            Return "Please use exact group name."
        }
        Else{
            $GroupID = $Group.group_id
        }
    }
    If($GroupID){
        [String]$Uri = "/admin/v2/groups/$($GroupID)/users"
        $Method = "GET"
        $Args = @{}
        $Args.Add("limit","500")
        $Args.Add("offset","0")
        $Offset = 0

        Do{
            $Args.offset = $Offset
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
                $Offset += 500
            }
        }Until($Output.count -lt 500)
    }
}

Function New-DuoGroup{

    Param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0)]
        [ValidateScript({
            If(Test-DuoGroup -GroupName $_){Throw "Group $_ already exist"}
            Else{$true}
        })]
            [String]$Name,
        [Parameter(Mandatory=$false,
        ValueFromPipeline=$true,
        Position=1)]
            [String]$Description,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Active","Bypass","Disabled")]
            [String]$Status
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/groups"
    $Args = @{}
    $Args.Add("name",$Name)
    If($Description){
        $Args.Add("desc",$Description)
    }
    If($Status){
        $Args.Add("status",$Status)
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

Function Update-DuoGroup{

    Param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0)]
        [ValidateScript({
            If(Test-DuoGroup -GroupName $_){$true}
            Else{Throw "Invalid Group ID"}
        })]
            [String]$GroupID,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            Position=1
        )]
        [Parameter(Mandatory=$false,
            ValuefromPipeline=$true,
            Position=2
        )]
            [String]$Name,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$false
        )]
            [String]$Description,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Active","Bypass","Disabled")]
            [String]$Status
    )

    #Base claim
    [String]$Method = "POST"
    [String]$Uri = "/admin/v1/groups/$($GroupID)"
    $Args = @{}
    If($Name){
        $Args.Add("name",$Name)
    }
    If($Status){
        $Args.Add("status",$Status)
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

Function Remove-DuoGroup{

    Param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0)]
        [ValidateScript({
            If(Test-DuoGroup -GroupName $_){$true}
            Else{Throw "Invalid Group ID"}
        })]
            [String]$GroupID
    )

    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/groups/$($GroupID)"
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
