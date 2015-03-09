# LuaLDAP - A Lua interface to an LDAP library

## Overview

LuaLDAP is a simple interface from Lua to OpenLDAP. It enables a Lua program to:

  * Connect to an LDAP server;
  * Execute any operation (search, add, compare, delete, modify and rename);
  * Retrieve entries and references of the search result.

LuaLDAP is free software and uses the same license as Lua 5.1.

### Contributing

Please send any patches or requests to <Jason@zx2c4.com>.

### Credits

LuaLDAP was originally designed by Roberto Ierusalimschy, Andre Carregal and Tomas Guisasola as part of the Kepler Project. It was implemented by Tomas Guisasola and Leonardo Godinho with contributions by Mark Edgar. LuaLDAP development was sponsored by Fabrica Digital and FINEP.

It was abandoned in 2007, and revived in 2015 by Jason Donenfeld.

## Manual

### Introduction

LuaLDAP defines one single global variable: a table called `lualdap`. This
table holds the functions used to create an LDAP connection object.

A connection object offers methods to perform any operation on the
directory such as comparing values, adding new entries, modifying
attributes on existing entries, removing entries, and the most common of
all: searching. Entries are represented as Lua tables; attributes are its
fields. The attribute values can be strings or tables of strings (used to
represent multiple values).

### Representing attributes

Many LDAP operations manage sets of attributes and values. LuaLDAP
provides a uniform way of representing them by using Lua tables. The table
attributes can be Lua string, a binary string (a string of bits), or table
of n values indexed from 1 to n. Some operations have different approaches
that will be explained as necessary.

Here is a simple example:

    entry = {
     an_attribute = "a value",
     other_attribute = {
      "first value of other attribute",
      "another value of other attribute",
     },
    }

Attribute names cannot contain the '\0' character.

### Distinguished names

The distinguished name (DN) is the term used to identify an entry on the
directory information tree. It is formed by the relative distinguished
name (RDN) of the entry and the distinguished name of its parent. LuaLDAP
will always use a string to represent the DN of any entry.

### Initialization functions

LuaLDAP provides a single way to connect to an LDAP server:

#### `lualdap.open_simple (connection_info_table)`

Initializes a session with an LDAP server, and binds to it. The `connection_info_table`
contains the following entries:

##### uri

An ldap:// or ldaps:// or similar URI for the requested server.

##### who

The DN of the user logging in.

##### password

A password to use in SASL.

##### starttls

A boolean of whether or not STARTTLS is to be used.

##### certfile

A path to a client certificate.

##### keyfile

A path to a client certificate key.

##### cacertfile

A path to a CA certificate chain.

##### cacertdir

A path to a CA certificate directory.

### Connection objects

A connection object offers methods which implement LDAP operations. Almost
all of them need a distinguished name to identify the entry on which the
operation will be executed.

These methods execute asynchronous operations and return a function that
should be called to obtain the results. The called functions will return
true indicating the success of the operation. The only exception is the
compare function which can return either true or false (as the result of
the comparison) on a successful operation.

There are two types of errors: API errors, such as wrong parameters,
absent connection etc.; and LDAP errors, such as malformed DN, unknown
attribute etc. API errors will raise a Lua error, while LDAP errors will
be reported by the function/method returning nil plus the error message
provided by the OpenLDAP client.

A connection object can be created by calling the Initialization function.

### Methods

#### `conn:add (distinguished_name, table_of_attributes)`

Adds a new entry to the directory with the given attributes and values.

#### `conn:close()`

Closes the connection conn.

#### `conn:compare (distinguished_name, attribute, value)`

Compares a value to an entry.

#### `conn:delete (distinguished_name)`

Deletes an entry from the directory.

#### `conn:modify (distinguished_name, table_of_operations*)`

Changes the values of attributes in the given entry. The tables of
operations are tables of attributes with the value on index 1
indicating the operation to be performed. The valid operations
are:

  * '+' to add the values to the attributes
  * '-' to delete the values of the attributes
  * '=' to replace the values of the attributes
  
Any number of tables of operations will be used in a single LDAP
modify operation.

#### `conn:rename (distinguished_name, new_relative_dn, new_parent)`

Changes an entry name (i.e. change its distinguished name).

#### `conn:search (table_of_search_parameters)`

Performs a search operation on the directory.
The search method will return a search iterator which is a
function that requires no arguments. The search iterator is used
to get the search result and will return a string representing the
distinguished name and a table of attributes as returned by the
search request.

The parameters are described below:

##### attrs

a string or a list of attribute names to be retrieved
(default is to retrieve all attributes).

##### attrsonly

a Boolean value that must be either false (default)
if both attribute names and values are to be
retrieved, or true if only names are wanted.

##### base

The distinguished name of the entry at which to start
the search.

##### filter

A string representing the search filter as described
in The String Representation of LDAP Search Filters
(RFC 2254).

##### scope

A string indicating the scope of the search. The
valid strings are: "base", "onelevel" and "subtree".
The empty string ("") and nil will be treated as the
default scope.

##### sizelimit

The maximum number of entries to return (default is
no limit).

##### timeout

The timeout in seconds (default is no timeout). The
precision is microseconds.


### Example

Here is a some sample code that demonstrate the basic use of the library:

    require "lualdap"

    ld = assert (lualdap.open_simple { uri = "ldap://ldap.server",
     who = "mydn=manoeljoaquim,ou=people,dc=ldap,dc=world",
     password = "mysecurepassword" })

    for dn, attribs in ld:search { base = "ou=people,dc=ldap,dc=world" } do
     io.write (string.format ("\t[%s]\n", dn))
     for name, values in pairs (attribs) do
      io.write ("["..name.."] : ")
      if type (values) == "string" then
       io.write (values)
      elseif type (values) == "table" then
       local n = table.getn(values)
       for i = 1, (n-1) do
        io.write (values[i]..",")
       end
       io.write (values[n])
      end
      io.write ("\n")
     end
    end

    ld:add ("mydn=newuser,ou=people,dc=ldap,dc=world", {
     objectClass = { "", "", },
     mydn = "newuser",
     abc = "qwerty",
     tel = { "123456758", "98765432", },
     givenName = "New User",
    })()

    ld:modify {"mydn=newuser,ou=people,dc=ldp,dc=world",
     { '=', givenName = "New", cn = "New", sn = "User", },
     { '+', o = { "University", "College", },
      mail = "newuser@university.edu", },
     { '-', abc = true, tel = "123456758", },
     { '+', tel = "13579113", },
    }()

    ld:delete ("mydn=newuser,ou=people,dc=ldp,dc=world")()

## License

    Copyright (c) 2003-2007 The Kepler Project.
    Copyright (c) 2015 Jason A. Donenfeld <Jason@zx2c4.com>.
    
    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
    THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS IN THE SOFTWARE.
