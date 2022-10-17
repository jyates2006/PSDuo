Function Get-DuoBypassCode{

    PARAM(
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true
        )]
        [ValidateScript({
            If(Test-DuoBypassCode -BypassCodeID $_){$true}
            Else{Throw "Invalid User ID"}
        })]
            [String]$BypassCodeID
    )
    #Base claim
    [String]$Method = "GET"
    If($BypassCodeID){
        [String]$Uri = "/admin/v1/bypass_codes/$($BypassCodeID)"
    }
    Else{
        [String]$Uri = "/admin/v1/bypass_codes"
    }
    $Args = @{}
    $Args.Add("limit","500")
    $Args.Add("offset","0")

    $Offset=0
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
            #Increment offset to return the next 500 Bypass codes
            $Offset += 500
        }
    }Until($Output.Count -lt 500)
}

Function Remove-DuoBypassCode{

    Param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true
        )]
        [ValidateScript({
            If(Test-DuoBypassCode -BypassCodeID $_){$true}
            Else{Throw "Invalid User ID"}
        })]
            [String]$BypassCodeID
    )

    #Base claim
    [String]$Method = "DELETE"
    [String]$Uri = "/admin/v1/bypass_codes/$($BypassCodeID)"
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