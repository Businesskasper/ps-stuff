# Converts a hashtable to a pscustomobject
# Example: $greeting = @{ hello = 'world' } | HashtableAsObject

function HashtableAsObject() {
    [cmdletbinding()]
    param(
        [AllowNull()]
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $item
    )
    if ($null -eq $item) {
        return $null
    }

    if ($item -is [Hashtable] -or $item -is [System.Collections.Generic.Dictionary[string, object]]) {
        # item is hashtable or object
        # create object and recursively add members
        $copy = [PSCustomObject]::new()
        $members = $item.GetEnumerator()
        foreach ($member in $members) {
            $asObj = HashtableAsObject -item $member.Value
            $copy | Add-Member -MemberType NoteProperty -Name $member.Key -Value $asObj
        }
        return $copy
    }
    # Temporary workaround since for some reason a String was recognized as PSCustomObject in the next clause
    elseif ($item.GetType().Name -eq "String" -or $item.GetType().Name -like "Int*" -or $item.GetType().Name -eq "Boolean") {
        # item is a primitive value
        # return as is
        return $item
    }
    elseif ([System.Collections.Generic.IEnumerable[object]].IsAssignableFrom($item.GetType())) {
        # item is a collection
        # create new array and recursviely add members
        $copy = [PSCustomObject[]]@()
        foreach ($member in $item) {
            $copy += HashtableAsObject -item $member
        }
        return $copy
    }
    elseif ($item -is [PSCustomObject]) {
        # item is an object
        # copy object and recursively add members
        $copy = [PSCustomObject]::new()
        $members = $item | Get-Member -MemberType NoteProperty
        foreach ($member in $members) {
            $asObj = HashtableAsObject -item $item.($member.Name)
            $copy | Add-Member -MemberType NoteProperty -Name $member.Name -Value $asObj
        }
        return $copy
    }
    else {
        # item is a primitive value
        # return as is
        return $item
    }
}
