; *******************************************
; Macros
; Kane / Suspect
; *******************************************

.ifndef MACROS_ASM

.macro WaitMs ms
	pha
	txa
	pha
	ldx	#:ms
	jsr	vblank.n
	pla
	tax
	pla
.endm

; this version does not save X and A
.macro WaitMsS ms
	ldx	#:ms
	jsr	vblank.n
.endm

// copy memory (len is -1)
.macro MemCpy src dst len
	mwa	#:src t1
	mwa	#:dst t3
	mwa	#:len t5
	jsr	memCopy
.endm

// clear memory (len is -1)
.macro MemClr src len
	mwa	#:src t1
	mwa	#:len t3
	jsr	memClear
.endm

// load 16bit value to X (msb) and Y (lsb)
.macro LdXY adr
	ldx	#>:adr
	ldy	#<:adr
.endm

// set colours (table of 16)
.macro SetColors coltab
	LdXY :coltab
	jsr	cols.setcols
.endm

.macro MakeSin convtab sintab centre amp size
	mwa	#:convtab t1
	ldx	#:amp					; X amplitude
	jsr	calc_sin.init			; prepare conversion tables ($100)
	mwa	#:convtab t1
	mwa	#:sintab t3
	lda	#:centre
	ldy	#:size					; size=256/Y. 1=256, 2=128, 4=64, 8=32
	jsr	calc_sin.calc
.endm

.macro InFill adr st nr val
	ldx	#:st
	lda	#:val
	ldy	#:nr
fx1	sta	:adr,x
	inx
	dey
	bne	fx1
.endm

.endif
