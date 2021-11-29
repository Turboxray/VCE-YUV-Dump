


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
            lda <line.indx
            sta $0002
            lda <line.indx+1
            sta $0003


        ;     bit <vdc_status
        ; bvs .vsync

            st0 #RCR
            lda <RCRline
            sta $0002
            lda <RCRline+1
            sta $0003
            inc <RCRline
        bne .skip
            inc <RCRline+1

.skip

            INC.w <line.indx
            lda <line.indx
            cmp #$08
        bcc .skip2
            and #$07
            cmp #$01
        bne .skip2
            INC.w <line.indx
.skip2

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

            stz <line.indx
            stz <line.indx+1

            ; VDC.reg CR , #(BG_ON|SPR_OFF|VINT_ON|HINT_ON)
            lda #(64)
            sta <RCRline
            st0 #RCR
            sta $0002
            st2 #$00
            stz __vblank
            lda #(65)
            sta <RCRline
            stz <RCRline+1

            VDC.reg BXR, _BXR
            VDC.reg BYR, _BYR

            BBS3 <vector_mask, .VDC.custom.vsync

.HsyncISR.IRQ.VDCrtn
        jmp .out

.VDC.custom.vsync
    jmp [vdc_vsync]

HsyncISR.IRQ.VDCrtn = .HsyncISR.IRQ.VDCrtn




