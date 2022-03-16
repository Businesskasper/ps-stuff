function GetRandomPassword([int]$length) {

	$pw = [String]::Empty
	1..$length | % { 
		$pw += [char]$(Get-Random -Minimum 97 -Maximum 126) 
	}
	return $pw
}

GetRandomPassword -length 8