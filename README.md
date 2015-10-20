# MasterSharingCore

This is the Core of the MasterSharing System for distributed group programming and other collaborative work.


## Usage

In order to use this module in your code, you need to include it in your package.json and install it, which can be done automatically via
`npm install --save mastersharingcore`.

After doing this, it can be required in your code like this
`msc = require 'mastersharingcore'`

Finally a client and a server can be created

- `server = msc.createServer port`
- `client = msc.createClient urlWithPort, username, color`

This package is used in the [atom-master-sharing plugin](https://atom.io/packages/atom-master-sharing).
To get an overview over the basic usage, just have look at its [code](https://github.com/okwast/AtomMasterSharing).

## Tests
To perform the tests of this module, you need to to the following steps.

1. Install npm and node
-  Download the repository to your local system.
-  Open the root of the module in a console
-  Run `npm test`


## Note
This package is in early a state of development and should not yet be used in a productive environment.