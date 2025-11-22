function AssertIsNotNull($obj, [string]$obj_name = "", [switch]$ReturnResultAsBoolean) {
    $test_result = ($null -eq $obj)

    if($obj_name) {
        if($test_result -eq $false) {
            PrintLiteGreen "`$$obj_name is not Null as expected" }
        else {
            PrintRed "`$$obj_name is Null!" }
    }

    if($ReturnResultAsBoolean.IsPresent) {  return $test_result  }  return
}

function AssertIsNull($obj, [string]$obj_name = "", [switch]$ReturnResultAsBoolean) {
    $test_result = ($null -eq $obj)

    if($obj_name) {
        if($test_result -eq $true) {
            PrintLiteGreen "`$$obj_name is Null as expected" }
        else {
            PrintRed "`$$obj_name is not Null! is: $($obj.GetType().Name)" }
    }

    if($ReturnResultAsBoolean.IsPresent) {  return $test_result  }  return
}

function AssertIsTruthy($obj, [string]$obj_name = "", [switch]$ReturnResultAsBoolean) {
    <# 
    .SYNOPSIS
    This assertion is equivalent to: if($obj)
    #>
    $test_result = $null

    if($obj) {  $test_result = $true  }
    else {
        $test_result = $false
    }

    if($obj_name) {
        if($test_result -eq $true) {
            PrintLiteGreen "`$$obj_name is Truthy as expected" }
        else {
            PrintRed "`$$obj_name is not Truthy!" }
    }
    
    if($ReturnResultAsBoolean.IsPresent) {  return $test_result  }  return
}

function AssertIsFalsy($obj, [string]$obj_name = "", [switch]$ReturnResultAsBoolean) {
    <# 
    .SYNOPSIS
    This assertion is equivalent to: -not($obj) == True
    #>
    $test_result = $null
    
    if(-not($obj)) {  $test_result = $true  }
    else {
        $test_result = $false
    }

    if($obj_name) {
        if($test_result -eq $true) {
            PrintLiteGreen "`$$obj_name is Falsy as expected" }
        else {
            PrintLiteRed "`$$obj_name is not Falsy!" }
    }

    if($ReturnResultAsBoolean.IsPresent) {  return $test_result  }  return
}


function AssertTruthyFalsySymmetry($obj, [string]$obj_name = "", [switch]$ReturnResultAsBoolean) {
    <# 
    .SYNOPSIS
    Symmetry is defined as opposite values in IsTruthy / IsFalsy tests. aka: "consistent/no contradiction". Think:
        -Are you alive? yes         -Are you truthy? yes
        -Are you dead?  no          -Are you falsy?  no
    #>
    $is_truthy = AssertIsTruthy $obj -ReturnResultAsBoolean
    $is_falsy  = AssertIsFalsy  $obj -ReturnResultAsBoolean
    $test_result = $null

    if($is_truthy -eq $is_falsy) {  $test_result = $false }
    else {
        $test_result = $true
    }    

    if($obj_name) {
        if($test_result -eq $true) {
            PrintLiteGreen "`$$obj_name has Truthy-Falsy-Symmetry as expected" }
        else {
            PrintRed "`$$obj_name does not have Truthy-Falsy-Symmetry!" }
    }

    if($ReturnResultAsBoolean.IsPresent) {  return $test_result  }  return
}

function AssertTruthyFalsyAsymmetry($obj, [string]$obj_name = "", [switch]$ReturnResultAsBoolean) {
    <# 
    .SYNOPSIS
    Asymmetry is defined as equal values in IsTruthy / IsFalsy tests. aka: "inconsistent/contradictory". Think:
        -Are you alive? yes          -Are you truthy? yes
        -Are you dead?  yes          -Are you falsy?  yes
        Do you see the contradiction?
    #>
    $is_truthy = AssertIsTruthy $obj -ReturnResultAsBoolean
    $is_falsy  = AssertIsFalsy  $obj -ReturnResultAsBoolean
    $test_result = $null

    if($is_truthy -eq $is_falsy) {  $test_result = $true }
    else {
        $test_result = $false
    }

    if($obj_name) {
        if($test_result -eq $true) {
            PrintLiteGreen "`$$obj_name has Truthy-Falsy-Asymmetry as expected" }
        else {
            PrintRed "`$$obj_name does not have Truthy-Falsy-Asymmetry!" }
    }

    if($ReturnResultAsBoolean.IsPresent) {  return $test_result  }  return
}

function AssertString($stringVarName, $string) {
    if(-not($stringVarName)) {
        throw [System.Management.Automation.RuntimeException]::new("AssertString second paramter required: `$stringVarName")
    }
    if([string]::IsNullOrEmpty($string)) {
        throw [System.Management.Automation.RuntimeException]::new("$stringVarName is Null or Empty")
    }
}

function AssertInt($str, $fail_message="") {
    $result = 0
    if ([int]::TryParse($str, [ref]$result)) {
        return $result
    } else {
        throw "`e[38;5;214m$fail_message`e[0m"
    }
}