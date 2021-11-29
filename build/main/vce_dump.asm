;  Title:
;
;    YUV table reader for VCE.
;
;
;  Details:
;
;    Set pin 59 to ground on VCE for the LSB of the YUV value.
;    Set pin 58 and 59 to ground on VCE for MSB of the YUV value.
;
;    Pin test pin 58 set low sets the VCE to read from the YUV table.
;    Pin 59 set (high/low) is the LSB or MSB of the YUV word value.
;
;    YUV word format is 0UUUUUVVVVVYYYYY. You'll need to do a two
;    pass capture to get the whole WORD value.
;
;
;  Program Description:
;
;    The VCE pointer address ($402/403) will not read from the YUV table,
;    but directly from cram. In order to get the YUV value, the VCE needs
;    to be reading the pixel value from the VDC. The sprite border color
;    displays the current color, and the YUV value (either LSB or MSB) is
;    taken from that pixel. After the list is built, the BG is turned back
;    on and the capture values are displayed in a matrix of byte hex format.
;
;    This rom uses values $000 to $1ff of GGGRRRBBB. The values displayed
;    in YUV table from "GRB" index, is left to right, top to bottom, for
;    the screen output. Every other row is a different tile palette to make
;    the matrix easier to read. a 16x32 matrix is too large for the screen,
;    so the vertical resolution is scaled down to 87.5% to show all 32 rows.
;
;
;    {Assemble with PCEAS: ver 3.24 or higher}
;
;  Turboxray '21
;



;..............................................................................................................
;..............................................................................................................
;..............................................................................................................
;..............................................................................................................

    list
    mlist

;..................................................
;                                                 .
;  Logical Memory Map:                            .
;                                                 .
;            $0000 = Hardware bank                .
;            $2000 = Sys Ram                      .
;            $4000 = Subcode                      .
;            $6000 = Data 0 / Cont. of Subcode    .
;            $8000 = Data 1                       .
;            $A000 = Data 2                       .
;            $C000 = Main                         .
;            $E000 = Fixed Libray                 .
;                                                 .
;..................................................


;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;//  Vars

    .include "../base_func/vars.inc"
    .include "../base_func/video/vdc/vars.inc"
    .include "../base_func/video/vdc/sprites/vars.inc"
    .include "../base_func/IO/irq_controller/vars.inc"
    .include "../base_func/audio/wsg/vars.inc"
    .include "../base_func/IO/gamepad/vars.inc"


    .include "../lib/controls/vars.inc"
    .include "../lib/HsyncISR/vars.inc"
    .include "../lib/control_vars/vars.inc"
    .include "../lib/random/16bit/vars.inc"

    .include "../general/vars.inc"

;....................................
    .code

    .bank $00, "Fixed Lib/Start up"
    .org $e000
;....................................

;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// Support files: equates and macros

    .include "../base_func/base.inc"
    .include "../base_func/video/video.inc"
    .include "../base_func/video/vdc/vdc.inc"
    .include "../base_func/video/vdc/sprites/sprites.inc"
    .include "../base_func/video/vce/vce.inc"
    .include "../base_func/timer/timer.inc"
    .include "../base_func/IO/irq_controller/irq.inc"
    .include "../base_func/IO/mapper/mapper.inc"
    .include "../base_func/audio/wsg/wsg.inc"
    .include "../base_func/IO/gamepad/gamepad.inc"

    .include "../lib/controls/controls.inc"
    .include "../lib/HsyncISR/hsync.inc"
    .include "../lib/control_vars/control.inc"
    .include "../lib/random/16bit/random_16bit.inc"

    .include "../general/general.inc"


;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// Startup and fix lib @$E000

startup:
        ;................................
        ;Main initialization routine.
        InitialStartup
        CallFarWide init_audio
        CallFarWide init_video

        stz $2000
        tii $2000,$2001,$2000


        VCE.reg LO_RES|H_FILTER_ON
        VDC.reg HSR  , #$0202
        VDC.reg HDR  , #$041f
        VDC.reg VSR  , #$1002
        VDC.reg VDR  , #$00e6
        VDC.reg VDE  , #$001f
        VDC.reg DCR  , #AUTO_SATB_ON
        VDC.reg CR   , #$0000
        VDC.reg SATB , #$0800
        VDC.reg MWR  , #SCR64_32

        IRQ.control IRQ2_ON|VIRQ_ON|TIRQ_OFF

        TIMER.port  _7.00khz
        TIMER.cmd   TMR_OFF

        MAP_BANK #MAIN, MPR6
        jmp MAIN

;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// Data / fixed bank


;Stuff for printing on screen
    .include "../base_func/video/print/lib.asm"

;other basic functions
    .include "../base_func/video/vdc/lib.asm"
    .include "../base_func/video/vdc/sprites/lib.asm"

; Lib stuffs
    .include "../lib/controls/lib.asm"
    .include "../lib/HsyncISR/lib.asm"
    .include "../base_func/IO/gamepad/lib.asm"
    .include "../lib/slow16by16Mul/lib.asm"
    .include "../lib/random/16bit/lib.asm"

;end DATA
;//...................................................................


;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// Interrupt routines

;//........
TIRQ.custom
    jmp [timer_vect]

TIRQ:   ;// Not used
        BBS2 <vector_mask, TIRQ.custom
        stz $1403
        rti

;//........
BRK.custom
    jmp [brk_vect]
BRK:
        BBS1 <vector_mask, BRK.custom
        rti

;//........
VDC.custom
    jmp [vdc_vect]

VDC:
        BBS0 <vector_mask, VDC.custom
          pha
        lda IRQ.ackVDC
        sta <vdc_status
        bit #$20
        bne VDC.vsync
VDC.hsync
        BBS3 <vector_mask, VDC.custom.hsync
        BBS5 <vdc_status, VDC.vsync
          pla
        rti

VDC.custom.hsync
    jmp [vdc_hsync]

VDC.custom.vsync
    jmp [vdc_vsync]

VDC.vsync
        phx
        phy
        BBS4 <vector_mask, VDC.custom.vsync

VDC.vsync.rtn
        ply
        plx
        pla
      stz __vblank
  rti

;//........
NMI:
        rti

;end INT

;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// INT VECTORS

  .org $fff6

    .dw BRK
    .dw VDC
    .dw TIRQ
    .dw NMI
    .dw startup

;..............................................................................................................
;..............................................................................................................
;..............................................................................................................
;..............................................................................................................
;Bank 0 end





;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// Main code bank @ $C000

;....................................
    .bank $01, "MAIN"
    .org $c000
;....................................


MAIN:

        Random.seed #$18ca

        ;................................
        ; Turn display off, interrupts on
        VDC.reg CR , #(BG_OFF|SPR_OFF|VINT_ON|HINT_ON)

        ;................................
        ; Load font
        loadCellToCram.BG Font, 0
        loadCellToCram.BG debug, 1
        loadCellToVram Font, $1000

        ;...............................
        ; Set the ISRs
        ISR.setVector VDC_VEC , HsyncISR.IRQ
        ISR.setVecMask VDC_VEC

        ;................................
        ; Clear map
        jsr ClearScreen.64x32

        ;...............................
        ; Start with the first line of the display
        VDC.reg RCR, #$40

        ;................................
        ; Start the party
        Interrupts.enable

        MOVE.b #$00, pal_color0
        MOVE.b #$00, pal_color1

GrabColorValues:

        VDC.reg CR , #(BG_OFF|SPR_OFF|VINT_ON|HINT_ON)
        WAITVBLANK

        MOVE.w #$00, colorSelect
        MOVE.w #cramArray, <A0

        ;................................
        ; Wait until the active dispay starts
.activeDisplay


        lda <RCRline+1
      bne .activeDisplay
        lda <RCRline
        cmp #100
      bcc .activeDisplay

        ;................................
        ; Delay inside the displayable area
        ldy #12
.delay
        pha
        pla
        pha
        pla
        dey
      bne .delay

        ;................................
        ; Save internal YUV value
        lda $404
        sta [A0]
        INC.w <A0
        INC.w colorSelect
        lda colorSelect+1
        cmp #$02
      bcs .done

        ;................................
        ; Set next color, but also reset pointer to sprite border color
        MOVE.w #$100, $402
        MOVE.w colorSelect, $404
        MOVE.w #$100, $402
        WAITVBLANK

      jmp .activeDisplay

.done

        ;................................
        ; Set the border color back to black and turn on BG
        MOVE.w #$100, $402
        MOVE.w #$00, $404
        VDC.reg CR , #(BG_ON|SPR_OFF|VINT_ON|HINT_ON)

        ;................................
        ; Sort through values and write to BAT
ShowColorValues:

        MOVE.b #$00, col
        MOVE.b #$00, row
        MOVE.b #$00, cntr0
        MOVE.w #cramArray, <A0
        cly

.loop_row
        MOVE.b #$00, col
        MOVE.b #$00, cntr1
        MOVE.b #$00, pal_color0
        MOVE.b #$00, pal_color1
.loop_col
        lda cntr1
        sta pal_color0
        sta pal_color1

        lda [A0]
        tay
        PRINT_BYTEhex_XY col,row

        INC.w <A0
        ADD.w #$02, col

        ; Swap the palette for the next byte value
        lda cntr1
        eor #$10
        sta cntr1

        lda col
        cmp #32
      bcc .loop_col
        inc row
        lda row
        cmp #32
      bcs main_loop
      jmp .loop_row


main_loop:

        WAITVBLANK

      jmp main_loop



;Main end
;//...................................................................



;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;

;....................................
    .code
    .bank $02, "Subcode 1"
    .org $8000
;....................................


  IncludeBinary Font.cell, "../base_func/video/print/font.dat"

Font.pal: .db $00,$00,$00,$00,$ff,$01,$ff,$01,$ff,$01,$ff,$01,$ff,$01,$ff,$01
Font.pal.size = sizeof(Font.pal)

debug.pal: .db $00,$00,$00,$00,$66,$01,$66,$01,$66,$01,$66,$01,$66,$01,$66,$01
           .db $00,$00,$33,$01,$ff,$01,$ff,$01,$ff,$01,$ff,$01,$ff,$01,$f6,$01
debug.pal.size = sizeof(debug.pal)


    ;// Support files for MAIN
    .include "../base_func/init/InitHW.asm"


;..............................................................................................................
;..............................................................................................................
;..............................................................................................................
;..............................................................................................................
;Bank 1 end


;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// Data/Code


;/////////////////////////////////////////////////////////////////////////////////
;


;....................................
    ;Pad the Rom
    .bank $3f, "PAD"
;....................................


;END OF FILE