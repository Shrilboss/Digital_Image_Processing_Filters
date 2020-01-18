`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: filters
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module filters(
clock,reset,                        //reset(active high) // clock which will be our input
sel1, sel2,sel,                      //sel1:chosing filter on left image ; sel2:chosing filter on right image ; sel:chosing image
hsync,vsync,                        // hsync and vsync for the working of monitor
vgaRed, vgaGreen, vgaBlue           // vgaRed, vgaGreen and vgaBlue 
);                                  // output pixels which will be displayed as pixel value
                                    // for a particular pixel.

    input clock;
    input reset;        
    input[3:0] sel1,sel2;       
    input [0:0] sel;           
    reg [7:0] gray, left, right, up, down, leftup, leftdown, rightup, rightdown;
    reg[7:0] out_r, out_b, out_g;            // variables used during calcultion
    reg [15:0] r, b, g;                         // variables used during calcultion
    
    
   reg clk; // intermediate clk reqiured as we need to convert 100MHz of our board to 25MHz pixel frequency
   initial begin
   clk =0;
   end
   always@(posedge clock)
   begin
    clk<=~clk; // making the clk a 50MHz clk
   end
   
    output reg hsync; // output flag which direct VGA
    output reg vsync;// output flag which direct VGA
    reg [7:0] tvgaRed,tvgaGreen,tvgaBlue; // required registers for stroring centre pixel RGB
    output reg [3:0] vgaRed,vgaGreen; // VGA outputs 
    output reg [3:0] vgaBlue; // VGA outputs
 
	reg read = 0; // variable for inputing into BRAM module variable
	reg [14:0] addra = 0; // address of pixels
	reg [95:0] in1 = 0; //write input for first BRAM
	wire [95:0] out1;// output of first BRAM
    reg [95:0] in2 = 0; // input second BRAM
	wire [95:0] out2; // output of second BRAM
    reg [95:0] out; // out variable used in further calculations


    reg [8:0]prewxp; // variables for the calculations related to prewitt filter
    reg [8:0]prewxn; // variables for calculations of prewitt filter
    reg [8:0]prewyp; // // variables for the calculations related to prewitt filter
    reg [8:0]prewyn;// variables for the calculations related to prewitt filter
    reg [8:0]laplp; //for calculations related to laplacian filter
    reg [8:0]lapln; // for calculations related to laplacian filter
	
	
	// block ram for the first input image
blk_mem_gen_0 inst1(
  .clka(clk),
  .wea(read), 
  .addra(addra),
  .dina(in1), 
  .douta(out1)
);
// second image
blk_parrotproper  inst2(
  .clka(clk),
  .wea(read), 
  .addra(addra),
  .dina(in2), 
  .douta(out2)
);

   wire pixel_clk; // final clock which needs to be used as pixel clk.
   reg 		pcount = 0; // variable for actually making a 25MHz clock
   wire 	ec = (pcount == 0); // negation of pcount.
   always @ (posedge clk) pcount <= ~pcount;
   assign 	pixel_clk = ec; // 25 MHz clock in form of wire
   
   reg 		hblank=0,vblank=0; // variables related to position of pixel
   initial begin
   hsync =0;
   vsync=0;
   end
   reg [9:0] 	hc=0; // horizontal location of pixel
   reg [9:0] 	vc=0; // vertical location of pixel
	
   wire 	hsyncon,hsyncoff,hreset,hblankon; // these variables signify the flahgs which tells the region for hsync =1 
   assign 	hblankon = ec & (hc == 639);    // start alert blank area in x direction 640 X 480
   assign 	hsyncon = ec & (hc == 655); // region alert for turning on hsync =1
   assign 	hsyncoff = ec & (hc == 751); // region alert for turning hsync =0
   assign 	hreset = ec & (hc == 799);  // tells that if horizontal location is too far then ee need to reset it.
   // ec is basicallly the doing the process after the posedge as it is the negation of the pixel clk
   // after posedge of ec if these conditions apply then change corresponding variables is the meaning of this above block.
   wire 	blank =  (vblank | (hblank & ~hreset));     //signifies the v ertial blank or horizontal blank or reset region
   
   wire 	vsyncon,vsyncoff,vreset,vblankon; // very similar to horizontal
   assign 	vblankon = hreset & (vc == 479);   
   assign 	vsyncon = hreset & (vc == 490);
   assign 	vsyncoff = hreset & (vc == 492);
   assign 	vreset = hreset & (vc == 523);
   always @(posedge clk) begin
   hc <= ec ? (hreset ? 0 : hc + 1) : hc; // if its after posedge of ec or we can say before posedge of pixel clk ifpixel is too far then do make its counter zero or increament in else case
   hblank <= hreset ? 0 : hblankon ? 1 : hblank; // you are in a blank region if reset condition or hblankon is already 1.
   hsync <= hsyncon ? 0 : hsyncoff ? 1 : hsync; // if horizontal sync range is there then make hsync 0 which will instruct VGA pixel to change path or if range is over then make hsync =1 else keep it as it is
   
   vc <= hreset ? (vreset ? 0 : vc + 1) : vc; // very similar to horizontal but only hreset also needs to be considered as movement of pixel is line by line horizontally
   vblank <= vreset ? 0 : vblankon ? 1 : vblank;
   vsync <= vsyncon ? 0 : vsyncoff ? 1 : vsync;
   end
   
   
always @(posedge pixel_clk)
	begin		
            if(blank == 0 && hc >= 100 && hc < 260 && vc >= 100 && vc < 215) // this basiclly goes and displays something if we are in the size range of our image
            begin
                if(sel==2'b00) begin
                    out = out1;
                end else if(sel==2'b01) begin
                        out = out2;
                end 

                gray =  {out[95], out[94], out[93], out[92], out[91], out[90], out[89], out[88]}; // middle pixel grayscale scale value in 3 X 3 pixel. 

                left = {out[87], out[86], out[85], out[84], out[83], out[82], out[81], out[80]}; // grayscale value of pixel just left to middle in 3 X 3
                right = {out[79], out[78], out[77], out[76], out[75], out[74], out[73], out[72]};// grayscale value of pixel just right to middle in 3 X 3
                up =  {out[71], out[70], out[69], out[68], out[67], out[66], out[65], out[64]}; // grayscale value of pixel just up above the middle pixel in 3 X 3 
                down = {out[63], out[62], out[61], out[60], out[59], out[58], out[57], out[56]}; 

                leftup = {out[55], out[54], out[53], out[52], out[51], out[50], out[49], out[48]};
                leftdown =  {out[47], out[46], out[45], out[44], out[43], out[42], out[41], out[40]}; // left down means one step left and one down in 3 X 3 kernel
                rightup = {out[39], out[38], out[37], out[36], out[35], out[34], out[33], out[32]};
                rightdown = {out[31], out[30], out[29], out[28], out[27], out[26], out[25], out[24]};

                tvgaBlue =  {out[23], out[22], out[21], out[20], out[19], out[18], out[17], out[16]}; //centre pixel rgb
                tvgaGreen = {out[15], out[14], out[13], out[12], out[11], out[10], out[9], out[8]};
                tvgaRed = {out[7], out[6], out[5], out[4], out1[3], out[2], out[1], out[0]};
            
                
                 
                    if(sel1 == 4'b0000)begin  //original
                            if(reset) begin
                                vgaRed = 0;
                                vgaGreen = 0;
                                vgaBlue = 0;
                            end
                            else begin
                                out_r = tvgaRed/16; // direct display of rgb
                                out_b = tvgaBlue/16;
                                out_g = tvgaGreen/16;
                                vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};
                              end
                   end else if(sel1 == 4'b0001)begin  //1.grayscale

                                if(reset) begin
                                    vgaRed = 0;
                                    vgaGreen = 0;
                                    vgaBlue = 0;
                                end else begin
                                    out_r = (tvgaRed >> 2) + (tvgaRed >> 5) + (tvgaGreen >> 1) + (tvgaGreen >> 4)+ (tvgaBlue >> 4) + (tvgaBlue >> 5);
                                    out_g = (tvgaRed >> 2) + (tvgaRed >> 5) + (tvgaGreen >> 1) + (tvgaGreen >> 4)+ (tvgaBlue >> 4) + (tvgaBlue >> 5);
                                    out_b = (tvgaRed >> 2) + (tvgaRed >> 5) + (tvgaGreen >> 1) + (tvgaGreen >> 4)+ (tvgaBlue >> 4) + (tvgaBlue >> 5);
                                    // calculating corresponding grayscale value and putting in rgb
                                    out_r = out_r/16;
                                    out_b = out_b/16;
                                    out_g = out_g/16;

                                    vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                    vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                    vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};
                                end
                        
                    end else if(sel1 == 4'b0010)begin     //2.prewitt y
                                        if(reset) begin
                                                vgaRed = 0;
                                                vgaGreen = 0;
                                                vgaBlue = 0;
                                        end else begin

                                            prewyp = leftup + up + rightup;
                                            prewyn = leftdown + down + rightdown;
                                            // taking positive and negative part separately and comparing and taking mod of difference
                                           // this positive and negative occur in convolution matrix of prewitt operator
                                            b = (prewyp>prewyn)?(prewyp-prewyn):(prewyn-prewyp);
                                            g=b;
                                                if(g>255)
                                                    begin
                                                        out_b = 255;
                                                        out_r = 255;
                                                        out_g = 255;
                                                    end
                                                else
                                                    begin
                                                    out_r = g[7:0];
                                                    out_b = g[7:0];
                                                    out_g = g[7:0];
                                                    end

                                            out_r = out_r/16;
                                            out_b = out_b/16;
                                            out_g = out_g/16;
                                            vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                            vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                            vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};
                                        end
                                       
                    end else if(sel1 == 4'b0011)begin  //3.colouvgaRed .laplacian 4* edge detection
                                        if(reset) begin
                                            vgaRed = 0;
                                            vgaGreen = 0;
                                            vgaBlue = 0;
                                        end else begin
                                            r =((4*gray) - left - right - up - down );
                                            if(r > 1024)begin
                                                    out_r = 255;
                                                    out_b = 0;
                                                    out_g = 0;
                                                end else if(r > 255) begin
                                                        out_r = 255;
                                                        out_b = 255;
                                                        out_g = 255;
                                                end else begin
                                                    out_r = tvgaRed;
                                                    out_b = tvgaBlue;
                                                    out_g = tvgaGreen;
                                                end

                                                out_r = out_r/16;
                                                out_b = out_b/16;
                                                out_g = out_g/16;
                                                vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                                vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                                vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};
                                        end
 end
         else if(sel1 == 4'b0100)begin  // 4.sobel edge detection
                                        if(reset) begin
                                            vgaRed = 0;
                                            vgaGreen = 0;
                                            vgaBlue = 0;
                                        end else begin
                                                r = ((rightup)- leftup + (2*right) - (2*left) + rightdown - leftdown);
                                                g = ((rightup) + (2*up) + leftup - rightdown - (2*down) - leftdown);
                                                // very similar process as prewitt
                                                if(r > 1024 & g > 1024)begin
                                                    b = -(r + g)/2;
                                                end else if(r > 1024 & g < 1024)begin
                                                    b = (-r  + g)/2;
                                                end else if(r < 1024 & g < 1024)begin
                                                    b = (r + g)/2;
                                                end else begin
                                                    b = (r - g)/2;
                                                end
                                                out_r = b;
                                                out_b = b;
                                                out_g = b;
                                                out_r = out_r/16;
                                                out_b = out_b/16;
                                                out_g = out_g/16;
                                                vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                                vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                                vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};

                                        end

                    end 
                    
                  else if(sel1 == 4'b0101)begin ///// 5.gaussian filter
                    if(reset) begin
                            vgaRed = 0;
                            vgaGreen = 0;
                            vgaBlue = 0;
                        end else begin
                              r = (rightup  + (2*up) + leftup + (2*right) + (4*gray) + (2*left) + rightdown + (2*down) + (2*leftdown));
                              r=r/16;
                               out_r = r;
                               out_b = r;
                               out_g = r;
                            // applying gaussian filter for blurring
                            out_r = out_r/16;
                           out_b = out_b/16;
                           out_g = out_g/16;
                         
                           vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                           vgaGreen = {out_b[3],out_b[2], out_b[1], out_b[0]};
                           vgaBlue = {out_g[3],out_g[2], out_g[1], out_g[0]};
                         end
                         end
                    else if(sel1 == 4'b0110)begin   //6.laplacian 8* edge detection
                                        if(reset) begin
                                                vgaRed = 0;
                                                vgaGreen = 0;
                                                vgaBlue = 0;
                                        end else begin
                                                r = ((8*gray) - left - right - up - down - leftup - leftdown - rightup - rightdown);
                                                if(r > 2048)begin
                                                    out_r = 0;
                                                    out_b = 0;
                                                    out_g = 0;
                                                end else if(r > 255) begin
                                                        out_r = 255;
                                                        out_b = 255;
                                                        out_g = 255;
                                                end else begin
                                                    out_r = r;
                                                    out_b = r;
                                                    out_g = r;
                                                end

                                                out_r = out_r/16;
                                                out_b = out_b/16;
                                                out_g = out_g/16;
                                                vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                                vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                                vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};
                                        end
                         
                    end else if(sel1 == 4'b0111)begin   //7.colouvgaRed laplacian 8* edge detection
                                        if(reset) begin
                                                vgaRed = 0;
                                                vgaGreen = 0;
                                                vgaBlue = 0;
                                        end else begin
                                            r = ((8*gray) - left - right - up - down - leftup - leftdown - rightup - rightdown);
                                            if(r > 2048)begin
                                            out_r = 255;
                                            out_b = 0;
                                            out_g = 0;
                                            end else if(r > 255) begin
                                                out_r = 255;
                                                out_b = 255;
                                                out_g = 255;
                                            end else begin
                                            out_r = tvgaRed;
                                            out_b = tvgaBlue;
                                            out_g = tvgaGreen;
                                            end

                                            out_r = out_r/16;
                                            out_b = out_b/16;
                                            out_g = out_g/16;
                                            vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                            vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                            vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};
                                        end

                    end else if(sel1 == 4'b1000)begin  //8. robinson mask northwest
                                        if(reset) begin
                                            vgaRed = 0;
                                            vgaGreen = 0;
                                            vgaBlue = 0;
                                        
                                        end else begin
                                            r=up+right+(2*rightup)-left-down-2*(leftdown);
                                         if(r > 1024)begin
                                            out_r = 0;
                                            out_b = 0;
                                            out_g = 0;
                                            end
                                           else if(r > 255) begin
                                                        out_r = 255;
                                                        out_b = 255;
                                                        out_g = 255;
                                                end else begin
                                                    out_r = r;
                                                    out_b = r;
                                                    out_g = r;
                                                    
                                                end

                                                out_r = out_r/16;
                                                out_b = out_b/16;
                                                out_g = out_g/16;
                                                vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                                vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                                vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};
                                        end

                    end else if(sel1 == 4'b1001)begin   //9.laplacian 4* edge detection
                                        if(reset) begin
                                            vgaRed = 0;
                                            vgaGreen = 0;
                                            vgaBlue = 0;
                                        end else begin
                                            r =((4*gray) - left - right - up - down );
                                            if(r > 1024)begin
                                                    out_r = 0;
                                                    out_b = 0;
                                                    out_g = 0;
                                                end else if(r > 255) begin
                                                        out_r = 255;
                                                        out_b = 255;
                                                        out_g = 255;
                                                end else begin
                                                    out_r = r;
                                                    out_b = r;
                                                    out_g = r;
                                                end

                                                out_r = out_r/16;
                                                out_b = out_b/16;
                                                out_g = out_g/16;
                                                vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                                vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                                vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};
                                        end
 
                    end else if(sel1 == 4'b1010)begin  //10.prewitt x
                                        if(reset) begin
                                                vgaRed = 0;
                                                vgaGreen = 0;
                                                vgaBlue = 0;
                                        end else begin
                                            prewxp = leftup + left + leftdown;
                                            prewxn = rightup + right + rightdown;
                                            r = (prewxp>prewxn)?(prewxp-prewxn):(prewxn-prewxp);
                                            g=r;
                                            if(g>255)
                                                begin
                                                    out_b = 255;
                                                    out_r = 255;
                                                    out_g = 255;
                                                end
                                                else
                                                    begin
                                                    out_r = g[7:0];
                                                    out_b = g[7:0];
                                                    out_g = g[7:0];
                                                    end

                                            out_r = out_r/16;
                                            out_b = out_b/16;
                                            out_g = out_g/16;
                                            vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                            vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                            vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};
                                        end

                    end else if(sel1 == 4'b1011)begin  //11.colouvgaRed prewit x
                                    if(reset) begin
                                            vgaRed = 0;
                                            vgaGreen = 0;
                                            vgaBlue = 0;
                                    end else begin
                                        prewxp = leftup + left + leftdown;
                                        prewxn = rightup + right + rightdown;
                                        r = (prewxp>prewxn)?(prewxp-prewxn):(prewxn-prewxp);
                                        g=r;
                                        if(g>255)
                                            begin
                                                out_b = 0;
                                                out_r = 255;
                                                out_g = 0;
                                        end else begin
                                                out_r = tvgaRed;
                                                out_b = tvgaBlue;
                                                out_g = tvgaGreen;
                                        end

                                        out_r = out_r/16;
                                        out_b = out_b/16;
                                        out_g = out_g/16;
                                        vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                        vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                        vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};
                                    end

                    end else if(sel1 == 4'b1100)begin  //12.sobel x
                                        
                                        if(reset) begin
                                            vgaRed = 0;
                                            vgaGreen = 0;
                                            vgaBlue = 0;
                                        end else begin
                                            r = leftup + 2*left +leftdown;
                                            b = rightup + 2*right + rightdown;
                                            g = (r>b)?(r-b):(b-r);
                                            if(g>255)
                                            begin
                                                out_r = 255;
                                                out_g = 255;
                                                out_b = 255;
                                            end
                                            else
                                            begin
                                                out_r = g[7:0];
                                                out_b = g[7:0];
                                                out_g = g[7:0];
                                            end

                                            out_r = out_r/16;
                                            out_b = out_b/16;
                                            out_g = out_g/16;
                                            vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                            vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                            vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};
                                    end

                    end else if(sel1 == 4'b1101)begin //13.colouvgaRed sobel x
                                        if(reset) begin
                                                vgaRed = 0;
                                                vgaGreen = 0;
                                                vgaBlue = 0;
                                            end 
                                        else begin 
                                            r = leftup + 2*left +leftdown;
                                            b = rightup + 2*right + rightdown;
                                            g = (r>b)?(r-b):(b-r);
                                            if(g>255)
                                            begin
                                            out_r = 255;
                                            out_g = 0;
                                            out_b = 0;
                                            end
                                            else
                                            begin
                                                out_r = tvgaRed;
                                                out_b = tvgaBlue;
                                                out_g = tvgaGreen;
                                            end

                                            out_r = out_r/16;
                                            out_b = out_b/16;
                                            out_g = out_g/16;
                                            vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                            vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                            vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};
                                        end

                    end else if(sel1 == 4'b1110)begin  //14.sobel y
                                        if(reset) begin
                                            vgaRed = 0;
                                            vgaGreen = 0;
                                            vgaBlue = 0;
                                        end else begin
                                            r = leftup + 2*up +rightup;
                                            b = leftdown + 2*down + rightdown;
                                            g = (r>b)?(r-b):(b-r);
                                            if(g>255)
                                            begin
                                            out_r = 0;
                                            out_g = 0;
                                            out_b = 0;
                                            end
                                            else
                                            begin
                                                out_r = g[7:0];
                                                out_b = g[7:0];
                                                out_g = g[7:0];
                                            end

                                            out_r = out_r/16;
                                            out_b = out_b/16;
                                            out_g = out_g/16;
                                            vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                            vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                            vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};
                                        end

                    end else if(sel1 == 4'b1111)begin   //15.colouvgaRed sobel y
                                        if(reset) begin
                                            vgaRed = 0;
                                            vgaGreen = 0;
                                            vgaBlue = 0;
                                        end else begin
                                            r = leftup + 2*up +rightup;
                                            b = leftdown + 2*down + rightdown;
                                            g = (r>b)?(r-b):(b-r);
                                            if(g>255)
                                            begin
                                            out_r = 255;
                                            out_g = 0;
                                            out_b = 0;
                                            end
                                            else
                                            begin
                                                out_r = tvgaRed;
                                                out_b = tvgaBlue;
                                                out_g = tvgaGreen;
                                            end

                                            out_r = out_r/16;
                                            out_b = out_b/16;
                                            out_g = out_g/16;
                                            vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                            vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                            vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};
                                        end
                    
                    end 
                    if(addra <18399)
                        addra = addra + 1;
                    else
                        addra = 0;
            end else if(blank == 0 && hc >= 262 && hc < 422 && vc >= 217 && vc < 332) begin
            // this part is basically for the display of second image in VGA
                if(sel==2'b00) begin
                    out = out1;
                end else if(sel==2'b01) begin
                        out = out2;
                end
                    
                gray =  {out[95], out[94], out[93], out[92], out[91], out[90], out[89], out[88]};

                left = {out[87], out[86], out[85], out[84], out[83], out[82], out[81], out[80]};
                right = {out[79], out[78], out[77], out[76], out[75], out[74], out[73], out[72]};
                up =  {out[71], out[70], out[69], out[68], out[67], out[66], out[65], out[64]};
                down = {out[63], out[62], out[61], out[60], out[59], out[58], out[57], out[56]};

                leftup = {out[55], out[54], out[53], out[52], out[51], out[50], out[49], out[48]};
                leftdown =  {out[47], out[46], out[45], out[44], out[43], out[42], out[41], out[40]};
                rightup = {out[39], out[38], out[37], out[36], out[35], out[34], out[33], out[32]};
                rightdown = {out[31], out[30], out[29], out[28], out[27], out[26], out[25], out[24]};

                tvgaBlue =  {out[23], out[22], out[21], out[20], out[19], out[18], out[17], out[16]};
                tvgaGreen = {out[15], out[14], out[13], out[12], out[11], out[10], out[9], out[8]};
                tvgaRed = {out[7], out[6], out[5], out[4], out1[3], out[2], out[1], out[0]};
                
                    if(sel2 == 4'b0000)begin  //0.original
                            if(reset) begin
                                vgaRed = 0;
                                vgaGreen = 0;
                                vgaBlue = 0;
                            end
                            else begin
                                out_r = tvgaRed/16;
                                out_b = tvgaBlue/16;
                                out_g = tvgaGreen/16;
                                vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};
                              end
                   end else if(sel2 == 4'b0001)begin  //1.grayscale

                                if(reset) begin
                                    vgaRed = 0;
                                    vgaGreen = 0;
                                    vgaBlue = 0;
                                end else begin
                                    out_r = (tvgaRed >> 2) + (tvgaRed >> 5) + (tvgaGreen >> 1) + (tvgaGreen >> 4)+ (tvgaBlue >> 4) + (tvgaBlue >> 5);
                                    out_g = (tvgaRed >> 2) + (tvgaRed >> 5) + (tvgaGreen >> 1) + (tvgaGreen >> 4)+ (tvgaBlue >> 4) + (tvgaBlue >> 5);
                                    out_b = (tvgaRed >> 2) + (tvgaRed >> 5) + (tvgaGreen >> 1) + (tvgaGreen >> 4)+ (tvgaBlue >> 4) + (tvgaBlue >> 5);

                                    out_r = out_r/16;
                                    out_b = out_b/16;
                                    out_g = out_g/16;

                                    vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                    vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                    vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};
                                end
                        
                    end else if(sel2 == 4'b0010)begin     //2.prewitt y
                                        if(reset) begin
                                                vgaRed = 0;
                                                vgaGreen = 0;
                                                vgaBlue = 0;
                                        end else begin

                                            prewyp = leftup + up + rightup;
                                            prewyn = leftdown + down + rightdown;

                                            b = (prewyp>prewyn)?(prewyp-prewyn):(prewyn-prewyp);
                                            g=b;
                                                if(g>255)
                                                    begin
                                                        out_b = 255;
                                                        out_r = 255;
                                                        out_g = 255;
                                                    end
                                                else
                                                    begin
                                                    out_r = g[7:0];
                                                    out_b = g[7:0];
                                                    out_g = g[7:0];
                                                    end

                                            out_r = out_r/16;
                                            out_b = out_b/16;
                                            out_g = out_g/16;
                                            vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                            vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                            vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};
                                        end
                                       
                    end else if(sel2 == 4'b0011)begin  //3.colouvgaRed prewit y
                                        if(reset) begin
                                            vgaRed = 0;
                                            vgaGreen = 0;
                                            vgaBlue = 0;
                                        end else begin

                                                prewyp = leftup + up + rightup;
                                                prewyn = leftdown + down + rightdown;

                                                b = (prewyp>prewyn)?(prewyp-prewyn):(prewyn-prewyp);
                                                g=b;
                                                    if(g>255)
                                                        begin
                                                            out_b = 0;
                                                            out_r = 255;
                                                            out_g = 0;
                                                        end
                                                        else
                                                            begin
                                                            out_r = tvgaRed;
                                                            out_b = tvgaBlue;
                                                            out_g = tvgaGreen;
                                                            end

                                            out_r = out_r/16;
                                            out_b = out_b/16;
                                            out_g = out_g/16;
                                            vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                            vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                            vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};
                                        end
                                            
                    end else if(sel2 == 4'b0100)begin  // 4.sobel edge detection
                                        if(reset) begin
                                            vgaRed = 0;
                                            vgaGreen = 0;
                                            vgaBlue = 0;
                                        end else begin
                                                r = ((rightup)- leftup + (2*right) - (2*left) + rightdown - leftdown);
                                                g = ((rightup) + (2*up) + leftup - rightdown - (2*down) - leftdown);

                                                if(r > 1024 & g > 1024)begin
                                                    b = -(r + g)/2;
                                                end else if(r > 1024 & g < 1024)begin
                                                    b = (-r  + g)/2;
                                                end else if(r < 1024 & g < 1024)begin
                                                    b = (r + g)/2;
                                                end else begin
                                                    b = (r - g)/2;
                                                end
                                                out_r = b;
                                                out_b = b;
                                                out_g = b;
                                                out_r = out_r/16;
                                                out_b = out_b/16;
                                                out_g = out_g/16;
                                                vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                                vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                                vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};

                                        end

                    end else if(sel2 == 4'b0101)begin  //5.gaussian blur
                                        if(reset) begin
                            vgaRed = 0;
                            vgaGreen = 0;
                            vgaBlue = 0;
                        end else begin
                              r = (rightup  + (2*up) + leftup + (2*right) + (4*gray) + (2*left) + rightdown + (2*down) + (2*leftdown));
                              r=r/16;
                               out_r = r;
                               out_b = r;
                               out_g = r;
                            
                            out_r = out_r/16;
                           out_b = out_b/16;
                           out_g = out_g/16;
                         
                           vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                           vgaGreen = {out_b[3],out_b[2], out_b[1], out_b[0]};
                           vgaBlue = {out_g[3],out_g[2], out_g[1], out_g[0]};
                         end
                
                    end else if(sel2 == 4'b0110)begin   //6.laplacian 8* edge detection
                                        if(reset) begin
                                                vgaRed = 0;
                                                vgaGreen = 0;
                                                vgaBlue = 0;
                                        end else begin
                                                r = ((8*gray) - left - right - up - down - leftup - leftdown - rightup - rightdown);
                                                if(r > 2048)begin
                                                    out_r = 0;
                                                    out_b = 0;
                                                    out_g = 0;
                                                end else if(r > 255) begin
                                                        out_r = 255;
                                                        out_b = 255;
                                                        out_g = 255;
                                                end else begin
                                                    out_r = r;
                                                    out_b = r;
                                                    out_g = r;
                                                end

                                                out_r = out_r/16;
                                                out_b = out_b/16;
                                                out_g = out_g/16;
                                                vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                                vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                                vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};
                                        end
                         
                    end else if(sel2 == 4'b0111)begin   //7.colouvgaRed laplacian 8* edge detection
                                        if(reset) begin
                                                vgaRed = 0;
                                                vgaGreen = 0;
                                                vgaBlue = 0;
                                        end else begin
                                            r = ((8*gray) - left - right - up - down - leftup - leftdown - rightup - rightdown);
                                            if(r > 2048)begin
                                            out_r = 255;
                                            out_b = 0;
                                            out_g = 0;
                                            end else if(r > 255) begin
                                                out_r = 255;
                                                out_b = 255;
                                                out_g = 255;
                                            end else begin
                                            out_r = tvgaRed;
                                            out_b = tvgaBlue;
                                            out_g = tvgaGreen;
                                            end

                                            out_r = out_r/16;
                                            out_b = out_b/16;
                                            out_g = out_g/16;
                                            vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                            vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                            vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};
                                        end

                    end else if(sel2 == 4'b1000)begin  //8.robinson mask south east
                                        if(reset) begin
                                            vgaRed = 0;
                                            vgaGreen = 0;
                                            vgaBlue = 0;
                                                
                                        end else begin
                                            r=-up-right-(2*rightup)+left+down+2*(leftdown);
                                            if(r > 1024)begin
                                            out_r = 0;
                                            out_b = 0;
                                            out_g = 0;
                                            end
                                           else  if(r > 255) begin
                                                        out_r = 255;
                                                        out_b = 255;
                                                        out_g = 255;
                                                end else begin
                                                    out_r = r;
                                                    out_b = r;
                                                    out_g = r;
                                                    
                                                end

                                                out_r = out_r/16;
                                                out_b = out_b/16;
                                                out_g = out_g/16;
                                                vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                                vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                                vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};
                                        end

                    end else if(sel2 == 4'b1001)begin   //9.laplacian 4*edge detection
                                        if(reset) begin
                                            vgaRed = 0;
                                            vgaGreen = 0;
                                            vgaBlue = 0;
                                        end else begin
                                            
                                             r =((4*gray) - left - right - up - down );
                                           if(r > 1024)begin
                                                    out_r = 0;
                                                    out_b = 0;
                                                    out_g = 0;
                                                end else if(r > 255) begin
                                                        out_r = 255;
                                                        out_b = 255;
                                                        out_g = 255;
                                                end else begin
                                                    out_r = r;
                                                    out_b = r;
                                                    out_g = r;
                                                end

                                                out_r = out_r/16;
                                                out_b = out_b/16;
                                                out_g = out_g/16;
                                                vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                                vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                                vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};
                                        end
 
                    end else if(sel2 == 4'b1010)begin  //10.prewitt x
                                        if(reset) begin
                                                vgaRed = 0;
                                                vgaGreen = 0;
                                                vgaBlue = 0;
                                        end else begin
                                            prewxp = leftup + left + leftdown;
                                            prewxn = rightup + right + rightdown;
                                            r = (prewxp>prewxn)?(prewxp-prewxn):(prewxn-prewxp);
                                            g=r;
                                            if(g>255)
                                                begin
                                                    out_b = 255;
                                                    out_r = 255;
                                                    out_g = 255;
                                                end
                                                else
                                                    begin
                                                    out_r = g[7:0];
                                                    out_b = g[7:0];
                                                    out_g = g[7:0];
                                                    end

                                            out_r = out_r/16;
                                            out_b = out_b/16;
                                            out_g = out_g/16;
                                            vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                            vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                            vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};
                                        end

                    end else if(sel2 == 4'b1011)begin  //11.colouvgaRed prewit x
                                    if(reset) begin
                                            vgaRed = 0;
                                            vgaGreen = 0;
                                            vgaBlue = 0;
                                    end else begin
                                        prewxp = leftup + left + leftdown;
                                        prewxn = rightup + right + rightdown;
                                        r = (prewxp>prewxn)?(prewxp-prewxn):(prewxn-prewxp);
                                        g=r;
                                        if(g>255)
                                            begin
                                                out_b = 0;
                                                out_r = 255;
                                                out_g = 0;
                                        end else begin
                                                out_r = tvgaRed;
                                                out_b = tvgaBlue;
                                                out_g = tvgaGreen;
                                        end

                                        out_r = out_r/16;
                                        out_b = out_b/16;
                                        out_g = out_g/16;
                                        vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                        vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                        vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};
                                    end

                    end else if(sel2 == 4'b1100)begin  //12.sobel x
                                        if(reset) begin
                                            vgaRed = 0;
                                            vgaGreen = 0;
                                            vgaBlue = 0;
                                        end else begin
                                            r = leftup + 2*left +leftdown;
                                            b = rightup + 2*right + rightdown;
                                            g = (r>b)?(r-b):(b-r);
                                            if(g>255)
                                            begin
                                                out_r = 255;
                                                out_g = 255;
                                                out_b = 255;
                                            end
                                            else
                                            begin
                                                out_r = g[7:0];
                                                out_b = g[7:0];
                                                out_g = g[7:0];
                                            end

                                            out_r = out_r/16;
                                            out_b = out_b/16;
                                            out_g = out_g/16;
                                            vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                            vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                            vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};
                                    end

                    end else if(sel2 == 4'b1101)begin //13.colouvgaRed sobel x
                                        if(reset) begin
                                                vgaRed = 0;
                                                vgaGreen = 0;
                                                vgaBlue = 0;
                                            end 
                                        else begin 
                                            r = leftup + 2*left +leftdown;
                                            b = rightup + 2*right + rightdown;
                                            g = (r>b)?(r-b):(b-r);
                                            if(g>255)
                                            begin
                                            out_r = 255;
                                            out_g = 0;
                                            out_b = 0;
                                            end
                                            else
                                            begin
                                                out_r = tvgaRed;
                                                out_b = tvgaBlue;
                                                out_g = tvgaGreen;
                                            end

                                            out_r = out_r/16;
                                            out_b = out_b/16;
                                            out_g = out_g/16;
                                            vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                            vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                            vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};
                                        end

                    end else if(sel2 == 4'b1110)begin  //14.sobel y
                                        if(reset) begin
                                            vgaRed = 0;
                                            vgaGreen = 0;
                                            vgaBlue = 0;
                                        end else begin
                                            r = leftup + 2*up +rightup;
                                            b = leftdown + 2*down + rightdown;
                                            g = (r>b)?(r-b):(b-r);
                                            if(g>255)
                                            begin
                                            out_r = 0;
                                            out_g = 0;
                                            out_b = 0;
                                            end
                                            else
                                            begin
                                                out_r = g[7:0];
                                                out_b = g[7:0];
                                                out_g = g[7:0];
                                            end

                                            out_r = out_r/16;
                                            out_b = out_b/16;
                                            out_g = out_g/16;
                                            vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                            vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                            vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};
                                        end

                    end else if(sel2 == 4'b1111)begin   //15.colouvgaRed sobel y
                                        if(reset) begin
                                            vgaRed = 0;
                                            vgaGreen = 0;
                                            vgaBlue = 0;
                                        end else begin
                                            r = leftup + 2*up +rightup;
                                            b = leftdown + 2*down + rightdown;
                                            g = (r>b)?(r-b):(b-r);
                                            if(g>255)
                                            begin
                                            out_r = 255;
                                            out_g = 0;
                                            out_b = 0;
                                            end
                                            else
                                            begin
                                                out_r = tvgaRed;
                                                out_b = tvgaBlue;
                                                out_g = tvgaGreen;
                                            end

                                            out_r = out_r/16;
                                            out_b = out_b/16;
                                            out_g = out_g/16;
                                            vgaRed = {out_r[3],out_r[2], out_r[1], out_r[0]};
                                            vgaGreen = {out_g[3],out_g[2], out_g[1], out_g[0]};
                                            vgaBlue = {out_b[3],out_b[2], out_b[1], out_b[0]};
                                        end
                    
                    end 
                    if(addra <18399)
                        addra = addra + 1;
                    else
                        addra = 0;
         
            end else begin
                vgaRed=0;
                vgaBlue=0;
                vgaGreen=0;
            end
            
        end 

endmodule