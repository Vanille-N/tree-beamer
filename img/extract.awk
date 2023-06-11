# Split a single document of the form
#
#   ::a::
#   figure A
#   ::b::
#   figure B
#   ::c::
#   figure C
#
# into
#
#   file a:
#     figure A
#   file b:
#     figure B
#   file c:
#     figure C
#
# The usecase is copy-pasting the LaTeX export from mathcha.io into a single
# file and dispatching all figures to other files.
#
# Filename is given as ::filename::
BEGIN {
    FNAME = "-"
}

/^::.*::$/ {
    FNAME = substr($0, 3, length($0) - 4) ".raw"
    print "Printing to file '" FNAME "'"
}

# Print all contents between \begin and \end
/\\begin\{tikzpicture\}/ {
    PRINTING = 1
    if (FNAME == "-") {
        print "WARNING: not printing to anywhere interesting"
    }
    NLINES = 0
}
PRINTING {
    print $0 >FNAME
    NLINES += 1
}
/\\end\{tikzpicture\}/ {
    PRINTING = 0
    FNAME = "-"
    print "  " NLINES " lines"
}
