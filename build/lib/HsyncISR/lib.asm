


;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;//
HsyncISR.IRQ:


;............................................
.check
    pha

;............................................
.hsync
            st0 #BYR
            MOVE.w <line.indx, $0002

            st0 #RCR
            MOVE.w <RCRline, $0002
            INC.w <RCRline


            INC.w <line.indx
            lda <line.indx
            cmp #$08
        bcc .skip
            and #$07
            cmp #$01
        bne .skip
            INC.w <line.indx
.skip

            lda IRQ.ackVDC
            sta <vdc_status
            bit #$20
        bne .vsync

    phx
    phy

;............................................
.out
            lda <vdc_reg
            sta $0000
    ply
    plx
    pla

    rti

;............................................
.vsync

    phx
    phy

            MOVE.w #$00, <line.indx

            st0 #RCR
            MOVE.w #64, $0002
            stz __vblank
            MOVE.w #65, <RCRline

            VDC.reg BXR, _BXR
            VDC.reg BYR, _BYR

            BBS3 <vector_mask, .VDC.custom.vsync

.HsyncISR.IRQ.VDCrtn
        jmp .out

.VDC.custom.vsync
    jmp [vdc_vsync]

HsyncISR.IRQ.VDCrtn = .HsyncISR.IRQ.VDCrtn
