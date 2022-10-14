# Converts a hashtable to a pscustomobject
# Example: $greeting = @{ hello = 'world' } | HashtableAsObject

function HashtableAsObject() {

    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $item
    )

    # Convert children
    if ($item -is [Hashtable] -or $item -is [System.Collections.Generic.Dictionary[string, object]]) {
        $copy = [PSCustomObject]::new()
        $item.GetEnumerator() | % {
            $copy | Add-Member -MemberType NoteProperty -Name $_.Key -Value (ConvertToPsObject -item $_.Value)
        }
        return $copy
    }
    elseif ($item -is [PSCustomObject]) {
        $copy = [PSCustomObject]::new()
        $item | Get-Member -MemberType NoteProperty | % {
            $copy | Add-Member -MemberType NoteProperty -Name $_.Name -Value (ConvertToPsObject -item $item.($_.Name))
        }
        return $copy
    }
    elseif ([System.Collections.Generic.IEnumerable[object]].IsAssignableFrom($item.GetType())) {
        $copy = [PSCustomObject[]]@()
        foreach ($child in $item) {
            $copy += ConvertToPsObject -item $child
        }
        return $copy
    }
    else {
        return $item
    }
}

<#
function HashtableAsObject {

    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $hashtable
    )
    $obj = [PSCustomObject]::new()
    $hashtable.GetEnumerator() | % {

        $obj | Add-Member -MemberType NoteProperty -Name $_.Key -Value $_.Value
    }

    return $obj
}
#>
