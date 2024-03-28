# ucicheck

A basic syntax checker for UCI configuration files.

https://openwrt.org/docs/guide-user/base-system/uci#file_syntax

## License

GPLv2-only - http://www.gnu.org/licenses/gpl-2.0.html

Copyright: (C) 2024 Thibaut VARÈNE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License version 2,
as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See LICENSE.md for details

## Dependencies

 - A **C compiler** supporting the C standard library (e.g. **gcc**)
 - **make**, **flex** and **bison**
 
## Building

To build, run `make`

## Usage

The tool accepts a single argument: a path to a UCI configuration file.

If the syntax is valid, no output is emitted and the tool returns a 0 exit code.
Otherwise, error messages are printed and a non-zero exit code is returned.

Example:

```sh
ucicheck config/system
````
