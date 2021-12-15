
######################
Pointer Wizardry v1.1 [Eon]
######################

##################################################
# New PSA Commands Added that can be used to read arbritary memory
# 
# 12150300 (MI Version : 121A0200)
#   Read from Pointer Path to variable.
# 12160400 (MI Version : 121B0300)
#   Read from Pointer Path with Mask to variable
# 12170300 (MI Version : 121C0200)
#   Write Integer to Pointed Address
# 12180300 (MI Version : 121D0200)
#   Write Float to Pointed Address
# 12180400 (MI Version : 121E0300)
#   Write Bit using Mask to Pointed Address
#
# Argument 0 Of all commands is value to Read into or Write out of
# Argument 1 Of all commands is a bit variable that is used for error detection. Set to True if Pointer Path is Valid, Else set to False. Can be used to quickly validate whether a path is pointing to an actual chars data or not.
# For Mask Commands, Argument 3 is the mask applied before reading/mask used to Write.
# Argument 3/4 is the base address for pointer paths. Not used for second variation, these use the characters Main Index as the base address. 
#
# Each command supports any number of extra arguements, each of which is used as an offset to in the pointer path.
#
# 
# Add the contents of the provided files in `PSA-C Config Extra Data` to the end of your PSA-Compressor Config files of the same names to add them to PSA-Compressor
#
# The Main Index of a given character/article is an identifying pointer that can be used to find any piece of information on them using pointer chains.
#
# Example : 
#    Assuming P1 is a Mario
#    12150800 Read From Pointer Path to variable.
#       Args : LA-Float[100], LA-Bit[33], 0x80624780, 0x34, 0x60, 0xD8, 0xC,0xC
#		0x80624780 ->  0x806232F0 + 0x34  ->  0x8125D140 (chars main index)+ 0x60 -> 0x8125DCA4 + 0xD8 -> 0x8125DCB0 + 0xC -> 0x8125EAE4 + 0xC -> Player 1 X position
#		This stores Player 1's X-position into LA-Float[100], and sets LA-Bit[33] to true since the path was successful.
#	 121A0500 Read From Pointer Path Using Main Index to variable
#       Args : LA-Float[100], LA-Bit[33], 0x60, 0xD8, 0xC,0xC
#       -> 0x8125D140 (chars main index) + 0x60 -> 0x8125DCA4 + 0xD8 -> 0x8125DCB0 + 0xC -> 0x8125EAE4 + 0xC -> Users 1 X position
#		This stores the users X-position into LA-Float[100], and sets LA-Bit[33] to true since the path was successful.
#
# All chars Main Index stored at (0x80624780) + 0x34 + 0x244*port + 0x4 for secondary chars.
# Hitboxes previously-hit list needs to be found, once this is found, we can effectively make a hitbox do anything. File will be updated once a method is found 
#
# All Articles Main Index stored in a linked list found at 0x805B8A88, can go forward in the linked list through Article MI + 0x8, backwards through it with Article MI + 0x4.
# You can treat an article the same as a fighter with pointer paths, the same path will get an articles X-position as it would get a fighters X-position.
# I don't currently know how to know the owner of an article from its MI or vice versa, will update when a method is found.
#
# 
# To get Pointer Paths, I recommend using Dolphin Memory Engine, alongside my Pointer Path DME file found at http://forums.kc-mm.com/Gallery/BrawlView.php?Number=216612
# 
# I will provide demo .pacs with different examples moves and uses in the future alongside maybe tutorial on finding pointers to different things, however currently I dont have the time so release is bare.
#
#
# If you want any help with using these commands/paths, feel free to DM me on Discord @;-; | Eon#0133
#
###################################################

HOOK @ $807ACE9C
{
.alias commandID = 16
.alias argCount = 17
.alias currentArg = 18
.alias WorkingPointer = 19
.alias result = 31
.alias prev31 = 15
.alias rememberLinkRegister = 14
.alias tempCompare = 14


.alias ReadFromLocation = 0x15
.alias ReadFromLocationMasked = 0x16
.alias WriteToLocationInt = 0x17
.alias WriteToLocationFloat = 0x18
.alias WriteToLocationBitMasked = 0x19

.alias ReadFromLocationBase = 0x1A
.alias ReadFromLocationMaskedBase = 0x1B
.alias WriteToLocationIntBase = 0x1C
.alias WriteToLocationFloatBase = 0x1D
.alias WriteToLocationBitMaskedBase = 0x1E

.alias MinCommand = ReadFromLocation
.alias MaxCommand = WriteToLocationFloatBase
.alias MinBaseAddress = ReadFromLocationBase
.alias commandCount = 5 #0x1A - 0x15 #(ReadFromLocationBase - ReadFromLocation)



extsb   r0, r3 # original command, stores command type (second byte of PSA command) into r0

cmpwi r0,MinCommand
blt _end
cmpwi r0,MaxCommand
bgt _end 
bl startentireCode
li r0, 100
b _end
startentireCode:
	stwu r1, -0x100(r1)
  	stmw r2, 0x20(r1)
	mflr r0
	stw r0, 0x104(r1)
_loadArgCountAndBaseAddress:
	extsb commandID, r3
	mr prev31, result
	lwz argCount, 0x8(r29)
	lbz argCount, 0x2(argCount)
	li currentArg, 2
	li WorkingPointer, 0
	cmpwi commandID, ReadFromLocationMasked
	beq _maskInUse
	cmpwi commandID, WriteToLocationBitMasked
	bne _checkBase

_maskInUse:
		addi currentArg, currentArg, 1
	 
_checkBase:
		cmpwi commandID, MinBaseAddress
		blt _loadBaseAddress

_usingMainIndex:
		addi WorkingPointer, r31, 0x8
		subi commandID, commandID, commandCount

#checks that each step in pointer path is within accessible memory 
_followPointerPath:
_calcAddress:
		lis tempCompare, 0x8000
		cmpw WorkingPointer, tempCompare
		blt _invalidAddress
		lis tempCompare, 0x8180
		subi tempCompare, tempCompare, 0x4
		cmpw WorkingPointer, tempCompare
		ble _loadAddress
		lis tempCompare, 0x9000
		cmpw WorkingPointer, tempCompare
		blt _invalidAddress
		lis tempCompare, 0x9400
		subi tempCompare, tempCompare, 0x4
		cmpw WorkingPointer, tempCompare
		bgt _invalidAddress

_loadAddress:
		cmpw currentArg, argCount
		bge _applyCommand
		lwz WorkingPointer, 0(WorkingPointer)

_loadBaseAddress:
		mr r5, currentArg
		bl _readInt
		add WorkingPointer, WorkingPointer, result
		addi currentArg, currentArg, 1
		b _calcAddress


_applyCommand:
	#Writes true to error variable 
	li r5, 1
	li result, 1
	bl _writeToVariable

	cmpwi commandID, ReadFromLocation
	beq _ReadFromLocation
	cmpwi commandID, ReadFromLocationMasked
	beq _ReadFromLocationMasked

	cmpwi commandID, WriteToLocationInt
	beq _WriteToLocationInt 
	cmpwi commandID, WriteToLocationFloat
	beq _WriteToLocationFloat
	cmpwi commandID, WriteToLocationBitMasked
	beq _WriteToLocationBitMasked

	b _exit

_ReadFromLocation:
		lwz result, 0(WorkingPointer)
		lfs f1, 0(WorkingPointer)
		li r5, 0
		bl _writeToVariable
		b _exit

_ReadFromLocationMasked:
		li r5, 2
		bl _readInt
		lwz WorkingPointer, 0(WorkingPointer)
		and result, WorkingPointer, result
		li r5, 0
		bl _writeToVariable
		b _exit




_WriteToLocationInt:
		li r5, 0
		bl _readInt
		stw result, 0(WorkingPointer)
		b _exit

_WriteToLocationFloat:
		li r5, 0
		bl _readFloat
		stw result, 0(WorkingPointer)
		b _exit


_WriteToLocationBitMasked:
		li r5, 0
		bl _readBit
		cmpwi result, 0
		bne _WriteTrue

_WriteFalse: #NANDs mask with target location, turning OFF every bit that is true that should be false according to the mask
			li r5, 2
			bl _readInt
			lwz tempCompare, 0(WorkingPointer)
			not result, result
			and result, tempCompare, result
			stw result, 0(WorkingPointer)
			b _exit

_WriteTrue: #ORs mask with target location, turning ON every bit that is false that should be true according to mask
			li r5, 2
			bl _readInt
			lwz tempCompare, 0(WorkingPointer)
			or result, tempCompare, result
			stw result, 0(WorkingPointer)
			b _exit



#Writes a Zero into the Bit variable specified in argument 2.
_invalidAddress: 
	li r5, 1
	li result, 0
	bl _writeToVariable
	b _exit

_functionCalls:
	#Reads the value of argument indexed in r5 into r31 assuming its an integer (only supports Value, Pointer and Variable types)
_readInt:
	mflr rememberLinkRegister
	li r0,0
	mr r3,r29
	stw r0,0x250(r1)
	addi r4,r1,0x250
	stb r0,0x254(r1)
	lwz r12,0(r29)
	lwz r12,32(r12)
	mtctr r12
	bctrl

	lwz	r3, 0x0250 (r1)
	lwz	r0, 0 (r3) #Gets Argument Type
_CheckValueInt:
		cmpwi	r0, 0
		bne _CheckPointerInt
		lwz	r3, 0x0250 (r1)
		lwz	r31, 0x0004 (r3)
		b _return
_CheckPointerInt:
		cmpwi	r0, 2
		bne _CheckVariableInt
		lwz	r3, 0x0250 (r1)
		lwz	r31, 0x0004 (r3)
		b _return
_CheckVariableInt:
		cmpwi r0, 5
		bne _return

		mr r3,prev31
		lwz r4,0x250(r1)
		lwz r4,0x4(r4)
		li r5,0
		lis r12,0x8079
		addi r12,r12,0x7104
		mtctr r12
		bctrl
		mr r31,r3
		b _return


	#Reads the value of argument indexed in r5 into r31 assuming its a float (only supports Scalar and Variable types). 
_readFloat:
	mflr rememberLinkRegister
	li r0,0
	mr r3,r29
	stw r0,0x250(r1)
	addi r4,r1,0x250
	stb r0,0x254(r1)
	lwz r12,0(r29)
	lwz r12,32(r12)
	mtctr r12
	bctrl

	lwz	r3, 0x250 (r1)
	lwz	r0, 0 (r3)
_checkScalarFloat:
		cmpwi	r0, 1
		bne _checkVariableFloat
		#Scalar Arguements are stored as an int that is 5000*float value. So divide scalar stored value / 5000 to get float form.
		lwz	r5, 0x250 (r1)
		lis	r0, 0x4330
		lis	r4, 0x80AD
		lis	r3, 0x80AD
		lwz	r5, 0x0004 (r5)
		stw	r0, 0x0278 (r1)
		xoris	r0, r5, 0x8000
		lfd	f2, 0x7A60 (r4)
		stw	r0, 0x027C (r1)
		lfs	f0, 0x7A58 (r3)
		lfd	f1, 0x0278 (r1)
		fsubs	f1,f1,f2
		fdivs	f31,f1,f0
		stfs f31, 0x27C(r1)
		lwz r31, 0x27C(r1)

		b _return

_checkVariableFloat:
		cmpwi r0, 5
		bne _return
		mr r3,prev31
		lwz r4,0x250(r1)
		lwz r4,0x4(r4)
		li r5,0
		lis r12,0x8079
		addi r12,r12,0x6f14
		mtctr r12
		bctrl
		stfs f1, 0x27C(r1)
		lwz r31, 0x27C(r1)
		b _return

_readBit:
	mflr rememberLinkRegister
	li r0,0
	mr r3,r29
	stw r0,0x250(r1)
	addi r4,r1,0x250
	stb r0,0x254(r1)
	lwz r12,0(r29)
	lwz r12,32(r12)
	mtctr r12
	bctrl

	lwz	r3, 0x250 (r1)
	lwz	r0, 0 (r3)
_checkBooleanBit:
		cmpwi	r0, 3
		bne 0x10
		lwz	r3, 0x250 (r1)
		lwz	r31, 0x0004 (r3)
		b _return
_checkVariableBit:
		cmpwi r0, 5
		bne _return
		mr r3,prev31
		lwz r4,0x250(r1)
		lwz r4,0x4(r4)
		li r5,0
		lis r12,0x807b
		addi r12,r12,-0x3324
		mtctr r12
		bctrl
		mr r31,r3
		b _return


	#call with r5 set to argument as to write to, r31 set to value to write
_writeToVariable:
	mflr rememberLinkRegister
	li r30,0
	mr r3,r29
	stw r30,0x248(r1)
	addi r4,r1,0x248
	stb r30,0x24C(r1)
	lwz r12,0(r29)
	lwz r12,32(r12)
	mtctr r12
	bctrl
	lwz r3,0x248(r1)
	lwz r0,0(r3)

	cmpwi r0,5    #if argument was not of type Variable, end
	bne- _return

	lwz r3,0x248(r1)
	lwz r30,4(r3)
	lwz r12,0(r29)

	lbz r3, 4(r3)
	andi. r3, r3, 0xF

	cmpwi r3, 0x1 
	beq _floatSet
	cmpwi r3, 0x2
	beq _bitSet


_intSet:
		lwz r12,0(r28)
		mr r3,r28
		mr r4,r31
		mr r5,r30
		lwz r12,28(r12)
		mtctr r12
		bctrl
		b _return

_floatSet:
		lwz r12,0(r28)
		mr	r3, r28
		mr	r4, r30
		lwz	r12, 0x003C (r12)
		mtctr	r12
		bctrl
		b _return

_bitSet:
		cmpwi r31, 0
		bne _bitOn 
_bitOff:
			lwz	r12, 0 (r28)
			mr	r3, r28
			mr	r4, r30
			lwz	r12, 0x0054 (r12)
			mtctr	r12
			bctrl	
			b _return
_bitOn:
			lwz	r12, 0 (r28)
			mr	r3, r28
			mr	r4, r30
			lwz	r12, 0x0050 (r12)
			mtctr	r12
			bctrl	

_return:
	mtlr rememberLinkRegister
	blr

#Exit on command executed, spoofs it as command 0x100 since thats impossible so will exit the overarching function.
_exit:

  	lwz r0, 0x104(r1)
  	mtlr r0
  	lmw r2, 0x20(r1)
  	addi r1, r1, 0x100
  	blr 

_end: 
	nop
}

op cmpwi r0, 0x33 @ $807ACE78