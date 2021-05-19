# ealisting
Listing to Census processing of enumeration areas


#### Requires private settings

The following file must be added by the user before the program can be run: `private.do`.
The file must be a Stata do-script setting the following 3 global macros:
```
global susoserver=""
global susouser=""
global susopassword=""
```

Each setting is, respectively: URL of the server, account name of the API user, and the corresponding password.

The program will stop with an error if this file is not created by the user.

Since this file contains sensitive confidential information, it should not be committed to public repositories.
