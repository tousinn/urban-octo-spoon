param (
    [parameter(Position = 0,
        Mandatory = $true)]
    [string] $Region,
    [string] $JsonFileUrl = "https://ip-ranges.amazonaws.com/ip-ranges.json"
)

function get-IpRangesByRegion {
    # Filtering the JSON-Object for the specific Region-String and return the filtered IPs as Array
    param (
        [string] $region,
        $json
    )
    $ipRanges = @()
    foreach ($entry in $json.prefixes) {                # Filter in IPv4
        if ($entry.region -eq $region) {
            $ipRanges += $entry.ip_prefix
        }
    }
    foreach ($entry in $json.ipv6_prefixes) {           # Filter in IPv6
        if ($entry.region -eq $region) {
            $ipRanges += $entry.ipv6_prefix
        }
    }
    $ipRanges
}

function Get-SumOfNumbers {
    # Calculates the sum of all Numbers in the Array of IPs. Also converts Hex to Dec to add them to the Sum, too
    param (
        $array
    )
    $sum = 0

    foreach ($value in $array) {
        if ($value -like "*.*") {                       # This matches IPv4
            $sum += $value.split("/")[1]
            ($value.split("/")[0]).split(".") | foreach-object { $sum += $_ }
        }
        elseif ($value -like "*:*") {                   # This matches IPv6
            $sum += $value.split("/")[1]
            ($value.split("/")[0]).split(":") | foreach-object {
                if ($_ -match "^\d+$") {                # This matches Decimal Numbers from IPv6
                    $sum += $_
                } elseif ($_ -match "^[0-9A-F]+$") {    # This matches the Hex-Numbers from IPv6
                    $sum += [uint32]$_.Insert(0,'0x')
                }
            }
        }
    }
    $sum
}

Write-Output "Script starting...`n"

Write-Output "Downloading Regionfile from '$JsonFileUrl'...`n"
$AllIpRanges = Invoke-WebRequest $JsonFileUrl | ConvertFrom-Json

Write-Output "Filtering IP-Ranges for Region '$Region'...`n"
$FilteredIpRanges = get-IpRangesByRegion -region $Region -json $AllIpRanges

if ($FilteredIpRanges.count -gt 0) {
    Write-output "IP Ranges in '$Region':"
    $FilteredIpRanges
    Write-Output "`nSum of all those decimal and hexadecimal numbers: $(Get-SumOfNumbers -array $FilteredIpRanges)"
} else {
    Write-Error "No region '$Region' found in List of IP-Ranges..."
}


Write-Output "`nScript finished!`n"
