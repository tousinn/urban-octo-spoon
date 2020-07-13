param (
    [parameter(Position = 0,
        Mandatory = $true)]
    [string] $Region = "eu-west-2",
    [string] $JsonFileUrl = "https://ip-ranges.amazonaws.com/ip-ranges.json"
)

function get-IpRangesByRegion {
    param (
        [string] $region,
        $json
    )
    $ipRanges = @()
    foreach ($entry in $json.prefixes) {
        if ($entry.region -eq $region) {
            $ipRanges += $entry.ip_prefix
        }
    }
    foreach ($entry in $json.ipv6_prefixes) {
        if ($entry.region -eq $region) {
            $ipRanges += $entry.ipv6_prefix
        }
    }
    $ipRanges
}

function Get-SumOfNumbers {
    param (
        $array
    )
    $sum = 0

    foreach ($value in $array) {
        if ($value -like "*.*") {
            $sum += $value.split("/")[1]
            ($value.split("/")[0]).split(".") | foreach-object { $sum += $_ }
        }
        elseif ($value -like "*:*") {
            $sum += $value.split("/")[1]
            ($value.split("/")[0]).split(":") | foreach-object {
                if ($_ -match "^\d+$") {
                    $sum += $_
                } elseif ($_ -match "^[0-9A-F]+$") {
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
