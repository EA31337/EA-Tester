#!/usr/bin/env python3
# Script to read various MT formats.

import argparse
import sys

from bstruct.bstruct_defs import *

def dump_hcc_content(filename):
    try:
        fp = open(filename, 'rb')
    except OSError as e:
            print("[ERROR] '%s' raised when tried to read the file '%s'" % (e.strerror, filename))
            sys.exit(1)

    buf = fp.read(HccHeader._size)
    obj = HccHeader(buf)

    assert(obj.magic == 501)

    print(obj)

    while True:
        buf = fp.read(HccTable._size)
        obj = HccTable(buf)

        # Quite crude, but seems to work.
        if obj.off == obj.size == 0:
            break

        print(obj)

        was = fp.tell()
        fp.seek(obj.off)

        buf = fp.read(HccRecordHeader._size)
        obj = HccRecordHeader(buf)

        assert(obj.magic == 0x81)

        print(obj)

        for i in range(obj.rows):
            buf = fp.read(HccRecord._size)
            obj = HccRecord(buf)

            assert(obj.separator & 0x00088884 == 0x00088884)

            print(obj)

            # Skip the eventual trailing bytes.
            extra1 = (obj.separator >> 28) & 15
            extra2 = (obj.separator >> 24) & 15
            extra3 = (obj.separator >> 20) & 15

            fp.seek(extra1 + extra2 + extra3, 1)

        fp.seek(was)

def dump_srv_content(filename):
    try:
        fp = open(filename, 'rb')
    except OSError as e:
            print("[ERROR] '%s' raised when tried to read the file '%s'" % (e.strerror, filename))
            sys.exit(1)

    buf = fp.read(SrvHeader._size)
    obj = SrvHeader(buf)

    print(obj)

    while True:
        buf = fp.read(SrvRecord._size)

        if len(buf) != SrvRecord._size:
            break

        obj = SrvRecord(buf)
        print(obj)

def dump_content(filename, offset, count, strucc):
    """
    Dump the content of the file "filename" starting from offset and using the
    BStruct subclass pointed by strucc
    """
    try:
        fp = open(filename, 'rb')
    except OSError as e:
            print("[ERROR] '%s' raised when tried to read the file '%s'" % (e.strerror, filename))
            sys.exit(1)

    fp.seek(offset)

    i = 0
    while i < count or count == 0:
        buf = fp.read(strucc._size)

        if len(buf) != strucc._size:
            break

        obj = strucc(buf)
        i += 1
        print(obj)

if __name__ == '__main__':
    # Parse the arguments.
    argumentParser = argparse.ArgumentParser(add_help=False)
    argumentParser.add_argument('-i', '--input-file', action='store', dest='inputFile', help='Input file', required=True)
    argumentParser.add_argument('-t', '--input-type', action='store', dest='inputType',
        help='Input type (fxt-header, hcc-header, sel, srv, symbols-raw, symgroups, ticks-raw)', required=True)
    argumentParser.add_argument('-h', '--help', action='help', help='Show this help message and exit')
    args = argumentParser.parse_args()

    if   args.inputType == 'fxt-header':  dump_content(args.inputFile, 0, 1, FxtHeader)
    elif args.inputType == 'hcc-header':  dump_hcc_content(args.inputFile)
    elif args.inputType == 'hst-header':  dump_content(args.inputFile, 0, 1, HstHeader)
    elif args.inputType == 'sel':         dump_content(args.inputFile, 4, 0, SymbolSel) # There's a 4-byte magic preceding the data.
    elif args.inputType == 'srv':         dump_srv_content(args.inputFile)
    elif args.inputType == 'symbols-raw': dump_content(args.inputFile, 0, 0, SymbolsRaw)
    elif args.inputType == 'symgroups':   dump_content(args.inputFile, 0, 0, Symgroups)
    elif args.inputType == 'ticks-raw':   dump_content(args.inputFile, 0, 0, TicksRaw)
    else:
        print('Not supported type: {}!'.format(args.inputType))
