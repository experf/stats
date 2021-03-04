Building A Release
==============================================================================

In brief:

1.  Build the image that the release will be built _in_:
    
        docker build -t elixir-ubuntu:latest .
        
2.  Build the release:
    
        ./bin/build
        
3.  If all is well, the archive will be in the `artifacts` dir.
