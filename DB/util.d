module DB.util;

enum DFront : ubyte
{
  dmd = 0,
  gdc = 1
}

enum DTarget : ubyte
{
  NOTHING = 0,
  SHAREDLIB = 1,
  STATICLIB = 2,
  EXECUTABLE = 3,
  OBJCOLLECTION = 4
}


