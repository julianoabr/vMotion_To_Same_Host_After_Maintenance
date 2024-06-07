# vMotion_To_Same_Host_After_Maintenance
Sometimes you need to do a maintenance in ESXi Host. 
DRS move VMs to other Hosts according to an algorithm.
In some environments VMs need to stay in a specific Host. 
This script get VMs that are running on a Host then the script is paused. After you do the maintenance, script move VMs back to the Host where they run before maintenance.
