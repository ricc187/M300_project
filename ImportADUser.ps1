
# Define the CSV file location and import the data
$Csvfile = "C:\ImportADUsers.csv"
$Users = Import-Csv $Csvfile -delimiter ","

# The password for the new user
$Password = "Pa$$w0rd"

# Import the Active Directory module
Import-Module ActiveDirectory

# Loop through each user
foreach ($User in $Users) {

    try {
		if (!($existingUser = Get-ADUser -Filter {SamAccountName -eq $SamAccountName})){
			# Debug: Check the value of 'User logon name'
			Write-Host "Checking user: $($User.'User logon name')" -ForegroundColor Cyan

			# Ensure the 'User logon name' is a string
			$SamAccountName = [string]$User.'User logon name'
			Write-Host "SamAccountName value: $SamAccountName" -ForegroundColor Cyan
			
			# Define the parameters using a hashtable
			$NewUserParams = @{
				Name                  = "$($User.'First name') $($User.'Last name')"
				GivenName             = $User.'First name'
				Surname               = $User.'Last name'
				DisplayName           = $User.'Display name'
				SamAccountName        = $SamAccountName  # Explicitly passing the string value
				AccountPassword       = (ConvertTo-SecureString "$Password" -AsPlainText -Force)
				Enabled               = if ($User.'Account status' -eq "Enabled") { $true } else { $false }
				ChangePasswordAtLogon = $true # Set the "User must change password at next logon"
			}

			# Add the info attribute to OtherAttributes only if Notes field contains a value
			if (![string]::IsNullOrEmpty($User.Notes)) {
				$NewUserParams.OtherAttributes = @{info = $User.Notes }
			}
			
			# User does not exist then proceed to create the new user account
            New-ADUser @NewUserParams
			
			$GroupName = $User.'GroupName'
			$GroupExists = $(try {Get-ADGroup -Filter "SamAccountName -eq '$GroupName'"} catch {$null})
			
			if(!([String]::IsNullOrEmpty($GroupExists.DistinguishedName))){
				Add-ADGroupMember -Identity $GroupExists -Members $SamAccountName
			}
			
            Write-Host "The user $SamAccountName is created successfully." -ForegroundColor Green
		}
		else {
			# Give a warning if user exists
            Write-Host "A user with username $SamAccountName already exists in Active Directory." -ForegroundColor Yellow
			
		}
    }
    catch {
        # Handle any errors that occur during account creation
        Write-Host "Failed to create user $($User.'User logon name') - $($_.Exception.Message)" -ForegroundColor Red
    }
}
