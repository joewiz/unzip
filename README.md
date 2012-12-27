# Unzip XQuery module

An XQuery module for listing and extracting the contents of zip files stored in the eXist-db database.
eXist-db has a built-in module that can perform many sophisticated operations on compressed files
(see the [compression module](http://exist-db.org/exist/functions/compression)), but many lines of
code are needed to simply list or extract the contents of zip files.  This module exposes two functions
for performing these operations. 

## Installation

This module requires eXist-db 2.0 and has been tested with 2.0RC.  It is not compatible with eXist-db 1.x.  
It also depends upon the FunctX library, so install this via the Admin Web Application's Package Repository 
pane; FunctX can be found under the CXAN tab.  (The development version of eXist-db 2.0RC2 will automatically
install FunctX as a dependency and so will not require separately installing FunctX.)

Next, clone this repository and run ant, which will construct an EXPath Archive (.xar) file.  

Finally, install this via the eXist-db Package Manager.

## Usage

### Import the module

    import module namespace unzip = "http://joewiz.org/ns/xquery/unzip";

### unzip:list()

This function displays the contents of a zip file.  Simply provide a path to where the zip file is 
stored in the database.

    unzip:list('/db/test.zip')

### unzip:unzip()

This function extracts the contents of a zip file.  By providing only the zip file, the file will be unzipped
in the same collection.  Or, to store the contents in a different collection, provide a path to the desired 
destination.  If the destination collection doesn't exist, it will be created.  The user who invokes the function
must have write access to the destination collection.

    unzip:unzip('/db/test.zip')

    unzip:unzip('/db/test.zip', '/db/test')

## Related work

The EXPath project has a specification for a [zip module](http://expath.org/spec/zip).  eXist-db has 
implemented [some of the functions](http://exist-db.org/exist/apps/fundocs/index.html) in the specification, 
but not all -- and in particular not those that this project helps with.  However, further development of 
that module might obviate the need for this module.  