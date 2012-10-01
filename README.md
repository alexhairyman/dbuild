# dbuild
this is a pure d build system that only works with dmd (_for now_)

### documentation
I've done my best to document it up, and there is a small example at the bottom that was left over from an older
Project, also, I've made it so that the only way to generate these commands is via the D api, I intend to move
the current dbuild file to another minidbuild.d, a single file build system that can be included with a project
And expand the current code into a cleaner multiple file setup, with one for DPackage, one for DBuild, etc. I also
want to modify the code so that it will work with c/c++ too. I need to really rewrite just the class system, so
that DBuild inherits from some generic build class.
