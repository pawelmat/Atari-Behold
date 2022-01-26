; ******************************************************
; BEHOLD demo, Kane / Suspect, 08/2021
; Copyright (C) 2021 Pawel Matusz. Distributed under the terms of the GNU GPL-3.0.
;
; "Snakes" for the lack of a better name
; ******************************************************

.proc snakes

init
	mwa	#snakeConvTab t1
	ldx	#14						; X amplitude
	jsr	calc_sin.init			; prepare conversion tables
	mwa	#snakeConvTab t1
	mwa	#snakeSinX t3
	lda	#0	; center
	ldy	#1	; size: 256
	jsr	calc_sin.calc

	mwa	#snakeConvTab t1
	ldx	#24						; Y amplitude
	jsr	calc_sin.init			; prepare conversion tables
	mwa	#snakeConvTab t1
	mwa	#snakeSinY t3
	lda	#0	; center
	ldy	#1	; size: 256
	jsr	calc_sin.calc

	jsr clear_screen
	jsr create_dl.no_scroll
	jsr	hscroll_shift_dl
	mva	#$22 DMACTL	; $21 = narrow playfield, $22 = normal
	mva	#$80 PRIOR	; 80: 9 cols (GTIA graphics 10) - 9 arbitrary colours | 40: 16 shades (GTIA graphics 9) - all shades of one background colour | C0: 16 cols (GTIA graphics 11 - all colours of the same luminance)
	mwa #dlist DLISTL
	rts

exec
	lda	#0
	sta	t1		// decrease screen intensity counter
	sta	t2		// palette change counter
	sta	t3		// palette index
	lda	#2
	sta	t4		// trail length

	mwa	#snakeSinX t5
	mwa	#snakeSinY t7

	SetColors palettea
loop
	vblank
;	WaitMsS	5

	inc	t1
	lda	t1
	cmp	t4
	bne	nofade
	mva	#0 t1
	jsr	fadescreen	
nofade

	mwa	#snakes t9
draw
	ldy	#0
	lda	(t9),y
	beq	enddraw
	ldy	#3			; X speed
	lda	(t9),y
	clc
	ldy	#2			; X
	adc	(t9),y
	sta	(t9),y
	tay
	lda	(t5),y		; sin x
	ldy	#0			; X offset
	clc
	adc	(t9),y
	tax

	ldy	#5			; Y speed
	lda	(t9),y
	clc
	ldy	#4			; Y
	adc	(t9),y
	sta	(t9),y
	tay
	lda	(t7),y		; sin y
	ldy	#1			; Y offset
	clc
	adc	(t9),y
	clc
	adc	#>scr
	sta	l1+2				; Y screen row
	clc
	adc	#1
	sta	l2+2				; Y+1 screen row
	lda	#$88
l1	sta	scr,x
l2	sta	scr+256,x	
	adw	t9 #6
	jmp	draw
enddraw

	inc	t2
	lda	t2
	cmp	#128				; every 128 cycles change paletter and trail type
	bne	cont
	mva	#0 t2
	inc	t3
	
	lda	t3
	tax
	ldy	trail,x				; change trail length
	beq	quit
	sty	t4
	mvy	#0 t1
	asl
	tax
	ldy	palletes,x
	inx
	lda	palletes,x
	tax
	jsr	cols.setcols		; change palette
cont
	jmp	loop

quit
	jsr	fadeout				; fade out all snakes without adding new
	rts


palettea	.byte	0,$01,$12,$14,$f6,$f8,$fa,$fe,$0f
paletteb	.byte	0,$d1,$d2,$d4,$d6,$d8,$da,$de,$0f
palettec	.byte	0,$91,$92,$94,$96,$98,$9a,$9e,$0f
paletted	.byte	0,$51,$52,$54,$56,$58,$5a,$5e,$0f
palletes	.byte	a(palettea),a(paletteb),a(palettec),a(paletted)
trail		.byte	2,4,3,1,0
snakes		.byte	[width_n/2+5],[height/2],0-1,1,128-2,2
			.byte	[width_n/2+4],[height/2],0-2,2,128-3,3
			.byte	[width_n/2+3],[height/2],0-3,3,0-4,4
			.byte	[width_n/2+2],[height/2],0-4,4,128-3,3
			.byte	[width_n/2+1],[height/2],0-3,3,0-1,1
			.byte	[width_n/2+0],[height/2],0-5,5,128-2,2
			.byte	[width_n/2-5],[height/2],128-1,1,128-3,3
			.byte	[width_n/2-4],[height/2],128-3,3,128-1,1
			.byte	[width_n/2-3],[height/2],128-5,5,0-4,4
			.byte	[width_n/2-2],[height/2],128-4,4,128-2,2
			.byte	[width_n/2-1],[height/2],128-2,2,0-7,7
			.byte 	0
			
/*
sprinkles
	SetColors palette02z
	mva	#30 t1
sloop
	vblank
	ldy	#2
sp1	lda RANDOM
	and	#31
	clc
	adc	#[width_n-32]/2
	tax						; X
	lda RANDOM
	and	#31
	clc
	adc	#[height-32]/2
	clc
	adc	#>scr
	sta	s1+2				; Y
	lda	#$99
s1	sta	scr,x
	dey
	bne	sp1
	jsr	fadescreen
	dec	t1
	bne	sloop
	jsr	fadeout
	rts

palette02z	.byte	0,$61,$62,$64,$66,$68,$6a,$6e,$0f
*/

; wait until wole screen fades out
fadeout
	mva	#17 t1
fo1	vblank
	vblank
	jsr	fadescreen
	dec	t1
	bne	fo1
	rts

; fade whole screen by 1 colour	
fadescreen
	lda	#>scr
	sta	f1+2
	sta	f2+2

	ldy	#height
fy	ldx	#width_n-1
f1	lda	scr,x
	beq	f3
	sec
	sbc	#$11			; this relies on both halves of each gfx byte always being the same
f2	sta	scr,x
f3	dex
	bpl	f1

	inc	f1+2			; move to new row
	inc	f2+2
	dey
	bne	fy
	rts

.endp
