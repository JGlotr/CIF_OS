This is a pretty standard custom archiso profile, meant to do a very specific set of tasks for the University of Rochester Computer Interest Floor -- Be exceptionally easy to install, not have a GUI, and do audio-forwarding on startup.  This does all of those. 
See https://wiki.archlinux.org/title/Archiso for more information on Archiso.  

To make an ISO, run 
sudo mkarchiso -v -r -w /tmp/archiso-tmp -o /mnt ~/archlive/
This presumes the file archlive is in your user direcory, and you would like to put the ISO in your mnt directory.  

To install the OS, simply boot into the ISO, then run 
bash install.sh

You need a 250 GB drive by default, and must boot via UEFI.  
Should you wish to edit any settings, you can edit install.sh and edit the user configuration section.  

This may get updated in the future to function with more features, but this is very much no a priority for myself, or CIF, since it works for what it needs to do, and other things need to get done.  
