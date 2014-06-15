travis-run build script generation
----------------------------------

`travis-run-script` takes on stdin the contents of a *.travis.yml* file and
spits out (on stdout) the build matrix configurations seperated by newlines and
encoded as YAML with newlines backslash-escaped.

To generate the build script for one of these configurations run
`travis-run-script --build` and write the selected configuration to stdin it
will then spit out a shell script on stdout that can be run inside the build VM.
