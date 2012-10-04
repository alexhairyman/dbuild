module DB.dpackage;
import std.file;

private import DB.util;

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
  bool IsObjectCollection() {return object_compile_;} ///ditto
  
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
