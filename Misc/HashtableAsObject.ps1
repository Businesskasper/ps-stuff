# Converts a hashtable to a pscustomobject
# Example: $greeting = @{ hello = 'world' } | HashtableAsObject

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