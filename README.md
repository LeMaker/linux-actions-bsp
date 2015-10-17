The Source Code for the S500 SOC is based on the Actions SDK. We have re-adjusted the structure of directory, and fix some bugs for the LeMaker Guitar.
It includes the "linux kernel (linux-actions)" "u-boot (u-boot-actions)" and "owl-actions" and so on, the "owl-actions" directory that includes some tools, 
scripts and configuration of the different boards.

## Usage
	1. /configure           # choose different boards type according to your needs  
	2. make hwpack          # make platform firmware package  

## Help informaiton
You can type the command **'make help'** to get more operations, as follows:    

	make hwpack          - Builds platform firmware package
	make linux           - Builds linux kernel   
	make linux-clean     - Clean linux kernel  
	make linux-config    - Menuconfig  
	make uboot           - Builds u-boot  
	make uboot-config    - Menuconfig  
	make uboot-clean     - Clean uboot  
	make clean           - Clean all object files

For more information about the using of the *linux-actions-bsp*, please visit the LeMaker wiki at <http://wiki.lemaker.org/LeMaker_Guitar:How_to_use_LeMaker_Guitar_SDK>

## Firmware Package
The source code will generate a Linux Platform Firmware with *"xxx.hwpack.tar.xz"* when you run the command **'make hwpack'**, and the package will be saved to the directory **"output"**.  
If you want to make system image based on the Firmware package, please visit the LeMaker wiki at: <http://wiki.lemaker.org/LeMaker_Guitar:How_to_make_LeMaker_Guitar_OS_image>

## Attentions
If you compile with the Source Code with normal user, may ask you to type the *user passwd* in this process.

## Feedback and Improvements
If you meet some bugs, you can fix it and feel free to contribute your code to the Repository. Of course, you can also report bugs to <http://bugs.lemaker.org/>
