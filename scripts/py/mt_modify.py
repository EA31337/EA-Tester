#!/usr/bin/env python3
# Script to modify various MT formats.

import argparse
import sys
import struct
from copy import copy

from bstruct.bstruct import BStruct
from bstruct.bstruct_defs import SymbolsRaw

#
# Exceptions for internal use.
#
class WrongStructFormat(Exception):
    pass

class NoSuchField(Exception):
    pass

class InvalidDataFormat(Exception):
    pass

class InvalidArgument(Exception):
    pass

#

def modify_field(ss, field_name, value):
    """
    Modify the field named 'field_name' in the BStruct 'ss'.
    'value' is the new value in string form.
    """
    if not isinstance(ss, BStruct):
        raise WrongStructFormat()

    # Format string that's feed into pack.
    fmts = None

    for (fname, ffmt, *_) in ss._fields:
        if fname == field_name:
            fmts = ffmt
            break

    if fmts is None:
        raise NoSuchField()

    # Try to perform the correct cast.
    if fmts[-1] == 'c':
        raise InvalidArgument('c fields aren\'t supported yet')
    elif fmts[-1] == 's':
        value = value.encode('utf-8')
    elif fmts[-1] in ['f', 'd']:
        value = float(value)
    else:
        value = int(value, 0)

    # Validate the data first.
    try:
        struct.pack(fmts, value)
    except struct.error as e:
        raise InvalidDataFormat('Invalid data format for field {}'.format(field_name))
    except:
        raise

    setattr(ss, field_name, value)

def parse_file(name, strucc):
    try:
        fp = open(name, 'rb')
    except OSError as e:
        print('Cannot open file \'{}\' for reading'.format(name))
        sys.exit(1)

    content = []

    while True:
        buf = fp.read(strucc._size)

        if len(buf) != strucc._size:
            break

        content.append(strucc(buf))

    fp.close()

    return content

def write_file(name, content):
    try:
        fp = open(name, 'wb')
    except OSError as e:
        print('Cannot open file \'{}\' for writing'.format(name))
        sys.exit(1)

    for r in content:
        fp.write(r.repack())

    fp.close()

def find_in_content(content, field_name, value):
    struct_type = type(content[0])

    # Make sure the field exists and is a string.
    ex = [x[0] for x in struct_type._fields
            if x[0] == field_name and x[1][-1] == 's']

    if len(ex) == 0:
        # The field isn't available in this BStruct.
        raise InvalidArgument(field_name)

    for r in content:
        v = getattr(r, ex[0])
        # Sanitize the value before checking the value.
        if v.decode('utf-8').rstrip('\0') == value:
            return r

    raise InvalidArgument(value)

#
# Filetype specific options.
#
class SymbolsRawBundle():
    name_field = 'name'
    sort_field = 'name'
    need_sort = True

if __name__ == '__main__':
    # Parse the arguments.
    argumentParser = argparse.ArgumentParser(add_help=False)
    argumentParser.add_argument('-i', '--input-file', action='store'     , dest='inputFile', help='Input file'            , required=True)
    argumentParser.add_argument('-t', '--input-type', action='store',
        dest='inputType', help='Input type (fxt-header, hcc-header, sel, srv, symbols-raw, symgroups, ticks-raw)'         , required=True)
    argumentParser.add_argument('-k', '--key-group' , action='store'     , dest='keyGroup' , help='Group key'             , required=False)
    argumentParser.add_argument('-d', '--delete'    , action='store_true', dest='doDelete' , help='Delete this record')
    argumentParser.add_argument('-a', '--add'       , action='store'     , dest='doAdd'    , help='Add a new record'      , default=None)
    argumentParser.add_argument('-m', '--modify'    , action='append'    , dest='doModify' , help='Modify the record data')
    argumentParser.add_argument('-h', '--help'      , action='help'      , help='Show this help message and exit')
    args = argumentParser.parse_args()

    if   args.inputType == 'fxt-header':  modify_content(args.inputFile, 0, FxtHeader)
#   elif args.inputType == 'hcc-header':  modify_content(args.inputFile)
#   elif args.inputType == 'hst-header':  modify_content(args.inputFile, 0, HstHeader)
#   elif args.inputType == 'sel':         modify_content(args.inputFile, 4, SymbolSel)
#   elif args.inputType == 'srv':         modify_content(args.inputFile)
    elif args.inputType == 'symbols-raw':

        if args.keyGroup is None:
            print('You need to specify the group by -k param!')
            sys.exit(1)

        # A bundle keeps track of various options that are filetype-specific.
        bundle = SymbolsRawBundle

        cont = parse_file(args.inputFile, SymbolsRaw)

        # Find the key group first.
        try:
            key_group = find_in_content(cont, bundle.name_field, args.keyGroup)
        except InvalidArgument as e:
            print('Could not find the -k group \'{}\''.format(args.keyGroup))
            sys.exit(1)

        if not args.doAdd is None:

            # We can't have two symbols with the same name.
            try:
                is_present = find_in_content(cont, bundle.name_field, args.doAdd)
            except InvalidArgument as e:
                pass
            else:
                print('The symbol {} is already in the file, cannot overwrite it'.format(e))
                sys.exit(1)

            # Clone the old object and modify its name.
            new_group = copy(key_group)
            modify_field(new_group, bundle.name_field, args.doAdd)
            cont.append(new_group)

        elif not args.doModify is None:
            for opt in args.doModify:
                # Options are in the 'name=value' format.
                val = opt.split('=')

                val_name  = val[0].strip()
                val_value = val[1].strip()

                # Perform the modification in place.
                modify_field(key_group, val_name, val_value)

        elif not args.doDelete is None:
            cont.remove(key_group)

        # Sort the file content if needed.
        if bundle.need_sort:
            cont.sort(key = lambda x: getattr(x, bundle.sort_field))

        # Serialize the file.
        write_file(args.inputFile, cont)

#   elif args.inputType == 'symgroups':   modify_content(args.inputFile, 0, Symgroups)
#   elif args.inputType == 'ticks-raw':   modify_content(args.inputFile, 0, TicksRaw)
    else:
        print('Not supported type: {}!'.format(args.inputType))
