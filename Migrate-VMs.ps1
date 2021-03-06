
######## Source vCenter ################
## Ensure all VMs are on shared storage that both the old and new hosts/vCenter can see#####

# Ensure CSV File exists in target location or update if modified
$VMsCSV = 'C:\Scripts\VM-Migration.csv'
$listVMs = Import-Csv $VMsCSV


# Connect to Source vCenter
Connect-VIServer 'SourcevCenter'


# Shutdown VM from inventory
foreach($itemVM in $listVMs){
	$VMName = $itemVM.VMName
	Get-VM -Name $VMName | Shutdown-VMGuest -Confirm:$false
	}
	
	
# Check power state
foreach($itemVM in $listVMs){
	$VMName = $itemVM.VMName
	Get-VM -Name $VMName
	}
	
	
# Remove from inventory
foreach($itemVM in $listVMs){
	$VMName = $itemVM.VMName
    Get-VM -Name $VMName | Remove-VM -DeletePermanently:$false -Confirm:$false -RunAsync
	}



#
# Connect to Destination vCenter Server
#

# Ensure CSV File exists in target location or update if modified
$VMsCSV = 'C:\Scripts\VM-Migration.csv'
$listVMs = Import-Csv $VMsCSV

# Connect to Destination vCenter
Connect-VIServer 'DestinationvCenter'


# This section will pull VMs into inventory from source vCenter
# Optionally can storage vMotion or move to Resource pool if required
	foreach($itemVM in $listVMs){
	$VMName = $itemVM.VMName
	$VMPath = $itemVM.Path
	if ($itemVM.TargetNetwork -ne 'None') {$TargetNetwork = Get-VDPortgroup -Name $itemVM.TargetNetwork -VDSwitch 'DVS_Prod'}
    if ($itemVM.TargetNetwork2 -ne 'None') {$TargetNetwork2 = Get-VDPortgroup -Name $itemVM.TargetNetwork2 -VDSwitch 'DVS_Prod'}
    $TargetCluster = $itemVM.TargetCluster
	$TargetFolder = $itemVM.TargetFolder
	$TargetDS = Get-DatastoreCluster -Name $itemVM.TargetDSName
	$esxhost = Get-Cluster -Name $TargetCluster | Get-VMHost | Where { $_.ConnectionState -eq "Connected" } | Get-Random
    #$TargetRP = $itemVM.TargetRP
	#$TargetRPLocation = Get-ResourcePool -Location $TargetCluster -Name $TargetRP
	

	New-VM -VMHost $esxhost -Name $VMName -Location $TargetFolder -VMFilePath $VMPath
	if ($itemVM.TargetNetwork -ne 'None') {Get-VM $VMName | Get-NetworkAdapter -Name 'Network Adapter 1' | Set-NetworkAdapter -Portgroup $TargetNetwork -Confirm:$false -RunAsync}
    #Get-VM -Name $VMName | Move-VM -Destination $TargetRPLocation -Confirm:$false
    if ($itemVM.TargetNetwork2 -ne 'None') {Get-VM $VMName | Get-NetworkAdapter -Name 'Network Adapter 2' | Set-NetworkAdapter -Portgroup $TargetNetwork2 -Confirm:$false -RunAsync}
	$CDDrive = Get-VM $VMName | Get-CDDrive
	$FloppyDrive = Get-VM $VMName | Get-FloppyDrive
	$USBDevice = Get-VM $VMName | Get-UsbDevice
	if ($CDDrive -ne $null) {Remove-CDDrive -CD $CDDrive -Confirm:$false}
	if ($FloppyDrive -ne $null) {Remove-FloppyDrive -Floppy $FloppyDrive -Confirm:$false}
	if ($USBDevice -ne $null) {Remove-UsbDevice -UsbDevice $USBDevice -Confirm:$false}
			
	Start-VM -VM $VMName -Confirm:$false -RunAsync
	
	Get-VMQuestion | Set-VMQuestion -Option 'button.uuid.movedTheVM' -Confirm:$false
	
	# Option to svMotion after power on (remove runasync from start to work
	#Get-VM -Name $VMName | Move-VM -Datastore $TargetDS -Confirm:$false
    }
	
	
	
# Use this one line to clear any VM questions if there are any stuck 
Get-VMQuestion | Set-VMQuestion -Option 'button.uuid.movedTheVM' -Confirm:$false



# Shutdown VM from inventory
foreach($itemVM in $listVMs){
	$VMName = $itemVM.VMName
	Get-VM -Name $VMName | Shutdown-VMGuest -Confirm:$false
	}
	
	
# Check power state
foreach($itemVM in $listVMs){
	$VMName = $itemVM.VMName
	Get-VM -Name $VMName
	}
	

# This section is to be used only for intra-cluster migrations
# If EVC mode not compatible or the hosts are not both attached to the same distributed switch, it is required for VMs to be powered off before this can be run
foreach($itemVM in $listVMs){
	$VMName = $itemVM.VMName
	if ($itemVM.TargetNetwork -ne 'None') {$TargetNetwork = Get-VDPortgroup -Name $itemVM.TargetNetwork -VDSwitch 'DVS_Prod'}
    if ($itemVM.TargetNetwork2 -ne 'None') {$TargetNetwork2 = Get-VDPortgroup -Name $itemVM.TargetNetwork2 -VDSwitch 'DVS_Prod'}
    $TargetCluster = $itemVM.TargetCluster
	$TargetFolder = $itemVM.TargetFolder
	$TargetDS = Get-DatastoreCluster -Name $itemVM.TargetDSName
	$esxhost = Get-Cluster -Name $TargetCluster | Get-VMHost | Where { $_.ConnectionState -eq "Connected" } | Get-Random
    #$TargetRP = $itemVM.TargetRP
	#$TargetRPLocation = Get-ResourcePool -Location $TargetCluster -Name $TargetRP
	
	Get-VM -Name $VMName | Move-VM -Destination $esxhost -Confirm:$false
	if ($itemVM.TargetNetwork -ne 'None') {Get-VM $VMName | Get-NetworkAdapter -Name 'Network Adapter 1' | Set-NetworkAdapter -Portgroup $TargetNetwork -Confirm:$false -RunAsync}
    if ($itemVM.TargetNetwork2 -ne 'None') {Get-VM $VMName | Get-NetworkAdapter -Name 'Network Adapter 2' | Set-NetworkAdapter -Portgroup $TargetNetwork2 -Confirm:$false -RunAsync}
	$CDDrive = Get-VM $VMName | Get-CDDrive
	$FloppyDrive = Get-VM $VMName | Get-FloppyDrive
	$USBDevice = Get-VM $VMName | Get-UsbDevice
	if ($CDDrive -ne $null) {Remove-CDDrive -CD $CDDrive -Confirm:$false}
	if ($FloppyDrive -ne $null) {Remove-FloppyDrive -Floppy $FloppyDrive -Confirm:$false}
	if ($USBDevice -ne $null) {Remove-UsbDevice -UsbDevice $USBDevice -Confirm:$false}
	# Need to test this
	#Get-VM $VMName | Get-SerialPort | Remove-SerialPort
		
	Start-VM -VM $VMName -Confirm:$false -RunAsync
	
	Get-VMQuestion | Set-VMQuestion -Option 'button.uuid.movedTheVM' -Confirm:$false
	
	# Option to svMotion after power on (remove runasync from start to work
	#Get-VM -Name $VMName | Move-VM -Datastore $TargetDS -Confirm:$false
    }
	
	



# Power On VMs
foreach($itemVM in $listVMs){
	$VMName = $itemVM.VMName
	Start-VM -VM $VMName -Confirm:$false -RunAsync
	}
	
	
# Upgrade HW version
foreach($itemVM in $listVMs){
	$VMName = $itemVM.VMName
	Set-VM -VM $VMName -Version:v10 -Confirm:$false -RunAsync
	}


# Storage vMotion VMs
foreach($itemVM in $listVMs){
	$VMName = $itemVM.VMName
	$TargetDSName = $itemVM.TargetDSName
	$TargetDS = Get-DatastoreCluster -Name $TargetDSName
	Write-Host "Ready to Migrate" $VMName 
	Pause
	Get-VM -Name $VMName | Move-VM -Datastore $TargetDS -DiskStorageFormat EagerZeroedThick -Confirm:$false -RunAsync
	}
	
	
	
# Functions to get and remove serial and parallel devices
# NEEDS TESTED
Function Get-SerialPort { 
    Param ( 
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)] 
        $VM 
    ) 
    Process { 
        Foreach ($VMachine in $VM) { 
            Foreach ($Device in $VMachine.ExtensionData.Config.Hardware.Device) { 
                If ($Device.gettype().Name -eq "VirtualSerialPort"){ 
                    $Details = New-Object PsObject 
                    $Details | Add-Member Noteproperty VM -Value $VMachine 
                    $Details | Add-Member Noteproperty Name -Value $Device.DeviceInfo.Label 
                    If ($Device.Backing.FileName) { $Details | Add-Member Noteproperty Filename -Value $Device.Backing.FileName } 
                    If ($Device.Backing.Datastore) { $Details | Add-Member Noteproperty Datastore -Value $Device.Backing.Datastore } 
                    If ($Device.Backing.DeviceName) { $Details | Add-Member Noteproperty DeviceName -Value $Device.Backing.DeviceName } 
                    $Details | Add-Member Noteproperty Connected -Value $Device.Connectable.Connected 
                    $Details | Add-Member Noteproperty StartConnected -Value $Device.Connectable.StartConnected 
                    $Details 
                } 
            } 
        } 
    } 
}

Function Remove-SerialPort { 
    Param ( 
        [Parameter(Mandatory=$True,ValueFromPipelinebyPropertyName=$True)] 
        $VM, 
        [Parameter(Mandatory=$True,ValueFromPipelinebyPropertyName=$True)] 
        $Name 
    ) 
    Process { 
        $VMSpec = New-Object VMware.Vim.VirtualMachineConfigSpec 
        $VMSpec.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec 
        $VMSpec.deviceChange[0] = New-Object VMware.Vim.VirtualDeviceConfigSpec 
        $VMSpec.deviceChange[0].operation = "remove" 
        $Device = $VM.ExtensionData.Config.Hardware.Device | Foreach { 
            $_ | Where {$_.gettype().Name -eq "VirtualSerialPort"} | Where { $_.DeviceInfo.Label -eq $Name } 
        } 
        $VMSpec.deviceChange[0].device = $Device 
        $VM.ExtensionData.ReconfigVM_Task($VMSpec) 
    } 
}
	
	
Function Get-ParallelPort { 
    Param ( 
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)] 
        $VM 
    ) 
    Process { 
        Foreach ($VMachine in $VM) { 
            Foreach ($Device in $VMachine.ExtensionData.Config.Hardware.Device) { 
                If ($Device.gettype().Name -eq "VirtualParallelPort"){ 
                    $Details = New-Object PsObject 
                    $Details | Add-Member Noteproperty VM -Value $VMachine 
                    $Details | Add-Member Noteproperty Name -Value $Device.DeviceInfo.Label 
                    If ($Device.Backing.FileName) { $Details | Add-Member Noteproperty Filename -Value $Device.Backing.FileName } 
                    If ($Device.Backing.Datastore) { $Details | Add-Member Noteproperty Datastore -Value $Device.Backing.Datastore } 
                    If ($Device.Backing.DeviceName) { $Details | Add-Member Noteproperty DeviceName -Value $Device.Backing.DeviceName } 
                    $Details | Add-Member Noteproperty Connected -Value $Device.Connectable.Connected 
                    $Details | Add-Member Noteproperty StartConnected -Value $Device.Connectable.StartConnected 
                    $Details 
                } 
            } 
        } 
    } 
}

Function Remove-ParallelPort { 
    Param ( 
        [Parameter(Mandatory=$True,ValueFromPipelinebyPropertyName=$True)] 
        $VM, 
        [Parameter(Mandatory=$True,ValueFromPipelinebyPropertyName=$True)] 
        $Name 
    ) 
    Process { 
        $VMSpec = New-Object VMware.Vim.VirtualMachineConfigSpec 
        $VMSpec.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec 
        $VMSpec.deviceChange[0] = New-Object VMware.Vim.VirtualDeviceConfigSpec 
        $VMSpec.deviceChange[0].operation = "remove" 
        $Device = $VM.ExtensionData.Config.Hardware.Device | Foreach { 
            $_ | Where {$_.gettype().Name -eq "VirtualParallelPort"} | Where { $_.DeviceInfo.Label -eq $Name } 
        } 
        $VMSpec.deviceChange[0].device = $Device 
        $VM.ExtensionData.ReconfigVM_Task($VMSpec) 
    } 
}

 
 
 