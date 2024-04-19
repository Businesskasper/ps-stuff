# Compares two objects and returns the difference
# Example: 
# 
# $item = [PSCustomObject]@{
#     "simpleKey"= "a"
#     "arrayKey" = @(
#         [PSCustomObject]@{
#            "foo" = "bar" 
#         },
#         [PSCustomObject]@{
#             "jo" = "no"
#         }
#     )
#     "boolKey" = $true
#      "jo" = @(1, 2, 3)
# }
# 
# 
# $reference = [PSCustomObject]@{
#     "simpleKey"= "b"
#     "arrayKey" = @(
#         [PSCustomObject]@{
#            "foo" = "baz" 
#         },
#         [PSCustomObject]@{
#             "jo" = "no"
#         }
#     )
#     "boolKey" = $true
#     "jo" = @(1, 2, 3, 4)
# }
# 
# $diff = getDiff -item $item -reference $reference


function getDiff() {

    param(
        [AllowNull()]
        [PSCustomObject]$item,

        [AllowNull()]
        [PSCustomObject]$reference
    )

    $diff = [PSCustomObject]::new()

    if ($null -eq $item) {
        return $null
    }

    $members = $item | Get-Member -MemberType NoteProperty
    
     foreach ($member in $members) {
        $value = $item.($member.Name)
        $refValue = $reference.($member.Name)

        if ($null -eq $value -and $null -ne $refValue) {
            $diff | Add-Member -MemberType NoteProperty -Name $member.Name -Value $null
            continue
        }
        elseif ($null -ne $value -and $null -eq $refValue) {
            $diff | Add-Member -MemberType NoteProperty -Name $member.Name -Value $value
            continue
        }
        elseif ($null -eq $value -and $null -eq $refValue) {
            continue
        }

        # value and reference are not comparable
        elseif ($value.GetType() -ne $refValue.GetType()) {
            $diff | Add-Member -MemberType NoteProperty -Name $member.Name -Value $value
            continue
        }

        # value is primitive
        if ($value.GetType().Name -eq "String" -or $value.GetType().Name -like "Int*" -or $value.GetType().Name -eq "Boolean") {
            if ($value -ne $refValue) {
                $diff | Add-Member -MemberType NoteProperty -Name $member.Name -Value $value
                continue
            }
        }  
        # value is collection
        elseif ([System.Collections.Generic.IEnumerable[object]].IsAssignableFrom($value.GetType())) {
            $itemChildren = $refValue[0..$($value.Count -1)]
            $subDiffs = @()
            for ($i = 0; $i -lt $itemChildren.Count; $i++) { 
                $subDiff = getDiff -item $value[$i] -reference $refValue[$i]
                if ($null -ne $subDiff) {
                    $subDiffs += $subDiff
                }
            }

            $refsNotInItem = $refValue[$($value.Count)..$($refValue.Count)]
            foreach($refNotInItem in $refsNotInItem) {
                # $subDiffs += $refNotInItem
                $subDiffs += $null
            }

            if ($subDiffs.Count -gt 0) {
                $diff | Add-Member -MemberType NoteProperty -Name $member.Name -Value $subDiffs
            }
            continue
        }
        # value is object
        elseif ($item -is [PSCustomObject]) {
            $subDiff = getDiff -item $value -reference $refValue
            if ($null -ne $subDiff) {
               $diff | Add-Member -MemberType NoteProperty -Name $member.Name -Value $subDiff 
            } 
            continue
        }
    }

    $hasNoDiffs = ($diff | Get-Member -MemberType NoteProperty).Count -eq 0
    if ($hasNoDiffs) {
        return $null
    }
    return $diff
}