module d.dbuild;

import std.file;
import std.stdio;
//import std.random;
//import std.md5;


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

/**
 * A build package, which stores data about files and arguments and such
 */
class DPackage
{
private:
  bool object_compile_ = false;
  string build_dir_;
  string doc_dir_;
  string header_dir_;
  string[] files_;
  string[] include_dirs_;
  string[] lib_dirs_;
  string[] libs_;
  string[] other_args_;
  //DPackage[] deps_;
  DTarget target_ = DTarget.NOTHING;  
  string out_file_;
  
  void DirMagic(string dir, bool cin = true, ref string varset = null)
  {
    if(exists(dir))
    {
      varset = dir;
    }
    else if (!exists(dir) && cin)
    {
      mkdirRecurse(dir);
    }
  }

public:

  this()
  {
  }
  
  string[] GetFiles() {return files_;} /// Get the var 
  string[] GetIncludes() {return include_dirs_;} /// ditto
  string[] GetLibs() {return libs_;} /// ditto 
  string[] GetLibDirs() {return lib_dirs_;} /// ditto
  string GetBuildDir() {return build_dir_;} /// ditto
  string GetDocDir() {return doc_dir_;} /// ditto
  string GetHeaderDir() {return header_dir_;} /// ditto
  string GetOutFile() {return out_file_;} /// ditto
  string[] GetArgs() {return other_args_;} /// ditto
  
  /// add an arbitrary argument
  void AddArg(string s)
  {
    other_args_ ~= s;
  }
  
  /// set the output filename
  void SetOutFile(string s)
  {
    out_file_ = s;
  }
  
  /// Set the type for the target
  void SetType(DTarget t)
  {
    target_ = t;
  }
  
  /// return type of package this is
  DTarget GetType() {return target_;}
  
  /**
   * Add a file to be included in the build
   */
  void AddFile(string file, bool compiletime=false)
  {
    if(exists(file) || compiletime)
      files_ ~= file;
  }
  
  /**
   * sets the specified directory
   * Params:
   *  cin= create if necessary, will by default create the directory you specify
   */
   
   ///ditto
  void SetBuildDir(string dir, bool cin=true)
  {
    DirMagic(dir, cin, build_dir_);
  }
  
  ///ditto
  void SetDocDir(string dir, bool cin=true)
  {
    DirMagic(dir, cin, doc_dir_);
  }
   
  ///ditto
  void SetHeaderDir(string dir, bool cin=true)
  {
    DirMagic(dir, cin, header_dir_);
  }
  
  /// add an entire directory of files to compile
  void AddSourceFileDir(string dir)
  {
    if(exists(dir))
    {
      foreach (DirEntry de; dirEntries(dir, SpanMode.shallow))
      {
        if(de.name[$-2..$] == ".d")
        {
          files_ ~= de.name;
        }
      }
    }
  }
  
  /// Add an include directory
  void AddInclude(string dir)
  {
    include_dirs_ ~= dir;
  }
  
  /// add a library to be included
  void AddLib(string libname)
  {
    libs_ ~= libname;
  }
  
  /// Add a library search directory
  void AddLibDir(string dir)
  {
    lib_dirs_ ~= dir;
  }
  
  void ClearAll()
  {
    
  }
  
}

/**
 * takes packages and does stuff with them
 */
class DBuild
{
private:
  DFront compiler_front_;
  string compiler_;
  string args_; /// contains list of arguments
  string files_; /// contains master list of files
  DPackage[string] packs_; /// contains the packages and their names
  string[][string] pdeps_;
  string inc_,hdir_,odir_,ldir_,lib_;
  
  void InitSwitches();
  
public:
  this(DFront compiler)
  {
    if(compiler == DFront.dmd)
      compiler_ = "dmd";
  }
  
  /**
   * adds a dependency for p1 to p2
   */
   void AddDepends(string p1, string p2)
   {
     if(PackExists(p1) && PackExists(p2))
     {
       pdeps_[p1] ~= p2;
     }
   }
   
   /**
    * get dependencies of the package
    */
   string[] GetDepends(string packagename)
   {
     string[] tstrarr;
     if(PackExists(packagename))
     {
       tstrarr = pdeps_[packagename];
     }
     return tstrarr;
   }
  
  /**
   * Adds a package with a string, so it can be built by name
   * Params:
   *  called= the name to call the package
   *  p= Package to add
   */
  void AddPackage(DPackage p, string called)
  {
    if ((called in packs_) is null)
    {
      packs_[called] = p;
      pdeps_[called] ~= null;
    }
  }
  
  /**
   * Get the package with the specified name
   */
  
  DPackage GetPackage(string packagename)
  {
    if (PackExists(packagename))
    {
      return packs_[packagename];
    }
    assert(0);
  }
  
  /**
   * Get package at the position specified $(B mostly for internal use)
   * $(GREEN $(B $(I Disabled because the array is an associative one )))
   * Disabled: It won't work.... ever
   */
  @disable DPackage GetPackage(uint index)
  {
    return null;
  }
  
  /**
   * Checks for package existence
   */
  bool PackExists(string packagename)
  {
    if ((packagename in packs_) is null)
      return false;
    else
      return true;
  }
  
  /**
   * Generate File List
   * Returns: string of all the files, spaced out
   */
  string GenFileList(string packagename)
  {
    string tstr;
    DPackage d = GetPackage(packagename);
    foreach (string s; d.GetFiles())
    {
      tstr ~= s ~ " ";
    }
    return tstr;
  }
  
  /**
   * Generates all the lib, include, etc arguments for the package
   * Returns: everything you will ever need to customize the build
   */
  string GenArgList(string packagename)
  {
    string tstr, outprefix;
    DPackage d = GetPackage(packagename);
    
    if(d.GetType() == DTarget.STATICLIB)
      tstr ~= "-lib ";
    else if(d.GetType() == DTarget.SHAREDLIB)
    {
      tstr ~= "-fPIC -shared ";
      outprefix = d.GetBuildDir ~ "/";
    }
    else if (d.GetType() == DTarget.EXECUTABLE)
    {
      outprefix = d.GetBuildDir ~ "/";
    }
      
    foreach(string s; d.GetIncludes())
    {
      tstr ~= "-I" ~ s ~ " ";
    }
    
    foreach(string s; d.GetLibDirs())
    {
      tstr ~= "-L-L" ~ s ~ " ";
    }
    
    foreach(string s; d.GetLibs())
    {
      tstr ~= "-L-l" ~ s ~ " ";
    }
    
    if(d.GetOutFile != null)
      tstr ~= "-of" ~ outprefix ~ d.GetOutFile() ~ " ";
    
    if(d.GetBuildDir != null)
      tstr ~= "-od" ~ d.GetBuildDir() ~ " ";
      
    if(d.GetHeaderDir != null)
      tstr ~= "-Hd" ~ d.GetHeaderDir() ~ " ";
    
    if(d.GetDocDir != null)
      tstr ~= "-Dd" ~ d.GetDocDir() ~ " ";
    
    foreach(string s; d.GetArgs())
    {
      tstr ~= " " ~ s ~ " ";
    }
    
    return tstr;
  }
  
  /**
   * Get an array of all the necessary dependant command lines for a package
   */
  string[] CompileCommandLineDepends(string packagename, bool includetarget=true)
  {
    string[] deplines;
    
    if(pdeps_.length > 0 && PackExists(packagename))
    {
      while(1)
      {
        if (pdeps_[packagename].length > 0 && pdeps_[packagename].length -1 > deplines.length)
        {
          foreach(string s; GetDepends(packagename))
          {
            deplines ~= CompileCommandLineDepends(s, true);
          }
        }
        else if(pdeps_[packagename].length - 1 == deplines.length && includetarget)
        {
          deplines ~= CompileCommandLine(packagename);
          break;
        }
      }
    }
    return deplines;
  }
  
  /**
   * Construct the command line necessary to build the package
   */
  string CompileCommandLine(string packagename)
  {
    string stemp;
    if (PackExists(packagename))
    {
      stemp ~= compiler_ ~ " " ~ this.GenFileList(packagename) ~ " " ~ this.GenArgList(packagename);
    }
    return stemp;
  }
  
  /**
   * returns array of strings to compile all of the files individually
   */
  @disable string[] ObjectCompileLine(string packagename)
  {
    return null;
  }
  
  public void Build(DPackage p)
  {
    
  }
}

version(NEVER) {
void main(string[] args)
{
  DPackage gw = new DPackage;
  gw.AddFile("d/GW/grid.d");
  gw.AddFile("d/GW/gridobj.d");
  gw.AddFile("d/GW/gridutil.d");
  gw.SetBuildDir("build");
  gw.SetHeaderDir("header");
  gw.SetDocDir("docs");
  gw.SetType(DTarget.STATICLIB);
  gw.AddInclude("d");
  
  DPackage gwd = new DPackage;
  gwd.AddFile("d/GW/grid_draw.d");
  gwd.SetType(DTarget.EXECUTABLE);
  gwd.AddLib("grid");
  gwd.AddLibDir("build");
  
  DBuild db = new DBuild(DFront.dmd);
  db.AddPackage(gw, "GW");
  db.AddPackage(gwd, "DRAW");
  db.AddDepends("DRAW", "GW");
  
  for(int i = 1; i < args.length; i++)
  {
    writeln(args[i]);
  }
  writeln(db.CompileCommandLine("DRAW"));
  writeln(db.GetDepends("DRAW"));
  writeln(db.CompileCommandLineDepends("DRAW"));
  
  
}
}
