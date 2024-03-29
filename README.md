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

The tool takes a path to a UCI configuration file as argument.

If the syntax is valid, no output is emitted and the tool returns a 0 exit code.
Otherwise, error messages are printed and a non-zero exit code is returned.

Usage:

```sh
ucicheck [-n] filename
````

## Notes

Due to UCI allowing embedded new lines in quoted literals,
unterminated quoted multi-line strings may typically be reported out of sync
(or not at all if a subsequent unbalanced closing quote terminates the unbalanced opening one).

In order to help debugging these cases, calling this tool with the `-n` option
switches to a stricter subset of the UCI syntax which does not allow embedded new lines in string literals.
