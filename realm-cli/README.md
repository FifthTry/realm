# realm-cli

A command line utitily to provide services offered by realm (a rust-elm web 
framework).

## Usage

### To create a new realm project 

`realm-cli startproject <project_name>`

eg: `realm-cli startproject hello`


### To build project

Move to the project directory and run `realm-cli build`  

In our example:
   
`
$ cd hello
$ realm-cli build
`

### To get server up and running

`$ realm-cli debug`  

## Development

1. Use local package:

  `
  $ python setup.py develop
  `

2. use black `black realm-cli` from time to time.
3. run test: `realm-cli test`.

