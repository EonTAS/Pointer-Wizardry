# Pointer-Wizardry

New PSA Commands Added that can be used to read arbritary memory
```
12150300 (MI Version : 121A0200)
  Read from Pointer Path to variable.
  
12160400 (MI Version : 121B0300)
  Read from Pointer Path with Mask to variable

12170300 (MI Version : 121C0200)
  Write Integer to Pointed Address

12180300 (MI Version : 121D0200)
  Write Float to Pointed Address

12180400 (MI Version : 121E0300)
  Write Bit using Mask to Pointed Address
```
Argument 0 Of all commands is value to Read into or Write out of

Argument 1 Of all commands is a bit variable that is used for error detection. Set to True if Pointer Path is Valid, Else set to False. Can be used to quickly validate whether a path is pointing to an actual chars data or not.

For Mask Commands, Argument 3 is the mask applied before reading/mask used to Write.

Argument 3/4 is the base address for pointer paths. Not used for second variation, these use the characters Main Index as the base address. 

Each command supports any number of extra arguements, each of which is used as an offset to in the pointer path.


Add the contents of the provided files in `PSA-C Config Extra Data` to the end of your PSA-Compressor Config files of the same names to add them to PSA-Compressor

The Main Index of a given character/article is an identifying pointer that can be used to find any piece of information on them using pointer chains.

Example : 
**Assuming P1 is a Mario**

```
12150800 Read From Pointer Path to variable.
 
Args : LA-Float[100], LA-Bit[33], 0x80624780, 0x34, 0x60, 0xD8, 0xC,0xC

0x80624780 ->  0x806232F0 + 0x34  ->  0x8125D140 (chars main index)+ 0x60 -> 0x8125DCA4 + 0xD8 -> 0x8125DCB0 + 0xC -> 0x8125EAE4 + 0xC -> Player 1 X position
```

This stores Player 1's X-position into LA-Float[100], and sets LA-Bit[33] to true since the path was successful.

```
121A0500 Read From Pointer Path Using Main Index to variable

Args : LA-Float[100], LA-Bit[33], 0x60, 0xD8, 0xC,0xC

-> 0x8125D140 (chars main index) + 0x60 -> 0x8125DCA4 + 0xD8 -> 0x8125DCB0 + 0xC -> 0x8125EAE4 + 0xC -> Users 1 X position
```

This stores the users X-position into LA-Float[100], and sets LA-Bit[33] to true since the path was successful.

All chars Main Index stored at (0x80624780) + 0x34 + 0x244\*port + 0x4 for secondary chars.

Hitboxes previously-hit list needs to be found, once this is found, we can effectively make a hitbox do anything. File will be updated once a method is found 


-----

All Articles Main Index stored in a linked list found at 0x805B8A88, can go forward in the linked list through Article MI + 0x8, backwards through it with Article MI + 0x4.

You can treat an article the same as a fighter with pointer paths, the same path will get an articles X-position as it would get a fighters X-position.

I don't currently know how to know the owner of an article from its MI or vice versa, will update when a method is found.

To get Pointer Paths, I recommend using Dolphin Memory Engine, alongside my Pointer Path DME file found at http://forums.kc-mm.com/Gallery/BrawlView.php?Number=216612
 
