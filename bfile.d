import DB.db;
import std.stdio;

void main()
{
  DBuild builder = new DBuild(DFront.dmd);
  
  DPackage dbuild = new DPackage();
  dbuild.AddSourceFileDir("DB");
  dbuild.SetType(DTarget.STATICLIB);
  dbuild.SetBuildDir("build");
  dbuild.SetOutFile("libdbuild");
  dbuild.AddArg("-O");
  
  builder.AddPackage(dbuild, "DBuild");
  
  foreach(string s; builder.CompileCommandLineDepends("DBuild"))
  {
    writeln (s);
  }
  
  
}
