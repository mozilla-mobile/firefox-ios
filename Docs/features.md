## Features

## `search`

### `awesome-bar`: `Variables`

This sub-feature controls the behaviour of the `awesome-bar`.

| Variable 	| Type 	| Default 	| Implemented by 	| Notes 	|
|---	|---	|---	|---	|---	|
| `use-page-content` 	| `Bool` 	| `true` 	| `SearchViewController` 	| If true, then use the text contents of the page,  as determined by readability to find open tabs in the AwesomeBar 	|

### `spotlight`: `Variables`

This sub-feature allows indexing of page content (from Readability) by Spotlight.

| Variable           	| Type     	| Default     	| Implemented by                                                 	| Notes                                                                                                                                                                                          	|
|--------------------	|----------	|-------------	|----------------------------------------------------------------	|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	|
| `enabled`          	| `Bool`   	| `false`     	| `UserActivityHandler`,   `ClearPrivateDataTableViewController` 	| If true, then add readable pages to the Spotlight index                                                                                                                                        	|
| `description`      	| `String` 	| `excerpt`   	| `UserActivityHandler`                                          	| The text added set as the contentDescription of the page. Possible values:   - `excerpt` the first paragraph.  - `content` the whole page content.  - `none` no description.                   	|
| `use-html-content` 	| `Bool`   	| `true`      	| `UserActivityHandler`                                          	| Give Spotlight the html as given by Readability.                                                                                                                                               	|
| `icon`             	| `String` 	| `letter`    	| `UserActivityHandler`                                          	| The thumbnail to use in Spotlight results. Possible values:   - `letter` use the first letter as an image  - `screenshot` use the tab screenshot  - `favicon` use the domain favicon  - `none` 	|
| `keep-for-days`    	| `Int`    	| iOS default 	| `UserActivityHandler`                                          	| The number of days before an item expires. By default, iOS expires after a month.                                                                                                              	|