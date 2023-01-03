# Natural Selection

## Selecting

This extension for Fantasy Grounds adds an intuitive way to deal with multiple tokens stacked together on the same grid space. When you select a token that shares its space with another token, a small pop up window will appear displaying the stacked tokens. You can then select which of the stacked tokens you want to interact with in the pop up menu. Doing so will bring the selected token to the top of the stack and select it for you.
![Selecting Tokens](https://user-images.githubusercontent.com/1416356/208997430-907b3b39-b386-431c-88e8-4c82b9208094.gif)

## Targeting

You can also target tokens within a stack either by holding Control when you select the token stack, or by holding Control when you select the token from the popup window
![Targeting](https://user-images.githubusercontent.com/1416356/208998639-4447cff8-61dd-47ee-a449-3fd4441b5b9e.gif)

## Drag/Drop

Lastly, after you open the token selector window, you can drop rolls (and any other drag/drop action) directly onto tokens within that window.
![Rolls](https://user-images.githubusercontent.com/1416356/208998840-e0085e93-c19c-41b3-bffd-d2a661089d02.gif)

## Game Options

### Selector Window Popup Location

This option determines where, relative to the token being selected, the token selector window pops up.

### Overlap Threshold

This option allows you to set what percentage must the tokens overlap for the selector window to appear. If disabled, then the selector will pop up if even a single pixel of the token overlaps another token. If you find Natural Selection is having strange interactions with other extensions, increasing the threshold could solve the issue.

This option is ignored for the _exact_ overlap calculation method.

### Calculation Methods

There are three methods for calculating token overlap, and there are three types of grids. These settings let you determine which method to use on which grid type. For more accurate overlap detection, it is recommended that you change your calculation method to match the shape of your tokens.

For example, if you use circular tokens, change the calculation method to circular. If you use square tokens, change the calculation method to square.

The _exact_ method works by checking if the stacked tokens are exactly on the same grid space, and ignores the overlap threshold.
