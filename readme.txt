FPGA used - NEXYS 4 DDR
HDL used - Verilog 
Software used - Vivado Hls edition
Output - VGA (640*480 px)

## Generating Coefficient file (.coe file)
The python code is divided into three parts. The first part is converting the image into a grayscale image file. The python file used in this process is the bnw.py in the folder coegen_python. The Output will be the grayscale image in the allocated directory. The second file does the job of generating 8 parallel images. These images have one pixel shifted. This process of sifting is done with all X and -X, Y and -Y direction and their combinations. Now, the next task is to create the kernel from these images. For this, the parallel generated images are the input to the third python code. The third python code is taking all those 9 images as an input and generating a coe file which is essential for generating a Block Random Access Memory (BRAM). 

## Block RAM generation -
To apply a filter on an image using FPGA we need to store the coefficient file of the image in the block memory of the FPGA. To store an image, FPGA provides us with the block memory from which we can instantiate the input image inside the main module. To generate the block RAM, select the "IP catalog" menu and then "Block Memory Generation", browse the COE file of the image and change the width and depth according to the rows and columns in the coe file. The project is done with the images of the size 160X115px.
After the generation of block RAM is completed, we can instantiate the image in the top module.

## Top module
The next step is the application of filters. The data from BRAM is accessed in a fashion of one pixel after the other. The accessing was done by the application of one 'always' block. That always block takes in the value as one address at a time which contains the details of the nearby 8 pixels which are going to form a 3X3 matrix. Then the obtained data is processed through the different filters which then is displayed on VGA. The VGA display is in the upper always block which is generating the hsync and vsync flags which tells the VGA to when to change the direction.The upper block consists of variable vc and hc which are corresponding to the horizontal location and vertical location of the pixel. when pixel reaches its horizontal hsync becomes 1, and vsync becomes 1 when it reaches at bottom. The variables hblank and vblank just deal with the blank region starting and ending. 
There are many filters inside the second always block which are applied to the selection of particular sel1 and sel2. The sel is a register for us to select one of the images. The VGA works with the refresh rate of 60HZ and each pixel is refreshed one after the other. The pixel value moves from the (0,0) and travels to (524,799).




#HOW TO APPLY FILTERS USING FPGA 
Download the complete Folder and all its files. 
To generate your own .coe file and kernel follow the steps as mentioned:- 
Remember that the image should be of 160*115 px only.
1.	 go to the folder named “Coegen_python” and convert your RGB image to grayscale using “gray_image_gen.py”. 
2.	Then input this newly formed grayscale image and original image in “parallel_image.py”. This will output you 8 grayscale images and 1 gray image obtained from the above step. 
3.	Input all these 9 gray images inside “kernel_coe_gen.py” to get an “image.coe” file.  

We also have some ready-made .coe kernel files for you to implement. Get these files inside the folder named “Images”. Open any image and download its .coe file. 
Now To implement all this on FPGA , open VIVADA Hx XLS edition. We have implemented the filters on Nexys 4 DDR board. 
1.	Open the folder named “FIlters” and open the file named “nexys_final.xpr”. 
2.	Go to IP catalog and open “Block Ram Generator”.
3.	Select “Enable all ports” under the section “Port A options”. Set Write Width and Read Wdth to “96” and Write Depth and Read Depth to “18402”. 
4.	Go to “Other Options” tab and load your .coe init file and press “OK”. 
5.	Now connect your Nexys 4 board to laptop using USB and then press “Generate Bitstream”. 
6.	Wait for the bitstream generation to complete and then open “Hardware manager”. 
7.	Press “Open Target” then press “Auto connect”, then after the board is connected press “Program Device”. 

## Inputs to the FPGA - 

To see and compare various filters that we have implemented, you have to give the input to the FPGA. There is a total of 10 inputs available. One input (SW0) is for RESET and one (SW1) is for choosing one of the two images (as we have stored two images in the BRAM for a time). The switches from (SW3 - SW6) are for the top-left image on the VGA screen. The switches from (SW7 - SW10) are for the bottom-right image on the VGA screen. Following are the binary codes for the filters -  

1.	0000 - Original Image
2.	0001 - Grayscale Image
3.	0010 - Prewitt Y
4.	0011 - Colour VGA Red Laplacian 4* edge detection
5.	0100 - Sobel edge detection
6.	0101 - Gaussian filter\
7.	0110 - Laplacian 8* edge detection
8.	0111 - Colour VGA Red Laplacian 8* edge detection
9.	1000 - Robinson Mask Northwest / Southeast
10.	1001 - Laplacian 4* edge detection
11.	1010 - Prewitt X
12.	1011 - Colour VGA Red Prewitt X
13.	1100 - Sobel X
14.	1101 - Colour VGA Red Sobel X
15.	1110 - Sobel Y
16.	1111 - Colour VGA Red Sobel Y 



