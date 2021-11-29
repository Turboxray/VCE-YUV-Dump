
# YUV table reader for VCE

## Details:

   Set pin 58 to ground on VCE for the LSB of the YUV value.
   Set pin 58 and 59 to ground on VCE for MSB of the YUV value.

   Pin test pin 58 set low sets the VCE to read from the YUV table.
   Pin 59 set (high/low) is the LSB or MSB of the YUV word value.

   YUV word format is 0UUUUUVVVVVYYYYY. You'll need to do a two
   pass capture to get the whole WORD value.


## Program Description:

   The VCE pointer address ($402/403) will not read from the YUV table,
   but directly from cram. In order to get the YUV value, the VCE needs
   to be reading the pixel value from the VDC. The sprite border color
   displays the current color, and the YUV value (either LSB or MSB) is
   taken from that pixel. After the list is built, the BG is turned back
   on and the capture values are displayed in a matrix of byte hex format.

   This rom uses values $000 to $1ff of GGGRRRBBB. The values displayed
   in YUV table from "GRB" index, is left to right, top to bottom, for
   the screen output. Every other row is a different tile palette to make
   the matrix easier to read. a 16x32 matrix is too large for the screen,
   so the vertical resolution is scaled down to 87.5% to show all 32 rows.
   The last row is a repeat of the first row.


   {Assemble with PCEAS: ver 3.24 or higher}

 Turboxray '21